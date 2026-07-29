import 'dart:convert';
import 'dart:io';

enum LogModule { app, api, database, sync, printer, crash, startup, migration }
enum LogLevel { debug, info, warning, error }

class LogService {
  static LogService? _instance;
  final String baseDirectory;
  bool isProduction = false;

  LogService._(this.baseDirectory);

  static void init(String baseDirectory, {bool runCleanup = true, bool isProduction = false}) {
    _instance = LogService._(baseDirectory)..isProduction = isProduction;
    if (runCleanup) {
      _instance!._rotateAndCleanupLogs();
    }
  }

  static LogService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('LogService não foi inicializado. Chame LogService.init(baseDirectory) primeiro.');
    }
    return inst;
  }

  /// Escreve uma mensagem de log técnica no arquivo correspondente ao módulo em formato JSON Lines.
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
    try {
      if (isProduction && level == LogLevel.debug) return;

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // Criar diretório específico do módulo
      final moduleDir = Directory('$baseDirectory/logs/${module.name}');
      if (!await moduleDir.exists()) {
        await moduleDir.create(recursive: true);
      }

      // Arquivo rotacionado diariamente
      final logFile = File('${moduleDir.path}/fincore_${module.name}_$dateStr.log');

      // Objeto de log estruturado em JSON Lines
      final logEntry = {
        'timestamp': now.toIso8601String(),
        'level': level.name.toUpperCase(),
        'module': module.name.toUpperCase(),
        if (tenantId != null) 'tenantId': tenantId,
        if (userId != null) 'userId': userId,
        if (traceId != null) 'traceId': traceId,
        if (context != null) 'context': context,
        'message': message,
        if (exception != null) 'exception': exception,
        if (stackTrace != null) 'stackTrace': stackTrace,
      };

      final logLine = jsonEncode(logEntry) + '\n';
      await logFile.writeAsString(logLine, mode: FileMode.append, flush: true);

      // Se for um erro e não for do módulo crash, salva também no log de crash global
      if (level == LogLevel.error && module != LogModule.crash) {
        final crashDir = Directory('$baseDirectory/logs/crash');
        if (!await crashDir.exists()) {
          await crashDir.create(recursive: true);
        }
        final crashFile = File('${crashDir.path}/fincore_crash_$dateStr.log');
        await crashFile.writeAsString(logLine, mode: FileMode.append, flush: true);
      }
      
      // Print to console using intelligent format
      if (!isProduction || level != LogLevel.debug) {
        final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond).toString().padLeft(3, '0')}';
        
        final emoji = {
          LogLevel.debug: '🔵 DEBUG',
          LogLevel.info: '🟢 INFO',
          LogLevel.warning: '🟠 WARNING',
          LogLevel.error: '🔴 ERROR',
        }[level];

        final buffer = StringBuffer();
        buffer.writeln('[$timeStr]');
        buffer.writeln('$emoji [${module.name.toUpperCase()}]');
        if (traceId != null) {
          buffer.writeln('Trace ID: $traceId');
        }
        if (context != null && context.isNotEmpty) {
          buffer.writeln('Context:');
          context.forEach((k, v) => buffer.writeln('  $k: $v'));
        }
        buffer.writeln(message);
        if (exception != null) buffer.writeln('Exception: $exception');
        if (stackTrace != null) buffer.writeln('StackTrace: $stackTrace');

        if (level == LogLevel.error) {
          stderr.write(buffer.toString());
        } else {
          stdout.write(buffer.toString());
        }
      }
    } catch (e) {
      // Fallback em caso de falha catastrófica de IO para não derrubar a aplicação
      stderr.writeln('⚠️ ERRO CRÍTICO NO LOGSERVICE: $e');
    }
  }

  // shortcuts
  Future<void> debug(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context}) =>
      log(module: module, level: LogLevel.debug, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context);

  Future<void> info(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context}) =>
      log(module: module, level: LogLevel.info, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context);

  Future<void> warning(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context}) =>
      log(module: module, level: LogLevel.warning, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context);

  Future<void> error(LogModule module, String message, {String? tenantId, String? userId, String? traceId, Map<String, dynamic>? context, String? exception, String? stackTrace}) =>
      log(module: module, level: LogLevel.error, message: message, tenantId: tenantId, userId: userId, traceId: traceId, context: context, exception: exception, stackTrace: stackTrace);

  /// Força a execução e conclusão da limpeza e rotação de logs antigos.
  Future<void> forceCleanup() => _rotateAndCleanupLogs();

  static bool _isCleaningUp = false;

  /// Rotaciona e apaga logs mais antigos do que 90 dias
  Future<void> _rotateAndCleanupLogs() async {
    if (_isCleaningUp) return;
    _isCleaningUp = true;
    try {
      final logsDir = Directory('$baseDirectory/logs');
      if (!await logsDir.exists()) return;

      final limitDate = DateTime.now().subtract(const Duration(days: 30));

      await for (final entity in logsDir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.log')) {
          final lastModified = await entity.lastModified();
          if (lastModified.isBefore(limitDate)) {
            await entity.delete();
            stdout.writeln('♻️ LOGSERVICE CLEANUP: Removido log expirado: ${entity.path}');
          }
        }
      }
    } catch (e) {
      stderr.writeln('⚠️ LOGSERVICE CLEANUP ERROR: $e');
    } finally {
      _isCleaningUp = false;
    }
  }

  /// Consulta logs do disco com base em filtros e paginação simples.
  Future<List<Map<String, dynamic>>> queryLogs({
    LogModule? module,
    LogLevel? level,
    DateTime? start,
    DateTime? end,
    String? searchQuery,
  }) async {
    final results = <Map<String, dynamic>>[];
    try {
      final logsDir = Directory('$baseDirectory/logs');
      if (!await logsDir.exists()) return [];

      final List<Directory> dirsToSearch = [];
      if (module != null) {
        final modDir = Directory('${logsDir.path}/${module.name}');
        if (await modDir.exists()) {
          dirsToSearch.add(modDir);
        }
      } else {
        await for (final dir in logsDir.list(followLinks: false)) {
          if (dir is Directory) {
            dirsToSearch.add(dir);
          }
        }
      }

      for (final dir in dirsToSearch) {
        await for (final file in dir.list(followLinks: false)) {
          if (file is File && file.path.endsWith('.log')) {
            final lines = await file.readAsLines();
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              try {
                final json = jsonDecode(line) as Map<String, dynamic>;
                
                if (level != null && json['level'] != level.name.toUpperCase()) {
                  continue;
                }
                
                if (json['timestamp'] != null) {
                  final ts = DateTime.tryParse(json['timestamp'] as String);
                  if (ts != null) {
                    if (start != null && ts.isBefore(start)) continue;
                    if (end != null && ts.isAfter(end)) continue;
                  }
                }
                
                if (searchQuery != null && searchQuery.isNotEmpty) {
                  final textToSearch = (json['message'] ?? '').toString() +
                      (json['exception'] ?? '').toString() +
                      (json['traceId'] ?? '').toString() +
                      (json['context'] ?? '').toString();
                  if (!textToSearch.toLowerCase().contains(searchQuery.toLowerCase())) {
                    continue;
                  }
                }

                results.add(json);
              } catch (_) {
                // Linha corrompida
              }
            }
          }
        }
      }
      
      results.sort((a, b) {
        final tA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(0);
        final tB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(0);
        return tB.compareTo(tA);
      });
      
    } catch (e) {
      stderr.writeln('Erro ao consultar logs: $e');
    }
    return results;
  }
}
