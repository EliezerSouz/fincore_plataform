import 'print_date.dart';

/// Componente de impressão reutilizável para o cabeçalho padrão de cupom.
class PrintHeader {
  const PrintHeader._();

  /// Gera as linhas do cabeçalho do cupom.
  static List<String> render({
    required String nomeEmpresaCupom,
    String? cnpj,
    String? telefone,
    String? endereco,
    required String tipoLogistica,
    required DateTime dataHora,
    required String shortId,
    int width = 48,
  }) {
    final lines = <String>[];
    final divSingle = '-' * width;

    lines.add('[CENTER][BOLD_ON]${nomeEmpresaCupom.toUpperCase()}[BOLD_OFF]');
    
    if (cnpj != null && cnpj.trim().isNotEmpty) {
      lines.add('[CENTER]CNPJ: ${cnpj.trim()}');
    }
    
    if (telefone != null && telefone.trim().isNotEmpty) {
      lines.add('[CENTER]TEL: ${telefone.trim()}');
    }
    
    if (endereco != null && endereco.trim().isNotEmpty) {
      lines.add('[CENTER]${endereco.trim()}');
    }
    
    lines.add('[CENTER][BOLD_ON]${tipoLogistica.toUpperCase()}[BOLD_OFF]');
    lines.add('[CENTER]${PrintDate.format(dataHora.toLocal())}');
    lines.add('[CENTER][BOLD_ON]PEDIDO #$shortId[BOLD_OFF]');
    lines.add(divSingle);

    return lines;
  }
}
