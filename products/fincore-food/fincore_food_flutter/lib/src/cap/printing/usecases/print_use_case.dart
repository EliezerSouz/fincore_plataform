import 'package:flutter/foundation.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:fincore_core/repository/print_job_repository.dart';
import '../models/print_config.dart';
import '../models/print_data.dart';
import '../services/print_manager.dart';
import '../drivers/printer_driver.dart';

/// Resultado do UseCase de impressão — combina resultado de impressão + jobs registrados.
class PrintUseCaseResult {
  final PrintManagerResult managerResult;
  final List<PrintJob> jobs;

  const PrintUseCaseResult({
    required this.managerResult,
    required this.jobs,
  });

  bool get success => managerResult.allSuccess;
  String get summary => managerResult.summary;
}

/// Caso de uso principal para impressão.
///
/// Responsabilidades:
/// 1. Carrega configurações do banco (via EmpresaConfiguracaoRepository)
/// 2. Converte para PrintConfig
/// 3. Delega para o PrintManager
/// 4. Registra cada job no PrintJobRepository (histórico/auditoria)
///
/// A UI chama **apenas** este UseCase. Nunca o PrintManager ou PrinterDriver.
class PrintUseCase {
  final EmpresaConfiguracaoRepository _configRepo;
  final PrintJobRepository _jobRepo;
  final PrintManager _manager;

  PrintUseCase({
    required EmpresaConfiguracaoRepository configRepo,
    required PrintJobRepository jobRepo,
    PrintManager manager = const PrintManager(),
  })  : _configRepo = configRepo,
        _jobRepo = jobRepo,
        _manager = manager;

  /// Imprime automaticamente em todas as vias configuradas.
  /// Chamado após finalizar um pedido.
  Future<PrintUseCaseResult> imprimirPedido({
    required PrintData data,
    String usuario = 'sistema',
  }) async {
    final config = await loadConfig();
    if (config == null) {
      debugPrint('[PrintUseCase] Sem configuração — impressão ignorada');
      return PrintUseCaseResult(
        managerResult: const PrintManagerResult(
          results: {},
          allSuccess: true,
          totalMs: 0,
        ),
        jobs: [],
      );
    }

    final result = await _manager.imprimirAutomatico(data: data, config: config);

    // Registrar cada via no histórico
    final jobs = <PrintJob>[];
    for (final entry in result.results.entries) {
      final via = entry.key;
      final printerResult = entry.value;
      final job = await _jobRepo.create(
        pedidoId: data.pedidoId,
        tipoVia: via.name,
        impressora: config.printer(via) ?? '',
        usuario: usuario,
        templateUsado: via.templateName,
      );
      await _jobRepo.updateStatus(
        job.id,
        status: printerResult.success ? 'success' : 'error',
        erro: printerResult.success ? null : printerResult.message,
        tempoExecucaoMs: printerResult.elapsedMs,
      );
      jobs.add(job.copyWith(
        status: printerResult.success ? 'success' : 'error',
        erro: printerResult.success ? null : printerResult.message,
        tempoExecucaoMs: printerResult.elapsedMs,
      ));
    }

    return PrintUseCaseResult(managerResult: result, jobs: jobs);
  }

  /// Reimprime uma via específica (botão "Reimprimir" na UI).
  Future<PrinterResult> reimprimir({
    required PrintVia via,
    required PrintData data,
    String usuario = 'sistema',
  }) async {
    final config = await loadConfig();
    if (config == null) {
      return const PrinterResult(
        success: false,
        message: 'Configurações não encontradas',
      );
    }

    final result = await _manager.imprimirVia(
      via: via,
      data: data,
      config: config,
    );

    // Registrar no histórico
    final job = await _jobRepo.create(
      pedidoId: data.pedidoId,
      tipoVia: via.name,
      impressora: config.printer(via) ?? '',
      usuario: usuario,
      templateUsado: via.templateName,
    );
    await _jobRepo.updateStatus(
      job.id,
      status: result.success ? 'success' : 'error',
      erro: result.success ? null : result.message,
      tempoExecucaoMs: result.elapsedMs,
    );

    return result;
  }

  /// Imprime um teste em uma impressora específica.
  Future<PrinterResult> testarImpressora({
    required String printerPath,
    required PrintVia via,
  }) async {
    final config = await loadConfig();
    return _manager.imprimirTeste(
      printerPath: printerPath,
      via: via,
      larguraPapel: config?.larguraPapel ?? 80,
    );
  }

  /// Carrega o histórico de impressões de um pedido.
  Future<List<PrintJob>> historicoPedido(String pedidoId) {
    return _jobRepo.findByPedidoId(pedidoId);
  }

  /// Carrega o histórico recente de impressões.
  Future<List<PrintJob>> historicoRecente({int limit = 50}) {
    return _jobRepo.findRecent(limit: limit);
  }

  /// Carrega a PrintConfig do banco.
  Future<PrintConfig?> loadConfig() async {
    final configs = await _configRepo.findAll();
    if (configs.isEmpty) return null;
    return PrintConfig.fromEntity(configs.first);
  }
}
