/// Exceções de domínio de cadastro (AUD-003).
///
/// Lançada quando uma regra de unicidade do agregado é violada dentro do
/// mesmo tenant (ex.: duas categorias com o mesmo nome).
class NomeDuplicadoException implements Exception {
  final String entidade;
  final String nome;

  const NomeDuplicadoException({required this.entidade, required this.nome});

  String get mensagem => 'Já existe $entidade cadastrado(a) com o nome "$nome".';

  @override
  String toString() => mensagem;
}

/// Normaliza nomes para comparação de unicidade: ignora caixa,
/// espaços nas pontas e espaços repetidos.
String normalizarNomeCadastro(String nome) =>
    nome.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
