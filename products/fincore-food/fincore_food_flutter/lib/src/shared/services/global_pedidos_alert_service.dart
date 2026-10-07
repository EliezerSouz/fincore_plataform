import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';
import 'windows_focus_service.dart';
import '../data/sync/supabase_sync_service.dart';

/// Modelo de resumo para alertas operacionais globais de pedidos
class PedidosAlertaResumo {
  final int totalAtrasados;
  final int totalUrgentes; // ≤ 15 min
  final int totalAtencao; // ≤ 30 min
  final List<PedidoData> pedidosCriticos;

  const PedidosAlertaResumo({
    required this.totalAtrasados,
    required this.totalUrgentes,
    required this.totalAtencao,
    required this.pedidosCriticos,
  });

  bool get temPendenciasCriticas => totalAtrasados > 0 || totalUrgentes > 0;
  bool get hasAny => totalAtrasados > 0 || totalUrgentes > 0 || totalAtencao > 0;
}

/// Serviço global de vigilância operacional de pedidos e novos pedidos recebidos.
///
/// Executa em background em todo o aplicativo (independente da tela ativa no Windows).
/// 1. Toca alerta sonoro configurável e vibrante.
/// 2. Restaura e foca a janela do Windows se estiver minimizada ou em segundo plano.
/// 3. Exibe overlay flutuante de novo pedido ou de pendências de entrega em qualquer tela.
/// 4. Reage em tempo real aos eventos WebSocket do Supabase e executa polling frequente de segurança.
class GlobalPedidosAlertService {
  static final GlobalPedidosAlertService _instance = GlobalPedidosAlertService._internal();
  factory GlobalPedidosAlertService() => _instance;
  GlobalPedidosAlertService._internal();

  Timer? _timer;
  StreamSubscription? _syncSub;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final Set<String> _knownPedidoIds = {};
  bool _isFirstLoadCompleted = false;

  PedidosAlertaResumo _ultimoResumo = const PedidosAlertaResumo(
    totalAtrasados: 0,
    totalUrgentes: 0,
    totalAtencao: 0,
    pedidosCriticos: [],
  );
  PedidosAlertaResumo get ultimoResumo => _ultimoResumo;

  final ValueNotifier<PedidosAlertaResumo?> resumoNotifier = ValueNotifier<PedidosAlertaResumo?>(null);
  final ValueNotifier<PedidosAlertaResumo?> alertaOverlayNotifier = ValueNotifier<PedidosAlertaResumo?>(null);
  final ValueNotifier<PedidoData?> novoPedidoOverlayNotifier = ValueNotifier<PedidoData?>(null);

  OverlayEntry? _overlayEntry;
  BuildContext? _shellContext;
  BuildContext? get shellContext => _shellContext;

  /// Registra o contexto do Shell para permitir apresentação do Overlay flutuante
  void registerShellContext(BuildContext context) {
    _shellContext = context;
  }

  /// Inicia o serviço global de monitoramento
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Escuta sincronizações e eventos Realtime do Supabase para notificação instantânea
    try {
      final syncService = DependencyInjection().tryGet<SupabaseSyncService>();
      _syncSub = syncService?.onDataSynced.listen((entity) {
        if (entity == 'ALL' ||
            entity.toLowerCase().contains('pedido') ||
            entity.toLowerCase().contains('ordem')) {
          checkNow();
        }
      });
    } catch (_) {}

