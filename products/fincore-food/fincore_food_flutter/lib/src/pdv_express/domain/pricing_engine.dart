import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import '../models/pdv_item.dart';
import '../../cap/pricing/pricing_strategy_factory.dart';
import '../../cap/pricing/pricing_strategy.dart';

class PricingGroup {
  final String id;
  final String name;

  const PricingGroup({required this.id, required this.name});
}

class PricingRange {
  final String id;
  final String groupId;
  final int minQty;
  final int? maxQty;
  final int unitPriceInCents;

  const PricingRange({
    required this.id,
    required this.groupId,
    required this.minQty,
    this.maxQty,
    required this.unitPriceInCents,
  });
}

class GroupPricingSummary {
  final PricingGroup group;
  final double totalQty;
  final int appliedUnitPriceInCents;
  final PricingRange? appliedRange;
  final PricingRange? nextRange;
  final double? qtyNeededForNextRange;
  final int? potentialSavingsInCents;

  const GroupPricingSummary({
    required this.group,
    required this.totalQty,
    required this.appliedUnitPriceInCents,
    this.appliedRange,
    this.nextRange,
    this.qtyNeededForNextRange,
    this.potentialSavingsInCents,
  });
}

class PricingResult {
  final Map<String, int> unitPrices;
  final List<GroupPricingSummary> groupSummaries;

  const PricingResult({
    required this.unitPrices,
    required this.groupSummaries,
  });
}

/// PricingEngine refatorado para usar Strategy Pattern via [PricingStrategyFactory].
///
/// O método [resolvePrice] é o ponto de entrada para o cálculo de preço
/// unitário de um produto, delegando à estratégia correta baseada na
/// [UnidadeVenda] do produto.
///
/// O método [calculate] (legado) continua disponível para compatibilidade
/// com as views que ainda usam PricingResult por grupos de tabela.
class PricingEngine {
  final ProdutoTabelaPrecificacaoRepository _assocRepo;
  final ItemTabelaPrecificacaoRepository _itemRepo;
  final TabelaPrecificacaoRepository _tabelaRepo;
  final PricingStrategyFactory _strategyFactory;

  PricingEngine({
    required ProdutoTabelaPrecificacaoRepository assocRepo,
    required ItemTabelaPrecificacaoRepository itemRepo,
    required TabelaPrecificacaoRepository tabelaRepo,
  })  : _assocRepo = assocRepo,
        _itemRepo = itemRepo,
        _tabelaRepo = tabelaRepo,
        _strategyFactory = const PricingStrategyFactory();

  /// Resolve o preço unitário em centavos para um produto e quantidade.
  ///
  /// 1. Busca a tabela de preço associada ao produto.
  /// 2. Encontra a faixa de preço aplicável à [quantidade].
  /// 3. Aplica a estratégia correta com base na [UnidadeVenda] do produto.
  ///
  /// Retorna 0 se não houver tabela ou faixa configurada.
  Future<int> resolvePrice({
    required String produtoId,
    required int quantidade,
    UnidadeVenda unidadeVenda = UnidadeVenda.un,
  }) async {
    try {
      final assocs = await _assocRepo.findByProdutoId(produtoId);
      final activeAssoc = assocs.firstWhere(
        (a) => a.ativo,
        orElse: () => throw Exception('Sem tabela ativa'),
      );

      final tabela = await _tabelaRepo.findById(activeAssoc.tabelaPrecificacaoId);
      if (tabela == null || !tabela.ativo) return 0;

      final itens = await _itemRepo.findByTabelaId(tabela.id);
      itens.sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));

      // Encontra a faixa aplicável
      int basePrice = 0;
      for (final faixa in itens) {
        if (quantidade >= faixa.quantidadeMinima &&
            (faixa.quantidadeMaxima == null || quantidade <= faixa.quantidadeMaxima!)) {
          basePrice = faixa.valorUnitarioCentavos;
          break;
        }
      }

      // Fallback: usa a primeira faixa se nenhuma foi encontrada
      if (basePrice == 0 && itens.isNotEmpty) {
        basePrice = itens.first.valorUnitarioCentavos;
      }

      // Delega o cálculo à estratégia correta
      final PricingStrategy strategy = _strategyFactory.getStrategy(unidadeVenda);
      return strategy.calculate(basePrice: basePrice, quantity: quantidade);
    } catch (_) {
      return 0;
    }
  }

  /// Método legado: calcula preços agrupados por tabela.
  /// Mantido para compatibilidade com as views existentes.
  PricingResult calculate({
    required List<PdvItem> cartItems,
    required Map<String, String> productToGroupMapping,
    required Map<String, int> productBasePrices,
  }) {
    final quantitiesPerGroup = <String, double>{};
    for (final item in cartItems) {
      final groupId = productToGroupMapping[item.productId];
      if (groupId != null) {
        quantitiesPerGroup.update(
          groupId,
          (val) => val + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    final unitPrices = <String, int>{};
    final groupSummaries = <GroupPricingSummary>[];

    for (final item in cartItems) {
      unitPrices[item.productId] = productBasePrices[item.productId] ?? item.priceInCents;
    }

    return PricingResult(unitPrices: unitPrices, groupSummaries: groupSummaries);
  }
}
