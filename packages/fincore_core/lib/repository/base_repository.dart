import '../context/tenant_context.dart';

abstract class BaseRepository<T, ID> {
  final TenantContext context;

  BaseRepository(this.context);

  /// Helper que retorna o tenantId ativo verificado no contexto de sessão.
  /// Lança ContextStateError se não houver um tenant ativo.
  String get activeTenantId => context.tenantId;

  /// Busca um registro pelo seu ID único.
  Future<T?> findById(ID id);

  /// Retorna todos os registros filtrados pelo Tenant ativo.
  Future<List<T>> findAll();

  /// Salva ou atualiza um registro garantindo a vinculação com o Tenant ativo.
  Future<void> save(T entity);

  /// Exclui logicamente ou fisicamente um registro pelo ID.
  Future<void> delete(ID id);
}
