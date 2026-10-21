import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

void main() {
  group('WhatsApp Template Engine - Motor de Condicionais & Tags Inteligentes', () {
    test('Cenário 1: Se PIX, exibe chave PIX; se Cartão/Dinheiro, não exibe chave nem linhas sobrando', () {
      const template = '''
💰 *Total: {total}*
💳 *Pagamento: {forma_pagamento}*

{se forma_pagamento == PIX}
🔑 *Chave PIX:* {chave_pix}
{/se}

📦 *Tipo:* {tipo_pedido}''';

      // 1. Caso PIX
      final varsPix = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana Souza',
        nomeEmpresa: 'Pizzaria do Bairro',
        total: 45.0,
        formaPagamento: 'PIX Mercado Pago',
        tipoPedido: 'Entrega',
        chavePix: '07389215640',
      );

      final resultadoPix = WhatsAppService.interpolarTemplate(template, varsPix);
      expect(resultadoPix, contains('🔑 *Chave PIX:* 07389215640'));
      expect(resultadoPix, contains('💳 *Pagamento: PIX Mercado Pago*'));

      // 2. Caso Cartão
      final varsCartao = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana Souza',
        nomeEmpresa: 'Pizzaria do Bairro',
        total: 45.0,
        formaPagamento: 'Cartão de Crédito',
        tipoPedido: 'Entrega',
        chavePix: '07389215640',
      );

      final resultadoCartao = WhatsAppService.interpolarTemplate(template, varsCartao);
      expect(resultadoCartao, isNot(contains('Chave PIX')));
      expect(resultadoCartao, isNot(contains('07389215640')));
      expect(resultadoCartao, contains('💳 *Pagamento: Cartão de Crédito*'));
      expect(resultadoCartao, contains('📦 *Tipo:* Entrega'));

      // 3. Caso Dinheiro
      final varsDinheiro = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana Souza',
        nomeEmpresa: 'Pizzaria do Bairro',
        total: 45.0,
        formaPagamento: 'Dinheiro',
        tipoPedido: 'Entrega',
        chavePix: '07389215640',
      );

      final resultadoDinheiro = WhatsAppService.interpolarTemplate(template, varsDinheiro);
      expect(resultadoDinheiro, isNot(contains('Chave PIX')));
      expect(resultadoDinheiro, contains('💳 *Pagamento: Dinheiro*'));
    });

    test('Cenário 2: PIX Pendente vs PIX já Confirmado / Pago', () {
      const template = '''
💳 *Pagamento:* {forma_pagamento}

{se forma_pagamento == PIX && status_pagamento == Pendente}
💳 *Pagamento pendente*
🔑 *Chave PIX:* {chave_pix}
📋 *Copia e Cola:*
{chave_pix_copia_cola}
{/se}

📦 *Tipo:* {tipo_pedido}''';

      // PIX Pendente
      final varsPendente = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        formaPagamento: 'PIX',
        statusPagamento: 'Pendente',
        chavePix: '07389215640',
        chavePixCopiaCola: '00020126...BCB',
        tipoPedido: 'Entrega',
      );

      final resultadoPendente = WhatsAppService.interpolarTemplate(template, varsPendente);
      expect(resultadoPendente, contains('💳 *Pagamento pendente*'));
      expect(resultadoPendente, contains('🔑 *Chave PIX:* 07389215640'));
      expect(resultadoPendente, contains('00020126...BCB'));

      // PIX já Confirmado / Pago
      final varsConfirmado = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        formaPagamento: 'PIX',
        statusPagamento: 'Confirmado',
        chavePix: '07389215640',
        chavePixCopiaCola: '00020126...BCB',
        tipoPedido: 'Entrega',
      );

      final resultadoConfirmado = WhatsAppService.interpolarTemplate(template, varsConfirmado);
      expect(resultadoConfirmado, isNot(contains('Pagamento pendente')));
      expect(resultadoConfirmado, isNot(contains('00020126...BCB')));
      expect(resultadoConfirmado, contains('💳 *Pagamento:* PIX'));
      expect(resultadoConfirmado, contains('📦 *Tipo:* Entrega'));
    });

    test('Cenário 3: Entrega vs Retirada com {senao}', () {
      const template = '''
{se tipo_pedido == Entrega}
📍 *Endereço:* {endereco}
{senao}
🏢 *Retirada:* {endereco_empresa}
{/se}''';

      // Entrega
      final varsEntrega = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        tipoPedido: 'Entrega (Delivery)',
        endereco: 'Rua das Flores, 120',
        enderecoEmpresa: 'Av. Brasil, 500',
      );

      final resultadoEntrega = WhatsAppService.interpolarTemplate(template, varsEntrega);
      expect(resultadoEntrega, contains('📍 *Endereço:* Rua das Flores, 120'));
      expect(resultadoEntrega, isNot(contains('Retirada')));

      // Retirada
      final varsRetirada = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        tipoPedido: 'Retirada no Balcão',
        endereco: 'Rua das Flores, 120',
        enderecoEmpresa: 'Av. Brasil, 500',
      );

      final resultadoRetirada = WhatsAppService.interpolarTemplate(template, varsRetirada);
      expect(resultadoRetirada, contains('🏢 *Retirada:* Av. Brasil, 500'));
      expect(resultadoRetirada, isNot(contains('📍 *Endereço:*')));
    });

    test('Cenário 4: Uso direto da tag inteligente {bloco_pix}', () {
      const template = '''
💰 *Total: {total}*
💳 *Pagamento: {forma_pagamento}*

{bloco_pix}

📦 *Tipo:* {tipo_pedido}''';

      // PIX
      final varsPix = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        total: 50.0,
        formaPagamento: 'PIX',
        chavePix: 'minhachave@pix.com',
        tipoPedido: 'Entrega',
      );

      final resPix = WhatsAppService.interpolarTemplate(template, varsPix);
      expect(resPix, contains('🔑 *Chave PIX:* minhachave@pix.com'));

      // Cartão
      final varsCartao = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        total: 50.0,
        formaPagamento: 'Cartão de Débito',
        chavePix: 'minhachave@pix.com',
        tipoPedido: 'Entrega',
      );

      final resCartao = WhatsAppService.interpolarTemplate(template, varsCartao);
      expect(resCartao, isNot(contains('Chave PIX')));
      expect(resCartao, isNot(contains('minhachave@pix.com')));
    });

    test('Cenário 5: Formatos configuráveis do PIX ({bloco_pix} com chave, copia e cola ou ambos)', () {
      const template = '''
💳 *Pagamento:* {forma_pagamento}
{bloco_pix}''';

      // 1. Formato 'chave'
      final varsChave = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        formaPagamento: 'PIX',
        chavePix: 'chave_123',
        chavePixCopiaCola: '00020126...COPIA_COLA',
        formatoPix: 'chave',
      );
      final resChave = WhatsAppService.interpolarTemplate(template, varsChave);
      expect(resChave, contains('🔑 *Chave PIX:* chave_123'));
      expect(resChave, isNot(contains('COPIA_COLA')));

      // 2. Formato 'copia_cola'
      final varsCopiaCola = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        formaPagamento: 'PIX',
        chavePix: 'chave_123',
        chavePixCopiaCola: '00020126...COPIA_COLA',
        formatoPix: 'copia_cola',
      );
      final resCopiaCola = WhatsAppService.interpolarTemplate(template, varsCopiaCola);
      expect(resCopiaCola, contains('📋 *PIX Copia e Cola:*'));
      expect(resCopiaCola, contains('00020126...COPIA_COLA'));
      expect(resCopiaCola, isNot(contains('🔑 *Chave PIX:*')));

      // 3. Formato 'bloco_completo'
      final varsCompleto = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Mariana',
        nomeEmpresa: 'Pizzaria',
        formaPagamento: 'PIX',
        chavePix: 'chave_123',
        chavePixCopiaCola: '00020126...COPIA_COLA',
        formatoPix: 'bloco_completo',
      );
      final resCompleto = WhatsAppService.interpolarTemplate(template, varsCompleto);
      expect(resCompleto, contains('🔑 *Chave PIX:* chave_123'));
      expect(resCompleto, contains('📋 *Copia e Cola:*'));
      expect(resCompleto, contains('00020126...COPIA_COLA'));
    });

    test('Cenário 6: WhatsAppPdvConfig e template oficial comprovante', () {
      const configPadrao = WhatsAppPdvConfig();
      expect(configPadrao.templateId, equals('comprovante'));
      expect(configPadrao.enviarPix2MsgPadrao, isFalse);
      expect(configPadrao.formatoPixPadrao, equals('bloco_completo'));
      expect(configPadrao.enviarWhatsAppPadrao, isTrue);

      final json = configPadrao.toJson();
      final restaurada = WhatsAppPdvConfig.fromJson(json);
      expect(restaurada.templateId, equals('comprovante'));
      expect(restaurada.enviarPix2MsgPadrao, isFalse);

      final padroes = WhatsAppService.getTemplatesPadrao();
      final comprovante = padroes.firstWhere((t) => t.id == 'comprovante');
      expect(comprovante.titulo, contains('Comprovante'));
      expect(comprovante.conteudo, contains('{bloco_pix}'));
      expect(comprovante.conteudo, contains('{bloco_endereco}'));
    });

    test('Cenário 7: Formatação inteligente de endereço JSON, quantidade 50.0 -> 50x e templates aprovado/cancelado', () {
      // 1. Decodificação de endereço JSON
      const rawJson = '{"cep":"37.557-044","logradouro":"Rua Professora Nádia Prancic Bento","numero":"398","bairro":"Francisca Augusta Rios","cidade":"Pouso Alegre","uf":"MG","complemento":"","referencia":"Casa","formatado":"Rua Professora Nádia Prancic Bento, 398 - Francisca Augusta Rios - Pouso Alegre - MG - CEP: 37.557-044"}';
      final formatado = WhatsAppService.formatarEnderecoCliente(rawJson);
      expect(formatado, equals('Rua Professora Nádia Prancic Bento, 398 - Francisca Augusta Rios - Pouso Alegre - MG - CEP: 37.557-044 (Ref: Casa)'));

      // 2. Formatação de quantidade sem decimal supérfluo
      expect(WhatsAppService.formatarQuantidadeDisplay(50.0), equals('50'));
      expect(WhatsAppService.formatarQuantidadeDisplay(1.5), equals('1,5'));
      expect(WhatsAppService.formatarQuantidadeDisplay('50.0'), equals('50'));

      final itensFormatados = WhatsAppService.formatarItensParaWhatsApp([
        {'nome': 'Mini Coxinha', 'qtd': 50.0, 'total': 62.50},
      ]);
      expect(itensFormatados, contains('▪ 50x *Mini Coxinha* - R\$ 62,50'));

      // 3. Interpolação com endereço JSON e motivo de cancelamento
      final varsCancelado = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Eliezer Severino de Souza',
        nomeEmpresa: 'Delivery do Eli',
        numeroPedido: '139',
        observacoes: 'Cliente solicitou cancelamento por motivo pessoal',
      );
      final padroes = WhatsAppService.getTemplatesPadrao(nomeEmpresa: 'Delivery do Eli');
      final templateCancelado = padroes.firstWhere((t) => t.id == 'pedido_cancelado');
      final msgCancelado = WhatsAppService.interpolarTemplate(templateCancelado.conteudo, varsCancelado);
      expect(msgCancelado, contains('AVISO — PEDIDO #139 CANCELADO'));
      expect(msgCancelado, contains('📝 *Motivo / Observações:* Cliente solicitou cancelamento por motivo pessoal'));

      // 4. Template oficial de pedido aprovado
      final templateAprovado = padroes.firstWhere((t) => t.id == 'pedido_aprovado');
      expect(templateAprovado.evento, equals('pedido_aprovado'));
      final varsAprovado = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: 'Eliezer',
        nomeEmpresa: 'Delivery do Eli',
        numeroPedido: '140',
        itens: [
          {'nome': 'Mini Coxinha', 'qtd': 50.0, 'total': 62.50},
        ],
        total: 62.50,
        subtotal: 62.50,
        formaPagamento: 'Pix Mercado Pago',
        tipoPedido: 'Entrega',
        endereco: rawJson,
      );
      final msgAprovado = WhatsAppService.interpolarTemplate(templateAprovado.conteudo, varsAprovado);
      expect(msgAprovado, contains('PEDIDO #140 APROVADO!'));
      expect(msgAprovado, contains('▪ 50x *Mini Coxinha*'));
      expect(msgAprovado, contains('📍 *Endereço de Entrega:* Rua Professora Nádia Prancic Bento, 398'));
      expect(msgAprovado, isNot(contains('{"cep"')));
    });
  });
}

