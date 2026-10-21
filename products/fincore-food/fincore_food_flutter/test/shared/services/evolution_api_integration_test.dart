@Tags(['integration'])
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

class _RealHttpOverrides extends HttpOverrides {
  // ignore: unnecessary_overrides
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  // Credenciais reais validadas no ambiente local da Evolution API
  const String kValidApiUrl = 'http://localhost:8080';
  const String kValidApiKey = 'fincore_sec_9f8e7d6c5b4a3a2b1c0d_api';
  const String kValidInstance = 'fincore_atendimento';
  const String kTestPhone = '553592503114'; // Eliezer (Delivery do Eli)

  bool isEvolutionApiReachable = false;

  setUpAll(() async {
    try {
      final socket = await Socket.connect('localhost', 8080, timeout: const Duration(milliseconds: 500));
      await socket.close();
      isEvolutionApiReachable = true;
    } catch (_) {
      isEvolutionApiReachable = false;
    }
  });

  setUp(() {
    EvolutionApiClient.clearAuditHistory();
  });

  group('Fase D1 — Validações Básicas e Segurança de Dados', () {
    test('Mascaramento de telefone preserva privacidade e conformidade LGPD', () {
      expect(EvolutionApiClient.mascararTelefone('5535992503114'), equals('5535****14'));
      expect(EvolutionApiClient.mascararTelefone('(35) 99250-3114'), equals('3599****14'));
      expect(EvolutionApiClient.mascararTelefone('123'), equals('***'));
    });

    test('Rejeição segura quando telefone de destino for inválido', () async {
      final config = EvolutionApiConfig(
        apiUrl: kValidApiUrl,
        apiKey: kValidApiKey,
        instanceName: kValidInstance,
      );

      final resultado = await WhatsAppService.enviarMensagem(
        rawPhone: '1234',
        mensagem: 'Teste com telefone inválido',
        config: config,
      );

      expect(resultado.sucesso, isFalse);
      expect(resultado.status, equals(WhatsAppSendStatus.telefoneInvalido));
      expect(resultado.erro, contains('inválido'));
    });

    test('Auditoria segura NUNCA expõe API Key ou credenciais confidenciais', () async {
      final config = EvolutionApiConfig(
        apiUrl: kValidApiUrl,
        apiKey: kValidApiKey,
        instanceName: kValidInstance,
      );

      await WhatsAppService.enviarMensagem(
        rawPhone: '1234',
        mensagem: 'Teste auditoria',
        config: config,
      );

      final historico = EvolutionApiClient.getAuditHistory();
      expect(historico, isNotEmpty);
      final jsonAuditoria = historico.first.toAuditMap().toString();

      expect(jsonAuditoria, isNot(contains(kValidApiKey)));
      expect(jsonAuditoria, isNot(contains('password')));
      expect(jsonAuditoria, isNot(contains('fincore_sec_')));
    });
  });

