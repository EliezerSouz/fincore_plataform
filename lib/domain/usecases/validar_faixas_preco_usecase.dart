import '../../core/errors/app_exceptions.dart';
import '../../models/domain_models.dart';

/// Caso de uso que valida se uma lista de faixas de preço por quantidade é válida.
///
/// Regras:
/// - Pelo menos uma faixa deve existir.
/// - Quantidades mínimas e preços devem ser maiores que zero.
/// - Nenhuma faixa pode ter quantidade máxima menor que a mínima.
/// - Faixas não podem se sobrepor nem ter lacunas inconsistentes.
class ValidarFaixasPrecoUseCase {
  const ValidarFaixasPrecoUseCase();

  void call(List<FaixaInput> faixas) {
    if (faixas.isEmpty) {
      throw const ValidationException('Cadastre ao menos uma faixa.');
    }
    final lista = [...faixas]..sort((a, b) => a.minima.compareTo(b.minima));
    for (var i = 0; i < lista.length; i++) {
      final f = lista[i];
      if (f.minima < 1 || f.valorCentavos < 1) {
        throw const ValidationException(
            'Quantidade e preço devem ser maiores que zero.');
      }
      if (f.maxima != null && f.maxima! < f.minima) {
        throw const ValidationException(
            'Quantidade máxima menor que a mínima.');
      }
      if (i > 0) {
        final anterior = lista[i - 1];
        if (anterior.maxima == null || f.minima <= anterior.maxima!) {
          throw const ValidationException(
              'Existem faixas de preço sobrepostas.');
        }
      }
    }
  }
}
