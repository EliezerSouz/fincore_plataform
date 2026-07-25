import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../data/services/impressora_pdf.dart';
import '../../../models/domain_models.dart';
import '../../../services/settings_service.dart';

class PreviewCupomWidget extends StatelessWidget {
  final PedidoCompleto pedidoCompleto;
  final AppSettings settings;

  const PreviewCupomWidget({
    super.key,
    required this.pedidoCompleto,
    required this.settings,
  });

  static Future<void> exibirDialog(
    BuildContext context, {
    required PedidoCompleto pedidoCompleto,
    required AppSettings settings,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 500,
          height: 650,
          child: Column(
            children: [
              AppBar(
                title: Text('Pré-visualização Cupom #${pedidoCompleto.pedido.numero}'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: PreviewCupomWidget(
                  pedidoCompleto: pedidoCompleto,
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (format) => ImpressoraPdf.gerarPdfBytes(pedidoCompleto, settings),
      allowPrinting: true,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
    );
  }
}
