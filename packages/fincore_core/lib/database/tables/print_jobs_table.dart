import 'package:drift/drift.dart';

/// Histórico de impressões realizadas pelo sistema.
/// Cada registro representa uma via impressa (ou tentativa de impressão).
/// Permite reimpressão e auditoria completa.
@DataClassName('PrintJobData')
class PrintJobsTable extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get pedidoId => text()();
  TextColumn get tipoVia => text()();       // 'cliente', 'cozinha', 'balcao', 'expedicao'
  TextColumn get impressora => text()();    // nome/path da impressora usada
  DateTimeColumn get dataHora => dateTime()();
  TextColumn get usuario => text()();
  TextColumn get status => text()();        // 'success', 'error', 'pending', 'cancelled'
  IntColumn get tentativas => integer().withDefault(const Constant(1))();
  TextColumn get erro => text().nullable()();
  IntColumn get tempoExecucaoMs => integer().withDefault(const Constant(0))();
  TextColumn get templateUsado => text().nullable()(); // 'template_cliente', 'template_cozinha', etc.

  @override
  Set<Column> get primaryKey => {id};
}
