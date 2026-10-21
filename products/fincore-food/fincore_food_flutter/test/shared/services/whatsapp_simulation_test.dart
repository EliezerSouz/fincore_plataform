import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String kTenantId = 'tenant_piloto_001';
  const String kPedidoId = 'ped_abc_123';
  const String kNumeroPedido = '1042';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WhatsAppService.limparHistoricoSimulacoes();
  });

  group('Fase C — WhatsAppService Modo Simulação / Mock', () {
    test('Padrão de fábrica: Todas as políticas de eventos iniciam como DESATIVADAS', () async {
      final politicas = await WhatsAppService.getPoliticasEventos(tenantId: kTenantId);

      expect(politicas[WhatsAppService.kEventoPedidoCriadoPdv], equals(WhatsAppEventPolicy.desativado));
      expect(politicas[WhatsAppService.kEventoPedidoAprovadoWeb], equals(WhatsAppEventPolicy.desativado));
      expect(politicas[WhatsAppService.kEventoPedidoPronto], equals(WhatsAppEventPolicy.desativado));
      expect(politicas[WhatsAppService.kEventoPedidoSaiuEntrega], equals(WhatsAppEventPolicy.desativado));
      expect(politicas[WhatsAppService.kEventoPedidoCancelado], equals(WhatsAppEventPolicy.desativado));
    });

    test('Persistência isolada no SharedPreferences por tenant', () async {
      final mapaParaSalvar = {
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.manual,
        WhatsAppService.kEventoPedidoSaiuEntrega: WhatsAppEventPolicy.automatico,
      };

      final salvo = await WhatsAppService.salvarPoliticasEventos(mapaParaSalvar, tenantId: kTenantId);
      expect(salvo, isTrue);

      final lido = await WhatsAppService.getPoliticasEventos(tenantId: kTenantId);
      expect(lido[WhatsAppService.kEventoPedidoCriadoPdv], equals(WhatsAppEventPolicy.manual));
      expect(lido[WhatsAppService.kEventoPedidoSaiuEntrega], equals(WhatsAppEventPolicy.automatico));
      expect(lido[WhatsAppService.kEventoPedidoCancelado], equals(WhatsAppEventPolicy.desativado));

      // Outro tenant mantém padrão de fábrica
      final lidoOutroTenant = await WhatsAppService.getPoliticasEventos(tenantId: 'tenant_outro_999');
      expect(lidoOutroTenant[WhatsAppService.kEventoPedidoCriadoPdv], equals(WhatsAppEventPolicy.desativado));
    });

    test('Bloqueio quando a trava global da empresa estiver desligada (BLOCKED_GLOBAL_DISABLED)', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: false, // Trava Global desligada
        clienteAceitaWhatsapp: true,
        rawPhone: '11999998888',
        clienteNome: 'João Silva',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_GLOBAL_DISABLED'));
      expect(decisao.isSimulacao, isTrue);
    });

    test('Bloqueio quando o evento estiver com política desativada (BLOCKED_EVENT_DISABLED)', () async {
      // Política desativada por padrão
      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11999998888',
        clienteNome: 'João Silva',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_EVENT_DISABLED'));
    });

    test('Bloqueio quando cliente não consentiu com WhatsApp (BLOCKED_NO_CONSENT)', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: false, // Consentimento não concedido
        rawPhone: '11999998888',
        clienteNome: 'Maria Santos',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_NO_CONSENT'));
    });

    test('Bloqueio quando telefone for inválido ou ausente (BLOCKED_INVALID_PHONE)', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '1234', // Telefone curto/inválido
        clienteNome: 'Carlos Rocha',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_INVALID_PHONE'));
    });

    test('Bloqueio por incompatibilidade logística: Saiu para Entrega em pedido de Balcão/Retirada', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoSaiuEntrega: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoSaiuEntrega,
        tipoLogistica: 'Balcão', // Incompatível com saiu para entrega
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11999998888',
        clienteNome: 'Luciana Lima',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_INVALID_LOGISTICS'));
    });

    test('Bloqueio por incompatibilidade logística: Pedido Pronto no Balcão para pedido de Entrega', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoPronto: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoPronto,
        tipoLogistica: 'Entrega', // Incompatível com pronto no balcão
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11999998888',
        clienteNome: 'Felipe Mendes',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_INVALID_LOGISTICS'));
    });

    test('Autorização em Modo Manual: requer confirmação e gera preview do template', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.manual,
      }, tenantId: kTenantId);

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        numeroPedido: kNumeroPedido,
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11999998888',
        clienteNome: 'Renata Dias',
      );

      expect(decisao.autorizado, isTrue);
      expect(decisao.codigoDecisao, equals('AUTHORIZED_MANUAL'));
      expect(decisao.requerConfirmacaoManual, isTrue);
      expect(decisao.isSimulacao, isTrue);
      expect(decisao.previewTexto, isNotNull);
      expect(decisao.previewTexto!.isNotEmpty, isTrue);
    });

    test('Idempotência Local: Rejeita disparo repetido para o mesmo pedido e evento (BLOCKED_DUPLICATE)', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoAprovadoWeb: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      // 1ª Execução
      final d1 = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: 'ped_duplo_99',
        numeroPedido: '99',
        eventoId: WhatsAppService.kEventoPedidoAprovadoWeb,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11988887777',
        clienteNome: 'Ana Paula',
      );
      expect(d1.autorizado, isTrue);
      expect(d1.codigoDecisao, equals('AUTHORIZED_AUTO_SIMULATED'));

      // 2ª Execução idêntica (clique duplo ou re-render)
      final d2 = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: 'ped_duplo_99',
        numeroPedido: '99',
        eventoId: WhatsAppService.kEventoPedidoAprovadoWeb,
        tipoLogistica: 'Entrega',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11988887777',
        clienteNome: 'Ana Paula',
      );

      expect(d2.autorizado, isFalse);
      expect(d2.codigoDecisao, equals('BLOCKED_DUPLICATE'));
      expect(d2.isDuplicado, isTrue);
    });

    test('Histórico em memória e auditoria visual registram todas as tentativas', () async {
      expect(WhatsAppService.getHistoricoSimulacoes().length, equals(0));

      await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: 'ped_hist_1',
        numeroPedido: '1',
        eventoId: WhatsAppService.kEventoPedidoCancelado,
        tipoLogistica: 'Balcão',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '11999998888',
        clienteNome: 'Cliente 1',
      );

      final historico = WhatsAppService.getHistoricoSimulacoes();
      expect(historico.length, equals(1));
      expect(historico.first.eventoId, equals(WhatsAppService.kEventoPedidoCancelado));
    });

    test('Template oficial pedido_cancelado e mapeamento dinâmico de modelo por evento', () async {
      // 1. Verifica se getTemplatesPadrao contém o template pedido_cancelado
      final templatesPadrao = WhatsAppService.getTemplatesPadrao(nomeEmpresa: 'Pizzaria Teste');
      final canceladoPadrao = templatesPadrao.firstWhere((t) => t.id == 'pedido_cancelado');
      expect(canceladoPadrao, isNotNull);
      expect(canceladoPadrao.evento, equals('pedido_cancelado'));
      expect(canceladoPadrao.emoji, equals('❌'));
      expect(canceladoPadrao.conteudo, contains('cancelado'));

      // 2. Verifica se salva e recupera templates mapeados por evento
      final mapaCustom = {
        WhatsAppService.kEventoPedidoCancelado: 'pedido_cancelado',
        WhatsAppService.kEventoPedidoPronto: 'pronto_retirada',
      };
      final okSalvar = await WhatsAppService.salvarTemplatesEventosConfigurados(mapaCustom, tenantId: kTenantId);
      expect(okSalvar, isTrue);

      final mapaRecuperado = await WhatsAppService.getTemplatesEventosConfigurados(tenantId: kTenantId);
      expect(mapaRecuperado[WhatsAppService.kEventoPedidoCancelado], equals('pedido_cancelado'));
      expect(mapaRecuperado[WhatsAppService.kEventoPedidoPronto], equals('pronto_retirada'));
    });
  });
}
