import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database_connection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'package:fincore_food_flutter/src/financeiro/controllers/contas_receber_controller.dart';

import 'package:fincore_food_flutter/src/shared/services/dpapi_env_service.dart';

/// Responsável por inicializar toda a infraestrutura da FINCORE Platform:
///
/// 1. Variáveis de ambiente (.env via flutter_dotenv e DPAPI)
/// 2. Banco de dados local Drift SQLite (offline-first)
/// 3. Contexto de Tenant ativo
/// 4. Seeds de dados iniciais
/// 5. Repositórios de domínio com Sync OBRIGATÓRIO via SyncableRepository
/// 6. Container de Injeção de Dependências
/// 7. Supabase SDK (banco central remoto + Realtime)
///
/// Arquitetura local-first (sem Serverpod):
/// ```
/// Flutter (Drift SQLite local) → OutboxService → SupabaseSyncService → Supabase PostgreSQL
///                                                        ↑
///                                              Realtime WebSocket ←┘
/// ```
class DatabaseInitializer {
  static Future<void> init() async {
    final stopwatch = Stopwatch()..start();
    final bool isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    // ──────────────────────────────────────────────────────────────
    // 0. Inicializar Serviço de Logs unificado
    // ──────────────────────────────────────────────────────────────
    if (kIsWeb) {
      LogService.init('', appVersion: AppConstants.version);
      await LogService.instance.info(LogModule.app, 'FINCORE Platform inicializado com sucesso (Web).');
    } else if (!isTest) {
      // Pasta LOG criada no mesmo diretório onde o executável (.exe) está rodando
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final logDir = p.join(exeDir, 'LOG');
      LogService.init(logDir, appVersion: AppConstants.version);
      await LogService.instance.info(LogModule.app, 'FINCORE Platform inicializado com sucesso.');
    } else {
      try {
        LogService.init(Directory.systemTemp.path);
      } catch (_) {}
    }

    // ──────────────────────────────────────────────────────────────
    // 1. Carregar variáveis de ambiente (.env) de forma segura com DPAPI
    // ──────────────────────────────────────────────────────────────
    if (!isTest) {
      try {
        await DpapiEnvService.loadSecure();
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
      final String dbPath;
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        final dataDir = Directory(p.join(exeDir, 'DATA'));
        if (!dataDir.existsSync()) {
          dataDir.createSync(recursive: true);
        }
        dbPath = p.join(dataDir.path, 'fincore_v3.db');

        // Migração transparente do banco antigo de Documents para DATA se existir
        try {
          final targetFile = File(dbPath);
          if (!targetFile.existsSync()) {
            final docsFolder = await getApplicationDocumentsDirectory();
            final oldDb = File(p.join(docsFolder.path, 'fincore_v3.db'));
            if (oldDb.existsSync()) {
              oldDb.copySync(dbPath);
              final oldWal = File(p.join(docsFolder.path, 'fincore_v3.db-wal'));
              if (oldWal.existsSync()) oldWal.copySync(p.join(dataDir.path, 'fincore_v3.db-wal'));
              final oldShm = File(p.join(docsFolder.path, 'fincore_v3.db-shm'));
              if (oldShm.existsSync()) oldShm.copySync(p.join(dataDir.path, 'fincore_v3.db-shm'));
            }
          }
        } catch (_) {}
      } else {
        final dbFolder = await getApplicationDocumentsDirectory();
        dbPath = p.join(dbFolder.path, 'fincore_v3.db');
      }

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

      // Auto-heal: reparar sessao_avulsa% em lancamentos_financeiros e outboxSync
      final defaultTenant = '65109ff8-443f-41ce-94c8-8311dfc79764';
      final defaultUser = '00000000-0000-0000-0000-000000000000';
      
      var sessaoAtiva = await (db.select(db.sessoesCaixaTable)
            ..where((t) => t.status.equals('aberta') & t.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();
      
      if (sessaoAtiva == null) {
        final newSessaoId = const Uuid().v4();
        final now = DateTime.now().toUtc();
        await db.into(db.sessoesCaixaTable).insert(
          SessoesCaixaTableCompanion.insert(
            id: newSessaoId,
            tenantId: defaultTenant,
            operadorId: defaultUser,
            operadorNome: const Value('Operador Caixa'),
            dataAbertura: now,
            status: const Value('aberta'),
            valorAberturaCentavos: const Value(0),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: defaultUser,
            updatedBy: defaultUser,
          ),
        );
        sessaoAtiva = await (db.select(db.sessoesCaixaTable)..where((t) => t.id.equals(newSessaoId))).getSingle();
      }

      final validSessaoId = sessaoAtiva.id;

      // 2. Reparar lançamentos financeiros locais com sessao_avulsa%
      await db.customUpdate(
        "UPDATE lancamentos_financeiros SET sessao_caixa_id = ? WHERE sessao_caixa_id LIKE 'sessao_avulsa%'",
        variables: [Variable.withString(validSessaoId)],
        updates: {db.lancamentosFinanceirosTable},
      );

      // 3. Reparar payloads no Outbox com sessao_avulsa%
      final outboxEntries = await (db.select(db.outboxSync)
            ..where((t) => t.entity.equals('lancamento_financeiro') & t.payload.like('%sessao_avulsa%')))
          .get();

      for (final entry in outboxEntries) {
        try {
          final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
          payload['sessaoCaixaId'] = validSessaoId;
          final newPayloadJson = jsonEncode(payload);
          await (db.update(db.outboxSync)..where((t) => t.id.equals(entry.id))).write(
            OutboxSyncCompanion(
              payload: Value(newPayloadJson),
              status: const Value('pending'),
              attemptsCount: const Value(0),
              errorMessage: const Value(null),
            ),
          );
        } catch (_) {}
      }
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

    outboxService.onMutationEnqueued = () {
      syncEngine.processPendingQueue().catchError((_) => const SyncResult(
            successCount: 0,
            failureCount: 0,
            hasPendingAfter: true,
          ));
    };

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

    // Garante cliente Consumidor Final padrão para todas as empresas registradas
    for (final emp in coreEmpresas) {
      try {
        await clienteRepo.ensureConsumidorFinalForTenant(emp.id);
      } catch (_) {}
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
    // NOTA: Client do Serverpod removido — arquitetura local-first

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

    // FINANCEIRO.CONTAS_RECEBER
    try {
      final oldContas = di.get<ContasReceberController>();
      oldContas.dispose();
    } catch (_) {}
    di.register<ContasReceberController>(ContasReceberController());

    // ──────────────────────────────────────────────────────────────
    // 8. Inicializar Supabase SDK + SupabaseSyncService
    // ──────────────────────────────────────────────────────────────
    if (!isTest) {
      var supabaseUrl = dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';
      var supabaseKey = dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

      if (supabaseUrl.isEmpty) {
        supabaseUrl = 'https://nlaxdeqbordmovukyypk.supabase.co';
      }
      if (supabaseKey.isEmpty) {
        supabaseKey = 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy';
      }

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
      final supabaseUrl = dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';
      final supabaseShort = supabaseUrl.isNotEmpty
          ? '${supabaseUrl.replaceFirst('https://', '').split('.').first}.supabase.co'
          : 'nao configurado';

      await FincoreLogger.instance.beginCycle(
        LogModule.startup,
        'INICIALIZACAO DO SISTEMA FINCORE ${AppConstants.version}',
      );
      await LogService.instance.info(LogModule.startup, 'Banco SQLite local inicializado com sucesso (fincore_v3.db)');
      await LogService.instance.info(LogModule.startup, 'Arquitetura local-first ativa (sem Serverpod)');
      await LogService.instance.info(LogModule.startup, 'Conexao Supabase configurada ($supabaseShort)');
      await LogService.instance.info(LogModule.startup, 'Mecanismo de sincronizacao ativo (Fila de Envio + Tempo Real)');
      await LogService.instance.info(LogModule.startup, 'Inicializacao do sistema concluida com sucesso em $elapsedStr');
      await FincoreLogger.instance.endCycle(LogModule.startup, 'SISTEMA PRONTO PARA USO');
    }
  }
}
