// ═══════════════════════════════════════════════════════════════════════════
// FINCORE Food — Reset do Banco e Caches Locais (Flutter)
// ═══════════════════════════════════════════════════════════════════════════
//
// Uso:
//   cd fincore_food_flutter
//   dart run bin/reset_local_db.dart
//
// O que faz:
//   1. Exclui o banco Drift local (fincore_v3.db e seus journals)
//   2. Exclui a pasta de AppData com SharedPreferences e caches do Hive
//   3. Limpa pasta de logs local
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  print('╔══ FINCORE FOOD — RESET LOCAL FLUTTER ══╗');
  
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  
  // 1. Banco Drift (SQLite)
  final documentsDir = p.join(userProfile, 'Documents');
  final dbFiles = [
    'fincore_v3.db',
    'fincore_v3.db-journal',
    'fincore_v3.db-shm',
    'fincore_v3.db-wal',
  ];
  
  print('\n➜  Limpando banco de dados local SQLite...');
  for (final filename in dbFiles) {
    final filePath = p.join(documentsDir, filename);
    final file = File(filePath);
    if (file.existsSync()) {
      try {
        file.deleteSync();
        print('   ✅ Excluído: $filePath');
      } catch (e) {
        print('   ❌ Erro ao excluir $filename: $e');
      }
    } else {
      print('   ℹ️  Arquivo inexistente: $filename');
    }
  }

  // 2. Caches e SharedPreferences no AppData (Roaming)
  // path_provider no Windows para com.example/fincore_food_flutter
  final appDataDirs = [
    p.join(userProfile, 'AppData', 'Roaming', 'com.example', 'fincore_food_flutter'),
    p.join(userProfile, 'AppData', 'Local', 'com.example', 'fincore_food_flutter'),
    p.join(userProfile, 'AppData', 'Local', 'Temp', 'com.example', 'fincore_food_flutter'),
  ];
  
  print('\n➜  Limpando caches (Hive, SharedPreferences) do AppData...');
  for (final path in appDataDirs) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
        print('   ✅ Pasta excluída: $path');
      } catch (e) {
        print('   ❌ Erro ao excluir pasta $path: $e');
      }
    } else {
      print('   ℹ️  Pasta inexistente: $path');
    }
  }

  // 3. Pasta de logs local do app
  final logsDir = Directory(p.join(Directory.current.path, 'logs'));
  if (logsDir.existsSync()) {
    print('\n➜  Limpando pasta de logs local...');
    try {
      logsDir.deleteSync(recursive: true);
      logsDir.createSync();
      print('   ✅ Logs excluídos.');
    } catch (e) {
      print('   ❌ Erro ao limpar pasta de logs: $e');
    }
  }

  print('\n🎉 Reset local concluído com sucesso!');
}
