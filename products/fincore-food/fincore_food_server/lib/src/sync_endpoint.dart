import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';

class SyncEndpoint extends Endpoint {
  /// Recebe uma lista de alterações geradas no FincoreCore (Outbox)
  /// e as aplica no banco Postgres usando Last-Write-Wins
  Future<bool> push(Session session, List<SyncPushEntry> changes) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) throw Exception('Usuário não autenticado');

    final tenantId = session.context['tenantId'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Sincronização abortada: Usuário sem Tenant');
    }

    // Processar cada mudança da lista
    for (final change in changes) {
      try {
        final payloadMap = jsonDecode(change.payload) as Map<String, dynamic>;
        
        // Mapear e atualizar o banco para cada "change.entity"
        switch (change.entity) {
          case 'empresa_configuracao':
            await _syncConfiguracao(session, tenantId, payloadMap);
            break;
          // Adicionar case para produtos, clientes, etc.
          default:
            session.log('Entidade desconhecida no sync: ${change.entity}', level: LogLevel.warning);
        }
      } catch (e) {
        session.log('Erro ao processar sync da entidade ${change.entity}: $e', level: LogLevel.error);
        return false;
      }
    }

    return true; // Push aplicado com sucesso
  }

  /// Retorna as modificações que ocorreram no servidor desde a última sincronização local
  Future<SyncPullPayload> pull(Session session, DateTime lastSyncAt) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) throw Exception('Usuário não autenticado');

    final tenantId = session.context['tenantId'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Sincronização abortada: Usuário sem Tenant');
    }

    // Buscar todas as configurações, membros, produtos, etc atualizados recentemente
    final configuracoes = await EmpresaConfiguracao.db.find(
      session,
      where: (t) => t.tenantId.equals(tenantId) & (t.updatedAt > lastSyncAt),
    );

    final membros = await MembroEmpresa.db.find(
      session,
      where: (t) => t.tenantId.equals(UuidValue.fromString(tenantId)) & (t.updatedAt > lastSyncAt),
    );

    // O SyncPullPayload encapsula todos os registros que precisam ser atualizados no client
    return SyncPullPayload(
      timestamp: DateTime.now().toUtc(),
      produtos: [],
      clientes: [],
      configuracoes: configuracoes,
      membros: membros,
    );
  }

  Future<void> _syncConfiguracao(Session session, String tenantId, Map<String, dynamic> payload) async {
    // Busca a configuração atual
    var config = await EmpresaConfiguracao.db.findFirstRow(
      session,
      where: (t) => t.tenantId.equals(tenantId)
    );

    if (config == null) return; // Se não existir, ignore o push ou crie (dependendo da lógica)

    // O FincoreCore envia metadados completos
    final syncVersionLocal = payload['syncVersion'] as int? ?? 1;

    // Conflito simplificado: O maior syncVersion vence
    if (syncVersionLocal >= config.syncVersion) {
      config.timezone = payload['timezone'] ?? config.timezone;
      config.locale = payload['locale'] ?? config.locale;
      config.currency = payload['currency'] ?? config.currency;
      config.taxaServico = (payload['taxaServico'] as num?)?.toDouble() ?? config.taxaServico;
      config.usarWhatsApp = payload['usarWhatsApp'] == 1 || payload['usarWhatsApp'] == true;
      config.tema = payload['tema'] ?? config.tema;
      config.syncVersion = syncVersionLocal;
      config.updatedAt = DateTime.now().toUtc();
      
      await EmpresaConfiguracao.db.updateRow(session, config);
    }
  }
}
