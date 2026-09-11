import 'package:fincore_shared/fincore_shared.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import 'print_qrcode.dart';

/// Componente de impressão reutilizável para renderizar dados PIX e QR Code no cupom.
class PrintPix {
  const PrintPix._();

  /// Gera a seção de pagamento PIX em linhas para o cupom.
  static List<String> render({
    required int totalCentavos,
    required String chave,
    required String tipoChave,
    required String favorecido,
    required String cidade,
    required String mensagemRodape,
    bool imprimirQRCode = true,
    bool imprimirCopiaCola = true,
    int width = 48,
  }) {
    final lines = <String>[];
    final divSingle = '-' * width;
    final double valorPix = totalCentavos / 100.0;

    final pixKeyVO = FincorePixKey(
      value: chave,
      tipo: PixKeyTipo.values.firstWhere(
        (t) => t.name.toLowerCase() == tipoChave.toLowerCase(),
        orElse: () => PixKeyTipo.aleatoria,
      ),
    );

    if (pixKeyVO.isEmpty) return lines;

    final copiaCola = PixGenerator.gerarCopiaCola(
      chave: pixKeyVO.clean,
      favorecido: favorecido.isNotEmpty ? favorecido : 'Estabelecimento',
      cidade: cidade.isNotEmpty ? cidade : 'Pouso Alegre - MG',
      valor: valorPix,
      mensagem: mensagemRodape.isNotEmpty ? mensagemRodape : 'Salgaderia',
    );

    lines.add('[CENTER][BOLD_ON]PAGAMENTO VIA PIX[BOLD_OFF]');
    
    if (imprimirQRCode) {
      final qr = PrintQrCode.format(copiaCola);
      if (qr.isNotEmpty) {
        lines.add(qr);
      }
    } else {
      lines.add('[CENTER][BOLD_ON]Chave: ${pixKeyVO.formatted} (${pixKeyVO.tipoLabel})[BOLD_OFF]');
      if (favorecido.trim().isNotEmpty) {
        lines.add('[CENTER]Favorecido: ${favorecido.trim()}');
      }
      if (imprimirCopiaCola) {
        lines.add('[CENTER]Pix Copia e Cola:');
        lines.add(copiaCola);
      }
    }
    lines.add(divSingle);

    return lines;
  }
}
