import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';
import '../../models/pedido_draft.dart';

/// Modal para Divisão de Pagamento (Split Payment - AUD-006).
///
/// Permite que o operador fracione a conta entre múltiplas formas de pagamento
/// (ex: R$ 60,00 no Cartão + R$ 40,00 em Dinheiro), calculando o saldo faltante
/// em tempo real e troco na fatia em dinheiro.
class SplitPaymentModal extends StatefulWidget {
  final PdvExpressController controller;

  const SplitPaymentModal({super.key, required this.controller});

  static Future<bool?> show(BuildContext context, PdvExpressController controller) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SplitPaymentModal(controller: controller),
    );
  }

  @override
  State<SplitPaymentModal> createState() => _SplitPaymentModalState();
}

class _SplitPaymentModalState extends State<SplitPaymentModal> {
  late final List<PagamentoItemDraft> _fatias;
  FormaPagamento? _formaSelecionada;
  final _valorCtrl = TextEditingController();
  final _trocoCtrl = TextEditingController();
  final _bandeiraCtrl = TextEditingController();
  final _nsuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se o controller já tinha fatias, clona para edição local
    _fatias = List<PagamentoItemDraft>.from(widget.controller.splitPayments);

    // Se estiver vazio e houver formas, seleciona a primeira e preenche com o restante
    if (widget.controller.formasPagamento.isNotEmpty) {
      _formaSelecionada = widget.controller.selectedFormaPagamento ?? widget.controller.formasPagamento.first;
    }
    _preencherComRestante();
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _trocoCtrl.dispose();
    _bandeiraCtrl.dispose();
    _nsuCtrl.dispose();
    super.dispose();
  }

  int get _totalVendaCentavos => widget.controller.totalInCents;

  int get _totalAdicionadoCentavos => _fatias.fold<int>(0, (acc, p) => acc + p.valorCentavos);

  int get _restanteCentavos {
    final diff = _totalVendaCentavos - _totalAdicionadoCentavos;
    return diff > 0 ? diff : 0;
  }

  void _preencherComRestante() {
    if (_restanteCentavos > 0) {
      _valorCtrl.text = (_restanteCentavos / 100).toStringAsFixed(2);
    } else {
      _valorCtrl.clear();
    }
  }

  void _adicionarFatia() {
    final valorReais = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final valorCentavos = (valorReais * 100).round();

    if (valorCentavos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor válido maior que zero.'),
          backgroundColor: FincoreColors.warning,
        ),
      );
      return;
    }

    final nomeForma = _formaSelecionada?.nome ?? 'Dinheiro';
    final isDinheiro = nomeForma.toLowerCase().contains('dinheiro');

    int trocoCentavos = 0;
    if (isDinheiro && _trocoCtrl.text.isNotEmpty) {
      final recebido = double.tryParse(_trocoCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final recebidoCentavos = (recebido * 100).round();
      if (recebidoCentavos > valorCentavos) {
        trocoCentavos = recebidoCentavos - valorCentavos;
      }
    }

    final fatia = PagamentoItemDraft(
      formaPagamentoId: _formaSelecionada?.id,
      formaPagamentoNome: nomeForma,
      valorCentavos: valorCentavos,
      trocoCentavos: trocoCentavos,
      bandeira: _bandeiraCtrl.text.trim().isNotEmpty ? _bandeiraCtrl.text.trim() : null,
      nsu: _nsuCtrl.text.trim().isNotEmpty ? _nsuCtrl.text.trim() : null,
    );

    setState(() {
      _fatias.add(fatia);
      _bandeiraCtrl.clear();
      _nsuCtrl.clear();
      _trocoCtrl.clear();
      _preencherComRestante();
    });
  }

  void _removerFatia(int index) {
    setState(() {
      _fatias.removeAt(index);
      _preencherComRestante();
    });
  }

  void _salvarEFechar() {
    if (_restanteCentavos > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ainda faltam R\$ ${(_restanteCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')} para cobrir o total da venda.',
          ),
          backgroundColor: FincoreColors.danger,
        ),
      );
      return;
    }

    widget.controller.setSplitPayments(_fatias);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDinheiro = _formaSelecionada?.nome.toLowerCase().contains('dinheiro') ?? false;
    final isCartao = _formaSelecionada?.nome.toLowerCase().contains('cart') ?? false;
    final totalFormatado = (_totalVendaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final cobertoFormatado = (_totalAdicionadoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final restanteFormatado = (_restanteCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final estaQuitado = _totalAdicionadoCentavos >= _totalVendaCentavos;

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FincoreColors.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabeçalho ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FincoreColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.call_split_rounded, color: FincoreColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Dividir Pagamento (Múltiplas Formas)',
                        style: TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Adicione as fatias do pagamento até atingir o total do pedido.',
                        style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: FincoreColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(color: FincoreColors.border, height: 28),

            // ── Barra de Progresso / Resumo de Totais ────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: estaQuitado ? FincoreColors.success.withValues(alpha: 0.5) : FincoreColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalItem('TOTAL DA VENDA', 'R\$ $totalFormatado', FincoreColors.textPrimary),
                  _buildDividerVert(),
                  _buildTotalItem('VALOR COBERTO', 'R\$ $cobertoFormatado', FincoreColors.success),
                  _buildDividerVert(),
                  _buildTotalItem(
                    'RESTANTE A PAGAR',
                    'R\$ $restanteFormatado',
                    estaQuitado ? FincoreColors.textMuted : FincoreColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Lista de Fatias Já Adicionadas ───────────────────────────
            const Text(
              'FATIAS DE PAGAMENTO DEFINIDAS:',
              style: TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: _fatias.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.payment_outlined, size: 36, color: FincoreColors.textMuted),
                            SizedBox(height: 8),
                            Text(
                              'Nenhuma fatia adicionada ainda.',
                              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _fatias.length,
                        separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final f = _fatias[index];
                          final vFormatado = (f.valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: FincoreColors.primary.withValues(alpha: 0.2),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: FincoreColors.primary,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  f.formaPagamentoNome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: FincoreColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (f.bandeira != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FincoreColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: FincoreColors.border),
                                    ),
                                    child: Text(
                                      f.bandeira!,
                                      style: const TextStyle(fontSize: 10, color: FincoreColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: f.trocoCentavos > 0
                                ? Text(
                                    'Troco: R\$ ${(f.trocoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(fontSize: 11, color: FincoreColors.success),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'R\$ $vFormatado',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: FincoreColors.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: FincoreColors.danger, size: 20),
                                  onPressed: () => _removerFatia(index),
                                  tooltip: 'Remover esta fatia',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Formulário para Adicionar Nova Fatia ─────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADICIONAR FATIA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: FincoreColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Dropdown de Forma de Pagamento
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<FormaPagamento>(
                          value: _formaSelecionada,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Forma de Pagamento',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: widget.controller.formasPagamento.map((forma) {
                            return DropdownMenuItem<FormaPagamento>(
                              value: forma,
                              child: Text(
                                forma.nome,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (nova) {
                            setState(() {
                              _formaSelecionada = nova;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Campo de Valor da Fatia
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _valorCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Valor R\$',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            suffixIcon: _restanteCentavos > 0
                                ? Tooltip(
                                    message: 'Preencher restante',
                                    child: IconButton(
                                      icon: Icon(Icons.flash_on, size: 16, color: FincoreColors.primary),
                                      onPressed: _preencherComRestante,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão Adicionar
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        onPressed: _adicionarFatia,
                      ),
                    ],
                  ),

                  // Campos contextuais adicionais (Troco se Dinheiro, Bandeira se Cartão)
                  if (isDinheiro || isCartao) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isDinheiro) ...[
                          Expanded(
                            child: TextField(
                              controller: _trocoCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Valor Entregue pelo Cliente (Troco)',
                                hintText: '0,00',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ),
                        ],
                        if (isCartao) ...[
                          Expanded(
                            child: TextField(
                              controller: _bandeiraCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Bandeira (Ex: Visa, Master, Elo)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nsuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'NSU / Autorização (Opcional)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Rodapé de Ações ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    widget.controller.clearSplitPayments();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancelar / Usar Forma Única'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aplicar Fatias ao Pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: estaQuitado ? FincoreColors.success : FincoreColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: estaQuitado ? _salvarEFechar : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildDividerVert() {
    return Container(
      height: 30,
      width: 1,
      color: FincoreColors.border,
    );
  }
}
