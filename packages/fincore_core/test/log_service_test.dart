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

  test('LogService cria arquivos de log narrativos', () async {
    LogService.init(tempDir.path, runCleanup: false);

    final logger = LogService.instance;

    await logger.info(LogModule.app, 'Mensagem informativa', tenantId: 'tenant-123', userId: 'user-456');
    await logger.error(LogModule.sync, 'Falha catastrófica no sync', tenantId: 'tenant-123', exception: 'SocketException: timeout');

    // Validar pasta logs
    final logDir = Directory('${tempDir.path}/logs');
    expect(await logDir.exists(), isTrue);

    final files = logDir.listSync(recursive: true).whereType<File>().toList();
    expect(files.length, equals(1));
    expect(files.first, isA<File>());

    final logContent = await files.first.readAsString();
    expect(logContent, contains('[SISTEMA    ]'));
    expect(logContent, contains('Mensagem informativa'));
    expect(logContent, contains('[SINCRONISMO]'));
    expect(logContent, contains('Falha catastrófica no sync'));
  });

  test('LogService remove arquivos de log mais velhos que 30 dias no startup', () async {
    final oldDir = Directory('${tempDir.path}/logs/2020-01/01');
    await oldDir.create(recursive: true);
    
    // 1. Criar arquivo simulando log antigo (deve terminar com .log)
    final oldFile = File('${oldDir.path}/fincore_10.log');
    await oldFile.writeAsString('{"old_log": true}');
    
    // Configurar data de modificação antiga
    final backThen = DateTime.now().subtract(const Duration(days: 35));
    await oldFile.setLastModified(backThen);

    // Criar um arquivo recente que NÃO deve ser excluído
    final recentFile = File('${oldDir.path}/fincore_today_10.log');
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
}
