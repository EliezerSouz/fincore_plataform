import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../controllers/pdv_express_controller.dart';
import '../../models/pdv_item.dart';

/// Painel Operacional Persistente do Carrinho (Coluna Direita do PDV Express)
/// Layout otimizado: Cliente no topo, itens no meio (expansível/rolável), totais e CTA fixados abaixo.
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
    final subtotalCentavos = controller.cart.fold(0, (sum, i) => sum + i.totalInCents);
    final taxaCentavos = controller.entrega.tipo == 'Entrega' ? controller.entrega.taxaEntregaCentavos : 0;
    final totalCentavos = controller.totalInCents;

    return Container(
      width: 380,
      height: double.infinity,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Card de Seleção de Cliente / Atendimento no Topo ───────
          _CustomerSelectorCard(controller: controller),
          const SizedBox(height: 10),

          // ── 2. Lista Limpa de Itens do Carrinho ────────────────────────
          Expanded(
            child: controller.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 32, color: FincoreColors.textMuted),
                        SizedBox(height: 4),
                        Text(
                          'Carrinho vazio',
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: controller.cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      return _CartItemRow(
                        item: item,
                        onDecrement: () {
                          controller.updateQuantity(
                            item.productId,
                            item.quantity - 1,
                          );
                        },
                        onIncrement: () {
                          controller.updateQuantity(
                            item.productId,
                            item.quantity + 1,
                          );
                        },
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),
          const Divider(color: FincoreColors.border, height: 1),
          const SizedBox(height: 12),

          // ── 3. Resumo de Totais (Subtotal, Taxa, TOTAL GIGANTE) ───────
          _TotalsSection(
            subtotalCentavos: subtotalCentavos,
            taxaCentavos: taxaCentavos,
            totalCentavos: totalCentavos,
          ),

          const SizedBox(height: 16),

          // ── 4. Método de Pagamento (Pills: PIX, Dinheiro, Cartão) ───────
          _PaymentMethodSelector(controller: controller),

          const SizedBox(height: 16),

          // ── 5. Botão CTA Principal "Avançar" ──────────────────────────
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: FincoreColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onNext,
              child: Text(
                controller.passoAtual == 2 ? 'Finalizar Venda [F12]' : 'Avançar',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Card de Cliente & Entrega Detalhado no Topo do Carrinho ────
class _CustomerSelectorCard extends StatelessWidget {
  final PdvExpressController controller;

  const _CustomerSelectorCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cliente = controller.cliente;
    final hasCliente = !cliente.isEmpty;
    final entrega = controller.entrega;
    final isDelivery = entrega.tipo == 'Entrega';
    final now = entrega.dataHora;
    final dataHoraStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final enderecoStr = isDelivery
        ? (entrega.logradouro.isNotEmpty
            ? '${entrega.logradouro}${entrega.numero.isNotEmpty ? ", ${entrega.numero}" : ""}${entrega.bairro.isNotEmpty ? " - ${entrega.bairro}" : ""}'
            : 'Endereço não informado')
        : 'Atendimento Presencial (Mesa ${entrega.mesa.isNotEmpty ? entrega.mesa : "N/A"})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título do Card
        Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: FincoreColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'RESUMO DO PEDIDO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Divider(color: FincoreColors.border, height: 20),

        // Bloco Cliente
        const Text(
          'CLIENTE',
          style: TextStyle(
            color: FincoreColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasCliente ? (cliente.nome ?? 'Cliente não informado') : 'Cliente não selecionado',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        if (hasCliente && cliente.telefone != null && cliente.telefone!.isNotEmpty)
          Text(
            cliente.telefone!,
            style: const TextStyle(
              color: FincoreColors.textSecondary,
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 12),

        // Bloco Entrega / Retirada
        const Text(
          'ENTREGA / RETIRADA',
          style: TextStyle(
            color: FincoreColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${entrega.tipo}: $dataHoraStr',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          enderecoStr,
          style: const TextStyle(
            color: FincoreColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        const Text(
          'ITENS NO CARRINHO',
          style: TextStyle(
            color: FincoreColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

/// ── Linha Individual do Carrinho com `- 1 +` inline ────────────────────────
class _CartItemRow extends StatelessWidget {
  final PdvItem item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItemRow({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final unitPriceStr = (item.priceInCents / 100).toStringAsFixed(2).replaceAll('.', ',');
    final priceTotalStr = (item.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Detalhes do Produto (Nome e Preço Unitário)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity.toInt()} un × R\$ $unitPriceStr',
                  style: TextStyle(
                    color: FincoreColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Botões de Quantidade
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityBtn(
                icon: Icons.remove,
                onTap: onDecrement,
              ),
              const SizedBox(width: 4),
              _QuantityBtn(
                icon: Icons.add,
                onTap: onIncrement,
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Preço Total do Item
          SizedBox(
            width: 75,
            child: Text(
              'R\$ $priceTotalStr',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Icon(icon, size: 14, color: FincoreColors.textSecondary),
      ),
    );
  }
}

/// ── Quadro de Totais com destaque gigante em Laranja no Total ───────────────
class _TotalsSection extends StatelessWidget {
  final int subtotalCentavos;
  final int taxaCentavos;
  final int totalCentavos;

  const _TotalsSection({
    required this.subtotalCentavos,
    required this.taxaCentavos,
    required this.totalCentavos,
  });

  @override
  Widget build(BuildContext context) {
    final subtotalStr = (subtotalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final taxaStr = (taxaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final totalStr = (totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal:',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
            ),
            Text(
              'R\$ $subtotalStr',
              style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Taxa de entrega:',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
            ),
            Text(
              'R\$ $taxaStr',
              style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total:',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              'R\$ $totalStr',
              style: TextStyle(
                color: FincoreColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ── Seletor de Pagamento em Pills (PIX, Dinheiro, Cartão) ───────────────────
class _PaymentMethodSelector extends StatelessWidget {
  final PdvExpressController controller;

  const _PaymentMethodSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'id': 'PIX', 'label': 'PIX', 'icon': Icons.qr_code},
      {'id': 'Dinheiro', 'label': 'Dinheiro', 'icon': Icons.attach_money},
      {'id': 'Cartão', 'label': 'Cartão', 'icon': Icons.credit_card},
    ];

    final activeMethod = controller.paymentMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pagamento:',
          style: TextStyle(
            color: FincoreColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: FincoreColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            children: methods.map((m) {
              final id = m['id'] as String;
              final label = m['label'] as String;
              final icon = m['icon'] as IconData;
              final isSelected = activeMethod.toLowerCase().contains(id.toLowerCase());

              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.setPaymentMethod(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FincoreColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: FincoreColors.border)
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected
                                ? FincoreColors.primary
                                : FincoreColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? FincoreColors.textPrimary
                                  : FincoreColors.textMuted,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
