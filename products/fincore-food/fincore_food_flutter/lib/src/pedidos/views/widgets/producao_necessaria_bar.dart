import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';

/// Faixa de "Produção Necessária" — exibe os itens consolidados por janelas operacionais de entrega.
class ProducaoNecessariaBar extends StatelessWidget {
  final CentralPedidosController controller;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ProducaoNecessariaBar({
    super.key,
    required this.controller,
    required this.isExpanded,
    required this.onToggle,
  });

  void _abrirRegistroProducaoDialog(
    BuildContext context,
    DateTime janela,
    ItemJanelaProducao item,
  ) {
    final textCtrl = TextEditingController(text: item.quantidadeRestante.toInt().toString());
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: FincoreColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.restaurant_outlined, size: 16, color: FincoreColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Produção: ${item.nomeProduto}',
                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Janela de Entrega: ${DateFormat('HH:mm').format(janela)}\n'
                'Planejado total: ${item.quantidadePlanejada.toInt()} ${item.unidade}\n'
                'Restante atual: ${item.quantidadeRestante.toInt()} ${item.unidade}',
                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quantidade produzida a somar:',
                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: textCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FincoreColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                controller.marcarProdutoConcluido(janela, item.produtoId, item.quantidadePlanejada);
                Navigator.of(ctx).pop();
              },
              child: const Text('Concluir Tudo', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final valor = double.tryParse(textCtrl.text) ?? 0;
                    if (valor > 0) {
                      controller.registrarProduzido(janela, item.produtoId, valor, item.quantidadePlanejada);
                    }
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final janelas = controller.janelasProducao;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header da faixa
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(10))
                : BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.restaurant_outlined,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PRODUÇÃO OPERACIONAL',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (janelas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${janelas.length} janela${janelas.length > 1 ? 's' : ''} ativa${janelas.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: FincoreColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          if (isExpanded) ...[
            Container(height: 1, color: FincoreColors.border),
            if (janelas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'Nenhum item pendente de produção.',
                  style: TextStyle(
                    color: FincoreColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool useHorizontalColumns = constraints.maxWidth > 700;
                    
                    final widgets = <Widget>[
                      // ── PRODUÇÃO AGORA (Janela mais próxima) ────────
                      _buildJanelaAgora(context, janelas[0]),
                      
                      // ── PRÓXIMA PRODUÇÃO (Janela secundária) ────────
                      if (janelas.length > 1) ...[
                        if (useHorizontalColumns) const SizedBox(width: 24) else const SizedBox(height: 16),
                        _buildJanelaProxima(janelas[1]),
                      ],
                    ];

                    if (useHorizontalColumns) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: widgets[0]),
                          if (janelas.length > 1) ...[
                            widgets[1], // Spacer
                            Expanded(flex: 2, child: widgets[2]),
                          ],
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widgets,
                      );
                    }
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildJanelaAgora(BuildContext context, JanelaProducao jp) {
    final horaTexto = DateFormat('HH:mm').format(jp.horarioEntrega.toLocal());
    final statusColor = jp.concluida ? const Color(0xFF10B981) : const Color(0xFFF97316);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'PRODUÇÃO AGORA (Entrega: $horaTexto · ${jp.totalPedidos} ped)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
            if (jp.concluida) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (jp.concluida)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF137333).withOpacity(0.15)),
            ),
            child: Row(
              children: const [
                Icon(Icons.done_all_rounded, color: Color(0xFF137333), size: 16),
                SizedBox(width: 8),
                Text(
                  '✓ Produção deste lote concluída',
                  style: TextStyle(color: Color(0xFF137333), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: jp.itens.map((item) {
                return _ProducaoItemCard(
                  item: item,
                  onTap: () => _abrirRegistroProducaoDialog(context, jp.horarioEntrega, item),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildJanelaProxima(JanelaProducao jp) {
    final horaTexto = DateFormat('HH:mm').format(jp.horarioEntrega.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: FincoreColors.textMuted, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'PRÓXIMA PRODUÇÃO (Janela: $horaTexto · ${jp.totalPedidos} ped)',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: FincoreColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: jp.itens.map((item) {
            final qtyStr = item.quantidadePlanejada % 1 == 0
                ? '${item.quantidadePlanejada.toInt()}'
                : item.quantidadePlanejada.toStringAsFixed(1);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FincoreColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Text(
                '${item.nomeProduto}: $qtyStr ${item.unidade}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FincoreColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProducaoItemCard extends StatelessWidget {
  final ItemJanelaProducao item;
  final VoidCallback onTap;

  const _ProducaoItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDone = item.concluida;
    final Color borderColor = isDone ? const Color(0xFF10B981) : FincoreColors.border;
    final Color bgColor = isDone ? const Color(0xFFE6F4EA) : FincoreColors.surfaceElevated;

    final planejadoStr = item.quantidadePlanejada % 1 == 0 ? '${item.quantidadePlanejada.toInt()}' : item.quantidadePlanejada.toStringAsFixed(1);
    final restanteStr = item.quantidadeRestante % 1 == 0 ? '${item.quantidadeRestante.toInt()}' : item.quantidadeRestante.toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDone) ...[
              const Icon(Icons.check_rounded, color: Color(0xFF137333), size: 14),
              const SizedBox(width: 4),
              Text(
                '${item.nomeProduto} concluída',
                style: const TextStyle(
                  color: Color(0xFF137333),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              Text(
                item.nomeProduto,
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$restanteStr / $planejadoStr un.',
                  style: TextStyle(
                    color: FincoreColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
