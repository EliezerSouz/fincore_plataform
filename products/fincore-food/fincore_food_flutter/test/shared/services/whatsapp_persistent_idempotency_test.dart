import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FincoreDatabase db;
  const String kTenantId = 'tenant_idempotency_test';
  const String kPedidoId = 'ped_persistent_999';
  const String kEventoId = 'pedido_pronto';
  const String kIdempotencyKey = '$kTenantId:$kPedidoId:$kEventoId';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    WhatsAppService.limparHistoricoSimulacoes();

    // Inicializa banco de dados SQLite Drift isolado em memória
    db = FincoreDatabase(NativeDatabase.memory());
    DependencyInjection().clear();
    DependencyInjection().register<FincoreDatabase>(db);

    // Inicializa a tabela forense de logs
    await WhatsAppService.logRepository.inicializarTabela();
  });

  tearDown(() async {
    await db.close();
    DependencyInjection().clear();
  });

  group('Fase D2 — Idempotência Persistente e Auditoria Forense no SQLite', () {
    test('Tabela whatsapp_mensagens_log é inicializada e existeIdempotencia retorna false inicialmente', () async {
      final repo = WhatsAppService.logRepository;
      final existe = await repo.existeIdempotencia(kIdempotencyKey);
      expect(existe, isFalse);
    });

    test('Registro com status sucesso grava no SQLite e bloqueia duplicação persistente', () async {
      final repo = WhatsAppService.logRepository;

      final record = WhatsAppMessageLogRecord(
        id: const Uuid().v4(),
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        eventoId: kEventoId,
        idempotencyKey: kIdempotencyKey,
        destinatarioMascarado: '+55 (35) *****-3114',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Seu pedido #999 está pronto!',
        status: 'sucesso',
        messageId: 'MSG-SQLITE-ID-12345',
        httpStatusCode: 200,
        erro: null,
        criadoEm: DateTime.now(),
      );

      final registrado = await repo.registrarLog(record);
      expect(registrado, isTrue);

      // Verificação de idempotência no banco de dados SQLite
      final existe = await repo.existeIdempotencia(kIdempotencyKey);
      expect(existe, isTrue);

      // Consulta direta via SQL na tabela para garantir persistência real
      final rows = await db.customSelect(
        'SELECT * FROM whatsapp_mensagens_log WHERE idempotency_key = ?',
        variables: [Variable.withString(kIdempotencyKey)],
      ).get();

      expect(rows.length, equals(1));
      expect(rows.first.data['destinatario_mascarado'], equals('+55 (35) *****-3114'));
      expect(rows.first.data['message_id'], equals('MSG-SQLITE-ID-12345'));
      expect(rows.first.data['http_status_code'], equals(200));
      expect(rows.first.data['status'], equals('sucesso'));
    });

    test('Sobrevivência a reinicialização: Idempotência persiste mesmo recriando a instância do repositório', () async {
      final repo1 = WhatsAppMessageLogRepository();

      final record = WhatsAppMessageLogRecord(
        id: const Uuid().v4(),
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        eventoId: kEventoId,
        idempotencyKey: kIdempotencyKey,
        destinatarioMascarado: '+55 (11) *****-8888',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Pedido despachado!',
        status: 'sucesso',
        messageId: 'MSG-RESTART-001',
        httpStatusCode: 201,
        erro: null,
        criadoEm: DateTime.now(),
      );

      await repo1.registrarLog(record);

      // Simula reinicialização do app recriando o repositório
      final repoNovoAposReinicio = WhatsAppMessageLogRepository();
      final existeAposReinicio = await repoNovoAposReinicio.existeIdempotencia(kIdempotencyKey);

      expect(existeAposReinicio, isTrue);
    });

    test('WhatsAppService.enviarMensagem bloqueia reenvio com mesma chave já persistida no banco', () async {
      final repo = WhatsAppService.logRepository;

      // Grava envio anterior com sucesso
      await repo.registrarLog(WhatsAppMessageLogRecord(
        id: const Uuid().v4(),
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        eventoId: kEventoId,
        idempotencyKey: kIdempotencyKey,
        destinatarioMascarado: '+55 (35) *****-3114',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Envio anterior efetuado',
        status: 'sucesso',
        messageId: 'MSG-PREV-SUCCESS',
        httpStatusCode: 200,
        erro: null,
        criadoEm: DateTime.now(),
      ));

      // Tentativa de novo envio com a mesma chave
      final res = await WhatsAppService.enviarMensagem(
        rawPhone: '35992503114',
        mensagem: 'Tentando enviar novamente o mesmo pedido',
        tenantId: kTenantId,
        pedidoId: kPedidoId,
        eventoId: kEventoId,
      );

      expect(res.sucesso, isFalse);
      expect(res.erro, contains('Disparo bloqueado por idempotência'));
      expect(res.telefoneMascarado, equals(EvolutionApiClient.mascararTelefone('35992503114')));
    });

    test('Envio com falha/erro NÃO bloqueia a chave para permitir retentativa do operador', () async {
      final repo = WhatsAppService.logRepository;
      const chaveFalha = 'tenant:ped_erro:evento';

      // Grava tentativa que falhou (ex: timeout de rede)
      await repo.registrarLog(WhatsAppMessageLogRecord(
        id: const Uuid().v4(),
        tenantId: kTenantId,
        pedidoId: 'ped_erro',
        eventoId: 'evento',
        idempotencyKey: chaveFalha,
        destinatarioMascarado: '+55 (35) *****-3114',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Falha de conexão',
        status: 'erroConexao',
        messageId: null,
        httpStatusCode: null,
        erro: 'Timeout de 10s atingido',
        criadoEm: DateTime.now(),
      ));

      // A idempotência NÃO deve considerar falha como envio concluído
      final existe = await repo.existeIdempotencia(chaveFalha);
      expect(existe, isFalse);
    });

    test('LGPD e Forense: listarLogs recupera histórico ordenado com números mascarados', () async {
      final repo = WhatsAppService.logRepository;

      for (int i = 1; i <= 3; i++) {
        await repo.registrarLog(WhatsAppMessageLogRecord(
          id: 'log_$i',
          tenantId: kTenantId,
          pedidoId: 'ped_$i',
          eventoId: 'evento_$i',
          idempotencyKey: '$kTenantId:ped_$i:evento_$i',
          destinatarioMascarado: '+55 (35) *****-000$i',
          instancia: 'fincore_atendimento',
          mensagemPreview: 'Preview da mensagem $i',
          status: 'sucesso',
          messageId: 'MSG-$i',
          httpStatusCode: 200,
          erro: null,
          criadoEm: DateTime.now().add(Duration(minutes: i)),
        ));
      }

      final logs = await repo.listarLogs(tenantId: kTenantId);
      expect(logs.length, equals(3));
      // Mais recente primeiro
      expect(logs.first.id, equals('log_3'));
      expect(logs.first.destinatarioMascarado, equals('+55 (35) *****-0003'));
      // Dados forenses íntegros
      expect(logs.first.messageId, equals('MSG-3'));
      expect(logs.first.httpStatusCode, equals(200));
    });
  });

  group('Fase D2 — Modo Manual Human-in-the-Loop', () {
    test('Política manual emite notificação reativa no manualPromptNotifier para o operador', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoPronto: WhatsAppEventPolicy.manual,
      }, tenantId: kTenantId);

      WhatsAppManualPrompt? promptCapturado;
      WhatsAppService.manualPromptNotifier.addListener(() {
        promptCapturado = WhatsAppService.manualPromptNotifier.value;
      });

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: 'ped_manual_101',
        numeroPedido: '101',
        eventoId: WhatsAppService.kEventoPedidoPronto,
        tipoLogistica: 'Retirada',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '35992503114',
        clienteNome: 'Eliezer',
      );

      expect(decisao.autorizado, isTrue);
      expect(decisao.politica, equals(WhatsAppEventPolicy.manual));
      expect(decisao.requerConfirmacaoManual, isTrue);
      expect(decisao.codigoDecisao, equals('AUTHORIZED_MANUAL'));

      // Verifica se o prompt reativo foi emitido para a UI
      expect(promptCapturado, isNotNull);
      expect(promptCapturado!.decisao.pedidoId, equals('ped_manual_101'));
      expect(promptCapturado!.rawPhone, equals('35992503114'));
      expect(promptCapturado!.tenantId, equals(kTenantId));
    });

    test('Política desativada (padrão) NÃO emite notificação para o operador', () async {
      WhatsAppManualPrompt? promptCapturado;
      WhatsAppService.manualPromptNotifier.addListener(() {
        promptCapturado = WhatsAppService.manualPromptNotifier.value;
      });

      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: 'ped_disabled_102',
        numeroPedido: '102',
        eventoId: WhatsAppService.kEventoPedidoPronto,
        tipoLogistica: 'Retirada',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '35992503114',
        clienteNome: 'Eliezer',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.requerConfirmacaoManual, isFalse);
      expect(promptCapturado, isNull);
    });

    test('Idempotência persistida no SQLite bloqueia re-avaliação do evento no Modo Manual', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoPronto: WhatsAppEventPolicy.manual,
      }, tenantId: kTenantId);

      const chave = '$kTenantId:ped_manual_dup:pedido_pronto';

      // Simula que o evento já foi despachado e gravado no SQLite
      await WhatsAppService.logRepository.registrarLog(WhatsAppMessageLogRecord(
        id: const Uuid().v4(),
        tenantId: kTenantId,
        pedidoId: 'ped_manual_dup',
        eventoId: WhatsAppService.kEventoPedidoPronto,
        idempotencyKey: chave,
        destinatarioMascarado: '+55 (35) *****-3114',
        instancia: 'fincore_atendimento',
        mensagemPreview: 'Disparado anteriormente',
        status: 'sucesso',
        criadoEm: DateTime.now(),
      ));

      // Avaliação simulada deve ser bloqueada por BLOCKED_DUPLICATE
      final decisao = await WhatsAppService.avaliarDecisaoSimulada(
        tenantId: kTenantId,
        pedidoId: 'ped_manual_dup',
        numeroPedido: '202',
        eventoId: WhatsAppService.kEventoPedidoPronto,
        tipoLogistica: 'Retirada',
        empresaUsarWhatsApp: true,
        clienteAceitaWhatsapp: true,
        rawPhone: '35992503114',
        clienteNome: 'Eliezer',
      );

      expect(decisao.autorizado, isFalse);
      expect(decisao.codigoDecisao, equals('BLOCKED_DUPLICATE'));
      expect(decisao.isDuplicado, isTrue);
      expect(decisao.requerConfirmacaoManual, isFalse);
    });
  });
}
