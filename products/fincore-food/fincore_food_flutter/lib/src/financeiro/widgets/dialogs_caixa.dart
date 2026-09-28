import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import '../controllers/financeiro_controller.dart';

class DialogAbrirCaixa extends StatefulWidget {
  final Future<void> Function(int valorCentavos, String nomeTurno) onConfirm;
  const DialogAbrirCaixa({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(int valorCentavos, String nomeTurno) onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogAbrirCaixa(onConfirm: onConfirm),
    );
  }

  @override
  State<DialogAbrirCaixa> createState() => _DialogAbrirCaixaState();
}

class _DialogAbrirCaixaState extends State<DialogAbrirCaixa> {
  final _ctrlValor = TextEditingController(text: '0');
  final _ctrlTurno = TextEditingController(text: 'Almoço');
  String _turnoSelecionado = 'Almoço';
  bool _loading = false;

  final List<String> _turnosPredefinidos = ['Almoço', 'Jantar', 'Madrugada', 'Turno 1', 'Turno 2'];

  @override
  void dispose() {
    _ctrlValor.dispose();
    _ctrlTurno.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Row(
        children: [
          Icon(Icons.point_of_sale_rounded, color: FincoreColors.success),
          SizedBox(width: 10),
          Text('Abertura de Caixa & Turno', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione ou identifique o Turno Operacional:',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _turnosPredefinidos.map((t) {
                final isSel = _turnoSelecionado == t;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _turnoSelecionado = t;
                      _ctrlTurno.text = t;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? FincoreColors.primary : FincoreColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? FincoreColors.primary : FincoreColors.border),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: isSel ? Colors.white : FincoreColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrlTurno,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Nome do Turno',
                labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: FincoreColors.background,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Informe o valor do fundo de troco em espécie na gaveta:',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrlValor,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Fundo de troco inicial (R\$)',
                labelStyle: const TextStyle(color: FincoreColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixText: 'R\$ ',
                prefixStyle: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: FincoreColors.background,
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
                  final val = (double.tryParse(_ctrlValor.text.replaceAll(',', '.')) ?? 0) * 100;
                  final turno = _ctrlTurno.text.trim().isNotEmpty ? _ctrlTurno.text.trim() : 'Turno Padrão';
                  await widget.onConfirm(val.toInt(), turno);
                  if (context.mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Abrir Caixa Agora', style: TextStyle(fontWeight: FontWeight.bold)),
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
  final _ctrlPixContado = TextEditingController();
  final _ctrlCreditoContado = TextEditingController();
  final _ctrlDebitoContado = TextEditingController();
  final _ctrlFiadoContado = TextEditingController();
  final _ctrlObs = TextEditingController();
  bool _loading = false;

  final _dtFmt = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrlDinheiroContado.dispose();
    _ctrlPixContado.dispose();
    _ctrlCreditoContado.dispose();
    _ctrlDebitoContado.dispose();
    _ctrlFiadoContado.dispose();
    _ctrlObs.dispose();
    super.dispose();
  }

  int _parseCentavos(String text) {
    if (text.trim().isEmpty) return 0;
    return ((double.tryParse(text.replaceAll(',', '.')) ?? 0) * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resumo;

    // Valores esperados calculados por modalidade
    final int espDinheiro = r.saldoEsperadoDinheiroCentavos;
    final int espPix = r.vendasPorFormaPagamento.entries
        .where((e) => e.key.toLowerCase().contains('pix'))
        .fold(0, (s, e) => s + e.value);
    final int espCredito = r.vendasPorFormaPagamento.entries
        .where((e) => e.key.toLowerCase().contains('créd') || e.key.toLowerCase().contains('cred'))
        .fold(0, (s, e) => s + e.value);
    final int espDebito = r.vendasPorFormaPagamento.entries
        .where((e) => e.key.toLowerCase().contains('déb') || e.key.toLowerCase().contains('deb'))
        .fold(0, (s, e) => s + e.value);
    final int espFiado = r.vendasPorFormaPagamento.entries
        .where((e) => e.key.toLowerCase().contains('prazo') || e.key.toLowerCase().contains('fiado'))
        .fold(0, (s, e) => s + e.value);

    // Valores informados
    final int infDinheiro = _parseCentavos(_ctrlDinheiroContado.text);

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.all(20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Conferência & Fechamento de Caixa', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  if (r.sessaoAtiva?.observacoes != null)
                    Text(
                      r.sessaoAtiva!.observacoes!,
                      style: TextStyle(color: FincoreColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: FincoreColors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 500,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: FincoreColors.primary,
              unselectedLabelColor: FincoreColors.textMuted,
              indicatorColor: FincoreColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Conferência'),
                Tab(text: 'Vendas Turno'),
                Tab(text: 'Notas a Prazo'),
                Tab(text: 'Movimentos'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Aba 1: Conferência de Valores por Modalidade
                  ListView(
                    children: [
                      const Text(
                        'Informe os valores apurados fisicamente para conferência contra o esperado:',
                        style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      _buildModalidadeRow(
                        modalidade: 'Dinheiro (Espécie na Gaveta)',
                        icone: Icons.payments_rounded,
                        cor: const Color(0xFF10B981),
                        esperadoCentavos: espDinheiro,
                        controller: _ctrlDinheiroContado,
                      ),
                      _buildModalidadeRow(
                        modalidade: 'PIX (Extrato Bancário)',
                        icone: Icons.pix_rounded,
                        cor: const Color(0xFF32BCAD),
                        esperadoCentavos: espPix,
                        controller: _ctrlPixContado,
                      ),
                      _buildModalidadeRow(
                        modalidade: 'Cartão de Crédito (Relatório POS)',
                        icone: Icons.credit_card_rounded,
                        cor: const Color(0xFF0284C7),
                        esperadoCentavos: espCredito,
                        controller: _ctrlCreditoContado,
                      ),
                      _buildModalidadeRow(
                        modalidade: 'Cartão de Débito (Relatório POS)',
                        icone: Icons.credit_card_outlined,
                        cor: const Color(0xFF3B82F6),
                        esperadoCentavos: espDebito,
                        controller: _ctrlDebitoContado,
                      ),
                      _buildModalidadeRow(
                        modalidade: 'Nota a Prazo (Comprovantes Vales)',
                        icone: Icons.receipt_long_rounded,
                        cor: const Color(0xFFF59E0B),
                        esperadoCentavos: espFiado,
                        controller: _ctrlFiadoContado,
                      ),
                      const Divider(color: FincoreColors.border, height: 24),
                      TextField(
                        controller: _ctrlObs,
                        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Observações de Fechamento / Justificativas',
                          labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: FincoreColors.background,
                        ),
                      ),
                    ],
                  ),

                  // Aba 2: Pedidos do Turno
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
                      return ListView.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                        itemBuilder: (context, i) {
                          final p = lista[i];
                          final nomeCliente = p.clienteNomeAvulso ?? 'Consumidor Final';
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Pedido #${p.numeroPedido ?? p.id.substring(0, 6)} · $nomeCliente',
                              style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
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
                      );
                    },
                  ),

                  // Aba 3: Notas a Prazo
                  FutureBuilder<List<PedidoData>>(
                    future: widget.controller.carregarPedidosSessao(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lista = (snapshot.data ?? [])
                          .where((p) => (p.formaPagamentoNome ?? '').toLowerCase().contains('prazo') || (p.formaPagamentoNome ?? '').toLowerCase().contains('fiado'))
                          .toList();
                      if (lista.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma venda em Nota a Prazo realizada neste turno.', style: TextStyle(color: FincoreColors.textMuted)),
                        );
                      }
                      return ListView.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                        itemBuilder: (context, i) {
                          final p = lista[i];
                          final nomeCliente = p.clienteNomeAvulso ?? 'Consumidor Final';
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF59E0B), size: 20),
                            title: Text(
                              'Pedido #${p.numeroPedido ?? p.id.substring(0, 6)} · $nomeCliente',
                              style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            subtitle: Text('Faturado em ${_dtFmt.format(p.dataHoraCriacao.toLocal())}', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                            trailing: Text(
                              widget.formatarValor(p.valorTotalCentavos),
                              style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Aba 4: Movimentos de Gaveta
                  FutureBuilder<List<LancamentoFinanceiroData>>(
                    future: r.sessaoAtiva != null ? widget.controller.carregarLancamentosSessao(r.sessaoAtiva!.id) : Future.value([]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lancamentos = snapshot.data ?? [];
                      if (lancamentos.isEmpty) {
                        return const Center(
                          child: Text('Nenhum movimento de sangria/suprimento neste turno.', style: TextStyle(color: FincoreColors.textMuted)),
                        );
                      }
                      return ListView.separated(
                        itemCount: lancamentos.length,
                        separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                        itemBuilder: (context, i) {
                          final l = lancamentos[i];
                          final isCredito = l.tipo == 'suprimento';
                          final col = isCredito ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(isCredito ? Icons.input_rounded : Icons.output_rounded, color: col, size: 20),
                            title: Text(l.descricao.isNotEmpty ? l.descricao : l.tipo.toUpperCase(), style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                            subtitle: Text(_dtFmt.format(l.dataHora.toLocal()), style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                            trailing: Text('${isCredito ? '+' : '-'}${widget.formatarValor(l.valorCentavos)}', style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          );
                        },
                      );
                    },
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Encerrar Turno e Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildModalidadeRow({
    required String modalidade,
    required IconData icone,
    required Color cor,
    required int esperadoCentavos,
    required TextEditingController controller,
  }) {
    final int informado = _parseCentavos(controller.text);
    final int diferenca = informado > 0 ? informado - esperadoCentavos : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(modalidade, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    'Esperado: ${widget.formatarValor(esperadoCentavos)}',
                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 130,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Apurado (R\$)',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                  prefixText: 'R\$ ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  filled: true,
                  fillColor: FincoreColors.surface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(
                informado == 0
                    ? '-'
                    : diferenca == 0
                        ? '✔ Correto'
                        : diferenca > 0
                            ? '+${widget.formatarValor(diferenca)}'
                            : widget.formatarValor(diferenca),
                style: TextStyle(
                  fontSize: 11,
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
