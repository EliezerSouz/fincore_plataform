import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';
import 'package:fincore_food_flutter/src/shared/services/impressao_service.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import 'split_payment_modal.dart';

class PaymentStep extends StatefulWidget {
  final PdvExpressController controller;

  const PaymentStep({
    super.key,
    required this.controller,
  });

  @override
  State<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<PaymentStep> {
  late final TextEditingController _trocoCtrl;
  late final TextEditingController _obsCtrl;
  FincoreImpressaoConfig? _impConfig;

  @override
  void initState() {
    super.initState();
    final entrega = widget.controller.entrega;
    _trocoCtrl = TextEditingController(
      text: entrega.trocoParaCentavos != null
          ? (entrega.trocoParaCentavos! / 100).toStringAsFixed(2)
          : '',
    );
    _obsCtrl = TextEditingController(text: entrega.observacoes);

    _trocoCtrl.addListener(_updateTroco);
    _obsCtrl.addListener(_updateObs);
    _loadPixConfig();
  }

  Future<void> _loadPixConfig() async {
    final config = await FincoreImpressaoConfig.carregar();
    if (mounted) {
      setState(() {
        _impConfig = config;
      });
    }
  }

  @override
  void dispose() {
    _trocoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _updateTroco() {
    final trocoReais = double.tryParse(_trocoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        trocoParaCentavos: () => trocoReais > 0 ? (trocoReais * 100).round() : null,
      ),
    );
  }

  void _updateObs() {
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        observacoes: _obsCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final formas = controller.formasPagamento;
    final selectedForma = controller.selectedFormaPagamento;
    final activePaymentMethod = controller.paymentMethod;

    // Classificação dinâmica das formas de pagamento
    final pixFormas = formas.where((f) => f.tipo == TipoFormaPagamento.pix || f.nome.toLowerCase().contains('pix')).toList();
    final cartaoFormas = formas.where((f) => f.tipo == TipoFormaPagamento.cartaoCredito || f.tipo == TipoFormaPagamento.cartaoDebito || f.nome.toLowerCase().contains('cart')).toList();
    final dinheiroFormas = formas.where((f) => f.tipo == TipoFormaPagamento.dinheiro || f.nome.toLowerCase().contains('dinheiro')).toList();
    final notaPrazoFormas = formas.where((f) => f.tipo == TipoFormaPagamento.notaPrazo || f.nome.toLowerCase().contains('prazo') || f.nome.toLowerCase().contains('faturad')).toList();
    final outrosFormas = formas.where((f) => !pixFormas.contains(f) && !cartaoFormas.contains(f) && !dinheiroFormas.contains(f) && !notaPrazoFormas.contains(f)).toList();

    // Determinar categoria ativa
    String activeCategory = 'Dinheiro';
    if (selectedForma != null) {
      if (pixFormas.any((f) => f.id == selectedForma.id)) {
        activeCategory = 'PIX';
      } else if (cartaoFormas.any((f) => f.id == selectedForma.id)) {
        activeCategory = 'Cartão';
      } else if (dinheiroFormas.any((f) => f.id == selectedForma.id)) {
        activeCategory = 'Dinheiro';
      } else if (notaPrazoFormas.any((f) => f.id == selectedForma.id)) {
        activeCategory = 'NotaPrazo';
      } else {
        activeCategory = 'Outros';
      }
    } else {
      final clean = activePaymentMethod.toLowerCase();
      if (clean.contains('pix')) {
        activeCategory = 'PIX';
      } else if (clean.contains('cart')) {
        activeCategory = 'Cartão';
      } else if (clean.contains('dinheiro')) {
        activeCategory = 'Dinheiro';
      } else if (clean.contains('prazo') || clean.contains('faturad')) {
        activeCategory = 'NotaPrazo';
      } else {
        activeCategory = 'Outros';
      }
    }

    // Informações de PIX da forma selecionada
    final effectivePixChave = (selectedForma?.pixChave != null && selectedForma!.pixChave!.isNotEmpty)
        ? selectedForma.pixChave!
        : (_impConfig?.pixChave ?? '');
    final effectivePixTipo = (selectedForma?.pixTipoChave != null && selectedForma!.pixTipoChave!.isNotEmpty)
        ? selectedForma.pixTipoChave!
        : (_impConfig?.pixTipo ?? 'PIX');
    final effectivePixBanco = selectedForma?.pixTipoBanco ?? '';
    final effectivePixFavorecido = _impConfig?.pixFavorecido ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment_outlined, color: FincoreColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'PAGAMENTO & OBSERVAÇÕES',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (controller.isSplitPayment) ...[
                    InkWell(
                      onTap: () => SplitPaymentModal.show(context, controller),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FincoreColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: FincoreColors.success.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_split_rounded, size: 14, color: FincoreColors.success),
                            const SizedBox(width: 5),
                            Text(
                              'Dividido (${controller.splitPayments.length} fatias)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: FincoreColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: FincoreColors.textMuted),
                      onPressed: () => controller.clearSplitPayments(),
                      tooltip: 'Desfazer divisão',
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call_split_rounded, size: 14),
                      label: const Text('Dividir Pagamento', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.background,
                        foregroundColor: FincoreColors.primary,
                        side: const BorderSide(color: FincoreColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => SplitPaymentModal.show(context, controller),
                    ),
                    const SizedBox(width: 8),
                    if (selectedForma != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: FincoreColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              selectedForma.nome,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: FincoreColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
              const Divider(color: FincoreColors.border, height: 24),

              if (controller.isSplitPayment) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAGAMENTOS FRACIONADOS APLICADOS:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.success, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      ...controller.splitPayments.map((pag) {
                        final vStr = (pag.valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• ${pag.formaPagamentoNome}${pag.bandeira != null ? " (${pag.bandeira})" : ""}',
                                style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'R\$ $vStr',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.success),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Opções de Pagamento Primárias (Categorias) ────────────
              Row(
                children: [
                  _buildPaymentCard(
                    label: 'Pix',
                    badgeText: pixFormas.length > 1 ? '${pixFormas.length} contas' : null,
                    icon: Icons.qr_code_scanner_outlined,
                    isSelected: activeCategory == 'PIX',
                    onTap: () {
                      if (pixFormas.isNotEmpty) {
                        controller.selectFormaPagamento(pixFormas.first);
                      } else {
                        controller.setPaymentMethod('PIX');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildPaymentCard(
                    label: 'Cartão',
                    badgeText: cartaoFormas.length > 1 ? '${cartaoFormas.length} tipos' : null,
                    icon: Icons.credit_card_outlined,
                    isSelected: activeCategory == 'Cartão',
                    onTap: () {
                      if (cartaoFormas.isNotEmpty) {
                        controller.selectFormaPagamento(cartaoFormas.first);
                      } else {
                        controller.setPaymentMethod('Cartão (Débito)');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildPaymentCard(
                    label: 'Dinheiro',
                    badgeText: dinheiroFormas.length > 1 ? '${dinheiroFormas.length} opções' : null,
                    icon: Icons.payments_outlined,
                    isSelected: activeCategory == 'Dinheiro',
                    onTap: () {
                      if (dinheiroFormas.isNotEmpty) {
                        controller.selectFormaPagamento(dinheiroFormas.first);
                      } else {
                        controller.setPaymentMethod('Dinheiro');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildPaymentCard(
                    label: 'Nota a Prazo',
                    badgeText: notaPrazoFormas.length > 1 ? '${notaPrazoFormas.length} prazos' : (notaPrazoFormas.isNotEmpty ? 'Faturado' : null),
                    icon: Icons.calendar_month_outlined,
                    isSelected: activeCategory == 'NotaPrazo',
                    onTap: () {
                      if (notaPrazoFormas.isNotEmpty) {
                        controller.selectFormaPagamento(notaPrazoFormas.first);
                      } else {
                        controller.setPaymentMethod('Nota a Prazo');
                      }
                    },
                  ),
                  if (outrosFormas.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    _buildPaymentCard(
                      label: 'Outros / Convênio',
                      badgeText: '${outrosFormas.length} opções',
                      icon: Icons.account_balance_wallet_outlined,
                      isSelected: activeCategory == 'Outros',
                      onTap: () {
                        controller.selectFormaPagamento(outrosFormas.first);
                      },
                    ),
                  ],
                ],
              ),

              // ── Sub-opções quando PIX está ativo ──────────────────────
              if (activeCategory == 'PIX') ...[
                const SizedBox(height: 20),
                const Text(
                  'SELECIONE A CONTA / CHAVE PIX',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                if (pixFormas.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pixFormas.map((forma) {
                      final isSelected = selectedForma?.id == forma.id || activePaymentMethod == forma.nome;
                      final bancoInfo = (forma.pixTipoBanco != null && forma.pixTipoBanco!.isNotEmpty) ? ' • ${forma.pixTipoBanco}' : '';
                      return ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          Icons.qr_code_2_rounded,
                          size: 16,
                          color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                        ),
                        label: Text('${forma.nome}$bancoInfo'),
                        selectedColor: FincoreColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected ? FincoreColors.primary : FincoreColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectFormaPagamento(forma);
                          }
                        },
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    'Utilizando chave PIX principal padrão.',
                    style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                  ),

                const SizedBox(height: 16),
                // Painel de Cópia da Chave Pix
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FincoreColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: FincoreColors.accent, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Chave Pix (${selectedForma?.nome ?? "Principal"} - $effectivePixTipo):',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: FincoreColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (effectivePixBanco.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.background,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          effectivePixBanco,
                                          style: const TextStyle(fontSize: 10, color: FincoreColors.accent, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  effectivePixChave.isNotEmpty
                                      ? effectivePixChave
                                      : 'Nenhuma Chave PIX configurada para esta opção.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: effectivePixChave.isNotEmpty ? FincoreColors.textPrimary : FincoreColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (effectivePixFavorecido.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Favorecido: $effectivePixFavorecido',
                                    style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (effectivePixChave.isNotEmpty)
                            Tooltip(
                              message: 'Copiar apenas a chave PIX',
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FincoreColors.accent,
                                  side: const BorderSide(color: FincoreColors.accent),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                icon: const Icon(Icons.copy, size: 14),
                                label: const Text('Copiar Chave', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: effectivePixChave));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: FincoreColors.success,
                                      content: Text('Chave Pix copiada com sucesso!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      if (effectivePixChave.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: FincoreColors.border, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.chat_outlined, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Pix Copia e Cola (Ideal para enviar no WhatsApp com o valor exato do pedido):',
                                style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.content_copy_rounded, size: 14),
                              label: const Text('Copiar Pix Copia e Cola', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final valorReais = widget.controller.totalInCents / 100.0;
                                final payload = PixGenerator.gerarCopiaCola(
                                  chave: effectivePixChave,
                                  favorecido: effectivePixFavorecido.isNotEmpty ? effectivePixFavorecido : 'Estabelecimento',
                                  cidade: 'Sorocaba',
                                  valor: valorReais,
                                  tipoChave: effectivePixTipo,
                                );
                                Clipboard.setData(ClipboardData(text: payload));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF10B981),
                                    content: Text('Código Pix Copia e Cola de R\$ ${valorReais.toStringAsFixed(2)} copiado para o WhatsApp!'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Sub-opções quando CARTÃO está ativo ───────────────────
              if (activeCategory == 'Cartão') ...[
                const SizedBox(height: 20),
                const Text(
                  'SELECIONE O TIPO / BANDEIRA DO CARTÃO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                if (cartaoFormas.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cartaoFormas.map((forma) {
                      final isSelected = selectedForma?.id == forma.id || activePaymentMethod == forma.nome;
                      final bandeiraInfo = (forma.bandeiraPadrao != null && forma.bandeiraPadrao!.isNotEmpty) ? ' • ${forma.bandeiraPadrao}' : '';
                      return ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          forma.tipo == TipoFormaPagamento.cartaoCredito ? Icons.credit_score_rounded : Icons.credit_card_rounded,
                          size: 16,
                          color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                        ),
                        label: Text('${forma.nome}$bandeiraInfo'),
                        selectedColor: FincoreColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected ? FincoreColors.primary : FincoreColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectFormaPagamento(forma);
                          }
                        },
                      );
                    }).toList(),
                  )
                else
                  Row(
                    children: [
                      _buildFallbackSubPaymentChip('Débito'),
                      const SizedBox(width: 8),
                      _buildFallbackSubPaymentChip('Crédito'),
                      const SizedBox(width: 8),
                      _buildFallbackSubPaymentChip('Parcelado'),
                    ],
                  ),
              ],

              // ── Sub-opções quando DINHEIRO está ativo ─────────────────
              if (activeCategory == 'Dinheiro') ...[
                if (dinheiroFormas.length > 1) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'OPÇÃO DE DINHEIRO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dinheiroFormas.map((forma) {
                      final isSelected = selectedForma?.id == forma.id || activePaymentMethod == forma.nome;
                      return ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          Icons.payments_outlined,
                          size: 16,
                          color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                        ),
                        label: Text(forma.nome),
                        selectedColor: FincoreColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected ? FincoreColors.primary : FincoreColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectFormaPagamento(forma);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],

                // Campo de Troco para Dinheiro
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _trocoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Troco para (R\$)',
                          hintText: 'Ex: 50.00',
                          prefixIcon: Icon(Icons.attach_money, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sugestões de Troco:', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildTrocoQuickButton('Sem Troco', 0),
                              _buildTrocoQuickButton('R\$ 20', 20),
                              _buildTrocoQuickButton('R\$ 50', 50),
                              _buildTrocoQuickButton('R\$ 100', 100),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // ── Sub-opções quando NOTA A PRAZO está ativo ──────────────
              if (activeCategory == 'NotaPrazo') ...[
                const SizedBox(height: 20),
                const Text(
                  'OPÇÃO DE NOTA A PRAZO / FATURADO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                if (notaPrazoFormas.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: notaPrazoFormas.map((forma) {
                      final isSelected = selectedForma?.id == forma.id || activePaymentMethod == forma.nome;
                      return ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: isSelected ? const Color(0xFF6366F1) : FincoreColors.textSecondary,
                        ),
                        label: Text(forma.nome),
                        selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF818CF8) : FincoreColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF6366F1) : FincoreColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectFormaPagamento(forma);
                          }
                        },
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    'Utilizando faturamento em Nota a Prazo.',
                    style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                  ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.assignment_outlined, size: 20, color: Color(0xFF818CF8)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nota a Prazo: o cliente apenas retira/recebe com o comprovante assinado e o valor fica registrado no Contas a Receber para liquidação posterior.',
                          style: TextStyle(fontSize: 11.5, color: FincoreColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Sub-opções quando OUTROS / INTERNO está ativo ─────────
              if (activeCategory == 'Outros' && outrosFormas.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'SELECIONE A FORMA DE PAGAMENTO / CONVÊNIO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: outrosFormas.map((forma) {
                    final isSelected = selectedForma?.id == forma.id || activePaymentMethod == forma.nome;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        forma.isUsoInterno || forma.tipo == TipoFormaPagamento.consumoInterno
                            ? Icons.restaurant_outlined
                            : Icons.card_giftcard_outlined,
                        size: 16,
                        color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                      ),
                      label: Text(forma.nome),
                      selectedColor: FincoreColors.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected ? FincoreColors.primary : FincoreColors.border,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          controller.selectFormaPagamento(forma);
                        }
                      },
                    );
                  }).toList(),
                ),

                if (selectedForma?.isUsoInterno == true || selectedForma?.tipo == TipoFormaPagamento.consumoInterno) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FincoreColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: FincoreColors.warning, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Forma de Consumo / Uso Interno: não gera receita financeira no caixa e baixa o estoque normalmente.',
                            style: TextStyle(fontSize: 11, color: FincoreColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // Observações do Pedido
              TextField(
                controller: _obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações do Pedido',
                  hintText: 'Ex: Salgados bem fritos, entregar na porta lateral...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String label,
    String? badgeText,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? FincoreColors.primary.withValues(alpha: 0.1) : FincoreColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? FincoreColors.primary : FincoreColors.border,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(height: 3),
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? FincoreColors.primary : FincoreColors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrocoQuickButton(String label, double valor) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: FincoreColors.textPrimary,
        side: const BorderSide(color: FincoreColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        if (valor == 0) {
          _trocoCtrl.clear();
        } else {
          _trocoCtrl.text = valor.toStringAsFixed(2);
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildFallbackSubPaymentChip(String tipoCartao) {
    final target = 'Cartão ($tipoCartao)';
    final isSelected = widget.controller.paymentMethod == target;

    return ChoiceChip(
      selected: isSelected,
      label: Text(tipoCartao),
      onSelected: (selected) {
        if (selected) {
          widget.controller.setPaymentMethod(target);
        }
      },
    );
  }
}
