import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:salgaderia/database/app_database.dart';
import 'package:salgaderia/data/repositories/grupo_preco_repository.dart';
import 'package:salgaderia/models/domain_models.dart';

void main() {
  test('Salvar Grupo de Preço', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = GrupoPrecoRepository(db);
    try {
      final id = await repo.salvar(
        nome: 'Teste',
        descricao: 'Desc',
        faixas: [
          FaixaInput(1, 10, 500),
        ],
      );
      print('Salvo com sucesso! ID: $id');
      expect(id, isNotNull);
    } catch (e, stack) {
      print('Erro: $e');
      print(stack);
      fail(e.toString());
    } finally {
      await db.close();
    }
  });
}
