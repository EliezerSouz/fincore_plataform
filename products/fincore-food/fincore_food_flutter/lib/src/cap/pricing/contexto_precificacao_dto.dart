class ContextoPrecificacaoDto {
  final String? clienteId;
  final String? tabelaPrecoId;
  final DateTime? dataHora;
  final String? canalVenda;
  final String? empresaId;

  const ContextoPrecificacaoDto({
    this.clienteId,
    this.tabelaPrecoId,
    this.dataHora,
    this.canalVenda,
    this.empresaId,
  });
}
