import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

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

/// Metadata da categoria de log no disco
class _LogCategoryConfig {
  final String folderName;
  final String filePrefix;

  const _LogCategoryConfig(this.folderName, this.filePrefix);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FincoreLogger
///
/// Serviço de log central do FINCORE. Estruturado em categorias dentro da pasta LOG:
///   - /LOG/Sincronizacao/  (Sync Supabase, Realtime, Outbox)
///   - /LOG/ImportExport/   (Carga de dados, CSV, Backups)
///   - /LOG/Operacional/    (Fluxo PDV, Caixa, Balcão, Navegação)
///   - /LOG/Impressao/      (Impressão Térmica ESC-POS, Spooler, KDS)
///   - /LOG/BancoDados/     (Consultas Drift/SQLite, Migrações)
///   - /LOG/Erros/          (Espelho global de erros e exceções)
///   - /LOG/Auditoria/      (Auditoria de usuários e políticas de preços)
///
/// Formatado para BareTail (Windows) com tags em caixa alta para realce de cores:
///   2026-09-11 18:51:20.123 [INFO   ] [INSERT] [SINCRONISMO] Cliente id=123 sincronizado
///   2026-09-11 18:51:21.450 [ERRO   ] [FALHA]  [BANCO      ] Erro ao atualizar preço (Timeout)
/// ─────────────────────────────────────────────────────────────────────────────
class FincoreLogger {
  static FincoreLogger? _instance;

  final String baseDirectory;
  final bool isProduction;

  // Cache de arquivos de log por categoria e data
  final Map<String, File> _activeFiles = {};
  final Map<String, String> _activeDates = {};

  FincoreLogger._(this.baseDirectory, {this.isProduction = false});

  // ── Inicialização ──────────────────────────────────────────────────────────

  static void init(String baseDirectory, {bool isProduction = false}) {
    _instance = FincoreLogger._(baseDirectory, isProduction: isProduction);
    _instance!._scheduleCleanup();
    _instance!._createBareTailHelpFile();
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

  /// Retorna o diretório raiz absoluto onde os logs/categorias são salvos.
  String get logRootPath {
    final clean = baseDirectory.replaceAll('\\', '/');
    if (clean.toUpperCase().endsWith('/LOG') || clean.toUpperCase().endsWith('/LOGS')) {
      return baseDirectory;
    }
    return '$baseDirectory/LOG';
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

  Future<void> beginCycle(LogModule module, String title, {String? context}) async {
    final line = _divider(title);
    await _write(LogLevel.info, module, line);
    if (context != null) {
      await _write(LogLevel.info, module, context);
    }
  }

  Future<void> endCycle(LogModule module, String summary) async {
    await _write(LogLevel.info, module, summary);
  }

  // ── Mapeamento de Categorias ──────────────────────────────────────────────

  static _LogCategoryConfig _categoryForModule(LogModule module) {
    return switch (module) {
      LogModule.sync         => const _LogCategoryConfig('Sincronizacao', 'sync'),
      LogModule.importExport => const _LogCategoryConfig('ImportExport', 'import_export'),
      LogModule.printer      => const _LogCategoryConfig('Impressao', 'impressao'),
      LogModule.database ||
      LogModule.migration    => const _LogCategoryConfig('BancoDados', 'banco_dados'),
      LogModule.crash        => const _LogCategoryConfig('Erros', 'erros'),
      LogModule.audit ||
      LogModule.api          => const _LogCategoryConfig('Auditoria', 'auditoria'),
      LogModule.app ||
      LogModule.startup      => const _LogCategoryConfig('Operacional', 'operacional'),
    };
  }

  // ── Formatação BareTail Friendly ──────────────────────────────────────────

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
      LogModule.startup      => 'STARTUP',
      LogModule.sync         => 'SINCRONISMO',
      LogModule.database     => 'BANCO',
      LogModule.api          => 'SERVICO',
      LogModule.migration    => 'MIGRACAO',
      LogModule.printer      => 'IMPRESSAO',
      LogModule.crash        => 'FALHA',
      LogModule.app          => 'SISTEMA',
      LogModule.importExport => 'IMPORT_EXPORT',
      LogModule.audit        => 'AUDITORIA',
    };
    return '[${name.padRight(13)}]';
  }

