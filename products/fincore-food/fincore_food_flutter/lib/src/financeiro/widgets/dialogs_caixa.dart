import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import '../controllers/financeiro_controller.dart';

class DialogAbrirCaixa extends StatefulWidget {
  final Future<void> Function(int valorCentavos, String nomeTurno) onConfirm;
  final FinanceiroController? controller;

  const DialogAbrirCaixa({
    super.key,
    required this.onConfirm,
    this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(int valorCentavos, String nomeTurno) onConfirm,
    FinanceiroController? controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogAbrirCaixa(
        onConfirm: onConfirm,
        controller: controller,
      ),
    );
  }

  @override
  State<DialogAbrirCaixa> createState() => _DialogAbrirCaixaState();
}

class _DialogAbrirCaixaState extends State<DialogAbrirCaixa> {
  final _ctrlValor = TextEditingController(text: '0');
  final _ctrlObs = TextEditingController();
  bool _loading = false;

  final List<int> _valoresRapidos = [0, 50, 100, 150, 200];

  @override
  void dispose() {
    _ctrlValor.dispose();
    _ctrlObs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turnoAnterior = widget.controller?.turnoDiaAnteriorAberto;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FincoreColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.point_of_sale_rounded, color: FincoreColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abertura de Caixa & Turno',
                  style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sequência e auditoria operacional do turno',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (turnoAnterior != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Atenção: Turno anterior ainda aberto!',
                              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Há uma sessão de caixa aberta em ${DateFormat('dd/MM/yyyy · HH:mm').format(turnoAnterior.dataAbertura.toLocal())}. Recomendamos fechar o turno pendente antes de abrir um novo.',
                              style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Informação de numeração automática
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: FincoreColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'O número do turno será gerado automaticamente em sequência para este dia operacional.',
                        style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Fundo de troco inicial em espécie na gaveta:',
                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Atalhos rápidos
              Wrap(
                spacing: 8,
                children: _valoresRapidos.map((v) {
                  return ActionChip(
                    label: Text('R\$ $v', style: const TextStyle(fontSize: 11.5)),
                    backgroundColor: FincoreColors.background,
                    side: const BorderSide(color: FincoreColors.border),
                    onPressed: () {
                      setState(() {
                        _ctrlValor.text = v.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _ctrlValor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Valor inicial em dinheiro (R\$)',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: FincoreColors.background,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _ctrlObs,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Observação opcional (ex: Terminal Balcão, Fundo Reserva)',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: FincoreColors.background,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final val = (double.tryParse(_ctrlValor.text.replaceAll(',', '.')) ?? 0) * 100;
                  final obs = _ctrlObs.text.trim();
                  await widget.onConfirm(val.toInt(), obs);
                  if (context.mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar & Abrir Caixa', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class DialogFecharCaixa extends StatefulWidget {
  final ResumoCaixa resumo;
  final FinanceiroController controller;
  final String Function(int) formatarValor;
  final Future<void> Function(int? valorContado, String? obs) onConfirm;

  const DialogFecharCaixa({
    super.key,
    required this.resumo,
    required this.controller,
    required this.formatarValor,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required ResumoCaixa resumo,
    required FinanceiroController controller,
    required String Function(int) formatarValor,
    required Future<void> Function(int? valorContado, String? obs) onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogFecharCaixa(
        resumo: resumo,
        controller: controller,
        formatarValor: formatarValor,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<DialogFecharCaixa> createState() => _DialogFecharCaixaState();
}

class _DialogFecharCaixaState extends State<DialogFecharCaixa> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ctrlDinheiroContado = TextEditingController();
  final Map<String, TextEditingController> _ctrlFormasMap = {};
  final _ctrlObs = TextEditingController();
  bool _loading = false;
  bool _imprimindo = false;

  final _dtFmt = DateFormat('HH:mm');
  final _dtFullFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final r = widget.resumo;
    for (final fp in r.vendasPorFormaPagamento.keys) {
      if (!fp.toLowerCase().contains('dinheiro') && !fp.toLowerCase().contains('especie')) {
        _ctrlFormasMap[fp] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrlDinheiroContado.dispose();
    for (final c in _ctrlFormasMap.values) {
      c.dispose();
    }
    _ctrlObs.dispose();
    super.dispose();
  }

  int _parseCentavos(String text) {
    if (text.trim().isEmpty) return 0;
    final clean = text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    return ((double.tryParse(clean) ?? 0) * 100).round();
  }

  IconData _getIconeModalidade(String modalidade) {
    final lower = modalidade.toLowerCase();
    if (lower.contains('pix')) return Icons.pix_rounded;
    if (lower.contains('créd') || lower.contains('cred')) return Icons.credit_card_rounded;
    if (lower.contains('déb') || lower.contains('deb') || lower.contains('cart')) return Icons.credit_card_outlined;
    if (lower.contains('prazo') || lower.contains('fiado') || lower.contains('faturad')) return Icons.receipt_long_rounded;
    if (lower.contains('vale') || lower.contains('refeição') || lower.contains('refeicao') || lower.contains('alimenta')) return Icons.food_bank_outlined;
    return Icons.payments_rounded;
  }

  Color _getCorModalidade(String modalidade) {
    final lower = modalidade.toLowerCase();
    if (lower.contains('pix')) return const Color(0xFF32BCAD);
    if (lower.contains('créd') || lower.contains('cred')) return const Color(0xFF0284C7);
    if (lower.contains('déb') || lower.contains('deb') || lower.contains('cart')) return const Color(0xFF3B82F6);
    if (lower.contains('prazo') || lower.contains('fiado')) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Future<void> _imprimirRelatorioFechamento() async {
    setState(() => _imprimindo = true);
    try {
      final r = widget.resumo;

      String empresaNome = 'FINCORE FOOD';
      try {
        if (TenantContext().hasContext) {
          empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
              ? TenantContext().empresa.nomeFantasia
              : TenantContext().empresa.razaoSocial;
        }
      } catch (_) {}

      final doc = pw.Document();
      final int espDinheiro = r.saldoEsperadoDinheiroCentavos;
      final int infDinheiro = _parseCentavos(_ctrlDinheiroContado.text);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    empresaNome.toUpperCase(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'FECHAMENTO DE TURNO / CAIXA',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('Operador: ${r.sessaoAtiva?.operadorNome ?? "Caixa"}', style: const pw.TextStyle(fontSize: 8.5)),
                if (r.sessaoAtiva?.observacoes != null)
                  pw.Text('${r.sessaoAtiva!.observacoes}', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text(
                  'Abertura: ${_dtFullFmt.format(r.sessaoAtiva?.dataAbertura.toLocal() ?? DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.Text(
                  'Fechamento: ${_dtFullFmt.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                pw.Text('RESUMO DO MOVIMENTO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 2),
                _pwRow('Fundo de Troco Inicial:', widget.formatarValor(r.fundoTrocoCentavos)),
                _pwRow('Vendas Totais (${r.qtdPedidos} pedidos):', widget.formatarValor(r.totalVendasCentavos)),
                _pwRow('Total Suprimentos (Reforço):', '+ ${widget.formatarValor(r.totalSuprimentosCentavos)}'),
                _pwRow('Total Sangrias (Retiradas):', '- ${widget.formatarValor(r.totalSangriasCentavos)}'),
                if (r.totalDespesasCentavos > 0)
                  _pwRow('Despesas Balcão:', '- ${widget.formatarValor(r.totalDespesasCentavos)}'),
                pw.SizedBox(height: 2),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                _pwRow('SALDO EM DINHEIRO (GAVETA):', widget.formatarValor(espDinheiro), isBold: true),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                pw.Text('VENDAS POR FORMA DE PAGAMENTO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 2),
                ...r.vendasPorFormaPagamento.entries.map((e) {
                  return _pwRow('• ${e.key}:', widget.formatarValor(e.value));
                }),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                pw.Text('CONFERENCIA FISICA / APURADA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 2),
                _pwRow('Dinheiro Contado:', infDinheiro > 0 ? widget.formatarValor(infDinheiro) : 'N/I'),
                if (infDinheiro > 0)
                  _pwRow('Diferença em Dinheiro:', widget.formatarValor(infDinheiro - espDinheiro), isBold: true),
                ..._ctrlFormasMap.entries.map((entry) {
                  final esp = r.vendasPorFormaPagamento[entry.key] ?? 0;
                  final inf = _parseCentavos(entry.value.text);
                  if (inf > 0) {
                    return _pwRow('${entry.key} Apurado:', '${widget.formatarValor(inf)} (Dif: ${widget.formatarValor(inf - esp)})');
                  }
                  return pw.SizedBox();
                }),

                if (_ctrlObs.text.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Divider(borderStyle: pw.BorderStyle.dashed),
                  pw.Text('OBSERVACOES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                  pw.Text(_ctrlObs.text.trim(), style: const pw.TextStyle(fontSize: 8)),
                ],

                pw.SizedBox(height: 14),
                pw.Center(child: pw.Text('____________________________________', style: const pw.TextStyle(fontSize: 8))),
                pw.Center(child: pw.Text('Assinatura do Operador de Caixa', style: const pw.TextStyle(fontSize: 8))),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text('FINCORE FOOD · Impresso em ${_dtFullFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 7))),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'Fechamento_Caixa_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: FincoreColors.danger, content: Text('Erro ao gerar impressão: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  pw.Widget _pwRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resumo;
    final int espDinheiro = r.saldoEsperadoDinheiroCentavos;
    final int infDinheiro = _parseCentavos(_ctrlDinheiroContado.text);
    final int difDinheiro = infDinheiro > 0 ? infDinheiro - espDinheiro : 0;

    int totalEsperadoGeral = espDinheiro;
    int totalApuradoGeral = infDinheiro;

    for (final entry in _ctrlFormasMap.entries) {
      final esp = r.vendasPorFormaPagamento[entry.key] ?? 0;
      final inf = _parseCentavos(entry.value.text);
      totalEsperadoGeral += esp;
      totalApuradoGeral += inf;
    }

    final int diferencaGlobal = totalApuradoGeral > 0 ? totalApuradoGeral - totalEsperadoGeral : 0;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conferência & Fechamento de Turno',
                    style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        r.sessaoAtiva?.observacoes ?? 'Turno Padrão',
                        style: TextStyle(color: FincoreColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const Text(' · ', style: TextStyle(color: FincoreColors.textMuted)),
                      Text(
                        'Aberto às ${_dtFmt.format(r.sessaoAtiva?.dataAbertura.toLocal() ?? DateTime.now())}',
                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5),
                      ),
                      if (r.sessaoAtiva?.operadorNome != null) ...[
                        const Text(' · ', style: TextStyle(color: FincoreColors.textMuted)),
                        Text(
                          'Operador: ${r.sessaoAtiva!.operadorNome}',
                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: FincoreColors.textMuted),
            tooltip: 'Fechar Janela',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 780,
        height: 540,
        child: Column(
          children: [
            // ── Barra de Abas ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: FincoreColors.primary,
                unselectedLabelColor: FincoreColors.textMuted,
                indicatorColor: FincoreColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  const Tab(icon: Icon(Icons.fact_check_outlined, size: 16), text: '1. Conferência'),
                  Tab(icon: const Icon(Icons.shopping_bag_outlined, size: 16), text: '2. Pedidos (${r.qtdPedidos})'),
                  Tab(
                    icon: const Icon(Icons.swap_vert_rounded, size: 16),
                    text: '3. Movimentos (${r.totalSangriasCentavos > 0 || r.totalSuprimentosCentavos > 0 ? "Ativo" : "0"})',
                  ),
                  const Tab(icon: Icon(Icons.print_outlined, size: 16), text: '4. Espelho de Cupom'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ═══════════════════════════════════════════════════════
                  // ABA 1: Conferência Detalhada de Valores por Modalidade
                  // ═══════════════════════════════════════════════════════
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: [
                      // Card Topo com Fundo de Troco e Saldo em Dinheiro
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Fundo de Troco Inicial', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                                  Text(widget.formatarValor(r.fundoTrocoCentavos), style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Vendas Brutas', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                                  Text(widget.formatarValor(r.totalVendasCentavos), style: const TextStyle(color: FincoreColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sangrias / Suprimentos', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                                  Text(
                                    '-${widget.formatarValor(r.totalSangriasCentavos)} / +${widget.formatarValor(r.totalSuprimentosCentavos)}',
                                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Esperado em Dinheiro', style: TextStyle(color: FincoreColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text(widget.formatarValor(espDinheiro), style: TextStyle(color: FincoreColors.primary, fontSize: 14, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Conferência física por modalidade de recebimento:',
                        style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // 1. Dinheiro Físico em Gaveta
                      _buildModalidadeRow(
                        modalidade: 'Dinheiro em Espécie (Gaveta)',
                        icone: Icons.payments_rounded,
                        cor: const Color(0xFF10B981),
                        subtitulo: 'Fundo Inicial (${widget.formatarValor(r.fundoTrocoCentavos)}) + Vendas + Reforços - Sangrias',
                        esperadoCentavos: espDinheiro,
                        controller: _ctrlDinheiroContado,
                      ),

                      // 2. Formas Reais cadastradas no Turno (PIX individuais, Cartões individuais, etc.)
                      ...r.vendasPorFormaPagamento.entries
                          .where((e) => !e.key.toLowerCase().contains('dinheiro') && !e.key.toLowerCase().contains('especie'))
                          .map((entry) {
                        final ctrl = _ctrlFormasMap[entry.key] ?? TextEditingController();
                        final icone = _getIconeModalidade(entry.key);
                        final cor = _getCorModalidade(entry.key);
                        return _buildModalidadeRow(
                          modalidade: entry.key,
                          icone: icone,
                          cor: cor,
                          subtitulo: 'Total registrado no sistema durante o turno',
                          esperadoCentavos: entry.value,
                          controller: ctrl,
                        );
                      }),

                      const SizedBox(height: 10),

                      // Card de Resumo das Diferenças Apuradas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (diferencaGlobal == 0 && totalApuradoGeral > 0)
                              ? FincoreColors.success.withValues(alpha: 0.1)
                              : (diferencaGlobal < 0 ? const Color(0xFFEF4444).withValues(alpha: 0.1) : FincoreColors.background),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (diferencaGlobal == 0 && totalApuradoGeral > 0)
                                ? FincoreColors.success.withValues(alpha: 0.3)
                                : (diferencaGlobal < 0 ? const Color(0xFFEF4444).withValues(alpha: 0.4) : FincoreColors.border),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  diferencaGlobal == 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                  color: diferencaGlobal == 0 ? FincoreColors.success : (diferencaGlobal < 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  totalApuradoGeral == 0
                                      ? 'Informe a contagem física das modalidades para verificar diferenças'
                                      : diferencaGlobal == 0
                                          ? 'Conferência 100% batida! Nenhuma divergência de valores.'
                                          : diferencaGlobal > 0
                                              ? 'Sobra global identificada no fechamento'
                                              : 'Divergência / Falta global identificada no fechamento',
                                  style: TextStyle(
                                    color: totalApuradoGeral == 0
                                        ? FincoreColors.textMuted
                                        : diferencaGlobal == 0
                                            ? FincoreColors.success
                                            : (diferencaGlobal < 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (totalApuradoGeral > 0)
                              Text(
                                diferencaGlobal == 0
                                    ? 'Diferença: R\$ 0,00'
                                    : diferencaGlobal > 0
                                        ? '+ ${widget.formatarValor(diferencaGlobal)}'
                                        : widget.formatarValor(diferencaGlobal),
                                style: TextStyle(
                                  color: diferencaGlobal == 0 ? FincoreColors.success : (diferencaGlobal < 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _ctrlObs,
                        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Observações / Justificativas do Fechamento',
                          labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                          hintText: 'Ex: Fundo de troco mantido na gaveta para o próximo turno...',
                          hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: FincoreColors.background,
                        ),
                      ),
                    ],
                  ),

                  // ═══════════════════════════════════════════════════════
                  // ABA 2: Lista Completa de Pedidos do Turno
                  // ═══════════════════════════════════════════════════════
                  FutureBuilder<List<PedidoData>>(
                    future: widget.controller.carregarPedidosSessao(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lista = snapshot.data ?? [];
                      if (lista.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma venda registrada neste turno.', style: TextStyle(color: FincoreColors.textMuted)),
                        );
                      }
                      final subtotal = lista.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
                      final ticketMedio = lista.isNotEmpty ? (subtotal / lista.length).round() : 0;

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${lista.length} Pedidos Realizados', style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Total: ${widget.formatarValor(subtotal)}', style: const TextStyle(color: FincoreColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Ticket Médio: ${widget.formatarValor(ticketMedio)}', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              itemCount: lista.length,
                              separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                              itemBuilder: (context, i) {
                                final p = lista[i];
                                final nomeCliente = p.clienteNomeAvulso ?? 'Consumidor Final';
                                final numPedido = p.numeroPedido != null
                                    ? '#${p.numeroPedido.toString().padLeft(4, '0')}'
                                    : '#${p.id.substring(0, 6).toUpperCase()}';
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: FincoreColors.primary.withValues(alpha: 0.15),
                                    child: Text('${i + 1}', style: TextStyle(color: FincoreColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(numPedido, style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          nomeCliente,
                                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${_dtFmt.format(p.dataHoraCriacao.toLocal())} · ${p.formaPagamentoNome ?? 'Dinheiro'} · ${p.tipoLogistica}',
                                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                                  ),
                                  trailing: Text(
                                    widget.formatarValor(p.valorTotalCentavos),
                                    style: const TextStyle(color: FincoreColors.success, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ═══════════════════════════════════════════════════════
                  // ABA 3: Movimentações de Caixa (Sangrias & Suprimentos)
                  // ═══════════════════════════════════════════════════════
                  FutureBuilder<List<LancamentoFinanceiroData>>(
                    future: r.sessaoAtiva != null ? widget.controller.carregarLancamentosSessao(r.sessaoAtiva!.id) : Future.value([]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lancamentos = snapshot.data ?? [];
                      if (lancamentos.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_vert_rounded, size: 36, color: FincoreColors.textMuted),
                              SizedBox(height: 8),
                              Text('Nenhuma sangria ou suprimento registrado neste turno.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${lancamentos.length} Movimentações de Gaveta', style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Suprimentos: +${widget.formatarValor(r.totalSuprimentosCentavos)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold)),
                                Text('Sangrias: -${widget.formatarValor(r.totalSangriasCentavos)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              itemCount: lancamentos.length,
                              separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                              itemBuilder: (context, i) {
                                final l = lancamentos[i];
                                final isCredito = l.tipo == 'suprimento';
                                final col = isCredito ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: col.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(isCredito ? Icons.input_rounded : Icons.output_rounded, color: col, size: 18),
                                  ),
                                  title: Text(
                                    l.descricao.isNotEmpty ? l.descricao : l.tipo.toUpperCase(),
                                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${_dtFmt.format(l.dataHora.toLocal())} · Tipo: ${l.tipo.toUpperCase()}',
                                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                                  ),
                                  trailing: Text(
                                    '${isCredito ? '+' : '-'}${widget.formatarValor(l.valorCentavos)}',
                                    style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ═══════════════════════════════════════════════════════
                  // ABA 4: Espelho Térmico de Fechamento & Impressão
                  // ═══════════════════════════════════════════════════════
                  Column(
                    children: [
                      // Botão de Ação de Impressão
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Visualização do Espelho de Cupom Térmico (80mm/58mm):',
                              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            ElevatedButton.icon(
                              icon: _imprimindo
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.print_rounded, size: 16),
                              label: const Text('Imprimir Relatório de Fechamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FincoreColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _imprimindo ? null : _imprimirRelatorioFechamento,
                            ),
                          ],
                        ),
                      ),

                      // Espelho Visual do Cupom
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: FincoreColors.border),
                          ),
                          child: SingleChildScrollView(
                            child: DefaultTextStyle(
                              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 11, height: 1.4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(child: Text('========================================')),
                                  const Center(child: Text('   COMPROVANTE DE FECHAMENTO DE CAIXA   ', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const Center(child: Text('========================================')),
                                  Text('Operador : ${r.sessaoAtiva?.operadorNome ?? "Caixa"}'),
                                  if (r.sessaoAtiva?.observacoes != null)
                                    Text('Turno    : ${r.sessaoAtiva!.observacoes}'),
                                  Text('Abertura : ${_dtFullFmt.format(r.sessaoAtiva?.dataAbertura.toLocal() ?? DateTime.now())}'),
                                  Text('Fechamento: ${_dtFullFmt.format(DateTime.now())}'),
                                  const Text('----------------------------------------'),
                                  const Text('RESUMO DO MOVIMENTO:'),
                                  _buildReceiptRow('Fundo Inicial', widget.formatarValor(r.fundoTrocoCentavos)),
                                  _buildReceiptRow('Vendas Totais (${r.qtdPedidos} ped)', widget.formatarValor(r.totalVendasCentavos)),
                                  _buildReceiptRow('Total Suprimentos', '+ ${widget.formatarValor(r.totalSuprimentosCentavos)}'),
                                  _buildReceiptRow('Total Sangrias', '- ${widget.formatarValor(r.totalSangriasCentavos)}'),
                                  if (r.totalDespesasCentavos > 0)
                                    _buildReceiptRow('Despesas Balcão', '- ${widget.formatarValor(r.totalDespesasCentavos)}'),
                                  const Text('----------------------------------------'),
                                  _buildReceiptRow('SALDO ESPERADO GAVETA', widget.formatarValor(espDinheiro), isBold: true),
                                  const Text('----------------------------------------'),
                                  const Text('VENDAS POR FORMA DE PAGAMENTO:'),
                                  ...r.vendasPorFormaPagamento.entries.map((e) {
                                    return _buildReceiptRow(e.key, widget.formatarValor(e.value));
                                  }),
                                  const Text('----------------------------------------'),
                                  const Text('CONFERENCIA APURADA:'),
                                  _buildReceiptRow('Dinheiro Apurado', infDinheiro > 0 ? widget.formatarValor(infDinheiro) : 'N/I'),
                                  if (infDinheiro > 0)
                                    _buildReceiptRow('Dif. Dinheiro', widget.formatarValor(difDinheiro), isBold: true),
                                  ..._ctrlFormasMap.entries.map((entry) {
                                    final esp = r.vendasPorFormaPagamento[entry.key] ?? 0;
                                    final inf = _parseCentavos(entry.value.text);
                                    if (inf > 0) {
                                      return _buildReceiptRow('${entry.key} Apurado', '${widget.formatarValor(inf)} (Dif: ${widget.formatarValor(inf - esp)})');
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                  if (_ctrlObs.text.trim().isNotEmpty) ...[
                                    const Text('----------------------------------------'),
                                    Text('OBSERVAÇÕES: ${_ctrlObs.text.trim()}'),
                                  ],
                                  const Text('========================================'),
                                  const SizedBox(height: 16),
                                  const Center(child: Text('________________________________________')),
                                  const Center(child: Text('Assinatura do Operador de Caixa')),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final int? valFisico = infDinheiro > 0 ? infDinheiro : null;
                  await widget.onConfirm(valFisico, _ctrlObs.text.trim().isEmpty ? null : _ctrlObs.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Encerrar Turno e Salvar Fechamento', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildModalidadeRow({
    required String modalidade,
    required IconData icone,
    required Color cor,
    required String subtitulo,
    required int esperadoCentavos,
    required TextEditingController controller,
  }) {
    final int informado = _parseCentavos(controller.text);
    final int diferenca = informado > 0 ? informado - esperadoCentavos : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icone, color: cor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(modalidade, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  Text(
                    'Esperado: ${widget.formatarValor(esperadoCentavos)}',
                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Apurado (R\$)',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                  prefixText: 'R\$ ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  filled: true,
                  fillColor: FincoreColors.surface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(
                informado == 0
                    ? 'Pendente'
                    : diferenca == 0
                        ? '✔ Batido'
                        : diferenca > 0
                            ? '+ ${widget.formatarValor(diferenca)}'
                            : widget.formatarValor(diferenca),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: informado == 0
                      ? FincoreColors.textMuted
                      : diferenca == 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogMovimentoCaixa extends StatefulWidget {
  final String initialTipo;
  final Future<void> Function(String tipo, int valor, String desc) onConfirm;

  const DialogMovimentoCaixa({
    super.key,
    this.initialTipo = 'sangria',
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    String initialTipo = 'sangria',
    required Future<void> Function(String tipo, int valor, String desc) onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogMovimentoCaixa(initialTipo: initialTipo, onConfirm: onConfirm),
    );
  }

  @override
  State<DialogMovimentoCaixa> createState() => _DialogMovimentoCaixaState();
}

class _DialogMovimentoCaixaState extends State<DialogMovimentoCaixa> {
  late String _tipo;
  final _valorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.initialTipo;
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Row(
        children: [
          Icon(Icons.swap_vert_rounded, color: FincoreColors.primary),
          const SizedBox(width: 10),
          const Text('Lançamento Avulso de Caixa', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _tipo,
            dropdownColor: FincoreColors.surface,
            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Tipo de Lançamento',
              labelStyle: const TextStyle(color: FincoreColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: FincoreColors.background,
            ),
            items: const [
              DropdownMenuItem(value: 'sangria', child: Text('Sangria (retirada de dinheiro da gaveta)')),
              DropdownMenuItem(value: 'suprimento', child: Text('Suprimento (reforço de notas/troco)')),
              DropdownMenuItem(value: 'despesa', child: Text('Despesa Operacional Balcão')),
            ],
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valorCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Valor (R\$)',
              labelStyle: const TextStyle(color: FincoreColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixText: 'R\$ ',
              filled: true,
              fillColor: FincoreColors.background,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Descrição / Motivo',
              labelStyle: const TextStyle(color: FincoreColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: FincoreColors.background,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  final valor = ((double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0) * 100).toInt();
                  if (valor <= 0) return;

                  setState(() => _loading = true);
                  await widget.onConfirm(_tipo, valor, _descCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar Lançamento', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
