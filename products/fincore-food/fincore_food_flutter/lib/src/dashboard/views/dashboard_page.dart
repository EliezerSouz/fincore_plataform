import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../domain/dashboard_alerts_service.dart';
import '../widgets/bloco_operacao_agora.dart';
import '../widgets/bloco_central_atencao.dart';
import '../widgets/bloco_timeline.dart';
import '../widgets/bloco_estoque_resumo.dart';
import '../widgets/bloco_producao_tempo_real.dart';
import '../widgets/bloco_proximas_entregas.dart';
import '../widgets/bloco_velocimetro_vendas.dart';
import '../widgets/bloco_ranking_produtos.dart';
import '../widgets/bloco_projecao_dias.dart';
import '../widgets/bloco_recomendacoes.dart';
import '../widgets/bloco_atividade_recente.dart';
import '../widgets/bloco_avaliacoes_nps.dart';
import '../widgets/dashboard_personalizar_modal.dart';

/// Dashboard principal do FINCORE Food — Centro de Comando Operacional.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;
  late final Timer _timer;
  String _currentTimeStr = '';

  @override
  void initState() {
    super.initState();
    _controller = DependencyInjection().get<DashboardController>();
    _controller.loadMetrics();

    // Atualiza a hora no header a cada segundo
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm:ss').format(now);
    if (mounted && timeStr != _currentTimeStr) {
      setState(() {
        _currentTimeStr = timeStr;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _saudacao {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = DependencyInjection().get<TenantContext>();
    final nomeUsuario = tenant.hasContext ? tenant.usuario.nome : 'Usuário';

    return Scaffold(
      backgroundColor: FincoreColors.background,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.metrics.totalPedidosHoje == 0) {
            return Center(
              child: CircularProgressIndicator(
                color: FincoreColors.primary,
                strokeWidth: 2,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.loadMetrics,
            color: FincoreColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header Compacto ──────────────────────────────────────────
                  _buildHeader(context, nomeUsuario),
                  const SizedBox(height: 18),

                  // ─── Central de Atenção (Coração - Exibido apenas com alertas) ──
                  if (_controller.alertas.isNotEmpty) ...[
                    BlocoCentralAtencao(controller: _controller),
                    const SizedBox(height: 20),
                  ],

                  // ─── Renderização Dinâmica e Ordenada de Blocos ───────────────
                  ..._buildDynamicBlocks(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String nomeUsuario) {
    final dataStr = DateFormat("d 'de' MMMM 'de' yyyy", "pt_BR").format(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final headerText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FINCORE FOOD',
              style: TextStyle(
                color: FincoreColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_saudacao, ${nomeUsuario.split(' ').first}.',
              style: const TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$dataStr • $_currentTimeStr',
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _controller.resumoOperacionalText,
              style: TextStyle(
                color: _controller.alertas.any((a) => a.categoria == CategoriaAlerta.acaoNecessaria)
                    ? const Color(0xFFE05C5C)
                    : (_controller.alertas.any((a) => a.categoria == CategoriaAlerta.acompanhamento)
                        ? const Color(0xFFF59E0B)
                        : FincoreColors.success),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _controller.loadMetrics,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Atualizar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: FincoreColors.textSecondary,
                side: const BorderSide(color: FincoreColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => DashboardPersonalizarModal(controller: _controller),
                );
              },
              icon: const Icon(Icons.tune_rounded, size: 14),
              label: const Text('Personalizar Dashboard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerText,
              const SizedBox(height: 12),
              actionButtons,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: headerText,
            ),
            actionButtons,
          ],
        );
      },
    );
  }

  List<Widget> _buildDynamicBlocks() {
    final List<Widget> widgets = [];

    for (final moduleName in _controller.enabledModules) {
      Widget? blockWidget;

      switch (moduleName) {
        case 'Operação Agora':
          blockWidget = BlocoOperacaoAgora(controller: _controller);
          break;
        case 'Linha do Tempo':
          blockWidget = BlocoTimeline(controller: _controller);
          break;
        case 'Estoque':
          blockWidget = BlocoEstoqueResumo(controller: _controller);
          break;
        case 'Produção':
          blockWidget = BlocoProducaoTempoReal(controller: _controller);
          break;
        case 'Entregas Futuras':
          blockWidget = BlocoProximasEntregas(controller: _controller);
          break;
        case 'Vendas':
          blockWidget = BlocoVelocimetroVendas(controller: _controller);
          break;
        case 'Produtos Mais Vendidos':
          blockWidget = BlocoRankingProdutos(controller: _controller);
          break;
        case 'Próximos Dias':
          blockWidget = BlocoProjecaoDias(controller: _controller);
          break;
        case 'Recomendações':
          blockWidget = BlocoRecomendacoes(controller: _controller);
          break;
        case 'Atividades Recentes':
          blockWidget = BlocoAtividadeRecente(controller: _controller);
          break;
        case 'Satisfação & Avaliações':
          blockWidget = BlocoAvaliacoesNps(controller: _controller);
          break;
      }

      if (blockWidget != null) {
        widgets.add(blockWidget);
        widgets.add(const SizedBox(height: 22));
      }
    }

    return widgets;
  }
}