  static String _levelTag(LogLevel level) {
    return switch (level) {
      LogSeverity.trace    => '[TRACE]  ',
      LogSeverity.debug    => '[DEBUG]  ',
      LogSeverity.info     => '[INFO]   ',
      LogSeverity.warning  => '[AVISO]  ',
      LogSeverity.error    => '[ERRO]   ',
      LogSeverity.critical => '[CRÍTICO]',
    };
  }

  /// Detecta se a mensagem possui verbo de operação CRUD para destacar no BareTail
  static String _detectOperationTag(String message) {
    final upper = message.toUpperCase();
    if (upper.contains('[INSERT]') ||
        upper.contains('[UPDATE]') ||
        upper.contains('[DELETE]') ||
        upper.contains('[SUCESSO]') ||
        upper.contains('[FALHA]')) {
      return '';
    }

    if (upper.contains('INSERT') || upper.contains('INSERIDO') || upper.contains('CRIADO') || upper.contains('CRIAR')) {
      return '[INSERT] ';
    }
    if (upper.contains('UPDATE') || upper.contains('ATUALIZADO') || upper.contains('ALTERADO') || upper.contains('ATUALIZAR')) {
      return '[UPDATE] ';
    }
    if (upper.contains('DELETE') || upper.contains('REMOVIDO') || upper.contains('EXCLUÍDO') || upper.contains('DELETADO')) {
      return '[DELETE] ';
    }
    if (upper.contains('SUCESSO') || upper.contains('CONCLUÍDO') || upper.contains('CONCLUIDO') || upper.contains(' OK')) {
      return '[SUCESSO] ';
    }
    if (upper.contains('FALHA') || upper.contains('FAILED') || upper.contains('ERRO')) {
      return '[FALHA] ';
    }
    return '';
  }

  static String _formatLine(DateTime dt, LogModule module, LogLevel level, String message) {
    final ts = _formatTimestamp(dt);
    final lvl = _levelTag(level);
    final mod = _moduleTag(module);
    final op = _detectOperationTag(message);

    if (op.isNotEmpty) {
      return '$ts $lvl $op$mod $message';
    }
    return '$ts $lvl $mod $message';
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

    if (detail != null && detail.trim().isNotEmpty) {
      for (final l in detail.trim().split('\n').take(5)) {
        if (l.trim().isNotEmpty) {
          lines.add('    >>> ${l.trim()}');
        }
      }
    }

    final category = _categoryForModule(module);

    for (final line in lines) {
      // Escreve na pasta específica da categoria
      await _writeLineToCategory(category, line, now);

      // Se for um ERRO ou CRÍTICO (e não estiver na pasta Erros), duplica na pasta Erros dedicada
      if ((level == LogLevel.error || level == LogLevel.critical || module == LogModule.crash) &&
          category.folderName != 'Erros') {
        const errorCategory = _LogCategoryConfig('Erros', 'erros');
        await _writeLineToCategory(errorCategory, line, now);
      }
    }

    _printToConsole(level, lines);
  }

  Future<void> _writeQueue = Future.value();

