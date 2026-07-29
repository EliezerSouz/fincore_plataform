import 'dart:convert';
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

  test('LogService cria arquivos de log estruturados em JSON Lines', () async {
    LogService.init(tempDir.path, runCleanup: false);

    final logger = LogService.instance;

    await logger.info(LogModule.app, 'Mensagem informativa', tenantId: 'tenant-123', userId: 'user-456');
    await logger.error(LogModule.sync, 'Falha catastrófica no sync', tenantId: 'tenant-123', exception: 'SocketException: timeout');

    // Validar pasta app
    final appLogDir = Directory('${tempDir.path}/logs/app');
    expect(await appLogDir.exists(), isTrue);

    final appFiles = appLogDir.listSync();
    expect(appFiles.length, equals(1));
    expect(appFiles.first, isA<File>());

    final appLogContent = await (appFiles.first as File).readAsString();
    final appJson = jsonDecode(appLogContent.trim());
    expect(appJson['message'], equals('Mensagem informativa'));
    expect(appJson['level'], equals('INFO'));
    expect(appJson['module'], equals('APP'));
    expect(appJson['tenantId'], equals('tenant-123'));
    expect(appJson['userId'], equals('user-456'));
    expect(appJson['timestamp'], isNotNull);

    // Validar pasta sync
    final syncLogDir = Directory('${tempDir.path}/logs/sync');
    expect(await syncLogDir.exists(), isTrue);

    final syncFiles = syncLogDir.listSync();
    expect(syncFiles.length, equals(1));
    
    final syncLogContent = await (syncFiles.first as File).readAsString();
    final syncJson = jsonDecode(syncLogContent.trim());
    expect(syncJson['message'], equals('Falha catastrófica no sync'));
    expect(syncJson['level'], equals('ERROR'));
    expect(syncJson['module'], equals('SYNC'));
    expect(syncJson['exception'], equals('SocketException: timeout'));
  });

  test('LogService remove arquivos de log mais velhos que 90 dias no startup', () async {
    // 1. Criar pasta e arquivo simulando log antigo
    final oldLogsDir = Directory('${tempDir.path}/logs/app');
    await oldLogsDir.create(recursive: true);
    final oldFile = File('${oldLogsDir.path}/fincore_app_2020-01-01.log');
    await oldFile.writeAsString('{"old_log": true}');
    
    // Configurar data de modificação antiga
    final backThen = DateTime.now().subtract(const Duration(days: 95));
    await oldFile.setLastModified(backThen);

    // Criar um arquivo recente que NÃO deve ser excluído
    final recentFile = File('${oldLogsDir.path}/fincore_app_today.log');
    await recentFile.writeAsString('{"recent": true}');
    await recentFile.setLastModified(DateTime.now());

    // 2. Inicializar o LogService e forçar a limpeza síncrona
    LogService.init(tempDir.path, runCleanup: false);
    await LogService.instance.forceCleanup();

    // 3. Verificar que o arquivo antigo foi deletado e o novo permaneceu
    expect(await oldFile.exists(), isFalse);
    expect(await recentFile.exists(), isTrue);
  });
}
