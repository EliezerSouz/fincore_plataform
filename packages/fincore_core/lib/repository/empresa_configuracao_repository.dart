import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/fincore_database.dart';
import '../context/tenant_context.dart';
import '../common/core_models.dart';
import '../common/domain_primitives.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class EmpresaConfiguracaoRepository
    extends SyncableRepository<CoreEmpresaConfiguracao> {

  EmpresaConfiguracaoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  Future<CoreEmpresaConfiguracao> save(CoreEmpresaConfiguracao entity) => saveWithSync(entity);

  @override
  String get entityName => 'empresa_configuracao';

  @override
  String extractId(CoreEmpresaConfiguracao entity) => entity.id;

  @override
  int extractVersion(CoreEmpresaConfiguracao entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(CoreEmpresaConfiguracao entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'timezone': entity.timezone,
        'locale': entity.locale,
        'currency': entity.currency,
        'taxaServico': entity.taxaServico,
        'usarWhatsApp': entity.usarWhatsApp,
        'tema': entity.tema,
        'pixKey': entity.pixKey,
        'printerConfig': entity.printerConfig,
        'logoUrl': entity.logoUrl,
        // CAP.PRINTING
        'printerCaixa': entity.printerCaixa,
        'printerCozinha': entity.printerCozinha,
        'printerBalcao': entity.printerBalcao,
        'printerExpedicao': entity.printerExpedicao,
        'autoPrintCaixa': entity.autoPrintCaixa,
        'autoPrintCozinha': entity.autoPrintCozinha,
        'autoPrintBalcao': entity.autoPrintBalcao,
        'autoPrintExpedicao': entity.autoPrintExpedicao,
        'viasCliente': entity.viasCliente,
        'viasCozinha': entity.viasCozinha,
        'viasBalcao': entity.viasBalcao,
        'viasExpedicao': entity.viasExpedicao,
        'larguraPapel': entity.larguraPapel,
        'cortarPapel': entity.cortarPapel,
        'abrirGaveta': entity.abrirGaveta,
        'imprimirQRCode': entity.imprimirQRCode,
        'imprimirCopiaCola': entity.imprimirCopiaCola,
        'imprimirLogo': entity.imprimirLogo,
        'imprimirRodape': entity.imprimirRodape,
        'mensagemRodape': entity.mensagemRodape,
        'pixFavorecido': entity.pixFavorecido,
        'pixBanco': entity.pixBanco,
        'pixTipo': entity.pixTipo,
        'pixCidade': entity.pixCidade,
        'nomeEmpresaCupom': entity.nomeEmpresaCupom,
        'telefoneEmpresa': entity.telefoneEmpresa,
        'cnpjEmpresa': entity.cnpjEmpresa,
        'enderecoEmpresa': entity.enderecoEmpresa,
        // Sync metadata
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<CoreEmpresaConfiguracao?> findById(String id) async {
    final row = await (db.select(db.empresaConfiguracaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToEntity(row);
  }

  @override
  Future<List<CoreEmpresaConfiguracao>> findAll() async {
    final rows = await (db.select(db.empresaConfiguracaoTable)
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> saveLocal(CoreEmpresaConfiguracao entity) async {
    final now = DateTime.now().toUtc();
    await db.into(db.empresaConfiguracaoTable).insertOnConflictUpdate(
          EmpresaConfiguracaoTableCompanion.insert(
            id: entity.id,
            tenantId: entity.tenantId,
            timezone: Value(entity.timezone),
            locale: Value(entity.locale),
            currency: Value(entity.currency),
            printerConfig: Value(entity.printerConfig),
            pixKey: Value(entity.pixKey),
            taxaServico: Value(entity.taxaServico),
            usarWhatsApp: Value(entity.usarWhatsApp),
            logoUrl: Value(entity.logoUrl),
            tema: Value(entity.tema),
            // CAP.PRINTING
            printerCaixa: Value(entity.printerCaixa),
            printerCozinha: Value(entity.printerCozinha),
            printerBalcao: Value(entity.printerBalcao),
            printerExpedicao: Value(entity.printerExpedicao),
            autoPrintCaixa: Value(entity.autoPrintCaixa),
            autoPrintCozinha: Value(entity.autoPrintCozinha),
            autoPrintBalcao: Value(entity.autoPrintBalcao),
            autoPrintExpedicao: Value(entity.autoPrintExpedicao),
            viasCliente: Value(entity.viasCliente),
            viasCozinha: Value(entity.viasCozinha),
            viasBalcao: Value(entity.viasBalcao),
            viasExpedicao: Value(entity.viasExpedicao),
            larguraPapel: Value(entity.larguraPapel),
            cortarPapel: Value(entity.cortarPapel),
            abrirGaveta: Value(entity.abrirGaveta),
            imprimirQRCode: Value(entity.imprimirQRCode),
            imprimirCopiaCola: Value(entity.imprimirCopiaCola),
            imprimirLogo: Value(entity.imprimirLogo),
            imprimirRodape: Value(entity.imprimirRodape),
            mensagemRodape: Value(entity.mensagemRodape),
            pixFavorecido: Value(entity.pixFavorecido),
            pixBanco: Value(entity.pixBanco),
            pixTipo: Value(entity.pixTipo),
            pixCidade: Value(entity.pixCidade),
            nomeEmpresaCupom: Value(entity.nomeEmpresaCupom),
            telefoneEmpresa: Value(entity.telefoneEmpresa),
            cnpjEmpresa: Value(entity.cnpjEmpresa),
            enderecoEmpresa: Value(entity.enderecoEmpresa),
            // Sync
            syncVersion: Value(entity.metadata.version + 1),
            createdAt: entity.metadata.createdAt,
            updatedAt: now,
            createdBy: entity.metadata.createdBy,
            updatedBy: entity.metadata.updatedBy,
            syncStatus: entity.metadata.syncStatus,
            lastSyncedAt: Value(entity.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, CoreEmpresaConfiguracao entity) async {
    await (db.delete(db.empresaConfiguracaoTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  CoreEmpresaConfiguracao _mapToEntity(EmpresaConfiguracaoData data) {
    return CoreEmpresaConfiguracao(
      id: data.id,
      tenantId: data.tenantId,
      timezone: data.timezone,
      locale: data.locale,
      currency: data.currency,
      taxaServico: data.taxaServico,
      usarWhatsApp: data.usarWhatsApp,
      tema: data.tema,
      pixKey: data.pixKey,
      printerConfig: data.printerConfig,
      logoUrl: data.logoUrl,
      // CAP.PRINTING
      printerCaixa: data.printerCaixa,
      printerCozinha: data.printerCozinha,
      printerBalcao: data.printerBalcao,
      printerExpedicao: data.printerExpedicao,
      autoPrintCaixa: data.autoPrintCaixa,
      autoPrintCozinha: data.autoPrintCozinha,
      autoPrintBalcao: data.autoPrintBalcao,
      autoPrintExpedicao: data.autoPrintExpedicao,
      viasCliente: data.viasCliente,
      viasCozinha: data.viasCozinha,
      viasBalcao: data.viasBalcao,
      viasExpedicao: data.viasExpedicao,
      larguraPapel: data.larguraPapel,
      cortarPapel: data.cortarPapel,
      abrirGaveta: data.abrirGaveta,
      imprimirQRCode: data.imprimirQRCode,
      imprimirCopiaCola: data.imprimirCopiaCola,
      imprimirLogo: data.imprimirLogo,
      imprimirRodape: data.imprimirRodape,
      mensagemRodape: data.mensagemRodape,
      pixFavorecido: data.pixFavorecido,
      pixBanco: data.pixBanco,
      pixTipo: data.pixTipo,
      pixCidade: data.pixCidade,
      nomeEmpresaCupom: data.nomeEmpresaCupom,
      telefoneEmpresa: data.telefoneEmpresa,
      cnpjEmpresa: data.cnpjEmpresa,
      enderecoEmpresa: data.enderecoEmpresa,
      metadata: SyncMetadata(
        version: data.syncVersion,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        createdBy: data.createdBy,
        updatedBy: data.updatedBy,
        deletedAt: data.deletedAt,
        syncStatus: data.syncStatus,
        lastSyncedAt: data.lastSyncedAt,
      ),
    );
  }
}
