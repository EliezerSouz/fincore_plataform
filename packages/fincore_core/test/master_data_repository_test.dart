import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_exceptions.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/database/fincore_seeds.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/forma_pagamento_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/src/logging/log_service.dart';

void main() {
  setUpAll(() {
    LogService.init('.');
  });

  late FincoreDatabase db;
  late TenantContext context;
  late CategoriaRepository categoriaRepo;
  late ProdutoRepository produtoRepo;
  late ClienteRepository clienteRepo;
  late LocalEntregaRepository localRepo;
  late FormaPagamentoRepository pagamentoRepo;
  late TaxaEntregaRepository taxaRepo;

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

    final outboxService = OutboxService(db: db, context: context);
    categoriaRepo = CategoriaRepository(db: db, context: context, outbox: outboxService);
    produtoRepo = ProdutoRepository(db: db, context: context, outbox: outboxService);
    clienteRepo = ClienteRepository(db: db, context: context, outbox: outboxService);
    localRepo = LocalEntregaRepository(db: db, context: context, outbox: outboxService);
    pagamentoRepo = FormaPagamentoRepository(db: db, context: context, outbox: outboxService);
    taxaRepo = TaxaEntregaRepository(db: db, context: context, outbox: outboxService);

    // Rodar os Seeds
    await FincoreSeeds.populate(db);
  });

  tearDown(() async {
    await db.close();
    context.clear();
  });

  group('Master Data - Seeds & Read Tests', () {
    test('Deve validar que as categorias foram semeadas corretamente', () async {
      final list = await categoriaRepo.findAll();
      expect(list.length, equals(3));
      expect(list.any((c) => c.nome == 'Salgados Fritos'), isTrue);
    });

    test('Deve validar que os produtos foram semeados corretamente', () async {
      final list = await produtoRepo.findAll();
      expect(list.length, equals(3));
      expect(list.any((p) => p.nome == 'Mini Coxinha'), isTrue);
    });

    test('Deve validar que o cliente padrão foi semeado corretamente', () async {
      final list = await clienteRepo.findAll();
      expect(list.length, equals(1));
      expect(list.first.nome, equals('Cliente Consumidor (Balcão)'));
    });

    test('Deve validar as formas de pagamento semeadas', () async {
      final list = await pagamentoRepo.findAll();
      expect(list.length, equals(2));
      expect(list.first.nome, equals('Dinheiro'));
    });
  });

  group('Master Data - Tenancy & Mutations', () {
    test('Deve salvar nova Categoria com sucesso sob o tenant correto', () async {
      final cat = Categoria(
        id: 'cat-nova-001',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Sobremesas',
        descricao: 'Doces e bolos',
        ordemExibicao: 4,
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

      await categoriaRepo.save(cat);

      final fetched = await categoriaRepo.findById('cat-nova-001');
      expect(fetched, isNotNull);
      expect(fetched!.nome, equals('Sobremesas'));
    });

    test('Deve disparar StateError ao salvar Categoria com Tenant incorreto', () async {
      final cat = Categoria(
        id: 'cat-invalida-001',
        tenantId: 'tenant-outro-999',
        nome: 'Tentativa Invasão',
        descricao: 'Desc',
        ordemExibicao: 1,
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

      expect(() => categoriaRepo.save(cat), throwsStateError);
    });

    test('AUD-003: Deve bloquear categoria com nome duplicado (ignorando caixa/espaços)', () async {
      Categoria nova(String id, String nome) => Categoria(
            id: id,
            tenantId: FincoreSeeds.seedTenantId,
            nome: nome,
            descricao: '',
            ordemExibicao: 1,
            ativo: true,
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: 'test',
              updatedBy: 'test',
            ),
          );

      await categoriaRepo.save(nova('cat-dup-1', 'Bebidas Geladas'));
      expect(() => categoriaRepo.save(nova('cat-dup-2', '  bebidas   GELADAS ')),
          throwsA(isA<NomeDuplicadoException>()));
      // Re-salvar a própria categoria (edição) continua permitido
      await categoriaRepo.save(nova('cat-dup-1', 'Bebidas Geladas'));
    });

    test('AUD-004: Deve persistir e recuperar subcategoria vinculada à categoria-pai (parentId)', () async {
      final pai = Categoria(
        id: 'cat-pai-100',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Doces Finos',
        descricao: 'Doces e bombons refinados',
        ordemExibicao: 10,
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
        ),
      );
      await categoriaRepo.save(pai);

      final filha = Categoria(
        id: 'cat-filha-101',
        tenantId: FincoreSeeds.seedTenantId,
        parentId: pai.id,
        nome: 'Trufas Gourmet',
        descricao: 'Trufas de chocolate belga',
        ordemExibicao: 1,
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
        ),
      );
      await categoriaRepo.save(filha);

      // Verificação direta por findById
      final recuperada = await categoriaRepo.findById('cat-filha-101');
      expect(recuperada, isNotNull);
      expect(recuperada!.parentId, equals('cat-pai-100'));
      expect(recuperada.nome, equals('Trufas Gourmet'));

      // Verificação por busca hierárquica findByParentId
      final subcategorias = await categoriaRepo.findByParentId('cat-pai-100');
      expect(subcategorias.length, equals(1));
      expect(subcategorias.first.id, equals('cat-filha-101'));

      // Categorias raiz não devem incluir a filha quando parentId for null
      final raizes = await categoriaRepo.findByParentId(null);
      expect(raizes.any((c) => c.id == 'cat-filha-101'), isFalse);
      expect(raizes.any((c) => c.id == 'cat-pai-100'), isTrue);
    });

    test('AUD-003: Deve bloquear produto com nome duplicado na mesma categoria', () async {
      final base = (await produtoRepo.findAll()).first;
      final copia = base.copyWith(id: 'prod-dup-1');
      expect(() => produtoRepo.save(copia), throwsA(isA<NomeDuplicadoException>()));
    });

    test('Deve deletar logicamente (Soft Delete) um produto', () async {
      const prodId = '00000000-0000-4000-a000-000000000201';
      final fetchedBefore = await produtoRepo.findById(prodId);
      expect(fetchedBefore, isNotNull, reason: 'Produto deve existir antes do delete');
      expect(fetchedBefore!.metadata.deletedAt, isNull);

      await produtoRepo.delete(prodId);

      // P1-03: findById retorna null para produto deletado (soft-delete filter)
      final fetchedAfter = await produtoRepo.findById(prodId);
      expect(fetchedAfter, isNull,
          reason: 'findById deve retornar null após soft-delete (P1-03)');

      // Verifica diretamente na tabela que deletedAt foi preenchido
      final row = await (db.select(db.produtosTable)
            ..where((t) => t.id.equals(prodId)))
          .getSingleOrNull();
      expect(row?.deletedAt, isNotNull,
          reason: 'deletedAt deve ser preenchido no banco após soft-delete');
      expect(row?.syncStatus, equals(SyncStatus.pending));
    });

    test('Deve salvar e buscar locais de entrega do cliente', () async {
      final mockCliente = Cliente(
        id: 'cliente-balcao-001',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Cliente Balcão',
        telefone: '11988887777',
        email: 'caixa@fincore.com',
        documento: '123.456.789-00',
        observacoes: '',
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
        ),
      );
      await clienteRepo.save(mockCliente);

      final local = LocalEntrega(
        id: 'local-novo-001',
        tenantId: FincoreSeeds.seedTenantId,
        clienteId: 'cliente-balcao-001',
        nomeIdentificador: 'Trabalho',
        logradouro: 'Av Central',
        numero: '100',
        bairro: 'Centro',
        cidade: 'Sorocaba',
        cep: '18000-000',
        referencia: 'Perto do shopping',
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
        ),
      );

      await localRepo.save(local);

      final list = await localRepo.findByClienteId('cliente-balcao-001');
      expect(list.length, equals(1));
      expect(list.first.nomeIdentificador, equals('Trabalho'));
    });

    test('Deve salvar e buscar taxas de entrega por tenant', () async {
      final taxa = TaxaEntrega(
        id: 'taxa-nova-001',
        tenantId: FincoreSeeds.seedTenantId,
        nome: 'Taxa Centro',
        tipoRegra: TipoRegraTaxaEntrega.fixo,
        valorCentavos: 500, // R$ 5,00
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test',
          updatedBy: 'test',
        ),
      );

      await taxaRepo.save(taxa);

      final list = await taxaRepo.findAll();
      expect(list.any((t) => t.nome == 'Taxa Centro'), isTrue);
    });
  });
}
