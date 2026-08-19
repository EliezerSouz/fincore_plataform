import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';

/// Faixa de "Produção Necessária" — exibe os itens que a cozinha precisa produzir.
///
/// Dados derivados 100% dos pedidos reais (pendente + emPreparo + pronto)
/// para a data e filtro de origem selecionados no controller.
/// Nunca usa valores hardcoded.
class ProducaoNecessariaBar extends StatelessWidget {
  final CentralPedidosController controller;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ProducaoNecessariaBar({
    super.key,
    required this.controller,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final itens = controller.producaoNecessaria;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        children: [
          // Header da faixa
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(10))
                : BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.restaurant_outlined,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PRODUÇÃO NECESSÁRIA',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (itens.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${itens.length} produto${itens.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: FincoreColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          if (isExpanded) ...[
            Container(height: 1, color: FincoreColors.border),
            if (itens.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Nenhum item pendente de produção.',
                  style: TextStyle(
                    color: FincoreColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              )
            else
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: itens.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) =>
                      _ProducaoChip(item: itens[idx]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProducaoChip extends StatelessWidget {
  final ItemProducaoNecessaria item;
  const _ProducaoChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final qtdStr = item.quantidade % 1 == 0
        ? '${item.quantidade.toInt()}'
        : item.quantidade.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$qtdStr ${item.unidade}',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.nomeProduto,
            style: const TextStyle(
              color: FincoreColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