  Future<void> _writeLineToCategory(_LogCategoryConfig category, String line, DateTime now) async {
    if (kIsWeb) return;
    final completer = Completer<void>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final file = await _getCategoryFile(category, now);
        await file.writeAsString('$line\n', mode: FileMode.append, encoding: utf8, flush: true);
      } catch (e) {
        debugPrint('! FINCORE LOG IO ERROR ($category): $e');
      } finally {
        completer.complete();
      }
    });
    return completer.future;
  }

  // ── Obtenção / Rotação Diária de Arquivo ─────────────────────────────────

  Future<File> _getCategoryFile(_LogCategoryConfig category, DateTime now) async {
    final monthStr = now.month.toString().padLeft(2, '0');
    final dayStr = now.day.toString().padLeft(2, '0');
    final dateKey = '${now.year}-$monthStr-$dayStr';

    final categoryKey = category.folderName;

    if (_activeDates[categoryKey] == dateKey && _activeFiles[categoryKey] != null) {
      return _activeFiles[categoryKey]!;
    }

    final rootDir = logRootPath;
    final dir = Directory('$rootDir/${category.folderName}');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/${category.filePrefix}_$dateKey.log');

    if (!await file.exists()) {
      await file.writeAsString(
        _fileHeader(now, category.folderName),
        mode: FileMode.write,
        encoding: utf8,
        flush: true,
      );
    }

    _activeFiles[categoryKey] = file;
    _activeDates[categoryKey] = dateKey;
    return file;
  }

  static String _fileHeader(DateTime now, String categoryName) {
    final ts = _formatTimestamp(now);
    return '\uFEFF' '''
========================================================================
  FINCORE Platform v1.2.0 | Log da Categoria: [$categoryName]
  Arquivo criado em: $ts
  Ambiente: Local (SQLite) <-> Nuvem (Supabase)
========================================================================

''';
  }

  void _createBareTailHelpFile() {
    if (kIsWeb) return;
    Future.microtask(() async {
      try {
        final rootDir = Directory(logRootPath);
        if (!await rootDir.exists()) await rootDir.create(recursive: true);
        final file = File('${rootDir.path}/COMO_CONFIGURAR_CORES_BARETAIL.txt');
        if (!await file.exists()) {
          await file.writeAsString('''
========================================================================
  FINCORE FOOD PLATFORM - GUIA DE HIGHLIGHT DE CORES NO BARETAIL
========================================================================

Esta pasta 'LOG' contém todos os relatórios de operação do sistema,
organizados por situação/contexto:

  - /Sincronizacao : Registros de envio e recebimento via Supabase e WebSocket
  - /ImportExport  : Operações de carga de dados, CSV, Backups e Relatórios
  - /Operacional   : Fluxo do PDV, abertura de caixa, navegação e comandos
  - /Impressao     : Rotas e disparos de impressão térmica (KDS e Vendas)
  - /BancoDados    : Consultas e alterações no SQLite (Drift)
  - /Erros         : Espelho dedicado de TODOS os erros e falhas do sistema
  - /Auditoria     : Registro forense de ações de usuários e precificação

------------------------------------------------------------------------
 COMO CONFIGURAR DESTAQUE DE CORES NO BARETAIL (WINDOWS)
------------------------------------------------------------------------
1. Abra o aplicativo BareTail no Windows (software leve e portátil).
2. Acesse o menu superior: Options -> Highlight...
3. Clique em "Add" e cadastre as seguintes regras de palavras:

 Regra (Text)    | Estilo Recomendado           | Finalidade
-----------------+------------------------------+-------------------------
 [ERRO]          | Fundo Vermelho / Texto Branco | Exceções e erros graves
 [CRÍTICO]       | Fundo Vermelho / Texto Amarelo | Crash de aplicação
 [AVISO]         | Fundo Amarelo / Texto Preto  | Alertas e retries
 [INSERT]        | Fundo Verde Claro / Texto    | Inserção de dados
 [UPDATE]        | Fundo Azul Claro / Texto     | Atualização de dados
 [DELETE]        | Fundo Magenta / Texto Branco | Exclusão de dados
 [SUCESSO]       | Texto Verde Bright           | Operação OK
 [FALHA]         | Fundo Laranja / Texto Preto  | Falhas de conexão
 [SINCRONISMO]   | Texto Roxo (Purple)          | Eventos de Sync
 [IMPRESSAO]     | Texto Ciano (Cyan)           | Eventos de Impressora

DICA: No BareTail você pode abrir múltiplos arquivos simultaneamente
(ex: Sincronizacao e Erros) e marcar "Follow Tail" para acompanhar a
operação do restaurante em tempo real!
========================================================================
''', encoding: utf8);
        }
      } catch (_) {}
    });
  }

  // ── Console ────────────────────────────────────────────────────────────────

  void _printToConsole(LogLevel level, List<String> lines) {
    final out = lines.join('\n');
    debugPrint(out);
  }

  // ── Limpeza automática (logs > 30 dias) ───────────────────────────────────

  void _scheduleCleanup() {
    if (kIsWeb) return;
    Future.microtask(() async {
      try {
        final dir = Directory(logRootPath);
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
      } catch (_) {}
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LogService (Wrapper de Compatibilidade + Central de Consulta)
// ─────────────────────────────────────────────────────────────────────────────

class LogService {
  static LogService? _instance;
  final String baseDirectory;
  bool isProduction = false;

  LogService._(this.baseDirectory);

  static void init(String baseDirectory, {bool runCleanup = true, bool isProduction = false}) {
    _instance = LogService._(baseDirectory)..isProduction = isProduction;
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

    String? detailStr;
    if (exception != null) detailStr = exception;
    if (stackTrace != null) {
      detailStr = detailStr != null ? '$detailStr\n$stackTrace' : stackTrace;
    }

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

  /// Consulta os arquivos de log no disco e retorna os dados estruturados para a UI
  Future<List<Map<String, dynamic>>> queryLogs({
    LogModule? module,
    LogLevel? level,
    DateTime? start,
    DateTime? end,
    String? searchQuery,
  }) async {
    if (kIsWeb) return [];

    final results = <Map<String, dynamic>>[];
    try {
      final rootDir = Directory(FincoreLogger.instance.logRootPath);
      if (!await rootDir.exists()) return [];

      final files = await rootDir
          .list(recursive: true)
          .where((f) => f is File && f.path.endsWith('.log'))
          .cast<File>()
          .toList();

      for (final file in files) {
        final lines = await file.readAsLines(encoding: utf8);
        Map<String, dynamic>? currentEntry;

        for (final line in lines) {
          if (line.startsWith('=') || line.startsWith('Sessão') || line.startsWith('\uFEFF') || line.trim().isEmpty) {
            continue;
          }

          final match = RegExp(r'^(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{3})\s+\[([A-ZÇÍ]+)\s*\](?:\s+\[[A-Z]+\])?\s+\[([A-Z_]+)\s*\]\s+(.*)$').firstMatch(line);

          if (match != null) {
            final tsStr = match.group(1)!;
            final levelStr = match.group(2)!.trim();
            final moduleStr = match.group(3)!.trim();
            final msgStr = match.group(4)!;

            final dt = DateTime.tryParse(tsStr);

            if (start != null && dt != null && dt.isBefore(start)) {
              currentEntry = null;
              continue;
            }
            if (end != null && dt != null && dt.isAfter(end)) {
              currentEntry = null;
              continue;
            }

            if (level != null && !levelStr.toUpperCase().contains(level.name.toUpperCase())) {
              currentEntry = null;
              continue;
            }
            if (module != null && !moduleStr.toUpperCase().contains(module.name.toUpperCase())) {
              currentEntry = null;
              continue;
            }

            if (searchQuery != null && searchQuery.isNotEmpty) {
              if (!line.toLowerCase().contains(searchQuery.toLowerCase())) {
                currentEntry = null;
                continue;
              }
            }

            currentEntry = {
              'timestamp': tsStr,
              'level': levelStr,
              'module': moduleStr,
              'message': msgStr,
              'exception': null,
            };
            results.add(currentEntry);
          } else if (currentEntry != null && line.trim().startsWith('>>>')) {
            final detailText = line.trim().substring(3).trim();
            if (currentEntry['exception'] == null) {
              currentEntry['exception'] = detailText;
            } else {
              currentEntry['exception'] = '${currentEntry['exception']}\n$detailText';
            }
          }
        }
      }

      results.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    } catch (e) {
      debugPrint('Erro ao consultar logs de disco: $e');
    }
    return results;
  }
}
