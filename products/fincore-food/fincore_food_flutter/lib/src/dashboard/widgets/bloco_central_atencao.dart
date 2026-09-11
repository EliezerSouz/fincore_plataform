import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_shared/fincore_shared.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/planejamento_controller.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:fincore_food_flutter/src/estoque/views/producao_page.dart';
import 'package:fincore_food_flutter/src/estoque/views/estoque_page.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pedidos_page.dart';
import '../controllers/dashboard_controller.dart';
import '../domain/dashboard_alerts_service.dart';

class BlocoCentralAtencao extends StatefulWidget {
  final DashboardController controller;

  const BlocoCentralAtencao({super.key, required this.controller});

  @override
  State<BlocoCentralAtencao> createState() => _BlocoCentralAtencaoState();
}

class _BlocoCentralAtencaoState extends State<BlocoCentralAtencao> {
  bool _mostrarTodos = false;

  @override
  Widget build(BuildContext context) {
    final alertas = widget.controller.alertas;
    if (alertas.isEmpty) return const SizedBox.shrink();

    final planeCtrl = DependencyInjection().get<PlanoProducaoController>();
    final estoqueCtrl = DependencyInjection().get<EstoqueController>();

    final acoesNecessarias = alertas.where((a) => a.categoria == CategoriaAlerta.acaoNecessaria).toList();
    final acompanhamentos = alertas.where((a) => a.categoria == CategoriaAlerta.acompanhamento).toList();

    final totalAlertas = acoesNecessarias.length + acompanhamentos.length;
    
    // Lista unificada para limite e paginação no cockpit
    final List<AlertaOperacional> listaExibicao = [...acoesNecessarias, ...acompanhamentos];
    final bool temMaisDeTres = listaExibicao.length > 3;
    final List<AlertaOperacional> listaFiltrada = (_mostrarTodos || !temMaisDeTres)
        ? listaExibicao
        : listaExibicao.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Central de Atenção ($totalAlertas)',
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (temMaisDeTres)
              TextButton(
                onPressed: () {
                  setState(() {
                    _mostrarTodos = !_mostrarTodos;
                  });
                },
                child: Text(
                  _mostrarTodos ? 'Ver Menos' : 'Ver Todos ($totalAlertas)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.primary,
                  ),
                ),
              ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listaFiltrada.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final alerta = listaFiltrada[idx];
            final Color corTema = alerta.categoria == CategoriaAlerta.acaoNecessaria
                ? const Color(0xFFE05C5C)
                : const Color(0xFFF59E0B);
            return _buildAlertaCard(context, alerta, corTema, planeCtrl, estoqueCtrl);
          },
        ),
      ],
    );
  }

  Widget _buildAlertaCard(
    BuildContext context,
    AlertaOperacional alerta,
    Color corTema,
    PlanoProducaoController planeCtrl,
    EstoqueController estoqueCtrl,
  ) {
    // Cálculo do projetado
    final projetado = alerta.fisico + alerta.planejado - alerta.reservado;

    // Progresso se for em execução
    final double? progresso = (alerta.tipo == TipoAlertaOperacional.campanhaEmExecucao && alerta.planejado + alerta.produzido > 0)
        ? (alerta.produzido / (alerta.planejado + alerta.produzido))
        : null;

    final String badgeLabel = alerta.categoria == CategoriaAlerta.acaoNecessaria
        ? 'AÇÃO NECESSÁRIA'
        : 'ACOMPANHAMENTO';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corTema.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: corTema.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(color: corTema, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;

              final textContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.titulo,
                    style: TextStyle(
                      color: corTema,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alerta.descricao,
                    style: const TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (alerta.impacto != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Impacto: ${alerta.impacto}',
                      style: const TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              );

              final hasButton = alerta.acaoLabel != null;
              final actionButton = _buildButtonForAlerta(context, alerta, planeCtrl, estoqueCtrl);

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textContent,
                    if (hasButton) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: actionButton,
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: textContent),
                  if (hasButton) ...[
                    const SizedBox(width: 12),
                    actionButton,
                  ],
                ],
              );
            },
          ),
          
          // Indicadores de explicabilidade
          if (alerta.produtoId != null) ...[
            const Divider(height: 18, color: FincoreColors.border),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildTooltipIndicator(
                  'Físico: ${alerta.fisico.round()}',
                  'Estoque físico atualmente presente no estabelecimento (Congelado/Físico).',
                ),
                _buildTooltipIndicator(
                  'Reservado: ${alerta.reservado.round()}',
                  'Quantidade total comprometida por pedidos confirmados que ainda não saíram.',
                ),
                _buildTooltipIndicator(
                  'Disponível: ${alerta.disponivel.round()}',
                  'Quantidade disponível para novos pedidos (Físico - Reservado).',
                ),
                _buildTooltipIndicator(
                  'Planejado: ${alerta.planejado.round()}',
                  'Quantidade registrada em campanhas de produção ainda não concluídas.',
                ),
                _buildTooltipIndicator(
                  'Mínimo: ${alerta.minimo.round()}',
                  'Limite de estoque mínimo recomendado para operação.',
                ),
                _buildTooltipIndicator(
                  'Crítico: ${alerta.critico.round()}',
                  'Limite crítico abaixo do qual há risco iminente de desabastecimento.',
                ),
                _buildTooltipIndicator(
                  'Projetado: ${projetado.round()}',
                  'Estimativa de saldo projetado após a conclusão das produções planejadas (Físico + Planejado - Reservado).',
                  isProjetado: true,
                ),
              ],
            ),
          ],

          if (progresso != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso da Produção: ${(progresso * 100).round()}% (${alerta.produzido} / ${alerta.planejado + alerta.produzido} un.)',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progresso,
              minHeight: 4,
              backgroundColor: FincoreColors.border,
              color: FincoreColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTooltipIndicator(String text, String tooltipMsg, {bool isProjetado = false}) {
    return Tooltip(
      message: tooltipMsg,
      decoration: BoxDecoration(
        color: FincoreColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      textStyle: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11),
      padding: const EdgeInsets.all(8),
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isProjetado
              ? FincoreColors.primary.withValues(alpha: 0.08)
              : FincoreColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isProjetado ? FincoreColors.primary.withValues(alpha: 0.3) : FincoreColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isProjetado ? FontWeight.bold : FontWeight.w600,
                color: isProjetado ? FincoreColors.primary : FincoreColors.textSecondary,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.help_outline_rounded, size: 10, color: FincoreColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonForAlerta(
    BuildContext context,
    AlertaOperacional alerta,
    PlanoProducaoController planeCtrl,
    EstoqueController estoqueCtrl,
  ) {
    final label = alerta.acaoLabel;
    if (label == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () {
        if (label == 'Planejar Produção') {
          final item = estoqueCtrl.itens.firstWhere(
            (i) => i.estoque.produtoId == alerta.produtoId,
          );
          showDialog(
            context: context,
            builder: (_) => CriarPlanoDialog(
              planeCtrl: planeCtrl,
              estoqueCtrl: estoqueCtrl,
              produtoIdPreSelecionado: item.estoque.produtoId,
              quantidadePreSelecionada: item.sugestaoProducao > 0 ? item.sugestaoProducao : null,
            ),
          );
        } else if (label == 'Acompanhar Produção' || label == 'Ver Planejamento') {
          ProducaoPage.initialTab = 2; // Planejamento
          ProducaoPage.filtroProdutoId = alerta.produtoId;
          FincoreShell.selectTab(context, 'producao');
        } else if (label == 'Ver Pedido') {
          _abrirVisualizarPedido(context, alerta.pedidoId);
        } else if (label == 'Ver Estoque') {
          EstoquePage.filtroProdutoId = alerta.produtoId;
          FincoreShell.selectTab(context, 'estoque');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: FincoreColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _abrirVisualizarPedido(BuildContext context, String? pedidoId) async {
    if (pedidoId == null) return;
    final db = DependencyInjection().get<FincoreDatabase>();
    final pedido = await (db.select(db.pedidosTable)..where((t) => t.id.equals(pedidoId))).getSingleOrNull();

    if (pedido == null || !context.mounted) return;

    final orderItens = await (db.select(db.itensPedidoTable)
          ..where((t) => t.pedidoId.equals(pedidoId) & t.deletedAt.isNull()))
        .get();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: FincoreColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Pedido #${pedido.numeroPedido ?? pedido.id.substring(0, 5)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${pedido.clienteNomeAvulso ?? 'Balcão'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Logística: ${pedido.tipoLogistica} • Status: ${pedido.status}', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
              if (pedido.dataHoraEntregaPrevista != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Entrega prevista: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.dataHoraEntregaPrevista!.toLocal())}',
                  style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
              const Divider(height: 24, color: FincoreColors.border),
              const Text('Itens do Pedido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...orderItens.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${it.quantidade.round()}x ${it.nomeProduto}', style: const TextStyle(fontSize: 12)),
                      Text(FincoreMoneyFormatter.format(it.valorTotalCentavos), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              const Divider(height: 24, color: FincoreColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(FincoreMoneyFormatter.format(pedido.valorTotalCentavos), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FincoreColors.success)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final dataRef = (pedido.dataHoraEntregaPrevista ?? pedido.dataHoraCriacao).toLocal();
              PedidosPage.dataPreSelecionada = dataRef;
              PedidosPage.filtroPedidoId = pedido.id;
              FincoreShell.selectTab(context, 'pedidos');
            },
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
            child: const Text('Ir para Central de Pedidos'),
          ),
        ],
      ),
    );
  }
}
