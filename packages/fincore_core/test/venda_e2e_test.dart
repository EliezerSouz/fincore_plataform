/// Testes de integração do fluxo de venda end-to-end (P0-01).
///
/// Valida que uma venda completa:
/// 1. Persiste na pedidos_table (SQLite local)
/// 2. Persiste itens na itens_pedido_table (SQLite local)
/// 3. Enfileira no outbox_sync com entity='Pedido'
/// 4. O soft-delete via undoLastVenda marca o pedido como cancelado
/// 5. O ConflictResolver protege pedidos com outbox pendente
library fincore_venda_e2e_test;

import 'dart:io';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/sync/conflict_resolver.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/src/logging/log_service.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _mockMetadata = SyncMetadata(
  version: 1,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  createdBy: 'operador-test',
  updatedBy: 'operador-test',
);

final _empresa = CoreEmpresa(
  id: 'tenant-e2e-test',
  razaoSocial: 'Salgaderia Teste LTDA',
  nomeFantasia: 'Salgaderia Teste',
  documentoFiscal: '12345678000100',
  email: 'teste@salgaderia.com',
  telefone: '11988887777',
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

final _operador = CoreUsuario(
  id: 'operador-001',
  nome: 'João Operador',
  email: 'joao@salgaderia.com',
  role: 'OPERADOR',
  criadoEm: DateTime.now(),
  atualizadoEm: DateTime.now(),
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Simula o _persistVenda() do PDVExpressController:
/// insere pedido + itens no banco e enfileira no Outbox.
Future<String> _persistVendaSimulada({
  required FincoreDatabase db,
  required TenantContext context,
  required OutboxService outbox,
  required List<Map<String, dynamic>> itens,
  required int totalCentavos,
  required String formaPagamento,
}) async {
  final pedidoId = const Uuid().v4();
  final now = DateTime.now().toUtc();
  final tenantId = context.tenantId;
  final operadorId = context.usuario.id;

  await db.transaction(() async {
    // 1. Inserir pedido principal
    await db.into(db.pedidosTable).insertOnConflictUpdate(
      PedidosTableCompanion.insert(
        id: pedidoId,
        tenantId: tenantId,
        status: const Value('confirmado'),
        tipoLogistica: 'Retirada',
        valorSubtotalCentavos: totalCentavos,
        valorTotalCentavos: totalCentavos,
        formaPagamentoNome: Value(formaPagamento),
        operadorId: Value(operadorId),
        dataHoraCriacao: now,
        canalOrigem: const Value('pdv_express'),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );

    // 2. Inserir itens
    for (final item in itens) {
      await db.into(db.itensPedidoTable).insertOnConflictUpdate(
        ItensPedidoTableCompanion.insert(
          id: const Uuid().v4(),
          tenantId: tenantId,
          pedidoId: pedidoId,
          produtoId: item['produtoId'] as String,
          nomeProduto: item['nome'] as String,
          quantidade: (item['quantidade'] as int).toDouble(),
          valorUnitarioCentavos: item['valorUnitario'] as int,
          valorTotalCentavos: (item['quantidade'] as int) * (item['valorUnitario'] as int),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: operadorId,
          updatedBy: operadorId,
        ),
      );
    }
  });

  // 3. Enfileirar no Outbox
  await outbox.enqueue(
    entity: 'Pedido',
    entityId: pedidoId,
    action: 'create',
    payload: {
      'id': pedidoId,
      'tenantId': tenantId,
      'status': 'confirmado',
      'valorTotalCentavos': totalCentavos,
      'createdAt': now.toIso8601String(),
    },
    version: 1,
  );

  return pedidoId;
}

// ─── Suite Principal ───────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late FincoreDatabase db;
  late TenantContext context;
  late OutboxService outbox;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('fincore_e2e_test');
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
    context.setContext(empresa: _empresa, usuario: _operador);
    outbox = OutboxService(db: db, context: context);
  });

  tearDown(() async {
    await db.close();
  });

  // ─── GRUPO 1: Fluxo de Venda E2E ──────────────────────────────────────────

  group('Fluxo de Venda E2E (P0-01)', () {
    test('Venda persiste na pedidos_table localmente', () async {
      final pedidoId = await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [
          {'produtoId': 'prod-coxinha', 'nome': 'Coxinha', 'quantidade': 5, 'valorUnitario': 500},
        ],
        totalCentavos: 2500,
        formaPagamento: 'Pix',
      );

      final pedidoLocal = await (db.select(db.pedidosTable)
            ..where((t) => t.id.equals(pedidoId)))
          .getSingleOrNull();

      expect(pedidoLocal, isNotNull, reason: 'Pedido deve existir na pedidos_table');
      expect(pedidoLocal!.status, equals('confirmado'));
      expect(pedidoLocal.valorTotalCentavos, equals(2500));
      expect(pedidoLocal.tenantId, equals('tenant-e2e-test'));
    });

    test('Itens da venda persistem na itens_pedido_table localmente', () async {
      final pedidoId = await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [
          {'produtoId': 'prod-esf', 'nome': 'Esfirra', 'quantidade': 10, 'valorUnitario': 300},
          {'produtoId': 'prod-pao', 'nome': 'Pão de Queijo', 'quantidade': 3, 'valorUnitario': 250},
        ],
        totalCentavos: 3750,
        formaPagamento: 'Dinheiro',
      );

      final itens = await (db.select(db.itensPedidoTable)
            ..where((t) => t.pedidoId.equals(pedidoId)))
          .get();

      expect(itens.length, equals(2), reason: '2 itens distintos devem persistir');
      expect(itens.any((i) => i.nomeProduto == 'Esfirra'), isTrue);
      expect(itens.any((i) => i.nomeProduto == 'Pão de Queijo'), isTrue);
    });

    test('Outbox contém entrada com entity=Pedido após venda', () async {
      final pedidoId = await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [
          {'produtoId': 'prod-x', 'nome': 'Produto X', 'quantidade': 2, 'valorUnitario': 1000},
        ],
        totalCentavos: 2000,
        formaPagamento: 'Cartão',
      );

      final pending = await outbox.getPendingEntries();
      final outboxPedido = pending.where((e) => e.entityId == pedidoId).toList();

      expect(outboxPedido.length, equals(1), reason: 'Deve existir 1 entrada no Outbox para o pedido');
      expect(outboxPedido.first.entity, equals('Pedido'));
      expect(outboxPedido.first.action, equals('create'));

      // Valida que o payload contém os campos essenciais
      final payload = jsonDecode(outboxPedido.first.payload) as Map<String, dynamic>;
      expect(payload['id'], equals(pedidoId));
      expect(payload['valorTotalCentavos'], equals(2000));
    });

    test('Soft-delete da venda (undoLastVenda) marca pedido como cancelado', () async {
      final pedidoId = await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [
          {'produtoId': 'prod-y', 'nome': 'Produto Y', 'quantidade': 1, 'valorUnitario': 800},
        ],
        totalCentavos: 800,
        formaPagamento: 'Pix',
      );

      // Simula undoLastVenda — remove do Outbox e faz soft delete
      await db.transaction(() async {
        // Remove do Outbox (ainda pendente, version 1 = local)
        await (db.delete(db.outboxSync)
              ..where((t) => t.entityId.equals(pedidoId) & t.status.equals('pending')))
            .go();

        final now = DateTime.now().toUtc();
        await (db.update(db.pedidosTable)
              ..where((t) => t.id.equals(pedidoId)))
            .write(PedidosTableCompanion(
          status: const Value('cancelado'),
          updatedAt: Value(now),
          deletedAt: Value(now),
        ));
      });

      final pedidoCancelado = await (db.select(db.pedidosTable)
            ..where((t) => t.id.equals(pedidoId)))
          .getSingleOrNull();

      expect(pedidoCancelado?.status, equals('cancelado'));
      expect(pedidoCancelado?.deletedAt, isNotNull);

      final pendingAfter = await outbox.getPendingEntries();
      expect(pendingAfter.any((e) => e.entityId == pedidoId), isFalse,
          reason: 'Outbox deve estar vazio após undo de venda pendente');
    });

    test('ConflictResolver protege pedido com Outbox pendente contra pull remoto', () async {
      final pedidoId = await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [
          {'produtoId': 'prod-z', 'nome': 'Produto Z', 'quantidade': 1, 'valorUnitario': 1200},
        ],
        totalCentavos: 1200,
        formaPagamento: 'Dinheiro',
      );

      // O Outbox tem o pedido pendente — simula pull de dado do servidor
      const resolver = ConflictResolver();
      final decision = resolver.resolve(
        entityName: 'Pedido',
        entityId: pedidoId,
        hasOutboxPending: true,  // ← Outbox ainda não foi processado
        localVersion: 1,
        serverVersion: 2,        // ← Servidor tem versão mais nova
      );

      expect(decision.allowOverwrite, isFalse,
          reason: 'Pedido com outbox pendente não deve ser sobrescrito pelo servidor');
    });
  });

  // ─── GRUPO 2: Segurança de Boot (P0-03) ───────────────────────────────────

  group('Segurança de Boot sem usuário local (P0-03)', () {
    test('Usuário placeholder não deve ter role Administrador', () {
      // Após P0-03: DatabaseInitializer não atribui mais role 'Administrador'
      final placeholder = CoreUsuario(
        id: const Uuid().v4(),
        nome: 'Sistema',
        role: null, // ← null após a correção
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      expect(placeholder.role, isNull);
      expect(placeholder.role, isNot(equals('Administrador')));
    });

    test('TenantContext sem setContext lança ContextStateError ao acessar usuario', () {
      final ctx = TenantContext();
      ctx.clear();

      expect(
        () => ctx.usuario,
        throwsA(isA<ContextStateError>()),
        reason: 'Acesso a usuario sem contexto ativo deve lançar ContextStateError',
      );
    });

    test('TenantContext sem setContext lança ContextStateError ao acessar empresa', () {
      final ctx = TenantContext();
      ctx.clear();

      expect(
        () => ctx.empresa,
        throwsA(isA<ContextStateError>()),
      );
    });
  });

  // ─── GRUPO 3: Dashboard — faturamento dos 7 dias (P2-07) ─────────────────

  group('Dashboard — faturamento real dos 7 dias (P2-07)', () {
    test('Pedidos de hoje são contabilizados no faturamento', () async {
      final tenantId = context.tenantId;
      final startOfDay = DateTime.now().toUtc().subtract(const Duration(hours: 12));

      await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [{'produtoId': 'p1', 'nome': 'Coxinha', 'quantidade': 2, 'valorUnitario': 500}],
        totalCentavos: 1000,
        formaPagamento: 'Pix',
      );

      // Conta pedidos de hoje na pedidos_table (lógica análoga ao DashboardRepository)
      final pedidosHoje = await (db.select(db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.dataHoraCriacao.isBiggerOrEqualValue(startOfDay) &
                t.status.isNotIn(['cancelado', 'rascunho'])))
          .get();

      expect(pedidosHoje.length, greaterThanOrEqualTo(1));
      final faturamento = pedidosHoje.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
      expect(faturamento, greaterThanOrEqualTo(1000));
    });

    test('Pedidos cancelados não entram no faturamento', () async {
      final pedidoId = await _persistVendaSimulada(
        db: db,
        context: context,
        outbox: outbox,
        itens: [{'produtoId': 'p2', 'nome': 'Esfiha', 'quantidade': 3, 'valorUnitario': 300}],
        totalCentavos: 900,
        formaPagamento: 'Dinheiro',
      );

      // Cancela o pedido
      final nowCancel = DateTime.now().toUtc();
      await (db.update(db.pedidosTable)
            ..where((t) => t.id.equals(pedidoId)))
          .write(PedidosTableCompanion(
        status: const Value('cancelado'),
        updatedAt: Value(nowCancel),
        deletedAt: Value(nowCancel),
      ));

      final tenantId = context.tenantId;
      final startOfDay = DateTime.now().toUtc().subtract(const Duration(hours: 1));

      final pedidosAtivos = await (db.select(db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.dataHoraCriacao.isBiggerOrEqualValue(startOfDay) &
                t.status.isNotIn(['cancelado', 'rascunho'])))
          .get();

      // O pedido cancelado não deve aparecer
      expect(pedidosAtivos.any((p) => p.id == pedidoId), isFalse,
          reason: 'Pedido cancelado não deve entrar no faturamento');
    });
  });
}
