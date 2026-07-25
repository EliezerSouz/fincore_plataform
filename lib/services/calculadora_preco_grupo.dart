import '../models/domain_models.dart';
import '../repositories/repositories.dart';

class CalculadoraPrecoGrupo {
  final GrupoPrecoRepository grupos;
  CalculadoraPrecoGrupo(this.grupos);

  Future<List<ResumoGrupo>> recalcular(List<ItemCarrinho> itens) async {
    final quantidades = <int, int>{};
    for (final item in itens) {
      quantidades.update(item.grupo.id, (v) => v + item.quantidade,
          ifAbsent: () => item.quantidade);
    }
    final resumos = <ResumoGrupo>[];
    for (final entry in quantidades.entries) {
      final preco = await grupos.preco(entry.key, entry.value);
      if (preco == null) {
        throw StateError(
            'O grupo não possui uma faixa para ${entry.value} unidades.');
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
