import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import '../controllers/dashboard_controller.dart';

class BlocoRankingProdutos extends StatelessWidget {
  final DashboardController controller;

  const BlocoRankingProdutos({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final topProdutos = controller.metrics.topProdutos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Ranking de Produtos (TOP 5)',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => FincoreShell.selectTab(context, 'produtos'),
              icon: const Icon(Icons.shopping_bag_outlined, size: 14),
              label: const Text('Produtos', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: FincoreColors.textSecondary,
                side: const BorderSide(color: FincoreColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          child: topProdutos.isEmpty
              ? const SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'Nenhuma venda registrada para ranqueamento.',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProdutos.length,
                  separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final p = topProdutos[index];
                    final rank = index + 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          // Medalha de Posição
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: rank <= 3
                                  ? FincoreColors.primary.withValues(alpha: 0.15)
                                  : FincoreColors.surfaceOverlay,
                              shape: BoxShape.circle,
                              border: rank <= 3 ? Border.all(color: FincoreColors.primary, width: 1.5) : null,
                            ),
                            child: Center(
                              child: Text(
                                rank.toString(),
                                style: TextStyle(
                                  color: rank <= 3 ? FincoreColors.primary : FincoreColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              p.nomeProduto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Quantidade vendida
                          Text(
                            '${p.quantidade.round()} un',
                            style: const TextStyle(
                              color: FincoreColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Indicador de Crescimento / Queda com variação percentual real e explicabilidade
                          Tooltip(
                            message: 'Comparação com o período anterior equivalente.',
                            decoration: BoxDecoration(
                              color: FincoreColors.surfaceOverlay,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            textStyle: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  p.isCrescimento
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: p.isCrescimento
                                      ? FincoreColors.success
                                      : const Color(0xFFF59E0B),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${p.isCrescimento ? '+' : ''}${p.variacaoPercentual.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: p.isCrescimento
                                        ? FincoreColors.success
                                        : const Color(0xFFF59E0B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
