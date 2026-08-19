import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
}

/// Nível de severidade do evento (Estilo Serilog / OpenTelemetry).
enum LogSeverity { trace, debug, info, warning, error, critical }

/// Alias de compatibilidade com código existente.
typedef LogLevel = LogSeverity;

/// Categoria da observabilidade (Pilares do FINCORE Enterprise).
enum LogCategory {
  audit,
  sync,
  error,
  performance,
  database,
  security,
  printer,
  api,
  system,
  business,
}

/// Destino de roteamento de telemetria e auditoria (Estratégia de 3 Níveis).
enum LogDestination {
  /// Nível 1 & 2: Logs operacionais e técnicos de infraestrutura (Exceções Flutter, SQLite, Impressoras, Retries).
  /// Armazenados exclusivamente em arquivos locais com retenção automática de 30 dias.
  localOnly,

  /// Eventos direcionados exclusivamente para a nuvem.
  cloudOnly,

  /// Nível 3: Auditoria de Negócio (CRUD, Preços, Pedidos, Usuários) e Crashes Fatais.
  /// Salvos no SQLite local E sincronizados permanentemente no Supabase Cloud.
  both,
}

/// Helper para geração de IDs correlacionados e prefixados (Correlation ID).
class CorrelationIdGenerator {
  static String generateCorrelationId() {
    final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'REQ-$rand';
  }

