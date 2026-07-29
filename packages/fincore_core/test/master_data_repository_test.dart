import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/database/fincore_seeds.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/forma_pagamento_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';

void main() {
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
        id: 'tenant-demo-001',
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

    categoriaRepo = CategoriaRepository(db: db, context: context);
    produtoRepo = ProdutoRepository(db: db, context: context);
    clienteRepo = ClienteRepository(db: db, context: context);
    localRepo = LocalEntregaRepository(db: db, context: context);
    pagamentoRepo = FormaPagamentoRepository(db: db, context: context);
    taxaRepo = TaxaEntregaRepository(db: db, context: context);

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
        tenantId: 'tenant-demo-001',
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

    test('Deve deletar logicamente (Soft Delete) um produto', () async {
      const prodId = 'prod-mini-coxinha';
      final fetchedBefore = await produtoRepo.findById(prodId);
      expect(fetchedBefore!.metadata.deletedAt, isNull);

      await produtoRepo.delete(prodId);

      final fetchedAfter = await produtoRepo.findById(prodId);
      expect(fetchedAfter!.metadata.deletedAt, isNotNull);
      expect(fetchedAfter.metadata.syncStatus, equals(SyncStatus.pending));
    });

    test('Deve salvar e buscar locais de entrega do cliente', () async {
      final local = LocalEntrega(
        id: 'local-novo-001',
        tenantId: 'tenant-demo-001',
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
        tenantId: 'tenant-demo-001',
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
