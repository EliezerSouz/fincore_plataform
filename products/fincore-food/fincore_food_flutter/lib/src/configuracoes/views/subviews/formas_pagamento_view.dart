import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/forma_pagamento_repository.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';

int _extrairPrazoDias(String? texto, [String? fallbackNome]) {
  final combined = '${texto ?? ''} ${fallbackNome ?? ''}';
  final match = RegExp(r'prazo[:\s=_-]*(\d+)', caseSensitive: false).firstMatch(combined) ??
      RegExp(r'(\d+)\s*dias?', caseSensitive: false).firstMatch(combined);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 7;
  }
  return 7;
}

double _extrairTaxaMdr(String? texto, [String? fallbackNome]) {
  final combined = '${texto ?? ''} ${fallbackNome ?? ''}';
  final match = RegExp(r'taxa[:\s=_-]*([0-9]+(?:[\.,][0-9]+)?)\s*%', caseSensitive: false).firstMatch(combined) ??
      RegExp(r'([0-9]+(?:[\.,][0-9]+)?)\s*%', caseSensitive: false).firstMatch(combined);
  if (match != null) {
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
  }
  return 0.0;
}

int _extrairPrazoRepasse(String? texto, [TipoFormaPagamento? tipo, String? fallbackNome]) {
  final combined = '${texto ?? ''} ${fallbackNome ?? ''}';
  final match = RegExp(r'repasse[:\s=_-]*(\d+)', caseSensitive: false).firstMatch(combined) ??
      RegExp(r'd\+(\d+)', caseSensitive: false).firstMatch(combined);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? (tipo == TipoFormaPagamento.cartaoDebito ? 1 : 30);
  }
  if (tipo == TipoFormaPagamento.cartaoDebito) return 1;
  if (tipo == TipoFormaPagamento.cartaoCredito) return 30;
  return 0;
}

String _extrairTipoDiasRepasse(String? texto, [TipoFormaPagamento? tipo]) {
  final t = (texto ?? '').toLowerCase();
  if (t.contains('útil') || t.contains('uteis') || t.contains('util')) return 'úteis';
  if (t.contains('corrid')) return 'corridos';
  if (tipo == TipoFormaPagamento.cartaoDebito) return 'úteis';
  return 'corridos';
}

class FormasPagamentoView extends StatefulWidget {
  final VoidCallback? onChanged;

  const FormasPagamentoView({super.key, this.onChanged});

  @override
  State<FormasPagamentoView> createState() => _FormasPagamentoViewState();
}

class _FormasPagamentoViewState extends State<FormasPagamentoView> {
  late final FormaPagamentoRepository _repo;
  late final TenantContext _tenantCtx;
  List<FormaPagamento> _formas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = DependencyInjection().get<FormaPagamentoRepository>();
    _tenantCtx = DependencyInjection().get<TenantContext>();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.findAll();
      setState(() {
        _formas = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[FormasPagamentoView] Erro ao carregar: $e');
      setState(() => _loading = false);
    }
  }

