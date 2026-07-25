import 'package:drift/native.dart';
import 'package:salgaderia/database/app_database.dart';
import 'package:salgaderia/data/repositories/grupo_preco_repository.dart';
import 'package:salgaderia/models/domain_models.dart';

void main() async {
  final db = AppDatabase(NativeDatabase.memory());
  final repo = GrupoPrecoRepository(db);
  try {
    print('Salvando grupo...');
    final id = await repo.salvar(
      nome: 'Teste',
      descricao: 'Desc',
      faixas: [
        FaixaInput(1, 10, 500),
      ],
    );
    print('Salvo com sucesso! ID: $id');
  } catch (e, stack) {
    print('Erro: $e');
    print(stack);
  } finally {
    await db.close();
  }
}
