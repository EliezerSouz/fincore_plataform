import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';
import 'package:fincore_food_flutter/src/shared/services/permissao_service.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/fincore_core.dart';

/// Card compacto do Kanban para uma [OrdemPreparo].
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

  // ── ID Amigável ────────────────────────────────────────────────────

  String get _friendlyId {
    final pedido = controller.pedidosMap[ordem.pedidoId];
    if (pedido != null && pedido.numeroPedido != null) {
      return 'Pedido #${pedido.numeroPedido.toString().padLeft(4, '0')}';
    }
    if (ordem.pedidoId.length > 6) {
      return 'Pedido #${ordem.pedidoId.substring(0, 6).toUpperCase()}';
    }
    return 'Pedido #${ordem.pedidoId.toUpperCase()}';
  }

  // ── Lógica de tempo ─────────────────────────────────────────────────

  bool _isAtrasado() {
    if (ordem.status == StatusOrdemPreparo.cancelado ||
        ordem.status == StatusOrdemPreparo.entregue) {
      return false;
    }
    final tempoLimite =
        ordem.criadaEm.add(Duration(seconds: ordem.tempoEstimadoSegundos));
    return DateTime.now().isAfter(tempoLimite);
  }

  // ── Ícone de logística ───────────────────────────────────────────────

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

  Widget _buildLogisticaChip(bool isDelivery) {
    final label = isDelivery ? 'Delivery' : parsed.tipoLogistica;
    final icon = isDelivery ? Icons.delivery_dining_outlined : _logisticaIcon();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF137333)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF137333),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color? iconColor,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled ? FincoreColors.border : FincoreColors.border.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isEnabled 
                ? (iconColor ?? FincoreColors.textSecondary) 
                : FincoreColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildAcaoRapidaButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
    final showFinanceiro = PermissaoService.podeVerFinanceiro(userRole);
    final showCancelar = PermissaoService.podeCancelarPedido(userRole) && 
                         ordem.status == StatusOrdemPreparo.pendente;

    final deadline = controller.calculateDeadline(ordem);
    final isDelivery = parsed.tipoLogistica.toLowerCase().contains('entrega') ||
                       parsed.tipoLogistica.toLowerCase().contains('delivery');

    final totalItens = ordem.itens.length;
    final totalUnidades = parsed.totalUnidades.toInt();
    final atrasado = _isAtrasado();

    final agendada = parsed.dataAgendada;
    final String horaTexto;
    final String prefixo = isDelivery ? 'Entrega' : parsed.tipoLogistica;
    if (agendada != null) {
      final localAgendada = agendada.toLocal();
      final hoje = DateTime.now();
      final String diaStr;
      if (localAgendada.year == hoje.year && localAgendada.month == hoje.month && localAgendada.day == hoje.day) {
        diaStr = 'Hoje';
      } else {
        diaStr = DateFormat('dd/MM').format(localAgendada);
      }
      horaTexto = '$prefixo: $diaStr — ${DateFormat('HH:mm').format(localAgendada)}';
    } else {
      horaTexto = '$prefixo: Hoje — ${DateFormat('HH:mm').format(ordem.criadaEm.toLocal())}';
    }

    final totalFinanceiro = controller.totalOrdemCentavos(ordem);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FincoreColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Red left accent indicator if delayed
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: atrasado ? const Color(0xFFEF4444) : Colors.transparent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 12, right: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Hora Agendada + Logística
                    Row(
                      children: [
                        Text(
                          horaTexto,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _buildLogisticaChip(isDelivery),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: Pedido ID + Status Atrasado + Status Badge
                    Row(
                      children: [
                        Text(
                          _friendlyId,
                          style: const TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (atrasado) ...[
                          Text(
                            deadline.tempoRestanteLabel,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
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
                    const SizedBox(height: 8),

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

                    // Row 4: Phone (if present)
                    if (parsed.telefone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        parsed.telefone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: FincoreColors.textMuted,
                        ),
                      ),
                    ],

                    // Row 5: Payment method (if present and showFinanceiro is true)
                    if (showFinanceiro && parsed.pagamento.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Pagamento: ${parsed.pagamento}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FincoreColors.textMuted,
                        ),
                      ),
                    ],

                    const Divider(color: FincoreColors.border, height: 16),

                    // Row 6: Itens para Cozinha (Destaque Visual)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ordem.itens.map((i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Text(
                                '${i.quantidade.toInt()} un.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: FincoreColors.primary,
                                ),
                              ),
                              const Text(
                                ' — ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: FincoreColors.textMuted,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  i.nomeProduto,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: FincoreColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: $totalItens item(ns) / $totalUnidades un.',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textMuted,
                          ),
                        ),
                        if (showFinanceiro && totalFinanceiro > 0)
                          Text(
                            'R\$ ${(totalFinanceiro / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE05638), // Orange/red accent price
                            ),
                          ),
                      ],
                    ),

                    const Divider(color: FincoreColors.border, height: 16),

                    // Row 7: Inteligência de Prazos
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREPARO: ${deadline.tempoPreparacaoMinutos} min',
                                style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                              ),
                              if (isDelivery)
                                Text(
                                  'DESLOC.: ${deadline.tempoDeslocamentoMinutos} min',
                                  style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                                ),
                              if (deadline.margemSegurancaMinutos > 0)
                                Text(
                                  'MARGEM: ${deadline.margemSegurancaMinutos} min',
                                  style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              () {
                                if (ordem.status == StatusOrdemPreparo.emPreparo) {
                                  return 'PRONTO ATÉ';
                                } else if (ordem.status == StatusOrdemPreparo.pronto) {
                                  return isDelivery ? 'ENTREGAR ATÉ' : 'RETIRAR ATÉ';
                                } else {
                                  return 'INICIAR ATÉ';
                                }
                              }(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FincoreColors.textMuted),
                            ),
                            Text(
                              () {
                                if (ordem.status == StatusOrdemPreparo.emPreparo) {
                                  final prontoAte = deadline.horarioEntrega.subtract(
                                    Duration(
                                      minutes: deadline.tempoDeslocamentoMinutos +
                                          deadline.margemSegurancaMinutos,
                                    ),
                                  );
                                  return DateFormat('HH:mm').format(prontoAte);
                                } else if (ordem.status == StatusOrdemPreparo.pronto) {
                                  return DateFormat('HH:mm').format(deadline.horarioEntrega);
                                } else {
                                  return deadline.isImmediate
                                      ? 'AGORA'
                                      : DateFormat('HH:mm').format(deadline.horarioInicioRecomendado);
                                }
                              }(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: FincoreColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(color: FincoreColors.border, height: 16),

                    // Row 8: Action Row
                    Row(
                      children: [
                        // Print Button
                        _buildCircularIconButton(
                          icon: Icons.print_outlined,
                          onTap: onImprimir,
                        ),
                        const SizedBox(width: 6),
                        // Details Button
                        _buildCircularIconButton(
                          icon: Icons.info_outline_rounded,
                          onTap: onTap,
                        ),
                        // Cancel Button (for admin/commercial view if eligible)
                        if (showCancelar && onCancelar != null) ...[
                          const SizedBox(width: 6),
                          _buildCircularIconButton(
                            icon: Icons.cancel_outlined,
                            iconColor: FincoreColors.danger,
                            onTap: onCancelar,
                          ),
                        ],
                        const Spacer(),
                        if (mostrarAcaoRapida && onAcaoRapida != null && acaoRapidaLabel != null)
                          _buildAcaoRapidaButton(
                            label: acaoRapidaLabel!,
                            icon: _getActionIcon(acaoRapidaLabel!),
                            onTap: onAcaoRapida!,
                          ),
                      ],
                    ),
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
