import 'package:drift/drift.dart';
import '../common/core_models.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'base_repository.dart';

class UsuarioRepository extends BaseRepository<CoreUsuario, String> {
  final FincoreDatabase db;

  UsuarioRepository({required this.db, required TenantContext context})
      : super(context);

  @override
  Future<CoreUsuario?> findById(String id) async {
    final row = await (db.select(db.usuariosTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<CoreUsuario>> findAll() async {
    final rows = await db.select(db.usuariosTable).get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> save(CoreUsuario usuario) async {
    final entry = UsuariosTableCompanion.insert(
      id: usuario.id,
      email: usuario.email,
      nome: usuario.nome,
      avatarUrl: Value(usuario.avatarUrl),
      criadoEm: usuario.criadoEm,
      atualizadoEm: usuario.atualizadoEm,
    );

    await db.into(db.usuariosTable).insertOnConflictUpdate(entry);
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.usuariosTable)..where((t) => t.id.equals(id))).go();
  }

  CoreUsuario _mapToDomain(UsuarioData data) {
    return CoreUsuario(
      id: data.id,
      email: data.email,
      nome: data.nome,
      avatarUrl: data.avatarUrl,
      criadoEm: data.criadoEm,
      atualizadoEm: data.atualizadoEm,
    );
  }
}
