import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/audit/audit_service.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:fincore_core/src/logging/log_service.dart';
import 'dart:io';

void main() {
  group('OutboxService, SyncEngine & AuditService Tests', () {
    late Directory tempDir;
    late FincoreDatabase db;
    late TenantContext context;
    late OutboxService outboxService;
    late AuditService auditService;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('fincore_sync_test');
      LogService.init(tempDir.path, runCleanup: false);
    });

    tearDownAll(() async {
      await LogService.instance.forceCleanup();
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-123',
      razaoSocial: 'Empresa Teste',
      nomeFantasia: 'Teste',
      documentoFiscal: '123',
      email: 'a@a.com',
      telefone: '123',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.bronze,
      timezone: 'GMT',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Web',
      version: 1,
      tipoPessoa: 'JURIDICA',
      metadata: mockMetadata,
    );

    final mockUsuario = CoreUsuario(
      id: 'user-1',
      nome: 'User Test',
      email: 'user@user.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      context = TenantContext();
      context.clear();
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      outboxService = OutboxService(db: db, context: context);
      auditService = AuditService(context: context);
    });

    tearDown(() async {
      await db.close();
    });

    test('should enqueue outbox items successfully with active tenantId', () async {
      final id = await outboxService.enqueue(
        entity: 'Empresa',
        entityId: 'tenant-123',
        action: 'UPDATE',
        payload: {'nomeFantasia': 'Nova Empresa'},
        version: 2,
      );

      expect(id, greaterThan(0));

      final pending = await outboxService.getPendingEntries();
      expect(pending.length, equals(1));
      expect(pending.first.entity, equals('Empresa'));
      expect(pending.first.tenantId, equals('tenant-123'));
      expect(pending.first.status, equals(SyncStatus.pending.name));
    });

    test('should process pending outbox queue with SyncEngine', () async {
      await outboxService.enqueue(
        entity: 'Usuario',
        entityId: 'user-1',
        action: 'CREATE',
        payload: {'nome': 'User Test'},
        version: 1,
      );

      final syncEngine = SyncEngine(
        outboxService: outboxService,
        context: context,
        db: db,
        serverPushHandler: (entry) async {
          return true; // Simula envio bem-sucedido
        },
      );

      final processed = await syncEngine.processPendingQueue();
      expect(processed.successCount, equals(1));

      final pendingAfter = await outboxService.getPendingEntries();
      expect(pendingAfter.isEmpty, isTrue);
    });

    test('should record AuditEvent correctly with AuditService', () async {
      await auditService.log(
        id: 'audit-1',
        entity: 'Empresa',
        entityId: 'tenant-123',
        action: AuditAction.update,
        before: '{"nome": "Antigo"}',
        after: '{"nome": "Novo"}',
        deviceId: 'device-001',
        origin: 'Windows-POS',
      );

      expect(auditService.logs.length, equals(1));
      expect(auditService.logs.first.tenantId, equals('tenant-123'));
      expect(auditService.logs.first.performedBy, equals('user-1'));
      expect(auditService.logs.first.origin, equals('Windows-POS'));
    });
  });
}
