import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../services/whatsapp_service.dart';

/// Diálogo não-bloqueante de confirmação do operador para o Modo Manual (Human-in-the-Loop — Fase D2)
class WhatsAppManualConfirmDialog extends StatefulWidget {
  final WhatsAppSimulatedDecision decisao;
  final String rawPhone;
  final String? tenantId;

  const WhatsAppManualConfirmDialog({
    super.key,
    required this.decisao,
    required this.rawPhone,
    this.tenantId,
  });

  /// Método estático utilitário para exibir o diálogo apenas quando a decisão exigir confirmação manual
  static Future<WhatsAppSendResult?> exibirSeNecessario(
    BuildContext context, {
    required WhatsAppSimulatedDecision decisao,
    required String? rawPhone,
    String? tenantId,
  }) async {
    if (!decisao.requerConfirmacaoManual || rawPhone == null || rawPhone.isEmpty) {
      return null;
    }

    return showDialog<WhatsAppSendResult?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsAppManualConfirmDialog(
        decisao: decisao,
        rawPhone: rawPhone,
        tenantId: tenantId,
      ),
    );
  }

  @override
  State<WhatsAppManualConfirmDialog> createState() => _WhatsAppManualConfirmDialogState();
}

class _WhatsAppManualConfirmDialogState extends State<WhatsAppManualConfirmDialog> {
  bool _enviando = false;

  Future<void> _confirmarEnvio() async {
    setState(() => _enviando = true);

    try {
      final resultado = await WhatsAppService.enviarMensagem(
        rawPhone: widget.rawPhone,
        mensagem: widget.decisao.previewTexto ?? '',
        tenantId: widget.tenantId,
        pedidoId: widget.decisao.pedidoId,
        eventoId: widget.decisao.eventoId,
        isManualIntent: true,
      );

      if (mounted) {
        Navigator.of(context).pop(resultado);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  resultado.sucesso ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultado.sucesso
                        ? 'WhatsApp enviado ao cliente! (${resultado.telefoneMascarado})'
                        : 'Não foi possível enviar WhatsApp: ${resultado.erro ?? resultado.status.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: resultado.sucesso ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF22C55E), width: 1.2),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF22C55E), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notificar Cliente via WhatsApp?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pedido #${widget.decisao.numeroPedido} · Modo Manual com Operador',
                  style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android_rounded, size: 16, color: FincoreColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Destino: ${widget.decisao.telefoneFormatado}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: FincoreColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balão de preview no estilo WhatsApp Dark
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF005C4B), // Verde escuro oficial do WhatsApp
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.decisao.previewTexto ?? '',
                style: const TextStyle(
                  color: Color(0xFFE9EDEF),
                  fontSize: 12,
                  height: 1.4,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ℹ️ O envio é opcional. Se você dispensar, o pedido segue o fluxo normal.',
              style: TextStyle(fontSize: 11, color: FincoreColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(null),
          child: const Text('Dispensar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: _enviando ? null : _confirmarEnvio,
          icon: _enviando
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(_enviando ? 'Enviando...' : 'Disparar WhatsApp 🚀'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}
