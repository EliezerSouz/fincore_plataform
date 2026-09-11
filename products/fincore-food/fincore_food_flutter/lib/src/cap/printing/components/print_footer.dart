/// Componente de impressão reutilizável para o rodapé padrão de cupom.
class PrintFooter {
  const PrintFooter._();

  /// Gera as linhas do rodapé do cupom.
  static List<String> render({
    required bool imprimirRodape,
    String? mensagemRodape,
  }) {
    final lines = <String>[];

    if (imprimirRodape) {
      lines.add('');
      lines.add('[CENTER]${mensagemRodape ?? "Obrigado pela preferencia!"}');
      //lines.add('[CENTER]Bom apetite!');
    }

    lines.add('');
    lines.add('[CENTER]Desenvolvido por Eliezer Souza - (35) 99250-3114');
    lines.add('');
    return lines;
  }
}
