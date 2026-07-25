import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/pdv_express_controller.dart';

class PixPaymentModal extends StatelessWidget {
  final PdvExpressController controller;

  const PixPaymentModal({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24), // Surface Slate
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF97316), width: 2), // Laranja Forno
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PAGAMENTO VIA PIX',
                    style: TextStyle(
                      color: Color(0xFFF3F4F6),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121214),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'R\$ ${(controller.totalInCents / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF06B6D4), // Cyan
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const Divider(color: Color(0xFF2E2E38), height: 32),
              
              // Simular QR Code do PIX
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  painter: FakeQrCodePainter(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Aguardando confirmação do banco...',
                style: TextStyle(
                  color: Color(0xFFF3F4F6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'O pedido será impresso automaticamente após aprovação.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botões de Contingência em caso de queda de rede
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        controller.changeState(PdvState.selectingPayment);
                      },
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444), // Carmim
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        controller.forceContingente();
                      },
                      child: const Text('FORÇAR APROVAÇÃO'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Pintar um QR Code de simulação estético
class FakeQrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Cantos principais do QR
    canvas.drawRect(const Rect.fromLTWH(0, 0, 50, 50), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 50, 0, 50, 50), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 50, 50, 50), paint);

    // Blocos internos dos cantos
    paint.color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(10, 10, 30, 30), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 40, 10, 30, 30), paint);
    canvas.drawRect(Rect.fromLTWH(10, size.height - 40, 30, 30), paint);

    paint.color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(20, 20, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 30, 20, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(20, size.height - 30, 10, 10), paint);

    // Desenhar pixels aleatórios simulando QR Code
    paint.color = Colors.black.withValues(alpha: 0.84);
    canvas.drawRect(const Rect.fromLTWH(70, 20, 20, 10), paint);
    canvas.drawRect(const Rect.fromLTWH(100, 40, 10, 30), paint);
    canvas.drawRect(const Rect.fromLTWH(20, 70, 30, 10), paint);
    canvas.drawRect(const Rect.fromLTWH(60, 90, 40, 20), paint);
    canvas.drawRect(const Rect.fromLTWH(120, 80, 10, 40), paint);
    canvas.drawRect(const Rect.fromLTWH(140, 120, 30, 15), paint);
    canvas.drawRect(const Rect.fromLTWH(40, 140, 25, 25), paint);
    canvas.drawRect(const Rect.fromLTWH(90, 150, 40, 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
