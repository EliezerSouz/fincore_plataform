import 'package:fincore_food_server/src/utils/custom_migration_runner.dart';

Future<void> main() async {
  print('🔄 Aplicando migrações no banco do Supabase...');
  await CustomMigrationRunner.run();
  print('✅ Processo finalizado com sucesso!');
}
