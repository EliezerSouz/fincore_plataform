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

/// Nível de severidade do evento.
enum LogLevel { debug, info, warning, error }

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
    final now = DateTime.now();
    final line = _divider(title);
    await _writeLine(line, now);
    if (context != null) {
      await _writeLine(_formatLine(now, module, LogLevel.info, context), now);
    }
  }

  /// Loga o fim de um ciclo com um resumo de uma linha.
  Future<void> endCycle(LogModule module, String summary) async {
    final now = DateTime.now();
    await _writeLine(_formatLine(now, module, LogLevel.info, summary), now);
    await _writeLine('', now); // linha em branco após o ciclo
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
    return '[${module.name.toUpperCase().padRight(9)}]';
  }

  static String _levelTag(LogLevel level) {
    return switch (level) {
      LogLevel.debug   => '      ',
      LogLevel.info    => '      ',
      LogLevel.warning => 'AVISO ',
      LogLevel.error   => 'ERRO  ',
    };
  }

  static String _formatLine(DateTime dt, LogModule module, LogLevel level, String message) {
    final ts  = _formatTimestamp(dt);
    final mod = _moduleTag(module);
    final lvl = _levelTag(level);
    return '$ts  $mod $lvl$message';
  }

  static String _divider(String title) {
    const width = 72;
    final inner = ' $title ';
    final pad   = ((width - inner.length) / 2).floor();
    final line  = ('─' * pad) + inner + ('─' * pad);
    return line.padRight(width, '─');
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

    // Linha principal
    String mainMsg = message;
    if (context != null) mainMsg = '$context  |  $message';
    lines.add(_formatLine(now, module, level, mainMsg));

    // Detalhe extra (ex: mensagem de exceção, stack trace resumido)
    if (detail != null) {
      for (final l in detail.trim().split('\n').take(3)) {
        if (l.trim().isNotEmpty) {
          lines.add('${''.padLeft(38)}>>> ${l.trim()}');
        }
      }
    }

    if (traceId != null) {
      lines.add('${''.padLeft(38)}--- Trace: $traceId');
    }

    for (final line in lines) {
      await _writeLine(line, now);
    }

    // ── Console output ──
    _printToConsole(level, lines);
  }

  Future<void> _writeLine(String line, DateTime now) async {
    try {
      final file = await _getFile(now);
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (e) {
      stderr.writeln('⚠ FINCORE LOG IO ERROR: $e');
    }
  }

  // ── Rotação de arquivo por hora ────────────────────────────────────────────

  Future<File> _getFile(DateTime now) async {
    if (_currentHour == now.hour && _currentFile != null) {
      return _currentFile!;
    }

    final dateStr = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final hourStr = now.hour.toString().padLeft(2, '0');

    final dir = Directory('$baseDirectory/logs');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/fincore_${dateStr}_$hourStr.log');

    // Escreve cabeçalho se o arquivo é novo
    if (!await file.exists()) {
      await file.writeAsString(
        _fileHeader(now),
        mode: FileMode.write,
        flush: true,
      );
    }

    _currentFile = file;
    _currentHour = now.hour;
    return file;
  }

  static String _fileHeader(DateTime now) {
    final ts = _formatTimestamp(now);
    return '''
════════════════════════════════════════════════════════════════════════
  FINCORE  v1.2.0  |  Log de Operação
  Sessão iniciada em: $ts
  Módulo: Integração Local ↔ Nuvem (Supabase)
════════════════════════════════════════════════════════════════════════

''';
  }

  // ── Console ────────────────────────────────────────────────────────────────

  void _printToConsole(LogLevel level, List<String> lines) {
    final prefix = switch (level) {
      LogLevel.debug   => '',
      LogLevel.info    => '',
      LogLevel.warning => '⚠ ',
      LogLevel.error   => '✖ ',
    };

    final out = lines.map((l) => '$prefix$l').join('\n');

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
        await for (final f in dir.list()) {
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
      case LogLevel.debug:
        await FincoreLogger.instance.debug(module, message, context: ctxStr, traceId: traceId);
      case LogLevel.info:
        await FincoreLogger.instance.info(module, message, context: ctxStr, traceId: traceId);
      case LogLevel.warning:
        await FincoreLogger.instance.warning(module, message, context: ctxStr, traceId: traceId, detail: detailStr);
      case LogLevel.error:
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
