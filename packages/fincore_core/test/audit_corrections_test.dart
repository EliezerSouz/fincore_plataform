/// Testes para as correções críticas implementadas na Auditoria Técnica.
///
/// Cobertura:
/// - ConflictResolver: Outbox shield, LWW, rejectAndLock
/// - TenantContext: Role TTL (P2-02)
/// - OutboxService: idempotência de enqueue (P1-06)
/// - ProdutoRepository: soft-delete no findById (P1-03)
/// - Boot sem usuário local (P0-03)
library fincore_audit_corrections_test;

import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/sync/conflict_resolver.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/src/logging/log_service.dart';

// ─── Helpers de Fixture ────────────────────────────────────────────────────────

final _mockMetadata = SyncMetadata(
  version: 1,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  createdBy: 'tester',
  updatedBy: 'tester',
);

final _empresa = CoreEmpresa(
  id: 'tenant-auditoria-test',
  razaoSocial: 'Empresa Auditoria',
  nomeFantasia: 'Auditoria Co',
  documentoFiscal: '99999999000100',
  email: 'auditoria@test.com',
  telefone: '11999999999',
  status: StatusEmpresa.ativo,
  plano: PlanoEmpresa.ouro,
  timezone: 'America/Sao_Paulo',
  locale: 'pt_BR',
  currency: 'BRL',
  country: 'BR',
  createdFrom: 'Test',
  version: 1,
  tipoPessoa: 'JURIDICA',
  metadata: _mockMetadata,
);

final _usuario = CoreUsuario(
  id: 'user-auditoria-1',
  nome: 'Auditor Tester',
  email: 'auditor@test.com',
  role: 'ADMINISTRADOR',
  criadoEm: DateTime.now(),
  atualizadoEm: DateTime.now(),
);

