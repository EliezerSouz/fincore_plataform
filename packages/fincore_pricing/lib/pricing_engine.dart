import 'repository/tabela_precificacao_repository.dart';
import 'repository/item_tabela_precificacao_repository.dart';
import 'repository/produto_tabela_precificacao_repository.dart';
import 'repository/categoria_tabela_precificacao_repository.dart';
import 'common/pricing_models.dart';

class PricingEngine {
  final TabelaPrecificacaoRepository tabelaRepo;
  final ItemTabelaPrecificacaoRepository itemRepo;
  final ProdutoTabelaPrecificacaoRepository assocRepo;
  final CategoriaTabelaPrecificacaoRepository? catAssocRepo;

  PricingEngine({
    required this.tabelaRepo,
    required this.itemRepo,
    required this.assocRepo,
    this.catAssocRepo,
  });

  /// Resolve o preço unitário final em centavos de um produto com base na quantidade, canal e grupo de cliente.
  Future<int> resolvePrice({
    required String produtoId,
    required int quantidade,
    int? quantidadeGrupo,
    String? canal,
    String? clienteGrupo,
  }) async {
    final now = DateTime.now();

    // 1. Obter a categoria do produto para fallback
    String? currentCategoriaId;
    try {
      final db = assocRepo.db;
      final productRow = await (db.select(db.produtosTable)
            ..where((t) => t.id.equals(produtoId)))
          .getSingleOrNull();
      currentCategoriaId = productRow?.categoriaId;
    } catch (_) {}

    // 2. Obter associações do produto
    final assocs = await assocRepo.findByProdutoId(produtoId);

    // 3. Filtrar associações do produto ativas e vigentes
    var activeAssocs = assocs.where((assoc) {
      if (!assoc.ativo) return false;
      if (assoc.dataInicio != null && now.isBefore(assoc.dataInicio!)) return false;
      if (assoc.dataFim != null && now.isAfter(assoc.dataFim!)) return false;
      return true;
    }).toList();

    // 3.1 Fallback por Categoria (Herança de Preço)
    if (activeAssocs.isEmpty && catAssocRepo != null && currentCategoriaId != null) {
      String? nextCatId = currentCategoriaId;
      final db = assocRepo.db;

      while (nextCatId != null && activeAssocs.isEmpty) {
        final catAssocs = await catAssocRepo!.findByCategoriaId(nextCatId);

        // Filtra as associações da categoria ativas e vigentes
        final validCatAssocs = catAssocs.where((assoc) {
          if (!assoc.ativo) return false;
          if (assoc.dataInicio != null && now.isBefore(assoc.dataInicio!)) return false;
          if (assoc.dataFim != null && now.isAfter(assoc.dataFim!)) return false;
          return true;
        }).toList();

        if (validCatAssocs.isNotEmpty) {
          // Converte CategoriaTabelaPrecificacao para candidatos de tabela correspondentes
          activeAssocs = validCatAssocs.map((catAssoc) {
            return ProdutoTabelaPrecificacao(
              id: catAssoc.id,
              tenantId: catAssoc.tenantId,
              produtoId: produtoId,
              tabelaPrecificacaoId: catAssoc.tabelaPrecificacaoId,
              ativo: catAssoc.ativo,
              prioridade: catAssoc.prioridade,
              dataInicio: catAssoc.dataInicio,
              dataFim: catAssoc.dataFim,
              metadata: catAssoc.metadata,
            );
          }).toList();
          break; // Encontrou associação ativa na categoria
        }

        // Sobe na hierarquia recursiva da categoria pai (parentId)
        try {
          final catRow = await (db.select(db.categoriasTable)
                ..where((t) => t.id.equals(nextCatId!)))
              .getSingleOrNull();
          nextCatId = catRow?.parentId;
        } catch (_) {
          nextCatId = null;
        }
      }
    }

    if (activeAssocs.isEmpty) {
      throw StateError('Nenhuma tabela de precificação ativa ou vigente encontrada para o produto $produtoId.');
    }

    // 4. Obter as tabelas correspondentes e resolver prioridades
    final candidateTables = <_ResolvedTableCandidate>[];

    for (final assoc in activeAssocs) {
      final tabela = await tabelaRepo.findById(assoc.tabelaPrecificacaoId);
      if (tabela != null && tabela.ativo) {
        // A prioridade efetiva é a do vínculo (se maior que zero), senão usa a da tabela
        final prioridadeEfetiva = assoc.prioridade > 0 ? assoc.prioridade : tabela.prioridade;
        candidateTables.add(_ResolvedTableCandidate(
          tabela: tabela,
          association: assoc,
          prioridadeEfetiva: prioridadeEfetiva,
        ));
      }
    }

    if (candidateTables.isEmpty) {
      throw StateError('Nenhuma tabela de precificação ativa associada ao produto $produtoId.');
    }

    // 5. Ordenar candidatos por canal específico e prioridade decrescente
    // P1-07: Usa campo estruturado `canal` em vez de substring do nome.
    // Prioridade: canal exato > 'todos' > outros canais
    candidateTables.sort((a, b) {
      if (canal != null) {
        // Normaliza canal do pedido para comparar com o campo estruturado
        final canalNorm = canal.toLowerCase();
        final aCanal = a.tabela.canal?.toLowerCase() ?? 'todos';
        final bCanal = b.tabela.canal?.toLowerCase() ?? 'todos';

        // Tabela com canal exato tem prioridade sobre 'todos'
        final aMatch = aCanal == canalNorm;
        final bMatch = bCanal == canalNorm;
        final aTodos = aCanal == 'todos';
        final bTodos = bCanal == 'todos';

        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        if (aTodos && !bTodos) return -1;
        if (!aTodos && bTodos) return 1;
      }

      // 5.2 Grupo de cliente específico tem precedência
      if (clienteGrupo != null) {
        final aMatchesGroup = a.tabela.nome.toLowerCase().contains(clienteGrupo.toLowerCase());
        final bMatchesGroup = b.tabela.nome.toLowerCase().contains(clienteGrupo.toLowerCase());
        if (aMatchesGroup && !bMatchesGroup) return -1;
        if (!aMatchesGroup && bMatchesGroup) return 1;
      }

      // 5.3 Ordenação por prioridade (decrescente)
      final compPrioridade = b.prioridadeEfetiva.compareTo(a.prioridadeEfetiva);
      if (compPrioridade != 0) return compPrioridade;

      // 5.4 Vigência mais restrita (menor duração) tem precedência
      final aDuration = _getDuration(a.association);
      final bDuration = _getDuration(b.association);
      return aDuration.compareTo(bDuration);
    });

    // Vencedor da resolução
    final winningCandidate = candidateTables.first;

    // 6. Buscar itens de precificação da tabela vencedora
    final itens = await itemRepo.findByTabelaId(winningCandidate.tabela.id);
    if (itens.isEmpty) {
      throw StateError('Nenhum item/faixa de preço cadastrado na tabela ${winningCandidate.tabela.nome} (${winningCandidate.tabela.id}).');
    }

    // 7. Aplicar regra de faixa/política correspondente
    final qtyToResolve = quantidadeGrupo ?? quantidade;
    for (final item in itens) {
      if (qtyToResolve >= item.quantidadeMinima &&
          (item.quantidadeMaxima == null || qtyToResolve <= item.quantidadeMaxima!)) {
        return item.valorUnitarioCentavos;
      }
    }

    // Fallback: se não enquadrar em nenhuma faixa, retorna o valor do primeiro item cadastrado
    return itens.first.valorUnitarioCentavos;
  }

  double _getDuration(ProdutoTabelaPrecificacao assoc) {
    if (assoc.dataInicio == null || assoc.dataFim == null) return double.maxFinite;
    return assoc.dataFim!.difference(assoc.dataInicio!).inMinutes.toDouble();
  }
}

class _ResolvedTableCandidate {
  final TabelaPrecificacao tabela;
  final ProdutoTabelaPrecificacao association;
  final int prioridadeEfetiva;

  const _ResolvedTableCandidate({
    required this.tabela,
    required this.association,
    required this.prioridadeEfetiva,
  });
}
