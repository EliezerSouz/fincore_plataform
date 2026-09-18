import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Níveis de Severidade de Log (Padronização FINCORE Enterprise).
enum LogLevel {
  trace,
  debug,
  info,
  notice,
  warning,
  error,
  critical,
  audit,
}

/// Alias de compatibilidade com código existente.
typedef LogSeverity = LogLevel;

/// Categorias Principais de Observabilidade.
enum LogCategory {
  operacional,
  auditoria,
  sincronizacao,
  bancoDados,
  rede,
  autenticacao,
  seguranca,
  sistema,
  performance,
  integracao,
  erro,
  audit,
  sync,
  error,
  database,
  security,
  printer,
  api,
  business,
}

/// Módulos do sistema FINCORE para categorização dos logs.
enum LogModule {
  startup,
  sync,
  database,
  api,
  migration,
  printer,
  crash,
  app,
  importExport,
  audit,
  estoque,
  producao,
  pedidos,
  financeiro,
}

/// Destino de roteamento de telemetria e auditoria.
enum LogDestination {
  localOnly,
  cloudOnly,
  both,
  supabase,
  api,
  printer,
  externalService,
}

/// Origem da Operação.
enum LogSource {
  local,
  remote,
  user,
  system,
  sync,
  scheduled,
  integration,
}

/// Estado da Operação.
enum LogStatus {
  started,
  inProgress,
  success,
  partial,
  failed,
  cancelled,
  skipped,
  retrying,
}

/// Modelo Conceitual Unificado de Evento de Log (`LogEvent`).
///
/// Todas as emissões de observabilidade na plataforma FINCORE seguem este modelo imutável
/// e fortemente tipado, permitindo rastreabilidade completa sem interferir na operação.
class LogEvent {
  final String? process;
  final String? step;
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String eventType;
  final String action;
  final LogModule module;
  final LogSource source;
  final String operation;
  final String message;
  final String? description;
  final String? entityType;
  final String? entityId;
  final String? userId;
  final String? tenantId;
  final String? correlationId;
  final String traceId;
  final String? parentEventId;
  final String? sessionId;
  final String? deviceId;
  final String environment;
  final String applicationVersion;
  final String? moduleVersion;
  final String loggerVersion;
  final String schemaVersion;
  final String? syncStatus;
  final LogSource origin;
  final LogDestination destination;
  final int? durationMs;
  final int attempt;
  final LogStatus status;
  final String? errorCode;
  final String? errorType;
  final String? errorMessage;
  final String? stackTrace;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? currentState;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime? syncedAt;

  static String defaultAppVersion = '1.2.2';
  static String defaultSchemaVersion = '1.2.2';
  static int _traceCounter = 0;

