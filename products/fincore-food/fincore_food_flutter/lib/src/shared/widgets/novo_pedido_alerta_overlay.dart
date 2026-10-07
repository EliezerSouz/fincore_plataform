import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../presentation/shell/fincore_shell.dart';
import '../../pedidos/views/pedidos_page.dart';

/// Overlay flutuante de alta prioridade exibido em QUALQUER tela do sistema
/// quando um novo pedido chega via Cardápio Digital ou canal externo.
class NovoPedidoAlertaOverlay extends StatefulWidget {
  final PedidoData pedido;
  final VoidCallback onDismiss;

  const NovoPedidoAlertaOverlay({
    super.key,
    required this.pedido,
    required this.onDismiss,
  });

  @override
  State<NovoPedidoAlertaOverlay> createState() => _NovoPedidoAlertaOverlayState();
}

class _NovoPedidoAlertaOverlayState extends State<NovoPedidoAlertaOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _opacityAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    // Auto-dismiss após 45 segundos se não for interagido
    _autoDismissTimer = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _handleAbrirPedido() {
    _animCtrl.reverse().then((_) {
      widget.onDismiss();
      final dataRef = widget.pedido.dataHoraCriacao.toLocal();
      PedidosPage.navegarParaData(dataRef, pedidoId: widget.pedido.id);
      FincoreShell.selectTab(context, 'pedidos');
    });
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFF97316); // Laranja FINCORE
    const greenBadge = Color(0xFF10B981); // Verde para novo pedido

    final clienteNome = widget.pedido.clienteNomeAvulso?.isNotEmpty == true
        ? widget.pedido.clienteNomeAvulso!
        : (widget.pedido.clienteTelefoneAvulso?.isNotEmpty == true
            ? widget.pedido.clienteTelefoneAvulso!
            : 'Cliente do Cardápio');

    final valorTotalStr = 'R\$ ${(widget.pedido.valorTotalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';
    final isCardapio = widget.pedido.canalOrigem.toLowerCase().contains('cardapio');
    final canalLabel = isCardapio ? '📱 Cardápio Digital' : widget.pedido.canalOrigem.toUpperCase();

    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        type: MaterialType.transparency,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _opacityAnim,
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: brandColor.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 3,
                    offset: const Offset(0, 10),
                  ),
                  const BoxShadow(
                    color: Colors.black87,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top glowing stripe
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            brandColor,
                            greenBadge,
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Ícone animado + Título + Fechar
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: brandColor.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: brandColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: brandColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: greenBadge.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: greenBadge.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'NOVO PEDIDO',
                                            style: TextStyle(
                                              color: greenBadge,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '#${widget.pedido.numeroPedido ?? '---'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      canalLabel,
                                      style: TextStyle(
                                        color: FincoreColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Fechar notificação',
                                onPressed: _handleDismiss,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Card de Informações do Cliente e Pedido
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.white70),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        clienteNome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          widget.pedido.tipoLogistica == 'Entrega'
                                              ? Icons.two_wheeler_rounded
                                              : Icons.storefront_rounded,
                                          size: 16,
                                          color: brandColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.pedido.tipoLogistica,
                                          style: TextStyle(
                                            color: FincoreColors.textSecondary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      valorTotalStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Botões de Ação
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _handleDismiss,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white60,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Dispensar',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text('Abrir Pedido'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 4,
                                    shadowColor: brandColor.withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onPressed: _handleAbrirPedido,
                                ),
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
          ),
        ),
      ),
    );
  }
}
