import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_core/database/fincore_seeds.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/forma_pagamento_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/pricing_engine.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/repository/lote_insumo_repository.dart';
import 'package:fincore_core/usecase/estornar_lote_estoque_usecase.dart';
import 'package:fincore_food_flutter/src/dashboard/data/dashboard_repository.dart';
import 'package:fincore_food_flutter/src/dashboard/domain/dashboard_service.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:fincore_core/repository/usuario_repository.dart';
import 'package:fincore_core/repository/empresa_repository.dart';
import 'package:fincore_core/repository/membro_empresa_repository.dart';
import 'package:fincore_core/repository/print_job_repository.dart';
import 'package:fincore_food_flutter/src/cap/printing/usecases/print_use_case.dart';

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
    final bool isTest = Platform.environment.containsKey('FLUTTER_TEST');

    // ──────────────────────────────────────────────────────────────
    // 0. Inicializar Serviço de Logs unificado
    // ──────────────────────────────────────────────────────────────
    if (!isTest) {
      final docDir = await getApplicationDocumentsDirectory();
      LogService.init(docDir.path);
      await LogService.instance.info(LogModule.app, 'FINCORE Platform inicializado com sucesso.');
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
    if (isTest) {
      db = FincoreDatabase(NativeDatabase.memory());
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'fincore_v3.db'));
      db = FincoreDatabase(NativeDatabase(file));
    }

    // ──────────────────────────────────────────────────────────────
    // 3. Contexto de Tenant e Supabase
    // ──────────────────────────────────────────────────────────────
    final context = TenantContext();

    // ──────────────────────────────────────────────────────────────
    // 4. Seeds de dados iniciais
    // ──────────────────────────────────────────────────────────────
    final empresas = await db.select(db.empresasTable).get();
    if (empresas.isEmpty) {
      await FincoreSeeds.populate(db);
    }

    // ──────────────────────────────────────────────────────────────
    // 5. Infraestrutura de Sync
    // O OutboxService e SyncEngine são criados ANTES dos repositórios
    // para que possam ser injetados como dependência obrigatória
    // ──────────────────────────────────────────────────────────────
    final outboxService = OutboxService(db: db, context: context);

    // SupabaseSyncService será configurado após a inicialização do Supabase
    // O SyncEngine recebe o handler de push via construtor
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
    final empresaRepo = EmpresaRepository(db: db, context: context);
    final membroRepo = MembroEmpresaRepository(db: db, context: context);
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

    final pricingEngine = PricingEngine(
      tabelaRepo: tabelaRepo,
      itemRepo: itemRepo,
      assocRepo: assocRepo,
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
    di.register<UsuarioRepository>(usuarioRepo);
    di.register<EmpresaRepository>(empresaRepo);
    di.register<TabelaPrecificacaoRepository>(tabelaRepo);
    di.register<ItemTabelaPrecificacaoRepository>(itemRepo);
    di.register<ProdutoTabelaPrecificacaoRepository>(assocRepo);
    di.register<PricingEngine>(pricingEngine);
    di.register<OrdemPreparoRepository>(ordemPreparoRepo);
    di.register<LoteInsumoRepository>(loteInsumoRepo);
    di.register<EstornarLoteEstoqueUseCase>(estornarLoteEstoqueUseCase);
    // CAP.PRINTING
    di.register<PrintJobRepository>(printJobRepo);
    di.register<PrintUseCase>(printUseCase);

    // CAP.DASHBOARD
    final dashboardRepo = DashboardRepository(db: db, tenantContext: context, KdsRepo: ordemPreparoRepo);
    final dashboardService = DashboardService(repository: dashboardRepo);
    di.register<DashboardRepository>(dashboardRepo);
    di.register<DashboardService>(dashboardService);

    // ──────────────────────────────────────────────────────────────
    // 8. Inicializar Supabase SDK + SupabaseSyncService
    // ──────────────────────────────────────────────────────────────
    if (!isTest) {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
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
          ? supabaseUrl.replaceFirst('https://', '').split('.').first + '.supabase.co'
          : 'nao configurado';

      LogService.instance.info(
        LogModule.startup,
        '''
╔═══════════════════════════════════════╗
║  FINCORE  v1.2.0  |  STARTUP OK      ║
╚═══════════════════════════════════════╝
  ✔ SQLite local  fincore_v3.db
  ✔ Supabase      $supabaseShort
  ✔ Sync Engine   ativo (outbox + push/pull)
  ✔ Bootstrap     $elapsedStr
───────────────────────────────────────''',
      );
    }
  }
}