    _scheduleNextCheck();
  }

  /// Para o serviço
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _syncSub?.cancel();
    _syncSub = null;
    dismissOverlay();
    dismissNovoPedidoOverlay();
  }

  /// Reinicia imediatamente o ciclo de temporização com as configurações recém-salvas
  void restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_isRunning) {
      _scheduleNextCheck();
    }
  }

  Future<void> _scheduleNextCheck() async {
    if (!_isRunning) return;

    // Sincroniza pedidos e ordens da nuvem para garantir captura de novos pedidos mesmo se o websocket oscilar
    try {
      final syncService = DependencyInjection().tryGet<SupabaseSyncService>();
      if (syncService != null && await syncService.isOnline()) {
        final db = DependencyInjection().get<FincoreDatabase>();
        await syncService.pullAll(db, DateTime.fromMillisecondsSinceEpoch(0));
      }
    } catch (_) {}

    // Executa a verificação imediatamente
    await checkNow();

    // Lê o intervalo configurado da empresa (máximo 15 segundos para resposta ágil de novos pedidos)
    int intervaloSegundos = 15;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInterval = prefs.getInt('alerta_sonoro_intervalo_segundos');
      if (savedInterval != null && savedInterval >= 5) {
        intervaloSegundos = savedInterval;
      } else {
        final di = DependencyInjection();
        final configRepo = di.get<EmpresaConfiguracaoRepository>();
        final configs = await configRepo.findAll();
        if (configs.isNotEmpty) {
          intervaloSegundos = configs.first.intervaloAlertaPendentesSegundos;
          if (intervaloSegundos < 5) intervaloSegundos = 5;
        }
      }
    } catch (_) {}

    _timer?.cancel();
    _timer = Timer(Duration(seconds: intervaloSegundos), () => _scheduleNextCheck());
  }

  /// Executa uma varredura imediata de pedidos no banco local
  Future<PedidosAlertaResumo> checkNow() async {
    try {
      final di = DependencyInjection();
      TenantContext tenantCtx;
      FincoreDatabase db;
      try {
        db = di.get<FincoreDatabase>();
        tenantCtx = di.get<TenantContext>();
      } catch (_) {
        return const PedidosAlertaResumo(totalAtrasados: 0, totalUrgentes: 0, totalAtencao: 0, pedidosCriticos: []);
      }

      if (!tenantCtx.hasContext) {
        return const PedidosAlertaResumo(totalAtrasados: 0, totalUrgentes: 0, totalAtencao: 0, pedidosCriticos: []);
      }

      final activeTenantId = tenantCtx.tenantId;

      // Margem de segurança padrão (em minutos)
      int margemMinutos = 10;
      try {
        final configRepo = di.get<EmpresaConfiguracaoRepository>();
        final configs = await configRepo.findAll();
        if (configs.isNotEmpty) {
          margemMinutos = configs.first.margemSegurancaMinutos;
        }
      } catch (_) {}

      // Busca TODOS os pedidos ativos: 'pendente' (Cardápio Web), 'confirmado' e 'em_preparo'
      final pedidosAtivos = await (db.select(db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(activeTenantId) &
                t.deletedAt.isNull() &
                t.status.isIn(const ['pendente', 'confirmado', 'em_preparo']) &
                t.isUsoInterno.equals(false)))
          .get();

      // ─── 1. Detecção de Novos Pedidos Recebidos ────────────────────────────
      if (_isFirstLoadCompleted) {
        final novosPedidos = pedidosAtivos.where((p) =>
            !_knownPedidoIds.contains(p.id) &&
            (p.status == 'pendente' || p.canalOrigem.toLowerCase().contains('cardapio') || p.status == 'confirmado')
        ).toList();

        if (novosPedidos.isNotEmpty) {
          // Ordena pelo mais recente
          novosPedidos.sort((a, b) => b.dataHoraCriacao.compareTo(a.dataHoraCriacao));
          final pedidoMaisRecente = novosPedidos.first;

          // 1. Toca o alerta sonoro de novo pedido
          await SoundService.playNewOrderSound();

          // 2. Foca e restaura a janela do Windows se estiver minimizada ou atrás de outros apps
          WindowsFocusService.bringWindowToFront();

          // 3. Notifica o Shell para exibir o banner flutuante em qualquer tela
          novoPedidoOverlayNotifier.value = null;
          novoPedidoOverlayNotifier.value = pedidoMaisRecente;
        }
      } else {
        _isFirstLoadCompleted = true;
      }

      _knownPedidoIds.addAll(pedidosAtivos.map((p) => p.id));

      // ─── 2. Detecção de Pedidos Atrasados / Próximos do Prazo ─────────────
      final now = DateTime.now();
      int atrasados = 0;
      int urgentes = 0;
      int atencao = 0;
      final List<PedidoData> criticos = [];

      final pedidosEmAndamento = pedidosAtivos.where((p) => p.status == 'confirmado' || p.status == 'em_preparo').toList();

      for (final p in pedidosEmAndamento) {
        DateTime deadline;
        if (p.dataHoraEntregaPrevista != null) {
          deadline = p.dataHoraEntregaPrevista!.toLocal();
        } else {
          deadline = p.dataHoraCriacao.toLocal().add(Duration(minutes: margemMinutos));
        }

        final diff = deadline.difference(now);

        if (diff.isNegative) {
          atrasados++;
          criticos.add(p);
        } else if (diff.inMinutes <= 15) {
          urgentes++;
          criticos.add(p);
        } else if (diff.inMinutes <= 30) {
          atencao++;
        }
      }

      final resumo = PedidosAlertaResumo(
        totalAtrasados: atrasados,
        totalUrgentes: urgentes,
        totalAtencao: atencao,
        pedidosCriticos: criticos,
      );

      _ultimoResumo = resumo;
      resumoNotifier.value = resumo;

      // Dispara som e overlay se houver pendências críticas de prazo
      if (resumo.temPendenciasCriticas) {
        // Toca som de urgência se não acabou de tocar novo pedido
        if (novoPedidoOverlayNotifier.value == null) {
          await SoundService.playUrgentSound();
        }

        // Notifica o Shell para exibir o overlay de atrasos no canto inferior
        alertaOverlayNotifier.value = null;
        alertaOverlayNotifier.value = resumo;
      } else if (resumo.totalAtencao > 0) {
        if (novoPedidoOverlayNotifier.value == null) {
          await SoundService.playAttentionSound();
        }
        dismissOverlay();
      } else {
        dismissOverlay();
      }

      return resumo;
    } catch (e) {
      debugPrint('[GlobalPedidosAlertService] Erro ao verificar pedidos: $e');
      return const PedidosAlertaResumo(totalAtrasados: 0, totalUrgentes: 0, totalAtencao: 0, pedidosCriticos: []);
    }
  }

  /// Descarta o overlay visual de atenção/atraso
  void dismissOverlay() {
    alertaOverlayNotifier.value = null;
    hideOverlay();
  }

  /// Descarta o overlay visual de novo pedido recebido
  void dismissNovoPedidoOverlay() {
    novoPedidoOverlayNotifier.value = null;
  }

  /// Esconde o overlay se inserido via OverlayState
  void hideOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }
}
