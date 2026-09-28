import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import '../controllers/financeiro_controller.dart';
import '../widgets/dialogs_caixa.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> with SingleTickerProviderStateMixin {
  late FinanceiroController _controller;
  late TabController _tabController;
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dtFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _controller = FinanceiroController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(int centavos) => _moeda.format(centavos / 100);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final ctrl = _controller;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumoHeader(ctrl),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 16),
            if (ctrl.loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAbaSessaoAtual(ctrl),
                    _buildAbaHistoricoCaixas(ctrl),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── Header Principal de Ação e Status ──────────────────────────────────────

  Widget _buildResumoHeader(FinanceiroController ctrl) {
    final aberto = ctrl.resumo.caixaAberto;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (aberto ? FincoreColors.success : const Color(0xFFE05C5C)).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              aberto ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 20,
              color: aberto ? FincoreColors.success : const Color(0xFFE05C5C),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    aberto ? 'CAIXA ABERTO' : 'CAIXA FECHADO',
                    style: TextStyle(
                      color: aberto ? FincoreColors.success : const Color(0xFFE05C5C),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (aberto && ctrl.resumo.sessaoAtiva != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· ${ctrl.resumo.sessaoAtiva!.operadorNome}',
                      style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                aberto
                    ? 'Aberto em ${_dtFormat.format(ctrl.resumo.sessaoAtiva!.dataAbertura.toLocal())}'
                    : 'Abra uma sessão para registrar entradas e saídas físicas',
                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: FincoreColors.textMuted),
            tooltip: 'Atualizar dados',
            onPressed: () => ctrl.refresh(),
          ),
          const SizedBox(width: 8),
          if (aberto) ...[
            OutlinedButton.icon(
              onPressed: () => _mostrarDialogMovimento(ctrl, 'sangria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFFEF4444)),
              label: const Text('Sangria', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _mostrarDialogMovimento(ctrl, 'suprimento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FincoreColors.success,
                side: const BorderSide(color: FincoreColors.success),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_upward_rounded, size: 14, color: FincoreColors.success),
              label: const Text('Suprimento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _mostrarDialogMovimento(ctrl, 'despesa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FincoreColors.primary,
                side: BorderSide(color: FincoreColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.add_rounded, size: 14, color: FincoreColors.primary),
              label: const Text('Lançamento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogFecharCaixa(ctrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE05C5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
              label: const Text('Fechar Caixa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogAbrirCaixa(ctrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 16, color: Colors.white),
              label: const Text('Abrir Novo Caixa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Navegação de Abas ──────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FincoreColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: FincoreColors.primary,
        labelColor: FincoreColors.primary,
        unselectedLabelColor: FincoreColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'SESSÃO ATUAL & VENDAS DO DIA'),
          Tab(text: 'HISTÓRICO DE CAIXAS (TURNOS ANTERIORES)'),
        ],
      ),
    );
  }

  // ─── ABA 1: Sessão Atual & Vendas do Dia ───────────────────────────────────

  Widget _buildAbaSessaoAtual(FinanceiroController ctrl) {
    final resumo = ctrl.resumo;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 2.2 : 1.8,
                children: [
                  _MetricCard(
                    titulo: 'Fundo de Troco',
                    valor: _fmt(resumo.fundoTrocoCentavos),
                    icone: Icons.account_balance_wallet_outlined,
                    corIcone: FincoreColors.primary,
                    subtitulo: 'Abertura do caixa',
                  ),
                  _MetricCard(
                    titulo: 'Vendas Totais do Dia',
                    valor: _fmt(resumo.totalVendasCentavos),
                    icone: Icons.trending_up_rounded,
                    corIcone: FincoreColors.success,
                    subtitulo: '${resumo.qtdPedidos} pedidos confirmados',
                  ),
                  _MetricCard(
                    titulo: 'Saídas / Sangrias',
                    valor: _fmt(resumo.totalDespesasCentavos + resumo.totalSangriasCentavos),
                    icone: Icons.arrow_downward_rounded,
                    corIcone: const Color(0xFFEF4444),
                    subtitulo: 'Sangrias + Despesas',
                  ),
                  _MetricCard(
                    titulo: 'Saldo Estimado em Espécie',
                    valor: _fmt(resumo.saldoEsperadoDinheiroCentavos),
                    icone: Icons.payments_outlined,
                    corIcone: const Color(0xFFF59E0B),
                    subtitulo: 'Troco + Dinheiro - Sangrias',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Cards de Vendas Agendadas vs. Vendas Imediatas
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.flash_on_rounded, color: FincoreColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vendas Imediatas (Pronta Entrega)',
                              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(resumo.totalVendasImediatasCentavos),
                              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${resumo.qtdVendasImediatas} ped.',
                          style: TextStyle(color: FincoreColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vendas Agendadas (Entrega Futura)',
                              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(resumo.totalVendasAgendadasCentavos),
                              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${resumo.qtdVendasAgendadas} agend.',
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Vendas por forma de pagamento
          const Text(
            'RECEITAS POR FORMA DE PAGAMENTO',
            style: TextStyle(
              color: FincoreColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          if (resumo.vendasPorFormaPagamento.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: const Center(
                child: Text(
                  'Nenhuma venda registrada na sessão do dia',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                children: [
                  ...resumo.vendasPorFormaPagamento.entries.map((e) {
                    final pct = resumo.totalVendasCentavos > 0
                        ? e.value / resumo.totalVendasCentavos
                        : 0.0;
                    return _FormaPagamentoRow(
                      nome: e.key,
                      valor: _fmt(e.value),
                      percentual: pct,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL DE RECEITAS BRUTAS',
                          style: TextStyle(
                            color: FincoreColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _fmt(resumo.totalVendasCentavos),
                          style: const TextStyle(
                            color: FincoreColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (resumo.totalConsumoInternoCentavos > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_outlined, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consumo Interno & Cortesia (Informativo)',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${resumo.qtdConsumoInterno} lançamento${resumo.qtdConsumoInterno != 1 ? 's' : ''} registrado${resumo.qtdConsumoInterno != 1 ? 's' : ''} para controle de estoque sem movimentação de caixa.',
                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _fmt(resumo.totalConsumoInternoCentavos),
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── ABA 2: Histórico de Caixas ────────────────────────────────────────────

  Widget _buildAbaHistoricoCaixas(FinanceiroController ctrl) {
    final sessoes = ctrl.historicoSessoes;
    if (sessoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: FincoreColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FincoreColors.border),
        ),
        child: const Center(
          child: Text(
            'Nenhuma sessão de caixa encerrada no histórico',
            style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(FincoreColors.surface),
            dataRowMaxHeight: 52,
            columns: const [
              DataColumn(label: Text('STATUS', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('OPERADOR', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ABERTURA', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('FECHAMENTO', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('FUNDO TROCO', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('TOTAL VENDAS', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('SAÍDAS', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('VALOR CONTADO', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('DIFERENÇA (QUEBRA)', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('AÇÕES', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
            rows: sessoes.map((s) {
              final isAberta = s.status == 'aberta';
              final diferenca = s.diferencaCentavos;
              final difCor = diferenca == null || diferenca == 0
                  ? FincoreColors.textSecondary
                  : (diferenca > 0 ? FincoreColors.success : const Color(0xFFEF4444));

              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isAberta ? FincoreColors.success : FincoreColors.textMuted).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAberta ? 'ABERTA' : 'FECHADA',
                        style: TextStyle(
                          color: isAberta ? FincoreColors.success : FincoreColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(s.operadorNome, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                  DataCell(Text(_dtFormat.format(s.dataAbertura.toLocal()), style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12))),
                  DataCell(Text(s.dataFechamento != null ? _dtFormat.format(s.dataFechamento!.toLocal()) : '-', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12))),
                  DataCell(Text(_fmt(s.valorAberturaCentavos), style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12))),
                  DataCell(Text(_fmt(s.totalVendasCentavos), style: const TextStyle(color: FincoreColors.success, fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(Text(_fmt(s.totalDespesasCentavos), style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
                  DataCell(Text(s.valorFechamentoCentavos != null ? _fmt(s.valorFechamentoCentavos!) : '-', style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12))),
                  DataCell(
                    Text(
                      diferenca != null ? (diferenca > 0 ? '+${_fmt(diferenca)}' : _fmt(diferenca)) : '-',
                      style: TextStyle(color: difCor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.receipt_long_outlined, size: 18, color: FincoreColors.primary),
                      tooltip: 'Ver Detalhes do Extrato',
                      onPressed: () => _mostrarDetalhesSessao(ctrl, s),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── Diálogos & Drawers ───────────────────────────────────────────────────

  void _mostrarDetalhesSessao(FinanceiroController ctrl, SessaoCaixaData sessao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FincoreColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ExtratoSessaoDrawer(ctrl: ctrl, sessao: sessao, formatarValor: _fmt),
    );
  }

  void _mostrarDialogAbrirCaixa(FinanceiroController ctrl) {
    DialogAbrirCaixa.show(
      context,
      onConfirm: (valor, turno) async {
        await ctrl.abrirCaixa(valorAberturaCentavos: valor, nomeTurno: turno);
      },
    );
  }

  void _mostrarDialogFecharCaixa(FinanceiroController ctrl) {
    DialogFecharCaixa.show(
      context,
      resumo: ctrl.resumo,
      controller: ctrl,
      formatarValor: _fmt,
      onConfirm: (valorContado, obs) async {
        await ctrl.fecharCaixa(
          valorContadoCentavos: valorContado,
          observacoes: obs,
        );
      },
    );
  }

  void _mostrarDialogMovimento(FinanceiroController ctrl, [String initialTipo = 'sangria']) {
    DialogMovimentoCaixa.show(
      context,
      initialTipo: initialTipo,
      onConfirm: (tipo, valor, desc) async {
        await ctrl.lancarMovimento(tipo: tipo, valorCentavos: valor, descricao: desc);
      },
    );
  }
}

// ─── Widgets Internos ─────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color corIcone;
  final String subtitulo;

  const _MetricCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.corIcone,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icone, size: 18, color: corIcone),
            ],
          ),
          Text(valor, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitulo, style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _FormaPagamentoRow extends StatelessWidget {
  final String nome;
  final String valor;
  final double percentual;

  const _FormaPagamentoRow({
    required this.nome,
    required this.valor,
    required this.percentual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nome, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
              Text(valor, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentual.clamp(0.0, 1.0),
              backgroundColor: FincoreColors.border,
              color: FincoreColors.primary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer de Extrato da Sessão ─────────────────────────────────────────────

class _ExtratoSessaoDrawer extends StatefulWidget {
  final FinanceiroController ctrl;
  final SessaoCaixaData sessao;
  final String Function(int) formatarValor;

  const _ExtratoSessaoDrawer({
    required this.ctrl,
    required this.sessao,
    required this.formatarValor,
  });

  @override
  State<_ExtratoSessaoDrawer> createState() => _ExtratoSessaoDrawerState();
}

class _ExtratoSessaoDrawerState extends State<_ExtratoSessaoDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _dtFmt = DateFormat('dd/MM HH:mm');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sessao;
    final obsTurno = s.observacoes;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessão #${s.id.substring(0, 8)} ${obsTurno != null ? "· $obsTurno" : ""}',
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Operador: ${s.operadorNome} · Aberto: ${_dtFmt.format(s.dataAbertura.toLocal())}${s.dataFechamento != null ? " · Fechado: ${_dtFmt.format(s.dataFechamento!.toLocal())}" : ""}',
                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabCtrl,
            labelColor: FincoreColors.primary,
            unselectedLabelColor: FincoreColors.textMuted,
            indicatorColor: FincoreColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long_outlined, size: 16), text: 'Vendas do Turno'),
              Tab(icon: Icon(Icons.assignment_turned_in_outlined, size: 16), text: 'Notas a Prazo'),
              Tab(icon: Icon(Icons.swap_vert_rounded, size: 16), text: 'Movimentos Gaveta'),
            ],
          ),
          const Divider(color: FincoreColors.border, height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Aba 1: Vendas do Turno
                FutureBuilder<List<PedidoData>>(
                  future: widget.ctrl.carregarPedidosSessao(s.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lista = snapshot.data ?? [];
                    if (lista.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma venda registrada nesta sessão.', style: TextStyle(color: FincoreColors.textMuted)),
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
                            '${_dtFmt.format(p.dataHoraCriacao.toLocal())} · ${p.formaPagamentoNome ?? "Dinheiro"} · ${p.tipoLogistica}',
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

                // Aba 2: Notas a Prazo
                FutureBuilder<List<PedidoData>>(
                  future: widget.ctrl.carregarPedidosSessao(s.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lista = (snapshot.data ?? [])
                        .where((p) => (p.formaPagamentoNome ?? '').toLowerCase().contains('prazo') || (p.formaPagamentoNome ?? '').toLowerCase().contains('fiado'))
                        .toList();
                    if (lista.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma venda em Nota a Prazo realizada nesta sessão.', style: TextStyle(color: FincoreColors.textMuted)),
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

                // Aba 3: Movimentos de Gaveta
                FutureBuilder<List<LancamentoFinanceiroData>>(
                  future: widget.ctrl.carregarLancamentosSessao(s.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lancamentos = snapshot.data ?? [];
                    if (lancamentos.isEmpty) {
                      return const Center(
                        child: Text('Nenhum movimento avulso registrado nesta sessão', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)),
                      );
                    }
                    return ListView.separated(
                      itemCount: lancamentos.length,
                      separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final l = lancamentos[index];
                        final isCredito = l.tipo == 'suprimento' || l.tipo == 'receita';
                        final color = isCredito ? FincoreColors.success : const Color(0xFFEF4444);

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isCredito ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: color,
                            size: 20,
                          ),
                          title: Text(
                            l.descricao.isNotEmpty ? l.descricao : l.tipo.toUpperCase(),
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(_dtFmt.format(l.dataHora.toLocal()), style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                          trailing: Text(
                            '${isCredito ? '+' : '-'}${widget.formatarValor(l.valorCentavos)}',
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
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
    );
  }
}