  void _abrirModal([FormaPagamento? forma]) {
    final nomeCtrl = TextEditingController(text: forma?.nome ?? '');
    final rawDescricao = forma?.descricao ?? '';
    final cleanDescricao = rawDescricao
        .replaceAll(RegExp(r'\[Prazo:\s*\d+\s*dias?\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[Taxa:\s*[0-9]+(?:[\.,][0-9]+)?\s*%\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[Repasse:\s*\d+\s*dias(?:\s+[a-zà-ú]+)?\]\s*', caseSensitive: false), '')
        .trim();
    final descricaoCtrl = TextEditingController(text: cleanDescricao);
    final prazoDiasCtrl = TextEditingController(text: '${_extrairPrazoDias(forma?.descricao, forma?.nome)}');

    TipoFormaPagamento tipo = forma?.tipo ?? TipoFormaPagamento.outro;
    final taxaMdrInicial = forma != null ? _extrairTaxaMdr(forma.descricao, forma.nome) : (tipo == TipoFormaPagamento.cartaoDebito ? 1.29 : (tipo == TipoFormaPagamento.cartaoCredito ? 2.99 : 0.0));
    final taxaMdrCtrl = TextEditingController(text: taxaMdrInicial > 0 ? taxaMdrInicial.toString().replaceAll('.', ',') : '');
    final prazoRepasseCtrl = TextEditingController(text: '${_extrairPrazoRepasse(forma?.descricao, tipo, forma?.nome)}');
    String tipoDiasRepasse = _extrairTipoDiasRepasse(forma?.descricao, tipo);

    final pixChaveCtrl = TextEditingController(text: forma?.pixChave ?? '');
    final pixTipoBancoCtrl = TextEditingController(text: forma?.pixTipoBanco ?? '');
    String pixTipoChave = forma?.pixTipoChave ?? 'CPF';
    String? bandeira = forma?.bandeiraPadrao;
    bool ativo = forma?.ativo ?? true;
    bool permiteTroco = forma?.permiteTroco ?? false;
    bool isUsoInterno = forma?.isUsoInterno ?? false;
    bool movimentaFinanceiro = forma?.movimentaFinanceiro ?? true;
    bool movimentaEstoque = forma?.movimentaEstoque ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            backgroundColor: FincoreColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              forma == null ? 'Nova Forma de Pagamento' : 'Editar Forma de Pagamento',
              style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FincoreFieldLabel(label: 'NOME DE EXIBIÇÃO', isRequired: true),
                      FincoreTextField(
                        controller: nomeCtrl,
                        hintText: 'Ex: PIX Nubank, Cartão Stone Débito, Faturado 15 Dias, Consumo Interno',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'TIPO DE PAGAMENTO'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: FincoreColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: FincoreColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<TipoFormaPagamento>(
                                      value: tipo,
                                      isExpanded: true,
                                      dropdownColor: FincoreColors.surface,
                                      items: TipoFormaPagamento.values.map((t) {
                                        String label = switch (t) {
                                          TipoFormaPagamento.dinheiro => 'Dinheiro',
                                          TipoFormaPagamento.pix => 'PIX',
                                          TipoFormaPagamento.cartaoCredito => 'Cartão de Crédito',
                                          TipoFormaPagamento.cartaoDebito => 'Cartão de Débito',
                                          TipoFormaPagamento.notaPrazo => 'Nota a Prazo / Faturado',
                                          TipoFormaPagamento.consumoInterno => 'Consumo / Uso Interno',
                                          TipoFormaPagamento.outro => 'Outro / Manual',
                                        };
                                        return DropdownMenuItem(value: t, child: Text(label, style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary)));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            tipo = val;
                                            if (val == TipoFormaPagamento.consumoInterno) {
                                              isUsoInterno = true;
                                              movimentaFinanceiro = false;
                                              movimentaEstoque = true;
                                              permiteTroco = false;
                                            } else if (val == TipoFormaPagamento.dinheiro) {
                                              permiteTroco = true;
                                            } else if (val == TipoFormaPagamento.notaPrazo) {
                                              isUsoInterno = false;
                                              movimentaFinanceiro = true;
                                              permiteTroco = false;
                                            } else if (val == TipoFormaPagamento.cartaoDebito) {
                                              if (taxaMdrCtrl.text.isEmpty) taxaMdrCtrl.text = '1,29';
                                              prazoRepasseCtrl.text = '1';
                                              tipoDiasRepasse = 'úteis';
                                            } else if (val == TipoFormaPagamento.cartaoCredito) {
                                              if (taxaMdrCtrl.text.isEmpty) taxaMdrCtrl.text = '2,99';
                                              prazoRepasseCtrl.text = '30';
                                              tipoDiasRepasse = 'corridos';
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'BANDEIRA PADRÃO (OPCIONAL)'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: FincoreColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: FincoreColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: bandeira,
                                      isExpanded: true,
                                      dropdownColor: FincoreColors.surface,
                                      hint: const Text('Nenhuma / Padrão', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
                                      items: [
                                        const DropdownMenuItem(value: null, child: Text('Nenhuma / Padrão', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted))),
                                        ...['Visa', 'Mastercard', 'Elo', 'Hipercard', 'Amex', 'VR / VA', 'Alelo', 'Sodexo']
                                            .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary)))),
                                      ],
                                      onChanged: (val) => setModalState(() => bandeira = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── Seção específica quando tipo == PIX ─────────────────
                      if (tipo == TipoFormaPagamento.pix) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.pix_outlined, size: 16, color: Color(0xFF10B981)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Configuração da Chave PIX',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const FincoreFieldLabel(label: 'TIPO DE CHAVE'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: FincoreColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: FincoreColors.border),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: ['CPF', 'CNPJ', 'Celular', 'E-mail', 'Aleatória (EVP)'].contains(pixTipoChave)
                                                  ? pixTipoChave
                                                  : 'CPF',
                                              isExpanded: true,
                                              dropdownColor: FincoreColors.surface,
                                              items: ['CPF', 'CNPJ', 'Celular', 'E-mail', 'Aleatória (EVP)'].map((k) {
                                                return DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary)));
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setModalState(() => pixTipoChave = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const FincoreFieldLabel(label: 'INSTITUIÇÃO / BANCO'),
                                        FincoreTextField(
                                          controller: pixTipoBancoCtrl,
                                          hintText: 'Ex: Nubank, BB, Inter, Mercado Pago',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const FincoreFieldLabel(label: 'CHAVE PIX'),
                              FincoreTextField(
                                controller: pixChaveCtrl,
                                hintText: 'Informe a chave (ex: 123.456.789-00 ou contato@loja.com)',
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Esta chave será impressa no cupom fiscal/não-fiscal e utilizada na cobrança quando esta forma de PIX for escolhida.',
                                style: TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Seção específica quando tipo == CARTÃO (DÉBITO OU CRÉDITO) ──
                      if (tipo == TipoFormaPagamento.cartaoDebito || tipo == TipoFormaPagamento.cartaoCredito) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.credit_card_rounded, size: 16, color: Color(0xFF0284C7)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Parâmetros da Maquininha / Adquirente & Partidas Dobradas',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const FincoreFieldLabel(label: 'TAXA MDR (%)'),
                                        FincoreTextField(
                                          controller: taxaMdrCtrl,
                                          hintText: tipo == TipoFormaPagamento.cartaoDebito ? '1,29' : '2,99',
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const FincoreFieldLabel(label: 'PRAZO REPASSE (DIAS)'),
                                        FincoreTextField(
                                          controller: prazoRepasseCtrl,
                                          hintText: tipo == TipoFormaPagamento.cartaoDebito ? '1' : '30',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const FincoreFieldLabel(label: 'TIPO DE CONTAGEM'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: FincoreColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: FincoreColors.border),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: tipoDiasRepasse,
                                              isExpanded: true,
                                              dropdownColor: FincoreColors.surface,
                                              items: const [
                                                DropdownMenuItem(value: 'úteis', child: Text('Dias Úteis', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary))),
                                                DropdownMenuItem(value: 'corridos', child: Text('Dias Corridos', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary))),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setModalState(() => tipoDiasRepasse = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ao vender neste cartão, o valor entra no Contas a Receber da Adquirente (não entra dinheiro no caixa físico) e a data de vencimento/previsão bancária é calculada automaticamente.',
                                style: TextStyle(fontSize: 10.5, color: FincoreColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Seção específica quando tipo == NOTA A PRAZO ─────────
                      if (tipo == TipoFormaPagamento.notaPrazo) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF6366F1)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Parâmetros de Faturamento & Vencimento',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const FincoreFieldLabel(label: 'PRAZO DE PAGAMENTO (DIAS)'),
                                        FincoreTextField(
                                          controller: prazoDiasCtrl,
                                          hintText: 'Ex: 5, 10, 15, 30',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'O vencimento no Contas a Receber será calculado somando este prazo à Data de Entrega do pedido (Ex: Entrega dia 10 + 5 dias = Vencimento dia 15).',
                                style: TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const FincoreFieldLabel(label: 'OBSERVAÇÕES / DESCRIÇÃO'),
                      FincoreTextField(
                        controller: descricaoCtrl,
                        hintText: 'Ex: Maquininha Stone balcão ou entrega',
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: FincoreColors.border),
                      const SizedBox(height: 8),

                      // Switches Operacionais
                      SwitchListTile(
                        value: isUsoInterno,
                        activeColor: const Color(0xFFF59E0B),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Consumo / Uso Interno (Não gera receita financeira)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        subtitle: const Text('Ideal para confraternizações, degustação ou almoço da equipe. Baixa o estoque sem entrar no caixa.', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                        onChanged: (v) {
                          setModalState(() {
                            isUsoInterno = v;
                            if (v) {
                              movimentaFinanceiro = false;
                              permiteTroco = false;
                            } else {
                              movimentaFinanceiro = true;
                            }
                          });
                        },
                      ),
                      SwitchListTile(
                        value: movimentaFinanceiro,
                        activeColor: FincoreColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Movimenta Financeiro (Entra no Caixa / Contas a Receber)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        subtitle: const Text('Gera lançamento de receita financeira na baixa do Contas a Receber ou no fechamento.', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                        onChanged: isUsoInterno ? null : (v) => setModalState(() => movimentaFinanceiro = v),
                      ),
                      SwitchListTile(
                        value: movimentaEstoque,
                        activeColor: FincoreColors.success,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Movimenta Estoque (Baixa de Produtos)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        subtitle: const Text('Consome as unidades dos produtos do estoque físico/produção.', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                        onChanged: (v) => setModalState(() => movimentaEstoque = v),
                      ),
                      SwitchListTile(
                        value: permiteTroco,
                        activeColor: FincoreColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Permite Troco no PDV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        subtitle: const Text('Habilita o campo de cálculo de troco para o operador de caixa.', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                        onChanged: isUsoInterno ? null : (v) => setModalState(() => permiteTroco = v),
                      ),
                      SwitchListTile(
                        value: ativo,
                        activeColor: FincoreColors.success,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Forma de Pagamento Ativa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        onChanged: (v) => setModalState(() => ativo = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final now = DateTime.now().toUtc();
                  final id = forma?.id ?? const Uuid().v4();

                  String? finalDescricao = descricaoCtrl.text.trim().isEmpty ? null : descricaoCtrl.text.trim();
                  if (tipo == TipoFormaPagamento.notaPrazo) {
                    final dias = int.tryParse(prazoDiasCtrl.text.trim()) ?? 7;
                    final prefixoPrazo = '[Prazo: $dias dias]';
                    finalDescricao = finalDescricao != null ? '$prefixoPrazo $finalDescricao' : prefixoPrazo;
                  } else if (tipo == TipoFormaPagamento.cartaoDebito || tipo == TipoFormaPagamento.cartaoCredito) {
                    final taxa = double.tryParse(taxaMdrCtrl.text.trim().replaceAll(',', '.')) ?? (tipo == TipoFormaPagamento.cartaoDebito ? 1.29 : 2.99);
                    final dias = int.tryParse(prazoRepasseCtrl.text.trim()) ?? (tipo == TipoFormaPagamento.cartaoDebito ? 1 : 30);
                    final prefixoCartao = '[Taxa: ${taxa.toStringAsFixed(2)}%] [Repasse: $dias dias $tipoDiasRepasse]';
                    finalDescricao = finalDescricao != null ? '$prefixoCartao $finalDescricao' : prefixoCartao;
                  }

                  final nova = FormaPagamento(
                    id: id,
                    tenantId: _tenantCtx.tenantId,
                    nome: nomeCtrl.text.trim(),
                    tipo: tipo,
                    ordem: forma?.ordem ?? (_formas.length + 1),
                    ativo: ativo,
                    permiteTroco: permiteTroco,
                    isUsoInterno: isUsoInterno,
                    movimentaFinanceiro: movimentaFinanceiro,
                    movimentaEstoque: movimentaEstoque,
                    bandeiraPadrao: bandeira,
                    descricao: finalDescricao,
                    pixChave: tipo == TipoFormaPagamento.pix && pixChaveCtrl.text.trim().isNotEmpty ? pixChaveCtrl.text.trim() : null,
                    pixTipoChave: tipo == TipoFormaPagamento.pix ? pixTipoChave : null,
                    pixTipoBanco: tipo == TipoFormaPagamento.pix && pixTipoBancoCtrl.text.trim().isNotEmpty ? pixTipoBancoCtrl.text.trim() : null,
                    metadata: forma?.metadata.copyWith(updatedAt: now) ??
                        SyncMetadata(
                          version: 1,
                          createdAt: now,
                          updatedAt: now,
                          createdBy: _tenantCtx.usuario.id,
                          updatedBy: _tenantCtx.usuario.id,
                          syncStatus: SyncStatus.pending,
                        ),
                  );

                  await _repo.save(nova);
                  if (mounted) {
                    _carregar();
                    widget.onChanged?.call();
                    Navigator.of(ctx).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(forma == null ? 'Cadastrar' : 'Salvar', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _excluir(FormaPagamento forma) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: const Text('Excluir Forma de Pagamento', style: TextStyle(color: FincoreColors.textPrimary)),
        content: Text('Deseja realmente desativar "${forma.nome}"?', style: const TextStyle(color: FincoreColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.danger, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.delete(forma.id);
      if (mounted) {
        _carregar();
        widget.onChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FincoreSectionCard(
          title: 'Formas de Pagamento Cadastradas',
          subtitle: 'Gerencie os métodos aceitos, taxas, prazos e parâmetros de PIX por conta',
          icon: Icons.payments_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formas.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Nenhuma forma de pagamento cadastrada',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _formas.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final forma = _formas[index];
                    final isUsoInterno = forma.isUsoInterno;
                    final isNotaPrazo = forma.tipo == TipoFormaPagamento.notaPrazo;
                    final prazo = isNotaPrazo ? _extrairPrazoDias(forma.descricao, forma.nome) : null;
                    final isCartao = forma.tipo == TipoFormaPagamento.cartaoDebito || forma.tipo == TipoFormaPagamento.cartaoCredito;
                    final taxaCartao = isCartao ? _extrairTaxaMdr(forma.descricao, forma.nome) : 0.0;
                    final repasseCartao = isCartao ? _extrairPrazoRepasse(forma.descricao, forma.tipo, forma.nome) : 0;
                    final tipoDiasCartao = isCartao ? _extrairTipoDiasRepasse(forma.descricao, forma.tipo) : 'corridos';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUsoInterno
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                              : isNotaPrazo
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                                  : FincoreColors.border,
                          width: (isUsoInterno || isNotaPrazo) ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (isUsoInterno
                                      ? const Color(0xFFF59E0B)
                                      : isNotaPrazo
                                          ? const Color(0xFF6366F1)
                                          : FincoreColors.primary)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUsoInterno
                                  ? Icons.restaurant_menu_rounded
                                  : isNotaPrazo
                                      ? Icons.calendar_month_outlined
                                      : (forma.tipo == TipoFormaPagamento.pix
                                          ? Icons.pix_outlined
                                          : (forma.tipo == TipoFormaPagamento.dinheiro
                                              ? Icons.payments_outlined
                                              : Icons.credit_card_outlined)),
                              size: 18,
                              color: isUsoInterno
                                  ? const Color(0xFFF59E0B)
                                  : isNotaPrazo
                                      ? const Color(0xFF6366F1)
                                      : FincoreColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      forma.nome,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: forma.ativo ? FincoreColors.textPrimary : FincoreColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isUsoInterno)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('USO INTERNO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                                      ),
                                    if (isNotaPrazo) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('A PRAZO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                                        ),
                                        child: Text('Prazo: $prazo dias', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                                      ),
                                    ],
                                    if (isCartao) ...[
                                      if (taxaCartao > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('MDR: ${taxaCartao.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                        ),
                                      ],
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                        ),
                                        child: Text('Repasse: D+$repasseCartao $tipoDiasCartao', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                      ),
                                    ],
                                     if (forma.bandeiraPadrao != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(forma.bandeiraPadrao!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                                      ),
                                    ],
                                    if (forma.tipo == TipoFormaPagamento.pix && forma.pixTipoBanco != null && forma.pixTipoBanco!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(forma.pixTipoBanco!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      ),
                                    ],
                                  ],
                                ),
                                if (forma.tipo == TipoFormaPagamento.pix && forma.pixChave != null && forma.pixChave!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '🔑 PIX (${forma.pixTipoChave ?? 'Chave'}): ${forma.pixChave}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      forma.movimentaFinanceiro ? '• Movimenta Financeiro' : '• Sem Caixa (R\$ 0)',
                                      style: TextStyle(fontSize: 11, color: forma.movimentaFinanceiro ? FincoreColors.success : FincoreColors.textMuted),
                                    ),
                                    Text(
                                      forma.movimentaEstoque ? '• Baixa Estoque' : '• Sem Baixa',
                                      style: TextStyle(fontSize: 11, color: forma.movimentaEstoque ? FincoreColors.primary : FincoreColors.textMuted),
                                    ),
                                    if (forma.permiteTroco)
                                      const Text('• Permite Troco', style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: FincoreColors.textSecondary),
                            onPressed: () => _abrirModal(forma),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: FincoreColors.danger),
                            onPressed: () => _excluir(forma),
                            tooltip: 'Excluir',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _abrirModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.primary.withValues(alpha: 0.15),
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.add_rounded, size: 18, color: FincoreColors.primary),
                label: Text('Adicionar Forma de Pagamento', style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

