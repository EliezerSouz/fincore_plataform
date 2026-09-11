import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';
import 'package:intl/intl.dart';

/// Card compacto do Kanban para uma [OrdemPreparo], focado puramente em dados operacionais.
class PedidoCard extends StatelessWidget {
  final OrdemPreparo ordem;
  final DadosOrdemKanban parsed;
  final String? userRole;
  final CentralPedidosController controller;
  final VoidCallback onTap;
  final Color accentColor;

  /// Se verdadeiro, mostra o botão de ação rápida no card.
  final bool mostrarAcaoRapida;

  /// Callback da ação rápida (avançar status).
  final VoidCallback? onAcaoRapida;

  /// Label do botão de ação rápida.
  final String? acaoRapidaLabel;

  final VoidCallback? onImprimir;
  final VoidCallback? onCancelar;

  const PedidoCard({
    super.key,
    required this.ordem,
    required this.parsed,
    required this.controller,
    required this.onTap,
    required this.accentColor,
    this.userRole,
    this.mostrarAcaoRapida = false,
    this.onAcaoRapida,
    this.acaoRapidaLabel,
    this.onImprimir,
    this.onCancelar,
  });

  String get _friendlyId {
    final numero = controller.getNumeroPedido(ordem.pedidoId);
    if (numero != null) {
      return 'Pedido #${numero.toString().padLeft(4, '0')}';
    }
    final pedido = controller.pedidosMap[ordem.pedidoId];
    if (pedido != null && pedido.numeroPedido != null) {
      return 'Pedido #${pedido.numeroPedido.toString().padLeft(4, '0')}';
    }
    if (ordem.pedidoId.length > 6) {
      return 'Pedido #${ordem.pedidoId.substring(0, 6).toUpperCase()}';
    }
    return 'Pedido #${ordem.pedidoId.toUpperCase()}';
  }


  IconData _logisticaIcon() {
    final t = parsed.tipoLogistica.toLowerCase();
    if (t.contains('entrega') || t.contains('delivery')) {
      return Icons.delivery_dining_outlined;
    }
    if (t.contains('mesa')) return Icons.table_restaurant_outlined;
    return Icons.storefront_outlined;
  }

