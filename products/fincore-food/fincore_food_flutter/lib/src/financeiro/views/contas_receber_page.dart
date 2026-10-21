import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/context/tenant_context.dart';
import '../controllers/contas_receber_controller.dart';
import '../widgets/dialog_baixa_titulo.dart';
import '../../shared/presentation/widgets/pedido_mirror_dialog.dart';
import '../../shared/presentation/widgets/whatsapp_dialog.dart';
import '../../shared/services/whatsapp_service.dart';
import '../../shared/services/pix_generator.dart';

class ContasReceberPage extends StatefulWidget {
  const ContasReceberPage({super.key});

  @override
  State<ContasReceberPage> createState() => _ContasReceberPageState();
}

class _ContasReceberPageState extends State<ContasReceberPage> {
  late ContasReceberController _controller;
  final _searchCtrl = TextEditingController();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _dateOnly = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _controller = ContasReceberController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
            _buildKpiCards(ctrl),
            const SizedBox(height: 16),
            _buildSubmenuBar(ctrl),
            const SizedBox(height: 16),
            _buildFilterBar(ctrl),
            const SizedBox(height: 16),
            Expanded(
              child: ctrl.loading
                  ? Center(
                      child: CircularProgressIndicator(color: FincoreColors.primary),
                    )
                  : ctrl.error != null
                      ? _buildErrorState(ctrl)
                      : _buildTable(ctrl),
            ),
          ],
        );
      },
    );
  }

  // ─── Submenus de Modalidade ──────────────────────────────────────────────────

  Widget _buildSubmenuBar(ContasReceberController ctrl) {
    final active = ctrl.formaPgtoFilter;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FincoreColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SubmenuTab(
              label: 'TODOS OS RECEBÍVEIS',
              icon: Icons.grid_view_rounded,
              selected: active == 'Todas' || active == 'Todos',
              onTap: () => ctrl.setFormaPgtoFilter('Todas'),
            ),
            const SizedBox(width: 8),
            _SubmenuTab(
              label: 'NOTAS A PRAZO (FIADO)',
              icon: Icons.receipt_long_rounded,
              selected: active == 'Notas a Prazo' || active == 'Nota a Prazo',
              onTap: () => ctrl.setFormaPgtoFilter('Notas a Prazo'),
            ),
            const SizedBox(width: 8),
            _SubmenuTab(
              label: 'CARTÕES A RECEBER',
              icon: Icons.credit_card_rounded,
              selected: active == 'Cartões a Receber' || active == 'Cartão' || active == 'Cartão de Crédito' || active == 'Cartão de Débito',
              onTap: () => ctrl.setFormaPgtoFilter('Cartões a Receber'),
            ),
            const SizedBox(width: 8),
            _SubmenuTab(
              label: 'PIX A RECEBER',
              icon: Icons.pix_rounded,
              selected: active == 'PIX a Receber' || active == 'PIX',
              onTap: () => ctrl.setFormaPgtoFilter('PIX a Receber'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Cards de Indicadores Financeiros (KPIs) ───────────────────────────────

  Widget _buildKpiCards(ContasReceberController ctrl) {
    final temTaxas = ctrl.totalTaxasMdrEstimadasCentavos > 0;

    return Row(
      children: [
        // 1. Total a Receber / Pendente Bruto
        Expanded(
          child: _buildMetricCard(
            title: 'TOTAL A RECEBER (BRUTO)',
            value: _fmt(ctrl.totalAReceberCentavos),
            subtitle: '${ctrl.qtdPendentes} título(s) pendente(s)',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFF59E0B),
            isAlert: ctrl.qtdPendentes > 0,
          ),
        ),
        const SizedBox(width: 12),

        // 2. Líquido Estimado (Banco após MDR)
        Expanded(
          child: _buildMetricCard(
            title: 'LÍQUIDO ESTIMADO (BANCO)',
            value: _fmt(ctrl.totalLiquidoAReceberCentavos),
            subtitle: temTaxas ? 'Taxas MDR: -${_fmt(ctrl.totalTaxasMdrEstimadasCentavos)}' : 'Sem retenção de taxas',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF0284C7),
            isAlert: false,
          ),
        ),
        const SizedBox(width: 12),

        // 3. Recebido no Período / Quitado
        Expanded(
          child: _buildMetricCard(
            title: ctrl.periodoPreset == 'hoje' ? 'RECEBIDO HOJE' : 'TOTAL RECEBIDO',
            value: _fmt(ctrl.totalRecebidoPeriodoCentavos),
            subtitle: '${ctrl.qtdRecebidos} pedido(s) quitados no filtro',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            isAlert: false,
          ),
        ),
        const SizedBox(width: 12),

        // 4. Títulos Vencidos
        Expanded(
          child: _buildMetricCard(
            title: 'TÍTULOS VENCIDOS',
            value: _fmt(ctrl.totalVencidoCentavos),
            subtitle: '${ctrl.qtdAtrasados} título(s) em atraso',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            isAlert: ctrl.totalVencidoCentavos > 0,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAlert,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? color.withValues(alpha: 0.45) : FincoreColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: FincoreColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: FincoreColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Barra de Filtros e Busca ───────────────────────────────────────────────

  Future<void> _abrirDateRangePicker(ContasReceberController ctrl) async {
    final hoje = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: ctrl.dataDe != null && ctrl.dataAte != null
          ? DateTimeRange(start: ctrl.dataDe!, end: ctrl.dataAte!)
          : DateTimeRange(start: hoje.subtract(const Duration(days: 7)), end: hoje),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: FincoreColors.primary,
              onPrimary: Colors.white,
              surface: FincoreColors.surface,
              onSurface: FincoreColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ctrl.setPeriodo(picked.start, picked.end, 'custom');
    }
  }

  Widget _buildFilterBar(ContasReceberController ctrl) {
    final formasDisponiveis = ctrl.formasPagamentoDisponiveis;
    final valorForma = formasDisponiveis.contains(ctrl.formaPgtoFilter) ? ctrl.formaPgtoFilter : 'Todas';

    String labelPeriodo = switch (ctrl.periodoPreset) {
      'hoje' => 'Hoje',
      'ontem' => 'Ontem',
      '7dias' => 'Últimos 7 dias',
      'mes' => 'Este Mês',
      'custom' => ctrl.dataDe != null && ctrl.dataAte != null
          ? '${_dateOnly.format(ctrl.dataDe!)} a ${_dateOnly.format(ctrl.dataAte!)}'
          : 'Personalizado',
      _ => 'Todo o Histórico',
    };

    final temFiltroAtivo = ctrl.statusFilter != 'Todos' ||
        ctrl.formaPgtoFilter != 'Todas' ||
        ctrl.searchQuery.isNotEmpty ||
        ctrl.dataDe != null ||
        ctrl.dataAte != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Campo de busca
          SizedBox(
            width: 320,
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ctrl.setSearchQuery(v.trim()),
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente, tel, pedido #...',
                  hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: FincoreColors.textMuted),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            ctrl.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Filtro de Status
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ctrl.statusFilter,
                dropdownColor: FincoreColors.surface,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: FincoreColors.textMuted),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos os Status')),
                  DropdownMenuItem(value: 'Pendentes', child: Text('Apenas Pendentes')),
                  DropdownMenuItem(value: 'Recebidos', child: Text('Apenas Quitados')),
                  DropdownMenuItem(value: 'Atrasados', child: Text('Apenas Atrasados')),
                ],
                onChanged: (v) {
                  if (v != null) ctrl.setStatusFilter(v);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Filtro de Modalidade / Forma de Pagamento
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ctrl.formaPgtoFilter != 'Todas' ? FincoreColors.primary.withValues(alpha: 0.6) : FincoreColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payment_rounded,
                  size: 16,
                  color: ctrl.formaPgtoFilter != 'Todas' ? FincoreColors.primary : FincoreColors.textMuted,
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: valorForma,
                    dropdownColor: FincoreColors.surface,
                    style: TextStyle(
                      color: ctrl.formaPgtoFilter != 'Todas' ? FincoreColors.primary : FincoreColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: ctrl.formaPgtoFilter != 'Todas' ? FontWeight.bold : FontWeight.normal,
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: FincoreColors.textMuted),
                    items: formasDisponiveis.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(f == 'Todas' ? 'Todas as Modalidades' : f),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) ctrl.setFormaPgtoFilter(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Filtro de Período por Data
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ctrl.periodoPreset != 'tudo' ? FincoreColors.primary.withValues(alpha: 0.6) : FincoreColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: ctrl.periodoPreset != 'tudo' ? FincoreColors.primary : FincoreColors.textMuted,
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ctrl.periodoPreset == 'custom' ? 'custom' : ctrl.periodoPreset,
                    dropdownColor: FincoreColors.surface,
                    style: TextStyle(
                      color: ctrl.periodoPreset != 'tudo' ? FincoreColors.primary : FincoreColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: ctrl.periodoPreset != 'tudo' ? FontWeight.bold : FontWeight.normal,
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: FincoreColors.textMuted),
                    items: [
                      const DropdownMenuItem(value: 'tudo', child: Text('Todo o Histórico')),
                      const DropdownMenuItem(value: 'hoje', child: Text('Hoje')),
                      const DropdownMenuItem(value: 'ontem', child: Text('Ontem')),
                      const DropdownMenuItem(value: '7dias', child: Text('Últimos 7 Dias')),
                      const DropdownMenuItem(value: 'mes', child: Text('Este Mês')),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text(ctrl.periodoPreset == 'custom' ? labelPeriodo : 'Personalizado...'),
                      ),
                    ],
                    onChanged: (v) {
                      final hoje = DateTime.now();
                      if (v == 'hoje') {
                        ctrl.setPeriodo(
                          DateTime(hoje.year, hoje.month, hoje.day),
                          DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59),
                          'hoje',
                        );
                      } else if (v == 'ontem') {
                        final ontem = hoje.subtract(const Duration(days: 1));
                        ctrl.setPeriodo(
                          DateTime(ontem.year, ontem.month, ontem.day),
                          DateTime(ontem.year, ontem.month, ontem.day, 23, 59, 59),
                          'ontem',
                        );
                      } else if (v == '7dias') {
                        final inicio = hoje.subtract(const Duration(days: 7));
                        ctrl.setPeriodo(
                          DateTime(inicio.year, inicio.month, inicio.day),
                          DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59),
                          '7dias',
                        );
                      } else if (v == 'mes') {
                        final inicio = DateTime(hoje.year, hoje.month, 1);
                        final fim = DateTime(hoje.year, hoje.month + 1, 0, 23, 59, 59);
                        ctrl.setPeriodo(inicio, fim, 'mes');
                      } else if (v == 'custom') {
                        _abrirDateRangePicker(ctrl);
                      } else {
                        ctrl.setPeriodo(null, null, 'tudo');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          if (temFiltroAtivo) ...[
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Limpar todos os filtros',
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20, color: FincoreColors.danger),
              onPressed: () {
                _searchCtrl.clear();
                ctrl.limparFiltros();
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── Tabela de Títulos ─────────────────────────────────────────────────────

  Widget _buildTable(ContasReceberController ctrl) {
    final lista = ctrl.titulosFiltrados;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: FincoreColors.border),
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 40, color: FincoreColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum título a receber encontrado',
              style: TextStyle(color: FincoreColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ajuste os filtros ou aguarde novas vendas para conciliação',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
            ),
          ],
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
        child: Column(
          children: [
            // Cabeçalho da Tabela
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: FincoreColors.surfaceElevated,
              child: const Row(
                children: [
                  SizedBox(width: 130, child: Text('PEDIDO', style: _colHeaderStyle)),
                  Expanded(flex: 3, child: Text('CLIENTE', style: _colHeaderStyle)),
                  Expanded(flex: 2, child: Text('FORMA PGTO', style: _colHeaderStyle)),
                  Expanded(flex: 2, child: Text('PEDIDO / ENTREGA', style: _colHeaderStyle)),
                  Expanded(flex: 2, child: Text('VENC. / PAGAMENTO', style: _colHeaderStyle)),
                  SizedBox(width: 110, child: Text('VALOR', style: _colHeaderStyle)),
                  SizedBox(width: 110, child: Text('STATUS', style: _colHeaderStyle)),
                  SizedBox(width: 160, child: Text('AÇÕES', textAlign: TextAlign.end, style: _colHeaderStyle)),
                ],
              ),
            ),
            const Divider(height: 1, color: FincoreColors.border),

            // Linhas
            Expanded(
              child: ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
                itemBuilder: (context, index) {
                  final item = lista[index];
                  return _buildTableRow(item, ctrl);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _colHeaderStyle = TextStyle(
    color: FincoreColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.6,
  );

  Widget _buildTableRow(TituloReceber item, ContasReceberController ctrl) {
    final isPix = item.formaPagamentoTipo == 'pix' || item.formaPagamentoNome.toLowerCase().contains('pix');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          // Pedido # + Visualizador
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.friendlyNumeroPedido,
                        style: const TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.canalOrigem == 'pdv_express' ? 'PDV Express' : item.canalOrigem.toUpperCase(),
                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => PedidoMirrorDialog.show(
                    context,
                    pedidoId: item.pedidoId,
                    numeroPedido: item.numeroPedido,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 12, color: FincoreColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          'Ver',
                          style: TextStyle(
                            color: FincoreColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cliente
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clienteNome,
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.clienteTelefone != null && item.clienteTelefone!.isNotEmpty)
                  Text(
                    item.clienteTelefone!,
                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5),
                  ),
              ],
            ),
          ),

          // Forma de Pagamento
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  isPix
                      ? Icons.pix
                      : item.formaPagamentoNome.toLowerCase().contains('cart')
                          ? Icons.credit_card_rounded
                          : Icons.account_balance_wallet_rounded,
                  size: 15,
                  color: isPix ? const Color(0xFF32BCAD) : FincoreColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.formaPagamentoNome,
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Pedido / Data de Entrega
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido: ${_dateFormat.format(item.dataEmissao)}',
                  style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5),
                ),
                Text(
                  'Entrega: ${_dateFormat.format(item.dataEntrega)}',
                  style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Vencimento / Data do Pagamento / Previsão Repasse
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isRecebido) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Pago em: ${_dateFormat.format(item.dataRecebimento ?? item.dataEmissao)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else if (item.isCartao) ...[
                  Text(
                    'Previsão Repasse (D+${item.prazoRepasseDias}):',
                    style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _dateFormat.format(item.dataVencimento),
                    style: TextStyle(
                      color: item.isAtrasado ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Venc: ${_dateFormat.format(item.dataVencimento)}',
                    style: TextStyle(
                      color: item.isAtrasado ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      fontSize: 11.5,
                      fontWeight: item.isAtrasado ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Valor
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmt(item.valorTotalCentavos),
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.isCartao && item.valorTaxaCentavos > 0)
                  Text(
                    'Líq: ${_fmt(item.valorLiquidoCentavos)}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Status Pill
          SizedBox(
            width: 120,
            child: _buildStatusPill(item),
          ),

          // Ações
          SizedBox(
            width: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botão Detalhes
                IconButton(
                  icon: Icon(Icons.info_outline_rounded, size: 18, color: FincoreColors.primary),
                  tooltip: 'Detalhes do Recebível',
                  style: IconButton.styleFrom(
                    backgroundColor: FincoreColors.primary.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _abrirDetalhesTitulo(item, ctrl),
                ),
                const SizedBox(width: 6),

                // Botão WhatsApp (apenas para Nota a Prazo / Fiado pendente de cliente)
                if (item.isNotaPrazo && (item.isPendente || item.isAtrasado) && item.clienteTelefone != null && item.clienteTelefone!.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                    tooltip: 'Cobrar Fiado via WhatsApp',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _abrirWhatsAppCobrar(item),
                  ),
                  const SizedBox(width: 6),
                ],

                // Botão Dar Baixa (se pendente ou atrasado) ou Estornar (se quitado)
                if (item.isPendente || item.isAtrasado)
                  ElevatedButton(
                    onPressed: () => _mostrarDialogDarBaixa(item, ctrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Baixar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Estornar Baixa Financeira',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _mostrarDialogEstorno(item, ctrl),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(TituloReceber item) {
    final Color color;
    final String label;
    final IconData icon;

    if (item.isRecebido) {
      color = const Color(0xFF10B981);
      label = item.isPix ? 'Recebido (PIX)' : 'Recebido';
      icon = Icons.check_circle_rounded;
    } else if (item.isCartao) {
      if (item.isAtrasado) {
        color = const Color(0xFFEF4444);
        label = 'Repasse Atrasado';
        icon = Icons.error_outline_rounded;
      } else {
        color = const Color(0xFF0284C7);
        label = 'Repasse D+${item.prazoRepasseDias}';
        icon = Icons.schedule_rounded;
      }
    } else if (item.isNotaPrazo) {
      if (item.isAtrasado) {
        color = const Color(0xFFEF4444);
        label = 'Fiado Atrasado';
        icon = Icons.warning_amber_rounded;
      } else {
        color = const Color(0xFFF59E0B);
        label = 'Fiado a Receber';
        icon = Icons.hourglass_empty_rounded;
      }
    } else {
      switch (item.status) {
        case StatusTituloReceber.pendente:
          color = const Color(0xFFF59E0B);
          label = 'Pendente';
          icon = Icons.hourglass_empty_rounded;
          break;
        case StatusTituloReceber.recebido:
          color = const Color(0xFF10B981);
          label = 'Recebido';
          icon = Icons.check_circle_rounded;
          break;
        case StatusTituloReceber.atrasado:
          color = const Color(0xFFEF4444);
          label = 'Atrasado';
          icon = Icons.error_outline_rounded;
          break;
        case StatusTituloReceber.cancelado:
          color = FincoreColors.textMuted;
          label = 'Cancelado';
          icon = Icons.cancel_outlined;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modal de Estorno de Baixa com Motivo ───────────────────────────

  Future<void> _mostrarDialogEstorno(TituloReceber item, ContasReceberController ctrl) async {
    final controllerMotivo = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Estornar Baixa Financeira?', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deseja realmente estornar a baixa do pedido #${item.friendlyNumeroPedido}? O lançamento do caixa será desfeito e o evento gravado na timeline.',
                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllerMotivo,
                autofocus: true,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Motivo do Estorno *',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                  hintText: 'Ex: Pagamento duplicado / Cliente desistiu',
                  hintStyle: TextStyle(color: FincoreColors.textMuted.withValues(alpha: 0.5), fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: FincoreColors.background,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o motivo do estorno';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controllerMotivo.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Estornar Baixa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.isEmpty) return;

    final ok = await ctrl.estornarBaixaPorPedidoId(pedidoId: item.pedidoId, motivoEstorno: motivo);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.warning,
          content: Text('Baixa financeira estornada com sucesso!'),
        ),
      );
    }
  }

  // ─── Modal de Detalhes do Título ──────────────────────────────────────────

  void _abrirDetalhesTitulo(TituloReceber item, ContasReceberController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de topo
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: FincoreColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: FincoreColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Detalhes do Recebível #${item.friendlyNumeroPedido}',
                        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: FincoreColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: FincoreColors.border, height: 24),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    // Seção 1: Cliente e Pedido
                    _buildDetalheGroup(
                      title: 'INFORMAÇÕES DO CLIENTE E CANAL',
                      children: [
                        _buildDetalheRow('Cliente', item.clienteNome),
                        if (item.clienteTelefone != null && item.clienteTelefone!.isNotEmpty)
                          _buildDetalheRow('Telefone', item.clienteTelefone!),
                        _buildDetalheRow('Canal de Origem', item.canalOrigem.toUpperCase()),
                        _buildDetalheRow('Data do Pedido', _dateFormat.format(item.dataEmissao)),
                        _buildDetalheRow('Data de Entrega', _dateFormat.format(item.dataEntrega)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Seção 2: Financeiro & MDR
                    _buildDetalheGroup(
                      title: 'DESCOMPOSIÇÃO DE VALORES (FINANCEIRO)',
                      children: [
                        _buildDetalheRow('Forma de Pagamento', item.formaPagamentoNome),
                        _buildDetalheRow('Valor Bruto', _fmt(item.valorTotalCentavos), bold: true),
                        if (item.isCartao) ...[
                          _buildDetalheRow('Prazo de Repasse', 'D+${item.prazoRepasseDias} dias'),
                          _buildDetalheRow('Taxa MDR Retida', '-${_fmt(item.valorTaxaCentavos)}', color: const Color(0xFFEF4444)),
                          _buildDetalheRow('Líquido a Entrar no Banco', _fmt(item.valorLiquidoCentavos), bold: true, color: const Color(0xFF10B981)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Seção 3: Status & Quitação
                    _buildDetalheGroup(
                      title: 'STATUS E HISTÓRICO DE QUITAÇÃO',
                      children: [
                        _buildDetalheRow('Status Atual', item.status.name.toUpperCase(), bold: true),
                        _buildDetalheRow('Data de Vencimento', _dateFormat.format(item.dataVencimento)),
                        if (item.isRecebido) ...[
                          _buildDetalheRow('Data da Baixa', _dateFormat.format(item.dataRecebimento ?? item.dataEmissao), color: const Color(0xFF10B981), bold: true),
                          _buildDetalheRow('Meio de Quitação', item.formaPagamentoNome),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fechar', style: TextStyle(color: FincoreColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  if (item.isPendente || item.isAtrasado)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Dar Baixa Agora'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _mostrarDialogDarBaixa(item, ctrl);
                      },
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      label: const Text('Estornar Baixa'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _mostrarDialogEstorno(item, ctrl);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalheGroup({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetalheRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              color: color ?? FincoreColors.textPrimary,
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modal de Baixa ────────────────────────────────────────────────────────

  Future<void> _mostrarDialogDarBaixa(TituloReceber item, ContasReceberController ctrl) async {
    final ok = await DialogBaixaTitulo.show(context, item: item, controller: ctrl);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.success,
          content: Text('Baixa confirmada com sucesso!'),
        ),
      );
    }
  }

  // ─── Cobrança via WhatsApp ─────────────────────────────────────────────────

  Future<void> _abrirWhatsAppCobrar(TituloReceber item) async {
    if (item.clienteTelefone == null || item.clienteTelefone!.isEmpty) return;

    String? empresaNome;
    try {
      if (TenantContext().hasContext) {
        empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
            ? TenantContext().empresa.nomeFantasia
            : TenantContext().empresa.razaoSocial;
      }
    } catch (_) {}

    PixWhatsAppInfo? pixInfo;
    if (item.pixChave != null && item.pixChave!.isNotEmpty) {
      final copiaECola = PixGenerator.gerarCopiaCola(
        chave: item.pixChave!,
        favorecido: empresaNome ?? 'Nossa Loja',
        cidade: 'Sorocaba',
        valor: item.valorTotalCentavos / 100.0,
        tipoChave: item.pixTipoChave,
      );

      pixInfo = PixWhatsAppInfo(
        chaveDisplay: item.pixChave!,
        tipoChave: item.pixTipoChave ?? 'PIX',
        copiaECola: copiaECola,
      );
    }

    final initialMsg = WhatsAppService.gerarTextoLembretePagamento(
      nomeCliente: item.clienteNome,
      numeroPedidoOuId: item.friendlyNumeroPedido,
      valor: item.valorTotalCentavos / 100.0,
      dataVencimento: _dateOnly.format(item.dataVencimento),
      nomeEmpresa: empresaNome,
    );

    await WhatsAppDialog.show(
      context,
      rawPhone: item.clienteTelefone!,
      clienteNome: item.clienteNome,
      initialMessage: initialMsg,
      initialTemplateId: 'cobranca_pix',
      pixInfo: pixInfo,
      numeroPedido: item.friendlyNumeroPedido,
      nomeEmpresa: empresaNome,
    );
  }

  Widget _buildErrorState(ContasReceberController ctrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: FincoreColors.danger),
          const SizedBox(height: 12),
          Text(
            ctrl.error ?? 'Erro desconhecido',
            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ctrl.carregar(),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}

class _SubmenuTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubmenuTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? FincoreColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? FincoreColors.primary : FincoreColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? FincoreColors.primary : FincoreColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
