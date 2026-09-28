import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';

class PedidoMirrorDialog extends StatelessWidget {
  final String pedidoId;
  final int? numeroPedido;

  const PedidoMirrorDialog({
    super.key,
    required this.pedidoId,
    this.numeroPedido,
  });

  static Future<void> show(BuildContext context, {required String pedidoId, int? numeroPedido}) {
    return showDialog(
      context: context,
      builder: (ctx) => PedidoMirrorDialog(
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
      ),
    );
  }

  String _fmt(int centavos) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(centavos / 100);
  }

  @override
  Widget build(BuildContext context) {
    final db = DependencyInjection().get<FincoreDatabase>();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(22),
        child: FutureBuilder<({PedidoData? pedido, List<ItemPedidoData> itens})>(
          future: () async {
            final p = await (db.select(db.pedidosTable)..where((t) => t.id.equals(pedidoId))).getSingleOrNull();
            final itens = await (db.select(db.itensPedidoTable)..where((t) => t.pedidoId.equals(pedidoId))).get();
            return (pedido: p, itens: itens);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: FincoreColors.primary),
                ),
              );
            }

            final data = snapshot.data;
            final pedido = data?.pedido;
            final itens = data?.itens ?? [];

            if (pedido == null) {
              return SizedBox(
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: FincoreColors.textMuted, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Pedido #$pedidoId não encontrado no banco de dados local.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Fechar', style: TextStyle(color: FincoreColors.primary)),
                    ),
                  ],
                ),
              );
            }

            final dataRef = pedido.dataHoraEntregaPrevista?.toLocal() ?? pedido.dataHoraCriacao.toLocal();
            final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(dataRef);
            final totalUnidades = itens.fold<double>(0.0, (sum, i) => sum + i.quantidade);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FincoreColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: FincoreColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espelho do Pedido #${pedido.numeroPedido.toString().padLeft(4, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              pedido.clienteNomeAvulso ?? 'Consumidor',
                              style: const TextStyle(
                                color: FincoreColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: FincoreColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: FincoreColors.border, height: 24),

                // ── Informações do Pedido ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          pedido.tipoLogistica.toLowerCase().contains('entrega')
                              ? Icons.delivery_dining_outlined
                              : Icons.storefront_outlined,
                          size: 16,
                          color: const Color(0xFF06B6D4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pedido.tipoLogistica.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF06B6D4),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Data do Pedido: $dataStr',
                      style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Lista de Itens ──────────────────────────────────
                const Text(
                  'ITENS DO PEDIDO',
                  style: TextStyle(
                    color: FincoreColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: itens.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Nenhum item listado.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final item in itens) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${item.quantidade.toInt()}x',
                                        style: TextStyle(
                                          color: FincoreColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.nomeProduto,
                                          style: const TextStyle(
                                            color: FincoreColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _fmt(item.valorTotalCentavos),
                                        style: const TextStyle(
                                          color: FincoreColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(color: FincoreColors.border, height: 1),
                              ],
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Totais e Pagamento ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FincoreColors.primary.withValues(alpha: 0.12),
                        FincoreColors.primary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Forma de Pagamento',
                            style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            pedido.formaPagamentoNome ?? 'Não informado',
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Volumes / Itens',
                            style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            '${itens.length} item(ns) / ${totalUnidades.toInt()} un.',
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (pedido.valorTaxaEntregaCentavos > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Taxa de Entrega',
                              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                            ),
                            Text(
                              _fmt(pedido.valorTaxaEntregaCentavos),
                              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const Divider(color: FincoreColors.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'VALOR TOTAL',
                            style: TextStyle(
                              color: FincoreColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _fmt(pedido.valorTotalCentavos),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
