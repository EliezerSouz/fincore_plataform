import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:intl/intl.dart';
import '../../controllers/pdv_express_controller.dart';
import '../../domain/pricing_engine.dart';
import '../../models/pdv_item.dart';

class OrderSummaryPanel extends StatelessWidget {
  final PdvExpressController controller;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const OrderSummaryPanel({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: double.infinity,
      color: FincoreColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header do Painel
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: FincoreColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'PAINEL OPERACIONAL',
                    style: TextStyle(
                      color: FincoreColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (controller.cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.cart.length} itens',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: FincoreColors.border, height: 1),

          // Cards Roláveis
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomerCard(cliente: controller.cliente),
                  const SizedBox(height: 16),
                  DeliveryCard(entrega: controller.entrega),
                  const SizedBox(height: 16),
                  PricingCard(pricingResult: controller.pricingResult),
                  const SizedBox(height: 16),
                  CartItemsCard(
                    items: controller.cart,
                    onRemove: (id, currentQty) async {
                      if (currentQty <= 1) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Remover Item', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            content: const Text('Deseja remover este produto do carrinho?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Remover', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          controller.updateQuantity(id, 0);
                        }
                      } else {
                        controller.updateQuantity(id, currentQty - 1);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TotalsCard(
                    subtotalCentavos: controller.cart.fold(0, (sum, i) => sum + i.totalInCents),
                    taxaEntregaCentavos: controller.entrega.tipo == 'Entrega' ? controller.entrega.taxaEntregaCentavos : 0,
                    trocoParaCentavos: controller.paymentMethod == 'Dinheiro' ? controller.entrega.trocoParaCentavos : null,
                    totalCentavos: controller.totalInCents,
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: FincoreColors.border, height: 1),

          // Botões de Ação
          Padding(
            padding: const EdgeInsets.all(20),
            child: ActionButtons(
              passoAtual: controller.passoAtual,
              podeAvancar: controller.podeAvancar(),
              onBack: onBack,
              onNext: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final DadosCliente cliente;

  const CustomerCard({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final hasClient = !cliente.isEmpty;

    return _buildSummaryCard(
      title: 'Cliente',
      icon: Icons.person_outline,
      child: hasClient
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nome ?? 'Consumidor',
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cliente.telefone ?? '',
                  style: const TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          : const Text(
              'Nenhum cliente identificado [F2]',
              style: TextStyle(
                color: FincoreColors.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final DadosEntrega entrega;

  const DeliveryCard({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(entrega.dataHora);
    final isDelivery = entrega.tipo == 'Entrega';

    return _buildSummaryCard(
      title: 'Logística',
      icon: Icons.local_shipping_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entrega.tipo.toUpperCase(),
                style: TextStyle(
                  color: isDelivery ? FincoreColors.primary : FincoreColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                entrega.prioridade,
                style: const TextStyle(
                  color: FincoreColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dataStr,
            style: const TextStyle(
              color: FincoreColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
          if (isDelivery && entrega.logradouro.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${entrega.logradouro}, ${entrega.numero}\nBairro: ${entrega.bairro}',
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PricingCard extends StatelessWidget {
  final PricingResult pricingResult;

  const PricingCard({super.key, required this.pricingResult});

  @override
  Widget build(BuildContext context) {
    if (pricingResult.groupSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSummaryCard(
      title: 'Grupos & Faixas de Preço',
      icon: Icons.sell_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: pricingResult.groupSummaries.map((sum) {
          final groupName = sum.group.name;
          final totalQty = sum.totalQty.toInt();
          final appliedPrice = (sum.appliedUnitPriceInCents / 100).toStringAsFixed(2);
          final hasUpsell = sum.potentialSavingsInCents != null && sum.potentialSavingsInCents! > 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '$totalQty un. (R\$ $appliedPrice unit.)',
                      style: const TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (hasUpsell && sum.qtyNeededForNextRange != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FincoreColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FincoreColors.warning.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, color: FincoreColors.warning, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary),
                              children: [
                                const TextSpan(text: 'Adicione mais '),
                                TextSpan(
                                  text: '${sum.qtyNeededForNextRange!.toInt()} un.',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.warning),
                                ),
                                const TextSpan(text: ' para economizar '),
                                TextSpan(
                                  text: 'R\$ ${(sum.potentialSavingsInCents! / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.success),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CartItemsCard extends StatelessWidget {
  final List<PdvItem> items;
  final Function(String id, double currentQty) onRemove;

  const CartItemsCard({
    super.key,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSummaryCard(
      title: 'Itens no Carrinho',
      icon: Icons.shopping_basket_outlined,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhum item adicionado',
                style: TextStyle(
                  color: FincoreColors.textMuted,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            )
          : Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final priceStr = (item.priceInCents / 100).toStringAsFixed(2);
                  final totalStr = (item.totalInCents / 100).toStringAsFixed(2);

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FincoreColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity.toInt()}x R\$ $priceStr',
                              style: const TextStyle(
                                color: FincoreColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'R\$ $totalStr',
                        style: const TextStyle(
                          color: FincoreColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: FincoreColors.danger, size: 18),
                        onPressed: () => onRemove(item.productId, item.quantity),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class TotalsCard extends StatelessWidget {
  final int subtotalCentavos;
  final int taxaEntregaCentavos;
  final int? trocoParaCentavos;
  final int totalCentavos;

  const TotalsCard({
    super.key,
    required this.subtotalCentavos,
    required this.taxaEntregaCentavos,
    this.trocoParaCentavos,
    required this.totalCentavos,
  });

  @override
  Widget build(BuildContext context) {
    final subtotalStr = (subtotalCentavos / 100).toStringAsFixed(2);
    final taxaStr = (taxaEntregaCentavos / 100).toStringAsFixed(2);
    final totalStr = (totalCentavos / 100).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
              ),
              Text(
                'R\$ $subtotalStr',
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Taxa / Frete',
                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
              ),
              Text(
                'R\$ $taxaStr',
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
              ),
            ],
          ),
          if (trocoParaCentavos != null && trocoParaCentavos! > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Troco para',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                ),
                Text(
                  'R\$ ${(trocoParaCentavos! / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor do Troco',
                  style: TextStyle(color: FincoreColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  'R\$ ${((trocoParaCentavos! - totalCentavos) / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: FincoreColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const Divider(color: FincoreColors.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL GERAL',
                style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'R\$ $totalStr',
                style: const TextStyle(
                  color: FincoreColors.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  final int passoAtual;
  final bool podeAvancar;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ActionButtons({
    super.key,
    required this.passoAtual,
    required this.podeAvancar,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final nextBtnText = passoAtual == 2
        ? 'CONFIRMAR PAGAMENTO [F12]'
        : (passoAtual == 0 ? 'AVANÇAR PARA PRODUTOS [F3]' : 'AVANÇAR PARA PAGAMENTO [F3]');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: podeAvancar ? FincoreColors.primary : FincoreColors.border,
              foregroundColor: podeAvancar ? Colors.white : FincoreColors.textMuted,
            ),
            onPressed: podeAvancar ? onNext : null,
            child: Text(nextBtnText),
          ),
        ),
        if (passoAtual > 0) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('VOLTAR ETAPA'),
            ),
          ),
        ],
      ],
    );
  }
}

Widget _buildSummaryCard({
  required String title,
  required IconData icon,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: FincoreColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: FincoreColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: FincoreColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const Divider(color: FincoreColors.border, height: 16),
        child,
      ],
    ),
  );
}