  group('Fase D1 — Cenários Obrigatórios de Integração Real', () {
    // TESTE 1: Evolution API disponível e operacional
    test('Teste 1: Evolution API disponível — mensagem enviada e aceita com sucesso', () async {
      if (!isEvolutionApiReachable) {
        // Container Docker da Evolution API desligado localmente — ignora teste vivo de rede externa
        return;
      }
      final config = EvolutionApiConfig(
        apiUrl: kValidApiUrl,
        apiKey: kValidApiKey,
        instanceName: kValidInstance,
      );

      final resultado = await WhatsAppService.enviarMensagem(
        rawPhone: kTestPhone,
        mensagem: '🧪 *Teste Técnico D1 (FINCORE Food)*: Validação de canal direto com Evolution API v2.3.7!',
        config: config,
        tenantId: 'tenant_teste_d1',
        pedidoId: 'ped_001',
        eventoId: 'teste_d1',
      );

      expect(resultado.sucesso, isTrue, reason: 'A Evolution API deve aceitar o envio (HTTP 200/201)');
      expect(resultado.status, equals(WhatsAppSendStatus.sucesso));
      expect(resultado.httpStatusCode, anyOf(200, 201));
      expect(resultado.messageId, isNotNull, reason: 'Deve extrair o messageId gerado pela Evolution API');
      expect(resultado.messageId, isNotEmpty);
      expect(resultado.telefoneMascarado, equals('5535****14'));
      expect(resultado.instancia, equals(kValidInstance));
      expect(resultado.idempotencyKey, equals('tenant_teste_d1:ped_001:teste_d1'));
    });

    // TESTE 2: Evolution API desligada (porta inexistente)
    test('Teste 2: Evolution API desligada — FINCORE trata erro com segurança e não trava', () async {
      final config = EvolutionApiConfig(
        apiUrl: 'http://localhost:59999', // Porta desligada/inexistente
        apiKey: kValidApiKey,
        instanceName: kValidInstance,
        timeout: const Duration(seconds: 2),
      );

      final resultado = await WhatsAppService.enviarMensagem(
        rawPhone: kTestPhone,
        mensagem: 'Teste com servidor desligado',
        config: config,
      );

      expect(resultado.sucesso, isFalse);
      expect(
        resultado.status,
        anyOf(WhatsAppSendStatus.servidorIndisponivel, WhatsAppSendStatus.timeout),
        reason: 'Deve identificar indisponibilidade de socket ou timeout',
      );
      expect(resultado.erro, isNotNull);
    });

    // TESTE 3: API Key inválida
    test('Teste 3: API Key inválida — envio rejeitado com falha de autenticação', () async {
      if (!isEvolutionApiReachable) {
        // Container Docker da Evolution API desligado localmente — ignora teste vivo de rede externa
        return;
      }
      final config = EvolutionApiConfig(
        apiUrl: kValidApiUrl,
        apiKey: 'chave_invalida_seguranca_fincore',
        instanceName: kValidInstance,
      );

      final resultado = await WhatsAppService.enviarMensagem(
        rawPhone: kTestPhone,
        mensagem: 'Teste com credencial inválida',
        config: config,
      );

      expect(resultado.sucesso, isFalse);
      expect(resultado.status, equals(WhatsAppSendStatus.falhaAutenticacao));
      expect(resultado.httpStatusCode, anyOf(401, 403));
      expect(resultado.erro, contains('autenticação'));
    });

    // TESTE 4: Timeout/indisponibilidade
    test('Teste 4: Timeout/indisponibilidade — tratado como timeout seguro sem exceção', () async {
      final config = EvolutionApiConfig(
        apiUrl: 'http://10.255.255.1:8080', // IP inalcançável para forçar timeout
        apiKey: kValidApiKey,
        instanceName: kValidInstance,
        timeout: const Duration(milliseconds: 100), // Timeout ultra-curto
      );

      final resultado = await WhatsAppService.enviarMensagem(
        rawPhone: kTestPhone,
        mensagem: 'Teste com timeout forçado',
        config: config,
      );

      expect(resultado.sucesso, isFalse);
      expect(
        resultado.status,
        anyOf(WhatsAppSendStatus.timeout, WhatsAppSendStatus.servidorIndisponivel),
      );
    });

    test('Teste 5: EvolutionInstanceInfo formata telefone brasileiro corretamente', () {
      const info13 = EvolutionInstanceInfo(
        name: 'instancia_teste',
        connectionStatus: 'open',
        ownerJid: '5535992503114@s.whatsapp.net',
        profileName: 'Eliezer',
      );
      expect(info13.isConnected, isTrue);
      expect(info13.formattedPhone, equals('+55 (35) 99250-3114'));

      const info12 = EvolutionInstanceInfo(
        name: 'instancia_fixo',
        connectionStatus: 'close',
        ownerJid: '553538221234@s.whatsapp.net',
      );
      expect(info12.isDisconnected, isTrue);
      expect(info12.formattedPhone, equals('+55 (35) 3822-1234'));

      const infoNotFound = EvolutionInstanceInfo(
        name: 'inexistente',
        connectionStatus: 'not_found',
      );
      expect(infoNotFound.isNotFound, isTrue);
      expect(infoNotFound.formattedPhone, isNull);
    });
  });
}
