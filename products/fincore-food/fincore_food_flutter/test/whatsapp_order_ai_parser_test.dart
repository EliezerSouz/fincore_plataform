import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_order_ai_parser.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';

void main() {
  group('WhatsAppOrderAiParser - Testes Unitários de Extração e NLP', () {
    late WhatsAppOrderAiParser parser;
    late List<Produto> catalogoMock;

    setUp(() {
      parser = WhatsAppOrderAiParser();
      final now = DateTime.now();
      catalogoMock = [
        Produto(
          id: 'prod-1',
          tenantId: 'tenant-1',
          nome: 'Pizza Calabresa',
          categoriaId: 'cat-pizza',
          unidadeVenda: UnidadeVenda.un,
          statusComercial: ProductStatus.disponivel,
          tempoMedioMinutos: 25,
          controlaEstoque: false,
          ordemProducao: 1,
          ativo: true,
          metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'u1', updatedBy: 'u1'),
        ),
        Produto(
          id: 'prod-2',
          tenantId: 'tenant-1',
          nome: 'Coca-Cola 2L',
          categoriaId: 'cat-bebidas',
          unidadeVenda: UnidadeVenda.un,
          statusComercial: ProductStatus.disponivel,
          tempoMedioMinutos: 0,
          controlaEstoque: true,
          ordemProducao: 2,
          ativo: true,
          metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'u1', updatedBy: 'u1'),
        ),
        Produto(
          id: 'prod-3',
          tenantId: 'tenant-1',
          nome: 'Batata Frita com Queijo e Bacon',
          categoriaId: 'cat-porcoes',
          unidadeVenda: UnidadeVenda.un,
          statusComercial: ProductStatus.disponivel,
          tempoMedioMinutos: 15,
          controlaEstoque: true,
          ordemProducao: 3,
          ativo: true,
          metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'u1', updatedBy: 'u1'),
        ),
        Produto(
          id: 'prod-4',
          tenantId: 'tenant-1',
          nome: 'Marmita Tradicional M',
          categoriaId: 'cat-refeicoes',
          unidadeVenda: UnidadeVenda.un,
          statusComercial: ProductStatus.disponivel,
          tempoMedioMinutos: 10,
          controlaEstoque: true,
          ordemProducao: 4,
          ativo: true,
          metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'u1', updatedBy: 'u1'),
        ),
      ];
    });

    test('Deve extrair pedido estruturado de delivery com troco e cliente', () {
      const mensagem = '''
*NOVO PEDIDO WHATSAPP*
Cliente: Mariana Souza
Telefone: (11) 98765-4321
Endereço: Rua das Palmeiras, 1420 - Centro
Ref: Próximo à farmácia Pague Menos
Itens:
1x Pizza Calabresa (sem cebola)
2x Coca-Cola 2L
Forma de Pagamento: Dinheiro
Troco para 100 reais
''';

      final resultado = parser.parseLocal(mensagem, catalogoProdutos: catalogoMock);

      expect(resultado.clienteNome, 'Mariana Souza');
      expect(resultado.clienteTelefone, '(11) 98765-4321');
      expect(resultado.tipoLogistica, 'Entrega');
      expect(resultado.logradouro, 'Rua das Palmeiras');
      expect(resultado.numero, '1420');
      expect(resultado.bairro, 'Centro');
      expect(resultado.referencia, 'Próximo à farmácia Pague Menos');
      expect(resultado.formaPagamento, 'Dinheiro');
      expect(resultado.trocoParaCentavos, 10000); // R$ 100,00

      expect(resultado.itens.length, 2);

      final itemPizza = resultado.itens.firstWhere((i) => i.produtoMatched?.id == 'prod-1');
      expect(itemPizza.quantidade, 1.0);
      expect(itemPizza.observacoes, 'sem cebola');

      final itemRefri = resultado.itens.firstWhere((i) => i.produtoMatched?.id == 'prod-2');
      expect(itemRefri.quantidade, 2.0);
    });

    test('Deve detectar pedido para Retirada e pagamento PIX', () {
      const mensagem = '''
Oi boa tarde!
Vou retirar no balcão:
1x Marmita Tradicional M
Vou pagar no PIX
Meu nome é Carlos Silva
Whats 19999887766
''';

      final resultado = parser.parseLocal(mensagem, catalogoProdutos: catalogoMock);

      expect(resultado.tipoLogistica, 'Retirada');
      expect(resultado.formaPagamento, 'PIX');
      expect(resultado.clienteNome, 'Carlos Silva');
      expect(resultado.clienteTelefone, contains('99988-7766'));
      expect(resultado.itens.length, 1);
      expect(resultado.itens.first.produtoMatched?.id, 'prod-4');
    });

    test('Deve executar Fuzzy Matching para produtos com grafia aproximada', () {
      const mensagem = '''
Manda aí:
1 batata frita queijo e bacon
1 coca 2l
Rua Brasil 50
''';

      final resultado = parser.parseLocal(mensagem, catalogoProdutos: catalogoMock);

      expect(resultado.itens.length, 2);
      expect(resultado.itens.any((i) => i.produtoMatched?.id == 'prod-3'), isTrue);
      expect(resultado.itens.any((i) => i.produtoMatched?.id == 'prod-2'), isTrue);
    });

    test('Deve extrair quantidades no final da linha após dois pontos (formato salgados)', () {
      const mensagem = '''
_ coxinha: 90
_ bolinha de queijo : 100
_ bolinha de Calabresa : 60
_ risole de carne : 45
_ risole de pizza : 65
_ enroladinho de salsicha :35
_ cigarrete : 80
_ kibe : 70
''';

      final resultado = parser.parseLocal(mensagem, catalogoProdutos: catalogoMock);

      expect(resultado.itens.length, 8);
      expect(resultado.itens[0].nomeIdentificado.toLowerCase(), contains('coxinha'));
      expect(resultado.itens[0].quantidade, 90.0);

      expect(resultado.itens[1].nomeIdentificado.toLowerCase(), contains('bolinha de queijo'));
      expect(resultado.itens[1].quantidade, 100.0);

      expect(resultado.itens[2].quantidade, 60.0);
      expect(resultado.itens[3].quantidade, 45.0);
      expect(resultado.itens[4].quantidade, 65.0);
      expect(resultado.itens[5].quantidade, 35.0);
      expect(resultado.itens[6].quantidade, 80.0);
      expect(resultado.itens[7].quantidade, 70.0);
    });
  });
}
