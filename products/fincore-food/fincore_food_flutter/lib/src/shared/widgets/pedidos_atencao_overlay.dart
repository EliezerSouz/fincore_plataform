import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../services/global_pedidos_alert_service.dart';
import '../presentation/shell/fincore_shell.dart';
import '../../pedidos/views/pedidos_page.dart';

class PedidosAtencaoOverlay extends StatefulWidget {
  final PedidosAlertaResumo resumo;
  final VoidCallback onDismiss;

  const PedidosAtencaoOverlay({
    super.key,
    required this.resumo,
    required this.onDismiss,
  });

  @override
  State<PedidosAtencaoOverlay> createState() => _PedidosAtencaoOverlayState();
}

class _PedidosAtencaoOverlayState extends State<PedidosAtencaoOverlay>
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
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _opacityAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    // Auto-dismiss após 30 segundos
    _autoDismissTimer = Timer(const Duration(seconds: 30), () {
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
      widget.onDismiss();
    });
  }

  void _handleGoToCentral() {
    _animCtrl.reverse().then((_) {
      widget.onDismiss();
      if (widget.resumo.pedidosCriticos.isNotEmpty) {
        final p = widget.resumo.pedidosCriticos.first;
        final dataRef = (p.dataHoraEntregaPrevista ?? p.dataHoraCriacao).toLocal();
        PedidosPage.navegarParaData(dataRef, pedidoId: p.id);
      }
      FincoreShell.selectTab(context, 'pedidos');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool temAtrasados = widget.resumo.totalAtrasados > 0;
    final Color alertColor = temAtrasados ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final String title = temAtrasados
        ? '${widget.resumo.totalAtrasados} Pedido${widget.resumo.totalAtrasados > 1 ? "s" : ""} Atrasado${widget.resumo.totalAtrasados > 1 ? "s" : ""}!'
        : '${widget.resumo.totalUrgentes} Pedido${widget.resumo.totalUrgentes > 1 ? "s" : ""} Próximo${widget.resumo.totalUrgentes > 1 ? "s" : ""} do Prazo!';

    final String subtitle = temAtrasados
        ? 'Há pedidos pendentes com horário de entrega expirado que necessitam de ação na cozinha/expedição.'
        : 'Há pedidos com entrega em menos de 15 minutos aguardando finalização.';

    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        type: MaterialType.transparency,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _opacityAnim,
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: alertColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: alertColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top alert stripe
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            alertColor,
                            alertColor.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: alertColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: alertColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  temAtrasados
                                      ? Icons.warning_amber_rounded
                                      : Icons.alarm_on_rounded,
                                  color: alertColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: FincoreColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close, size: 18, color: FincoreColors.textMuted),
                                onPressed: _handleDismiss,
                                tooltip: 'Dispensar',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Botões de ação
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _handleDismiss,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: FincoreColors.textSecondary,
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Silenciar', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _handleGoToCentral,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: alertColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.arrow_forward, size: 14),
                                  label: const Text(
                                    'Ir para Central',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
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
