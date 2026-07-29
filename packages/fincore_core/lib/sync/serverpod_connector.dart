import '../context/tenant_context.dart';
import '../database/fincore_database.dart';

abstract class CoreServerConnector {
  final TenantContext context;
  final String hostUrl;

  CoreServerConnector({required this.context, required this.hostUrl});

  /// Injeta os cabeçalhos de autenticação e tenantId ativo nas chamadas de rede.
  Map<String, String> get defaultHeaders {
    if (!context.hasContext) {
      return {};
    }
    return {
      'X-Tenant-ID': context.tenantId,
      'X-User-ID': context.usuario.id,
      'Authorization': 'Bearer ${context.usuario.id}',
    };
  }

  /// Despacha uma transação do Outbox para o servidor remoto.
  Future<bool> sendOutboxEntry(OutboxEntry entry);
}
