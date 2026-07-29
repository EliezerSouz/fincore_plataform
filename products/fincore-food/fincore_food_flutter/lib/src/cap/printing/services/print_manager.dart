import 'package:flutter/foundation.dart';
import '../models/print_config.dart';
import '../models/print_data.dart';
import '../templates/print_template_engine.dart';
import '../drivers/printer_driver.dart';

/// Resultado agregado de uma operação de impressão multi-via.
class PrintManagerResult {
  final Map<PrintVia, PrinterResult> results;
  final bool allSuccess;
  final int totalMs;

  const PrintManagerResult({
    required this.results,
    required this.allSuccess,
    required this.totalMs,
  });

  /// Mensagem resumo para exibição na UI.
  String get summary {
    if (allSuccess) return 'Todas as vias impressas com sucesso';
    final falhas = results.entries
        .where((e) => !e.value.success)
        .map((e) => '${e.key.displayName}: ${e.value.message}')
        .join(', ');
    return 'Falhas: $falhas';
  }
}

/// Orquestra a impressão em todas as vias configuradas.
///
/// Fluxo:
/// 1. Recebe [PrintData] + [PrintConfig]
/// 2. Determina quais vias devem ser impressas
/// 3. Para cada via: gera template → envia para impressora
/// 4. Retorna resultado agregado
///
/// A UI **nunca** chama este serviço diretamente.
/// O [PrintUseCase] é responsável por chamar o Manager.
class PrintManager {
  final PrintTemplateEngine _templateEngine;
  final PrinterDriver _driver;

  const PrintManager({
    PrintTemplateEngine templateEngine = const PrintTemplateEngine(),
    PrinterDriver driver = const PrinterDriver(),
  })  : _templateEngine = templateEngine,
        _driver = driver;

  /// Imprime automaticamente em todas as vias que têm autoprint habilitado.
  Future<PrintManagerResult> imprimirAutomatico({
    required PrintData data,
    required PrintConfig config,
  }) async {
    final viasParaImprimir = config.viasAutoprint;
    if (viasParaImprimir.isEmpty) {
      return const PrintManagerResult(
        results: {},
        allSuccess: true,
        totalMs: 0,
      );
    }

    return _imprimirVias(
      vias: viasParaImprimir,
      data: data,
      config: config,
    );
  }

  /// Imprime uma via específica (para reimpressão manual ou via avulsa).
  Future<PrinterResult> imprimirVia({
    required PrintVia via,
    required PrintData data,
    required PrintConfig config,
  }) async {
    if (!config.isEnabled(via)) {
      return PrinterResult(
        success: false,
        message: 'A via ${via.displayName} está desabilitada nas configurações.',
      );
    }

    final printer = config.printer(via);
    if (printer == null || printer.isEmpty) {
      return const PrinterResult(
        success: false,
        message: 'Nenhuma impressora configurada para esta via',
      );
    }

    final lines = _templateEngine.render(via: via, data: data, config: config);
    final text = lines.join('\n');

    final copias = config.copias(via);
    final copiasEfetivas = copias;

    PrinterResult? lastResult;
    for (int i = 0; i < copiasEfetivas; i++) {
      lastResult = await _driver.send(
        printerPath: printer,
        text: text,
        cortarPapel: config.cortarPapel,
        abrirGaveta: via == PrintVia.cliente && config.abrirGaveta,
        larguraPapel: config.larguraPapel,
      );
      if (!lastResult.success) break;
    }

    return lastResult ?? const PrinterResult(
      success: false,
      message: 'Nenhuma cópia impressa',
    );
  }

  /// Imprime múltiplas vias em paralelo.
  Future<PrintManagerResult> _imprimirVias({
    required List<PrintVia> vias,
    required PrintData data,
    required PrintConfig config,
  }) async {
    final sw = Stopwatch()..start();
    final results = <PrintVia, PrinterResult>{};

    // Imprimir sequencialmente para evitar conflito no spooler
    for (final via in vias) {
      debugPrint('[PrintManager] Imprimindo ${via.displayName}...');
      results[via] = await imprimirVia(
        via: via,
        data: data,
        config: config,
      );
    }

    sw.stop();

    final allSuccess = results.values.every((r) => r.success);
    debugPrint('[PrintManager] ${allSuccess ? "✅" : "⚠️"} ${results.length} vias processadas em ${sw.elapsedMilliseconds}ms');

    return PrintManagerResult(
      results: results,
      allSuccess: allSuccess,
      totalMs: sw.elapsedMilliseconds,
    );
  }

  /// Imprime um teste rápido em uma impressora específica.
  Future<PrinterResult> imprimirTeste({
    required String printerPath,
    required PrintVia via,
    int larguraPapel = 80,
  }) async {
    final w = larguraPapel == 58 ? 32 : 48;
    final line = '=' * w;
    final sep = '-' * w;
    final now = DateTime.now();
    final nowStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final sb = StringBuffer();
    sb.writeln(line);
    sb.writeln(_center('FINCORE FOOD', w));
    sb.writeln(_center('TESTE DE IMPRESSAO', w));
    sb.writeln(line);
    sb.writeln('VIA      : ${via.displayName}');
    sb.writeln('LARGURA  : ${larguraPapel}mm');
    sb.writeln('DATA     : $nowStr');
    sb.writeln('STATUS   : ONLINE [OK]');
    sb.writeln(sep);
    sb.writeln(_center('Impressora configurada', w));
    sb.writeln(_center('com sucesso!', w));
    sb.writeln(line);
    sb.writeln('\n\n\n');

    return _driver.send(
      printerPath: printerPath,
      text: sb.toString(),
      cortarPapel: true,
      abrirGaveta: false,
      larguraPapel: larguraPapel,
    );
  }

  String _center(String text, int width) {
    if (text.length >= width) return text;
    final pad = (width - text.length) ~/ 2;
    return ' ' * pad + text;
  }
}
