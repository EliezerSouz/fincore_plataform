import 'package:fincore_shared/fincore_shared.dart';

/// Componente de impressão reutilizável para formatar endereços no cupom.
class PrintAddress {
  const PrintAddress._();

  /// Gera a formatação do endereço em linhas para impressão térmica.
  static List<String> format({
    required String logradouro,
    String numero = '',
    required String bairro,
    String cidade = '',
    String uf = '',
    String? referencia,
    String? cep,
  }) {
    final addr = FincoreAddress(
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      uf: uf,
      cep: cep ?? '',
    );

    final lines = <String>[];
    
    // Obter as linhas sugeridas pelo Value Object
    final printLines = FincoreAddressFormatter.formatForPrint(addr);
    for (final line in printLines) {
      if (line.isNotEmpty) {
        lines.add('  $line');
      }
    }

    if (referencia != null && referencia.trim().isNotEmpty) {
      lines.add('  REF: ${referencia.trim()}');
    }

    return lines;
  }
}