  LogEvent({
    this.process,
    this.step,
    String? id,
    DateTime? timestamp,
    required this.level,
    required this.category,
    required this.eventType,
    required this.action,
    required this.module,
    this.source = LogSource.local,
    required this.operation,
    required this.message,
    this.description,
    this.entityType,
    this.entityId,
    this.userId,
    this.tenantId,
    this.correlationId,
    String? traceId,
    this.parentEventId,
    this.sessionId,
    this.deviceId,
    this.environment = 'production',
    String? applicationVersion,
    this.moduleVersion,
    this.loggerVersion = '1.3.0',
    String? schemaVersion,
    this.syncStatus,
    LogSource? origin,
    this.destination = LogDestination.localOnly,
    this.durationMs,
    this.attempt = 1,
    this.status = LogStatus.success,
    this.errorCode,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.previousState,
    this.currentState,
    Map<String, dynamic>? metadata,
    this.payload,
    DateTime? createdAt,
    this.syncedAt,
  })  : id = id ?? const Uuid().v4(),
        timestamp = (timestamp ?? DateTime.now()).toUtc(),
        applicationVersion = applicationVersion ?? defaultAppVersion,
        schemaVersion = schemaVersion ?? defaultSchemaVersion,
        traceId = traceId ?? _generateTraceId(),
        origin = origin ?? source,
        metadata = metadata != null ? _redactSensitiveData(metadata) : const {},
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  static String _generateTraceId() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    _traceCounter = (_traceCounter + 1) % 10000;
    final seq = _traceCounter.toString().padLeft(4, '0');
    return 'REQ-$y$m$d-$seq';
  }

  /// Filtra chaves sensíveis (redaction) de um mapa de dados para proteger senhas/tokens.
  static Map<String, dynamic> _redactSensitiveData(Map<String, dynamic> map) {
    final copy = <String, dynamic>{};
    for (final entry in map.entries) {
      final keyLower = entry.key.toLowerCase();
      if (keyLower.contains('password') ||
          keyLower.contains('senha') ||
          keyLower.contains('token') ||
          keyLower.contains('secret') ||
          keyLower.contains('privatekey')) {
        copy[entry.key] = '***REDACTED***';
      } else if (entry.value is Map<String, dynamic>) {
        copy[entry.key] = _redactSensitiveData(entry.value as Map<String, dynamic>);
      } else {
        copy[entry.key] = entry.value;
      }
    }
    return copy;
  }

  /// Serialização para JSON estruturado (OpenTelemetry / Serilog Compatible).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name.toUpperCase(),
      'category': category.name.toUpperCase(),
      'process': process ?? eventType,
      'step': step ?? operation,
      'eventType': eventType,
      'action': action,
      'module': module.name,
      'source': source.name.toUpperCase(),
      'operation': operation,
      'message': message,
      if (description != null) 'description': description,
      if (entityType != null) 'entityType': entityType,
      if (entityId != null) 'entityId': entityId,
      if (userId != null) 'userId': userId,
      if (tenantId != null) 'tenantId': tenantId,
      if (correlationId != null) 'correlationId': correlationId,
      'traceId': traceId,
      if (parentEventId != null) 'parentEventId': parentEventId,
      if (sessionId != null) 'sessionId': sessionId,
      if (deviceId != null) 'deviceId': deviceId,
      'environment': environment,
      'versions': {
        'application': applicationVersion,
        if (moduleVersion != null) 'module': moduleVersion,
        'logger': loggerVersion,
        'schema': schemaVersion,
      },
      if (syncStatus != null) 'syncStatus': syncStatus,
      'origin': origin.name.toUpperCase(),
      'destination': destination.name,
      if (durationMs != null) 'durationMs': durationMs,
      'attempt': attempt,
      'status': status.name.toUpperCase(),
      if (errorCode != null || errorType != null || errorMessage != null)
        'error': {
          if (errorCode != null) 'code': errorCode,
          if (errorType != null) 'type': errorType,
          if (errorMessage != null) 'message': errorMessage,
          if (stackTrace != null) 'stackTrace': stackTrace,
        },
      if (previousState != null) 'previousState': previousState,
      if (currentState != null) 'currentState': currentState,
      'metadata': metadata,
      if (payload != null) 'payload': _redactSensitiveData(payload!),
      'createdAt': createdAt.toIso8601String(),
      if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
    };
  }

  /// Formatação de linha legível e profissional para arquivos .log
  /// Padrão FINCORE: DATA/HORA | LEVEL | CATEGORIA | PROCESSO | ETAPA | AÇÃO | [Rastreio: REQ-...] | CONTEXTO
  String toBareTailLine() {
    final local = timestamp.toLocal();
    final y = local.year;
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    final ms = local.millisecond.toString().padLeft(3, '0');

    final offset = local.timeZoneOffset;
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (offset.inMinutes.remainder(60)).abs().toString().padLeft(2, '0');
    final offsetSign = offset.isNegative ? '-' : '+';
    final tzStr = '$offsetSign$offsetHours:$offsetMinutes';

    final timeStr = '$y-$mo-$d $h:$mi:$s.$ms $tzStr';

    final lvlStr = switch (level) {
      LogLevel.trace    => '[TRACE]  ',
      LogLevel.debug    => '[DEBUG]  ',
      LogLevel.info     => '[INFO]   ',
      LogLevel.notice   => '[NOTICE] ',
      LogLevel.warning  => '[AVISO]  ',
      LogLevel.error    => '[ERRO]   ',
      LogLevel.critical => '[CRÍTICO]',
      LogLevel.audit    => '[AUDIT]  ',
    };

    final catStr = '[${category.name.toUpperCase()}]';
    final effectiveProcess = (process ?? eventType).toUpperCase();
    final effectiveStep = (step ?? operation).toUpperCase();
    final effectiveAction = action.toUpperCase();

    final header = '$timeStr | $lvlStr | $catStr | $effectiveProcess | $effectiveStep | $effectiveAction';
    final traceStr = '[Rastreio: $traceId]';

    final metaDetails = <String>[];
    if (entityType != null && entityType!.isNotEmpty) {
      final idDisplay = entityId != null ? ' | ID: $entityId' : '';
      metaDetails.add('Entidade: $entityType$idDisplay');
    } else if (entityId != null && entityId!.isNotEmpty) {
      metaDetails.add('ID: $entityId');
    }

    if (userId != null || tenantId != null) {
      metaDetails.add('${userId ?? 'system'}@${tenantId ?? 'default'}');
    }

    if (attempt > 1 || status == LogStatus.retrying) {
      metaDetails.add('Tentativa: $attempt');
    }

    if (durationMs != null) {
      metaDetails.add('Tempo: ${durationMs}ms');
    }

    if (status != LogStatus.success && status != LogStatus.inProgress && status != LogStatus.started) {
      final statusName = switch (status) {
        LogStatus.failed    => 'FALHA',
        LogStatus.partial   => 'PARCIAL',
        LogStatus.cancelled => 'CANCELADO',
        LogStatus.skipped   => 'IGNORADO',
        LogStatus.retrying  => 'RETENTANDO',
        _                   => status.name.toUpperCase(),
      };
      metaDetails.add('Resultado: $statusName');
    } else if (effectiveAction.contains('RESULTADO') || effectiveAction.contains('CONCLUIDO') || effectiveAction.contains('FIM')) {
      metaDetails.add('Resultado: SUCESSO');
    }

    if (errorCode != null || errorMessage != null) {
      final errPrefix = errorCode != null ? 'Erro: [$errorCode] ' : 'Erro: ';
      metaDetails.add('$errPrefix${errorMessage ?? ''}'.trim());
    }
    if (errorType != null) {
      metaDetails.add('Motivo: $errorType');
    }

    final contextStr = metaDetails.isNotEmpty ? ' | ${metaDetails.join(' | ')}' : '';
    final mainLine = '$header | $traceStr$contextStr';

    if (message.isNotEmpty && message != operation && message != eventType) {
      if (message.startsWith('┌──') || message.startsWith('└──') || message.startsWith('===') || message.contains('\n')) {
        return '$mainLine\n$message';
      } else {
        return '$mainLine | $message';
      }
    }

    return mainLine;
  }

  @override
  String toString() => jsonEncode(toJson());
}
