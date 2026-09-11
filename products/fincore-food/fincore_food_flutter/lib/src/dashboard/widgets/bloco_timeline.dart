import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_shared/fincore_shared.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pedidos_page.dart';
import '../controllers/dashboard_controller.dart';
import '../data/dashboard_repository.dart';

class BlocoTimeline extends StatelessWidget {
  final DashboardController controller;

  const BlocoTimeline({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final timeline = controller.metrics.timelineHoje;
    if (timeline.isEmpty) return const SizedBox.shrink();

    // Encontra o index do evento mais próximo do horário atual
    final nowStr = DateFormat('HH:mm').format(DateTime.now());
    int activeIndex = 0;
    for (int i = 0; i < timeline.length; i++) {
      if (timeline[i].hora.compareTo(nowStr) >= 0) {
        activeIndex = i;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Linha do Tempo de Hoje',
            style: TextStyle(
              color: FincoreColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final ev = timeline[index];
              final isCurrent = index == activeIndex;

              final Color dotColor = switch (ev.tipo) {
                'Entrega' => const Color(0xFF3B82F6),
                'Retirada' => const Color(0xFF8B5CF6),
                'Preparação' => const Color(0xFFF59E0B),
                'Produção' => const Color(0xFF10B981),
                _ => FincoreColors.primary,
              };

              return Row(
                children: [
                  GestureDetector(
                    onTap: () => _abrirVisualizarPedidoOuPlano(context, ev),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 170,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? dotColor.withValues(alpha: 0.08)
                            : FincoreColors.surfaceOverlay,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? dotColor
                              : FincoreColors.border,
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ev.hora,
                                style: TextStyle(
                                  color: dotColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: dotColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'AGORA',
                                    style: TextStyle(
                                      color: dotColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            ev.cliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FincoreColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ev.tipo,
                                style: const TextStyle(
                                  color: FincoreColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                ev.status.toUpperCase(),
                                style: TextStyle(
                                  color: ev.status == 'cancelado'
                                      ? const Color(0xFFE05C5C)
                                      : FincoreColors.textSecondary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < timeline.length - 1) ...[
                    Container(
                      width: 28,
                      height: 1.5,
                      color: FincoreColors.border,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _abrirVisualizarPedidoOuPlano(BuildContext context, EventoTimeline ev) async {
    if (ev.tipo == 'Produção') {
      FincoreShell.selectTab(context, 'producao');
      return;
    }

    final db = DependencyInjection().get<FincoreDatabase>();
    final pedido = await (db.select(db.pedidosTable)..where((t) => t.id.equals(ev.orderId))).getSingleOrNull();

    if (pedido == null || !context.mounted) return;

    final orderItens = await (db.select(db.itensPedidoTable)
          ..where((t) => t.pedidoId.equals(ev.orderId) & t.deletedAt.isNull()))
        .get();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: FincoreColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Pedido #${pedido.numeroPedido ?? pedido.id.substring(0, 5)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${pedido.clienteNomeAvulso ?? 'Balcão'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Logística: ${pedido.tipoLogistica} • Status: ${pedido.status}', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
              if (pedido.dataHoraEntregaPrevista != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Entrega prevista: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.dataHoraEntregaPrevista!.toLocal())}',
                  style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
              const Divider(height: 24, color: FincoreColors.border),
              const Text('Itens do Pedido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...orderItens.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${it.quantidade.round()}x ${it.nomeProduto}', style: const TextStyle(fontSize: 12)),
                      Text(FincoreMoneyFormatter.format(it.valorTotalCentavos), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              const Divider(height: 24, color: FincoreColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(FincoreMoneyFormatter.format(pedido.valorTotalCentavos), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FincoreColors.success)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final dataRef = (pedido.dataHoraEntregaPrevista ?? pedido.dataHoraCriacao).toLocal();
              PedidosPage.dataPreSelecionada = dataRef;
              PedidosPage.filtroPedidoId = pedido.id;
              FincoreShell.selectTab(context, 'pedidos');
            },
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
            child: const Text('Ir para Central de Pedidos'),
          ),
        ],
      ),
    );
  }
}
