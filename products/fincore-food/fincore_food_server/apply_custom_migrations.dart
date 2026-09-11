import 'package:fincore_food_server/src/utils/custom_migration_runner.dart';

void main() async {
  print('Iniciando CustomMigrationRunner a partir do script utilitário...');
  await CustomMigrationRunner.run();
  print('Pronto!');
}
