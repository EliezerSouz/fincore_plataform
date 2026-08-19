import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../controllers/estoque_controller.dart';

/// Tela de Controle de Estoque de Produtos Acabados
class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  late EstoqueController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EstoqueController();
  }

  @override
  void dispose() {
    _controller.dispose();
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
              const SizedBox(height: 20),
              if (ctrl.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (ctrl.error != null)
                Expanded(
                  child: Center(
                    child: Text(ctrl.error!, style: const TextStyle(color: FincoreColors.danger)),
                  ),
                )
              else
                Expanded(child: _buildBody(ctrl)),
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
                'Estoque',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${ctrl.itens.length} produto${ctrl.itens.length != 1 ? 's' : ''} com controle ativo',
                style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: FincoreColors.textMuted),
          onPressed: () => ctrl.refresh(),
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(EstoqueController ctrl) {
    if (ctrl.itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FincoreColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, color: FincoreColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum produto com controle de estoque',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ative "Controla Estoque" no cadastro dos seus produtos.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alertas no topo
        if (ctrl.temAlertas) ...[
          _buildAlertas(ctrl),
          const SizedBox(height: 20),
        ],

        // Lista completa
        const Text(
          'TODOS OS PRODUTOS',
          style: TextStyle(
            color: FincoreColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: ctrl.itens.length,
            separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
            itemBuilder: (context, i) => _EstoqueItemTile(
              item: ctrl.itens[i],
              onAjuste: () => _mostrarAjuste(context, ctrl, ctrl.itens[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Alertas ──────────────────────────────────────────────────────────────

  Widget _buildAlertas(EstoqueController ctrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE05C5C).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE05C5C).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE05C5C)),
              SizedBox(width: 8),
              Text(
                'ALERTAS DE ESTOQUE',
                style: TextStyle(
                  color: Color(0xFFE05C5C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...ctrl.itensCriticos.map((item) => _AlertaRow(
            nome: item.nomeProduto,
            qtd: item.quantidadeAtual,
            unidade: item.unidade,
            status: EstoqueStatus.critico,
          )),
          ...ctrl.itensBaixos.map((item) => _AlertaRow(
            nome: item.nomeProduto,
            qtd: item.quantidadeAtual,
            unidade: item.unidade,
            status: EstoqueStatus.baixo,
          )),
        ],
      ),
    );
  }

  // ─── Ajuste Dialog ────────────────────────────────────────────────────────

  void _mostrarAjuste(BuildContext context, EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _DialogAjusteEstoque(
        nomeProduto: item.nomeProduto,
        quantidadeAtual: item.quantidadeAtual,
        unidade: item.unidade,
        onConfirm: (quantidade, tipo, motivo) async {
          await ctrl.ajustarEstoque(
            produtoId: item.estoque.produtoId,
            quantidade: quantidade,
            tipo: tipo,
            motivo: motivo,
          );
        },
      ),
    );
  }
}

// ─── Widgets Internos ─────────────────────────────────────────────────────────

class _EstoqueItemTile extends StatelessWidget {
  final EstoqueItem item;
  final VoidCallback onAjuste;

  const _EstoqueItemTile({required this.item, required this.onAjuste});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    final pct = item.quantidadeMaxima > 0
        ? (item.quantidadeAtual / item.quantidadeMaxima).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          // Indicador de cor do produto
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: item.corEtiqueta != null
                  ? Color(int.tryParse('0xFF${item.corEtiqueta!.replaceAll('#', '')}') ?? 0xFF6C63FF)
                  : FincoreColors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nomeProduto,
                        style: const TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Badge de status
                    _StatusBadge(status: item.status),
                    const SizedBox(width: 8),
                    // Botão de ajuste
                    GestureDetector(
                      onTap: onAjuste,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FincoreColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: const Text(
                          'Ajustar',
                          style: TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: FincoreColors.border,
                          color: color,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.quantidadeAtual} ${item.unidade}',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.quantidadeMinima > 0)
                      Text(
                        ' / mín ${item.quantidadeMinima}',
                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                      ),
                  ],
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

class _StatusBadge extends StatelessWidget {
  final EstoqueStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EstoqueStatus.normal => ('Normal', FincoreColors.success),
      EstoqueStatus.baixo => ('Baixo', const Color(0xFFE89F2A)),
      EstoqueStatus.critico => ('Crítico', const Color(0xFFE05C5C)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AlertaRow extends StatelessWidget {
  final String nome;
  final int qtd;
  final String unidade;
  final EstoqueStatus status;

  const _AlertaRow({
    required this.nome,
    required this.qtd,
    required this.unidade,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == EstoqueStatus.critico
        ? const Color(0xFFE05C5C)
        : const Color(0xFFE89F2A);
    final label = status == EstoqueStatus.critico ? '🔴' : '🟡';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(nome, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
          ),
          Text(
            '$qtd $unidade',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DialogAjusteEstoque extends StatefulWidget {
  final String nomeProduto;
  final int quantidadeAtual;
  final String unidade;
  final Future<void> Function(int quantidade, String tipo, String motivo) onConfirm;

  const _DialogAjusteEstoque({
    required this.nomeProduto,
    required this.quantidadeAtual,
    required this.unidade,
    required this.onConfirm,
  });

  @override
  State<_DialogAjusteEstoque> createState() => _DialogAjusteEstoqueState();
}

class _DialogAjusteEstoqueState extends State<_DialogAjusteEstoque> {
  String _tipo = 'entrada';
  final _qCtrl = TextEditingController();
  final _mCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Text(
        'Ajustar Estoque — ${widget.nomeProduto}',
        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo atual: ${widget.quantidadeAtual} ${widget.unidade}',
            style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: _tipo,
            isExpanded: true,
            dropdownColor: FincoreColors.surface,
            style: const TextStyle(color: FincoreColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'entrada', child: Text('Entrada (compra/recebimento)')),
              DropdownMenuItem(value: 'ajuste_positivo', child: Text('Ajuste Positivo')),
              DropdownMenuItem(value: 'ajuste_negativo', child: Text('Ajuste Negativo (perda)')),
              DropdownMenuItem(value: 'inventario', child: Text('Inventário (definir saldo)')),
            ],
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: FincoreColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Quantidade (${widget.unidade})',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mCtrl,
            style: const TextStyle(color: FincoreColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Motivo / Observação',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  final qty = int.tryParse(_qCtrl.text);
                  if (qty == null || qty <= 0) return;
                  setState(() => _loading = true);
                  await widget.onConfirm(qty, _tipo, _mCtrl.text.isEmpty ? _tipo : _mCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
