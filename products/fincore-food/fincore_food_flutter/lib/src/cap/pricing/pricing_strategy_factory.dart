import 'package:fincore_core/common/master_data_models.dart';
import 'pricing_strategy.dart';
import 'strategies/unidade_strategy.dart';
import 'strategies/cento_strategy.dart';
import 'strategies/kg_strategy.dart';
import 'strategies/litro_strategy.dart';
import 'strategies/caixa_strategy.dart';
import 'strategies/bandeja_strategy.dart';

/// Fábrica de estratégias de precificação.
///
/// Seleciona a implementação correta de [PricingStrategy] com base no
/// [UnidadeVenda] do produto. Novas unidades podem ser adicionadas aqui
/// sem alterar o [PricingEngine].
class PricingStrategyFactory {
  const PricingStrategyFactory();
  /// Retorna a estratégia adequada para a [unidadeVenda] informada.
  /// Caso a unidade não seja reconhecida, usa [UnidadeStrategy] como fallback.
  PricingStrategy getStrategy(UnidadeVenda unidadeVenda) {
    switch (unidadeVenda) {
      case UnidadeVenda.un:
        return UnidadeStrategy();
      case UnidadeVenda.cento:
        return CentoStrategy();
      case UnidadeVenda.kg:
        return KgStrategy();
      case UnidadeVenda.l:
        return LitroStrategy();
      case UnidadeVenda.caixa:
        return CaixaStrategy();
      case UnidadeVenda.bandeja:
        return BandejaStrategy();
    }
  }
}
