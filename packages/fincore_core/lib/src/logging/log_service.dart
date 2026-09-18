import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'log_event.dart';

export 'log_event.dart';

/// Helper para geração de IDs correlacionados e prefixados (Correlation ID).
class CorrelationIdGenerator {
  static int _counter = 0;

  static String generateCorrelationId([DateTime? date]) {
    final now = date ?? DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    _counter = (_counter + 1) % 10000;
    final seq = _counter.toString().padLeft(4, '0');
    return 'REQ-$y$m$d-$seq';
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
  static bool enableJsonl = false;

  final String baseDirectory;
  final bool isProduction;
  final String appVersion;

  // Cache de arquivos de log por categoria e data
  final Map<String, File> _activeFiles = {};
  final Map<String, String> _activeDates = {};

  FincoreLogger._(this.baseDirectory, {this.isProduction = false, this.appVersion = 'v1.0.0'});

  // ── Inicialização ──────────────────────────────────────────────────────────

  static void init(String baseDirectory, {bool isProduction = false, String appVersion = 'v1.0.0'}) {
    LogEvent.defaultAppVersion = appVersion;
    _instance = FincoreLogger._(baseDirectory, isProduction: isProduction, appVersion: appVersion);
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
    final ctxInfo = context != null ? ' | Context: $context' : '';
    await _write(LogLevel.info, module, '>>> START: $title [$appVersion]$ctxInfo');
  }

  Future<void> endCycle(LogModule module, String summary) async {
    await _write(LogLevel.info, module, '<<< END: $summary');
  }

  /// Emite evento operacional narrativo (PROCESSO -> ETAPA -> AÇÃO -> CONTEXTO -> RESULTADO)
  Future<void> logOperational({
    required String process,
    required String step,
    required String action,
    required String message,
    String? traceId,
    String? entityType,
    String? entityId,
    LogStatus status = LogStatus.success,
    int? durationMs,
    String? errorCode,
    String? errorType,
    String? errorMessage,
    Map<String, dynamic>? context,
    String? tenantId,
    String? userId,
  }) async {
    final effectiveTraceId = traceId ?? CorrelationIdGenerator.generateCorrelationId();
    final event = LogEvent(
      level: status == LogStatus.failed ? LogLevel.error : LogLevel.info,
      category: LogCategory.operacional,
      process: process,
      step: step,
      eventType: process,
      action: action,
      module: LogModule.pedidos,
      operation: step,
      message: message,
      traceId: effectiveTraceId,
      entityType: entityType,
      entityId: entityId,
      status: status,
      durationMs: durationMs,
      errorCode: errorCode,
      errorType: errorType,
      errorMessage: errorMessage,
      tenantId: tenantId,
      userId: userId,
      metadata: context ?? const {},
    );
    await emitEvent(event);
  }

  /// Emite evento de mutação de banco de dados estruturado
  Future<void> logDatabase({
    required String step,
    required String action,
    required String entity,
    required String id,
    String? process,
    String? operation,
    int? version,
    int? oldVersion,
    String? traceId,
    LogStatus status = LogStatus.success,
    int? durationMs,
    String? details,
    String? tenantId,
  }) async {
    final effectiveTraceId = traceId ?? CorrelationIdGenerator.generateCorrelationId();
    final versionStr = (oldVersion != null && oldVersion > 0)
        ? 'Versão: $oldVersion → ${version ?? (oldVersion + 1)}'
        : (version != null ? 'Versão: v$version' : null);
    final msg = [
      if (operation != null) operation,
      if (versionStr != null) versionStr,
      if (details != null && details.isNotEmpty) details,
    ].join(' | ');

    final event = LogEvent(
      level: status == LogStatus.failed ? LogLevel.error : LogLevel.info,
      category: LogCategory.bancoDados,
      process: process ?? entity.toUpperCase(),
      step: step,
      eventType: 'MUTACAO_LOCAL',
      action: action,
      module: LogModule.database,
      operation: operation ?? 'MUTACAO',
      message: msg.isNotEmpty ? msg : 'Operação de banco em $entity',
      traceId: effectiveTraceId,
      entityType: entity,
      entityId: id,
      status: status,
      durationMs: durationMs,
      tenantId: tenantId,
    );
    await emitEvent(event);
  }

  /// Emite evento de sincronização (PUSH / PULL / REALTIME / RETRY)
  Future<void> logSync({
    required String step,
    required String action,
    String? entity,
    String? id,
    String? traceId,
    int attempt = 1,
    int maxAttempts = 5,
    LogStatus status = LogStatus.success,
    int? durationMs,
    String? errorCode,
    String? errorReason,
    String? errorMessage,
    String? message,
    String? tenantId,
  }) async {
    final effectiveTraceId = traceId ?? CorrelationIdGenerator.generateCorrelationId();
    final isError = status == LogStatus.failed || (errorCode != null && status != LogStatus.success);
    final isWarning = status == LogStatus.retrying || status == LogStatus.partial;

    final event = LogEvent(
      level: isError ? LogLevel.error : (isWarning ? LogLevel.warning : LogLevel.info),
      category: LogCategory.sincronizacao,
      process: (entity != null && entity.trim().isNotEmpty) ? entity.trim().toUpperCase() : 'SINCRONIZACAO',
      step: step,
      eventType: 'SINCRONIZACAO',
      action: action,
      module: LogModule.sync,
      operation: step,
      message: message ?? (entity != null ? '$action $entity' : 'Sincronização $step'),
      traceId: effectiveTraceId,
      entityType: entity,
      entityId: id,
      attempt: attempt,
      status: status,
      durationMs: durationMs,
      errorCode: errorCode,
      errorType: errorReason,
      errorMessage: errorMessage,
      tenantId: tenantId,
    );
    await emitEvent(event);
  }

  /// Emite um [LogEvent] estruturado de forma não-bloqueante para o disco e console.
  Future<void> emitEvent(LogEvent event) async {
    if (isProduction && event.level == LogLevel.debug) return;
    try {
      final line = event.toBareTailLine();
      final jsonLine = jsonEncode(event.toJson());
      final category = _categoryForModule(event.module);
      await _writeLineToCategory(category, line, event.timestamp, jsonLine: jsonLine);

      if ((event.level == LogLevel.error || event.level == LogLevel.critical || event.module == LogModule.crash) &&
          category.folderName != 'Erros') {
        const errorCategory = _LogCategoryConfig('Erros', 'erros');
        await _writeLineToCategory(errorCategory, line, event.timestamp, jsonLine: jsonLine);
      }
      _printToConsole(event.level, [line]);
    } catch (e) {
      debugPrint('! FINCORE LOGGER NON-BLOCKING ERROR: $e');
    }
  }

  // ── Mapeamento de Categorias ──────────────────────────────────────────────

  static _LogCategoryConfig _categoryForModule(LogModule module) {
    return switch (module) {
      LogModule.sync         => const _LogCategoryConfig('Sincronizacao', 'sync'),
      LogModule.importExport => const _LogCategoryConfig('ImportExport', 'import_export'),
      LogModule.printer      => const _LogCategoryConfig('Impressao', 'impressao'),
      LogModule.database ||
      LogModule.migration ||
      LogModule.estoque      => const _LogCategoryConfig('BancoDados', 'banco_dados'),
      LogModule.crash        => const _LogCategoryConfig('Erros', 'erros'),
      LogModule.audit ||
      LogModule.api          => const _LogCategoryConfig('Auditoria', 'auditoria'),
      LogModule.app ||
      LogModule.startup ||
      LogModule.producao ||
      LogModule.pedidos ||
      LogModule.financeiro   => const _LogCategoryConfig('Operacional', 'operacional'),
    };
  }

  static LogCategory _categoryEnumForModule(LogModule module) {
    return switch (module) {
      LogModule.sync         => LogCategory.sincronizacao,
      LogModule.importExport => LogCategory.operacional,
      LogModule.printer      => LogCategory.printer,
      LogModule.database     => LogCategory.bancoDados,
      LogModule.migration    => LogCategory.bancoDados,
      LogModule.estoque      => LogCategory.bancoDados,
      LogModule.crash        => LogCategory.erro,
      LogModule.audit        => LogCategory.auditoria,
      LogModule.api          => LogCategory.api,
      LogModule.startup      => LogCategory.sistema,
      LogModule.producao     => LogCategory.operacional,
      LogModule.pedidos      => LogCategory.operacional,
      LogModule.financeiro   => LogCategory.operacional,
      LogModule.app          => LogCategory.sistema,
    };
  }

  static String _detectAction(String message) {
    final upper = message.toUpperCase();
    if (upper.contains('INSERT') || upper.contains('INSERIDO') || upper.contains('CRIADO') || upper.contains('CREATE')) return 'CREATE';
    if (upper.contains('UPDATE') || upper.contains('ATUALIZADO') || upper.contains('ALTERADO')) return 'UPDATE';
    if (upper.contains('DELETE') || upper.contains('REMOVIDO') || upper.contains('EXCLUÍDO') || upper.contains('DELETADO')) return 'DELETE';
    if (upper.contains('PUSH')) return 'PUSH';
    if (upper.contains('PULL')) return 'PULL';
    if (upper.contains('START') || upper.contains('INICIO') || upper.contains('INÍCIO')) return 'START';
    return 'EXECUTE';
  }

  static String _detectEventType(String message, LogModule module) {
    final upper = message.toUpperCase();
    if (upper.contains('MUTACAO') || upper.contains('MUTATION')) return 'MUTACAO_LOCAL';
    if (upper.contains('SYNC') || upper.contains('SINCRONISMO')) return 'SINCRONIZACAO';
    if (upper.contains('ESTOQUE')) return 'ESTOQUE';
    if (upper.contains('PEDIDO')) return 'PEDIDO';
    if (upper.contains('PRODUCAO') || upper.contains('PRODUÇÃO')) return 'PRODUCAO';
    if (upper.contains('STARTUP') || upper.contains('INICIALIZADO')) return 'INICIALIZACAO';
    return '${module.name.toUpperCase()}_EVENT';
  }

  // ── Formatação BareTail Friendly ──────────────────────────────────────────

  static String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y  = local.year;
    final mo = local.month.toString().padLeft(2, '0');
    final d  = local.day.toString().padLeft(2, '0');
    final h  = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    final s  = local.second.toString().padLeft(2, '0');
    final ms = local.millisecond.toString().padLeft(3, '0');
    
    final offset = local.timeZoneOffset;
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (offset.inMinutes.remainder(60)).abs().toString().padLeft(2, '0');
    final offsetSign = offset.isNegative ? '-' : '+';
    final tzStr = '$offsetSign$offsetHours:$offsetMinutes';

    return '$y-$mo-$d $h:$mi:$s.$ms $tzStr';
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
      LogModule.estoque      => 'ESTOQUE',
      LogModule.producao     => 'PRODUCAO',
      LogModule.pedidos      => 'PEDIDOS',
      LogModule.financeiro   => 'FINANCEIRO',
    };
    return '[${name.padRight(13)}]';
  }

  static String _levelTag(LogLevel level) {
    return switch (level) {
      LogLevel.trace    => '[TRACE]  ',
      LogLevel.debug    => '[DEBUG]  ',
      LogLevel.info     => '[INFO]   ',
      LogLevel.notice   => '[NOTICE] ',
      LogLevel.warning  => '[AVISO]  ',
      LogLevel.error    => '[ERRO]   ',
      LogLevel.critical => '[CRÍTICO]',
      LogLevel.audit    => '[AUDIT]  ',
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

    final effectiveTraceId = traceId ?? CorrelationIdGenerator.generateCorrelationId();
    final event = LogEvent(
      level: level,
      category: _categoryEnumForModule(module),
      eventType: _detectEventType(message, module),
      action: _detectAction(message),
      module: module,
      operation: context ?? module.name,
      message: message,
      description: detail,
      traceId: effectiveTraceId,
      metadata: context != null ? {'context': context} : const {},
    );

    await emitEvent(event);
  }

  Future<void> _writeQueue = Future.value();

  Future<void> _writeLineToCategory(_LogCategoryConfig category, String line, DateTime now, {String? jsonLine}) async {
    if (kIsWeb) return;
    final completer = Completer<void>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final file = await _getCategoryFile(category, now);
        await file.writeAsString('$line\n', mode: FileMode.append, encoding: utf8, flush: true);

        if (enableJsonl && jsonLine != null) {
          final jsonFile = await _getCategoryFile(category, now, isJson: true);
          await jsonFile.writeAsString('$jsonLine\n', mode: FileMode.append, encoding: utf8, flush: true);
        }
      } catch (e) {
        debugPrint('! FINCORE LOG IO ERROR ($category): $e');
      } finally {
        completer.complete();
      }
    });
    return completer.future;
  }

  // ── Obtenção / Rotação Diária de Arquivo ─────────────────────────────────

  Future<File> _getCategoryFile(_LogCategoryConfig category, DateTime now, {bool isJson = false}) async {
    final yearStr = now.year.toString();
    final monthStr = now.month.toString().padLeft(2, '0');
    final dayStr = now.day.toString().padLeft(2, '0');
    final dateKey = '$yearStr-$monthStr-$dayStr';
    final monthKey = '$yearStr-$monthStr';

    final ext = isJson ? 'jsonl' : 'log';
    final categoryKey = isJson ? '${category.folderName}_json' : category.folderName;

    if (_activeDates[categoryKey] == dateKey && _activeFiles[categoryKey] != null) {
      return _activeFiles[categoryKey]!;
    }

    final rootDir = logRootPath;
    final dir = Directory('$rootDir/$monthKey');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/${category.filePrefix}_$dateKey.$ext');

    if (!isJson && !await file.exists()) {
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

  String _fileHeader(DateTime now, String categoryName) {
    final ts = _formatTimestamp(now);
    return '\uFEFF' '''
==========================================================================================
  FINCORE Platform $appVersion | Log da Categoria: [$categoryName]
  Arquivo criado em: $ts
  Ambiente: Local (SQLite) <-> Nuvem (Supabase)
==========================================================================================

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

  static void init(String baseDirectory, {bool runCleanup = true, bool isProduction = false, String appVersion = 'v1.0.0'}) {
    _instance = LogService._(baseDirectory)..isProduction = isProduction;
    FincoreLogger.init(baseDirectory, isProduction: isProduction, appVersion: appVersion);
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
      case LogLevel.trace:
      case LogLevel.debug:
        await FincoreLogger.instance.debug(module, message, context: ctxStr, traceId: traceId);
      case LogLevel.info:
      case LogLevel.notice:
        await FincoreLogger.instance.info(module, message, context: ctxStr, traceId: traceId);
      case LogLevel.warning:
        await FincoreLogger.instance.warning(module, message, context: ctxStr, traceId: traceId, detail: detailStr);
      case LogLevel.error:
      case LogLevel.critical:
      case LogLevel.audit:
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

  /// Emite evento operacional narrativo (PROCESSO -> ETAPA -> AÇÃO -> CONTEXTO -> RESULTADO)
  Future<void> logOperational({
    required String process,
    required String step,
    required String action,
    required String message,
    String? traceId,
    String? entityType,
    String? entityId,
    LogStatus status = LogStatus.success,
    int? durationMs,
    String? errorCode,
    String? errorType,
    String? errorMessage,
    Map<String, dynamic>? context,
    String? tenantId,
    String? userId,
  }) => FincoreLogger.instance.logOperational(
    process: process,
    step: step,
    action: action,
    message: message,
    traceId: traceId,
    entityType: entityType,
    entityId: entityId,
    status: status,
    durationMs: durationMs,
    errorCode: errorCode,
    errorType: errorType,
    errorMessage: errorMessage,
    context: context,
    tenantId: tenantId,
    userId: userId,
  );

  /// Emite evento de mutação de banco de dados estruturado
  Future<void> logDatabase({
    required String step,
    required String action,
    required String entity,
    required String id,
    String? process,
    String? operation,
    int? version,
    int? oldVersion,
    String? traceId,
    LogStatus status = LogStatus.success,
    int? durationMs,
    String? details,
    String? tenantId,
  }) => FincoreLogger.instance.logDatabase(
    step: step,
    action: action,
    entity: entity,
    id: id,
    process: process,
    operation: operation,
    version: version,
    oldVersion: oldVersion,
    traceId: traceId,
    status: status,
    durationMs: durationMs,
    details: details,
    tenantId: tenantId,
  );

  /// Emite evento de sincronização (PUSH / PULL / REALTIME / RETRY)
  Future<void> logSync({
    required String step,
    required String action,
    String? entity,
    String? id,
    String? traceId,
    int attempt = 1,
    int maxAttempts = 5,
    LogStatus status = LogStatus.success,
    int? durationMs,
    String? errorCode,
    String? errorReason,
    String? errorMessage,
    String? message,
    String? tenantId,
  }) => FincoreLogger.instance.logSync(
    step: step,
    action: action,
    entity: entity,
    id: id,
    traceId: traceId,
    attempt: attempt,
    maxAttempts: maxAttempts,
    status: status,
    durationMs: durationMs,
    errorCode: errorCode,
    errorReason: errorReason,
    errorMessage: errorMessage,
    message: message,
    tenantId: tenantId,
  );

  /// Emite um [LogEvent] estruturado.
  Future<void> emitEvent(LogEvent event) => FincoreLogger.instance.emitEvent(event);
  Future<void> logEvent(LogEvent event) => FincoreLogger.instance.emitEvent(event);

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
    final seenKeys = <String>{};

    try {
      final rootDir = Directory(FincoreLogger.instance.logRootPath);
      if (!await rootDir.exists()) return [];

      final files = await rootDir
          .list(recursive: true)
          .where((f) => f is File && (f.path.endsWith('.jsonl') || f.path.endsWith('.log')))
          .cast<File>()
          .toList();

      // Processa primeiro os arquivos .jsonl (dados estruturados ricos)
      files.sort((a, b) {
        if (a.path.endsWith('.jsonl') && !b.path.endsWith('.jsonl')) return -1;
        if (!a.path.endsWith('.jsonl') && b.path.endsWith('.jsonl')) return 1;
        return 0;
      });

      for (final file in files) {
        final lines = await file.readAsLines(encoding: utf8);
        final isJsonl = file.path.endsWith('.jsonl');

        if (isJsonl) {
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final map = jsonDecode(line) as Map<String, dynamic>;
              final tsStr = map['timestamp'] as String?;
              final dt = tsStr != null ? DateTime.tryParse(tsStr) : null;

              if (start != null && dt != null && dt.isBefore(start)) continue;
              if (end != null && dt != null && dt.isAfter(end)) continue;

              final levelStr = map['level']?.toString() ?? 'INFO';
              final moduleStr = map['module']?.toString() ?? 'APP';

              if (level != null && !levelStr.toUpperCase().contains(level.name.toUpperCase())) continue;
              if (module != null && !moduleStr.toUpperCase().contains(module.name.toUpperCase())) continue;

              final traceId = map['traceId']?.toString();
              final message = map['message']?.toString() ?? '';

              if (searchQuery != null && searchQuery.isNotEmpty) {
                final fullSearchText = '$line ${traceId ?? ''}'.toLowerCase();
                if (!fullSearchText.contains(searchQuery.toLowerCase())) continue;
              }

              final uniqueKey = map['id']?.toString() ?? '$tsStr-$message';
              if (seenKeys.contains(uniqueKey)) continue;
              seenKeys.add(uniqueKey);

              final modEnum = LogModule.values.firstWhere((m) => m.name.toLowerCase() == moduleStr.toLowerCase(), orElse: () => LogModule.app);
              final displayModule = FincoreLogger._moduleTag(modEnum).replaceAll('[', '').replaceAll(']', '').trim();

              results.add({
                'id': map['id'],
                'timestamp': tsStr ?? '',
                'level': levelStr,
                'module': displayModule,
                'action': map['action'],
                'operation': map['operation'],
                'message': message,
                'traceId': traceId,
                'correlationId': map['correlationId'],
                'userId': map['userId'],
                'tenantId': map['tenantId'],
                'entityType': map['entityType'],
                'entityId': map['entityId'],
                'metadata': map['metadata'],
                'versions': map['versions'],
                'exception': map['error'] != null ? '${map['error']['code'] ?? ''} ${map['error']['message'] ?? ''}' : map['description'],
              });
            } catch (_) {}
          }
        } else {
          // Fallback para arquivos .log de texto
          Map<String, dynamic>? currentEntry;

          for (final line in lines) {
            if (line.startsWith('=') || line.startsWith('Sessão') || line.startsWith('\uFEFF') || line.trim().isEmpty) {
              continue;
            }

            // Suporta o padrão com pipes (|) ou colchetes ([])
            final pipeMatch = RegExp(r'^(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{3}(?:\s[+-]\d{2}:\d{2})?)\s*\|\s*\[?([A-ZÇÍ]+)\]?\s*\|\s*\[?([A-Z_]+)\]?\s*\|\s*(.*)$').firstMatch(line);
            final bracketMatch = RegExp(r'^(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{3})\s+\[([A-ZÇÍ]+)\s*\](?:\s+\[[A-Z]+\])?\s+\[([A-Z_]+)\s*\]\s+(.*)$').firstMatch(line);

            final match = pipeMatch ?? bracketMatch;

            if (match != null) {
              final tsStr = match.group(1)!;
              final levelStr = match.group(2)!.trim();
              final moduleStr = match.group(3)!.trim();
              final msgStr = match.group(4)!;

              final dt = DateTime.tryParse(tsStr.split(' ').first);

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

              // Extrai Trace ID da linha de log se presente [Rastreio: ...]
              String? traceId;
              final traceMatch = RegExp(r'\[Rastreio:\s*([A-Za-z0-9_-]+)\]').firstMatch(msgStr);
              if (traceMatch != null) {
                traceId = traceMatch.group(1);
              }

              final uniqueKey = '$tsStr-$msgStr';
              if (seenKeys.contains(uniqueKey)) continue;
              seenKeys.add(uniqueKey);

              currentEntry = {
                'timestamp': tsStr,
                'level': levelStr,
                'module': moduleStr,
                'message': msgStr,
                'traceId': traceId,
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
      }

      results.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    } catch (e) {
      debugPrint('Erro ao consultar logs de disco: $e');
    }
    return results;
  }
}
