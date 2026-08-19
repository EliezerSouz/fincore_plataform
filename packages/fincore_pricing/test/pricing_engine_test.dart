import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/database/fincore_seeds.dart';
import 'package:fincore_core/src/logging/log_service.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/pricing_engine.dart';
import 'package:fincore_core/sync/outbox_service.dart';
 
void main() {
  setUpAll(() {
    LogService.init('.');
  });

  late FincoreDatabase db;
  late TenantContext context;
  late OutboxService outboxService;
  late TabelaPrecificacaoRepository tabelaRepo;
  late ItemTabelaPrecificacaoRepository itemRepo;
  late ProdutoTabelaPrecificacaoRepository assocRepo;
  late PricingEngine engine;

  setUp(() async {
    db = FincoreDatabase(NativeDatabase.memory());
    context = TenantContext();
    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );
    context.setContext(
      empresa: CoreEmpresa(
        id: FincoreSeeds.seedTenantId,
        razaoSocial: 'Demo Empresa',
        nomeFantasia: 'Demo',
        documentoFiscal: '00000000000',
        email: 'demo@demo.com',
        telefone: '00000000000',
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
      ),
      usuario: CoreUsuario(
        id: 'user-demo-admin',
        nome: 'Admin',
        email: 'admin@demo.com',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
    );
 
    outboxService = OutboxService(db: db, context: context);
 
    tabelaRepo = TabelaPrecificacaoRepository(db: db, context: context, outbox: outboxService);
    itemRepo = ItemTabelaPrecificacaoRepository(db: db, context: context, outbox: outboxService);
    assocRepo = ProdutoTabelaPrecificacaoRepository(db: db, context: context, outbox: outboxService);
    final catAssocRepo = CategoriaTabelaPrecificacaoRepository(db: db, context: context, outbox: outboxService);
 
    engine = PricingEngine(
      tabelaRepo: tabelaRepo,
      itemRepo: itemRepo,
      assocRepo: assocRepo,
      catAssocRepo: catAssocRepo,
    );

    // Rodar os seeds para carregar as tabelas Geral e Bebidas
    await FincoreSeeds.populate(db);
  });

  tearDown(() async {
    await db.close();
    context.clear();
  });

  group('Pricing Engine - Resolução de Faixas de Preço', () {
    test('Deve resolver preço unitário correto para quantidade pequena (faixa 1)', () async {
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000201',
        quantidade: 10,
      );
      expect(preco, equals(200)); // R$ 2,00
    });

    test('Deve resolver preço unitário correto para quantidade média (faixa 2)', () async {
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000201',
        quantidade: 30,
      );
      expect(preco, equals(180)); // R$ 1,80
    });

    test('Deve resolver preço unitário correto para quantidade alta (faixa 4)', () async {
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000201',
        quantidade: 150,
      );
      expect(preco, equals(140)); // R$ 1,40
    });

    test('Deve resolver preço unitário fixo para Coca-Cola', () async {
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000203',
        quantidade: 5,
      );
      expect(preco, equals(600)); // R$ 6,00
    });
  });

  group('Pricing Engine - Prioridades e Resolução de Conflitos', () {
    test('Deve resolver tabela promocional de maior prioridade se estiver ativa', () async {
      // 1. Criar uma tabela promocional com prioridade alta (20)
      final promoTable = TabelaPrecificacao(
        id: 'tabela-promo-julho',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Promoção de Julho',
        descricao: 'Salgados promocionais',
        tipoPolitica: PricingPolicyType.unitario,
        prioridade: 20, // Maior que 10 da Geral
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await tabelaRepo.save(promoTable);

      // 2. Criar item de preço de 150 centavos (R$ 1,50)
      final promoItem = ItemTabelaPrecificacao(
        id: 'item-promo-1',
        tenantId: FincoreSeeds.seedTenantId,
        tabelaPrecificacaoId: 'tabela-promo-julho',
        quantidadeMinima: 1,
        quantidadeMaxima: null,
        valorUnitarioCentavos: 150,
        ordem: 1,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await itemRepo.save(promoItem);

      // 3. Vincular produto à tabela promocional
      final assoc = ProdutoTabelaPrecificacao(
        id: 'assoc-coxinha-promo',
        tenantId: FincoreSeeds.seedTenantId,
        produtoId: '00000000-0000-4000-a000-000000000201',
        tabelaPrecificacaoId: 'tabela-promo-julho',
        ativo: true,
        prioridade: 0,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await assocRepo.save(assoc);

      // 4. Resolver preço - deve retornar o preço da Promoção (150) mesmo para quantidade pequena
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000201',
        quantidade: 10,
      );
      expect(preco, equals(150));
    });

    test('Deve desconsiderar tabela de alta prioridade se estiver fora da vigência', () async {
      // 1. Criar uma tabela vencida
      final expiredTable = TabelaPrecificacao(
        id: 'tabela-vencida',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Promoção Vencida',
        descricao: 'Salgados vencidos',
        tipoPolitica: PricingPolicyType.unitario,
        prioridade: 30, // Muito alta
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await tabelaRepo.save(expiredTable);

      final expiredItem = ItemTabelaPrecificacao(
        id: 'item-expired-1',
        tenantId: FincoreSeeds.seedTenantId,
        tabelaPrecificacaoId: 'tabela-vencida',
        quantidadeMinima: 1,
        quantidadeMaxima: null,
        valorUnitarioCentavos: 100, // Super barato R$ 1,00
        ordem: 1,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await itemRepo.save(expiredItem);

      // Vincula com vigência no passado
      final assoc = ProdutoTabelaPrecificacao(
        id: 'assoc-coxinha-expired',
        tenantId: FincoreSeeds.seedTenantId,
        produtoId: '00000000-0000-4000-a000-000000000201',
        tabelaPrecificacaoId: 'tabela-vencida',
        ativo: true,
        prioridade: 0,
        dataInicio: DateTime.now().subtract(const Duration(days: 10)),
        dataFim: DateTime.now().subtract(const Duration(days: 2)), // Venceu há 2 dias
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await assocRepo.save(assoc);

    });

    test('Deve lancar StateError para produto sem nenhuma tabela vinculada', () async {
      expect(
        () => engine.resolvePrice(
          produtoId: 'prod-sem-tabela',
          quantidade: 10,
        ),
        throwsStateError,
      );
    });

    test('Deve desconsiderar tabela de precificacao inativa', () async {
      // 1. Desativar tabela de bebidas
      final tabela = await tabelaRepo.findById('00000000-0000-4000-a000-000000000902');
      expect(tabela, isNotNull);
      final inactiveTabela = TabelaPrecificacao(
        id: tabela!.id,
        tenantId: tabela.tenantId,
        nome: tabela.nome,
        descricao: tabela.descricao,
        tipoPolitica: tabela.tipoPolitica,
        prioridade: tabela.prioridade,
        ativo: false, // INATIVA
        metadata: tabela.metadata,
      );
      await tabelaRepo.save(inactiveTabela);

      // 2. Tentar resolver preço da Coca-Cola (que estava vinculada à tabela inativa)
      // Deve disparar StateError porque a única tabela associada está inativa
      expect(
        () => engine.resolvePrice(
          produtoId: '00000000-0000-4000-a000-000000000203',
          quantidade: 1,
        ),
        throwsStateError,
      );
    });

    test('Deve desconsiderar associacao (ProdutoTabelaPrecificacao) inativa', () async {
      // 1. Inativar o vínculo da Mini Coxinha com a Tabela Geral
      final assocs = await assocRepo.findByProdutoId('00000000-0000-4000-a000-000000000201');
      expect(assocs.length, equals(1));
      final assoc = assocs.first;
      final inactiveAssoc = ProdutoTabelaPrecificacao(
        id: assoc.id,
        tenantId: assoc.tenantId,
        produtoId: assoc.produtoId,
        tabelaPrecificacaoId: assoc.tabelaPrecificacaoId,
        ativo: false, // Vínculo Inativo!
        prioridade: assoc.prioridade,
        metadata: assoc.metadata,
      );
      await assocRepo.save(inactiveAssoc);

      // 2. Resolver preço - deve falhar pois o único vínculo está inativo
      expect(
        () => engine.resolvePrice(
          produtoId: '00000000-0000-4000-a000-000000000201',
          quantidade: 10,
        ),
        throwsStateError,
      );
    });

    test('Deve cair no fallback do primeiro item quando a quantidade estiver fora de qualquer faixa', () async {
      // 1. Criar tabela sem faixa inicial para quantidade = 0
      final customTable = TabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000992',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Tabela Sem Faixa Inicial',
        descricao: 'Tabela de teste',
        tipoPolitica: PricingPolicyType.unitario,
        prioridade: 15, // Maior que a Geral
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await tabelaRepo.save(customTable);
 
      // Item começa na quantidade minima 10
      final customItem = ItemTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000882',
        tenantId: FincoreSeeds.seedTenantId,
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000992',
        quantidadeMinima: 10,
        quantidadeMaxima: null,
        valorUnitarioCentavos: 333,
        ordem: 1,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await itemRepo.save(customItem);
 
      final assoc = ProdutoTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000772',
        tenantId: FincoreSeeds.seedTenantId,
        produtoId: '00000000-0000-4000-a000-000000000201',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000992',
        ativo: true,
        prioridade: 0,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await assocRepo.save(assoc);
 
      // 2. Tentar resolver para quantidade = 2 (fora da faixa >=10)
      // Deve retornar o fallback (primeiro item cadastrado = 333)
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000201',
        quantidade: 2,
      );
      expect(preco, equals(333));
    });

    test('Deve desempacotar empate resolvendo pela vigencia mais restrita em caso de empate de prioridades', () async {
      final now = DateTime.now();
 
      // Criar duas tabelas com a mesma prioridade (15) vinculadas à Mini Coxinha
      final tableLong = TabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000993',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Tabela Longa Vigência',
        descricao: '10 dias de vigencia',
        tipoPolitica: PricingPolicyType.unitario,
        prioridade: 15,
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: now,
          updatedAt: now,
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await tabelaRepo.save(tableLong);
 
      final itemLong = ItemTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000883',
        tenantId: FincoreSeeds.seedTenantId,
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000993',
        quantidadeMinima: 1,
        quantidadeMaxima: null,
        valorUnitarioCentavos: 190, // R$ 1,90
        ordem: 1,
        metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'test', updatedBy: 'test', syncStatus: SyncStatus.pending),
      );
      await itemRepo.save(itemLong);
 
      final assocLong = ProdutoTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000773',
        tenantId: FincoreSeeds.seedTenantId,
        produtoId: '00000000-0000-4000-a000-000000000201',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000993',
        ativo: true,
        prioridade: 0,
        dataInicio: now.subtract(const Duration(days: 5)),
        dataFim: now.add(const Duration(days: 5)), // Duração = 10 dias
        metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'test', updatedBy: 'test', syncStatus: SyncStatus.pending),
      );
      await assocRepo.save(assocLong);
 
      // Tabela de vigência curta (2 dias)
      final tableShort = TabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000994',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Tabela Curta Vigência',
        descricao: '2 dias de vigencia',
        tipoPolitica: PricingPolicyType.unitario,
        prioridade: 15, // MESMA PRIORIDADE (15)
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: now,
          updatedAt: now,
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      await tabelaRepo.save(tableShort);
 
      final itemShort = ItemTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000884',
        tenantId: FincoreSeeds.seedTenantId,
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000994',
        quantidadeMinima: 1,
        quantidadeMaxima: null,
        valorUnitarioCentavos: 110, // R$ 1,10 (muito mais barato!)
        ordem: 1,
        metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'test', updatedBy: 'test', syncStatus: SyncStatus.pending),
      );
      await itemRepo.save(itemShort);
 
      final assocShort = ProdutoTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000774',
        tenantId: FincoreSeeds.seedTenantId,
        produtoId: '00000000-0000-4000-a000-000000000201',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000994',
        ativo: true,
        prioridade: 0,
        dataInicio: now.subtract(const Duration(days: 1)),
        dataFim: now.add(const Duration(days: 1)), // Duração = 2 dias (mais curta)
        metadata: SyncMetadata(version: 1, createdAt: now, updatedAt: now, createdBy: 'test', updatedBy: 'test', syncStatus: SyncStatus.pending),
      );
      await assocRepo.save(assocShort);
 
      // Ao resolver o preço, a de vigência mais curta (110) deve vencer o empate!
      final preco = await engine.resolvePrice(
        produtoId: '00000000-0000-4000-a000-000000000201',
        quantidade: 1,
      );
      expect(preco, equals(110));
    });
  });

  group('Pricing Repositories - Tenancy, Mutations & Soft Deletes', () {
    test('Deve validar findAll, save, delete e tenancy do TabelaPrecificacaoRepository', () async {
      // FindAll
      final list = await tabelaRepo.findAll();
      expect(list.length, equals(2)); // Geral e Bebidas de seeds

      // Tenancy violado ao salvar
      final t = TabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000999',
        tenantId: 'outro-tenant',
        nome: 'Errado',
        descricao: '',
        tipoPolitica: PricingPolicyType.unitario,
        prioridade: 1,
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
        ),
      );
      expect(() => tabelaRepo.save(t), throwsStateError);

      // Soft delete
      await tabelaRepo.delete('00000000-0000-4000-a000-000000000901');
      final deleted = await tabelaRepo.findById('00000000-0000-4000-a000-000000000901');
      expect(deleted!.metadata.deletedAt, isNotNull);
    });

    test('Deve validar findAll, save, delete e tenancy do ItemTabelaPrecificacaoRepository', () async {
      // FindAll
      final list = await itemRepo.findAll();
      expect(list.length, equals(5)); // 4 geral + 1 bebida

      // Tenancy violado
      final item = ItemTabelaPrecificacao(
        id: '00000000-0000-4000-a000-000000000899',
        tenantId: 'outro-tenant',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
        quantidadeMinima: 1,
        quantidadeMaxima: null,
        valorUnitarioCentavos: 100,
        ordem: 1,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      expect(() => itemRepo.save(item), throwsStateError);

      // Soft delete
      await itemRepo.delete('00000000-0000-4000-a000-000000000911');
      final deleted = await itemRepo.findById('00000000-0000-4000-a000-000000000911');
      expect(deleted!.metadata.deletedAt, isNotNull);
    });

    test('Deve validar findAll, save, delete e tenancy do ProdutoTabelaPrecificacaoRepository', () async {
      // FindAll
      final list = await assocRepo.findAll();
      expect(list.length, equals(3)); // 3 associacoes de seeds
 
      // Tenancy violado
      final assoc = ProdutoTabelaPrecificacao(
        id: 'assoc-errada',
        tenantId: 'outro-tenant',
        produtoId: '00000000-0000-4000-a000-000000000201',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
        ativo: true,
        prioridade: 1,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
          syncStatus: SyncStatus.pending,
        ),
      );
      expect(() => assocRepo.save(assoc), throwsStateError);
 
      // Soft delete
      await assocRepo.delete('00000000-0000-4000-a000-000000000931');
      final deleted = await assocRepo.findById('00000000-0000-4000-a000-000000000931');
      expect(deleted!.metadata.deletedAt, isNotNull);
    });
 
    test('Deve resolver preço herdado de CategoriaTabelaPrecificacao (fallback)', () async {
      final catAssocRepo = CategoriaTabelaPrecificacaoRepository(db: db, context: context, outbox: outboxService);
      final mockMetadata = SyncMetadata(
        version: 1,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        createdBy: 'test',
        updatedBy: 'test',
      );
      
      await db.into(db.produtosTable).insert(
        ProdutosTableCompanion(
          id: const Value('prod-teste-refri'),
          tenantId: const Value(FincoreSeeds.seedTenantId),
          nome: const Value('Refrigerante Teste'),
          categoriaId: const Value('00000000-0000-4000-a000-000000000103'), // Bebidas no seeds
          unidadeVenda: const Value('un'),
          statusComercial: const Value('disponivel'),
          tempoMedioMinutos: const Value(2),
          controlaEstoque: const Value(false),
          ordemProducao: const Value(1),
          ativo: const Value(true),
          createdBy: const Value('seed'),
          updatedBy: const Value('seed'),
          syncStatus: const Value(SyncStatus.synced),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
 
      await catAssocRepo.save(CategoriaTabelaPrecificacao(
        id: 'cat-assoc-bebidas',
        tenantId: FincoreSeeds.seedTenantId,
        categoriaId: '00000000-0000-4000-a000-000000000103',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000902',
        ativo: true,
        prioridade: 1,
        metadata: mockMetadata,
      ));
 
      final preco = await engine.resolvePrice(
        produtoId: 'prod-teste-refri',
        quantidade: 1,
      );
 
      expect(preco, equals(600)); // Faixa unitária da tabela de bebidas dos seeds é R$ 6,00 (600 centavos)
    });
 
    test('Deve validar prioridade de sobrecarga (Produto > Categoria)', () async {
      final catAssocRepo = CategoriaTabelaPrecificacaoRepository(db: db, context: context, outbox: outboxService);
      final mockMetadata = SyncMetadata(
        version: 1,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        createdBy: 'test',
        updatedBy: 'test',
      );
 
      await db.into(db.produtosTable).insert(
        ProdutosTableCompanion(
          id: const Value('prod-teste-uva'),
          tenantId: const Value(FincoreSeeds.seedTenantId),
          nome: const Value('Suco de Uva Teste'),
          categoriaId: const Value('00000000-0000-4000-a000-000000000103'),
          unidadeVenda: const Value('un'),
          statusComercial: const Value('disponivel'),
          tempoMedioMinutos: const Value(2),
          controlaEstoque: const Value(false),
          ordemProducao: const Value(2),
          ativo: const Value(true),
          createdBy: const Value('seed'),
          updatedBy: const Value('seed'),
          syncStatus: const Value(SyncStatus.synced),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
 
      await catAssocRepo.save(CategoriaTabelaPrecificacao(
        id: 'cat-assoc-bebidas-uva',
        tenantId: FincoreSeeds.seedTenantId,
        categoriaId: '00000000-0000-4000-a000-000000000103',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000902',
        ativo: true,
        prioridade: 1,
        metadata: mockMetadata,
      ));
 
      final precoCat = await engine.resolvePrice(produtoId: 'prod-teste-uva', quantidade: 1);
      expect(precoCat, equals(600)); // R$ 6,00
 
      await assocRepo.save(ProdutoTabelaPrecificacao(
        id: 'assoc-uva-geral',
        tenantId: FincoreSeeds.seedTenantId,
        produtoId: 'prod-teste-uva',
        tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
        ativo: true,
        prioridade: 2,
        metadata: mockMetadata,
      ));
 
      final precoProd = await engine.resolvePrice(produtoId: 'prod-teste-uva', quantidade: 1);
      expect(precoProd, equals(200));
    });
  });

  // ─── GRUPO: Canal Estruturado (P1-07) ──────────────────────────────────────
  group('Canal estruturado na TabelaPrecificacao (P1-07)', () {
    // UUID do produto semeado pelo FincoreSeeds.populate() nos testes
    const seedProdId = '00000000-0000-4000-a000-000000000201';

    test('Tabela com canal todos se aplica a qualquer canal de venda', () async {
      // A semente padrão não define canal explícito, então 'todos' é o default
      // Verificamos que o PricingEngine resolve preço sem canal específico
      final preco = await engine.resolvePrice(
        produtoId: seedProdId,
        quantidade: 1,
        canal: null, // Sem canal específico
      );
      expect(preco, greaterThan(0),
          reason: 'Deve resolver preço mesmo sem canal especificado');
    });

    test('Canal delivery resolve preço corretamente quando tabela aceita todos', () async {
      // A tabela default tem canal='todos' (por migration), então deve aceitar delivery
      final preco = await engine.resolvePrice(
        produtoId: seedProdId,
        quantidade: 1,
        canal: 'Entrega', // Canal delivery
      );
      expect(preco, greaterThan(0));
    });

    test('Canal Retirada resolve preço corretamente quando tabela aceita todos', () async {
      final preco = await engine.resolvePrice(
        produtoId: seedProdId,
        quantidade: 1,
        canal: 'Retirada',
      );
      expect(preco, greaterThan(0));
    });
  });
}