  IconData _getActionIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('preparar') || l.contains('iniciar')) {
      return Icons.play_arrow_rounded;
    }
    if (l.contains('finalizar') || l.contains('concluir') || l.contains('pronto')) {
      return Icons.check_rounded;
    }
    if (l.contains('retirar') || l.contains('entregar') || l.contains('enviar')) {
      return Icons.storefront_rounded;
    }
    return Icons.arrow_forward_rounded;
  }

  String _getStatusLabel(StatusOrdemPreparo status) {
    switch (status) {
      case StatusOrdemPreparo.pendente:
        return 'Pendente';
      case StatusOrdemPreparo.emPreparo:
        return 'Em Preparo';
      case StatusOrdemPreparo.pronto:
        return 'Pronto';
      case StatusOrdemPreparo.entregue:
        return 'Entregue';
      case StatusOrdemPreparo.cancelado:
        return 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = controller.calculateDeadline(ordem);
    final isDelivery = parsed.tipoLogistica.toLowerCase().contains('entrega') ||
                       parsed.tipoLogistica.toLowerCase().contains('delivery');

    final bool isPendente = ordem.status == StatusOrdemPreparo.pendente;
    final bool isEmPreparo = ordem.status == StatusOrdemPreparo.emPreparo;
    final bool isPronto = ordem.status == StatusOrdemPreparo.pronto;

    // Prioridade de data de entrega: banco > parse obs > fallback legado > criadaEm da ordem
    final pedidoRow = controller.pedidosMap[ordem.pedidoId];
    DateTime? dataEntregaRef = pedidoRow?.dataHoraEntregaPrevista?.toLocal()
        ?? parsed.dataAgendada?.toLocal();

    // Fallback legado: código antigo salvava dataHoraCriacao = horário de entrega
    if (dataEntregaRef == null && pedidoRow != null) {
      final pedidoCriada = pedidoRow.dataHoraCriacao.toLocal();
      final ordemCriada  = ordem.criadaEm.toLocal();
      if (pedidoCriada.difference(ordemCriada).inMinutes > 30) {
        dataEntregaRef = pedidoCriada;
      }
    }

    final String horaTexto;
    final refTime = dataEntregaRef ?? ordem.criadaEm.toLocal();
    {
      final hoje = DateTime.now();
      final String diaStr;
      if (refTime.year == hoje.year &&
          refTime.month == hoje.month &&
          refTime.day == hoje.day) {
        diaStr = 'Hoje';
      } else if (refTime.year == hoje.year &&
          refTime.month == hoje.month &&
          refTime.day == hoje.day + 1) {
        diaStr = 'Amanhã';
      } else {
        final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final wStr = weekdays[refTime.weekday - 1];
        diaStr = '$wStr ${DateFormat('dd/MM').format(refTime)}';
      }
      horaTexto = '$diaStr · ${DateFormat('HH:mm').format(refTime)}';
    }

    final statusColor = deadline.statusColor;
    final isCriticoOuAtrasado = statusColor == const Color(0xFFDC2626) ||
        statusColor == const Color(0xFFEF4444);

    // Copia e ordena os itens do pedido pela quantidade decrescente
    final sortedItens = List<ItemOrdemPreparo>.from(ordem.itens)
      ..sort((a, b) => b.quantidade.compareTo(a.quantidade));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCriticoOuAtrasado ? statusColor.withValues(alpha: 0.5) : FincoreColors.border,
            width: isCriticoOuAtrasado ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: isCriticoOuAtrasado ? statusColor : Colors.transparent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 12, right: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Tipo Logística com ícone + Horário
                    Row(
                      children: [
                        Icon(
                          isDelivery ? Icons.delivery_dining_outlined : _logisticaIcon(),
                          size: 14,
                          color: isDelivery ? const Color(0xFF137333) : FincoreColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDelivery ? 'DELIVERY' : parsed.tipoLogistica.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDelivery ? const Color(0xFF137333) : FincoreColors.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          horaTexto,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2: Pedido ID + Status Atrasado + Status Badge
                    Row(
                      children: [
                        Text(
                          _friendlyId,
                          style: const TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _getStatusLabel(ordem.status).toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 3: Cliente
                    Text(
                      parsed.cliente.isEmpty ? 'Consumidor' : parsed.cliente,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Row 4: Composição detalhada do pedido
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final i in sortedItens)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${i.quantidade % 1 == 0 ? i.quantidade.toInt() : i.quantidade.toStringAsFixed(1)} ×',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: FincoreColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      i.nomeProduto,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: FincoreColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Row 5: Horário da Etapa Atual (varia por status)
                    Row(
                      children: [
                        if (isCriticoOuAtrasado) ...[
                          // Bolinha vermelha de atraso/urgência
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              () {
                                if (isPendente) {
                                  // Atrasou o início: mostra quanto tempo de atraso
                                  return '${deadline.statusLabel.toUpperCase()} · ${deadline.tempoRestanteLabel}';
                                }
                                if (isEmPreparo) {
                                  return '${deadline.statusLabel.toUpperCase()} · ${deadline.tempoRestanteLabel}';
                                }
                                if (isPronto) {
                                  return '${deadline.statusLabel.toUpperCase()} · ${deadline.tempoRestanteLabel}';
                                }
                                return deadline.tempoRestanteLabel;
                              }(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFDC2626),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ] else ...[
                          // ── Pendente: mostrar QUANDO INICIAR ──────────────────
                          if (isPendente) ...[
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 14,
                              color: deadline.statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deadline.isImmediate
                                  ? 'INICIAR AGORA'
                                  : 'INICIAR ÀS · ${DateFormat('HH:mm').format(deadline.horarioInicioRecomendado)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: deadline.statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),

                          // ── Em Preparo: mostrar ATÉ QUANDO FICAR PRONTO ──────
                          ] else if (isEmPreparo) ...[
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: deadline.statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deadline.isImmediate
                                  ? 'EM PREPARAÇÃO'
                                  : 'PRONTO ATÉ · ${DateFormat('HH:mm').format(deadline.horarioProntoAte)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: deadline.statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),

                          // ── Pronto: mostrar QUANDO SAIR (entrega) ou ATÉ QUANDO (retirada) ──
                          ] else if (isPronto) ...[
                            Icon(
                              isDelivery
                                  ? Icons.delivery_dining_rounded
                                  : Icons.storefront_rounded,
                              size: 14,
                              color: deadline.statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deadline.isImmediate
                                  ? (isDelivery ? 'PRONTO PARA ENTREGA' : 'PRONTO PARA RETIRADA')
                                  : (isDelivery
                                      ? 'SAIR ÀS · ${DateFormat('HH:mm').format(deadline.horarioSairAte)}'
                                      : 'RETIRADA ATÉ · ${DateFormat('HH:mm').format(deadline.horarioEntrega)}'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: deadline.statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),

                          // ── Outros (entregue/cancelado): prazo final ───────────
                          ] else ...[
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: FincoreColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Entrega: ${DateFormat('HH:mm').format(deadline.horarioEntrega)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: FincoreColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),

                    // Row 6: Botão de Ação Rápida Único e Destacada
                    if (mostrarAcaoRapida && onAcaoRapida != null && acaoRapidaLabel != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: onAcaoRapida,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getActionIcon(acaoRapidaLabel!), color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  acaoRapidaLabel!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
