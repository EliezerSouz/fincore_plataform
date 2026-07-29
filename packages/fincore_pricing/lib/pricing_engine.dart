import 'repository/tabela_precificacao_repository.dart';
import 'repository/item_tabela_precificacao_repository.dart';
import 'repository/produto_tabela_precificacao_repository.dart';
import 'common/pricing_models.dart';

class PricingEngine {
  final TabelaPrecificacaoRepository tabelaRepo;
  final ItemTabelaPrecificacaoRepository itemRepo;
  final ProdutoTabelaPrecificacaoRepository assocRepo;

  PricingEngine({
    required this.tabelaRepo,
    required this.itemRepo,
    required this.assocRepo,
  });

  /// Resolve o preço unitário final em centavos de um produto com base na quantidade, canal e grupo de cliente.
  Future<int> resolvePrice({
    required String produtoId,
    required int quantidade,
    String? canal,
    String? clienteGrupo,
  }) async {
    final now = DateTime.now();

    // 1. Obter associações do produto
    final assocs = await assocRepo.findByProdutoId(produtoId);

    // 2. Filtrar associações ativas e vigentes
    final activeAssocs = assocs.where((assoc) {
      if (!assoc.ativo) return false;
      if (assoc.dataInicio != null && now.isBefore(assoc.dataInicio!)) return false;
      if (assoc.dataFim != null && now.isAfter(assoc.dataFim!)) return false;
      return true;
    }).toList();

    if (activeAssocs.isEmpty) {
      throw StateError('Nenhuma tabela de precificação ativa ou vigente encontrada para o produto $produtoId.');
    }

    // 3. Obter as tabelas correspondentes e resolver prioridades
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

    // 4. Ordenar candidatos por canal específico e prioridade decrescente
    candidateTables.sort((a, b) {
      // 4.1 Canal específico tem precedência
      if (canal != null) {
        final aMatchesCanal = a.tabela.nome.toLowerCase().contains(canal.toLowerCase());
        final bMatchesCanal = b.tabela.nome.toLowerCase().contains(canal.toLowerCase());
        if (aMatchesCanal && !bMatchesCanal) return -1;
        if (!aMatchesCanal && bMatchesCanal) return 1;
      }

      // 4.2 Grupo de cliente específico tem precedência
      if (clienteGrupo != null) {
        final aMatchesGroup = a.tabela.nome.toLowerCase().contains(clienteGrupo.toLowerCase());
        final bMatchesGroup = b.tabela.nome.toLowerCase().contains(clienteGrupo.toLowerCase());
        if (aMatchesGroup && !bMatchesGroup) return -1;
        if (!aMatchesGroup && bMatchesGroup) return 1;
      }

      // 4.3 Ordenação por prioridade (decrescente)
      final compPrioridade = b.prioridadeEfetiva.compareTo(a.prioridadeEfetiva);
      if (compPrioridade != 0) return compPrioridade;

      // 4.4 Vigência mais restrita (menor duração) tem precedência
      final aDuration = _getDuration(a.association);
      final bDuration = _getDuration(b.association);
      return aDuration.compareTo(bDuration);
    });

    // Vencedor da resolução
    final winningCandidate = candidateTables.first;

    // 5. Buscar itens de precificação da tabela vencedora
    final itens = await itemRepo.findByTabelaId(winningCandidate.tabela.id);
    if (itens.isEmpty) {
      throw StateError('Nenhum item/faixa de preço cadastrado na tabela ${winningCandidate.tabela.nome} (${winningCandidate.tabela.id}).');
    }

    // 6. Aplicar regra de faixa/política correspondente
    for (final item in itens) {
      if (quantidade >= item.quantidadeMinima &&
          (item.quantidadeMaxima == null || quantidade <= item.quantidadeMaxima!)) {
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
