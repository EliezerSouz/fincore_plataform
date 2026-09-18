import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_core/src/logging/log_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fincore_logger_test_');
    LogService.init(tempDir.path, runCleanup: false, isProduction: false, appVersion: '1.2.1');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Sistema de Logging Padronizado — FINCORE Enterprise', () {
    test('LogEvent cria ID, TraceId e JSON válidos', () {
      final event = LogEvent(
        level: LogLevel.info,
        category: LogCategory.operacional,
        eventType: 'PEDIDO_CRIADO',
        action: 'CREATE',
        module: LogModule.pedidos,
        operation: 'CriarPedido',
        message: 'Pedido #0001 criado com sucesso.',
        entityType: 'pedidos',
        entityId: 'ped-12345678',
        userId: 'op-01',
        tenantId: 'emp-01',
        traceId: 'TRC-TESTE123',
        metadata: {'valorCentavos': 5000, 'password': 'minhasenha123'},
      );

      expect(event.id.isNotEmpty, isTrue);
      expect(event.traceId, equals('TRC-TESTE123'));
      expect(event.applicationVersion, equals('1.2.1'));
      expect(event.loggerVersion, equals('1.3.0'));

      final json = event.toJson();
      expect(json['level'], equals('INFO'));
      expect(json['category'], equals('OPERACIONAL'));
      expect(json['eventType'], equals('PEDIDO_CRIADO'));

      // Verifica se a senha foi mascarada (Redaction)
      expect(json['metadata']['password'], equals('***REDACTED***'));
      expect(json['metadata']['valorCentavos'], equals(5000));
    });

    test('LogEvent gera formatação BareTail alinhada', () {
      final event = LogEvent(
        level: LogLevel.warning,
        category: LogCategory.sincronizacao,
        eventType: 'SYNC_RETRY',
        action: 'PUSH',
        module: LogModule.sync,
        operation: 'PushOutbox',
        message: 'Falha temporária ao enviar outbox.',
        entityType: 'itens_pedido',
        entityId: 'item-87654321',
        userId: 'op-02',
        tenantId: 'emp-01',
        traceId: 'TRC-SYNC-999',
        errorCode: '23503',
        errorMessage: 'Key (pedidoId) is not present in table "pedido".',
        status: LogStatus.retrying,
      );

      final line = event.toBareTailLine();
      expect(line.contains('[AVISO]'), isTrue);
      expect(line.contains('[SINCRONIZACAO]'), isTrue);
      expect(line.contains('[Rastreio: TRC-SYNC-999]'), isTrue);
      expect(line.contains('op-02@emp-01'), isTrue);
      expect(line.contains('Erro: [23503]'), isTrue);
    });

    test('LogService.emitEvent executa de forma não-bloqueante', () async {
      final event = LogEvent(
        level: LogLevel.info,
        category: LogCategory.bancoDados,
        eventType: 'MUTACAO_LOCAL',
        action: 'UPDATE',
        module: LogModule.database,
        operation: 'saveLocal',
        message: 'Alteração em empresa_configuracao.',
        entityType: 'empresa_configuracao',
        entityId: 'cfg-100',
      );

      expect(() async => await LogService.instance.emitEvent(event), returnsNormally);
    });
  });
}
