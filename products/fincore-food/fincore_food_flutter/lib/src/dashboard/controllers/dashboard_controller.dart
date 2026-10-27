import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import '../domain/dashboard_service.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_alerts_service.dart';
import '../../estoque/controllers/estoque_controller.dart';
import '../../estoque/controllers/planejamento_controller.dart';
import '../../shared/data/sync/supabase_sync_service.dart';

/// Recomendação operacional automática da IA/regras do sistema
class RecomendacaoOperacional {
  final String tipo; // 'producao_recomendada' | 'nenhuma_acao' | 'alerta_operacional'
  final String produtoId;
  final String produtoNome;
  final String titulo;
  final String descricao;
  final String acaoLabel;

  const RecomendacaoOperacional({
    required this.tipo,
    required this.produtoId,
    required this.produtoNome,
    required this.titulo,
    required this.descricao,
    required this.acaoLabel,
  });
}

/// Controller do Dashboard — gerencia estado e lógica de negócio.
class DashboardController extends ChangeNotifier {
  final DashboardService _service;
  late final EstoqueController _estoqueController;
  late final PlanoProducaoController _planoProducaoController;
  late final DashboardAlertsService _alertsService;
  StreamSubscription<String>? _syncSub;

  DashboardMetrics _metrics = DashboardMetrics.zero();
  List<AlertaOperacional> _alertas = [];
  List<RecomendacaoOperacional> _recomendacoes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Preferências do usuário sobre a ordem e visibilidade dos módulos
  List<String> _enabledModules = [
    'Operação Agora',
    'Atividades Recentes',
    'Estoque',
    'Produção',
    'Entregas Futuras',
    'Vendas',
    'Produtos Mais Vendidos',
    'Satisfação & Avaliações',
    'Próximos Dias',
    'Recomendações',
  ];

  DashboardController({
    required DashboardService service,
    EstoqueController? estoqueController,
    PlanoProducaoController? planoProducaoController,
    DashboardAlertsService? alertsService,
  }) : _service = service {
    _estoqueController = estoqueController ?? DependencyInjection().get<EstoqueController>();
    _planoProducaoController = planoProducaoController ?? DependencyInjection().get<PlanoProducaoController>();
    _alertsService = alertsService ?? DashboardAlertsService();

    // Registra listeners para atualizar o dashboard quando os dados de estoque e planos mudarem
    _estoqueController.addListener(_onControllersChanged);
    _planoProducaoController.addListener(_onControllersChanged);

    // Escuta finalização da sincronização em nuvem (pull/push de pedidos e estoque)
    try {
      final syncService = DependencyInjection().get<SupabaseSyncService>();
      _syncSub = syncService.onDataSynced.listen((_) => loadMetrics());
    } catch (_) {}

    loadModulePreferences();
  }

  // ─── Getters públicos (somente leitura para a UI) ─────────────────────────
  DashboardMetrics get metrics => _metrics;
  List<AlertaOperacional> get alertas => _alertas;
  List<RecomendacaoOperacional> get recomendacoes => _recomendacoes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<String> get enabledModules => _enabledModules;

  String get resumoOperacionalText {
    final acoesNecessarias = _alertas.where((a) => a.categoria == CategoriaAlerta.acaoNecessaria).length;
    final acompanhamentos = _alertas.where((a) => a.categoria == CategoriaAlerta.acompanhamento).length;

    if (acoesNecessarias > 0) {
      return "Operação requer atenção urgente. Há $acoesNecessarias alerta${acoesNecessarias > 1 ? 's críticos (pedidos atrasados, estoque crítico ou produção pendente)' : ' crítico (pedido atrasado, estoque crítico ou produção pendente)'}.";
    }
    if (acompanhamentos > 0) {
      return "Operação sob acompanhamento. $acompanhamentos item${acompanhamentos > 1 ? 'ns estão' : ' está'} em acompanhamento.";
    }

    return "Operação estável. Nenhuma ação imediata necessária.";
  }

  void _onControllersChanged() {
    if (_isLoading) return;
    loadMetrics();
  }

  /// Carrega as métricas e alertas consolidados
  Future<void> loadMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 0. Garante que os dados de estoque e planos estão atualizados do banco local
      await _estoqueController.refresh();
      await _planoProducaoController.refresh();

