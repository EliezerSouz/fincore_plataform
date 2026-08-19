import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/services/commercial_pricing_engine.dart';

void main() {
  group('CommercialPricingEngine — Suíte de Testes Automatizados de Regras Comerciais', () {
    late PoliticaComercialModel salgadosPolicy;

    setUp(() {
      salgadosPolicy = const PoliticaComercialModel(
        id: 'policy_salgados_v1',
        nome: 'Mini Salgados Tradicionais',
        descricao: 'Faixas de preço acumuladas para Coxinha, Kibe, Risole e Bolinha',
        versao: 1,
        faixas: [
          FaixaPrecificacaoModel(id: 'f1', quantidadeMinima: 25, quantidadeMaxima: 25, precoUnitario: 1.50),
          FaixaPrecificacaoModel(id: 'f2', quantidadeMinima: 26, quantidadeMaxima: 49, precoUnitario: 1.45),
          FaixaPrecificacaoModel(id: 'f3', quantidadeMinima: 50, quantidadeMaxima: 99, precoUnitario: 1.40),
          FaixaPrecificacaoModel(id: 'f4', quantidadeMinima: 100, quantidadeMaxima: 9999, precoUnitario: 1.30),
        ],
        produtosParticipantesIds: {'coxinha_id', 'kibe_id', 'risole_id', 'bolinha_id'},
      );
    });

    test('Cálculo Lote de 25 Unidades Mistas (Faixa 25 un = R\$ 1,50/un)', () {
      final items = [
        const ItemCotacao(produtoId: 'coxinha_id', nomeProduto: 'Coxinha', quantidade: 10),
        const ItemCotacao(produtoId: 'kibe_id', nomeProduto: 'Kibe', quantidade: 5),
        const ItemCotacao(produtoId: 'risole_id', nomeProduto: 'Risole', quantidade: 5),
        const ItemCotacao(produtoId: 'bolinha_id', nomeProduto: 'Bolinha', quantidade: 5),
      ];

      final result = CommercialPricingEngine.instance.calculatePolicyQuote(
        policy: salgadosPolicy,
        items: items,
      );

      expect(result.quantidadeTotalGrupo, equals(25.0));
      expect(result.precoUnitarioAplicado, equals(1.50));
      expect(result.valorTotalGrupo, equals(37.50));
      expect(result.explicacao.passos.length, greaterThanOrEqualTo(5));
    });

    test('Cálculo Lote de 100 Unidades (Faixa 100+ un = R\$ 1,30/un)', () {
      final items = [
        const ItemCotacao(produtoId: 'coxinha_id', nomeProduto: 'Coxinha', quantidade: 50),
        const ItemCotacao(produtoId: 'kibe_id', nomeProduto: 'Kibe', quantidade: 50),
      ];

      final result = CommercialPricingEngine.instance.calculatePolicyQuote(
        policy: salgadosPolicy,
        items: items,
      );

      expect(result.quantidadeTotalGrupo, equals(100.0));
      expect(result.precoUnitarioAplicado, equals(1.30));
      expect(result.valorTotalGrupo, equals(130.0));
    });

    test('Cálculo com Perfil Cliente Revenda Atacado (10% Desconto Adicional)', () {
      final items = [
        const ItemCotacao(produtoId: 'coxinha_id', nomeProduto: 'Coxinha', quantidade: 100),
      ];

      final result = CommercialPricingEngine.instance.calculatePolicyQuote(
        policy: salgadosPolicy,
        items: items,
        perfilCliente: PerfilCliente.revendaAtacado,
      );

      // Preço Base R$ 1.30 * 0.90 = R$ 1.17
      expect(result.precoUnitarioAplicado, closeTo(1.17, 0.01));
      expect(result.valorTotalGrupo, closeTo(117.00, 0.01));
      expect(result.descontoAplicado, greaterThan(0));
    });

    test('Validador de Faixas — Detecção de Sobreposição e Brecha', () {
      const faixasComErro = [
        FaixaPrecificacaoModel(id: 'f1', quantidadeMinima: 25, quantidadeMaxima: 50, precoUnitario: 1.50),
        FaixaPrecificacaoModel(id: 'f2', quantidadeMinima: 50, quantidadeMaxima: 100, precoUnitario: 1.40), // Colisão no 50
      ];

      final alertas = CommercialPricingEngine.instance.validateFaixas(faixasComErro);
      expect(alertas.any((a) => a.isErro), isTrue);
    });
  });
}
