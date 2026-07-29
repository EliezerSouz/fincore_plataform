class PixGenerator {
  static String _formatTlv(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  static String gerarCopiaCola({
    required String chave,
    required String favorecido,
    required String cidade,
    required double valor,
    String mensagem = '',
  }) {
    // 00: Payload Format Indicator (Fixed "01")
    String payload = _formatTlv('00', '01');

    // 26: Merchant Account Information
    // Subtag 00: GUI (br.gov.bcb.pix)
    // Subtag 01: Chave Pix
    // Subtag 02: Mensagem (opcional)
    String merchantInfo = _formatTlv('00', 'br.gov.bcb.pix') + _formatTlv('01', chave);
    if (mensagem.trim().isNotEmpty) {
      final cleanMsg = mensagem.replaceAll(RegExp(r'[^\w\s]'), '');
      final truncated = cleanMsg.substring(0, cleanMsg.length.clamp(0, 25));
      merchantInfo += _formatTlv('02', truncated);
    }
    payload += _formatTlv('26', merchantInfo);

    // 52: Merchant Category Code (Fixed "0000")
    payload += _formatTlv('52', '0000');

    // 53: Transaction Currency (BRL = 986)
    payload += _formatTlv('53', '986');

    // 54: Transaction Amount (Only if > 0)
    if (valor > 0) {
      payload += _formatTlv('54', valor.toStringAsFixed(2));
    }

    // 58: Country Code (Fixed "BR")
    payload += _formatTlv('58', 'BR');

    // 59: Merchant Name
    final cleanFav = favorecido.replaceAll(RegExp(r'[^\w\s]'), '');
    final name = cleanFav.substring(0, cleanFav.length.clamp(0, 25));
    payload += _formatTlv('59', name.isNotEmpty ? name : 'Estabelecimento');

    // 60: Merchant City
    final cleanCity = cidade.replaceAll(RegExp(r'[^\w\s]'), '');
    final city = cleanCity.substring(0, cleanCity.length.clamp(0, 15));
    payload += _formatTlv('60', city.isNotEmpty ? city : 'Sorocaba');

    // 62: Additional Data Field Template (Subtag 05: Reference Label "***")
    payload += _formatTlv('62', _formatTlv('05', '***'));

    // 63: CRC16 prefix
    payload += '6304';

    // Calculate CRC16 checksum
    final crc = _calcularCrc16(payload);
    final crcHex = crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$payload$crcHex';
  }

  static int _calcularCrc16(String payload) {
    int crc = 0xFFFF;
    final bytes = payload.codeUnits;
    for (int byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc;
  }
}
