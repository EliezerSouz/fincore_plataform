import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/estoque/views/producao_page.dart';
import '../controllers/dashboard_controller.dart';
import '../data/dashboard_repository.dart';

class BlocoProjecaoDias extends StatelessWidget {
  final DashboardController controller;

  const BlocoProjecaoDias({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final projecoes = controller.metrics.projecaoDias;
    if (projecoes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Previsão dos Próximos Dias',
            style: TextStyle(
              color: FincoreColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final useScroll = constraints.maxWidth < 550;
            final content = SizedBox(
              width: useScroll ? 550 : constraints.maxWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.0),
                    1: FlexColumnWidth(2.5),
                    2: FlexColumnWidth(2.5),
                    3: FlexColumnWidth(2.0),
                  },
                  children: [
                    // Cabeçalho
                    TableRow(
                      decoration: const BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        border: Border(bottom: BorderSide(color: FincoreColors.border)),
                      ),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Text('DIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Text('PEDIDOS', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Text('PRODUÇÃO', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Text('ESTOQUE', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                      ],
                    ),
                    // Linhas
                    ...projecoes.map((p) {
                      final isAtencao = p.estoqueStatus == 'ATENCAO';
                      final isCritico = p.estoqueStatus == 'CRITICO';

                      final Color statusColor = isCritico
                          ? const Color(0xFFE05C5C)
                          : (isAtencao ? const Color(0xFFF59E0B) : FincoreColors.success);

                      final String labelStatus = isCritico
                          ? 'CRÍTICO'
                          : (isAtencao ? 'ATENÇÃO' : 'NORMAL');

                      final totalProds = p.totalProducoesPlanejadas + p.totalProducoesEmAndamento;

                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: FincoreColors.border, width: 0.5)),
                        ),
                        children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: InkWell(
                              onTap: () => _mostrarDetalhesDia(context, p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Text(
                                  p.diaSemana,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: InkWell(
                              onTap: () => _mostrarDetalhesDia(context, p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Text(
                                  p.totalPedidos > 0 ? '${p.totalPedidos} agendado(s)' : 'Nenhum',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.totalPedidos > 0 ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                                    fontWeight: p.totalPedidos > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: InkWell(
                              onTap: () => _mostrarDetalhesDia(context, p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Text(
                                  totalProds > 0 ? '$totalProds ativa(s)' : 'Nenhuma',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: totalProds > 0 ? const Color(0xFF3B82F6) : FincoreColors.textSecondary,
                                    fontWeight: totalProds > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: InkWell(
                              onTap: () => _mostrarDetalhesDia(context, p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      labelStatus,
                                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );

            if (useScroll) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: content,
              );
            }
            return content;
          },
        ),
      ],
    );
  }

  void _mostrarDetalhesDia(BuildContext context, ProjecaoDia p) {
    showDialog(
      context: context,
      builder: (ctx) {
        final formatadorData = DateFormat('dd/MM/yyyy');
        return AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                p.itensComRisco.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: p.itensComRisco.isNotEmpty
                    ? (p.estoqueStatus == 'CRITICO' ? const Color(0xFFE05C5C) : const Color(0xFFF59E0B))
                    : FincoreColors.success,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Previsão: ${p.diaSemana} (${formatadorData.format(p.data.toLocal())})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedidos Agendados: ${p.totalPedidos} pedido(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Campanhas de Produção: ${p.totalProducoesPlanejadas} planejada(s) • ${p.totalProducoesEmAndamento} em andamento',
                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                  ),
                  const Divider(height: 20, color: FincoreColors.border),
                  if (p.itensComRisco.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: FincoreColors.success, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Todos os produtos com pedidos agendados possuem cobertura de estoque física ou planejada. Operação estável!',
                              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Por que este dia está em atenção?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE05C5C)),
                    ),
                    const SizedBox(height: 8),
                    ...p.itensComRisco.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.nomeProduto,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE05C5C).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'RISCO DE ATENDIMENTO',
                                    style: TextStyle(color: Color(0xFFE05C5C), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Indicadores explicativos
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildIndicatorMini('Físico Disp: ${item.quantidadeDisponivel.round()}'),
                                _buildIndicatorMini('Reservado Dia: ${item.quantidadeReservadaDia.round()}'),
                                _buildIndicatorMini('Planejado até Dia: ${item.producaoPlanejadaAteDia.round()}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saldo Projetado no Dia: ${item.projetado.round()} un.',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE05C5C)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    FincoreShell.selectTab(context, 'pedidos');
                                  },
                                  icon: const Icon(Icons.receipt_long_rounded, size: 12),
                                  label: const Text('Ver Pedidos', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: FincoreColors.textSecondary,
                                    side: const BorderSide(color: FincoreColors.border),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    ProducaoPage.initialTab = 2; // Planejamento
                                    ProducaoPage.filtroProdutoId = item.produtoId;
                                    FincoreShell.selectTab(context, 'producao');
                                  },
                                  icon: const Icon(Icons.precision_manufacturing_rounded, size: 12),
                                  label: const Text('Ver Produção', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FincoreColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar', style: TextStyle(color: FincoreColors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIndicatorMini(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, color: FincoreColors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
