import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:drift/drift.dart';

class ServerpodSyncHandler {
  final Client client;

  ServerpodSyncHandler(this.client);

  /// Recebe a entrada do Outbox (SyncEngine) e despacha para a nuvem
  Future<bool> push(OutboxEntry entry) async {
    final pushEntry = SyncPushEntry(
      id: entry.id.toString(),
      entity: entry.entity,
      entityId: entry.entityId,
      action: entry.action,
      payload: entry.payload,
      createdAt: entry.createdAt,
    );

    try {
      final success = await client.sync.push([pushEntry]);
      return success;
    } catch (e) {
      print('Erro ao enviar push pro Serverpod: $e');
      return false;
    }
  }

  /// Chamado periodicamente ou por botão manual para trazer alterações remotas
  Future<void> pull(DateTime lastSyncAt, FincoreDatabase db) async {
    try {
      final pullPayload = await client.sync.pull(lastSyncAt);
      
      await db.transaction(() async {
        // Exemplo: Sincronizando Configurações Recebidas
        for (final remoteConfig in pullPayload.configuracoes) {
           await db.into(db.empresaConfiguracaoTable).insertOnConflictUpdate(
             EmpresaConfiguracaoTableCompanion.insert(
               id: remoteConfig.id.toString(),
               tenantId: remoteConfig.tenantId,
               timezone: Value(remoteConfig.timezone),
               locale: Value(remoteConfig.locale),
               currency: Value(remoteConfig.currency),
               taxaServico: Value(remoteConfig.taxaServico),
               usarWhatsApp: Value(remoteConfig.usarWhatsApp),
               tema: Value(remoteConfig.tema),
               syncVersion: Value(remoteConfig.syncVersion),
               createdAt: remoteConfig.createdAt,
               updatedAt: remoteConfig.updatedAt,
               createdBy: remoteConfig.createdBy.toString(),
               updatedBy: remoteConfig.updatedBy.toString(),
               deletedAt: Value(remoteConfig.deletedAt),
               deletedBy: const Value(null),
               syncStatus: SyncStatus.synced,
               lastSyncedAt: Value(remoteConfig.updatedAt),
               pixKey: Value(remoteConfig.pixKey),
               printerConfig: Value(remoteConfig.printerConfig),
               logoUrl: Value(remoteConfig.logoUrl),
             )
           );
        }
        
      });

      print('Pull executado com sucesso: ${pullPayload.configuracoes.length} configurações recebidas.');
    } catch (e) {
      print('Erro ao fazer pull do Serverpod: $e');
    }
  }
}
