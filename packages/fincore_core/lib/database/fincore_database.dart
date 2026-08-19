import 'package:drift/drift.dart';
import 'tables/empresas_table.dart';
import 'tables/usuarios_table.dart';
import 'tables/categorias_table.dart';
import 'tables/produtos_table.dart';
import 'tables/tabelas_precificacao_table.dart';
import 'tables/itens_tabela_precificacao_table.dart';
import 'tables/produtos_tabelas_precificacao_table.dart';
import 'tables/clientes_table.dart';
import 'tables/locais_entrega_table.dart';
import 'tables/formas_pagamento_table.dart';
import 'tables/taxas_entrega_table.dart';
// M6: KDS — Ordens de Preparo e Lotes de Insumos
import 'tables/kds_tables.dart';
// LC-1: Onboarding
import 'tables/membros_empresa_table.dart';
import 'tables/eventos_empresa_table.dart';
import 'tables/empresa_convites_table.dart';
import '../common/domain_primitives.dart';
import 'tables/empresa_configuracao_table.dart';
// CAP.PRINTING: Histórico de Impressões
import 'tables/print_jobs_table.dart';
// Auditoria
import 'tables/audit_logs_table.dart';
import 'tables/categorias_tabelas_precificacao_table.dart';
// P0-01: Tabelas de Pedidos e Itens (ciclo de vida de vendas)
import 'tables/pedidos_table.dart';
// ESTOQUE: Controle de estoque de produtos acabados
import 'tables/estoque_tables.dart';
// FINANCEIRO: Sessões de caixa e lançamentos
import 'tables/financeiro_tables.dart';
import '../src/logging/log_service.dart';

part 'fincore_database.g.dart';

