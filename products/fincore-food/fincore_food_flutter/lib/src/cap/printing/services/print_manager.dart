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

  /// Imprime um teste realista de cupom em uma impressora específica.
  Future<PrinterResult> imprimirTeste({
    required String printerPath,
    required PrintVia via,
    int larguraPapel = 80,
  }) async {
    final sampleData = PrintData(
      pedidoId: 'TEST-101',
      numeroPedido: 101,
      clienteNome: 'Cliente Teste (Demonstração)',
      clienteTelefone: '(15) 99999-8888',
      tipoLogistica: 'Entrega',
      endereco: 'Av. Paulista, 1000 - Apt 42',
      bairro: 'Bela Vista',
      cidade: 'Sorocaba',
      uf: 'SP',
      formaPagamento: 'PIX',
      totalCentavos: 4500,
      taxaEntregaCentavos: 500,
      trocoParaCentavos: 5000,
      itens: const [
        PrintDataItem(
          nome: 'X-Tudo Especial Gourmet',
          quantidade: 2,
          precoUnitarioCentavos: 1800,
          totalCentavos: 3600,
          observacao: 'Sem cebola, bacon extra',
        ),
        PrintDataItem(
          nome: 'Coca-Cola 2L Gelada',
          quantidade: 1,
          precoUnitarioCentavos: 900,
          totalCentavos: 900,
        ),
      ],
      dataHora: DateTime.now(),
      observacao: 'TESTE DE IMPRESSAO - Demonstracao de layout fisico',
      status: 'confirmado',
    );

    final config = PrintConfig(
      printers: const {
        PrintVia.cliente: 'default',
        PrintVia.cozinha: 'default',
        PrintVia.balcao: 'default',
        PrintVia.expedicao: 'default',
      },
      autoprint: const {
        PrintVia.cliente: true,
        PrintVia.cozinha: true,
        PrintVia.balcao: true,
        PrintVia.expedicao: true,
      },
      vias: const {
        PrintVia.cliente: 1,
        PrintVia.cozinha: 1,
        PrintVia.balcao: 1,
        PrintVia.expedicao: 1,
      },
      larguraPapel: larguraPapel,
      nomeEmpresaCupom: 'FINCORE FOOD - TESTE',
      imprimirRodape: true,
      mensagemRodape: 'Obrigado pela preferência! Volte sempre!',
    );

    final lines = _templateEngine.render(via: via, data: sampleData, config: config);
    final text = lines.join('\n');

    return _driver.send(
      printerPath: printerPath,
      text: text,
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
