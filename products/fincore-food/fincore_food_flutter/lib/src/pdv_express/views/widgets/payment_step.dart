import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../controllers/pdv_express_controller.dart';

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
        trocoParaCentavos: () => (trocoReais * 100).round(),
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
    final pagamento = widget.controller.paymentMethod;

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
              const Row(
                children: [
                  Icon(Icons.payment_outlined, color: FincoreColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PAGAMENTO & OBSERVAÇÕES',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const Divider(color: FincoreColors.border, height: 24),

              // Opções de Pagamento Primárias
              Row(
                children: [
                  _buildPaymentCard(
                    label: 'Pix',
                    icon: Icons.qr_code_scanner_outlined,
                    isSelected: pagamento.startsWith('PIX'),
                    onTap: () {
                      widget.controller.setPaymentMethod('PIX');
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildPaymentCard(
                    label: 'Cartão',
                    icon: Icons.credit_card_outlined,
                    isSelected: pagamento.startsWith('Cartão'),
                    onTap: () {
                      widget.controller.setPaymentMethod('Cartão (Débito)');
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildPaymentCard(
                    label: 'Dinheiro',
                    icon: Icons.payments_outlined,
                    isSelected: pagamento.startsWith('Dinheiro'),
                    onTap: () {
                      widget.controller.setPaymentMethod('Dinheiro');
                    },
                  ),
                ],
              ),

              // Sub-opções de Cartão
              if (pagamento.startsWith('Cartão')) ...[
                const SizedBox(height: 20),
                const Text(
                  'TIPO DE CARTÃO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSubPaymentChip('Débito'),
                    const SizedBox(width: 8),
                    _buildSubPaymentChip('Crédito'),
                    const SizedBox(width: 8),
                    _buildSubPaymentChip('Parcelado'),
                  ],
                ),
              ],

              // Painel de Cópia da Chave Pix
              if (pagamento.startsWith('PIX')) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FincoreColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, color: FincoreColors.accent),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chave Pix para Pagamento (CNPJ):',
                              style: TextStyle(
                                fontSize: 11,
                                color: FincoreColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '12.345.678/0001-90',
                              style: TextStyle(
                                fontSize: 13,
                                color: FincoreColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: FincoreColors.accent),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '12.345.678/0001-90'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: FincoreColors.success,
                              content: Text('Chave Pix copiada com sucesso!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Campo de Troco para Dinheiro
              if (pagamento == 'Dinheiro') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _trocoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Troco para (R\$)',
                      hintText: 'Ex: 50.00',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

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
          padding: const EdgeInsets.symmetric(vertical: 20),
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
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubPaymentChip(String tipoCartao) {
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
