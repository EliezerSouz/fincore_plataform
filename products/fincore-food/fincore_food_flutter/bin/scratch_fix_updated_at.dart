import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;

void main() async {
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');
  
  print('Abrindo banco local: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('Erro: Banco local não encontrado.');
    return;
  }
  
  final db = FincoreDatabase(NativeDatabase(File(dbPath)));
  
  try {
    print('Corrigindo updated_at da ordem ff3e0d6e-dfd1-42b6-b0a1-d079c203bc26...');
    
    // Obter timestamp atual em segundos (inteiro)
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    
    await db.customStatement(
      "UPDATE ordens_preparo_table SET updated_at = ? WHERE id = ?",
      [nowSeconds, 'ff3e0d6e-dfd1-42b6-b0a1-d079c203bc26']
    );
    
    print('Ordem ff3e0d6e-dfd1-42b6-b0a1-d079c203bc26 corrigida com sucesso! updated_at setado como $nowSeconds.');
  } catch (e) {
    print('Erro ao corrigir updated_at: $e');
  } finally {
    await db.close();
  }
}
