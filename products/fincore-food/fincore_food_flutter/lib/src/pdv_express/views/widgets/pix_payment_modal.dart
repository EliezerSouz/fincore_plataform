import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_food_flutter/src/shared/services/impressao_service.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import '../../controllers/pdv_express_controller.dart';

class PixPaymentModal extends StatefulWidget {
  final PdvExpressController controller;

  const PixPaymentModal({
    super.key,
    required this.controller,
  });

  @override
  State<PixPaymentModal> createState() => _PixPaymentModalState();
}

class _PixPaymentModalState extends State<PixPaymentModal> {
  bool _loading = true;
  String _pixChave = '';
  String _pixTipo = 'PIX';
  String _pixFavorecido = '';
  String _pixCopiaCola = '';
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadPixConfig();
  }

  Future<void> _loadPixConfig() async {
    final config = await FincoreImpressaoConfig.carregar();
    final valorReais = widget.controller.totalInCents / 100.0;

    String copiaCola = '';
    if (config.pixChave.isNotEmpty) {
      copiaCola = PixGenerator.gerarCopiaCola(
        chave: config.pixChave,
        favorecido: config.pixFavorecido.isNotEmpty ? config.pixFavorecido : 'Estabelecimento',
        cidade: 'Sorocaba',
        valor: valorReais,
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _pixChave = config.pixChave;
        _pixTipo = config.pixTipo;
        _pixFavorecido = config.pixFavorecido;
        _pixCopiaCola = copiaCola;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Container(
          width: 440,
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
                      'R\$ ${(widget.controller.totalInCents / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF06B6D4), // Cyan
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const Divider(color: Color(0xFF2E2E38), height: 28),

              if (_loading) ...[
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFFF97316)),
                ),
              ] else if (_pixChave.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhuma Chave PIX cadastrada.\nAcesse "Configurações" para cadastrar a chave do estabelecimento.',
                          style: TextStyle(color: Color(0xFFF3F4F6), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Informações da Chave
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121214),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chave ($_pixTipo):', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                          SelectableText(
                            _pixChave,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      if (_pixFavorecido.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Favorecido:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                            Text(
                              _pixFavorecido,
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Realista + Copia e Cola
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    painter: FakeQrCodePainter(),
                  ),
                ),
                const SizedBox(height: 12),

                // Botão Copiar PIX Copia e Cola
                if (_pixCopiaCola.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _copied ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
                        side: BorderSide(color: _copied ? const Color(0xFF10B981) : const Color(0xFF06B6D4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _pixCopiaCola));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) setState(() => _copied = false);
                        });
                      },
                      icon: Icon(_copied ? Icons.check : Icons.copy_rounded, size: 16),
                      label: Text(_copied ? 'CÓDIGO COPIADO!' : 'COPIAR PIX COPIA E COLA', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),
              const Text(
                'Aguardando confirmação do pagamento...',
                style: TextStyle(
                  color: Color(0xFFF3F4F6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'O pedido será impresso automaticamente após aprovação.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 20),

              // Botões de Contingência em caso de queda de rede
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        widget.controller.changeState(PdvState.selectingPayment);
                      },
                      child: const Text('CANCELAR', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444), // Carmim
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        widget.controller.forceContingente();
                      },
                      child: const Text('FORÇAR APROVAÇÃO', style: TextStyle(fontSize: 12)),
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
    canvas.drawRect(const Rect.fromLTWH(0, 0, 45, 45), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 45, 0, 45, 45), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 45, 45, 45), paint);

    // Blocos internos dos cantos
    paint.color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(8, 8, 29, 29), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 37, 8, 29, 29), paint);
    canvas.drawRect(Rect.fromLTWH(8, size.height - 37, 29, 29), paint);

    paint.color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(17, 17, 11, 11), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 28, 17, 11, 11), paint);
    canvas.drawRect(Rect.fromLTWH(17, size.height - 28, 11, 11), paint);

    // Desenhar pixels aleatórios simulando QR Code
    paint.color = Colors.black.withValues(alpha: 0.85);
    canvas.drawRect(const Rect.fromLTWH(60, 15, 18, 10), paint);
    canvas.drawRect(const Rect.fromLTWH(90, 35, 10, 25), paint);
    canvas.drawRect(const Rect.fromLTWH(15, 60, 25, 10), paint);
    canvas.drawRect(const Rect.fromLTWH(50, 80, 35, 18), paint);
    canvas.drawRect(const Rect.fromLTWH(110, 70, 10, 35), paint);
    canvas.drawRect(const Rect.fromLTWH(130, 110, 25, 15), paint);
    canvas.drawRect(const Rect.fromLTWH(35, 125, 20, 20), paint);
    canvas.drawRect(const Rect.fromLTWH(80, 135, 35, 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
