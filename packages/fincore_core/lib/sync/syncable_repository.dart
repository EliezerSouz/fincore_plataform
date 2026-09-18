import 'dart:async';
import 'dart:convert';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'outbox_service.dart';
import 'sync_engine.dart';
import '../di/dependency_injection.dart';
import '../repository/audit_log_repository.dart';
import '../common/diff_util.dart';
import '../src/logging/log_service.dart';

/// Contrato de sincronização obrigatório para todas as entidades do domínio.
///
/// Qualquer repositório que extende [SyncableRepository] garante que
/// TODA operação de escrita (save/delete) gera um rastro no [OutboxService]
/// dentro da MESMA transação Drift — tornando impossível salvar sem sincronizar.
///
/// O [SyncEngine.triggerImmediate()] é chamado após cada mutação para
/// tentar o push imediatamente (se houver conexão). Caso contrário,
/// o dado fica no outbox e é enviado no próximo ciclo de polling.
abstract class SyncableRepository<T> {
  final FincoreDatabase db;
  final TenantContext context;
  final OutboxService outbox;
  final SyncEngine? syncEngine;

  SyncableRepository({
    required this.db,
    required this.context,
    required this.outbox,
    this.syncEngine,
  });

  // ──────────────────────────────────────────────────────────
  // Contrato obrigatório — cada repositório implementa estes:
  // ──────────────────────────────────────────────────────────

  /// Nome da entidade no outbox (ex: 'empresa_configuracao', 'produtos').
  String get entityName;

  /// Serializa a entidade para o payload JSON que vai para o outbox → Supabase.
  Map<String, dynamic> toOutboxPayload(T entity);

  /// Extrai o ID único (UUID String) da entidade.
  String extractId(T entity);

  /// Extrai a versão de sync atual da entidade.
  int extractVersion(T entity);

  // ──────────────────────────────────────────────────────────
  // CRUD padrão — implementado por cada repositório filho
  // ──────────────────────────────────────────────────────────

  Future<T?> findById(String id);
  Future<List<T>> findAll();

  /// Grava no SQLite local. NÃO chame diretamente — use [saveWithSync].
  Future<void> saveLocal(T entity);

  /// Soft delete no SQLite local. NÃO chame diretamente — use [deleteWithSync].
  Future<void> deleteLocal(String id, T entity);

  // ──────────────────────────────────────────────────────────
  // API pública: sempre usa sync obrigatório
  // ──────────────────────────────────────────────────────────

  Future<T> saveWithSync(T entity, {String? traceId}) async {
    final effectiveTraceId = traceId ?? CorrelationIdGenerator.generateCorrelationId();
    final id = extractId(entity);
    final oldEntity = await findById(id);
    final oldVersion = oldEntity != null ? extractVersion(oldEntity) : 0;
    final entityVersion = extractVersion(entity);
    final currentMax = oldVersion > entityVersion ? oldVersion : entityVersion;
    final newVersion = currentMax + 1;

    final isUpdate = oldEntity != null;
    Map<String, dynamic>? diff;
    if (isUpdate) {
      diff = generateJsonDiff(
        toOutboxPayload(oldEntity),
        toOutboxPayload(entity),
      );
    }

    final outboxPayload = toOutboxPayload(entity);
    outboxPayload['_traceId'] = effectiveTraceId;

    await db.transaction(() async {
      // 1. Grava no SQLite local
      await saveLocal(entity);

      // 2. Enfileira no outbox — ATÔMICO com o save local
      await outbox.enqueue(
        entity: entityName,
        entityId: extractId(entity),
        action: 'UPSERT',
        payload: outboxPayload,
        version: newVersion,
      );

      // 3. Registra Auditoria (apenas se houver mudanças reais num UPDATE ou se for CREATE)
      bool shouldLogAudit = true;
      if (isUpdate && (diff == null || diff!.isEmpty)) {
        shouldLogAudit = false;
      }

      if (shouldLogAudit) {
        try {
          final auditRepo = DependencyInjection().get<AuditLogRepository>();
          await auditRepo.log(
            entityName: entityName,
            entityId: id,
            userId: context.hasContext ? context.usuario.id : 'system',
            action: isUpdate ? 'UPDATE' : 'CREATE',
            diff: diff,
            syncVersion: newVersion,
            deviceInfo: 'App',
            origin: 'Mobile/PDV',
          );
        } catch (e) {
          // Ignorar falha se o repositório de auditoria não estiver registrado ainda
        }
      }
    });

    final diffDetails = (isUpdate && diff != null && diff.isNotEmpty)
        ? 'Alterações: ${jsonEncode(diff)}'
        : null;

    await LogService.instance.logDatabase(
      step: 'MUTACAO_LOCAL',
      action: isUpdate ? 'UPDATE' : 'CREATE',
      entity: entityName,
      id: id,
      version: newVersion,
      oldVersion: oldVersion > 0 ? oldVersion : null,
      traceId: effectiveTraceId,
      details: diffDetails,
      tenantId: context.hasContext ? context.tenantId : null,
      status: LogStatus.success,
    );

    // 3. Tenta push imediato (fire-and-forget — não bloqueia a UI)
    _triggerPush();

    return entity;
  }

  /// Deleta localmente e enfileira no outbox em uma única transação atômica.
  Future<void> deleteWithSync(String id, {String? traceId}) async {
    final effectiveTraceId = traceId ?? CorrelationIdGenerator.generateCorrelationId();
    final entity = await findById(id);
    if (entity == null) return;
    final oldVersion = extractVersion(entity);
    final newVersion = oldVersion + 1;

    await db.transaction(() async {
      // 1. Soft delete local
      await deleteLocal(id, entity);

      // 2. Enfileira DELETE no outbox — ATÔMICO
      await outbox.enqueue(
        entity: entityName,
        entityId: id,
        action: 'DELETE',
        payload: {
          'id': id,
          'tenantId': context.tenantId,
          '_traceId': effectiveTraceId,
        },
        version: newVersion,
      );

      // 3. Registra Auditoria de DELETE
      try {
        final auditRepo = DependencyInjection().get<AuditLogRepository>();
        await auditRepo.log(
          entityName: entityName,
          entityId: id,
          userId: context.hasContext ? context.usuario.id : 'system',
          action: 'DELETE',
          syncVersion: newVersion,
          deviceInfo: 'App',
          origin: 'Mobile/PDV',
        );
      } catch (e) {
        // Ignorar falha se o repositório não estiver registrado
      }
    });

    await LogService.instance.logDatabase(
      step: 'MUTACAO_LOCAL',
      action: 'DELETE',
      entity: entityName,
      id: id,
      version: newVersion,
      oldVersion: oldVersion > 0 ? oldVersion : null,
      traceId: effectiveTraceId,
      details: 'Exclusão lógica (soft delete)',
      tenantId: context.hasContext ? context.tenantId : null,
      status: LogStatus.success,
    );

    _triggerPush();
  }

  // ──────────────────────────────────────────────────────────
  // Helpers internos
  // ──────────────────────────────────────────────────────────

  String get activeTenantId => context.tenantId;

  void _triggerPush() {
    // Fire-and-forget — não await para não bloquear a UI
    syncEngine?.processPendingQueue().catchError((_) {
      return const SyncResult(successCount: 0, failureCount: 0, hasPendingAfter: true);
    });
  }
}
