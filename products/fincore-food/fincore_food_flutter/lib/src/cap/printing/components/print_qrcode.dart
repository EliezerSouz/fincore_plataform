/// Componente de impressão para gerar tags de QR Code ESC/POS.
class PrintQrCode {
  const PrintQrCode._();

  /// Retorna a tag de impressão de QR Code compatível com o driver.
  static String format(String data) {
    if (data.trim().isEmpty) return '';
    return '[QRCODE:${data.trim()}]';
  }
}