  static String prefixId(String prefix, String rawId) {
    final clean = rawId.replaceAll('-', '').toUpperCase();
    final shortId = clean.length > 8 ? clean.substring(0, 8) : clean;
    return '$prefix-$shortId';
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FincoreLogger
///
/// Serviço de log central do FINCORE. Inspirado nos logs de campo de sistemas
/// de integração profissionais: legível no Notepad, rastreável por grep,
/// rotacionado por hora para evitar arquivos gigantes.
///
/// Formato de arquivo (plain text):
///   2026-07-30 14:22:01.312  [SYNC]      Ciclo de envio iniciado — 3 pendente(s)
///   2026-07-30 14:22:01.450  [SYNC]      Cliente  id=abc123  ENVIADO  (148ms)
///   2026-07-30 14:22:01.451  [SYNC] ERRO Falha ao enviar Produto  id=xyz999
///                            >>> PostgrestException: column not found
///
/// Rotação: um arquivo por hora → fincore_YYYY-MM-DD_HH.log
/// ─────────────────────────────────────────────────────────────────────────────
class FincoreLogger {
  static FincoreLogger? _instance;

  final String baseDirectory;
  final bool isProduction;

  // Arquivo de log atual (rotado por hora)
  File? _currentFile;
  int? _currentHour;

  FincoreLogger._(this.baseDirectory, {this.isProduction = false});

  // ── Inicialização ──────────────────────────────────────────────────────────

  static void init(String baseDirectory, {bool isProduction = false}) {
    _instance = FincoreLogger._(baseDirectory, isProduction: isProduction);
    _instance!._scheduleCleanup();
  }

  static FincoreLogger get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'FincoreLogger não inicializado. Chame FincoreLogger.init(baseDirectory) primeiro.',
      );
    }
    return inst;
  }

  // ── API Pública ────────────────────────────────────────────────────────────

  Future<void> info(LogModule module, String message, {
    String? context,
    String? traceId,
  }) => _write(LogLevel.info, module, message, context: context, traceId: traceId);

  Future<void> debug(LogModule module, String message, {
    String? context,
    String? traceId,
  }) => _write(LogLevel.debug, module, message, context: context, traceId: traceId);

  Future<void> warning(LogModule module, String message, {
    String? context,
    String? traceId,
    String? detail,
  }) => _write(LogLevel.warning, module, message, context: context, traceId: traceId, detail: detail);

  Future<void> error(LogModule module, String message, {
    String? context,
    String? traceId,
    String? detail,
  }) => _write(LogLevel.error, module, message, context: context, traceId: traceId, detail: detail);

  /// Loga o início de um ciclo de operação (ex: ciclo de sync, startup, etc.)
  /// Cria uma linha divisória visível no arquivo para fácil localização.
  Future<void> beginCycle(LogModule module, String title, {String? context}) async {
    final line = _divider(title);
    await _write(LogLevel.info, module, line);
    if (context != null) {
      await _write(LogLevel.info, module, context);
    }
  }

  /// Loga o fim de um ciclo com um resumo de uma linha.
  Future<void> endCycle(LogModule module, String summary) async {
    await _write(LogLevel.info, module, summary);
  }

  // ── Formatação ─────────────────────────────────────────────────────────────

  static String _formatTimestamp(DateTime dt) {
    final y  = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-$d $h:$mi:$s.$ms';
  }

  static String _moduleTag(LogModule module) {
    final name = switch (module) {
      LogModule.startup   => 'INICIO',
      LogModule.sync      => 'SINCRONISMO',
      LogModule.database  => 'BANCO',
      LogModule.api       => 'SERVICO',
      LogModule.migration => 'MIGRACAO',
      LogModule.printer   => 'IMPRESSAO',
      LogModule.crash     => 'FALHA',
      LogModule.app       => 'SISTEMA',
    };
    return '[${name.padRight(11)}]';
  }

  static String _levelTag(LogLevel level) {
    return switch (level) {
      LogSeverity.trace    => '[TRACE]: ',
      LogSeverity.debug    => '',
      LogSeverity.info     => '',
      LogSeverity.warning  => 'AVISO: ',
      LogSeverity.error    => 'ERRO: ',
      LogSeverity.critical => 'CRÍTICO: ',
    };
  }

  static String _formatLine(DateTime dt, LogModule module, LogLevel level, String message) {
    final ts  = _formatTimestamp(dt);
    final mod = _moduleTag(module);
    final lvl = _levelTag(level);
    return '$ts $mod $lvl$message';
  }

  static String _divider(String title) {
    const width = 72;
    final inner = ' $title ';
    final pad   = ((width - inner.length) / 2).floor();
    final line  = ('-' * pad) + inner + ('-' * pad);
    return line.padRight(width, '-');
  }

  // ── Escrita ────────────────────────────────────────────────────────────────

  Future<void> _write(
    LogLevel level,
    LogModule module,
    String message, {
    String? context,
    String? traceId,
    String? detail,
  }) async {
    if (isProduction && level == LogLevel.debug) return;

    final now = DateTime.now();

    // ── Monta as linhas ──
    final lines = <String>[];

    final rawLines = message.split('\n');
    for (int i = 0; i < rawLines.length; i++) {
      final lineStr = rawLines[i];
      if (lineStr.trim().isEmpty && i > 0 && i < rawLines.length - 1) continue;
      String formattedMsg = lineStr;
      if (i == 0 && context != null) formattedMsg = '$context | $formattedMsg';
      if (i == 0 && traceId != null) formattedMsg = '$formattedMsg [Rastreio: $traceId]';
      lines.add(_formatLine(now, module, level, formattedMsg));
    }

    // Detalhes de erro/exceção (opcional)
    if (detail != null && detail.trim().isNotEmpty) {
      for (final l in detail.trim().split('\n').take(3)) {
        if (l.trim().isNotEmpty) {
          lines.add('    >>> ${l.trim()}');
        }
      }
    }

    for (final line in lines) {
      await _writeLine(line, now);
    }

    // ── Console output ──
    _printToConsole(level, lines);
  }

  Future<void> _writeQueue = Future.value();

  Future<void> _writeLine(String line, DateTime now) async {
    final completer = Completer<void>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final file = await _getFile(now);
        await file.writeAsString('$line\n', mode: FileMode.append, encoding: utf8, flush: true);
      } catch (e) {
        stderr.writeln('! FINCORE LOG IO ERROR: $e');
      } finally {
        completer.complete();
      }
    });
    return completer.future;
  }

  // ── Rotação de arquivo por hora ────────────────────────────────────────────

  Future<File> _getFile(DateTime now) async {
    if (_currentHour == now.hour && _currentFile != null) {
      return _currentFile!;
    }

    final monthStr = now.month.toString().padLeft(2, '0');
    final dayStr = now.day.toString().padLeft(2, '0');
    final hourStr = now.hour.toString().padLeft(2, '0');

    final dir = Directory('$baseDirectory/logs/${now.year}-$monthStr/$dayStr');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/fincore_$hourStr.log');

    // Escreve cabeçalho se o arquivo é novo
    if (!await file.exists()) {
      await file.writeAsString(
        _fileHeader(now),
        mode: FileMode.write,
        encoding: utf8,
        flush: true,
      );
    }

    _currentFile = file;
    _currentHour = now.hour;
    return file;
  }

  static String _fileHeader(DateTime now) {
    final ts = _formatTimestamp(now);
    return '\uFEFF' '''
========================================================================
  FINCORE Platform v1.2.0 | Log de Operação e Sincronização
  Sessão iniciada em: $ts
  Ambiente: Local (SQLite) <-> Nuvem (Supabase)
========================================================================

''';
  }

  // ── Console ────────────────────────────────────────────────────────────────

  void _printToConsole(LogLevel level, List<String> lines) {
    final out = lines.join('\n');
    if (level == LogLevel.error || level == LogLevel.warning) {
      stderr.writeln(out);
    } else {
      stdout.writeln(out);
    }
  }

  // ── Limpeza automática (logs > 30 dias) ───────────────────────────────────

  void _scheduleCleanup() {
    Future.microtask(() async {
      try {
        final dir = Directory('$baseDirectory/logs');
        if (!await dir.exists()) return;
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        await for (final f in dir.list(recursive: true)) {
          if (f is File && f.path.endsWith('.log')) {
            final modified = await f.lastModified();
            if (modified.isBefore(cutoff)) {
              await f.delete();
            }
          }
        }
      } catch (_) {
        // Limpeza silenciosa — não bloqueia o app
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alias de compatibilidade: LogService → FincoreLogger
// Mantém compatibilidade com código existente durante a migração.
// ─────────────────────────────────────────────────────────────────────────────

/// @deprecated Use [FincoreLogger] diretamente.
/// Mantido para compatibilidade com código legado durante a migração.
class LogService {
  static LogService? _instance;
  final String baseDirectory;
  bool isProduction = false;

  LogService._(this.baseDirectory);

  static void init(String baseDirectory, {bool runCleanup = true, bool isProduction = false}) {
    _instance = LogService._(baseDirectory)..isProduction = isProduction;
    // Inicializa o novo logger também
    FincoreLogger.init(baseDirectory, isProduction: isProduction);
  }

  static LogService get instance {
    final inst = _instance;
    if (inst == null) throw StateError('LogService não inicializado.');
    return inst;
  }

  Future<void> log({
    required LogModule module,
    required LogLevel level,
    required String message,
    String? tenantId,
    String? userId,
    String? traceId,
    Map<String, dynamic>? context,
    String? exception,
    String? stackTrace,
  }) async {
    // Monta context string compatível
    String? ctxStr;
    if (context != null && context.isNotEmpty) {
      final usuario = context['usuario'];
      final empresa = context['empresa'];
      if (usuario != null && empresa != null) {
        ctxStr = '$usuario @ $empresa';
      } else {
        ctxStr = context.entries.map((e) => '${e.key}=${e.value}').join('  ');
      }
    }

    // Monta detail string
    String? detailStr;
    if (exception != null) detailStr = exception;

    switch (level) {
      case LogSeverity.trace:
      case LogSeverity.debug:
        await FincoreLogger.instance.debug(module, message, context: ctxStr, traceId: traceId);
      case LogSeverity.info:
        await FincoreLogger.instance.info(module, message, context: ctxStr, traceId: traceId);
      case LogSeverity.warning:
        await FincoreLogger.instance.warning(module, message, context: ctxStr, traceId: traceId, detail: detailStr);
      case LogSeverity.error:
      case LogSeverity.critical:
        await FincoreLogger.instance.error(module, message, context: ctxStr, traceId: traceId, detail: detailStr);
    }
  }

  Future<void> debug(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context}) =>
      log(module: module, level: LogLevel.debug, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context);

  Future<void> info(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context}) =>
      log(module: module, level: LogLevel.info, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context);

  Future<void> warning(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context}) =>
      log(module: module, level: LogLevel.warning, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context);

  Future<void> error(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context, String? exception, String? stackTrace}) =>
      log(module: module, level: LogLevel.error, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context, exception: exception, stackTrace: stackTrace);

  Future<void> forceCleanup() async {}

  Future<List<Map<String, dynamic>>> queryLogs({
    LogModule? module,
    LogLevel? level,
    DateTime? start,
    DateTime? end,
    String? searchQuery,
  }) async => [];
}
