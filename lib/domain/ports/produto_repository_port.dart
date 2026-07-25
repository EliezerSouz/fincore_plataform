import '../../database/app_database.dart';
import '../../models/domain_models.dart';

abstract class IProdutoRepository {
  Stream<List<Produto>> observar();
  Future<int> salvar({
    int? id,
    required String nome,
    required String categoria,
    required int grupoPrecoId,
    int tempoMedioMinutos,
    bool controlaEstoque,
    int ordemProducao,
    int estoqueMinimo,
    int estoqueIdeal,
    int loteMinimo,
    bool ativo = true,
  });
  Future<ProdutoComGrupo?> comGrupo(Produto produto);
  Future<void> desativar(int id);
}
