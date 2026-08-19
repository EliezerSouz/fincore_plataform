import 'dart:convert';
import 'package:drift/drift.dart';
import '../common/core_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../di/dependency_injection.dart';
import '../sync/outbox_service.dart';
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
    // Grava o avatarUrl contendo o JSON encodado da role e hash da senha
    final entry = UsuariosTableCompanion.insert(
      id: usuario.id,
      tenantId: Value(usuario.tenantId),
      authUserId: Value(usuario.authUserId),
      username: usuario.username,
      email: Value(usuario.email),
      nome: usuario.nome,
      avatarUrl: Value(usuario.avatarUrl),
      ativo: Value(usuario.ativo),
      criadoEm: usuario.criadoEm,
      atualizadoEm: usuario.atualizadoEm,
    );

    await db.into(db.usuariosTable).insertOnConflictUpdate(entry);
  }

  Future<void> saveWithSync(CoreUsuario usuario) async {
    await save(usuario);

    final outbox = DependencyInjection().get<OutboxService>();
    final now = DateTime.now().toUtc();
    
    // Configura metadados mínimos de sincronização
    final updatedMetadata = (usuario.metadata ?? SyncMetadata(
      version: 1,
      createdAt: now,
      updatedAt: now,
      createdBy: context.hasContext ? context.usuario.id : 'system',
      updatedBy: context.hasContext ? context.usuario.id : 'system',
      syncStatus: SyncStatus.pending,
    )).copyWith(updatedAt: now);

    final payload = {
      'id': usuario.id,
      'tenantId': usuario.tenantId,
      'authUserId': usuario.authUserId,
      'username': usuario.username,
      'email': usuario.email,
      'nome': usuario.nome,
      'avatarUrl': usuario.avatarUrl,
      'ativo': usuario.ativo,
      'criadoEm': usuario.criadoEm.toIso8601String(),
      'atualizadoEm': now.toIso8601String(),
      'syncVersion': updatedMetadata.version,
      'createdAt': updatedMetadata.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': updatedMetadata.createdBy,
      'updatedBy': updatedMetadata.updatedBy,
    };

    await outbox.enqueue(
      entity: 'usuarios',
      entityId: usuario.id,
      action: 'UPSERT',
      payload: payload,
      version: updatedMetadata.version,
    );
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.usuariosTable)..where((t) => t.id.equals(id))).go();
  }

  CoreUsuario _mapToDomain(UsuarioData data) {
    String? role = 'ADMIN';
    String? avatar = data.avatarUrl;
    
    // Se for JSON, extrai o cargo (role)
    if (avatar != null && avatar.startsWith('{')) {
      try {
        final map = jsonDecode(avatar);
        role = map['role'] as String?;
      } catch (_) {}
    } else if (avatar != null && avatar.startsWith('role:')) {
      // Fallback para mapeamentos antigos no banco
      role = avatar.substring(5);
      avatar = null;
    }

    return CoreUsuario(
      id: data.id,
      tenantId: data.tenantId,
      authUserId: data.authUserId,
      username: data.username,
      email: data.email,
      nome: data.nome,
      role: role,
      avatarUrl: data.avatarUrl, // Mantém o JSON original para que possa ser decodificado no formulário/login se necessário
      ativo: data.ativo,
      criadoEm: data.criadoEm,
      atualizadoEm: data.atualizadoEm,
    );
  }
}
