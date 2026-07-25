import '../../database/app_database.dart';
import '../../models/domain_models.dart';

abstract class IGrupoPrecoRepository {
  Stream<List<GruposPrecoData>> observar();
  Future<List<FaixasPrecoData>> faixas(int grupoId);
  Future<int?> preco(int grupoId, int quantidade);
  Future<int> salvar({
    int? id,
    required String nome,
    String descricao = '',
    required List<FaixaInput> faixas,
  });
}
