import 'dart:io';
import 'package:test/test.dart';
import 'package:fincore_core/fincore_core.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fincore_log_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('LogService cria arquivos de log organizados por categorias', () async {
    LogService.init(tempDir.path, runCleanup: false);

    final logger = LogService.instance;

    await logger.info(LogModule.app, 'Mensagem informativa', tenantId: 'tenant-123', userId: 'user-456');
    await logger.error(LogModule.sync, 'Falha catastrófica no sync', tenantId: 'tenant-123', exception: 'SocketException: timeout');

    final logDir = Directory(FincoreLogger.instance.logRootPath);
    expect(await logDir.exists(), isTrue);

    final files = logDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.log')).toList();
    expect(files.length, equals(3)); // Operacional, Sincronizacao, Erros (espelho)

    final opFile = files.firstWhere((f) => f.path.contains('Operacional'));
    final syncFile = files.firstWhere((f) => f.path.contains('Sincronizacao'));
    final errorFile = files.firstWhere((f) => f.path.contains('Erros'));

    final opContent = await opFile.readAsString();
    expect(opContent, contains('[SISTEMA'));
    expect(opContent, contains('Mensagem informativa'));

    final syncContent = await syncFile.readAsString();
    expect(syncContent, contains('[SINCRONISMO'));
    expect(syncContent, contains('Falha catastrófica no sync'));

    final errorContent = await errorFile.readAsString();
    expect(errorContent, contains('[ERRO'));
    expect(errorContent, contains('Falha catastrófica no sync'));
  });

  test('LogService remove arquivos de log mais velhos que 30 dias no startup', () async {
    final oldDir = Directory('${tempDir.path}/LOG/Erros');
    await oldDir.create(recursive: true);
    
    // 1. Criar arquivo simulando log antigo (deve terminar com .log)
    final oldFile = File('${oldDir.path}/erros_2020-01-01.log');
    await oldFile.writeAsString('{"old_log": true}');
    
    // Configurar data de modificação antiga
    final backThen = DateTime.now().subtract(const Duration(days: 35));
    await oldFile.setLastModified(backThen);

    // Criar um arquivo recente que NÃO deve ser excluído
    final recentFile = File('${oldDir.path}/erros_today.log');
    await recentFile.writeAsString('{"recent": true}');
    await recentFile.setLastModified(DateTime.now());

    // 2. Inicializar o LogService (que chama _scheduleCleanup)
    LogService.init(tempDir.path, runCleanup: true);

    // Dar um pequeno tempo para a microtask de cleanup rodar
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Verificar que o arquivo antigo foi deletado e o novo permaneceu
    expect(await oldFile.exists(), isFalse);
    expect(await recentFile.exists(), isTrue);
  });

  test('LogService.queryLogs retorna registros filtrados a partir do disco', () async {
    LogService.init(tempDir.path, runCleanup: false);

    await LogService.instance.info(LogModule.app, 'Operação normal do PDV');
    await LogService.instance.error(LogModule.sync, 'Falha de rede Supabase');

    final results = await LogService.instance.queryLogs();
    expect(results.length, greaterThanOrEqualTo(2));

    final syncResults = await LogService.instance.queryLogs(module: LogModule.sync);
    expect(syncResults.every((r) => r['module'].toString().contains('SINCRONISMO')), isTrue);
  });
}
