import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import '../controllers/financeiro_controller.dart';

/// Central de Fechamento de Turno & Workstation Operacional
/// Visão gerencial completa em tela cheia com 9 dimensões de análise,
/// conferência física por contagem de cédulas, auditoria de pedidos,
/// produtos vendidos, encomendas futuras e espelho de impressão térmica.
class FechamentoTurnoPage extends StatefulWidget {
  final FinanceiroController controller;
  final String? sessaoId;

  const FechamentoTurnoPage({
    super.key,
    required this.controller,
    this.sessaoId,
  });

  static Future<void> show(
    BuildContext context, {
    required FinanceiroController controller,
    String? sessaoId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FechamentoTurnoPage(
          controller: controller,
          sessaoId: sessaoId,
        ),
      ),
    );
  }

  @override
  State<FechamentoTurnoPage> createState() => _FechamentoTurnoPageState();
}

class _FechamentoTurnoPageState extends State<FechamentoTurnoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dtFmt = DateFormat('dd/MM/yyyy · HH:mm');
  final _horaFmt = DateFormat('HH:mm');
  final _moedaFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Controllers de conferência
  final _ctrlDinheiroTotal = TextEditingController();
  final _ctrlObsFechamento = TextEditingController();
  final Map<String, TextEditingController> _ctrlFormasMap = {};

  // Contagem de cédulas e moedas
  final Map<int, TextEditingController> _ctrlCedulas = {
    200: TextEditingController(),
    100: TextEditingController(),
    50: TextEditingController(),
    20: TextEditingController(),
    10: TextEditingController(),
    5: TextEditingController(),
    2: TextEditingController(),
  };
  final TextEditingController _ctrlMoedas = TextEditingController();
  bool _modoContagemCedulas = false;

  // Estado e filtros
  bool _loading = false;
  bool _imprimindo = false;
  String _filtroVendas = 'todas';
  String _filtroMovimentos = 'todos';
  int _subAbaContasReceberIndex = 0; // 0: Baixas Efetuadas, 1: Contas Geradas
  String _filtroContasGeradas = 'todas'; // 'todas', 'pendentes', 'quitadas'
  String _filtroBaixas = 'todas'; // 'todas', 'turno', 'anteriores'
  PedidoData? _pedidoSelecionadoAuditoria;
  List<ItemPedidoData> _itensPedidoSelecionado = [];
  bool _carregandoItensPedido = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);

    final r = widget.controller.resumo;
    for (final key in r.vendasPorFormaPagamento.keys) {
      if (!key.toLowerCase().contains('dinheiro') && !key.toLowerCase().contains('especie')) {
        _ctrlFormasMap[key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrlDinheiroTotal.dispose();
    _ctrlObsFechamento.dispose();
    for (final c in _ctrlFormasMap.values) {
      c.dispose();
    }
    for (final c in _ctrlCedulas.values) {
      c.dispose();
    }
    _ctrlMoedas.dispose();
    super.dispose();
  }

  String _formatar(int centavos) => _moedaFmt.format(centavos / 100.0);

  int _parseCentavos(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
    final val = double.tryParse(clean) ?? 0.0;
    return (val * 100).round();
  }

  int _calcularTotalContagemCedulas() {
    int totalCentavos = 0;
    for (final entry in _ctrlCedulas.entries) {
      final qtd = int.tryParse(entry.value.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      totalCentavos += qtd * entry.key * 100;
    }
    final moedasCentavos = _parseCentavos(_ctrlMoedas.text);
    totalCentavos += moedasCentavos;
    return totalCentavos;
  }

  void _atualizarDinheiroPorCedulas() {
    final total = _calcularTotalContagemCedulas();
    setState(() {
      _ctrlDinheiroTotal.text = (total / 100.0).toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  Future<void> _selecionarPedidoAuditoria(PedidoData pedido) async {
    setState(() {
      _pedidoSelecionadoAuditoria = pedido;
      _carregandoItensPedido = true;
    });

    final itens = await widget.controller.carregarItensPedido(pedido.id);
    if (mounted) {
      setState(() {
        _itensPedidoSelecionado = itens;
        _carregandoItensPedido = false;
      });
    }
  }

  Future<void> _imprimirRelatorio() async {
    setState(() => _imprimindo = true);
    try {
      final r = widget.controller.resumo;
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
      final int infDinheiro = _parseCentavos(_ctrlDinheiroTotal.text);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(empresaNome.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                ),
                pw.Center(
                  child: pw.Text('RELATÓRIO DE FECHAMENTO DE TURNO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.SizedBox(height: 3),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('Operador: ${r.sessaoAtiva?.operadorNome ?? "Caixa"}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Turno   : ${r.nomeTurnoFormatado}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('Abertura: ${_dtFmt.format(r.sessaoAtiva?.dataAbertura.toLocal() ?? DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Fechamento: ${_dtFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('RESUMO DO MOVIMENTO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                _pwRow('Fundo Inicial:', _formatar(r.fundoTrocoCentavos)),
                _pwRow('Vendas Totais (${r.qtdPedidos} ped):', _formatar(r.totalVendasCentavos)),
                if (r.totalRecebimentosBaixasCentavos > 0)
                  _pwRow('Baixas Recebidas:', '+ ${_formatar(r.totalRecebimentosBaixasCentavos)}'),
                _pwRow('Total Suprimentos:', '+ ${_formatar(r.totalSuprimentosCentavos)}'),
                _pwRow('Total Sangrias:', '- ${_formatar(r.totalSangriasCentavos)}'),
                if (r.totalDespesasCentavos > 0)
                  _pwRow('Despesas Balcão:', '- ${_formatar(r.totalDespesasCentavos)}'),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                _pwRow('SALDO ESPERADO GAVETA:', _formatar(espDinheiro), isBold: true),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('VENDAS POR FORMA DE PAGAMENTO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                ...r.vendasPorFormaPagamento.entries.map((e) => _pwRow('• ${e.key}:', _formatar(e.value))),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('CONFERÊNCIA FÍSICA / APURADA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                _pwRow('Dinheiro Apurado:', infDinheiro > 0 ? _formatar(infDinheiro) : 'N/I'),
                if (infDinheiro > 0)
                  _pwRow('Diferença Dinheiro:', _formatar(infDinheiro - espDinheiro), isBold: true),
                if (_ctrlObsFechamento.text.trim().isNotEmpty) ...[
                  pw.Divider(borderStyle: pw.BorderStyle.dashed),
                  pw.Text('OBSERVAÇÕES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Text(_ctrlObsFechamento.text.trim(), style: const pw.TextStyle(fontSize: 7.5)),
                ],
                pw.SizedBox(height: 12),
                pw.Center(child: pw.Text('____________________________________', style: const pw.TextStyle(fontSize: 8))),
                pw.Center(child: pw.Text('Assinatura do Operador de Caixa', style: const pw.TextStyle(fontSize: 7.5))),
                pw.SizedBox(height: 6),
                pw.Center(child: pw.Text('FINCORE FOOD · ${_dtFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 6.5))),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'Fechamento_Turno_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: FincoreColors.danger, content: Text('Erro ao imprimir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  pw.Widget _pwRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _solicitarConfirmacaoFechamento() async {
    final r = widget.controller.resumo;
    final int espDinheiro = r.saldoEsperadoDinheiroCentavos;
    final int infDinheiro = _parseCentavos(_ctrlDinheiroTotal.text);
    final int difDinheiro = infDinheiro > 0 ? infDinheiro - espDinheiro : 0;

    final bool temDivergencia = infDinheiro > 0 && difDinheiro != 0;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (temDivergencia ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                temDivergencia ? Icons.warning_amber_rounded : Icons.lock_clock_rounded,
                color: temDivergencia ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar Encerramento do Turno', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  children: [
                    _buildModalSummaryRow('Vendas Totais do Turno:', _formatar(r.totalVendasCentavos), isBold: true),
                    const SizedBox(height: 4),
                    _buildModalSummaryRow('Dinheiro Esperado na Gaveta:', _formatar(espDinheiro)),
                    _buildModalSummaryRow('Dinheiro Físico Informado:', infDinheiro > 0 ? _formatar(infDinheiro) : 'Não informado'),
                    const Divider(color: FincoreColors.border, height: 14),
                    _buildModalSummaryRow(
                      'Diferença Apurada:',
                      difDinheiro == 0 ? 'R\$ 0,00 (100% Batido)' : (difDinheiro > 0 ? '+ ${_formatar(difDinheiro)} (Sobra)' : '${_formatar(difDinheiro)} (Falta / Quebra)'),
                      color: difDinheiro == 0 ? const Color(0xFF10B981) : (difDinheiro > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              if (temDivergencia) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Atenção: Houve divergência no valor apurado. As observações registradas serão salvas no log de auditoria fiscal.',
                          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Após encerrar o turno, este caixa será bloqueado para novas operações até que uma nova sessão seja aberta.',
                style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar e Conferir', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Encerrar Turno Definitivamente', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _loading = true);
      final int? valFisico = infDinheiro > 0 ? infDinheiro : null;
      await widget.controller.fecharCaixa(
        valorContadoCentavos: valFisico,
        observacoes: _ctrlObsFechamento.text.trim().isEmpty ? null : _ctrlObsFechamento.text.trim(),
      );
      if (mounted) {
        setState(() => _loading = false);
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildModalSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color ?? FincoreColors.textPrimary, fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.controller.resumo;
    final abertura = r.sessaoAtiva?.dataAbertura.toLocal() ?? DateTime.now();
    final duracao = DateTime.now().difference(abertura);
    final duracaoStr = '${duracao.inHours}h ${duracao.inMinutes.remainder(60)}min';

    final int espDinheiro = r.saldoEsperadoDinheiroCentavos;
    final int infDinheiro = _parseCentavos(_ctrlDinheiroTotal.text);
    final int difDinheiro = infDinheiro > 0 ? infDinheiro - espDinheiro : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ─── CABEÇALHO DA WORKSTATION DE FECHAMENTO ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: FincoreColors.surface,
                border: Border(bottom: BorderSide(color: FincoreColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: FincoreColors.textSecondary),
                        tooltip: 'Voltar ao PDV / Painel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
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
                          Row(
                            children: [
                              const Text(
                                'CENTRAL DE FECHAMENTO DO TURNO',
                                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  r.nomeTurnoFormatado,
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text('Aberto às ${_horaFmt.format(abertura)}', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                              const Text(' · ', style: TextStyle(color: FincoreColors.textMuted)),
                              Text('Duração: $duracaoStr', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                              const Text(' · ', style: TextStyle(color: FincoreColors.textMuted)),
                              Text('Operador: ${r.sessaoAtiva?.operadorNome ?? "Caixa"}', style: TextStyle(color: FincoreColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: _imprimindo
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)))
                            : const Icon(Icons.print_outlined, size: 16),
                        label: const Text('Imprimir Espelho (80mm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FincoreColors.textPrimary,
                          side: const BorderSide(color: FincoreColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _imprimindo ? null : _imprimirRelatorio,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock_outline_rounded, size: 18),
                        label: const Text('Encerrar Turno e Salvar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        onPressed: _loading ? null : _solicitarConfirmacaoFechamento,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── BARRA DE ABAS OPERACIONAIS ──────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: FincoreColors.surface,
                border: Border(bottom: BorderSide(color: FincoreColors.border)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: FincoreColors.primary,
                unselectedLabelColor: FincoreColors.textMuted,
                indicatorColor: FincoreColors.primary,
                indicatorWeight: 3,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                tabs: [
                  const Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: '1. Visão Geral'),
                  Tab(icon: const Icon(Icons.payments_outlined, size: 16), text: '2. Dinheiro Físico (${_formatar(espDinheiro)})'),
                  const Tab(icon: Icon(Icons.pie_chart_outline, size: 16), text: '3. Formas de Pagamento'),
                  Tab(icon: const Icon(Icons.receipt_long_outlined, size: 16), text: '4. Vendas (${r.qtdPedidos})'),
                  const Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 16), text: '5. Contas a Receber'),
                  const Tab(icon: Icon(Icons.swap_horiz_rounded, size: 16), text: '6. Movimentações'),
                  const Tab(icon: Icon(Icons.timeline_outlined, size: 16), text: '7. Timeline Financeira'),
                  const Tab(icon: Icon(Icons.fastfood_outlined, size: 16), text: '8. Produtos Vendidos'),
                  Tab(icon: const Icon(Icons.event_note_outlined, size: 16), text: '9. Encomendas (${r.qtdVendasAgendadas})'),
                  const Tab(icon: Icon(Icons.receipt_outlined, size: 16), text: '10. Espelho Térmico'),
                ],
              ),
            ),

            // ─── CORPO DAS ABAS ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAbaVisaoGeral(r, duracaoStr, espDinheiro, infDinheiro, difDinheiro),
                  _buildAbaDinheiroFisico(r, espDinheiro, infDinheiro, difDinheiro),
                  _buildAbaFormasPagamento(r),
                  _buildAbaVendas(r),
                  _buildAbaContasReceber(r),
                  _buildAbaMovimentacoes(r),
                  _buildAbaTimeline(r),
                  _buildAbaProdutosVendidos(r),
                  _buildAbaEncomendasFuturas(r),
                  _buildAbaEspelhoTermico(r, espDinheiro, infDinheiro, difDinheiro),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. ABA: VISÃO GERAL & BALANÇO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaVisaoGeral(ResumoCaixa r, String duracaoStr, int espDinheiro, int infDinheiro, int difDinheiro) {
    final ticketMedio = r.qtdPedidos > 0 ? (r.totalVendasCentavos / r.qtdPedidos).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 4 Big Numbers no Topo
        Row(
          children: [
            Expanded(
              child: _buildBigMetricCard(
                titulo: 'VENDAS DO TURNO',
                valor: _formatar(r.totalVendasCentavos),
                subtitulo: '${r.qtdPedidos} pedidos emitidos',
                icone: Icons.shopping_bag_outlined,
                cor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildBigMetricCard(
                titulo: 'RECEBIMENTOS TOTAIS',
                valor: _formatar(r.totalRecebimentosTurno + r.totalSuprimentosCentavos),
                subtitulo: 'Vendas + Baixas + Suprimentos',
                icone: Icons.arrow_downward_rounded,
                cor: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildBigMetricCard(
                titulo: 'TICKET MÉDIO',
                valor: _formatar(ticketMedio),
                subtitulo: 'Média por cliente atendido',
                icone: Icons.trending_up_rounded,
                cor: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildBigMetricCard(
                titulo: 'ESPERADO EM DINHEIRO',
                valor: _formatar(espDinheiro),
                subtitulo: 'Fundo Inicial + Gaveta Líquida',
                icone: Icons.payments_rounded,
                cor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Grid com Resumo do Turno e Balanço das Modalidades
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel Esquerdo: Resumo Financeiro Consolidado
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RESUMO DO MOVIMENTO DO TURNO', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        Icon(Icons.analytics_outlined, color: FincoreColors.textMuted, size: 20),
                      ],
                    ),
                    const Divider(color: FincoreColors.border, height: 20),
                    _buildSummaryLine('Fundo de Troco Inicial', _formatar(r.fundoTrocoCentavos)),
                    _buildClickableSummaryLine(
                      'Vendas Imediatas Balcão/Delivery',
                      _formatar(r.totalVendasImediatasCentavos),
                      onTap: () => _tabController.animateTo(3),
                      tooltip: 'Ver detalhes das vendas',
                    ),
                    _buildClickableSummaryLine(
                      'Vendas Agendadas / Encomendas',
                      _formatar(r.totalVendasAgendadasCentavos),
                      onTap: () => _tabController.animateTo(8),
                      tooltip: 'Ver encomendas',
                    ),
                    _buildClickableSummaryLine(
                      'Total de Vendas Brutas (${r.qtdPedidos} pedidos)',
                      _formatar(r.totalVendasCentavos),
                      onTap: () => _tabController.animateTo(3),
                      isBold: true,
                      color: const Color(0xFF10B981),
                      tooltip: 'Abrir lista completa de pedidos',
                    ),
                    if (r.totalRecebimentosBaixasCentavos > 0)
                      _buildClickableSummaryLine(
                        'Recebimentos de Contas Anteriores (Baixas)',
                        '+ ${_formatar(r.totalRecebimentosBaixasCentavos)}',
                        onTap: () => _tabController.animateTo(4),
                        color: const Color(0xFF10B981),
                        tooltip: 'Ver baixas recebidas neste turno',
                      ),
                    const SizedBox(height: 6),
                    _buildClickableSummaryLine(
                      'Reforços / Suprimentos de Gaveta',
                      '+ ${_formatar(r.totalSuprimentosCentavos)}',
                      onTap: () => _tabController.animateTo(5),
                      color: const Color(0xFF0284C7),
                      tooltip: 'Ver suprimentos lançados',
                    ),
                    _buildClickableSummaryLine(
                      'Sangrias / Retiradas para Cofre',
                      '- ${_formatar(r.totalSangriasCentavos)}',
                      onTap: () => _tabController.animateTo(5),
                      color: const Color(0xFFEF4444),
                      tooltip: 'Ver sangrias lançadas',
                    ),
                    if (r.totalDespesasCentavos > 0)
                      _buildClickableSummaryLine(
                        'Despesas Operacionais Balcão',
                        '- ${_formatar(r.totalDespesasCentavos)}',
                        onTap: () => _tabController.animateTo(5),
                        color: const Color(0xFFEF4444),
                        tooltip: 'Ver despesas lançadas',
                      ),
                    const Divider(color: FincoreColors.border, height: 20),
                    _buildClickableSummaryLine(
                      'SALDO ESPERADO TOTAL DO CAIXA',
                      _formatar(espDinheiro),
                      onTap: () => _tabController.animateTo(1),
                      isBold: true,
                      fontSize: 14,
                      color: const Color(0xFF10B981),
                      tooltip: 'Conferir dinheiro físico',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),

            // Painel Direito: Distribuição Rápida de Formas de Pagamento
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DISTRIBUIÇÃO POR MODALIDADE', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Divider(color: FincoreColors.border, height: 20),
                    if (r.vendasPorFormaPagamento.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Nenhuma venda registrada neste turno.', style: TextStyle(color: FincoreColors.textMuted))),
                      )
                    else
                      ...r.vendasPorFormaPagamento.entries.map((e) {
                        final perc = r.totalVendasCentavos > 0 ? (e.value / r.totalVendasCentavos) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  Text('${_formatar(e.value)} (${(perc * 100).toStringAsFixed(1)}%)', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: perc.clamp(0.0, 1.0),
                                  backgroundColor: FincoreColors.background,
                                  color: _getCorModalidade(e.key),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. ABA: DINHEIRO FÍSICO & CONFERÊNCIA DA GAVETA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaDinheiroFisico(ResumoCaixa r, int espDinheiro, int infDinheiro, int difDinheiro) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna Esquerda: A Matemática da Gaveta
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONCILIAÇÃO DO DINHEIRO EM ESPÉCIE', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Text('Entradas e saídas físicas com impacto direto na gaveta', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                    const Divider(color: FincoreColors.border, height: 20),
                    _buildSummaryLine('(+) Fundo de Troco Inicial', _formatar(r.fundoTrocoCentavos)),
                    _buildSummaryLine('(+) Vendas em Dinheiro Realizadas', _formatar(r.totalVendasDinheiroCentavos), color: const Color(0xFF10B981)),
                    if (r.totalRecebimentosBaixasDinheiroCentavos > 0)
                      _buildSummaryLine('(+) Baixas Recebidas em Dinheiro', '+ ${_formatar(r.totalRecebimentosBaixasDinheiroCentavos)}', color: const Color(0xFF10B981)),
                    _buildSummaryLine('(+) Suprimentos / Reforços de Moedas', '+ ${_formatar(r.totalSuprimentosCentavos)}', color: const Color(0xFF0284C7)),
                    _buildSummaryLine('(-) Sangrias / Retiradas de Notas', '- ${_formatar(r.totalSangriasCentavos)}', color: const Color(0xFFEF4444)),
                    if (r.totalDespesasCentavos > 0)
                      _buildSummaryLine('(-) Despesas Balcão Pagas em Dinheiro', '- ${_formatar(r.totalDespesasCentavos)}', color: const Color(0xFFEF4444)),
                    const Divider(color: FincoreColors.border, height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FincoreColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DINHEIRO ESPERADO NA GAVETA:', style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_formatar(espDinheiro), style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ctrlObsFechamento,
                      maxLines: 3,
                      style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Justificativa / Observações do Caixa',
                        labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                        hintText: 'Ex: Fundo de troco mantido na gaveta para o próximo turno...',
                        hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5),
                        filled: true,
                        fillColor: FincoreColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),

            // Coluna Direita: Contagem de Cédulas & Moedas
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CONTAGEM FÍSICA APURADA', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          icon: Icon(_modoContagemCedulas ? Icons.edit_note_outlined : Icons.calculate_outlined, size: 16),
                          label: Text(_modoContagemCedulas ? 'Digitar Total Direto' : 'Contagem por Cédula', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _modoContagemCedulas = !_modoContagemCedulas),
                        ),
                      ],
                    ),
                    const Divider(color: FincoreColors.border, height: 16),

                    if (!_modoContagemCedulas) ...[
                      // Campo de Digitação Direta
                      const Text('Informe o valor total em dinheiro contado na gaveta:', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ctrlDinheiroTotal,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Total Apurado em Dinheiro (R\$)',
                          prefixText: 'R\$ ',
                          filled: true,
                          fillColor: FincoreColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ] else ...[
                      // Tabela de Cédulas e Moedas
                      const Text('Informe a quantidade de cada cédula presente na gaveta:', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5)),
                      const SizedBox(height: 10),
                      ..._ctrlCedulas.entries.map((e) {
                        final valNota = e.key;
                        final ctrl = e.value;
                        final qtd = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        final subtotal = qtd * valNota * 100;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text('R\$ $valNota', style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 8),
                              const Text('×', style: TextStyle(color: FincoreColors.textMuted)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 70,
                                height: 36,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    filled: true,
                                    fillColor: FincoreColors.background,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onChanged: (_) => _atualizarDinheiroPorCedulas(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '= ${_formatar(subtotal)}',
                                  style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Moedas', style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _ctrlMoedas,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                decoration: InputDecoration(
                                  prefixText: 'R\$ ',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  filled: true,
                                  fillColor: FincoreColors.background,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onChanged: (_) => _atualizarDinheiroPorCedulas(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Card com Resultado da Diferença
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (difDinheiro == 0 && infDinheiro > 0)
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : (difDinheiro < 0 ? const Color(0xFFEF4444).withValues(alpha: 0.1) : (difDinheiro > 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : FincoreColors.background)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (difDinheiro == 0 && infDinheiro > 0)
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : (difDinheiro < 0 ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                (difDinheiro == 0 && infDinheiro > 0)
                                    ? Icons.check_circle_rounded
                                    : (difDinheiro < 0 ? Icons.error_outline_rounded : Icons.info_outline),
                                color: (difDinheiro == 0 && infDinheiro > 0)
                                    ? const Color(0xFF10B981)
                                    : (difDinheiro < 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                infDinheiro == 0
                                    ? 'Aguardando contagem'
                                    : difDinheiro == 0
                                        ? 'Gaveta 100% Batida!'
                                        : (difDinheiro > 0 ? 'Sobra de Gaveta' : 'Falta / Quebra de Caixa'),
                                style: TextStyle(
                                  color: (difDinheiro == 0 && infDinheiro > 0)
                                      ? const Color(0xFF10B981)
                                      : (difDinheiro < 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (infDinheiro > 0)
                            Text(
                              difDinheiro == 0 ? 'R\$ 0,00' : (difDinheiro > 0 ? '+ ${_formatar(difDinheiro)}' : _formatar(difDinheiro)),
                              style: TextStyle(
                                color: difDinheiro == 0
                                    ? const Color(0xFF10B981)
                                    : (difDinheiro < 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ABA: FORMAS DE PAGAMENTO & CANAIS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaFormasPagamento(ResumoCaixa r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DISCRIMINAÇÃO POR FORMA DE PAGAMENTO E DESTINO FINANCEIRO', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const Text('Distinção de impacto físico na gaveta vs impacto em conta bancária/adquirente', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
              const Divider(color: FincoreColors.border, height: 20),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: FincoreColors.background),
                    children: [
                      _buildTableHeaderCell('Modalidade / Conta'),
                      _buildTableHeaderCell('Valor Total'),
                      _buildTableHeaderCell('% do Faturamento'),
                      _buildTableHeaderCell('Destino Financeiro'),
                      _buildTableHeaderCell('Impacto Gaveta Física'),
                    ],
                  ),
                  ...r.vendasPorFormaPagamento.entries.map((entry) {
                    final isDinheiro = entry.key.toLowerCase().contains('dinheiro') || entry.key.toLowerCase().contains('especie');
                    final isPix = entry.key.toLowerCase().contains('pix');
                    final perc = r.totalVendasCentavos > 0 ? (entry.value / r.totalVendasCentavos) * 100 : 0.0;

                    return TableRow(
                      children: [
                        _buildTableCell(entry.key, isBold: true),
                        _buildTableCell(_formatar(entry.value), color: const Color(0xFF10B981), isBold: true),
                        _buildTableCell('${perc.toStringAsFixed(1)}%'),
                        _buildTableCell(isDinheiro ? 'Gaveta Física' : (isPix ? 'Conta Banco / PIX' : 'Adquirente / Cartão')),
                        _buildTableCell(
                          isDinheiro ? '+ ${_formatar(entry.value)}' : 'R\$ 0,00 (Sem impacto na gaveta)',
                          color: isDinheiro ? const Color(0xFF10B981) : FincoreColors.textMuted,
                          isBold: isDinheiro,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. ABA: VENDAS DO TURNO & AUDITORIA DE PEDIDOS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaVendas(ResumoCaixa r) {
    return FutureBuilder<List<PedidoData>>(
      future: widget.controller.carregarPedidosSessao(widget.sessaoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final todos = snapshot.data ?? [];
        final filtrados = todos.where((p) {
          if (_filtroVendas == 'pagas') return (p.formaPagamentoNome?.toLowerCase().contains('prazo') != true);
          if (_filtroVendas == 'prazo') return (p.formaPagamentoNome?.toLowerCase().contains('prazo') == true || p.formaPagamentoNome?.toLowerCase().contains('fiado') == true);
          if (_filtroVendas == 'delivery') return p.tipoLogistica == 'Entrega' || p.tipoLogistica == 'Delivery';
          if (_filtroVendas == 'balcao') return p.tipoLogistica == 'Balcão' || p.tipoLogistica == 'Retirada';
          return true;
        }).toList();

        return Row(
          children: [
            // Lista Principal de Pedidos
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: FincoreColors.surface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${filtrados.length} Vendas Encontradas', style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: [
                            _buildFilterChip('Todas', 'todas', _filtroVendas, (v) => setState(() => _filtroVendas = v)),
                            _buildFilterChip('Pagas', 'pagas', _filtroVendas, (v) => setState(() => _filtroVendas = v)),
                            _buildFilterChip('A Prazo', 'prazo', _filtroVendas, (v) => setState(() => _filtroVendas = v)),
                            _buildFilterChip('Delivery', 'delivery', _filtroVendas, (v) => setState(() => _filtroVendas = v)),
                            _buildFilterChip('Balcão', 'balcao', _filtroVendas, (v) => setState(() => _filtroVendas = v)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: FincoreColors.border, height: 1),
                  Expanded(
                    child: filtrados.isEmpty
                        ? const Center(child: Text('Nenhuma venda para o filtro selecionado.', style: TextStyle(color: FincoreColors.textMuted)))
                        : ListView.separated(
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                            itemBuilder: (context, i) {
                              final p = filtrados[i];
                              final isSelected = _pedidoSelecionadoAuditoria?.id == p.id;
                              final numPed = p.numeroPedido != null ? '#${p.numeroPedido.toString().padLeft(4, '0')}' : '#${p.id.substring(0, 6).toUpperCase()}';
                              final nomeCliente = p.clienteNomeAvulso ?? 'Consumidor Final';

                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: FincoreColors.primary.withValues(alpha: 0.12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                onTap: () => _selecionarPedidoAuditoria(p),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: FincoreColors.surface,
                                  child: Text('${i + 1}', style: TextStyle(color: FincoreColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                title: Row(
                                  children: [
                                    Text(numPed, style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(nomeCliente, style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${_horaFmt.format(p.dataHoraCriacao.toLocal())} · ${p.formaPagamentoNome ?? 'Dinheiro'} · Canal: ${p.tipoLogistica}',
                                  style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_formatar(p.valorTotalCentavos), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: FincoreColors.textMuted, size: 18),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: FincoreColors.border, width: 1),

            // Painel Lateral de Auditoria de Itens do Pedido Selecionado
            Expanded(
              flex: 4,
              child: Container(
                color: FincoreColors.surface,
                padding: const EdgeInsets.all(16),
                child: _pedidoSelecionadoAuditoria == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_outlined, size: 36, color: FincoreColors.textMuted),
                            SizedBox(height: 8),
                            Text('Selecione uma venda ao lado para auditar seus itens e detalhes.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Auditoria do Pedido ${_pedidoSelecionadoAuditoria!.numeroPedido != null ? "#${_pedidoSelecionadoAuditoria!.numeroPedido}" : ""}',
                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: FincoreColors.textMuted),
                                onPressed: () => setState(() => _pedidoSelecionadoAuditoria = null),
                              ),
                            ],
                          ),
                          Text(
                            'Cliente: ${_pedidoSelecionadoAuditoria!.clienteNomeAvulso ?? "Consumidor Final"} · ${_dtFmt.format(_pedidoSelecionadoAuditoria!.dataHoraCriacao.toLocal())}',
                            style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5),
                          ),
                          const Divider(color: FincoreColors.border, height: 16),
                          _carregandoItensPedido
                              ? const Center(child: CircularProgressIndicator())
                              : Expanded(
                                  child: ListView.separated(
                                    itemCount: _itensPedidoSelecionado.length,
                                    separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                                    itemBuilder: (context, idx) {
                                      final item = _itensPedidoSelecionado[idx];
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(item.nomeProduto, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                          '${item.quantidade.toStringAsFixed(item.quantidade % 1 == 0 ? 0 : 2)} × ${_formatar(item.valorUnitarioCentavos)}',
                                          style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                                        ),
                                        trailing: Text(_formatar(item.valorTotalCentavos), style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                      );
                                    },
                                  ),
                                ),
                          const Divider(color: FincoreColors.border, height: 16),
                          _buildSummaryLine('Subtotal dos Itens:', _formatar(_pedidoSelecionadoAuditoria!.valorSubtotalCentavos)),
                          _buildSummaryLine('Taxa de Entrega:', '+ ${_formatar(_pedidoSelecionadoAuditoria!.valorTaxaEntregaCentavos)}'),
                          _buildSummaryLine('TOTAL DO PEDIDO:', _formatar(_pedidoSelecionadoAuditoria!.valorTotalCentavos), isBold: true, color: const Color(0xFF10B981)),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. ABA: CONTAS A RECEBER & VENDAS A PRAZO — DUAS SUB-ABAS COM RASTREABILIDADE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaContasReceber(ResumoCaixa r) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.controller.carregarContasReceberDoTurno(widget.sessaoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? {};
        final contasGeradas = (data['contasGeradas'] as List<PedidoData>?) ?? [];
        final contasGeradasQuitadas = (data['contasGeradasQuitadas'] as List<PedidoData>?) ?? [];
        final contasGeradasPendentes = (data['contasGeradasPendentes'] as List<PedidoData>?) ?? [];
        final lancamentosBaixa = (data['lancamentosBaixa'] as List<LancamentoFinanceiroData>?) ?? [];
        final lancamentosBaixaTurnoAtual = (data['lancamentosBaixaTurnoAtual'] as List<LancamentoFinanceiroData>?) ?? [];
        final lancamentosBaixaAnteriores = (data['lancamentosBaixaAnteriores'] as List<LancamentoFinanceiroData>?) ?? [];
        final mapaBaixasPorPedido = (data['mapaBaixasPorPedido'] as Map<String, LancamentoFinanceiroData>?) ?? {};

        final totalGerado = (data['totalGeradoCentavos'] as int?) ?? 0;
        final totalGeradoQuitado = (data['totalGeradoQuitadoCentavos'] as int?) ?? 0;
        final totalGeradoPendente = (data['totalGeradoPendenteCentavos'] as int?) ?? 0;
        final totalRecebido = (data['totalRecebidoCentavos'] as int?) ?? 0;
        final totalRecebidoDinheiro = (data['totalRecebidoDinheiroCentavos'] as int?) ?? 0;

        // Filtragem para Sub-Aba 1 (Baixas)
        final baixasFiltradas = lancamentosBaixa.where((l) {
          if (_filtroBaixas == 'turno') return lancamentosBaixaTurnoAtual.contains(l);
          if (_filtroBaixas == 'anteriores') return lancamentosBaixaAnteriores.contains(l);
          return true;
        }).toList();

        // Filtragem para Sub-Aba 2 (Contas Geradas)
        final contasFiltradas = contasGeradas.where((p) {
          if (_filtroContasGeradas == 'pendentes') return contasGeradasPendentes.contains(p);
          if (_filtroContasGeradas == 'quitadas') return contasGeradasQuitadas.contains(p);
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── CABEÇALHO COM SELETOR DE SUB-ABAS ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _subAbaContasReceberIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _subAbaContasReceberIndex == 0 ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _subAbaContasReceberIndex == 0 ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              color: _subAbaContasReceberIndex == 0 ? const Color(0xFF10B981) : FincoreColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Baixas / Recebimentos Efetuados',
                                  style: TextStyle(
                                    color: _subAbaContasReceberIndex == 0 ? const Color(0xFF10B981) : FincoreColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${lancamentosBaixa.length} baixas · ${_formatar(totalRecebido)} recebidos no turno',
                                  style: TextStyle(
                                    color: _subAbaContasReceberIndex == 0 ? const Color(0xFF10B981) : FincoreColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: _subAbaContasReceberIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _subAbaContasReceberIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _subAbaContasReceberIndex == 1 ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _subAbaContasReceberIndex == 1 ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_late_outlined,
                              color: _subAbaContasReceberIndex == 1 ? const Color(0xFFF59E0B) : FincoreColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contas a Receber Geradas no Turno',
                                  style: TextStyle(
                                    color: _subAbaContasReceberIndex == 1 ? const Color(0xFFF59E0B) : FincoreColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${contasGeradas.length} pedidos a prazo · ${_formatar(totalGerado)} faturados',
                                  style: TextStyle(
                                    color: _subAbaContasReceberIndex == 1 ? const Color(0xFFF59E0B) : FincoreColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: _subAbaContasReceberIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ═════════════════════════════════════════════════════════════════
            // CONTEÚDO DA SUB-ABA 1: BAIXAS E RECEBIMENTOS EFETUADOS
            // ═════════════════════════════════════════════════════════════════
            if (_subAbaContasReceberIndex == 0) ...[
              // 4 Big Numbers de Baixas
              Row(
                children: [
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'TOTAL RECEBIDO EM BAIXAS',
                      valor: _formatar(totalRecebido),
                      subtitulo: '${lancamentosBaixa.length} títulos liquidados no caixa',
                      icone: Icons.check_circle_outline,
                      cor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'RECEBIDO EM DINHEIRO',
                      valor: _formatar(totalRecebidoDinheiro),
                      subtitulo: 'Impactou gaveta física',
                      icone: Icons.payments_outlined,
                      cor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'RECEBIDO VIA PIX / BANCO',
                      valor: _formatar(totalRecebido - totalRecebidoDinheiro),
                      subtitulo: 'Impacto direto em conta bancária',
                      icone: Icons.account_balance_outlined,
                      cor: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'VENDAS DO TURNO QUITADAS',
                      valor: '${lancamentosBaixaTurnoAtual.length}',
                      subtitulo: '${lancamentosBaixaAnteriores.length} de títulos anteriores',
                      icone: Icons.sync_alt_outlined,
                      cor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Lista de Baixas com Filtros
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DISCRIMINAÇÃO DAS BAIXAS EFETUADAS', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Rastreabilidade da origem de cada recebimento efetuado neste turno', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                        Row(
                          children: [
                            _buildFilterChip('Todas (${lancamentosBaixa.length})', 'todas', _filtroBaixas, (v) => setState(() => _filtroBaixas = v)),
                            _buildFilterChip('Vendas deste Turno (${lancamentosBaixaTurnoAtual.length})', 'turno', _filtroBaixas, (v) => setState(() => _filtroBaixas = v)),
                            _buildFilterChip('Títulos Anteriores (${lancamentosBaixaAnteriores.length})', 'anteriores', _filtroBaixas, (v) => setState(() => _filtroBaixas = v)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: FincoreColors.border, height: 20),
                    if (baixasFiltradas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Nenhum recebimento de título encontrado para este filtro.', style: TextStyle(color: FincoreColors.textMuted))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: baixasFiltradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final l = baixasFiltradas[i];
                          final fp = l.formaPagamentoNome ?? 'Dinheiro';
                          final isDinheiro = fp.toLowerCase().contains('dinheiro') || fp.toLowerCase().contains('especie');
                          final isQuitacaoTurnoAtual = lancamentosBaixaTurnoAtual.contains(l);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isQuitacaoTurnoAtual
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : FincoreColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            l.descricao.isNotEmpty ? l.descricao : 'Baixa de Título',
                                            style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isQuitacaoTurnoAtual)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                              ),
                                              child: const Text(
                                                '🎯 Quitou Venda deste Turno',
                                                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                                              ),
                                              child: const Text(
                                                '📄 Título / Dívida Anterior',
                                                style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatar(l.valorCentavos),
                                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildTraceChip(
                                      Icons.access_time_outlined,
                                      _dtFmt.format(l.dataHora.toLocal()),
                                      const Color(0xFF6B7280),
                                    ),
                                    _buildTraceChip(
                                      isDinheiro ? Icons.payments_outlined : Icons.account_balance_rounded,
                                      'Recebido via $fp',
                                      isDinheiro ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                                    ),
                                    if (l.pedidoId != null)
                                      _buildTraceChip(
                                        Icons.receipt_long_outlined,
                                        'Pedido vinculado',
                                        const Color(0xFFF59E0B),
                                      ),
                                    _buildTraceChip(
                                      isDinheiro ? Icons.inbox_rounded : Icons.sync_alt_rounded,
                                      isDinheiro ? 'Impactou gaveta física' : 'Sem impacto na gaveta física',
                                      isDinheiro ? const Color(0xFF10B981) : FincoreColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],

            // ═════════════════════════════════════════════════════════════════
            // CONTEÚDO DA SUB-ABA 2: CONTAS GERADAS NO TURNO
            // ═════════════════════════════════════════════════════════════════
            if (_subAbaContasReceberIndex == 1) ...[
              // 4 Big Numbers de Contas Geradas
              Row(
                children: [
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'TOTAL FATURADO A PRAZO',
                      valor: _formatar(totalGerado),
                      subtitulo: '${contasGeradas.length} pedidos emitidos a prazo no turno',
                      icone: Icons.assignment_late_outlined,
                      cor: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'JÁ LIQUIDADO NO TURNO',
                      valor: _formatar(totalGeradoQuitado),
                      subtitulo: '${contasGeradasQuitadas.length} pedidos já recebidos neste caixa',
                      icone: Icons.check_circle_outline,
                      cor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'PENDENTE DE BAIXA',
                      valor: _formatar(totalGeradoPendente),
                      subtitulo: '${contasGeradasPendentes.length} pedidos em aberto na carteira',
                      icone: Icons.pending_actions_outlined,
                      cor: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildBigMetricCard(
                      titulo: 'TAXA DE LIQUIDAÇÃO',
                      valor: totalGerado > 0 ? '${((totalGeradoQuitado / totalGerado) * 100).toStringAsFixed(1)}%' : '0,0%',
                      subtitulo: 'Recebido no mesmo turno',
                      icone: Icons.pie_chart_outline_rounded,
                      cor: const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Lista de Contas Geradas no Turno com Filtros
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PEDIDOS FATURADOS A PRAZO / FIADO NESTE TURNO', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Status individual de cada venda a prazo gerada: se já foi recebida no turno ou se continua pendente', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                        Row(
                          children: [
                            _buildFilterChip('Todas (${contasGeradas.length})', 'todas', _filtroContasGeradas, (v) => setState(() => _filtroContasGeradas = v)),
                            _buildFilterChip('Pendentes (${contasGeradasPendentes.length})', 'pendentes', _filtroContasGeradas, (v) => setState(() => _filtroContasGeradas = v)),
                            _buildFilterChip('Já Quitadas no Turno (${contasGeradasQuitadas.length})', 'quitadas', _filtroContasGeradas, (v) => setState(() => _filtroContasGeradas = v)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: FincoreColors.border, height: 20),
                    if (contasFiltradas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Nenhum pedido faturado a prazo encontrado para este filtro.', style: TextStyle(color: FincoreColors.textMuted))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: contasFiltradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = contasFiltradas[i];
                          final numPed = p.numeroPedido != null ? '#${p.numeroPedido.toString().padLeft(4, '0')}' : '#${p.id.substring(0, 6).toUpperCase()}';
                          final isQuitado = contasGeradasQuitadas.contains(p);
                          final baixaAssociada = mapaBaixasPorPedido[p.id];

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isQuitado
                                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            p.clienteNomeAvulso ?? 'Consumidor Final',
                                            style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Pedido $numPed', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                                          const SizedBox(width: 10),
                                          if (isQuitado)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                              ),
                                              child: const Text(
                                                '✅ Quitado / Liquidado no Turno',
                                                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                              ),
                                              child: const Text(
                                                '⏳ Pendente de Recebimento',
                                                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatar(p.valorTotalCentavos),
                                      style: TextStyle(
                                        color: isQuitado ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildTraceChip(
                                      Icons.access_time_outlined,
                                      'Emissão: ${_dtFmt.format(p.dataHoraCriacao.toLocal())}',
                                      const Color(0xFF6B7280),
                                    ),
                                    _buildTraceChip(
                                      Icons.credit_card_outlined,
                                      'Faturamento: ${p.formaPagamentoNome ?? "A Prazo"}',
                                      const Color(0xFFF59E0B),
                                    ),
                                    _buildTraceChip(
                                      Icons.local_shipping_outlined,
                                      'Canal: ${p.tipoLogistica}',
                                      const Color(0xFF6B7280),
                                    ),
                                    if (isQuitado && baixaAssociada != null) ...[
                                      _buildTraceChip(
                                        Icons.check_circle_outlined,
                                        'Baixa às ${_horaFmt.format(baixaAssociada.dataHora.toLocal())} via ${baixaAssociada.formaPagamentoNome ?? "Dinheiro"}',
                                        const Color(0xFF10B981),
                                      ),
                                    ] else if (!isQuitado) ...[
                                      _buildTraceChip(
                                        Icons.info_outline,
                                        'Aguardando quitação em turnos futuros',
                                        const Color(0xFFF59E0B),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. ABA: MOVIMENTAÇÕES DE GAVETA & TESOURARIA — COM RASTREABILIDADE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaMovimentacoes(ResumoCaixa r) {
    return FutureBuilder<List<LancamentoFinanceiroData>>(
      future: r.sessaoAtiva != null ? widget.controller.carregarLancamentosSessao(r.sessaoAtiva!.id) : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final todos = snapshot.data ?? [];
        final filtrados = todos.where((l) {
          if (_filtroMovimentos == 'sangrias') return l.tipo == 'sangria';
          if (_filtroMovimentos == 'suprimentos') return l.tipo == 'suprimento';
          if (_filtroMovimentos == 'despesas') return l.tipo == 'despesa';
          if (_filtroMovimentos == 'recebimentos') return l.tipo == 'receita' || l.tipo == 'suprimento';
          return true;
        }).toList();

        // Totalizadores da view filtrada
        int totalEntradas = 0, totalSaidas = 0;
        for (final l in filtrados) {
          if (l.tipo == 'suprimento' || l.tipo == 'receita') {
            totalEntradas += l.valorCentavos;
          } else {
            totalSaidas += l.valorCentavos;
          }
        }

        return Column(
          children: [
            // Cabeçalho com filtros e totalizadores
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: FincoreColors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${filtrados.length} Lançamentos · Entradas: ${_formatar(totalEntradas)} · Saídas: ${_formatar(totalSaidas)}',
                              style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const Text('Todos os lançamentos avulsos de caixa com origem rastreada', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          _buildFilterChip('Todas', 'todos', _filtroMovimentos, (v) => setState(() => _filtroMovimentos = v)),
                          _buildFilterChip('Recebimentos', 'recebimentos', _filtroMovimentos, (v) => setState(() => _filtroMovimentos = v)),
                          _buildFilterChip('Sangrias', 'sangrias', _filtroMovimentos, (v) => setState(() => _filtroMovimentos = v)),
                          _buildFilterChip('Suprimentos', 'suprimentos', _filtroMovimentos, (v) => setState(() => _filtroMovimentos = v)),
                          _buildFilterChip('Despesas', 'despesas', _filtroMovimentos, (v) => setState(() => _filtroMovimentos = v)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: FincoreColors.border, height: 1),
            Expanded(
              child: filtrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.swap_horiz_rounded, size: 40, color: FincoreColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            _filtroMovimentos == 'todos'
                                ? 'Nenhuma movimentação avulsa registrada neste turno.'
                                : 'Nenhum lançamento de "$_filtroMovimentos" neste turno.',
                            style: const TextStyle(color: FincoreColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final l = filtrados[i];
                        final isCredito = l.tipo == 'suprimento' || l.tipo == 'receita';
                        final cor = isCredito ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                        final fp = l.formaPagamentoNome ?? (isCredito ? 'Dinheiro' : 'Saída Gaveta');
                        final isDinheiro = fp.toLowerCase().contains('dinheiro') || fp.toLowerCase().contains('especie');
                        final descLower = l.descricao.toLowerCase();
                        final isBaixa = descLower.contains('baixa') || descLower.contains('liquid') || descLower.contains('quitação') || descLower.contains('quitacao');

                        return Container(
                          padding: const EdgeInsets.all(14),
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
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Icon(
                                      _getIconeMovimento(l.tipo, isCredito),
                                      color: cor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                              child: Text(
                                                isBaixa ? 'BAIXA' : l.tipo.toUpperCase(),
                                                style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 10),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                l.descricao.isNotEmpty ? l.descricao : 'Lançamento Avulso',
                                                style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${isCredito ? "+" : "-"}${_formatar(l.valorCentavos)}',
                                    style: TextStyle(color: cor, fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // ── Chips de Rastreabilidade ──────────────────
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildTraceChip(
                                    Icons.access_time_outlined,
                                    _dtFmt.format(l.dataHora.toLocal()),
                                    const Color(0xFF6B7280),
                                  ),
                                  _buildTraceChip(
                                    isDinheiro ? Icons.payments_outlined : Icons.account_balance_rounded,
                                    fp,
                                    isDinheiro ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                                  ),
                                  if (l.pedidoId != null)
                                    _buildTraceChip(
                                      Icons.receipt_long_outlined,
                                      'Pedido vinculado',
                                      const Color(0xFFF59E0B),
                                    ),
                                  _buildTraceChip(
                                    isDinheiro ? Icons.inbox_rounded : Icons.sync_alt_rounded,
                                    isDinheiro ? 'Impacta gaveta' : 'Fora da gaveta',
                                    isDinheiro ? (isCredito ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : FincoreColors.textMuted,
                                  ),
                                  if (r.sessaoAtiva?.operadorNome != null)
                                    _buildTraceChip(
                                      Icons.person_outline_rounded,
                                      r.sessaoAtiva!.operadorNome,
                                      const Color(0xFF6B7280),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. ABA: TIMELINE FINANCEIRA CRONOLÓGICA DO TURNO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaTimeline(ResumoCaixa r) {
    return FutureBuilder<List<EventoTimeline>>(
      future: widget.controller.carregarTimelineFinanceira(widget.sessaoId ?? r.sessaoAtiva?.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final eventos = snapshot.data ?? [];

        if (eventos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline_outlined, size: 48, color: FincoreColors.textMuted),
                SizedBox(height: 12),
                Text('Nenhum evento registrado neste turno.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: FincoreColors.surface,
              child: Row(
                children: [
                  Icon(Icons.timeline_outlined, color: FincoreColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${eventos.length} eventos · Trilha financeira completa do turno',
                    style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    'RASTREÁVEL ATÉ A ORIGEM',
                    style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            const Divider(color: FincoreColors.border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: eventos.length,
                itemBuilder: (context, i) {
                  final ev = eventos[i];
                  final isFirst = i == 0;
                  final isLast = i == eventos.length - 1;
                  final cor = _getCorEvento(ev.tipo);
                  final icone = _getIconeEvento(ev.tipo);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Trilho vertical da timeline
                        SizedBox(
                          width: 48,
                          child: Column(
                            children: [
                              if (!isFirst)
                                Container(width: 2, height: 16, color: FincoreColors.border),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cor.withValues(alpha: 0.5), width: 1.5),
                                ),
                                child: Icon(icone, color: cor, size: 16),
                              ),
                              if (!isLast)
                                Expanded(child: Container(width: 2, color: FincoreColors.border)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Conteúdo do evento
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: FincoreColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: ev.tipo == EventoTipo.abertura || ev.tipo == EventoTipo.fechamento
                                    ? cor.withValues(alpha: 0.4)
                                    : FincoreColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ev.descricao,
                                          style: TextStyle(
                                            color: FincoreColors.textPrimary,
                                            fontWeight: ev.tipo == EventoTipo.abertura || ev.tipo == EventoTipo.fechamento
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      if (ev.isCredito || ev.isDebito)
                                        Text(
                                          '${ev.isCredito ? "+" : "-"}${_formatar(ev.valorCentavos)}',
                                          style: TextStyle(
                                            color: ev.isCredito ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        )
                                      else if (ev.valorCentavos > 0)
                                        Text(
                                          _formatar(ev.valorCentavos),
                                          style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildTraceChip(
                                        Icons.access_time_outlined,
                                        _horaFmt.format(ev.dataHora.toLocal()),
                                        const Color(0xFF6B7280),
                                      ),
                                      if (ev.formaPagamento != null)
                                        _buildTraceChip(
                                          Icons.payment_outlined,
                                          ev.formaPagamento!,
                                          const Color(0xFF0284C7),
                                        ),
                                      if (ev.clienteNome != null)
                                        _buildTraceChip(
                                          Icons.person_outline_rounded,
                                          ev.clienteNome!,
                                          const Color(0xFF6B7280),
                                        ),
                                      if (ev.tipoLogistica != null)
                                        _buildTraceChip(
                                          Icons.local_shipping_outlined,
                                          ev.tipoLogistica!,
                                          const Color(0xFF6B7280),
                                        ),
                                      if (ev.impactaGaveta && (ev.isCredito || ev.isDebito))
                                        _buildTraceChip(
                                          Icons.inbox_rounded,
                                          ev.isCredito ? 'Entra na gaveta' : 'Sai da gaveta',
                                          ev.isCredito ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. ABA: PRODUTOS VENDIDOS NO TURNO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaProdutosVendidos(ResumoCaixa r) {
    return FutureBuilder<List<ProdutoVendidoResumo>>(
      future: widget.controller.carregarProdutosVendidosSessao(widget.sessaoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = snapshot.data ?? [];
        final double totalItens = lista.fold<double>(0.0, (s, p) => s + p.quantidade);
        final int totalValor = lista.fold<int>(0, (s, p) => s + p.totalCentavos);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildBigMetricCard(
                    titulo: 'TOTAL DE PRODUTOS VENDIDOS',
                    valor: '${totalItens.toStringAsFixed(totalItens % 1 == 0 ? 0 : 2)} unidades',
                    subtitulo: '${lista.length} produtos distintos comercializados',
                    icone: Icons.inventory_2_outlined,
                    cor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBigMetricCard(
                    titulo: 'FATURAMENTO EM PRODUTOS',
                    valor: _formatar(totalValor),
                    subtitulo: 'Total bruto dos itens vendidos',
                    icone: Icons.receipt_long_outlined,
                    cor: const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RANKING DE PRODUTOS VENDIDOS NO TURNO', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Divider(color: FincoreColors.border, height: 20),
                  if (lista.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Nenhum produto vendido neste turno.', style: TextStyle(color: FincoreColors.textMuted))),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: FincoreColors.background),
                          children: [
                            _buildTableHeaderCell('Produto'),
                            _buildTableHeaderCell('Quantidade'),
                            _buildTableHeaderCell('Faturamento'),
                            _buildTableHeaderCell('% do Turno'),
                          ],
                        ),
                        ...lista.map((p) => TableRow(
                              children: [
                                _buildTableCell(p.nome, isBold: true),
                                _buildTableCell('${p.quantidade.toStringAsFixed(p.quantidade % 1 == 0 ? 0 : 2)} un'),
                                _buildTableCell(_formatar(p.totalCentavos), color: const Color(0xFF10B981), isBold: true),
                                _buildTableCell('${p.percentualFaturamento.toStringAsFixed(1)}%'),
                              ],
                            )),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. ABA: ENCOMENDAS FUTURAS & AGENDAMENTOS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaEncomendasFuturas(ResumoCaixa r) {
    return FutureBuilder<List<PedidoData>>(
      future: widget.controller.carregarEncomendasFuturasSessao(widget.sessaoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final encomendas = snapshot.data ?? [];
        final totalEncomendas = encomendas.fold<int>(0, (s, p) => s + p.valorTotalCentavos);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildBigMetricCard(
              titulo: 'ENCOMENDAS PROGRAMADAS NO TURNO',
              valor: _formatar(totalEncomendas),
              subtitulo: '${encomendas.length} pedidos agendados para produção futura',
              icone: Icons.calendar_month_outlined,
              cor: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LISTA DE ENCOMENDAS AGENDADAS', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Divider(color: FincoreColors.border, height: 20),
                  if (encomendas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Nenhuma encomenda futura registrada durante este turno.', style: TextStyle(color: FincoreColors.textMuted))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: encomendas.length,
                      separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                      itemBuilder: (context, i) {
                        final p = encomendas[i];
                        final dtEntrega = p.dataHoraEntregaPrevista ?? p.dataHoraCriacao;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_available_outlined, color: Color(0xFFF59E0B)),
                          title: Text(p.clienteNomeAvulso ?? 'Consumidor', style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('Entrega prevista: ${_dtFmt.format(dtEntrega.toLocal())} · ${p.tipoLogistica}', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                          trailing: Text(_formatar(p.valorTotalCentavos), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. ABA: ESPELHO DE CUPOM TÉRMICO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAbaEspelhoTermico(ResumoCaixa r, int espDinheiro, int infDinheiro, int difDinheiro) {
    return Center(
      child: Container(
        width: 380,
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FincoreColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
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
                Text('Turno    : ${r.nomeTurnoFormatado}'),
                Text('Abertura : ${_dtFmt.format(r.sessaoAtiva?.dataAbertura.toLocal() ?? DateTime.now())}'),
                Text('Fechamento: ${_dtFmt.format(DateTime.now())}'),
                const Text('----------------------------------------'),
                const Text('RESUMO DO MOVIMENTO:'),
                _buildReceiptRow('Fundo Inicial', _formatar(r.fundoTrocoCentavos)),
                _buildReceiptRow('Vendas Totais (${r.qtdPedidos} ped)', _formatar(r.totalVendasCentavos)),
                if (r.totalRecebimentosBaixasCentavos > 0)
                  _buildReceiptRow('Baixas Recebidas', '+ ${_formatar(r.totalRecebimentosBaixasCentavos)}'),
                _buildReceiptRow('Total Suprimentos', '+ ${_formatar(r.totalSuprimentosCentavos)}'),
                _buildReceiptRow('Total Sangrias', '- ${_formatar(r.totalSangriasCentavos)}'),
                if (r.totalDespesasCentavos > 0)
                  _buildReceiptRow('Despesas Balcão', '- ${_formatar(r.totalDespesasCentavos)}'),
                const Text('----------------------------------------'),
                _buildReceiptRow('SALDO ESPERADO GAVETA', _formatar(espDinheiro), isBold: true),
                const Text('----------------------------------------'),
                const Text('VENDAS POR FORMA DE PAGAMENTO:'),
                ...r.vendasPorFormaPagamento.entries.map((e) => _buildReceiptRow(e.key, _formatar(e.value))),
                const Text('----------------------------------------'),
                const Text('CONFERENCIA APURADA:'),
                _buildReceiptRow('Dinheiro Apurado', infDinheiro > 0 ? _formatar(infDinheiro) : 'N/I'),
                if (infDinheiro > 0)
                  _buildReceiptRow('Dif. Dinheiro', _formatar(difDinheiro), isBold: true),
                if (_ctrlObsFechamento.text.trim().isNotEmpty) ...[
                  const Text('----------------------------------------'),
                  Text('OBSERVAÇÕES: ${_ctrlObsFechamento.text.trim()}'),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS VISUAIS E COMPONENTES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBigMetricCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icone, color: cor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(color: cor, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitulo, style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String valor, {bool isBold = false, Color? color, double fontSize = 12.5}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: FincoreColors.textSecondary, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(valor, style: TextStyle(color: color ?? FincoreColors.textPrimary, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  /// Linha clicável da Visão Geral — navega para a aba detalhada ao clicar
  Widget _buildClickableSummaryLine(
    String label,
    String valor, {
    required VoidCallback onTap,
    bool isBold = false,
    Color? color,
    double fontSize = 12.5,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(label, style: TextStyle(color: FincoreColors.textSecondary, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new_rounded, size: 12, color: FincoreColors.textMuted),
                ],
              ),
              Text(valor, style: TextStyle(color: color ?? FincoreColors.textPrimary, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip de rastreabilidade (ícone + label) para identificar origem de lançamento
  Widget _buildTraceChip(IconData icone, String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 11, color: cor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: cor, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getIconeMovimento(String tipo, bool isCredito) {
    switch (tipo) {
      case 'sangria': return Icons.arrow_upward_rounded;
      case 'suprimento': return Icons.add_circle_outline_rounded;
      case 'despesa': return Icons.remove_circle_outline_rounded;
      case 'receita': return Icons.arrow_downward_rounded;
      default: return isCredito ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    }
  }

  Color _getCorEvento(EventoTipo tipo) {
    switch (tipo) {
      case EventoTipo.abertura: return const Color(0xFF0284C7);
      case EventoTipo.fechamento: return const Color(0xFF6B7280);
      case EventoTipo.venda: return const Color(0xFF10B981);
      case EventoTipo.cancelamento: return const Color(0xFFEF4444);
      case EventoTipo.consumoInterno: return const Color(0xFF6B7280);
      case EventoTipo.sangria: return const Color(0xFFEF4444);
      case EventoTipo.suprimento: return const Color(0xFF0284C7);
      case EventoTipo.despesa: return const Color(0xFFF59E0B);
      case EventoTipo.baixa: return const Color(0xFF10B981);
      case EventoTipo.recebimento: return const Color(0xFF10B981);
    }
  }

  IconData _getIconeEvento(EventoTipo tipo) {
    switch (tipo) {
      case EventoTipo.abertura: return Icons.lock_open_rounded;
      case EventoTipo.fechamento: return Icons.lock_rounded;
      case EventoTipo.venda: return Icons.shopping_bag_outlined;
      case EventoTipo.cancelamento: return Icons.cancel_outlined;
      case EventoTipo.consumoInterno: return Icons.restaurant_outlined;
      case EventoTipo.sangria: return Icons.arrow_upward_rounded;
      case EventoTipo.suprimento: return Icons.add_circle_outline_rounded;
      case EventoTipo.despesa: return Icons.receipt_outlined;
      case EventoTipo.baixa: return Icons.check_circle_outline;
      case EventoTipo.recebimento: return Icons.arrow_downward_rounded;
    }
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

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(color: FincoreColors.textMuted, fontWeight: FontWeight.bold, fontSize: 11.5)),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: TextStyle(color: color ?? FincoreColors.textPrimary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12.5)),
    );
  }

  Widget _buildFilterChip(String label, String valor, String valorAtual, Function(String) onSelect) {
    final isSelected = valor == valorAtual;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11.5)),
        selected: isSelected,
        backgroundColor: FincoreColors.background,
        selectedColor: FincoreColors.primary.withValues(alpha: 0.15),
        checkmarkColor: FincoreColors.primary,
        side: BorderSide(color: isSelected ? FincoreColors.primary : FincoreColors.border),
        onSelected: (_) => onSelect(valor),
      ),
    );
  }

  Color _getCorModalidade(String modalidade) {
    final lower = modalidade.toLowerCase();
    if (lower.contains('pix')) return const Color(0xFF32BCAD);
    if (lower.contains('créd') || lower.contains('cred')) return const Color(0xFF0284C7);
    if (lower.contains('déb') || lower.contains('deb') || lower.contains('cart')) return const Color(0xFF3B82F6);
    if (lower.contains('prazo') || lower.contains('fiado')) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}