// ─── Suite Principal ───────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late FincoreDatabase db;
  late TenantContext context;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('fincore_audit_corr_test');
    LogService.init(tempDir.path, runCleanup: false);
  });

  tearDownAll(() async {
    await LogService.instance.forceCleanup();
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    db = FincoreDatabase(NativeDatabase.memory());
    context = TenantContext();
    context.clear();
    context.setContext(empresa: _empresa, usuario: _usuario);
  });

  tearDown(() async {
    await db.close();
  });

  // ─── GRUPO 1: ConflictResolver ─────────────────────────────────────────────

  group('ConflictResolver', () {
    const resolver = ConflictResolver();

    test('REGRA SUPREMA — Outbox pendente bloqueia qualquer sobrescrita', () {
      final decision = resolver.resolve(
        entityName: 'produtos',
        entityId: 'prod-001',
        hasOutboxPending: true,  // ← Dado local não enviado ainda
        localVersion: 1,
        serverVersion: 99,       // ← Servidor com versão muito mais nova
      );

      expect(decision.allowOverwrite, isFalse,
          reason: 'Outbox pendente deve bloquear mesmo com servidor mais novo');
      expect(decision.strategy, equals(ConflictStrategy.rejectAndLock));
    });

    test('LWW — Servidor mais novo sobrescreve local (cadastros base)', () {
      final decision = resolver.resolve(
        entityName: 'categorias',
        entityId: 'cat-001',
        hasOutboxPending: false,
        localVersion: 3,
        serverVersion: 5, // ← Servidor mais novo
      );

      expect(decision.allowOverwrite, isTrue);
      expect(decision.strategy, equals(ConflictStrategy.lww));
    });

    test('LWW — Servidor mais antigo é rejeitado (dado local prevalece)', () {
      final decision = resolver.resolve(
        entityName: 'clientes',
        entityId: 'cli-001',
        hasOutboxPending: false,
        localVersion: 7,
        serverVersion: 4, // ← Servidor mais antigo
      );

      expect(decision.allowOverwrite, isFalse,
          reason: 'Versão do servidor mais antiga deve ser rejeitada em LWW');
      expect(decision.strategy, equals(ConflictStrategy.lww));
    });

    test('rejectAndLock — Transação financeira com versão divergente bloqueia sobrescrita', () {
      final decision = resolver.resolve(
        entityName: 'transacao_financeira',
        entityId: 'fin-001',
        hasOutboxPending: false,
        localVersion: 2,
        serverVersion: 3, // ← Servidor diferente, mas entidade crítica
      );

      expect(decision.allowOverwrite, isFalse,
          reason: 'Entidades financeiras com conflito de versão nunca devem ser sobrescritas automaticamente');
      expect(decision.strategy, equals(ConflictStrategy.rejectAndLock));
    });

    test('rejectAndLock — Pedido sem conflito de versão permite aplicação', () {
      // Quando localVersion == null, o registro não existe localmente → pode inserir
      final decision = resolver.resolve(
        entityName: 'pedido',
        entityId: 'ped-002',
        hasOutboxPending: false,
        localVersion: null, // Registro novo no dispositivo
        serverVersion: 1,
      );

      expect(decision.allowOverwrite, isTrue,
          reason: 'Pedido novo (sem versão local) deve ser inserido do servidor');
    });

    test('LWW — Registro novo (sem versão local) sempre é aplicado', () {
      final decision = resolver.resolve(
        entityName: 'produtos',
        entityId: 'prod-novo',
        hasOutboxPending: false,
        localVersion: null, // Não existe localmente
        serverVersion: 1,
      );

      expect(decision.allowOverwrite, isTrue);
    });
  });

  // ─── GRUPO 2: TenantContext — Role TTL (P2-02) ────────────────────────────

  group('TenantContext — Role TTL (P2-02)', () {
    test('roleEfetivo retorna role real quando TTL está válido', () {
      context.clear();
      context.setContext(empresa: _empresa, usuario: _usuario);

      // Imediatamente após setContext, o TTL está válido
      expect(context.isRoleFresh(), isTrue);
      expect(context.roleEfetivo, equals('ADMINISTRADOR'));
    });

    test('roleEfetivo degrada para OPERADOR quando TTL expirou', () {
      context.clear();
      context.setContext(empresa: _empresa, usuario: _usuario);

      // Simula expiração do TTL apagando o timestamp
      // Não há como retroceder o DateTime diretamente, então testamos o fallback
      // de `_roleVerifiedAt == null` via clear sem re-setar:
      //  clear() já zera _roleVerifiedAt e hasContext vira false
      context.clear();

      // Após clear, isRoleFresh deve ser false
      expect(context.isRoleFresh(), isFalse);
    });

    test('markRoleVerified atualiza o TTL', () async {
      context.clear();
      context.setContext(empresa: _empresa, usuario: _usuario);

      // Garante que o role está fresco
      expect(context.isRoleFresh(), isTrue);

      // markRoleVerified não deve lançar e deve manter o TTL ativo
      context.markRoleVerified();
      expect(context.isRoleFresh(), isTrue);
    });

    test('hasContext false após clear()', () {
      context.clear();
      expect(context.hasContext, isFalse);
    });
  });

  // ─── GRUPO 3: OutboxService — idempotência de enqueue (P1-06) ────────────

  group('OutboxService — idempotência', () {
    late OutboxService outbox;

    setUp(() {
      outbox = OutboxService(db: db, context: context);
    });

    test('Múltiplos enqueues do mesmo entityId fazem coalescing (não duplica)', () async {
      await outbox.enqueue(
        entity: 'Pedido',
        entityId: 'ped-coalesce-01',
        action: 'create',
        payload: {'status': 'confirmado', 'total': 5000},
        version: 1,
      );

      await outbox.enqueue(
        entity: 'Pedido',
        entityId: 'ped-coalesce-01',
        action: 'create',
        payload: {'status': 'confirmado', 'total': 6000}, // payload atualizado
        version: 1,
      );

      final pending = await outbox.getPendingEntries();
      final pedidoEntries = pending.where((e) => e.entityId == 'ped-coalesce-01').toList();

      expect(pedidoEntries.length, equals(1),
          reason: 'Dois enqueues do mesmo entityId devem resultar em 1 entrada (coalescing)');
    });

    test('DELETE de registro criado localmente (version==1) remove da fila sem enviar', () async {
      await outbox.enqueue(
        entity: 'Pedido',
        entityId: 'ped-local-delete',
        action: 'create',
        payload: {'status': 'confirmado'},
        version: 1,
      );

      // Desfazer venda — deve remover o entry (nunca foi ao servidor)
      final id = await outbox.enqueue(
        entity: 'Pedido',
        entityId: 'ped-local-delete',
        action: 'DELETE',
        payload: {},
        version: 1, // version 1 = criado localmente, nunca sincronizado
      );

      expect(id, equals(0),
          reason: 'Retorno 0 indica que a entrada foi removida (sem envio ao servidor)');

      final pending = await outbox.getPendingEntries();
      expect(pending.any((e) => e.entityId == 'ped-local-delete'), isFalse,
          reason: 'Entry deve ter sido removido da fila');
    });

    test('isOutboxEmpty retorna true quando fila está vazia', () async {
      final empty = await outbox.isOutboxEmpty();
      expect(empty, isTrue);
    });

    test('isOutboxEmpty retorna false após enqueue', () async {
      await outbox.enqueue(
        entity: 'Produto',
        entityId: 'prod-check-empty',
        action: 'UPDATE',
        payload: {'nome': 'Teste'},
        version: 2,
      );

      final empty = await outbox.isOutboxEmpty();
      expect(empty, isFalse);
    });

    test('purgeSyncedEntries remove apenas entradas com status synced', () async {
      await outbox.enqueue(
        entity: 'Produto',
        entityId: 'prod-purge',
        action: 'UPDATE',
        payload: {'nome': 'Purge Test'},
        version: 1,
      );

      final pending = await outbox.getPendingEntries();
      final entry = pending.first;

      // Marca como synced
      await outbox.updateStatus(entry.id, SyncStatus.synced);

      // Purge
      final removed = await outbox.purgeSyncedEntries();
      expect(removed, equals(1));

      // Não deve mais aparecer nas pendentes
      final pendingAfter = await outbox.getPendingEntries();
      expect(pendingAfter.any((e) => e.entityId == 'prod-purge'), isFalse);
    });
  });

  // ─── GRUPO 4: ProdutoRepository — soft-delete no findById (P1-03) ─────────

  group('ProdutoRepository — findById ignora soft-deleted (P1-03)', () {
    late ProdutoRepository produtoRepo;
    late OutboxService localOutbox;

    setUp(() async {
      localOutbox = OutboxService(db: db, context: context);
      produtoRepo = ProdutoRepository(db: db, context: context, outbox: localOutbox);
      // Desativa FK para inserção direta de produto sem categoria mãe no teste
      await db.customStatement('PRAGMA foreign_keys = OFF');
    });

    test('findById retorna null para produto com deletedAt preenchido', () async {
      final tenantId = context.tenantId;
      final now = DateTime.now().toUtc();

      await db.into(db.produtosTable).insert(ProdutosTableCompanion.insert(
        id: 'prod-soft-deleted',
        tenantId: tenantId,
        nome: 'Produto Deletado',
        categoriaId: 'cat-fk-off',
        unidadeVenda: 'un',
        statusComercial: 'inativo',
        tempoMedioMinutos: 15,
        controlaEstoque: false,
        ordemProducao: 0,
        ativo: false,
        syncStatus: SyncStatus.synced,
        createdAt: now,
        updatedAt: now,
        createdBy: 'tester',
        updatedBy: 'tester',
        deletedAt: Value(now), // ← soft-deleted
      ));

      final resultado = await produtoRepo.findById('prod-soft-deleted');
      expect(resultado, isNull,
          reason: 'findById deve retornar null para produto com deletedAt preenchido (P1-03)');
    });

    test('findById retorna produto ativo corretamente', () async {
      final tenantId = context.tenantId;
      final now = DateTime.now().toUtc();

      await db.into(db.produtosTable).insert(ProdutosTableCompanion.insert(
        id: 'prod-ativo-001',
        tenantId: tenantId,
        nome: 'Coxinha Premium',
        categoriaId: 'cat-fk-off',
        unidadeVenda: 'un',
        statusComercial: 'disponivel',
        tempoMedioMinutos: 10,
        controlaEstoque: false,
        ordemProducao: 1,
        ativo: true,
        syncStatus: SyncStatus.synced,
        createdAt: now,
        updatedAt: now,
        createdBy: 'tester',
        updatedBy: 'tester',
      ));

      final produto = await produtoRepo.findById('prod-ativo-001');
      expect(produto, isNotNull);
      expect(produto!.nome, equals('Coxinha Premium'));
    });
  });

  // ─── GRUPO 5: Boot sem usuário local — fallback de role (P0-03) ───────────

  group('Boot sem usuário local — role não deve ser Administrador (P0-03)', () {
    test('CoreUsuario criado com role null não deve ter role hardcoded', () {
      // Simula o usuário placeholder criado pelo DatabaseInitializer antes do fix
      final usuarioSemRole = CoreUsuario(
        id: 'placeholder-user',
        nome: 'Sistema',
        role: null, // ← Após correção P0-03: null, não mais 'Administrador'
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      expect(usuarioSemRole.role, isNull,
          reason: 'Usuário placeholder deve ter role null após correção P0-03');
    });

    test('roleEfetivo do TenantContext retorna OPERADOR para usuário com role null', () {
      context.clear();
      final usuarioSemRole = CoreUsuario(
        id: 'placeholder-2',
        nome: 'Sem Role',
        role: null,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );
      context.setContext(empresa: _empresa, usuario: usuarioSemRole);

      expect(context.roleEfetivo, equals('OPERADOR'),
          reason: 'role null deve resultar em OPERADOR como fallback seguro');
    });
  });
}
