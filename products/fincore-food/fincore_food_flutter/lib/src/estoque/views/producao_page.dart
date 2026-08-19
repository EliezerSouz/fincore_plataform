import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import '../controllers/estoque_controller.dart';


/// Tela de Gestão de Produção e Agenda de Reservas.
///
/// Painel A — Lista de produtos com:
///   Físico | Reservado | Disponível | Mínimo
///   Badge preditivo de necessidade de produção.
///
/// Painel B — Agenda: reservas futuras ordenadas por data de entrega.
class ProducaoPage extends StatefulWidget {
  const ProducaoPage({super.key});

  @override
  State<ProducaoPage> createState() => _ProducaoPageState();
}

class _ProducaoPageState extends State<ProducaoPage>
    with SingleTickerProviderStateMixin {
  late EstoqueController _controller;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _controller = EstoqueController();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<EstoqueController>(
        builder: (context, ctrl, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ctrl),
              const SizedBox(height: 12),
              _buildTabBar(),
              const SizedBox(height: 16),
              if (ctrl.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildPainelProdutos(ctrl),
                      _buildPainelAgenda(ctrl),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(EstoqueController ctrl) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Produção & Estoque',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${ctrl.itens.length} produto${ctrl.itens.length != 1 ? 's' : ''} · '
                '${ctrl.qtdAlertasUrgentes > 0 ? '${ctrl.qtdAlertasUrgentes} com alerta' : 'estoque ok'}',
                style: TextStyle(
                  color: ctrl.qtdAlertasUrgentes > 0
                      ? const Color(0xFFE05C5C)
                      : FincoreColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: FincoreColors.textMuted),
          onPressed: () => ctrl.refresh(),
        ),
        const SizedBox(width: 8),
        // Botão principal de produção
        Consumer<EstoqueController>(
          builder: (_, ctrl, __) => GestureDetector(
            onTap: () => _abrirRegistroProducao(ctrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FincoreColors.primary, FincoreColors.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: FincoreColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Registrar Produção',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          color: FincoreColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: FincoreColors.primary.withOpacity(0.4)),
        ),
        labelColor: FincoreColors.primary,
        unselectedLabelColor: FincoreColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Situação de Estoque'),
          Tab(text: 'Agenda de Entregas'),
        ],
      ),
    );
  }

  // ─── Painel A: Situação de Estoque ────────────────────────────────────────

  Widget _buildPainelProdutos(EstoqueController ctrl) {
    if (ctrl.itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: FincoreColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nenhum produto com controle de estoque ativo',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ative "Controla Estoque" no cadastro dos produtos.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da tabela
        _buildCabecalhoTabela(),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            itemCount: ctrl.itens.length,
            separatorBuilder: (_, __) =>
                const Divider(color: FincoreColors.border, height: 1),
            itemBuilder: (context, i) => _ProdutoEstoqueRow(
              item: ctrl.itens[i],
              onProducao: () => _abrirRegistroProducaoParaProduto(ctrl, ctrl.itens[i]),
              onHistorico: () => _abrirHistorico(ctrl, ctrl.itens[i]),
              onConfigurar: () => _abrirConfigurar(ctrl, ctrl.itens[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalhoTabela() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'PRODUTO',
              style: TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ..._colLabel('FÍSICO'),
          ..._colLabel('RESERVADO'),
          ..._colLabel('DISPONÍVEL'),
          ..._colLabel('MÍNIMO'),
          const SizedBox(width: 90),
        ],
      ),
    );
  }

  List<Widget> _colLabel(String label) => [
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FincoreColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ];

  // ─── Painel B: Agenda de Reservas ─────────────────────────────────────────

  Widget _buildPainelAgenda(EstoqueController ctrl) {
    if (ctrl.reservasAgendadas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined,
                color: FincoreColors.success, size: 48),
            SizedBox(height: 16),
            Text(
              'Nenhuma entrega futura com estoque reservado',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'As reservas aparecem aqui ao confirmar pedidos com data futura.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupa por data de entrega
    final Map<String, List<ReservaAgendada>> porData = {};
    for (final r in ctrl.reservasAgendadas) {
      final key = DateFormat('dd/MM/yyyy — EEEE', 'pt_BR').format(r.dataEntrega);
      porData.putIfAbsent(key, () => []).add(r);
    }

    return ListView.builder(
      itemCount: porData.length,
      itemBuilder: (context, i) {
        final dataKey = porData.keys.elementAt(i);
        final reservasDoDia = porData[dataKey]!;

        // Total por produto naquele dia
        final Map<String, int> totalPorProduto = {};
        for (final r in reservasDoDia) {
          totalPorProduto[r.nomeProduto] =
              (totalPorProduto[r.nomeProduto] ?? 0) + r.quantidade;
        }

        final dataEntrega = reservasDoDia.first.dataEntrega;
        final diasAte = dataEntrega.difference(DateTime.now()).inDays;
        final urgente = diasAte <= 1;
        final atencao = diasAte <= 3 && diasAte > 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: urgente
                ? const Color(0xFFE05C5C).withOpacity(0.06)
                : atencao
                    ? const Color(0xFFE89F2A).withOpacity(0.06)
                    : FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: urgente
                  ? const Color(0xFFE05C5C).withOpacity(0.3)
                  : atencao
                      ? const Color(0xFFE89F2A).withOpacity(0.3)
                      : FincoreColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      urgente
                          ? Icons.warning_amber_rounded
                          : Icons.calendar_today_rounded,
                      size: 16,
                      color: urgente
                          ? const Color(0xFFE05C5C)
                          : atencao
                              ? const Color(0xFFE89F2A)
                              : FincoreColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dataKey.toUpperCase(),
                        style: TextStyle(
                          color: urgente
                              ? const Color(0xFFE05C5C)
                              : atencao
                                  ? const Color(0xFFE89F2A)
                                  : FincoreColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    // Badge de urgência
                    if (urgente || atencao)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: urgente
                              ? const Color(0xFFE05C5C).withOpacity(0.15)
                              : const Color(0xFFE89F2A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          urgente ? '⚠️ Amanhã!' : 'Em $diasAte dias',
                          style: TextStyle(
                            color: urgente
                                ? const Color(0xFFE05C5C)
                                : const Color(0xFFE89F2A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: FincoreColors.border, height: 1),
              ...totalPorProduto.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.kitchen_rounded,
                            size: 14, color: FincoreColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                                color: FincoreColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${e.value} un',
                          style: TextStyle(
                            color: urgente
                                ? const Color(0xFFE05C5C)
                                : FincoreColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  // ─── Ações ────────────────────────────────────────────────────────────────

  void _abrirRegistroProducao(EstoqueController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _RegistrarProducaoDialog(
        controller: ctrl,
        produtoPreSelecionado: null,
      ),
    );
  }

  void _abrirRegistroProducaoParaProduto(
      EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _RegistrarProducaoDialog(
        controller: ctrl,
        produtoPreSelecionado: item,
      ),
    );
  }

  void _abrirHistorico(EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _HistoricoDialog(
        controller: ctrl,
        item: item,
      ),
    );
  }

  void _abrirConfigurar(EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _ConfigurarDialog(
        controller: ctrl,
        item: item,
      ),
    );
  }
}

// ─── Linha de Produto na Tabela ───────────────────────────────────────────────

class _ProdutoEstoqueRow extends StatelessWidget {
  final EstoqueItem item;
  final VoidCallback onProducao;
  final VoidCallback onHistorico;
  final VoidCallback onConfigurar;

  const _ProdutoEstoqueRow({
    required this.item,
    required this.onProducao,
    required this.onHistorico,
    required this.onConfigurar,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          // Faixa de cor do produto
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: item.corEtiqueta != null
                  ? Color(int.tryParse(
                          '0xFF${item.corEtiqueta!.replaceAll('#', '')}') ??
                      0xFF6C63FF)
                  : FincoreColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          // Nome + badge de status
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nomeProduto,
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.sugestaoProducao > 0)
                  Text(
                    '▲ Produzir ${item.sugestaoProducao} ${item.unidade}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Colunas numéricas
          _NumCell(value: item.quantidadeAtual, unit: item.unidade, color: FincoreColors.textSecondary),
          _NumCell(
            value: item.quantidadeReservada,
            unit: item.unidade,
            color: item.quantidadeReservada > 0
                ? const Color(0xFFE89F2A)
                : FincoreColors.textMuted,
          ),
          _NumCell(
            value: item.quantidadeDisponivel,
            unit: item.unidade,
            color: statusColor,
            bold: true,
          ),
          _NumCell(
            value: item.quantidadeMinima,
            unit: item.unidade,
            color: FincoreColors.textMuted,
          ),

          // Botões de ação
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MiniIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Registrar Produção',
                  color: FincoreColors.primary,
                  onTap: onProducao,
                ),
                const SizedBox(width: 4),
                _MiniIconButton(
                  icon: Icons.history_rounded,
                  tooltip: 'Histórico',
                  color: FincoreColors.textMuted,
                  onTap: onHistorico,
                ),
                const SizedBox(width: 4),
                _MiniIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Configurar',
                  color: FincoreColors.textMuted,
                  onTap: onConfigurar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(EstoqueStatus s) {
    switch (s) {
      case EstoqueStatus.normal:
        return FincoreColors.success;
      case EstoqueStatus.baixo:
        return const Color(0xFFE89F2A);
      case EstoqueStatus.critico:
        return const Color(0xFFE05C5C);
    }
  }
}

class _NumCell extends StatelessWidget {
  final int value;
  final String unit;
  final Color color;
  final bool bold;

  const _NumCell({
    required this.value,
    required this.unit,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: bold ? 14 : 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Dialog: Registrar Produção ───────────────────────────────────────────────

class _RegistrarProducaoDialog extends StatefulWidget {
  final EstoqueController controller;
  final EstoqueItem? produtoPreSelecionado;

  const _RegistrarProducaoDialog({
    required this.controller,
    this.produtoPreSelecionado,
  });

  @override
  State<_RegistrarProducaoDialog> createState() =>
      _RegistrarProducaoDialogState();
}

class _RegistrarProducaoDialogState extends State<_RegistrarProducaoDialog> {
  EstoqueItem? _produtoSelecionado;
  final _qtdCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  DateTime _dataProducao = DateTime.now();
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _produtoSelecionado = widget.produtoPreSelecionado;
    if (_produtoSelecionado != null) {
      // Pré-preenche com o tamanho do lote sugerido
      _qtdCtrl.text = _produtoSelecionado!.quantidadeProducaoLote.toString();
    }
    _motivoCtrl.text = 'Produção turno — ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.controller.itens;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: FincoreColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded, color: FincoreColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Registrar Produção',
              style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seleção do produto
            const Text('Produto',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<EstoqueItem>(
              value: _produtoSelecionado,
              decoration: InputDecoration(
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Selecionar produto',
                  style: TextStyle(color: FincoreColors.textMuted)),
              dropdownColor: FincoreColors.surfaceElevated,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              items: itens
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Row(
                          children: [
                            Text(item.nomeProduto),
                            const SizedBox(width: 8),
                            Text(
                              '(${item.quantidadeDisponivel} disponível)',
                              style: const TextStyle(
                                  color: FincoreColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _produtoSelecionado = v;
                if (v != null && _qtdCtrl.text.isEmpty) {
                  _qtdCtrl.text = v.quantidadeProducaoLote.toString();
                }
              }),
            ),

            const SizedBox(height: 16),

            // Quantidade produzida
            const Text('Quantidade Produzida',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _qtdCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                suffixText: _produtoSelecionado?.unidade ?? 'un',
                suffixStyle: const TextStyle(color: FincoreColors.textMuted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (_produtoSelecionado != null) ...[
              const SizedBox(height: 4),
              Text(
                'Lote sugerido: ${_produtoSelecionado!.quantidadeProducaoLote} ${_produtoSelecionado!.unidade}',
                style: const TextStyle(
                    color: FincoreColors.textMuted, fontSize: 11),
              ),
            ],

            const SizedBox(height: 16),

            // Data de produção
            const Text('Data de Produção',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataProducao,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dataProducao = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: FincoreColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy — EEEE', 'pt_BR')
                          .format(_dataProducao),
                      style: const TextStyle(
                          color: FincoreColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Motivo / Observações (obrigatório)
            const Text('Observações',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _motivoCtrl,
              style: const TextStyle(
                  color: FincoreColors.textPrimary, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: Produção turno manhã — responsável: papai',
                hintStyle:
                    const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(_erro!,
                  style: const TextStyle(
                      color: Color(0xFFE05C5C), fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _confirmar,
          style: FilledButton.styleFrom(
            backgroundColor: FincoreColors.primary,
          ),
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded, size: 16),
          label: const Text('Confirmar Produção'),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    setState(() => _erro = null);

    final produto = _produtoSelecionado;
    if (produto == null) {
      setState(() => _erro = 'Selecione um produto.');
      return;
    }
    final qty = int.tryParse(_qtdCtrl.text);
    if (qty == null || qty <= 0) {
      setState(() => _erro = 'Informe uma quantidade válida.');
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Informe uma observação (obrigatório).');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.controller.registrarProducao(
        produtoId: produto.estoque.produtoId,
        quantidade: qty,
        motivo: _motivoCtrl.text.trim(),
        dataProducao: _dataProducao,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Dialog: Histórico de Movimentações ────────────────────────────────────────

class _HistoricoDialog extends StatefulWidget {
  final EstoqueController controller;
  final EstoqueItem item;

  const _HistoricoDialog({required this.controller, required this.item});

  @override
  State<_HistoricoDialog> createState() => _HistoricoDialogState();
}

class _HistoricoDialogState extends State<_HistoricoDialog> {
  List<MovimentacaoEstoqueData>? _historico;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await widget.controller.carregarHistorico(
      produtoId: widget.item.estoque.produtoId,
    );
    if (mounted) setState(() => _historico = h);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Text('Histórico — ${widget.item.nomeProduto}',
          style: const TextStyle(
              color: FincoreColors.textPrimary, fontSize: 15)),
      content: SizedBox(
        width: 480,
        height: 400,
        child: _historico == null
            ? const Center(child: CircularProgressIndicator())
            : _historico!.isEmpty
                ? const Center(
                    child: Text('Nenhuma movimentação registrada',
                        style: TextStyle(color: FincoreColors.textMuted)))
                : ListView.separated(
                    itemCount: _historico!.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: FincoreColors.border, height: 1),
                    itemBuilder: (context, i) {
                      final m = _historico![i];
                      return _MovimentacaoRow(mov: m);
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
      ],
    );
  }
}

class _MovimentacaoRow extends StatelessWidget {
  final MovimentacaoEstoqueData mov;
  const _MovimentacaoRow({required this.mov});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _tipoInfo(mov.tipo);
    final delta = _deltaText(mov);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                if (mov.motivo.isNotEmpty)
                  Text(mov.motivo,
                      style: const TextStyle(
                          color: FincoreColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(delta,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text(
                DateFormat('dd/MM HH:mm').format(mov.dataHora),
                style: const TextStyle(
                    color: FincoreColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _tipoInfo(String tipo) {
    return switch (tipo) {
      'producao' => (Icons.factory_rounded, FincoreColors.success, 'Produção'),
      'reserva' => (Icons.bookmark_added_rounded, const Color(0xFFE89F2A), 'Reserva'),
      'liberacao_reserva' => (Icons.bookmark_remove_rounded, FincoreColors.textMuted, 'Reserva Liberada'),
      'expedicao' => (Icons.local_shipping_rounded, FincoreColors.primary, 'Expedição'),
      'ajuste_positivo' => (Icons.add_circle_rounded, FincoreColors.success, 'Ajuste +'),
      'ajuste_negativo' => (Icons.remove_circle_rounded, const Color(0xFFE05C5C), 'Ajuste −'),
      'inventario' => (Icons.assignment_rounded, FincoreColors.info, 'Inventário'),
      'saida' || 'cancelamento' => (Icons.remove_shopping_cart_rounded, const Color(0xFFE05C5C), 'Saída'),
      _ => (Icons.swap_horiz_rounded, FincoreColors.textMuted, tipo),
    };
  }

  String _deltaText(MovimentacaoEstoqueData mov) {
    final delta = mov.quantidadeDepois - mov.quantidadeAntes;
    final sign = delta >= 0 ? '+' : '';
    return '$sign$delta un';
  }
}

// ─── Dialog: Configurar Parâmetros ───────────────────────────────────────────────

class _ConfigurarDialog extends StatefulWidget {
  final EstoqueController controller;
  final EstoqueItem item;

  const _ConfigurarDialog({required this.controller, required this.item});

  @override
  State<_ConfigurarDialog> createState() => _ConfigurarDialogState();
}

class _ConfigurarDialogState extends State<_ConfigurarDialog> {
  late TextEditingController _minimoCtrl;
  late TextEditingController _loteCtrl;
  late TextEditingController _coberCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _minimoCtrl =
        TextEditingController(text: widget.item.quantidadeMinima.toString());
    _loteCtrl = TextEditingController(
        text: widget.item.quantidadeProducaoLote.toString());
    _coberCtrl =
        TextEditingController(text: widget.item.diasCoberturaAlvo.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Text(
        'Configurar — ${widget.item.nomeProduto}',
        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Campo(
              label: 'Estoque Mínimo Disponível (alerta)',
              hint: 'ex: 300',
              controller: _minimoCtrl,
              subtitle: 'Alerta quando Físico − Reservado ≤ este valor',
            ),
            const SizedBox(height: 14),
            _Campo(
              label: 'Tamanho Sugerido de Lote (un)',
              hint: 'ex: 200',
              controller: _loteCtrl,
              subtitle: 'Pré-preenchido ao registrar produção',
            ),
            const SizedBox(height: 14),
            _Campo(
              label: 'Cobertura Alvo (dias)',
              hint: 'ex: 3',
              controller: _coberCtrl,
              subtitle: 'Dias de operação que o estoque deve cobrir',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _salvar,
          child: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    setState(() => _loading = true);
    await widget.controller.configurarParametros(
      estoqueId: widget.item.estoque.id,
      quantidadeMinima: int.tryParse(_minimoCtrl.text),
      quantidadeProducaoLote: int.tryParse(_loteCtrl.text),
      diasCoberturaAlvo: int.tryParse(_coberCtrl.text),
    );
    if (mounted) Navigator.pop(context);
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final String hint;
  final String subtitle;
  final TextEditingController controller;

  const _Campo({
    required this.label,
    required this.hint,
    required this.subtitle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              color: FincoreColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: FincoreColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FincoreColors.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                color: FincoreColors.textMuted, fontSize: 10)),
      ],
    );
  }
}
