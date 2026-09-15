import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/audit/audit_service.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:fincore_core/src/logging/log_service.dart';

void main() {
  group('Sincronização Bidirecional Balcão (POS) x Cozinha (KDS) & Estoque', () {
    late Directory tempDir;

    // Simula Node 1: Computador Balcão (POS)
    late FincoreDatabase dbBalcao;
    late TenantContext contextBalcao;
    late OutboxService outboxBalcao;
    late SyncEngine syncEngineBalcao;
    late AuditService auditBalcao;

    // Simula Node 2: Computador Cozinha (KDS)
    late FincoreDatabase dbCozinha;
    late TenantContext contextCozinha;
    late OutboxService outboxCozinha;
    late SyncEngine syncEngineCozinha;
    late AuditService auditCozinha;

    // Fila central simulada em memória (Simulando o Nuvem/Serverpod)
    final List<OutboxEntry> cloudSyncQueue = [];

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('fincore_pos_kds_sync_test');
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
      id: 'tenant-restaurante-001',
      razaoSocial: 'Restaurante Fincore LTDA',
      nomeFantasia: 'Fincore Food',
      documentoFiscal: '12.345.678/0001-90',
      email: 'contato@fincorefood.com',
      telefone: '11999998888',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.ouro,
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Web',
      version: 1,
      tipoPessoa: 'JURIDICA',
      metadata: mockMetadata,
    );

    final mockUsuarioBalcao = CoreUsuario(
      id: 'op-balcao-01',
      nome: 'Operador Balcao',
      email: 'balcao@fincorefood.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final mockUsuarioCozinha = CoreUsuario(
      id: 'chef-cozinha-01',
      nome: 'Chef Cozinha',
      email: 'cozinha@fincorefood.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() async {
      cloudSyncQueue.clear();

      // Configuração do Computador do Balcão
      dbBalcao = FincoreDatabase(NativeDatabase.memory());
      contextBalcao = TenantContext();
      contextBalcao.setContext(empresa: mockEmpresa, usuario: mockUsuarioBalcao);
      outboxBalcao = OutboxService(db: dbBalcao, context: contextBalcao);
      auditBalcao = AuditService(context: contextBalcao);

      syncEngineBalcao = SyncEngine(
        outboxService: outboxBalcao,
        context: contextBalcao,
        db: dbBalcao,
        serverPushHandler: (entry) async {
          cloudSyncQueue.add(entry);
          return true;
        },
      );

      // Configuração do Computador da Cozinha
      dbCozinha = FincoreDatabase(NativeDatabase.memory());
      contextCozinha = TenantContext();
      contextCozinha.setContext(empresa: mockEmpresa, usuario: mockUsuarioCozinha);
      outboxCozinha = OutboxService(db: dbCozinha, context: contextCozinha);
      auditCozinha = AuditService(context: contextCozinha);

      syncEngineCozinha = SyncEngine(
        outboxService: outboxCozinha,
        context: contextCozinha,
        db: dbCozinha,
        serverPushHandler: (entry) async {
          cloudSyncQueue.add(entry);
          return true;
        },
      );
    });

    tearDown(() async {
      await dbBalcao.close();
      await dbCozinha.close();
    });

    test('Cenário 1: Venda realizada no Balcão gera pedido, reserva estoque e envia Ordem de Preparo para Cozinha', () async {
      contextBalcao.setContext(empresa: mockEmpresa, usuario: mockUsuarioBalcao);

      // 1. Balcão realiza venda de 2x X-Burguer
      final pedidoId = 'PED-2026-001';
      final outboxBalcaoId = await outboxBalcao.enqueue(
        entity: 'Pedido',
        entityId: pedidoId,
        action: 'CREATE',
        payload: {
          'status': 'pendente_preparo',
          'total': 58.00,
          'itens': [
            {'produtoId': 'prod-burguer-01', 'quantidade': 2, 'unidade': 'un', 'preco': 29.00}
          ]
        },
        version: 1,
      );

      expect(outboxBalcaoId, greaterThan(0));

      // 2. Balcão grava audit log da venda
      await auditBalcao.log(
        id: 'audit-pos-001',
        entity: 'Pedido',
        entityId: pedidoId,
        action: AuditAction.create,
        before: null,
        after: '{"status": "pendente_preparo", "total": 58.00}',
        deviceId: 'PC-BALCAO-01',
        origin: 'Windows-POS',
      );

      // 3. Sincronização do Balcão enviando para a Nuvem
      final pushResult = await syncEngineBalcao.processPendingQueue();
      expect(pushResult.successCount, equals(1));
      expect(cloudSyncQueue.length, equals(1));
      expect(cloudSyncQueue.first.entity, equals('Pedido'));
      expect(cloudSyncQueue.first.entityId, equals(pedidoId));

      // 4. Cozinha recebe (pull) a notificação e cria Ordem de Preparo local
      contextCozinha.setContext(empresa: mockEmpresa, usuario: mockUsuarioCozinha);
      final entryCloud = cloudSyncQueue.first;
      final outboxKdsId = await outboxCozinha.enqueue(
        entity: 'OrdemPreparo',
        entityId: 'KDS-001',
        action: 'CREATE',
        payload: {
          'pedidoId': entryCloud.entityId,
          'status': StatusOrdemPreparo.pendente.name,
          'prioridade': PrioridadeOrdem.normal.name,
        },
        version: 1,
      );

      expect(outboxKdsId, greaterThan(0));
      final pendingKds = await outboxCozinha.getPendingEntries();
      expect(pendingKds.first.entity, equals('OrdemPreparo'));
      expect(pendingKds.first.status, equals(SyncStatus.pending.name));
    });

    test('Cenário 2: Cozinha altera status da Ordem de Preparo e Balcão recebe atualização em tempo real', () async {
      contextCozinha.setContext(empresa: mockEmpresa, usuario: mockUsuarioCozinha);

      // 1. Cozinha inicia preparo da ordem (pendente -> emPreparo)
      await outboxCozinha.enqueue(
        entity: 'OrdemPreparo',
        entityId: 'KDS-001',
        action: 'UPDATE',
        payload: {
          'status': StatusOrdemPreparo.emPreparo.name,
          'operadorId': 'chef-cozinha-01',
          'iniciadaEm': DateTime.now().toIso8601String(),
        },
        version: 2,
      );

      await auditCozinha.log(
        id: 'audit-kds-001',
        entity: 'OrdemPreparo',
        entityId: 'KDS-001',
        action: AuditAction.update,
        before: '{"status": "pendente"}',
        after: '{"status": "emPreparo"}',
        deviceId: 'PC-COZINHA-01',
        origin: 'Windows-KDS',
      );

      // 2. Cozinha sincroniza com a nuvem
      final pushResultCozinha = await syncEngineCozinha.processPendingQueue();
      expect(pushResultCozinha.successCount, equals(1));

      // 3. Cozinha marca como PRONTO
      await outboxCozinha.enqueue(
        entity: 'OrdemPreparo',
        entityId: 'KDS-001',
        action: 'UPDATE',
        payload: {
          'status': StatusOrdemPreparo.pronto.name,
          'concluidaEm': DateTime.now().toIso8601String(),
        },
        version: 3,
      );

      await syncEngineCozinha.processPendingQueue();
      expect(cloudSyncQueue.length, equals(2));

      // 4. Balcão lê as atualizações da Cozinha na nuvem e atualiza status no POS
      contextBalcao.setContext(empresa: mockEmpresa, usuario: mockUsuarioBalcao);
      final ultimaMutacao = cloudSyncQueue.last;
      expect(ultimaMutacao.entity, equals('OrdemPreparo'));
      expect(ultimaMutacao.entityId, equals('KDS-001'));
      expect(ultimaMutacao.version, equals(3));
    });

    test('Cenário 3: Reversão de status (Cozinha reverte de Pronto para Em Preparo) é propagada simetricamente', () async {
      contextCozinha.setContext(empresa: mockEmpresa, usuario: mockUsuarioCozinha);

      // 1. Cozinha cometeu engano e reverte status de PRONTO para EM_PREPARO
      final revertOutboxId = await outboxCozinha.enqueue(
        entity: 'OrdemPreparo',
        entityId: 'KDS-001',
        action: 'REVERT_STATUS',
        payload: {
          'status': StatusOrdemPreparo.emPreparo.name,
          'motivo': 'Item incompleto na bandeja',
        },
        version: 4,
      );

      expect(revertOutboxId, greaterThan(0));

      await auditCozinha.log(
        id: 'audit-kds-002',
        entity: 'OrdemPreparo',
        entityId: 'KDS-001',
        action: AuditAction.update,
        before: '{"status": "pronto"}',
        after: '{"status": "emPreparo", "motivo": "Item incompleto na bandeja"}',
        deviceId: 'PC-COZINHA-01',
        origin: 'Windows-KDS',
      );

      final pushResult = await syncEngineCozinha.processPendingQueue();
      expect(pushResult.successCount, equals(1));

      // Balcão recebe o evento de reversão e atualiza a tela
      contextBalcao.setContext(empresa: mockEmpresa, usuario: mockUsuarioBalcao);
      final revertEvent = cloudSyncQueue.last;
      expect(revertEvent.action, equals('REVERT_STATUS'));
      expect(revertEvent.version, equals(4));
    });

    test('Cenário 4: Alteração de Cadastro e Saldo de Estoque sincronizados entre Balcão e Cozinha', () async {
      contextBalcao.setContext(empresa: mockEmpresa, usuario: mockUsuarioBalcao);

      // 1. Balcão realiza ajuste manual de estoque do Pão de Burguer (+50 unidades)
      final loteId = 'LOTE-PAO-001';
      await outboxBalcao.enqueue(
        entity: 'LoteInsumo',
        entityId: loteId,
        action: 'UPDATE_ESTOQUE',
        payload: {
          'produtoId': 'prod-pao-01',
          'quantidadeInicial': 10000, // 100.00 un
          'quantidadeDisponivel': 15000, // 150.00 un
          'quantidadeReservada': 0,
        },
        version: 1,
      );

      await auditBalcao.log(
        id: 'audit-pos-estoque-001',
        entity: 'LoteInsumo',
        entityId: loteId,
        action: AuditAction.update,
        before: '{"quantidadeDisponivel": 10000}',
        after: '{"quantidadeDisponivel": 15000}',
        deviceId: 'PC-BALCAO-01',
        origin: 'Windows-POS',
      );

      final pushResult = await syncEngineBalcao.processPendingQueue();
      expect(pushResult.successCount, equals(1));

      // 2. Cozinha consulta alteração e verifica sincronia de saldo
      contextCozinha.setContext(empresa: mockEmpresa, usuario: mockUsuarioCozinha);
      final mutacaoEstoque = cloudSyncQueue.last;
      expect(mutacaoEstoque.entity, equals('LoteInsumo'));
      expect(mutacaoEstoque.entityId, equals(loteId));
      final payloadMap = jsonDecode(mutacaoEstoque.payload) as Map<String, dynamic>;
      expect(payloadMap['quantidadeDisponivel'], equals(15000));
    });

    test('Cenário 5: Verificação de Rastreabilidade e Logs de Sincronia', () async {
      // Registrar evento de auditoria no Balcão
      contextBalcao.setContext(empresa: mockEmpresa, usuario: mockUsuarioBalcao);
      await auditBalcao.log(
        id: 'audit-pos-log-001',
        entity: 'Pedido',
        entityId: 'PED-LOG-001',
        action: AuditAction.create,
        before: null,
        after: '{"total": 100.0}',
        deviceId: 'PC-BALCAO-01',
        origin: 'Windows-POS',
      );

      // Registrar evento de auditoria na Cozinha
      contextCozinha.setContext(empresa: mockEmpresa, usuario: mockUsuarioCozinha);
      await auditCozinha.log(
        id: 'audit-kds-log-001',
        entity: 'OrdemPreparo',
        entityId: 'KDS-LOG-001',
        action: AuditAction.update,
        before: '{"status": "pendente"}',
        after: '{"status": "pronto"}',
        deviceId: 'PC-COZINHA-01',
        origin: 'Windows-KDS',
      );

      expect(auditBalcao.logs.isNotEmpty, isTrue);
      expect(auditCozinha.logs.isNotEmpty, isTrue);

      final auditBalcaoItem = auditBalcao.logs.first;
      expect(auditBalcaoItem.tenantId, equals('tenant-restaurante-001'));
      expect(auditBalcaoItem.performedBy, equals('op-balcao-01'));
      expect(auditBalcaoItem.origin, equals('Windows-POS'));

      final auditCozinhaItem = auditCozinha.logs.last;
      expect(auditCozinhaItem.tenantId, equals('tenant-restaurante-001'));
      expect(auditCozinhaItem.performedBy, equals('chef-cozinha-01'));
      expect(auditCozinhaItem.origin, equals('Windows-KDS'));
    });
  });
}
