import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/planejamento_controller.dart';
import 'package:fincore_food_flutter/src/estoque/views/producao_page.dart'; // Para CriarPlanoDialog
import '../controllers/dashboard_controller.dart';

class BlocoEstoqueResumo extends StatelessWidget {
  final DashboardController controller;

  const BlocoEstoqueResumo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final estoqueCtrl = DependencyInjection().get<EstoqueController>();
    final planeCtrl = DependencyInjection().get<PlanoProducaoController>();
    final itens = estoqueCtrl.itens;
    final itensPrecisamAcao = estoqueCtrl.itensPrecisamAcao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estoque Operacional',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => FincoreShell.selectTab(context, 'estoque'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 14),
                  label: const Text('Ver Estoque', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FincoreColors.textSecondary,
                    side: const BorderSide(color: FincoreColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mini KPI cards inline de contadores
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniCounter('Controlados', itens.length.toString(), FincoreColors.textSecondary),
            _buildMiniCounter('Críticos', estoqueCtrl.itensCriticos.length.toString(), const Color(0xFFE05C5C)),
            _buildMiniCounter('Atenção', estoqueCtrl.itensBaixos.length.toString(), const Color(0xFFF59E0B)),
            _buildMiniCounter('Com produção', estoqueCtrl.itensComProducao.length.toString(), const Color(0xFF3B82F6)),
            _buildMiniCounter('Normais', estoqueCtrl.itensNormais.length.toString(), FincoreColors.success),
          ],
        ),
        const SizedBox(height: 12),

        // Tabela resumida de itens que precisam de atenção
        LayoutBuilder(
          builder: (context, constraints) {
            final useScroll = constraints.maxWidth < 800;
            final content = SizedBox(
              width: useScroll ? 800 : constraints.maxWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        border: Border(bottom: BorderSide(color: FincoreColors.border)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(flex: 3, child: Text('PRODUTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                          const Expanded(flex: 2, child: Text('FÍSICO', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                          Expanded(
                            flex: 2,
                            child: Tooltip(
                              message: 'Quantidade comprometida por pedidos confirmados.',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('RESERVADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                                  SizedBox(width: 2),
                                  Icon(Icons.help_outline_rounded, size: 10, color: FincoreColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Tooltip(
                              message: 'Quantidade disponível para novos pedidos.\nCálculo: Físico - Reservado (limite comercial a 0).',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('DISPONÍVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                                  SizedBox(width: 2),
                                  Icon(Icons.help_outline_rounded, size: 10, color: FincoreColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          const Expanded(flex: 2, child: Text('PLANEJADO', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                          Expanded(
                            flex: 2,
                            child: Tooltip(
                              message: 'Saldo após entrada da produção planejada e saída das reservas.\nCálculo: Físico + Produção Planejada - Reservado.',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('PROJETADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                                  SizedBox(width: 2),
                                  Icon(Icons.help_outline_rounded, size: 10, color: FincoreColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          const Expanded(flex: 2, child: Text('SITUAÇÃO', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                          const SizedBox(width: 100, child: Text('AÇÃO', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                        ],
                      ),
                    ),
                    if (itensPrecisamAcao.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Tudo sob controle! Nenhum produto exige atenção imediata.',
                            style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: itensPrecisamAcao.length,
                        separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                        itemBuilder: (context, i) {
                          final item = itensPrecisamAcao[i];
                          final isCritico = item.status == EstoqueStatus.critico;
                          final statusColor = isCritico ? const Color(0xFFE05C5C) : const Color(0xFFF59E0B);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nomeProduto,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isCritico ? const Color(0xFFE05C5C) : FincoreColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Unidade: ${item.unidade}',
                                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.quantidadeAtual.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.quantidadeReservada.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.quantidadeReservada > 0 ? const Color(0xFFF59E0B) : FincoreColors.textSecondary,
                                      fontWeight: item.quantidadeReservada > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.quantidadeDisponivel.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                      if (item.deficitAtual > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE05C5C).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'déficit ${item.deficitAtual}',
                                            style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.producaoPlanejada > 0 ? '+${item.producaoPlanejada}' : '0',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.producaoPlanejada > 0 ? const Color(0xFF3B82F6) : FincoreColors.textMuted,
                                      fontWeight: item.producaoPlanejada > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.estoqueProjetado.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.estoqueProjetado < 0
                                          ? const Color(0xFFE05C5C)
                                          : (item.estoqueProjetado < item.quantidadeMinima
                                              ? const Color(0xFFF59E0B)
                                              : FincoreColors.success),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isCritico ? 'Crítico' : 'Atenção',
                                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => CriarPlanoDialog(
                                            planeCtrl: planeCtrl,
                                            estoqueCtrl: estoqueCtrl,
                                            produtoIdPreSelecionado: item.estoque.produtoId,
                                            quantidadePreSelecionada: item.sugestaoProducao > 0 ? item.sugestaoProducao : null,
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: FincoreColors.primary,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Planejar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  Widget _buildMiniCounter(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
