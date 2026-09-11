import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/audit/audit_service.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/config/config_aggregates.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/empresa_repository.dart';
import 'package:fincore_core/repository/usuario_repository.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:fincore_core/src/logging/log_service.dart';
import 'dart:io';

void main() {
  group('Platform Core E2E Integration Tests (Milestone 3)', () {
    late Directory tempDir;
    late FincoreDatabase db;
    late TenantContext context;
    late DependencyInjection di;
    late EmpresaRepository empresaRepository;
    late UsuarioRepository usuarioRepository;
    late OutboxService outboxService;
    late SyncEngine syncEngine;
    late AuditService auditService;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('fincore_e2e_logs');
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
      createdBy: 'admin-e2e',
      updatedBy: 'admin-e2e',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-e2e-001',
      razaoSocial: 'FINCORE Food Matriz LTDA',
      nomeFantasia: 'FINCORE Food Matriz',
      documentoFiscal: '11.222.333/0001-44',
      email: 'matriz@fincore.com',
      telefone: '11912345678',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.ouro,
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Web-Admin',
      version: 1,
      tipoPessoa: 'JURIDICA',
      metadata: mockMetadata,
    );

    final mockUsuario = CoreUsuario(
      id: 'user-e2e-001',
      nome: 'Gerente Geral',
      email: 'gerente@fincore.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      context = TenantContext();
      context.clear();
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      di = DependencyInjection();
      di.clear();

      outboxService = OutboxService(db: db, context: context);
      empresaRepository = EmpresaRepository(db: db, context: context, outbox: outboxService);
      usuarioRepository = UsuarioRepository(db: db, context: context);
      auditService = AuditService(context: context);
      syncEngine = SyncEngine(
        outboxService: outboxService,
        context: context,
        db: db,
        serverPushHandler: (entry) async => true,
      );

      di.register<FincoreDatabase>(db);
      di.register<TenantContext>(context);
      di.register<EmpresaRepository>(empresaRepository);
      di.register<UsuarioRepository>(usuarioRepository);
      di.register<OutboxService>(outboxService);
      di.register<SyncEngine>(syncEngine);
      di.register<AuditService>(auditService);
    });

    tearDown(() async {
      await db.close();
      di.clear();
    });

    test('should execute complete E2E lifecycle (DI, Context, DB, Outbox, Sync, Audit & Inheritance)', () async {
      // 1. Validar Service Locator (DI)
      expect(di.get<TenantContext>(), same(context));
      expect(di.get<EmpresaRepository>(), same(empresaRepository));

      // 2. Persistir Empresa e Usuário no banco SQLite via repositórios com tenancy-isolation
      await empresaRepository.save(mockEmpresa);
      await usuarioRepository.save(mockUsuario);
      // Process pending queue from the save so step 4 only processes the UPDATE
      await syncEngine.processPendingQueue();

      final retrievedEmpresa = await empresaRepository.findById('tenant-e2e-001');
      expect(retrievedEmpresa, isNotNull);
      expect(retrievedEmpresa!.nomeFantasia, equals('FINCORE Food Matriz'));

      final retrievedUsuario = await usuarioRepository.findById('user-e2e-001');
      expect(retrievedUsuario, isNotNull);
      expect(retrievedUsuario!.nome, equals('Gerente Geral'));

      // 3. Enfileirar mutação no Outbox
      final outboxId = await outboxService.enqueue(
        entity: 'Empresa',
        entityId: mockEmpresa.id,
        action: 'UPDATE',
        payload: {'nomeFantasia': 'FINCORE Food Matriz VIP'},
        version: 2,
      );
      expect(outboxId, greaterThan(0));

      // 4. Processar fila de sincronização via SyncEngine
      final processedResult = await syncEngine.processPendingQueue();
      expect(processedResult.successCount, equals(1));

      // 5. Registrar e verificar evento imutável de Auditoria
      await auditService.log(
        id: 'audit-e2e-001',
        entity: 'Empresa',
        entityId: mockEmpresa.id,
        action: AuditAction.update,
        before: '{"nomeFantasia": "FINCORE Food Matriz"}',
        after: '{"nomeFantasia": "FINCORE Food Matriz VIP"}',
        deviceId: 'terminal-01',
        origin: 'Windows-POS',
      );

      expect(auditService.logs.length, equals(1));
      expect(auditService.logs.first.tenantId, equals('tenant-e2e-001'));
      expect(auditService.logs.first.performedBy, equals('user-e2e-001'));

      // 6. Validar o resolvedor de herança do Centro de Configuração
      final printer = CentroDeConfiguracao.resolveInherited<String>(
        userOrTerminalValue: null,
        empresaValue: 'EPSON_TM_T20_MATRIZ',
        defaultValue: 'GENERIC_POS_58',
      );
      expect(printer, equals('EPSON_TM_T20_MATRIZ'));
    });
  });
}
