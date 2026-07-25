import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../domain/ports/produto_repository_port.dart';
import '../../models/domain_models.dart';

class ProdutoRepository implements IProdutoRepository {
  final AppDatabase db;
  ProdutoRepository(this.db);

  @override
  Stream<List<Produto>> observar() => (db.select(db.produtos)
        ..where((p) => p.ativo.equals(true))
        ..orderBy([(p) => OrderingTerm.asc(p.nome)]))
      .watch();

  @override
  Future<int> salvar({
    int? id,
    required String nome,
    required String categoria,
    required int grupoPrecoId,
    int tempoMedioMinutos = 10,
    bool controlaEstoque = true,
    int ordemProducao = 0,
    int estoqueMinimo = 0,
    int estoqueIdeal = 0,
    int loteMinimo = 1,
    bool ativo = true,
  }) async {
    final prodId = id == null
        ? await db.into(db.produtos).insert(ProdutosCompanion.insert(
            nome: nome.trim(),
            categoria: Value(categoria.trim()),
            grupoPrecoId: Value(grupoPrecoId),
            tempoMedioMinutos: Value(tempoMedioMinutos),
            controlaEstoque: Value(controlaEstoque),
            ordemProducao: Value(ordemProducao),
            ativo: Value(ativo)))
        : await (db.update(db.produtos)..where((p) => p.id.equals(id)))
            .write(ProdutosCompanion(
                nome: Value(nome.trim()),
                categoria: Value(categoria.trim()),
                grupoPrecoId: Value(grupoPrecoId),
                tempoMedioMinutos: Value(tempoMedioMinutos),
                controlaEstoque: Value(controlaEstoque),
                ordemProducao: Value(ordemProducao),
                ativo: Value(ativo)))
            .then((_) => id);

    // Salvar/Atualizar estoque mínimo correspondente
    final est = await (db.select(db.estoqueAtual)
          ..where((e) => e.produtoId.equals(prodId)))
        .getSingleOrNull();

    if (est == null) {
      await db.into(db.estoqueAtual).insert(EstoqueAtualCompanion.insert(
            produtoId: Value(prodId),
            saldoAtual: const Value(0),
            reservado: const Value(0),
            estoqueMinimo: Value(estoqueMinimo),
            estoqueIdeal: Value(estoqueIdeal),
            loteMinimo: Value(loteMinimo),
          ));
    } else {
      await (db.update(db.estoqueAtual)..where((e) => e.produtoId.equals(prodId)))
          .write(EstoqueAtualCompanion(
            estoqueMinimo: Value(estoqueMinimo),
            estoqueIdeal: Value(estoqueIdeal),
            loteMinimo: Value(loteMinimo),
          ));
    }

    return prodId;
  }

  @override
  Future<ProdutoComGrupo?> comGrupo(Produto produto) async {
    if (produto.grupoPrecoId == null) return null;
    final grupo = await (db.select(db.gruposPreco)
          ..where((g) => g.id.equals(produto.grupoPrecoId!)))
        .getSingleOrNull();
    return grupo == null ? null : ProdutoComGrupo(produto, grupo);
  }

  @override
  Future<void> desativar(int id) =>
      (db.update(db.produtos)..where((p) => p.id.equals(id)))
          .write(const ProdutosCompanion(ativo: Value(false)));
}
