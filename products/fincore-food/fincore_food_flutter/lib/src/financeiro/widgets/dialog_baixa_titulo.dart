import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../controllers/contas_receber_controller.dart';
import '../../shared/presentation/widgets/pedido_mirror_dialog.dart';

class DialogBaixaTitulo extends StatefulWidget {
  final TituloReceber item;
  final ContasReceberController controller;

  const DialogBaixaTitulo({
    super.key,
    required this.item,
    required this.controller,
  });

  static Future<bool> show(
    BuildContext context, {
    required TituloReceber item,
    required ContasReceberController controller,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogBaixaTitulo(
        item: item,
        controller: controller,
      ),
    );
    return result ?? false;
  }

  @override
  State<DialogBaixaTitulo> createState() => _DialogBaixaTituloState();
}

class _DialogBaixaTituloState extends State<DialogBaixaTitulo> {
  final _obsCtrl = TextEditingController();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late DateTime _dataPagamento;
  String _formaQuitacaoSelecionada = 'PIX';
  bool _loading = false;

  final List<String> _opcoesMeioPagamento = const [
    'PIX',
    'Dinheiro',
    'Cartão de Débito',
    'Cartão de Crédito',
    'Transferência Bancária',
  ];

  @override
  void initState() {
    super.initState();
    _dataPagamento = DateTime.now();
    if (widget.item.isCartao) {
      _formaQuitacaoSelecionada = widget.item.tipoModalidadePadronizada;
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  String _fmt(int centavos) => _moeda.format(centavos / 100);

  Future<void> _selecionarDataPagamento() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dataPagamento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: FincoreColors.surface,
              onSurface: FincoreColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataPagamento),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF10B981),
                onPrimary: Colors.white,
                surface: FincoreColors.surface,
                onSurface: FincoreColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _dataPagamento = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _dataPagamento = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _dataPagamento.hour,
            _dataPagamento.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.price_check_rounded, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmar Liquidação de Título',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Registrar recebimento financeiro no caixa',
                  style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FincoreColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pedido:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                      Row(
                        children: [
                          Text(
                            item.friendlyNumeroPedido,
                            style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              PedidoMirrorDialog.show(
                                context,
                                pedidoId: item.pedidoId,
                                numeroPedido: item.numeroPedido,
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: FincoreColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 12, color: FincoreColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ver Pedido',
                                    style: TextStyle(color: FincoreColors.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cliente:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                      Text(item.clienteNome, style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Data do Pedido:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                      Text(_dateFormat.format(item.dataEmissao), style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Data da Entrega:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                      Text(_dateFormat.format(item.dataEntrega), style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Forma Original:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                      Text(item.formaPagamentoNome, style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  const Divider(color: FincoreColors.border, height: 18),
                  if (item.isCartao && item.valorTaxaCentavos > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor Bruto (Maquininha):', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                        Text(_fmt(item.valorTotalCentavos), style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Taxa MDR (${item.taxaMdrPercentual.toStringAsFixed(2)}%):', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        Text('- ${_fmt(item.valorTaxaCentavos)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Líquido a Entrar no Banco:', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          _fmt(item.valorLiquidoCentavos),
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor a Quitar:', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          _fmt(item.valorTotalCentavos),
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Seleção de Meio de Pagamento para Baixa/Quitação
            if (item.isNotaPrazo) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Meio de Pagamento Usado:',
                    style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: FincoreColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _opcoesMeioPagamento.contains(_formaQuitacaoSelecionada) ? _formaQuitacaoSelecionada : _opcoesMeioPagamento.first,
                        dropdownColor: FincoreColors.surfaceElevated,
                        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                        items: _opcoesMeioPagamento.map((op) {
                          return DropdownMenuItem<String>(
                            value: op,
                            child: Text(op),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _formaQuitacaoSelecionada = v);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Seleção da Data de Pagamento / Liquidação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data do Pagamento:',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: _selecionarDataPagamento,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FincoreColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          _dateFormat.format(_dataPagamento),
                          style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_calendar_outlined, size: 12, color: FincoreColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text(
              'Observações da Baixa (Opcional):',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _obsCtrl,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ex: Confirmado no extrato bancário / PIX recebido no ato',
                hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: FincoreColors.primary)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  setState(() => _loading = true);
                  final ok = await widget.controller.darBaixa(
                    widget.item,
                    observacao: _obsCtrl.text.trim(),
                    dataBaixa: _dataPagamento,
                    formaPagamentoQuitacaoNome: item.isNotaPrazo ? _formaQuitacaoSelecionada : null,
                  );
                  if (mounted) {
                    nav.pop(ok);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar Baixa', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
