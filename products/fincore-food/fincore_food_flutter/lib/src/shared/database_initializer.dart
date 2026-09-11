import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'database_connection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
// fincore_core barrel — cobre todos os repositórios, serviços e modelos do core
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/pricing_engine.dart';
import 'package:fincore_food_flutter/src/dashboard/data/dashboard_repository.dart';
import 'package:fincore_food_flutter/src/dashboard/domain/dashboard_service.dart';
import 'package:fincore_food_flutter/src/dashboard/controllers/dashboard_controller.dart';
import 'package:fincore_food_flutter/src/clientes/controllers/clientes_controller.dart';
import 'package:fincore_core/repository/print_job_repository.dart';
import 'package:fincore_food_flutter/src/cap/printing/usecases/print_use_case.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/planejamento_controller.dart';

/// Responsável por inicializar toda a infraestrutura da FINCORE Platform:
///
/// 1. Variáveis de ambiente (.env via flutter_dotenv)
/// 2. Banco de dados local Drift SQLite (offline-first)
/// 3. Contexto de Tenant ativo
/// 4. Seeds de dados iniciais
/// 5. Repositórios de domínio com Sync OBRIGATÓRIO via SyncableRepository
/// 6. Container de Injeção de Dependências
/// 7. Supabase SDK (banco central remoto + Realtime)
///
/// Arquitetura de dados:
/// ```
/// Flutter (Drift SQLite local) → OutboxService → SupabaseSyncService → Supabase PostgreSQL
///                                                        ↑
///                                              Realtime WebSocket ←┘
/// ```
class DatabaseInitializer {
  static Future<void> init(Client client) async {
    final stopwatch = Stopwatch()..start();
    final bool isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    // ──────────────────────────────────────────────────────────────
    // 0. Inicializar Serviço de Logs unificado
    // ──────────────────────────────────────────────────────────────
    if (kIsWeb) {
      LogService.init('');
      await LogService.instance.info(LogModule.app, 'FINCORE Platform inicializado com sucesso (Web).');
    } else if (!isTest) {
      final docDir = await getApplicationDocumentsDirectory();
      LogService.init(docDir.path);
      await LogService.instance.info(LogModule.app, 'FINCORE Platform inicializado com sucesso.');
    } else {
      try {
        LogService.init(Directory.systemTemp.path);
      } catch (_) {}
    }

    // ──────────────────────────────────────────────────────────────
    // 1. Carregar variáveis de ambiente (.env)
    // ──────────────────────────────────────────────────────────────
    if (!isTest) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}
    }

    // ──────────────────────────────────────────────────────────────
    // 2. Abrir banco de dados Drift SQLite (offline-first local)
    // ──────────────────────────────────────────────────────────────
    final FincoreDatabase db;
    if (kIsWeb) {
      db = FincoreDatabase(createDatabaseConnection('fincore_v3'));
    } else if (isTest) {
      db = FincoreDatabase(createDatabaseConnection('fincore_v3', inMemory: true));
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'fincore_v3.db');

      // O banco local é a fonte de verdade durante operação offline. Nunca o
      // apague automaticamente: uma heurística de "correção" pode descartar
      // pedidos e mutações ainda não enviados ao servidor.
      db = FincoreDatabase(createDatabaseConnection(dbPath));
    }

    // ──────────────────────────────────────────────────────────────
    // 3. Contexto de Tenant e Supabase
    // ──────────────────────────────────────────────────────────────
    final context = TenantContext();

    // Limpeza proativa de registros legados do SQLite local com tenant-demo-001 (formato não-UUID)
    try {
      await (db.delete(db.outboxSync)..where((t) => t.tenantId.equals('tenant-demo-001'))).go();
      await (db.delete(db.empresasTable)..where((t) => t.id.equals('tenant-demo-001'))).go();
      // Remove registros de auditoria com IDs legados não-UUID ("AUD-XXX") que quebram o Supabase
      await (db.delete(db.outboxSync)
            ..where((t) => t.entity.equals('audit_log') & t.entityId.like('AUD-%')))
          .go();
    } catch (_) {}

    // ──────────────────────────────────────────────────────────────
    // 4. Seeds de dados iniciais (com UUID válido)
    // ──────────────────────────────────────────────────────────────
    final empresas = await db.select(db.empresasTable).get();
    if (empresas.isEmpty) {
      await FincoreSeeds.populate(db);
    }
    // ──────────────────────────────────────────────────────────────
    // 5. Infraestrutura de Sync
    // ──────────────────────────────────────────────────────────────
    final outboxService = OutboxService(db: db, context: context);
    late final SupabaseSyncService supabaseSyncService;

    final syncEngine = SyncEngine(
      outboxService: outboxService,
      context: context,
      db: db,
      serverPushHandler: (entry) async {
        return await supabaseSyncService.push(entry);
      },
    );

    // ──────────────────────────────────────────────────────────────
    // 6. Instanciar Repositórios — TODOS com sync obrigatório
    // ──────────────────────────────────────────────────────────────
    final categoriaRepo = CategoriaRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final produtoRepo = ProdutoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final clienteRepo = ClienteRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final localRepo = LocalEntregaRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );

    // Repositório de Auditoria
    final auditRepo = AuditLogRepository(
      db: db,
      outboxRepo: outboxService,
    );
    final pagamentoRepo = FormaPagamentoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final taxaRepo = TaxaEntregaRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final configRepo = EmpresaConfiguracaoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );

    // Repositórios sem sync bidirecional por enquanto (somente leitura remota)
    final usuarioRepo = UsuarioRepository(db: db, context: context);
    final empresaRepo = EmpresaRepository(
      db: db,
      context: context,
      outbox: outboxService,
      syncEngine: syncEngine,
    );

    // Ativar o contexto do Tenant com os dados do banco local
    final coreEmpresas = await empresaRepo.findAll();
    if (coreEmpresas.isNotEmpty) {
      final emp = coreEmpresas.first;
      final coreUsuarios = await usuarioRepo.findAll();
      // ⚠️  SEGURANÇA (P0-03): Este usuário placeholder é criado APENAS como contexto
      // mínimo para que o banco inicialize antes da autenticação real via Supabase.
      // role: null impede que qualquer módulo administrativo seja acessado sem login.
      // O FincoreRootRouter substituirá este contexto pelo usuário real após o login.
      final usr = coreUsuarios.isNotEmpty
          ? coreUsuarios.first
          : CoreUsuario(
              id: '00000000-0000-0000-0000-000000000001',
              tenantId: emp.id,
              nome: 'Sistema',
              email: null,
              role: null, // Sem role — exige autenticação antes de conceder acesso
              criadoEm: DateTime.now(),
              atualizadoEm: DateTime.now(),
            );
      context.setContext(empresa: emp, usuario: usr);
    }
    final membroRepo = MembroEmpresaRepository(db: db, context: context);
    final empresaConviteRepo = EmpresaConviteRepository(db: db, context: context);
    final ordemPreparoRepo = OrdemPreparoRepository(db: db, context: context);
    final loteInsumoRepo = LoteInsumoRepository(db: db, context: context);
    final estornarLoteEstoqueUseCase = EstornarLoteEstoqueUseCase(loteRepository: loteInsumoRepo);

    // CAP.PRINTING: Repositório de Jobs e UseCase
    final printJobRepo = PrintJobRepository(db: db, context: context);
    final printUseCase = PrintUseCase(
      configRepo: configRepo,
      jobRepo: printJobRepo,
    );

    // Precificação com sync obrigatório
    final tabelaRepo = TabelaPrecificacaoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final itemRepo = ItemTabelaPrecificacaoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final assocRepo = ProdutoTabelaPrecificacaoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );
    final catAssocRepo = CategoriaTabelaPrecificacaoRepository(
      db: db, context: context, outbox: outboxService, syncEngine: syncEngine,
    );

    final pricingEngine = PricingEngine(
      tabelaRepo: tabelaRepo,
      itemRepo: itemRepo,
      assocRepo: assocRepo,
      catAssocRepo: catAssocRepo,
    );

    // ──────────────────────────────────────────────────────────────
    // 7. Registrar tudo no Container de Injeção de Dependências
    // ──────────────────────────────────────────────────────────────
    final di = DependencyInjection();
    di.register<FincoreDatabase>(db);
    di.register<TenantContext>(context);
    di.register<OutboxService>(outboxService);
    di.register<SyncEngine>(syncEngine);
    di.register<AuditLogRepository>(auditRepo);
    di.register<CategoriaRepository>(categoriaRepo);
    di.register<ProdutoRepository>(produtoRepo);
    di.register<ClienteRepository>(clienteRepo);
    di.register<LocalEntregaRepository>(localRepo);
    di.register<FormaPagamentoRepository>(pagamentoRepo);
    di.register<TaxaEntregaRepository>(taxaRepo);
    di.register<EmpresaConfiguracaoRepository>(configRepo);
    di.register<MembroEmpresaRepository>(membroRepo);
    di.register<EmpresaConviteRepository>(empresaConviteRepo);
    di.register<UsuarioRepository>(usuarioRepo);
    di.register<EmpresaRepository>(empresaRepo);
    di.register<TabelaPrecificacaoRepository>(tabelaRepo);
    di.register<ItemTabelaPrecificacaoRepository>(itemRepo);
    di.register<ProdutoTabelaPrecificacaoRepository>(assocRepo);
    di.register<CategoriaTabelaPrecificacaoRepository>(catAssocRepo);
    di.register<PricingEngine>(pricingEngine);
    di.register<OrdemPreparoRepository>(ordemPreparoRepo);
    di.register<LoteInsumoRepository>(loteInsumoRepo);
    di.register<EstornarLoteEstoqueUseCase>(estornarLoteEstoqueUseCase);
    // CAP.PRINTING
    di.register<PrintJobRepository>(printJobRepo);
    di.register<PrintUseCase>(printUseCase);
    di.register<Client>(client);

    // CAP.CLIENTES — Controller registrado após os repositórios dos quais depende
    try {
      final oldController = di.get<ClientesController>();
      oldController.dispose();
    } catch (_) {}

    final clientesController = ClientesController(
      clienteRepo: clienteRepo,
      localRepo: localRepo,
      taxaRepo: taxaRepo,
    );
    di.register<ClientesController>(clientesController);

    // CAP.ESTOQUE
    try {
      final oldEstoqueController = di.get<EstoqueController>();
      oldEstoqueController.dispose();
    } catch (_) {}

    final estoqueController = EstoqueController();
    di.register<EstoqueController>(estoqueController);

    // CAP.PLANEJAMENTO — controller de planejamento de produção
    // (registrado APÓS EstoqueController pois depende dele)
    try {
      final oldPlanejamento = di.get<PlanoProducaoController>();
      oldPlanejamento.dispose();
    } catch (_) {}
    di.register<PlanoProducaoController>(PlanoProducaoController());

    // CAP.DASHBOARD
    try {
      final oldDashboardController = di.get<DashboardController>();
      oldDashboardController.dispose();
    } catch (_) {}

    final dashboardRepo = DashboardRepository(db: db, tenantContext: context, kdsRepo: ordemPreparoRepo);
    final dashboardService = DashboardService(repository: dashboardRepo);
    final dashboardController = DashboardController(service: dashboardService);
    di.register<DashboardRepository>(dashboardRepo);
    di.register<DashboardService>(dashboardService);
    di.register<DashboardController>(dashboardController);

    // ──────────────────────────────────────────────────────────────
    // 8. Inicializar Supabase SDK + SupabaseSyncService
    // ──────────────────────────────────────────────────────────────
    if (!isTest) {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseKey,
          debug: false,
        );

        supabaseSyncService = SupabaseSyncService(
          supabase: Supabase.instance.client,
          context: context,
          outbox: outboxService,
        );
        di.register<SupabaseSyncService>(supabaseSyncService);
      }
    }

    if (!isTest) {
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final elapsedStr = elapsedMs < 1000 ? '${elapsedMs}ms' : '${(elapsedMs / 1000).toStringAsFixed(2)}s';
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseShort = supabaseUrl.isNotEmpty
          ? '${supabaseUrl.replaceFirst('https://', '').split('.').first}.supabase.co'
          : 'nao configurado';

      await FincoreLogger.instance.beginCycle(
        LogModule.startup,
        'INICIALIZACAO DO SISTEMA FINCORE v1.2.0',
      );
      await LogService.instance.info(LogModule.startup, 'Banco SQLite local inicializado com sucesso (fincore_v3.db)');
      await LogService.instance.info(LogModule.startup, 'Conexao Supabase configurada ($supabaseShort)');
      await LogService.instance.info(LogModule.startup, 'Mecanismo de sincronizacao ativo (Fila de Envio + Tempo Real)');
      await LogService.instance.info(LogModule.startup, 'Inicializacao do sistema concluida com sucesso em $elapsedStr');
      await FincoreLogger.instance.endCycle(LogModule.startup, 'SISTEMA PRONTO PARA USO');
    }
  }
}
