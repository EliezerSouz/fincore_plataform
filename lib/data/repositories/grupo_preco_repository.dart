import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../domain/ports/grupo_preco_repository_port.dart';
import '../../domain/usecases/validar_faixas_preco_usecase.dart';
import '../../models/domain_models.dart';

class GrupoPrecoRepository implements IGrupoPrecoRepository {
  final AppDatabase db;
  final ValidarFaixasPrecoUseCase _validarFaixasUseCase;

  GrupoPrecoRepository(this.db,
      {ValidarFaixasPrecoUseCase validarFaixasUseCase =
          const ValidarFaixasPrecoUseCase()})
      : _validarFaixasUseCase = validarFaixasUseCase;

  @override
  Stream<List<GruposPrecoData>> observar() => (db.select(db.gruposPreco)
        ..where((g) => g.ativo.equals(true))
        ..orderBy([(g) => OrderingTerm.asc(g.nome)]))
      .watch();

  @override
  Future<List<FaixasPrecoData>> faixas(int grupoId) => (db.select(db.faixasPreco)
        ..where((f) => f.grupoPrecoId.equals(grupoId))
        ..orderBy([(f) => OrderingTerm.asc(f.quantidadeMinima)]))
      .get();

  @override
  Future<int?> preco(int grupoId, int quantidade) async {
    final q = db.select(db.faixasPreco)
      ..where((f) =>
          f.grupoPrecoId.equals(grupoId) &
          f.quantidadeMinima.isSmallerOrEqualValue(quantidade) &
          (f.quantidadeMaxima.isNull() |
              f.quantidadeMaxima.isBiggerOrEqualValue(quantidade)))
      ..limit(1);
    return (await q.getSingleOrNull())?.valorUnitarioCentavos;
  }

  @override
  Future<int> salvar({
    int? id,
    required String nome,
    String descricao = '',
    required List<FaixaInput> faixas,
  }) =>
      db.transaction(() async {
        _validarFaixasUseCase(faixas);
        int grupoId;
        if (id == null) {
          grupoId = await db.into(db.gruposPreco).insert(
                GruposPrecoCompanion.insert(
                  nome: nome.trim(),
                  descricao: Value(descricao.trim()),
                ),
              );
        } else {
          grupoId = id;
          await (db.update(db.gruposPreco)..where((g) => g.id.equals(id))).write(
            GruposPrecoCompanion(
              nome: Value(nome.trim()),
              descricao: Value(descricao.trim()),
            ),
          );
        }

        await (db.delete(db.faixasPreco)
              ..where((f) => f.grupoPrecoId.equals(grupoId)))
            .go();

        for (final f in faixas) {
          await db.into(db.faixasPreco).insert(
                FaixasPrecoCompanion.insert(
                  produtoId: const Value(null),
                  grupoPrecoId: Value(grupoId),
                  quantidadeMinima: f.minima,
                  quantidadeMaxima: Value(f.maxima),
                  valorUnitarioCentavos: f.valorCentavos,
                ),
              );
        }
        return grupoId;
      });

  /// Mantido por compatibilidade retroativa.
  static void validarFaixas(List<FaixaInput> faixas) {
    const ValidarFaixasPrecoUseCase()(faixas);
  }
}