@DataClassName('OutboxEntry')
// P3-04: Índice composto (tenantId, status) para evitar full scan na fila de outbox.
// getPendingEntries() e getOutboxStats() filtram por estes dois campos.
@TableIndex(name: 'outbox_tenant_status_idx', columns: {#tenantId, #status})
class OutboxSync extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tenantId => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get payload => text()();
  TextColumn get status => text()(); // pending, processing, synced, failed, retrying, resolved
  IntColumn get version => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  IntColumn get attemptsCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
}

@DriftDatabase(tables: [
  OutboxSync,
  EmpresasTable,
  EmpresaConvitesTable,
  UsuariosTable,
  CategoriasTable,
  ProdutosTable,
  TabelasPrecificacaoTable,
  ItensTabelaPrecificacaoTable,
  ProdutosTabelasPrecificacaoTable,
  CategoriasTabelasPrecificacaoTable,
  ClientesTable,
  LocaisEntregaTable,
  FormasPagamentoTable,
  TaxasEntregaTable,
  // M6: KDS
  OrdensPreparoTable,
  LotesInsumoTable,
  HistoricosOrdemPreparoTable,
  // LC-1: Onboarding
  MembrosEmpresaTable,
  EmpresaConfiguracaoTable,
  // CAP.PRINTING
  PrintJobsTable,
  AuditLogsTable,
  // P0-01: Pedidos e Itens — ciclo de vida de vendas
  PedidosTable,
  ItensPedidoTable,
  // ESTOQUE: Controle de estoque de produtos acabados
  EstoqueProdutosTable,
  MovimentacoesEstoqueTable,
  // FINANCEIRO: Caixa e lançamentos
  SessoesCaixaTable,
  LancamentosFinanceirosTable,
])
class FincoreDatabase extends _$FincoreDatabase {
  FincoreDatabase(super.e);

  @override
  int get schemaVersion => 20;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          LogService.instance.info(LogModule.migration, 'Iniciando atualização de schema do SQLite (v$from ➔ v$to)');
          if (from < 4) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 004: Criando tabela historicosOrdemPreparo...');
            await m.createTable(historicosOrdemPreparoTable);
            LogService.instance.info(LogModule.migration, 'Migration 004: ✔ OK');
          }
          if (from < 5) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 005: Configurando novas colunas de impressão e tabela printJobs...');
            await m.createTable(printJobsTable);
            // CAP.PRINTING: Novas colunas na empresa_configuracao_table
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN printer_caixa TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN printer_cozinha TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN printer_balcao TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN printer_expedicao TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN auto_print_caixa INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN auto_print_cozinha INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN auto_print_balcao INTEGER NOT NULL DEFAULT 0');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN auto_print_expedicao INTEGER NOT NULL DEFAULT 0');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN vias_cliente INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN vias_cozinha INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN vias_balcao INTEGER NOT NULL DEFAULT 0');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN vias_expedicao INTEGER NOT NULL DEFAULT 0');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN largura_papel INTEGER NOT NULL DEFAULT 80');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN cortar_papel INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN abrir_gaveta INTEGER NOT NULL DEFAULT 0');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN imprimir_q_r_code INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN imprimir_copia_cola INTEGER NOT NULL DEFAULT 1');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN imprimir_logo INTEGER NOT NULL DEFAULT 0');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN imprimir_rodape INTEGER NOT NULL DEFAULT 1');
            await customStatement("ALTER TABLE empresa_configuracao_table ADD COLUMN mensagem_rodape TEXT NOT NULL DEFAULT 'Obrigado pela preferência!'");
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN pix_favorecido TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN pix_banco TEXT');
            await customStatement("ALTER TABLE empresa_configuracao_table ADD COLUMN pix_tipo TEXT NOT NULL DEFAULT 'CPF'");
            await customStatement("ALTER TABLE empresa_configuracao_table ADD COLUMN pix_cidade TEXT NOT NULL DEFAULT 'Sorocaba'");
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN nome_empresa_cupom TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN telefone_empresa TEXT');
            LogService.instance.info(LogModule.migration, 'Migration 005: ✔ OK');
          }
          if (from < 6) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 006: Adicionando cnpj e endereco a empresa_configuracao...');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN cnpj_empresa TEXT');
            await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN endereco_empresa TEXT');
            LogService.instance.info(LogModule.migration, 'Migration 006: ✔ OK');
          }
          if (from < 7) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 007: Criando tabela audit_logs...');
            await m.createTable(auditLogsTable);
            LogService.instance.info(LogModule.migration, 'Migration 007: ✔ OK');
          }
          if (from < 8) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 008: Adicionando sync_version a audit_logs_table...');
            await customStatement('ALTER TABLE audit_logs_table ADD COLUMN sync_version INTEGER');
            LogService.instance.info(LogModule.migration, 'Migration 008: ✔ OK');
          }
          if (from < 9) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 009: IAM Revamp (UsuariosTable + Colunas Fiscais em EmpresasTable)...');
            // Nota: empresa_convites_table é criada/corrigida na migration 015.
            // As tentativas abaixo são idempotentes (try/catch).
            try { await customStatement('ALTER TABLE usuarios_table ADD COLUMN tenant_id TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE usuarios_table ADD COLUMN auth_user_id TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE usuarios_table ADD COLUMN username TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE usuarios_table ADD COLUMN ativo INTEGER NOT NULL DEFAULT 1'); } catch (_) {}
            try { await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS usr_tenant_username_idx ON usuarios_table (tenant_id, username)'); } catch (_) {}

            // Colunas fiscais e cadastrais na empresas_table
            try { await customStatement("ALTER TABLE empresas_table ADD COLUMN tipo_pessoa TEXT NOT NULL DEFAULT 'JURIDICA'"); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN inscricao_estadual TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN inscricao_municipal TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN regime_tributario TEXT'); } catch (_) {}
            // Nota: coluna 'endereco' legada era adicionada aqui; os 7 campos estruturados são adicionados na migration 015.

            LogService.instance.info(LogModule.migration, 'Migration 009: ✔ OK');
          }
          if (from < 10) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 010: Criando tabela categorias_tabelas_precificacao...');
            await m.createTable(categoriasTabelasPrecificacaoTable);
            LogService.instance.info(LogModule.migration, 'Migration 010: ✔ OK');
          }
          if (from < 12) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 012: Adicionando colunas comerciais à taxas_entrega_table...');
            try { await customStatement('ALTER TABLE taxas_entrega_table ADD COLUMN pedido_minimo_centavos INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            try { await customStatement('ALTER TABLE taxas_entrega_table ADD COLUMN prazo_estimado TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE taxas_entrega_table ADD COLUMN observacoes TEXT'); } catch (_) {}
            LogService.instance.info(LogModule.migration, 'Migration 012: ✔ OK');
          }
          if (from < 13) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 013: Criando tabelas de Pedidos e Itens do Pedido (P0-01)...');
            await m.createTable(pedidosTable);
            await m.createTable(itensPedidoTable);
            try {
              await customStatement(
                'CREATE INDEX IF NOT EXISTS outbox_tenant_status_idx ON outbox_sync (tenant_id, status)',
              );
            } catch (_) {}
            LogService.instance.info(LogModule.migration, 'Migration 013: ✔ OK — Tabelas pedidos_table e itens_pedido_table criadas.');
          }
          if (from < 14) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 014: Adicionando campo canal à tabelas_precificacao_table (P1-07)...');
            // Valor padrão 'todos' mantém compatibilidade retroativa — todas as tabelas
            // existentes passam a responder a qualquer canal até serem explicitamente configuradas.
            try {
              await customStatement(
                "ALTER TABLE tabelas_precificacao_table ADD COLUMN canal TEXT NOT NULL DEFAULT 'todos'",
              );
            } catch (_) {}
            LogService.instance.info(LogModule.migration, 'Migration 014: ✔ OK — Campo canal adicionado com default todos.');
          }
          if (from < 15) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 015: Endereço estruturado + EmpresaConvitesTable com schema correto...');
            // ── empresas_table: 7 colunas de endereço estruturado (idempotente) ──
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN cep TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN logradouro TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN numero TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN complemento TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN bairro TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN cidade TEXT'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresas_table ADD COLUMN estado TEXT'); } catch (_) {}
            // ── empresa_configuracao_table: 4 colunas de conectores ativos ──
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN mercado_pago_ativo INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN open_pix_ativo INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN asaas_ativo INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN ifood_ativo INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            // ── empresa_convites_table: corrigir schema legado da migration 009 ──
            // A migration 009 criou a tabela com colunas incorretas (token, expires_at).
            // Como empresa_convite é Pull-only, descartamos a tabela antiga e Drift recria
            // com o schema correto via m.createTable(). Convites serão re-sincronizados
            // do Supabase no próximo Pull.
            try { await customStatement('DROP TABLE IF EXISTS empresa_convites_table'); } catch (_) {}
            await m.createTable(empresaConvitesTable);
            LogService.instance.info(LogModule.migration, 'Migration 015: ✔ OK');
          }
          if (from < 16) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 016: Adicionando margem_seguranca_minutos a empresa_configuracao...');
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN margem_seguranca_minutos INTEGER NOT NULL DEFAULT 10'); } catch (_) {}
            LogService.instance.info(LogModule.migration, 'Migration 016: ✔ OK');
          }
          if (from < 17) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 017: Adicionando colunas de entrega por KM à empresa_configuracao...');
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN taxa_entrega_por_km INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            try { await customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN valor_por_km_centavos INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            LogService.instance.info(LogModule.migration, 'Migration 017: ✔ OK');
          }
          if (from < 18) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 018: Criando tabelas de Estoque (produtos acabados)...');
            await m.createTable(estoqueProdutosTable);
            await m.createTable(movimentacoesEstoqueTable);
            LogService.instance.info(LogModule.migration, 'Migration 018: ✔ OK — Tabelas estoque_produtos_table e movimentacoes_estoque_table criadas.');
          }
          if (from < 19) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 019: Criando tabelas Financeiras (sessões de caixa e lançamentos)...');
            await m.createTable(sessoesCaixaTable);
            await m.createTable(lancamentosFinanceirosTable);
            LogService.instance.info(LogModule.migration, 'Migration 019: ✔ OK — Tabelas sessoes_caixa_table e lancamentos_financeiros_table criadas.');
          }
          if (from < 20) {
            LogService.instance.info(LogModule.migration, 'Executando Migration 020: Adicionando campos de Produção e Reserva ao Estoque...');
            // Novos campos em estoque_produtos_table
            try { await customStatement('ALTER TABLE estoque_produtos_table ADD COLUMN quantidade_reservada INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
            try { await customStatement('ALTER TABLE estoque_produtos_table ADD COLUMN quantidade_producao_lote INTEGER NOT NULL DEFAULT 100'); } catch (_) {}
            try { await customStatement('ALTER TABLE estoque_produtos_table ADD COLUMN dias_cobertura_alvo INTEGER NOT NULL DEFAULT 3'); } catch (_) {}
            // Novos campos em movimentacoes_estoque_table
            try { await customStatement('ALTER TABLE movimentacoes_estoque_table ADD COLUMN quantidade_reservada_antes INTEGER'); } catch (_) {}
            try { await customStatement('ALTER TABLE movimentacoes_estoque_table ADD COLUMN quantidade_reservada_depois INTEGER'); } catch (_) {}
            try { await customStatement('ALTER TABLE movimentacoes_estoque_table ADD COLUMN data_entrega_prevista INTEGER'); } catch (_) {}
            // Índice adicional para consultas de planejamento por data
            try { await customStatement('CREATE INDEX IF NOT EXISTS mov_estoque_data_hora_idx ON movimentacoes_estoque_table (tenant_id, data_hora)'); } catch (_) {}
            LogService.instance.info(LogModule.migration, 'Migration 020: ✔ OK — Campos de produção e reserva adicionados.');
          }
          LogService.instance.info(LogModule.migration, 'Atualização de schema concluída com sucesso (v$to)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          
          // Garante que colunas novas e legadas de tipos não-nulos não possuam NULL físico no SQLite local
          try {
            await customStatement('UPDATE empresa_configuracao_table SET mercado_pago_ativo = 0 WHERE mercado_pago_ativo IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET open_pix_ativo = 0 WHERE open_pix_ativo IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET asaas_ativo = 0 WHERE asaas_ativo IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET ifood_ativo = 0 WHERE ifood_ativo IS NULL');
            
            await customStatement('UPDATE empresa_configuracao_table SET auto_print_caixa = 1 WHERE auto_print_caixa IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET auto_print_cozinha = 1 WHERE auto_print_cozinha IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET auto_print_balcao = 0 WHERE auto_print_balcao IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET auto_print_expedicao = 0 WHERE auto_print_expedicao IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET vias_cliente = 1 WHERE vias_cliente IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET vias_cozinha = 1 WHERE vias_cozinha IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET vias_balcao = 0 WHERE vias_balcao IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET vias_expedicao = 0 WHERE vias_expedicao IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET largura_papel = 80 WHERE largura_papel IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET cortar_papel = 1 WHERE cortar_papel IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET abrir_gaveta = 0 WHERE abrir_gaveta IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET imprimir_q_r_code = 1 WHERE imprimir_q_r_code IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET imprimir_copia_cola = 1 WHERE imprimir_copia_cola IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET imprimir_logo = 0 WHERE imprimir_logo IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET imprimir_rodape = 1 WHERE imprimir_rodape IS NULL');
            await customStatement("UPDATE empresa_configuracao_table SET mensagem_rodape = 'Obrigado pela preferência!' WHERE mensagem_rodape IS NULL");
            await customStatement("UPDATE empresa_configuracao_table SET pix_tipo = 'CPF' WHERE pix_tipo IS NULL");
            await customStatement('UPDATE empresa_configuracao_table SET taxa_servico = 0.10 WHERE taxa_servico IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET usar_whats_app = 1 WHERE usar_whats_app IS NULL');
            await customStatement("UPDATE empresa_configuracao_table SET tema = 'dark' WHERE tema IS NULL");
            
            await customStatement('UPDATE empresa_configuracao_table SET modo_delivery_ativo = 1 WHERE modo_delivery_ativo IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET modo_comandas_ativo = 0 WHERE modo_comandas_ativo IS NULL');
            await customStatement('UPDATE empresa_configuracao_table SET cliente_obrigatorio_venda = 0 WHERE cliente_obrigatorio_venda IS NULL');
            await customStatement("UPDATE empresa_configuracao_table SET atendimento_padrao = 'Delivery' WHERE atendimento_padrao IS NULL");
            await customStatement('UPDATE empresa_configuracao_table SET margem_seguranca_minutos = 10 WHERE margem_seguranca_minutos IS NULL');
          } catch (_) {}

          try {
            await customStatement('UPDATE empresa_configuracao_table SET taxa_entrega_por_km = 0 WHERE taxa_entrega_por_km IS NULL');
          } catch (_) {}
          try {
            await customStatement('UPDATE empresa_configuracao_table SET valor_por_km_centavos = 0 WHERE valor_por_km_centavos IS NULL');
          } catch (_) {}

          // Fallback de desenvolvimento: garante existência das novas colunas de taxas de entrega
          try {
            await customStatement('ALTER TABLE taxas_entrega_table ADD COLUMN pedido_minimo_centavos INTEGER');
          } catch (_) {}
          try {
            await customStatement('ALTER TABLE taxas_entrega_table ADD COLUMN prazo_estimado TEXT');
          } catch (_) {}
          try {
            await customStatement('ALTER TABLE taxas_entrega_table ADD COLUMN observacoes TEXT');
          } catch (_) {}
        },
      );
}
