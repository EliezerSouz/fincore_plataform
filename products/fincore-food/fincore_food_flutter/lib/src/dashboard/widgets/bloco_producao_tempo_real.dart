import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/planejamento_controller.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';

class BlocoProducaoTempoReal extends StatelessWidget {
  final DashboardController controller;

  const BlocoProducaoTempoReal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final planeCtrl = DependencyInjection().get<PlanoProducaoController>();
    final estoqueCtrl = DependencyInjection().get<EstoqueController>();

    final planos = planeCtrl.planos;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    // Filtros de campanhas
    final emPreparacao = planos.where((p) =>
        p.status == 'planejada' &&
        p.dataPlano.isAfter(startOfDay) &&
        p.dataPlano.isBefore(endOfDay)
    ).toList();

    final emProducao = planos.where((p) =>
        p.status == 'em_preparacao' || p.status == 'em_producao' || p.status == 'parcial'
    ).toList();

    final concluidasHoje = planos.where((p) =>
        p.status == 'concluida' &&
        p.dataPlano.isAfter(startOfDay) &&
        p.dataPlano.isBefore(endOfDay)
    ).toList();

    final proximasCampanhas = planos.where((p) =>
        p.status == 'planejada' &&
        p.dataPlano.isAfter(endOfDay)
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Produção em Tempo Real',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => FincoreShell.selectTab(context, 'producao'),
              icon: const Icon(Icons.factory_outlined, size: 14),
              label: const Text('Ver Produção', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: FincoreColors.textSecondary,
                side: const BorderSide(color: FincoreColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final painelEsquerda = Container(
              padding: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Em Produção',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FincoreColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${emProducao.length} ativa(s)',
                          style: const TextStyle(color: FincoreColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: FincoreColors.border),
                  Expanded(
                    child: emProducao.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma campanha em execução no momento.',
                              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            itemCount: emProducao.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final p = emProducao[index];
                              final item = estoqueCtrl.itens
                                  .where((i) => i.estoque.produtoId == p.produtoId)
                                  .firstOrNull;
                              if (item == null) return const SizedBox.shrink();

                              final double pct = p.quantidadePlanejada > 0 ? (p.quantidadeProduzida / p.quantidadePlanejada) : 0.0;
                              final int unFaltantes = p.quantidadePlanejada - p.quantidadeProduzida;
                              final int tempoMinutos = item.tempoPreparacao * unFaltantes;
                              final String tempoRestante = tempoMinutos > 0 ? '$tempoMinutos min restantes' : 'Concluindo';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.nomeProduto,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${p.quantidadeProduzida} / ${p.quantidadePlanejada} un (${(pct * 100).round()}%)',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: pct,
                                    color: FincoreColors.primary,
                                    backgroundColor: FincoreColors.border,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tempoRestante,
                                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );

            final painelDireita = Container(
              padding: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo da Campanha',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                  const Divider(height: 20, color: FincoreColors.border),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResumoRow('Aguardando início:', emPreparacao.length.toString(), const Color(0xFFF59E0B)),
                        _buildResumoRow('Concluídas hoje:', concluidasHoje.length.toString(), FincoreColors.success),
                        _buildResumoRow(
                          'Próxima planejada:',
                          proximasCampanhas.isEmpty
                              ? 'Nenhuma'
                              : DateFormat('dd/MM HH:mm').format(proximasCampanhas.first.dataPlano.toLocal()),
                          const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (isMobile) {
              return Column(
                children: [
                  painelEsquerda,
                  const SizedBox(height: 14),
                  painelDireita,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: painelEsquerda,
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: painelDireita,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResumoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
