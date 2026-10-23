import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_order_ai_parser.dart';
import 'package:fincore_food_flutter/src/shared/services/evolution_api_client.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';

void main() {
  group('WhatsApp Order AI Parser - Header & Timestamp Resilience', () {
    final parser = WhatsAppOrderAiParser();
    final catalogo = [
      Produto(
        id: 'p1',
        tenantId: 'tenant-1',
        nome: 'Mini Coxinha',
        categoriaId: 'c1',
        unidadeVenda: UnidadeVenda.un,
        statusComercial: ProductStatus.disponivel,
        tempoMedioMinutos: 10,
        controlaEstoque: false,
        ordemProducao: 1,
        ativo: true,
        metadata: SyncMetadata(version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: 'test', updatedBy: 'test'),
      ),
      Produto(
        id: 'p2',
        tenantId: 'tenant-1',
        nome: 'Bolinha de Queijo',
        categoriaId: 'c1',
        unidadeVenda: UnidadeVenda.un,
        statusComercial: ProductStatus.disponivel,
        tempoMedioMinutos: 10,
        controlaEstoque: false,
        ordemProducao: 2,
        ativo: true,
        metadata: SyncMetadata(version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: 'test', updatedBy: 'test'),
      ),
      Produto(
        id: 'p3',
        tenantId: 'tenant-1',
        nome: 'Kibe Frito',
        categoriaId: 'c1',
        unidadeVenda: UnidadeVenda.un,
        statusComercial: ProductStatus.disponivel,
        tempoMedioMinutos: 10,
        controlaEstoque: false,
        ordemProducao: 3,
        ativo: true,
        metadata: SyncMetadata(version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: 'test', updatedBy: 'test'),
      ),
    ];

    test('1. Deve interpretar formato Android/Web com data, hora e remetente', () {
      const msg = '''
[22/10/2026, 14:32:10] Lucas S&S: Oi bom dia!
Quero fazer um pedido para entrega:
100x Mini Coxinha
50 Bolinha de Queijo
Rua das Flores, 120 - Centro
Vou pagar no PIX
''';

      final res = parser.parseLocal(msg, catalogoProdutos: catalogo);

      expect(res.clienteNome, equals('Lucas S&S'));
      expect(res.tipoLogistica, equals('Entrega'));
      expect(res.logradouro, equals('Rua das Flores'));
      expect(res.numero, equals('120'));
      expect(res.bairro, equals('Centro'));
      expect(res.formaPagamento, equals('PIX'));
      expect(res.itens.length, equals(2));
      expect(res.itens[0].quantidade, equals(100.0));
      expect(res.itens[0].nomeIdentificado, equals('Mini Coxinha'));
      expect(res.itens[1].quantidade, equals(50.0));
      expect(res.itens[1].nomeIdentificado, equals('Bolinha de Queijo'));
    });

    test('2. Deve interpretar formato WhatsApp Web com traço e número de telefone no remetente', () {
      const msg = '''
22/10/2026, 14:32 - +55 19 98877-6655: Olá
Nome: Mariana Costa
30 Mini Coxinha
20 Kibe Frito
Retirada no balcão
''';

      final res = parser.parseLocal(msg, catalogoProdutos: catalogo);

      expect(res.clienteNome, equals('Mariana Costa'));
      expect(res.clienteTelefone, contains('98877-6655'));
      expect(res.tipoLogistica, equals('Retirada'));
      expect(res.itens.length, equals(2));
    });

    test('3. Deve suportar linhas soltas de timestamps entre mensagens', () {
      const msg = '''
Lucas
14:32
Quero pedir
50x Mini Coxinha
14:33
Troco para 100
''';

      final res = parser.parseLocal(msg, catalogoProdutos: catalogo);

      expect(res.itens.length, equals(1));
      expect(res.itens[0].quantidade, equals(50.0));
      expect(res.trocoParaCentavos, equals(10000));
      expect(res.formaPagamento, equals('Dinheiro'));
    });
  });

  group('Evolution API & WhatsApp Config - Link Preview Condicional', () {
    test('1. Configuração padrão deve ter enviarLinkPreview ativo', () {
      const config = EvolutionApiConfig(
        apiUrl: 'https://vps72051.publiccloud.com.br',
        apiKey: 'test-key',
        instanceName: 'test-inst',
      );

      expect(config.enviarLinkPreview, isTrue);

      final json = config.toJson();
      expect(json['enviarLinkPreview'], isTrue);

      final reloaded = EvolutionApiConfig.fromJson(json);
      expect(reloaded.enviarLinkPreview, isTrue);
    });

    test('2. WhatsAppPdvConfig deve serializar e desserializar enviarLinkPreview', () {
      const pdvCfg = WhatsAppPdvConfig(enviarLinkPreview: false);
      expect(pdvCfg.enviarLinkPreview, isFalse);

      final json = pdvCfg.toJson();
      expect(json['enviarLinkPreview'], isFalse);

      final reloaded = WhatsAppPdvConfig.fromJson(json);
      expect(reloaded.enviarLinkPreview, isFalse);
    });

    test('3. Verificação de link na mensagem: apenas mensagens com http/https devem ativar preview', () {
      const msgSemLink = '🧾 *COMPROVANTE DO PEDIDO #123*\nObrigado pela preferência!';
      const msgComLink = '🌐 Acompanhe seu pedido em: https://fincore.me/pedido/123';

      final bool contemLink1 = msgSemLink.contains(RegExp(r'https?:\/\/', caseSensitive: false));
      final bool contemLink2 = msgComLink.contains(RegExp(r'https?:\/\/', caseSensitive: false));

      expect(contemLink1, isFalse);
      expect(contemLink2, isTrue);
    });
  });
}
