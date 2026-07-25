import '../../core/errors/app_exceptions.dart';
import '../../models/domain_models.dart';
import '../ports/grupo_preco_repository_port.dart';

/// Caso de uso que recalcula o preço unitário e total dos itens do carrinho
/// com base no acumulado de quantidades por grupo de preço.
///
/// Aceita qualquer implementação de [IGrupoPrecoRepository] (Drift local na Fase 1,
/// API HTTP no backend Go na Fase 2).
class RecalcularPrecoUseCase {
  final IGrupoPrecoRepository _grupos;
  const RecalcularPrecoUseCase(this._grupos);

  Future<List<ResumoGrupo>> call(List<ItemCarrinho> itens) async {
    if (itens.isEmpty) return [];

    final quantidades = <int, int>{};
    for (final item in itens) {
      quantidades.update(
        item.grupo.id,
        (v) => v + item.quantidade,
        ifAbsent: () => item.quantidade,
      );
    }

    final resumos = <ResumoGrupo>[];
    for (final entry in quantidades.entries) {
      final preco = await _grupos.preco(entry.key, entry.value);
      if (preco == null) {
        throw ValidationException(
          'O grupo não possui uma faixa de preço para ${entry.value} unidades.',
        );
      }
      final grupo = itens.firstWhere((i) => i.grupo.id == entry.key).grupo;
      for (final item in itens.where((i) => i.grupo.id == entry.key)) {
        item.valorUnitarioCentavos = preco;
      }
      resumos.add(ResumoGrupo(grupo, entry.value, preco));
    }
    return resumos;
  }
}
