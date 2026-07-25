import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String titulo;
  final String mensagem;
  final String textoConfirmar;
  final String textoCancelar;
  final bool ehPerigoso;

  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensagem,
    this.textoConfirmar = 'Confirmar',
    this.textoCancelar = 'Cancelar',
    this.ehPerigoso = false,
  });

  static Future<bool> exibir(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    String textoConfirmar = 'Confirmar',
    String textoCancelar = 'Cancelar',
    bool ehPerigoso = false,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        titulo: titulo,
        mensagem: mensagem,
        textoConfirmar: textoConfirmar,
        textoCancelar: textoCancelar,
        ehPerigoso: ehPerigoso,
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(mensagem),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(textoCancelar),
        ),
        FilledButton(
          style: ehPerigoso
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(textoConfirmar),
        ),
      ],
    );
  }
}