      // 1. Busca agregações do banco (pedidos, faturamento, ranking)
      _metrics = await _service.getMetrics();

      // 2. Consolida alertas operacionais via serviço de domínio
      _alertas = await _alertsService.obterAlertasAtivos(_estoqueController, _planoProducaoController);

      // 3. Gera recomendações da IA do sistema
      _gerarRecomendacoes();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Falha ao carregar painel operacional: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gera recomendações inteligentes baseadas nas regras operacionais
  void _gerarRecomendacoes() {
    final List<RecomendacaoOperacional> recs = [];

    for (final item in _estoqueController.itens) {
      if (item.status == EstoqueStatus.critico || item.status == EstoqueStatus.baixo) {
        if (item.producaoPlanejada == 0) {
          recs.add(RecomendacaoOperacional(
            tipo: 'producao_recomendada',
            produtoId: item.estoque.produtoId,
            produtoNome: item.nomeProduto,
            titulo: 'Produção Recomendada',
            descricao: 'O produto ${item.nomeProduto} está com estoque abaixo do mínimo e nenhum planejamento está ativo.',
            acaoLabel: 'Planejar Produção',
          ));
        } else if (item.deficitAtual > 0 && item.producaoPlanejada >= item.deficitAtual) {
          recs.add(RecomendacaoOperacional(
            tipo: 'nenhuma_acao',
            produtoId: item.estoque.produtoId,
            produtoNome: item.nomeProduto,
            titulo: 'Nenhuma ação necessária',
            descricao: 'Já existe produção suficiente de ${item.nomeProduto} para cobrir as reservas existentes.',
            acaoLabel: 'Ver Planejamento',
          ));
        }
      } else {
        // Alerta operacional de cobertura baixa (se menor que 2 dias de cobertura)
        final cobertura = item.quantidadeDisponivel > 0 ? (item.quantidadeDisponivel / 25.0) : 0.0;
        if (cobertura > 0 && cobertura < 2.0 && item.producaoPlanejada == 0) {
          recs.add(RecomendacaoOperacional(
            tipo: 'alerta_operacional',
            produtoId: item.estoque.produtoId,
            produtoNome: item.nomeProduto,
            titulo: 'Alerta Operacional',
            descricao: 'O produto ${item.nomeProduto} possui cobertura de estoque estimada de apenas ${cobertura.toStringAsFixed(1)} dias.',
            acaoLabel: 'Ver Estoque',
          ));
        }
      }
    }

    // Limita às 3 recomendações mais urgentes para não poluir
    _recomendacoes = recs.take(3).toList();
  }

  /// Carrega as preferências de personalização do usuário
  Future<void> loadModulePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tenant = DependencyInjection().get<TenantContext>();
      final userId = tenant.hasContext ? tenant.usuario.id : 'global';
      final list = prefs.getStringList('dashboard_modules_$userId');
      if (list != null && list.isNotEmpty) {
        _enabledModules = list;
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Salva as preferências de personalização e registra log de auditoria
  Future<void> saveModulePreferences(List<String> modules) async {
    final List<String> finalModules = List.from(modules);
    for (final essential in ['Operação Agora', 'Produção', 'Entregas Futuras']) {
      if (!finalModules.contains(essential)) {
        finalModules.add(essential);
      }
    }
    _enabledModules = finalModules;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tenant = DependencyInjection().get<TenantContext>();
      final userId = tenant.hasContext ? tenant.usuario.id : 'global';
      await prefs.setStringList('dashboard_modules_$userId', modules);

      // Auditoria
      if (tenant.hasContext) {
        final auditRepo = DependencyInjection().get<AuditLogRepository>();
        await auditRepo.log(
          entityName: 'dashboard_personalizacao',
          entityId: tenant.usuario.id,
          userId: tenant.usuario.id,
          action: 'UPDATE',
          entityDisplayName: 'Dashboard Personalizada',
          entityModule: 'Dashboard',
          reason: 'O usuário personalizou a visibilidade e ordem dos blocos do cockpit.',
          diff: {'modulos': modules},
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _estoqueController.removeListener(_onControllersChanged);
    _planoProducaoController.removeListener(_onControllersChanged);
    super.dispose();
  }
}
