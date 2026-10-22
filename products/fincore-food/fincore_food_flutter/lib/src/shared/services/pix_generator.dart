/// Gerador de Payload e Código Pix Copia e Cola conforme o padrão oficial do
/// Banco Central do Brasil (Bacen / EMV QRCPS-MPM).
class PixGenerator {
  static String _formatTlv(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  /// Remove acentos e caracteres especiais para compatibilidade com padrão ASCII do Bacen
  static String _removerAcentos(String texto) {
    const comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const semAcento = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    String resultado = texto;
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Normaliza a chave Pix para o padrão exigido pelo Banco Central:
  /// - Telefone: E.164 com prefixo internacional (+55 + DDD + NUMERO) sem máscaras ou traços
  /// - CPF: 11 dígitos numéricos
  /// - CNPJ: 14 dígitos numéricos
  /// - E-mail: minúsculas e sem espaços
  /// - Chave Aleatória: minúsculas e sem espaços
  static String normalizarChave({
    required String chave,
    String? tipo,
  }) {
    String clean = chave.trim();
    if (clean.isEmpty) return '';

    final tipoUpper = tipo?.toUpperCase().trim() ?? '';

    // 1. Tipo especificado explicitamente como TELEFONE / CELULAR
    if (tipoUpper.contains('TEL') || tipoUpper.contains('CEL') || tipoUpper.contains('FONE')) {
      String digitos = clean.replaceAll(RegExp(r'\D'), '');
      if (digitos.startsWith('55') && (digitos.length == 12 || digitos.length == 13)) {
        digitos = digitos.substring(2);
      }
      return '+55$digitos';
    }

    // 2. Tipo especificado como CPF
    if (tipoUpper.contains('CPF')) {
      return clean.replaceAll(RegExp(r'\D'), '');
    }

    // 3. Tipo especificado como CNPJ
    if (tipoUpper.contains('CNPJ')) {
      return clean.replaceAll(RegExp(r'\D'), '');
    }

    // 4. Tipo especificado como E-mail ou contém @
    if (tipoUpper.contains('EMAIL') || tipoUpper.contains('E-MAIL') || clean.contains('@')) {
      return clean.toLowerCase().replaceAll(' ', '');
    }

    // 5. AUTO-DETECÇÃO quando o tipo não foi passado ou é genérico:
    if (clean.contains('@')) {
      return clean.toLowerCase().replaceAll(' ', '');
    }

    // Se já começa com +, trata como telefone internacional
    if (clean.startsWith('+')) {
      final digitos = clean.replaceAll(RegExp(r'\D'), '');
      return '+$digitos';
    }

    final apenasDigitos = clean.replaceAll(RegExp(r'\D'), '');

    // CNPJ: 14 dígitos
    if (apenasDigitos.length == 14) {
      return apenasDigitos;
    }

    // Telefone fixo (10 dígitos: DDD + 8 dígitos)
    if (apenasDigitos.length == 10) {
      return '+55$apenasDigitos';
    }

    // 12 ou 13 dígitos começando com 55 (ex: 5511999998888) -> Telefone com DDI
    if ((apenasDigitos.length == 12 || apenasDigitos.length == 13) && apenasDigitos.startsWith('55')) {
      return '+$apenasDigitos';
    }

    // 11 dígitos: Celular ou CPF
    if (apenasDigitos.length == 11) {
      // Se tiver máscara de telefone com parêntese ou traço: (11) 98888-7777
      if (clean.contains('(') || clean.contains(')') || clean.contains('-') && clean.indexOf('-') > 4) {
        return '+55$apenasDigitos';
      }
      // Se o terceiro dígito for 9 (ex: 11988887777), é padrão celular brasileiro
      final ddd = int.tryParse(apenasDigitos.substring(0, 2)) ?? 0;
      final nonoDigito = apenasDigitos.substring(2, 3);
      if (ddd >= 11 && ddd <= 99 && nonoDigito == '9') {
        // Se o tipo foi explicitamente omitido ou sugerido telefone, formata como +55
        // Se for um CPF numérico puro sem tipo, o usuário pode ter cadastrado CPF.
        // Porém, se o tipo for CPF, o if (tipoUpper.contains('CPF')) acima já cuidou.
        return apenasDigitos;
      }
      return apenasDigitos;
    }

    // Chave Aleatória (UUID) ou texto simples
    return clean.toLowerCase().replaceAll(' ', '');
  }

  static String gerarCopiaCola({
    required String chave,
    required String favorecido,
    required String cidade,
    required double valor,
    String mensagem = '',
    String? tipoChave,
  }) {
    // Normaliza a chave conforme a regra do Bacen
    final chaveNormalizada = normalizarChave(
      chave: chave,
      tipo: tipoChave,
    );

    // 00: Payload Format Indicator (Fixed "01")
    String payload = _formatTlv('00', '01');

    // 26: Merchant Account Information
    // Subtag 00: GUI (br.gov.bcb.pix)
    // Subtag 01: Chave Pix
    // Subtag 02: Mensagem (opcional)
    String merchantInfo = _formatTlv('00', 'br.gov.bcb.pix') + _formatTlv('01', chaveNormalizada);
    if (mensagem.trim().isNotEmpty) {
      final cleanMsg = _removerAcentos(mensagem);
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

    // 59: Merchant Name (Máx 25 chars, sem acentos, maiúsculo padrão Bacen)
    final cleanFav = _removerAcentos(favorecido).toUpperCase();
    final name = cleanFav.substring(0, cleanFav.length.clamp(0, 25));
    payload += _formatTlv('59', name.isNotEmpty ? name : 'ESTABELECIMENTO');

    // 60: Merchant City (Máx 15 chars, sem acentos, maiúsculo padrão Bacen)
    final cleanCity = _removerAcentos(cidade).toUpperCase();
    final city = cleanCity.substring(0, cleanCity.length.clamp(0, 15));
    payload += _formatTlv('60', city.isNotEmpty ? city : 'POUSO ALEGRE');

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
