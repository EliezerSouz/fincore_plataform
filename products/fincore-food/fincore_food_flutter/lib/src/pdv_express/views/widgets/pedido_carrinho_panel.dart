import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';
import '../../models/pdv_item.dart';

/// Coluna 3 da Workstation: Pedido / Carrinho, Formas de Pagamento & Finalização
/// Sempre visível, permitindo conferência contínua, seleção hierárquica por modalidades
/// (Dinheiro, PIX, Cartão Crédito, Débito, Prazo com sub-bandeiras sem poluição visual),
/// exibição de taxa de entrega, taxa de serviço e ação de finalizar [F10/F12].
class PedidoCarrinhoPanel extends StatefulWidget {
  final PdvExpressController controller;
  final VoidCallback onFinalizar;
  final VoidCallback onLimpar;

  const PedidoCarrinhoPanel({
    super.key,
    required this.controller,
    required this.onFinalizar,
    required this.onLimpar,
  });

  @override
  State<PedidoCarrinhoPanel> createState() => _PedidoCarrinhoPanelState();
}

class _PedidoCarrinhoPanelState extends State<PedidoCarrinhoPanel> {
  final _trocoCtrl = TextEditingController();
  String? _modalidadeAtiva;

  @override
  void initState() {
    super.initState();
    final entrega = widget.controller.entrega;
    if (entrega.trocoParaCentavos != null && entrega.trocoParaCentavos! > 0) {
      _trocoCtrl.text = (entrega.trocoParaCentavos! / 100).toStringAsFixed(2).replaceAll('.', ',');
    }
    _atualizarModalidadeAtiva();
    _trocoCtrl.addListener(_onTrocoChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _trocoCtrl.removeListener(_onTrocoChanged);
    _trocoCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final entrega = widget.controller.entrega;
    if (entrega.trocoParaCentavos == null && _trocoCtrl.text.isNotEmpty) {
      _trocoCtrl.clear();
    }
    _atualizarModalidadeAtiva();
    if (mounted) setState(() {});
  }

  void _atualizarModalidadeAtiva() {
    final selectedForma = widget.controller.selectedFormaPagamento;
    if (selectedForma != null) {
      _modalidadeAtiva = _obterModalidadeDaForma(selectedForma);
    } else {
      _modalidadeAtiva = 'Dinheiro';
    }
  }

  void _onTrocoChanged() {
    final clean = _trocoCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    final trocoReais = double.tryParse(clean) ?? 0.0;
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        trocoParaCentavos: () => trocoReais > 0 ? (trocoReais * 100).round() : null,
      ),
    );
  }

  Future<void> _showEditQuantityDialog(BuildContext context, PdvItem item) async {
    final ctrl = TextEditingController(
      text: item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(2),
    );

    final newQty = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Alterar Quantidade: ${item.name}',
          style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 260,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Quantidade',
              hintText: 'Ex: 25',
              filled: true,
              fillColor: FincoreColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
              Navigator.of(ctx).pop(val);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (newQty != null) {
      await widget.controller.updateQuantity(item.productId, newQty);
    }
  }

  String _obterModalidadeDaForma(FormaPagamento forma) {
    if (forma.tipo == TipoFormaPagamento.dinheiro || forma.nome.toLowerCase().contains('dinheiro')) {
      return 'Dinheiro';
    }
    if (forma.tipo == TipoFormaPagamento.pix || forma.nome.toLowerCase().contains('pix')) {
      return 'PIX';
    }
    if (forma.tipo == TipoFormaPagamento.cartaoCredito || forma.nome.toLowerCase().contains('crédito') || forma.nome.toLowerCase().contains('credito')) {
      return 'Crédito';
    }
    if (forma.tipo == TipoFormaPagamento.cartaoDebito || forma.nome.toLowerCase().contains('débito') || forma.nome.toLowerCase().contains('debito')) {
      return 'Débito';
    }
    if (forma.tipo == TipoFormaPagamento.notaPrazo || forma.nome.toLowerCase().contains('prazo') || forma.nome.toLowerCase().contains('faturad')) {
      return 'A Prazo';
    }
    if (forma.tipo == TipoFormaPagamento.consumoInterno || forma.nome.toLowerCase().contains('consumo') || forma.nome.toLowerCase().contains('cortesia')) {
      return 'Consumo/Cortesia';
    }
    return 'Outros';
  }

  IconData _getIconeModalidade(String modalidade) {
    switch (modalidade) {
      case 'Dinheiro':
        return Icons.attach_money_rounded;
      case 'PIX':
        return Icons.bolt_rounded;
      case 'Crédito':
        return Icons.credit_card_rounded;
      case 'Débito':
        return Icons.payment_rounded;
      case 'A Prazo':
        return Icons.receipt_long_rounded;
      case 'Consumo/Cortesia':
        return Icons.restaurant_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  void _selecionarModalidade(String modalidade, List<FormaPagamento> formasDaModalidade) {
    setState(() {
      _modalidadeAtiva = modalidade;
    });

    if (formasDaModalidade.isNotEmpty) {
      // Se a forma atualmente selecionada já pertence a este grupo, mantém
      final selected = widget.controller.selectedFormaPagamento;
      if (selected == null || !formasDaModalidade.any((f) => f.id == selected.id)) {
        widget.controller.selectFormaPagamento(formasDaModalidade.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final cart = controller.cart;
    final totalUnits = cart.fold<double>(0, (sum, i) => sum + i.quantity);
    final totalUnitsStr = totalUnits % 1 == 0 ? totalUnits.toStringAsFixed(0) : totalUnits.toStringAsFixed(1);

    final subtotalCentavos = cart.fold(0, (sum, i) => sum + i.totalInCents);
    final taxaCentavos = controller.entrega.tipo == 'Entrega' ? controller.entrega.taxaEntregaCentavos : 0;
    final taxaServicoCentavos = controller.entrega.taxaServicoCentavos;
    final totalCentavos = controller.totalInCents;

    final formas = controller.formasPagamento;
    final selectedForma = controller.selectedFormaPagamento;
    final isDinheiro = selectedForma?.tipo == TipoFormaPagamento.dinheiro ||
        (selectedForma?.nome.toLowerCase().contains('dinheiro') ?? false);

    // ── Agrupamento Real das Formas por Modalidade ────────────────────
    final Map<String, List<FormaPagamento>> gruposModalidade = {};
    for (final f in formas) {
      final mod = _obterModalidadeDaForma(f);
      gruposModalidade.putIfAbsent(mod, () => []).add(f);
    }

    // Modalidade atualmente em foco
    final currentMod = _modalidadeAtiva ?? (selectedForma != null ? _obterModalidadeDaForma(selectedForma) : 'Dinheiro');
    final formasDoGrupoAtivo = gruposModalidade[currentMod] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Cabeçalho do Pedido ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FincoreColors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_outlined, color: FincoreColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'PEDIDO',
                  style: TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: FincoreColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalUnitsStr un',
                    style: TextStyle(
                      color: FincoreColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (cart.isNotEmpty)
                  InkWell(
                    onTap: widget.onLimpar,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: const [
                          Icon(Icons.delete_sweep_outlined, size: 14, color: Color(0xFFEF4444)),
                          SizedBox(width: 4),
                          Text(
                            'Limpar [ESC]',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── 2. Lista Rolável de Itens ────────────────────────────────
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_shopping_cart_rounded, size: 40, color: FincoreColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Carrinho vazio',
                          style: TextStyle(color: FincoreColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Adicione produtos pelo catálogo ao lado',
                          style: TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final unitPriceStr = 'R\$ ${(item.priceInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
                      final itemTotalStr = 'R\$ ${(item.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
                      final qtyStr = item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          children: [
                            // Controles de Quantidade (-) Qtd (+)
                            Container(
                              decoration: BoxDecoration(
                                color: FincoreColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: FincoreColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => controller.updateQuantity(item.productId, item.quantity - 1),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.remove, size: 14, color: FincoreColors.textSecondary),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _showEditQuantityDialog(context, item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Text(
                                        qtyStr,
                                        style: const TextStyle(
                                          color: FincoreColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => controller.updateQuantity(item.productId, item.quantity + 1),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.add, size: 14, color: FincoreColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Nome e Preço Unitário
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: FincoreColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$qtyStr x $unitPriceStr',
                                    style: const TextStyle(
                                      color: FincoreColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Total do Item
                            Text(
                              itemTotalStr,
                              style: const TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Botão Excluir
                            IconButton(
                              icon: const Icon(Icons.close, size: 14, color: FincoreColors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Remover Item',
                              onPressed: () => controller.updateQuantity(item.productId, 0),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ── 3. Seção Hierárquica de Formas de Pagamento (Sem Cortes) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: FincoreColors.background,
              border: Border(
                top: BorderSide(color: FincoreColors.border),
                bottom: BorderSide(color: FincoreColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Forma de Pagamento',
                      style: TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (selectedForma != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedForma.nome,
                          style: TextStyle(
                            color: FincoreColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // NÍVEL 1: Modalidades Principais (Dinheiro, PIX, Crédito, Débito, Prazo, etc.)
                if (gruposModalidade.isEmpty)
                  const Text('Nenhuma forma cadastrada', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: gruposModalidade.keys.map((modalidade) {
                      final isModalidadeAtiva = currentMod == modalidade;
                      final icone = _getIconeModalidade(modalidade);
                      final itensDoGrupo = gruposModalidade[modalidade] ?? [];

                      return InkWell(
                        onTap: () => _selecionarModalidade(modalidade, itensDoGrupo),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isModalidadeAtiva
                                ? FincoreColors.primary.withValues(alpha: 0.20)
                                : FincoreColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isModalidadeAtiva ? FincoreColors.primary : FincoreColors.border,
                              width: isModalidadeAtiva ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icone,
                                size: 14,
                                color: isModalidadeAtiva ? FincoreColors.primary : FincoreColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                modalidade,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isModalidadeAtiva ? FontWeight.bold : FontWeight.normal,
                                  color: isModalidadeAtiva ? FincoreColors.primary : FincoreColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // NÍVEL 2: Sub-opções (Bandeiras / Contas / Tipos Específicos) se houver mais de 1 no grupo
                if (formasDoGrupoAtivo.length > 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecione a opção de $currentMod:',
                          style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: formasDoGrupoAtivo.map((forma) {
                            final isSel = selectedForma?.id == forma.id;
                            return InkWell(
                              onTap: () => controller.selectFormaPagamento(forma),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? FincoreColors.primary : FincoreColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSel ? FincoreColors.primary : FincoreColors.border,
                                  ),
                                ),
                                child: Text(
                                  forma.nome,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? Colors.white : FincoreColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Se for dinheiro: Campo de Troco
                if (isDinheiro) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Troco para R\$:',
                        style: TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: TextField(
                            controller: _trocoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '0,00',
                              hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                              filled: true,
                              fillColor: FincoreColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: FincoreColors.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: FincoreColors.border)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── 4. Seção Financeira de Totais ───────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FincoreColors.border)),
            ),
            child: Column(
              children: [
                _buildTotalRow(
                  'Subtotal:',
                  'R\$ ${(subtotalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                if (taxaCentavos > 0) ...[
                  const SizedBox(height: 4),
                  _buildTotalRow(
                    'Taxa de Entrega:',
                    'R\$ ${(taxaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
                if (taxaServicoCentavos > 0) ...[
                  const SizedBox(height: 4),
                  _buildTotalRow(
                    'Taxa de Serviço / Garçom:',
                    'R\$ ${(taxaServicoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                    color: const Color(0xFF38BDF8),
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(color: FincoreColors.border, height: 1),
                const SizedBox(height: 8),

                // TOTAL DESTACADO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'R\$ ${(totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 5. Botão de Ação Principal [F10 / F12] ──────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cart.isEmpty ? FincoreColors.surfaceElevated : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: cart.isEmpty ? 0 : 4,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: cart.isEmpty ? null : widget.onFinalizar,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'RECEBER / FINALIZAR [F10]',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? FincoreColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
