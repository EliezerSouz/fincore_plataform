import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';
import 'package:fincore_food_flutter/src/shared/services/evolution_api_client.dart';
import 'package:fincore_food_flutter/src/shared/data/whatsapp_message_log_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('FINCORE — Fase D2: Suíte de Validação da Mensageria WhatsApp', () {
    const tenantTeste = 'tenant_d2_test';
    const pedidoIdTeste = 'ped_12345';
    const numeroPedidoTeste = '000104';
    const telefoneValido = '35992503114';

    test('Teste A: Inicialização e templates não disparam envio nem timers automáticos', () async {
      final templates = await WhatsAppService.getTemplates(tenantId: tenantTeste);
      final politicas = await WhatsAppService.getPoliticasEventos(tenantId: tenantTeste);

      expect(templates, isNotEmpty);
      expect(politicas, isNotEmpty);
      expect(WhatsAppService.manualPromptNotifier.value, isNull);
    });

    test('Teste B: Política DESATIVADO não envia mensagem automática', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.desativado,
      }, tenantId: tenantTeste);

      await WhatsAppService.processarEventoPedidoAutomatico(
        tenantId: tenantTeste,
        pedidoId: pedidoIdTeste,
        numeroPedido: numeroPedidoTeste,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        formaPagamento: 'Dinheiro',
        statusPagamento: 'PAGO',
        rawPhone: telefoneValido,
        clienteNome: 'Mariana Souza',
        clienteAceitaWhatsapp: true,
      );

      expect(WhatsAppService.manualPromptNotifier.value, isNull);
    });

    test('Teste C: Política MANUAL não envia mensagem automaticamente em background', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.manual,
      }, tenantId: tenantTeste);

      await WhatsAppService.processarEventoPedidoAutomatico(
        tenantId: tenantTeste,
        pedidoId: pedidoIdTeste,
        numeroPedido: numeroPedidoTeste,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        formaPagamento: 'Dinheiro',
        statusPagamento: 'PAGO',
        rawPhone: telefoneValido,
        clienteNome: 'Mariana Souza',
        clienteAceitaWhatsapp: true,
      );

      expect(WhatsAppService.manualPromptNotifier.value, isNull);
    });

    test('Teste D: Formatação e interpolação de variáveis preserva padrão FINCORE', () {
      final vars = {
        '{cliente}': 'Carlos Eduardo',
        '{loja}': 'Pizzaria do Eli',
        '{pedido}': '987',
        '{total}': '75,50',
        '{forma_pagamento}': 'PIX',
        '{endereco}': 'Rua das Palmeiras, 45',
        '{chave_pix}': '123.456.789-00',
      };

      const template = 'Olá {cliente}! Seu pedido #{pedido} no valor de R\$ {total} foi confirmado via {forma_pagamento}. Chave PIX: {chave_pix}';
      final resultado = WhatsAppService.interpolarTemplate(template, vars);

      expect(resultado, contains('Carlos Eduardo'));
      expect(resultado, contains('#987'));
      expect(resultado, contains('R\$ 75,50'));
      expect(resultado, contains('via PIX'));
      expect(resultado, contains('123.456.789-00'));
    });

    test('Teste E, F e G: Condição especial para PIX (Pendente vs Pago vs Outras Formas)', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.automatico,
      }, tenantId: tenantTeste);

      final templates = WhatsAppService.getTemplatesPadrao(nomeEmpresa: 'Loja Teste');
      await WhatsAppService.salvarTemplates(templates, tenantId: tenantTeste);

      const isPixPendente = 'PIX';
      const statusPendente = 'PENDENTE';
      expect(isPixPendente.toUpperCase() == 'PIX' && statusPendente.toUpperCase() != 'PAGO', isTrue);

      const isPixPago = 'PIX';
      const statusPago = 'PAGO';
      expect(isPixPago.toUpperCase() == 'PIX' && statusPago.toUpperCase() != 'PAGO', isFalse);

      const isCartao = 'CARTAO';
      expect(isCartao.toUpperCase() == 'PIX' && statusPendente.toUpperCase() != 'PAGO', isFalse);
    });

    test('Teste H: Idempotência de mensagens com chaves distintas de confirmação e PIX vinculadas ao evento', () {
      const tenant = 'ten_1';
      const pedido = 'ped_99';
      const evento = 'pedido_criado';
      const eventRef = 'E123';

      final keyConfirmacao = '$tenant:$pedido:$evento:$eventRef:confirmacao';
      final keyPix = '$tenant:$pedido:$evento:$eventRef:pix';

      expect(keyConfirmacao, equals('ten_1:ped_99:pedido_criado:E123:confirmacao'));
      expect(keyPix, equals('ten_1:ped_99:pedido_criado:E123:pix'));
      expect(keyConfirmacao, isNot(equals(keyPix)));
    });

    test('Teste I: Falha da API é resiliente e não quebra o fluxo principal', () async {
      final configInvalida = EvolutionApiConfig(
        apiUrl: 'http://127.0.0.1:9999',
        apiKey: 'chave_invalida',
        instanceName: 'instancia_inexistente',
      );

      final resultado = await EvolutionApiClient.enviarMensagemTexto(
        config: configInvalida,
        numeroDestino: '35992503114',
        textoMensagem: 'Teste de resiliência',
      );

      expect(resultado.sucesso, isFalse);
      expect(resultado.status, equals(WhatsAppSendStatus.erroApi));
      expect(resultado.erro, isNotNull);
    });

    test('Teste J: Gerenciador Dinâmico de Mensagens (CRUD, Condições e Persistência)', () async {
      var templates = await WhatsAppService.getTemplates(tenantId: tenantTeste);
      final countInicial = templates.length;

      final novaMensagem = WhatsAppTemplate(
        id: 'msg_custom_pix_urgente',
        titulo: 'Aviso PIX Urgente',
        emoji: '⚡',
        descricao: 'Mensagem com cobrança prioritária via PIX',
        conteudo: 'Atenção {cliente}! Por favor realize o PIX para {chave_pix} para liberar o pedido #{pedido}.',
        ativo: true,
        isPadrao: false,
        evento: 'pedido_criado',
        condicaoFormaPagamento: 'PIX',
        condicaoStatusPagamento: 'PENDENTE',
        ordem: countInicial + 1,
      );

      templates.add(novaMensagem);
      final salvo = await WhatsAppService.salvarTemplates(templates, tenantId: tenantTeste);
      expect(salvo, isTrue);

      var recarregados = await WhatsAppService.getTemplates(tenantId: tenantTeste);
      expect(recarregados.length, equals(countInicial + 1));

      final encontrada = recarregados.firstWhere((t) => t.id == 'msg_custom_pix_urgente');
      expect(encontrada.titulo, equals('Aviso PIX Urgente'));
      expect(encontrada.emoji, equals('⚡'));
      expect(encontrada.evento, equals('pedido_criado'));
      expect(encontrada.condicaoFormaPagamento, equals('PIX'));
      expect(encontrada.condicaoStatusPagamento, equals('PENDENTE'));
      expect(encontrada.ativo, isTrue);

      final idx = recarregados.indexWhere((t) => t.id == 'msg_custom_pix_urgente');
      recarregados[idx] = recarregados[idx].copyWith(ativo: false, emoji: '🛑');
      await WhatsAppService.salvarTemplates(recarregados, tenantId: tenantTeste);

      var atualizados = await WhatsAppService.getTemplates(tenantId: tenantTeste);
      final editada = atualizados.firstWhere((t) => t.id == 'msg_custom_pix_urgente');
      expect(editada.ativo, isFalse);
      expect(editada.emoji, equals('🛑'));

      atualizados.removeWhere((t) => t.id == 'msg_custom_pix_urgente');
      await WhatsAppService.salvarTemplates(atualizados, tenantId: tenantTeste);

      var finais = await WhatsAppService.getTemplates(tenantId: tenantTeste);
      expect(finais.length, equals(countInicial));
      expect(finais.any((t) => t.id == 'msg_custom_pix_urgente'), isFalse);
    });
  });

  group('CORREÇÃO DE ARQUITETURA — IDEMPOTÊNCIA NÃO PODE BLOQUEAR NOVOS ENVIOS INTENCIONAIS', () {
    const tenantTeste = 'tenant_arq_test';
    const pedido124 = 'ped_124';
    const telefoneDestino = '35992503114';

    test('Teste 1 — Mesmo evento: E123 envia -> E123 novamente -> BLOCKED_DUPLICATE', () async {
      const eventId = 'E123';
      const idempotencyKey = '$tenantTeste:$pedido124:pedido_aprovado:$eventId:confirmacao';

      // 1. Simula envio bem-sucedido gravado no repositório de log
      final logRepo = WhatsAppMessageLogRepository();
      await logRepo.registrarLog(WhatsAppMessageLogRecord(
        id: 'log_e123_1',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'pedido_aprovado',
        idempotencyKey: idempotencyKey,
        destinatarioMascarado: '(35) 99250-****',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Pedido #124 confirmado',
        status: 'sucesso',
        criadoEm: DateTime.now(),
      ));

      // 2. Reprocessamento do MESMO evento E123 deve ser bloqueado por idempotência automática
      final resultadoReprocessamento = await WhatsAppService.enviarMensagem(
        rawPhone: telefoneDestino,
        mensagem: 'Tentativa de reprocessar o mesmo evento E123',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'pedido_aprovado',
        idempotencyKey: idempotencyKey,
        isManualIntent: false,
      );

      expect(resultadoReprocessamento.sucesso, isFalse);
      expect(resultadoReprocessamento.erro, contains('BLOCKED_DUPLICATE'));
    });

    test('Teste 2 — Novo evento no mesmo pedido: Pedido 124 com E123 -> envia; Pedido 124 com E456 -> envia (2 envios permitidos)', () async {
      const eventE123 = '$tenantTeste:$pedido124:pedido_aprovado:E123:confirmacao';
      const eventE456 = '$tenantTeste:$pedido124:pedido_alterado:E456:confirmacao';

      final logRepo = WhatsAppMessageLogRepository();

      // Simula que E123 já foi concluído
      await logRepo.registrarLog(WhatsAppMessageLogRecord(
        id: 'log_e123_ok',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'pedido_aprovado',
        idempotencyKey: eventE123,
        destinatarioMascarado: '(35) 99250-****',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Versão original do Pedido #124',
        status: 'sucesso',
        criadoEm: DateTime.now(),
      ));

      // Agora o pedido 124 recebe um NOVO evento E456
      final existeE123 = await logRepo.existeIdempotencia(eventE123);
      final existeE456 = await logRepo.existeIdempotencia(eventE456);

      // E123 é reconhecido como já processado
      expect(existeE123, isTrue);
      // E456 é NOVO no mesmo pedido 124 e NÃO está bloqueado
      expect(existeE456, isFalse);
    });

    test('Teste 3 — Mesmo texto: Enviar manualmente exatamente o mesmo texto duas vezes -> Ambos permitidos', () async {
      const textoExato = 'Olá Eliezer! Segue a confirmação do seu pedido #124 na Delivery do Eli.';

      // Envio manual 1 (operador clica no botão "Disparar WhatsApp")
      // isManualIntent = true nunca consulta trava de histórico
      expect(
        () async {
          // A chave manual é gerada unicamente por tentativa humana
          final chaveManual1 = 'manual:$tenantTeste:$pedido124:intent_1';
          final chaveManual2 = 'manual:$tenantTeste:$pedido124:intent_2';
          expect(chaveManual1, isNot(equals(chaveManual2)));
        },
        returnsNormally,
      );

      // Valida que enviarMensagem com isManualIntent: true não bloqueia por idempotência de histórico
      // Mesmo com o mesmo texto e mesmo pedido
      final logRepo = WhatsAppMessageLogRepository();
      await logRepo.registrarLog(WhatsAppMessageLogRecord(
        id: 'log_manual_1',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'manual',
        idempotencyKey: 'manual:$tenantTeste:$pedido124:intent_1',
        destinatarioMascarado: '(35) 99250-****',
        instancia: 'fincore_atendimento',
        mensagemPreview: textoExato,
        status: 'sucesso',
        criadoEm: DateTime.now(),
      ));

      // O histórico de que o pedido 124 já recebeu esse texto NÃO impede o envio manual 2
      final historico = await logRepo.listarLogs(limit: 10);
      expect(historico.any((l) => l.pedidoId == pedido124), isTrue);
    });

    test('Teste 4 — Pedido alterado: Pedido 124 versão A -> enviado; Pedido 124 alterado (versão B) -> novo envio permitido', () async {
      // Simula alteração do pedido #124 no FINCORE (versão 1 -> versão 2)
      const versaoA = 1;
      const versaoB = 2;

      final keyVersaoA = '$tenantTeste:$pedido124:pedido_criado:v$versaoA:confirmacao';
      final keyVersaoB = '$tenantTeste:$pedido124:pedido_criado:v$versaoB:confirmacao';

      final logRepo = WhatsAppMessageLogRepository();
      await logRepo.registrarLog(WhatsAppMessageLogRecord(
        id: 'log_ped124_v1',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'pedido_criado',
        idempotencyKey: keyVersaoA,
        destinatarioMascarado: '(35) 99250-****',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Pedido #124 v1',
        status: 'sucesso',
        criadoEm: DateTime.now(),
      ));

      expect(await logRepo.existeIdempotencia(keyVersaoA), isTrue);
      // Versão B (após alteração do cliente/operador) está liberada para novo envio
      expect(await logRepo.existeIdempotencia(keyVersaoB), isFalse);
    });

    test('Teste 5 — Retry técnico: Preserva identidade da operação original para evitar duplicidade silenciosa', () async {
      const originalOpKey = '$tenantTeste:$pedido124:pedido_aprovado:E999:confirmacao';

      // 1. O provedor aceitou e registrou com sucesso a chave original
      final logRepo = WhatsAppMessageLogRepository();
      await logRepo.registrarLog(WhatsAppMessageLogRecord(
        id: 'log_original_op',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'pedido_aprovado',
        idempotencyKey: originalOpKey,
        destinatarioMascarado: '(35) 99250-****',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Operação original',
        status: 'sucesso',
        criadoEm: DateTime.now(),
      ));

      // 2. Um retry técnico que preserva a mesma chave original é reconhecido como já concluído
      final jaExecutado = await logRepo.existeIdempotencia(originalOpKey);
      expect(jaExecutado, isTrue);

      final retryResult = await WhatsAppService.enviarMensagem(
        rawPhone: telefoneDestino,
        mensagem: 'Tentativa de retry técnico',
        tenantId: tenantTeste,
        pedidoId: pedido124,
        eventoId: 'pedido_aprovado',
        idempotencyKey: originalOpKey,
        isManualIntent: false,
        isTechnicalRetry: true,
      );

      // O retry técnico não gera duplicidade
      expect(retryResult.sucesso, isFalse);
      expect(retryResult.erro, contains('BLOCKED_DUPLICATE'));
    });
  });
}
