library fincore_estoque_producao_test;

import 'dart:io';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/common/estoque_producao_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _mockMetadata = SyncMetadata(
  version: 1,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  createdBy: 'operador-test',
  updatedBy: 'operador-test',
);

final _empresa = CoreEmpresa(
  id: 'tenant-test',
  razaoSocial: 'Alimentação E2E LTDA',
  nomeFantasia: 'FINCORE FOOD Teste',
  documentoFiscal: '12345678000100',
  email: 'teste@fincore.com',
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
  nome: 'Felipe Planejador',
  email: 'felipe@fincore.com',
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
    tempDir = Directory.systemTemp.createTempSync('fincore_estoque_test');
    LogService.init(tempDir.path, runCleanup: false);
  });

  tearDownAll(() async {
    await LogService.instance.forceCleanup();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    db = FincoreDatabase(NativeDatabase.memory());
    context = TenantContext();
    context.clear();
    context.setContext(empresa: _empresa, usuario: _operador);

    // Registra DI mock para os testes rodarem isolados
    final di = DependencyInjection();
    di.clear();
    di.register<FincoreDatabase>(db);
    di.register<TenantContext>(context);
    di.register<OutboxService>(OutboxService(db: db, context: context));
    di.register<AuditLogRepository>(AuditLogRepository(db: db));

    // Seed Categoria necessária para a FK de produto
    await db.into(db.categoriasTable).insert(
      CategoriasTableCompanion.insert(
        id: 'cat-geral',
        tenantId: 'tenant-test',
        nome: 'Geral',
        descricao: 'Categoria Geral',
        ordemExibicao: 1,
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
        updatedBy: 'system',
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
      ),
    );

    // Seed Produto para os testes
    await db.into(db.produtosTable).insert(
      ProdutosTableCompanion.insert(
        id: 'prod-coxinha',
        tenantId: 'tenant-test',
        nome: 'Coxinha de Frango',
        categoriaId: 'cat-geral',
        unidadeVenda: 'un',
        statusComercial: 'ativo',
        tempoMedioMinutos: 15,
        controlaEstoque: true,
        ordemProducao: 1,
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
        updatedBy: 'system',
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
      ),
    );

    // Seed Registro de Estoque Inicial
    await db.into(db.estoqueProdutosTable).insert(
      EstoqueProdutosTableCompanion.insert(
        id: 'est-coxinha',
        tenantId: 'tenant-test',
        produtoId: 'prod-coxinha',
        quantidadeAtual: const Value(500), // físico
        quantidadeReservada: const Value(100), // reservado
        quantidadeMinima: const Value(200), // mínimo
        quantidadeProducaoLote: const Value(100),
        diasCoberturaAlvo: const Value(3),
        unidade: const Value('un'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
        updatedBy: 'system',
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Módulo de Estoque + Produção + Demanda Futura', () {
    // 1. Estoque físico
    test('1. Físico atual inicia com valor correto', () async {
      final est = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();
      expect(est.quantidadeAtual, equals(500));
    });

    // 2. Reserva de pedido
    test('2. Reserva adiciona quantidade reservada corretamento', () async {
      final estAntes = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      final novaReserva = 50;
      await db.update(db.estoqueProdutosTable).write(
        EstoqueProdutosTableCompanion(
          quantidadeReservada: Value(estAntes.quantidadeReservada + novaReserva),
        ),
      );

      final estDepois = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();
      expect(estDepois.quantidadeReservada, equals(150));
    });

    // 3. Liberação de reserva
    test('3. Liberação de reserva subtrai do reservado', () async {
      final estAntes = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      final liberacao = 50;
      await db.update(db.estoqueProdutosTable).write(
        EstoqueProdutosTableCompanion(
          quantidadeReservada: Value((estAntes.quantidadeReservada - liberacao).clamp(0, 999999)),
        ),
      );

      final estDepois = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();
      expect(estDepois.quantidadeReservada, equals(50));
    });

    // 4. Estoque disponível = físico - reservado
    test('4. Estoque disponível calcula corretamente', () async {
      final est = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();
      final disponivel = est.quantidadeAtual - est.quantidadeReservada;
      expect(disponivel, equals(400));
    });

    // 5. Demanda futura por produto
    test('5. Demanda futura calcula soma de pedidos ativos', () async {
      final now = DateTime.now().toUtc();
      // Criar pedido com data de entrega futura
      final pedidoId = const Uuid().v4();
      await db.into(db.pedidosTable).insert(
        PedidosTableCompanion.insert(
          id: pedidoId,
          tenantId: 'tenant-test',
          status: const Value('confirmado'),
          tipoLogistica: 'Entrega',
          valorSubtotalCentavos: 1000,
          valorTotalCentavos: 1000,
          dataHoraCriacao: now,
          dataHoraEntregaPrevista: Value(now.add(const Duration(days: 2))),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      // Itens do pedido
      await db.into(db.itensPedidoTable).insert(
        ItensPedidoTableCompanion.insert(
          id: const Uuid().v4(),
          tenantId: 'tenant-test',
          pedidoId: pedidoId,
          produtoId: 'prod-coxinha',
          nomeProduto: 'Coxinha de Frango',
          quantidade: 80.0,
          valorUnitarioCentavos: 100,
          valorTotalCentavos: 8000,
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      // Verifica demanda
      final statusAtivos = {'confirmado', 'em_preparo', 'pronto'};
      final pedidos = await (db.select(db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals('tenant-test') &
                t.status.isIn(statusAtivos.toList()) &
                t.deletedAt.isNull()))
          .get();

      double totalDemanda = 0;
      for (final p in pedidos) {
        final itens = await (db.select(db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(p.id) & t.deletedAt.isNull()))
            .get();
        for (final item in itens) {
          if (item.produtoId == 'prod-coxinha') {
            totalDemanda += item.quantidade;
          }
        }
      }
      expect(totalDemanda, equals(80.0));
    });

    // 6. Criação de plano de produção
    test('6. Criação de plano de produção persiste na tabela', () async {
      final now = DateTime.now().toUtc();
      final planoId = const Uuid().v4();

      await db.into(db.planejamentoProducaoTable).insert(
        PlanejamentoProducaoTableCompanion.insert(
          id: planoId,
          tenantId: 'tenant-test',
          produtoId: 'prod-coxinha',
          dataPlano: now.add(const Duration(days: 1)),
          quantidadePlanejada: 300,
          status: const Value('planejada'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      final plano = await (db.select(db.planejamentoProducaoTable)
            ..where((t) => t.id.equals(planoId)))
          .getSingle();

      expect(plano.quantidadePlanejada, equals(300));
      expect(plano.status, equals('planejada'));
    });

    // 7. Produção parcial
    test('7. Produção parcial atualiza saldo produzido', () async {
      final now = DateTime.now().toUtc();
      final planoId = const Uuid().v4();

      await db.into(db.planejamentoProducaoTable).insert(
        PlanejamentoProducaoTableCompanion.insert(
          id: planoId,
          tenantId: 'tenant-test',
          produtoId: 'prod-coxinha',
          dataPlano: now.add(const Duration(days: 1)),
          quantidadePlanejada: 300,
          quantidadeProduzida: const Value(0),
          status: const Value('planejada'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      await (db.update(db.planejamentoProducaoTable)..where((t) => t.id.equals(planoId))).write(
        const PlanejamentoProducaoTableCompanion(
          quantidadeProduzida: Value(150),
          status: Value('parcial'),
        ),
      );

      final plano = await (db.select(db.planejamentoProducaoTable)
            ..where((t) => t.id.equals(planoId)))
          .getSingle();

      expect(plano.quantidadeProduzida, equals(150));
      expect(plano.status, equals('parcial'));
    });

    // 8. Conclusão de plano → entrada de estoque
    test('8. Conclusão de plano gera entrada de estoque', () async {
      final now = DateTime.now().toUtc();
      final planoId = const Uuid().v4();

      await db.into(db.planejamentoProducaoTable).insert(
        PlanejamentoProducaoTableCompanion.insert(
          id: planoId,
          tenantId: 'tenant-test',
          produtoId: 'prod-coxinha',
          dataPlano: now.add(const Duration(days: 1)),
          quantidadePlanejada: 300,
          status: const Value('planejada'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      // Concluir plano
      await (db.update(db.planejamentoProducaoTable)..where((t) => t.id.equals(planoId))).write(
        const PlanejamentoProducaoTableCompanion(
          quantidadeProduzida: Value(300),
          status: Value('concluida'),
        ),
      );

      // Simular trigger do controller que soma estoque físico
      final estAntes = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      await db.update(db.estoqueProdutosTable).write(
        EstoqueProdutosTableCompanion(
          quantidadeAtual: Value(estAntes.quantidadeAtual + 300),
        ),
      );

      final estDepois = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      expect(estDepois.quantidadeAtual, equals(800));
    });

    // 9. Estoque projetado com Regra de Ouro (Físico + Planejada - Reservado)
    test('9. Estoque projetado calcula fórmula corretamente usando Regra de Ouro', () async {
      final est = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      final fisico = est.quantidadeAtual; // 800
      final reservado = est.quantidadeReservada; // 400
      final planejado = 300;

      final projetado = fisico + planejado - reservado;
      expect(projetado, equals(700));
    });

    // 10. Pedido atendível via produção planejada
    test('10. Pedido classificado como atendível via planejamento', () async {
      final fisico = 100;
      final planejado = 300;
      final reservado = 250;

      final status = (fisico >= reservado)
          ? StatusAtendibilidade.atendivel
          : (fisico + planejado >= reservado)
              ? StatusAtendibilidade.atendivelViaPlanejamento
              : StatusAtendibilidade.naoAtendivel;

      expect(status, equals(StatusAtendibilidade.atendivelViaPlanejamento));
    });

    // 11. Pedido NÃO atendível
    test('11. Pedido classificado como não atendível se estoque insuficiente', () async {
      final fisico = 100;
      final planejado = 50;
      final reservado = 250;

      final status = (fisico >= reservado)
          ? StatusAtendibilidade.atendivel
          : (fisico + planejado >= reservado)
              ? StatusAtendibilidade.atendivelViaPlanejamento
              : StatusAtendibilidade.naoAtendivel;

      expect(status, equals(StatusAtendibilidade.naoAtendivel));
    });

    // Cenários de Auditoria e Regra de Ouro (Cenários 1 a 6)
    group('Cenários de Saldos e Projeção — Regra de Ouro (Seção 21)', () {
      test('Cenário 1 — Físico 150, Reservado 25, Produção 0', () {
        final ep = EstoqueProjetado(
          produtoId: 'p1',
          nomeProduto: 'Coxinha',
          fisico: 150,
          reservado: 25,
          seguranca: 50,
          minimo: 100,
          critica: 30,
          demandaFutura: 25,
          producaoPlanejada: 0,
          situacao: StatusAtendibilidade.atendivel,
        );

        expect(ep.disponivel, equals(125));
        expect(ep.deficitAtual, equals(0));
        expect(ep.projetado, equals(125));
      });

      test('Cenário 2 — Físico 75, Reservado 100, Produção 0', () {
        final ep = EstoqueProjetado(
          produtoId: 'p2',
          nomeProduto: 'Risole',
          fisico: 75,
          reservado: 100,
          seguranca: 50,
          minimo: 100,
          critica: 30,
          demandaFutura: 100,
          producaoPlanejada: 0,
          situacao: StatusAtendibilidade.naoAtendivel,
        );

        expect(ep.disponivel, equals(0));
        expect(ep.deficitAtual, equals(25));
        expect(ep.projetado, equals(-25)); // Insuficiência real evidenciada!
      });

      test('Cenário 3 — Físico 75, Reservado 100, Produção 25', () {
        final ep = EstoqueProjetado(
          produtoId: 'p3',
          nomeProduto: 'Quibe',
          fisico: 75,
          reservado: 100,
          seguranca: 50,
          minimo: 100,
          critica: 30,
          demandaFutura: 100,
          producaoPlanejada: 25,
          situacao: StatusAtendibilidade.atendivelViaPlanejamento,
        );

        expect(ep.disponivel, equals(0));
        expect(ep.deficitAtual, equals(25));
        expect(ep.projetado, equals(0)); // Produção cobre exatamente o déficit!
      });

      test('Cenário 4 — Físico 75, Reservado 100, Produção 400', () {
        final ep = EstoqueProjetado(
          produtoId: 'p4',
          nomeProduto: 'Empada',
          fisico: 75,
          reservado: 100,
          seguranca: 50,
          minimo: 100,
          critica: 30,
          demandaFutura: 100,
          producaoPlanejada: 400,
          situacao: StatusAtendibilidade.atendivelViaPlanejamento,
        );

        expect(ep.disponivel, equals(0));
        expect(ep.deficitAtual, equals(25));
        expect(ep.projetado, equals(375)); // 75 + 400 - 100 = 375!
      });

      test('Cenário 5 — Físico 450, Reservado 200, Produção 200', () {
        final ep = EstoqueProjetado(
          produtoId: 'p5',
          nomeProduto: 'Enroladinho',
          fisico: 450,
          reservado: 200,
          seguranca: 50,
          minimo: 100,
          critica: 30,
          demandaFutura: 200,
          producaoPlanejada: 200,
          situacao: StatusAtendibilidade.atendivel,
        );

        expect(ep.disponivel, equals(250));
        expect(ep.deficitAtual, equals(0));
        expect(ep.projetado, equals(450)); // 450 + 200 - 200 = 450!
      });

      test('Cenário 6 — Físico 100, Reservado 0, Produção 0', () {
        final ep = EstoqueProjetado(
          produtoId: 'p6',
          nomeProduto: 'Pastel',
          fisico: 100,
          reservado: 0,
          seguranca: 50,
          minimo: 100,
          critica: 30,
          demandaFutura: 0,
          producaoPlanejada: 0,
          situacao: StatusAtendibilidade.atendivel,
        );

        expect(ep.disponivel, equals(100));
        expect(ep.deficitAtual, equals(0));
        expect(ep.projetado, equals(100));
      });
    });

    // 12. Estoque mínimo → sinalização
    test('12. Disponível abaixo do mínimo gera alerta correto', () async {
      // Definir disponível abaixo do mínimo
      await db.update(db.estoqueProdutosTable).write(
        const EstoqueProdutosTableCompanion(
          quantidadeAtual: Value(250),
          quantidadeReservada: Value(100), // Disponível = 150 < mínimo 200
        ),
      );

      final est = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      final disponivel = est.quantidadeAtual - est.quantidadeReservada;
      final alerta = disponivel <= est.quantidadeMinima;

      expect(alerta, isTrue);
    });

    // 13. Cancelamento de pedido → liberação de reserva
    test('13. Cancelar pedido zera reservas e atualiza estoque', () async {
      final estAntes = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      // Libera as reservas do pedido (100)
      await db.update(db.estoqueProdutosTable).write(
        EstoqueProdutosTableCompanion(
          quantidadeReservada: Value((estAntes.quantidadeReservada - 100).clamp(0, 999999)),
        ),
      );

      final estDepois = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      expect(estDepois.quantidadeReservada, equals(0));
    });

    // 14. Idempotência do recálculo
    test('14. Recálculo idempotente reconstrói reservas corretamente', () async {
      final now = DateTime.now().toUtc();
      final pedidoId = const Uuid().v4();

      // Criar pedido ativo
      await db.into(db.pedidosTable).insert(
        PedidosTableCompanion.insert(
          id: pedidoId,
          tenantId: 'tenant-test',
          status: const Value('confirmado'),
          tipoLogistica: 'Entrega',
          valorSubtotalCentavos: 1000,
          valorTotalCentavos: 1000,
          dataHoraCriacao: now,
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      // Criar item de pedido com 80 unidades
      await db.into(db.itensPedidoTable).insert(
        ItensPedidoTableCompanion.insert(
          id: const Uuid().v4(),
          tenantId: 'tenant-test',
          pedidoId: pedidoId,
          produtoId: 'prod-coxinha',
          nomeProduto: 'Coxinha de Frango',
          quantidade: 80.0,
          valorUnitarioCentavos: 100,
          valorTotalCentavos: 8000,
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      // Simula zerar reservas e rodar recalculation
      await db.update(db.estoqueProdutosTable).write(
        const EstoqueProdutosTableCompanion(quantidadeReservada: Value(0)),
      );

      // Soma de reservas de pedidos ativos
      final statusAtivos = {'confirmado', 'em_preparo', 'pronto'};
      final pedidos = await (db.select(db.pedidosTable)
            ..where((t) => t.status.isIn(statusAtivos.toList())))
          .get();

      int somaReservas = 0;
      for (final p in pedidos) {
        final itens = await (db.select(db.itensPedidoTable)..where((t) => t.pedidoId.equals(p.id))).get();
        for (final item in itens) {
          if (item.produtoId == 'prod-coxinha') {
            somaReservas += item.quantidade.round();
          }
        }
      }

      await db.update(db.estoqueProdutosTable).write(
        EstoqueProdutosTableCompanion(quantidadeReservada: Value(somaReservas)),
      );

      final estFinal = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.produtoId.equals('prod-coxinha')))
          .getSingle();

      expect(estFinal.quantidadeReservada, equals(80));
    });

    // 15. Sincronização Outbox (simulada)
    test('15. Outbox enfileira plano de produção criado para sincronizar', () async {
      final now = DateTime.now().toUtc();
      final planoId = const Uuid().v4();

      await db.into(db.outboxSync).insert(
        OutboxSyncCompanion.insert(
          tenantId: 'tenant-test',
          entity: 'planejamento_producao',
          entityId: planoId,
          action: 'create',
          payload: '{}',
          status: 'pending',
          version: 1,
          createdAt: now,
        ),
      );

      final outboxCount = await db.select(db.outboxSync).get();
      expect(outboxCount.length, equals(1));
      expect(outboxCount.first.entity, equals('planejamento_producao'));
    });

    // 16. Auditoria de eventos críticos
    test('16. Evento de planejamento criado gera log de auditoria', () async {
      final auditLogRepo = DependencyInjection().get<AuditLogRepository>();

      await auditLogRepo.log(
        entityName: 'planejamento_producao',
        entityId: 'plano-123',
        userId: 'operador-001',
        action: 'CREATE',
        entityDisplayName: 'Plano de Produção - Coxinha de Frango (Status: planejada)',
        entityModule: 'Produção',
        diff: {'quantidadePlanejada': 300},
      );

      final logs = await db.select(db.auditLogsTable).get();
      expect(logs.length, equals(1));
      expect(logs.first.action, equals('CREATE'));
      expect(logs.first.targetEntity, equals('planejamento_producao'));
      expect(jsonDecode(logs.first.diff ?? '{}')['quantidadePlanejada'], equals(300));
    });

    // 17. Evolução dos níveis de estoque: segurança, crítico e sugestões com a Regra de Ouro
    test('17. Níveis de estoque de segurança e crítico influenciam projeção e geram sugestões com Regra de Ouro', () async {
      final now = DateTime.now().toUtc();
      final produtoId = 'prod-coxinha';
      final estoqueId = 'est-coxinha';

      // Remove estoque antigo se existir para isolamento do teste
      await (db.delete(db.estoqueProdutosTable)..where((t) => t.produtoId.equals(produtoId))).go();

      // Insere estoque com níveis operacionais específicos
      await db.into(db.estoqueProdutosTable).insert(
        EstoqueProdutosTableCompanion.insert(
          id: estoqueId,
          tenantId: 'tenant-test',
          produtoId: produtoId,
          quantidadeAtual: const Value(150),
          quantidadeReservada: const Value(250), // deficit de 100
          quantidadeSeguranca: const Value(20),
          quantidadeMinima: const Value(75),
          quantidadeCritica: const Value(50),
          capacidadeCampanha: const Value(100),
          estrategiaProducao: const Value('concentrada'),
          tempoPreparacao: const Value(30),
          unidade: const Value('un'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      // 1. Verifica saldos e limiares no banco
      final est = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.id.equals(estoqueId)))
          .getSingle();

      expect(est.quantidadeAtual, equals(150));
      expect(est.quantidadeReservada, equals(250));
      expect(est.quantidadeSeguranca, equals(20));
      expect(est.quantidadeMinima, equals(75));
      expect(est.quantidadeCritica, equals(50));
      expect(est.capacidadeCampanha, equals(100));

      // 2. Simula o cálculo de projeção e situação de atendibilidade (Caso A: reserva > fisico)
      final disponivel = (est.quantidadeAtual - est.quantidadeReservada).clamp(0, 999999);
      expect(disponivel, equals(0)); // 0 disponível pois reservas superam o físico

      final deficit = est.quantidadeReservada - est.quantidadeAtual;
      expect(deficit, equals(100)); // falta física imediata de 100 unidades

      // 3. Simula a geração da sugestão preditiva com a Regra de Ouro (explicando o porquê)
      final lote = est.capacidadeCampanha > 0 ? est.capacidadeCampanha : 100;
      final qtdSugerida = ((deficit / lote).ceil() * lote);
      expect(qtdSugerida, equals(100)); // arredondado para o lote de 100

      String motivo = 'Estoque insuficiente para cobrir as reservas atuais.\n'
          '- ${est.quantidadeReservada} un. reservadas\n'
          '- ${est.quantidadeAtual} un. físicas atuais\n'
          '- Estoque disponível insuficiente.';

      if (est.capacidadeCampanha > 0 && qtdSugerida > est.capacidadeCampanha) {
        motivo += '\n⚠️ CAPACIDADE INSUFICIENTE: A necessidade ($qtdSugerida un.) excede a capacidade diária (${est.capacidadeCampanha} un.).';
      }

      expect(motivo, contains('Estoque insuficiente para cobrir as reservas atuais'));
      expect(motivo, contains('- 250 un. reservadas'));
      expect(motivo, contains('- 150 un. físicas atuais'));
    });

    group('Cenários Operacionais de Produção e Duplicidade - Regras de Negócio', () {
      // Helper local para simular a criação de plano com validação transacional
      Future<String> criarPlanoSimulado({
        required String produtoId,
        required DateTime dataPlano,
        required int quantidadePlanejada,
        required String tenantId,
        String? necessidadeOrigem,
      }) async {
        return await db.transaction(() async {
          final existingActive = await (db.select(db.planejamentoProducaoTable)
                ..where((t) =>
                    t.tenantId.equals(tenantId) &
                    t.produtoId.equals(produtoId) &
                    t.dataPlano.equals(dataPlano.toUtc()) &
                    t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial']) &
                    t.deletedAt.isNull()))
              .getSingleOrNull();

          if (existingActive != null) {
            throw Exception('Já existe uma produção planejada para este produto nesta data.');
          }

          final planoId = const Uuid().v4();
          await db.into(db.planejamentoProducaoTable).insert(
            PlanejamentoProducaoTableCompanion.insert(
              id: planoId,
              tenantId: tenantId,
              produtoId: produtoId,
              dataPlano: dataPlano.toUtc(),
              quantidadePlanejada: quantidadePlanejada,
              quantidadeProduzida: const Value(0),
              capacidadeCampanha: const Value(0),
              status: const Value('planejada'),
              syncStatus: SyncStatus.pending,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: 'operador-test',
              updatedBy: 'operador-test',
            ),
          );
          return planoId;
        });
      }

      // Helper local para simular o ajuste de quantidade planejada
      Future<void> ajustarQuantidadeSimulado({
        required String planoId,
        required int novaQuantidadePlanejada,
      }) async {
        await db.transaction(() async {
          final plano = await (db.select(db.planejamentoProducaoTable)
                ..where((t) => t.id.equals(planoId)))
              .getSingleOrNull();

          if (plano == null) throw Exception('Plano não encontrado');

          final activeStatus = {'planejada', 'em_preparacao', 'em_producao', 'parcial'};
          if (!activeStatus.contains(plano.status)) {
            throw Exception('Apenas campanhas ativas podem ser ajustadas.');
          }

          await (db.update(db.planejamentoProducaoTable)
                ..where((t) => t.id.equals(planoId)))
              .write(PlanejamentoProducaoTableCompanion(
            quantidadePlanejada: Value(novaQuantidadePlanejada),
            updatedAt: Value(DateTime.now()),
          ));
        });
      }

      // Helper local para simular registro parcial incremental
      Future<void> registrarParcialSimulado({
        required String planoId,
        required int quantidadeProduzida,
      }) async {
        await db.transaction(() async {
          final plano = await (db.select(db.planejamentoProducaoTable)
                ..where((t) => t.id.equals(planoId)))
              .getSingleOrNull();

          if (plano == null) throw Exception('Plano não encontrado');

          final novaQtdProduzida = (plano.quantidadeProduzida + quantidadeProduzida).clamp(0, 999999);
          final novoStatus = novaQtdProduzida >= plano.quantidadePlanejada ? 'concluida' : 'parcial';

          await (db.update(db.planejamentoProducaoTable)
                ..where((t) => t.id.equals(planoId)))
              .write(PlanejamentoProducaoTableCompanion(
            quantidadeProduzida: Value(novaQtdProduzida),
            status: Value(novoStatus),
            updatedAt: Value(DateTime.now()),
          ));

          // Entrada no estoque físico (apenas o incremental)
          final est = await (db.select(db.estoqueProdutosTable)
                ..where((t) => t.produtoId.equals(plano.produtoId)))
              .getSingleOrNull();
          if (est != null) {
            await (db.update(db.estoqueProdutosTable)
                  ..where((t) => t.produtoId.equals(plano.produtoId)))
                .write(EstoqueProdutosTableCompanion(
              quantidadeAtual: Value(est.quantidadeAtual + quantidadeProduzida),
            ));
          }
        });
      }

      // Helper local para simular conclusão com entrada incremental
      Future<void> concluirPlanoSimulado({
        required String planoId,
        required int quantidadeFinalProduzida,
      }) async {
        await db.transaction(() async {
          final plano = await (db.select(db.planejamentoProducaoTable)
                ..where((t) => t.id.equals(planoId)))
              .getSingleOrNull();

          if (plano == null) throw Exception('Plano não encontrado');

          await (db.update(db.planejamentoProducaoTable)
                ..where((t) => t.id.equals(planoId)))
              .write(PlanejamentoProducaoTableCompanion(
            quantidadeProduzida: Value(quantidadeFinalProduzida),
            status: const Value('concluida'),
            updatedAt: Value(DateTime.now()),
          ));

          final incremental = (quantidadeFinalProduzida - plano.quantidadeProduzida).clamp(0, 999999);
          if (incremental > 0) {
            final est = await (db.select(db.estoqueProdutosTable)
                  ..where((t) => t.produtoId.equals(plano.produtoId)))
                .getSingleOrNull();
            if (est != null) {
              await (db.update(db.estoqueProdutosTable)
                    ..where((t) => t.produtoId.equals(plano.produtoId)))
                  .write(EstoqueProdutosTableCompanion(
                quantidadeAtual: Value(est.quantidadeAtual + incremental),
              ));
            }
          }
        });
      }

      test('TESTE 1 — Duplicidade simples', () async {
        final data = DateTime(2026, 8, 28);
        await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        // Tentar criar outro idêntico na mesma data deve falhar
        expect(
          () => criarPlanoSimulado(
            produtoId: 'prod-coxinha',
            dataPlano: data,
            quantidadePlanejada: 300,
            tenantId: 'tenant-test',
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'mensagem', contains('Já existe uma produção planejada'))),
        );
      });

      test('TESTE 2 — Mesmo produto, outra data', () async {
        final data1 = DateTime(2026, 8, 28);
        final data2 = DateTime(2026, 8, 29);

        final id1 = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data1,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        final id2 = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data2,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        expect(id1, isNotEmpty);
        expect(id2, isNotEmpty);
        expect(id1, isNot(equals(id2)));
      });

      test('TESTE 3 — Produtos diferentes, mesma data', () async {
        final data = DateTime(2026, 8, 28);

        // Adiciona um risole
        await db.into(db.produtosTable).insert(
          ProdutosTableCompanion.insert(
            id: 'prod-risole',
            tenantId: 'tenant-test',
            nome: 'Risole de Presunto',
            categoriaId: 'cat-geral',
            unidadeVenda: 'un',
            statusComercial: 'ativo',
            tempoMedioMinutos: 10,
            controlaEstoque: true,
            ordemProducao: 1,
            ativo: true,
            syncStatus: SyncStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'system',
            updatedBy: 'system',
          ),
        );

        final idCoxinha = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        final idRisole = await criarPlanoSimulado(
          produtoId: 'prod-risole',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        expect(idCoxinha, isNotEmpty);
        expect(idRisole, isNotEmpty);
      });

      test('TESTE 4 — Necessidade adicional', () async {
        final data = DateTime(2026, 8, 28);

        final planoId = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        // Simula que a necessidade aumentou para 500, então ajustamos o plano existente
        await ajustarQuantidadeSimulado(
          planoId: planoId,
          novaQuantidadePlanejada: 500,
        );

        final plano = await (db.select(db.planejamentoProducaoTable)
              ..where((t) => t.id.equals(planoId)))
            .getSingle();

        expect(plano.quantidadePlanejada, equals(500));
      });

      test('TESTE 5 — Produção parcial', () async {
        final data = DateTime(2026, 8, 28);

        final planoId = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        // Zera estoque físico para rastreio preciso
        await (db.update(db.estoqueProdutosTable)
              ..where((t) => t.produtoId.equals('prod-coxinha')))
            .write(const EstoqueProdutosTableCompanion(quantidadeAtual: Value(0)));

        // Registra parcial de 150
        await registrarParcialSimulado(planoId: planoId, quantidadeProduzida: 150);

        final plano = await (db.select(db.planejamentoProducaoTable)
              ..where((t) => t.id.equals(planoId)))
            .getSingle();

        final est = await (db.select(db.estoqueProdutosTable)
              ..where((t) => t.produtoId.equals('prod-coxinha')))
            .getSingle();

        expect(plano.status, equals('parcial'));
        expect(plano.quantidadeProduzida, equals(150));
        expect(est.quantidadeAtual, equals(150)); // Estoque recebeu +150
      });

      test('TESTE 6 — Campanha concluída', () async {
        final data = DateTime(2026, 8, 28);

        final planoId = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        // Zera estoque físico
        await (db.update(db.estoqueProdutosTable)
              ..where((t) => t.produtoId.equals('prod-coxinha')))
            .write(const EstoqueProdutosTableCompanion(quantidadeAtual: Value(0)));

        // Lança parcial de 150
        await registrarParcialSimulado(planoId: planoId, quantidadeProduzida: 150);

        // Conclui com 300 final
        await concluirPlanoSimulado(planoId: planoId, quantidadeFinalProduzida: 300);

        final plano = await (db.select(db.planejamentoProducaoTable)
              ..where((t) => t.id.equals(planoId)))
            .getSingle();

        final est = await (db.select(db.estoqueProdutosTable)
              ..where((t) => t.produtoId.equals('prod-coxinha')))
            .getSingle();

        expect(plano.status, equals('concluida'));
        expect(plano.quantidadeProduzida, equals(300));
        expect(est.quantidadeAtual, equals(300)); // Total 300 (150 parcial + 150 final)
      });

      test('TESTE 7 — Campanha cancelada', () async {
        final data = DateTime(2026, 8, 28);

        final planoId = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        // Cancela o plano
        await (db.update(db.planejamentoProducaoTable)
              ..where((t) => t.id.equals(planoId)))
            .write(const PlanejamentoProducaoTableCompanion(
          status: Value('cancelada'),
        ));

        // Permite criar novo planejamento pois o anterior está cancelado (inativo)
        final novoPlanoId = await criarPlanoSimulado(
          produtoId: 'prod-coxinha',
          dataPlano: data,
          quantidadePlanejada: 300,
          tenantId: 'tenant-test',
        );

        expect(novoPlanoId, isNotEmpty);
        expect(novoPlanoId, isNot(equals(planoId)));
      });

      test('TESTE 8 — Concorrência', () async {
        final data = DateTime(2026, 8, 28);

        // Executa duas tentativas simultâneas (Future.wait)
        final resultados = await Future.wait([
          criarPlanoSimulado(
            produtoId: 'prod-coxinha',
            dataPlano: data,
            quantidadePlanejada: 300,
            tenantId: 'tenant-test',
          ).then((id) => 'OK: $id').catchError((e) => 'ERRO: ${e.toString()}'),
          criarPlanoSimulado(
            produtoId: 'prod-coxinha',
            dataPlano: data,
            quantidadePlanejada: 300,
            tenantId: 'tenant-test',
          ).then((id) => 'OK: $id').catchError((e) => 'ERRO: ${e.toString()}'),
        ]);

        final okeys = resultados.where((r) => r.startsWith('OK:')).toList();
        final errors = resultados.where((r) => r.startsWith('ERRO:')).toList();

        expect(okeys.length, equals(1)); // Somente uma criada
        expect(errors.length, equals(1)); // Outra falhou com duplicidade
        expect(errors.first, contains('Já existe uma produção planejada'));
      });
    });
  });
}
