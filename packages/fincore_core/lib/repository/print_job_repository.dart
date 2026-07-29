import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/fincore_database.dart';
import '../context/tenant_context.dart';

/// Modelo de domínio para um job de impressão.
class PrintJob {
  final String id;
  final String tenantId;
  final String pedidoId;
  final String tipoVia;
  final String impressora;
  final DateTime dataHora;
  final String usuario;
  final String status;
  final int tentativas;
  final String? erro;
  final int tempoExecucaoMs;
  final String? templateUsado;

  const PrintJob({
    required this.id,
    required this.tenantId,
    required this.pedidoId,
    required this.tipoVia,
    required this.impressora,
    required this.dataHora,
    required this.usuario,
    required this.status,
    this.tentativas = 1,
    this.erro,
    this.tempoExecucaoMs = 0,
    this.templateUsado,
  });

  PrintJob copyWith({
    String? status,
    int? tentativas,
    String? erro,
    int? tempoExecucaoMs,
  }) {
    return PrintJob(
      id: id,
      tenantId: tenantId,
      pedidoId: pedidoId,
      tipoVia: tipoVia,
      impressora: impressora,
      dataHora: dataHora,
      usuario: usuario,
      status: status ?? this.status,
      tentativas: tentativas ?? this.tentativas,
      erro: erro ?? this.erro,
      tempoExecucaoMs: tempoExecucaoMs ?? this.tempoExecucaoMs,
      templateUsado: templateUsado,
    );
  }
}

/// Repositório para histórico de impressões.
/// Somente local (sem sync bidirecional — print_jobs são locais ao dispositivo).
class PrintJobRepository {
  final FincoreDatabase db;
  final TenantContext context;

  PrintJobRepository({required this.db, required this.context});

  String get _tenantId => context.tenantId;

  /// Registra um novo job de impressão.
  Future<PrintJob> create({
    required String pedidoId,
    required String tipoVia,
    required String impressora,
    required String usuario,
    String? templateUsado,
  }) async {
    final job = PrintJob(
      id: const Uuid().v4(),
      tenantId: _tenantId,
      pedidoId: pedidoId,
      tipoVia: tipoVia,
      impressora: impressora,
      dataHora: DateTime.now().toUtc(),
      usuario: usuario,
      status: 'pending',
      templateUsado: templateUsado,
    );
    await _saveLocal(job);
    return job;
  }

  /// Atualiza o status de um job (ex: pending → success ou error).
  Future<void> updateStatus(String jobId, {
    required String status,
    String? erro,
    int? tempoExecucaoMs,
    int? tentativas,
  }) async {
    await (db.update(db.printJobsTable)
          ..where((t) => t.id.equals(jobId)))
        .write(PrintJobsTableCompanion(
      status: Value(status),
      erro: Value(erro),
      tempoExecucaoMs: tempoExecucaoMs != null ? Value(tempoExecucaoMs) : const Value.absent(),
      tentativas: tentativas != null ? Value(tentativas) : const Value.absent(),
    ));
  }

  /// Lista todos os jobs de um pedido específico.
  Future<List<PrintJob>> findByPedidoId(String pedidoId) async {
    final rows = await (db.select(db.printJobsTable)
          ..where((t) => t.pedidoId.equals(pedidoId) & t.tenantId.equals(_tenantId))
          ..orderBy([(t) => OrderingTerm.desc(t.dataHora)]))
        .get();
    return rows.map(_mapToEntity).toList();
  }

  /// Lista os últimos N jobs (para dashboard/histórico).
  Future<List<PrintJob>> findRecent({int limit = 50}) async {
    final rows = await (db.select(db.printJobsTable)
          ..where((t) => t.tenantId.equals(_tenantId))
          ..orderBy([(t) => OrderingTerm.desc(t.dataHora)])
          ..limit(limit))
        .get();
    return rows.map(_mapToEntity).toList();
  }

  /// Busca jobs com erro para retry.
  Future<List<PrintJob>> findPending() async {
    final rows = await (db.select(db.printJobsTable)
          ..where((t) => t.tenantId.equals(_tenantId) & t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.dataHora)]))
        .get();
    return rows.map(_mapToEntity).toList();
  }

  Future<void> _saveLocal(PrintJob job) async {
    await db.into(db.printJobsTable).insertOnConflictUpdate(
          PrintJobsTableCompanion.insert(
            id: job.id,
            tenantId: job.tenantId,
            pedidoId: job.pedidoId,
            tipoVia: job.tipoVia,
            impressora: job.impressora,
            dataHora: job.dataHora,
            usuario: job.usuario,
            status: job.status,
            tentativas: Value(job.tentativas),
            erro: Value(job.erro),
            tempoExecucaoMs: Value(job.tempoExecucaoMs),
            templateUsado: Value(job.templateUsado),
          ),
        );
  }

  PrintJob _mapToEntity(PrintJobData data) {
    return PrintJob(
      id: data.id,
      tenantId: data.tenantId,
      pedidoId: data.pedidoId,
      tipoVia: data.tipoVia,
      impressora: data.impressora,
      dataHora: data.dataHora,
      usuario: data.usuario,
      status: data.status,
      tentativas: data.tentativas,
      erro: data.erro,
      tempoExecucaoMs: data.tempoExecucaoMs,
      templateUsado: data.templateUsado,
    );
  }
}
