import 'package:drift/drift.dart';
import 'fincore_database.dart';
import '../common/domain_primitives.dart';

class FincoreSeeds {
  static Future<void> populate(FincoreDatabase db) async {
    // Banco de dados inicia vazio e será sincronizado com o Serverpod.
    // O "Consumidor Final" padrão é criado e injetado pelo backend no momento da criação do Tenant.
  }
}
