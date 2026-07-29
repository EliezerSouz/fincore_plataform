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
import '../common/domain_primitives.dart';
import 'tables/empresa_configuracao_table.dart';
// CAP.PRINTING: Histórico de Impressões
import 'tables/print_jobs_table.dart';
// Auditoria
import 'tables/audit_logs_table.dart';
import '../src/logging/log_service.dart';

part 'fincore_database.g.dart';

@DataClassName('OutboxEntry')
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
  UsuariosTable,
  CategoriasTable,
  ProdutosTable,
  TabelasPrecificacaoTable,
  ItensTabelaPrecificacaoTable,
  ProdutosTabelasPrecificacaoTable,
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
  EventosEmpresaTable,
  EmpresaConfiguracaoTable,
  // CAP.PRINTING
  PrintJobsTable,
  AuditLogsTable,
])
class FincoreDatabase extends _$FincoreDatabase {
  FincoreDatabase(super.e);

  @override
  int get schemaVersion => 8;

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
          LogService.instance.info(LogModule.migration, 'Atualização de schema concluída com sucesso (v$to)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
