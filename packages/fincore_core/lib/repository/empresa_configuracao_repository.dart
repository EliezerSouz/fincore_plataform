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
        'modoDeliveryAtivo': entity.modoDeliveryAtivo,
        'modoComandasAtivo': entity.modoComandasAtivo,
        'clienteObrigatorioVenda': entity.clienteObrigatorioVenda,
        'atendimentoPadrao': entity.atendimentoPadrao,
        'mercadoPagoAtivo': entity.mercadoPagoAtivo,
        'openPixAtivo': entity.openPixAtivo,
        'asaasAtivo': entity.asaasAtivo,
        'ifoodAtivo': entity.ifoodAtivo,
        'margemSegurancaMinutos': entity.margemSegurancaMinutos,
        'taxaEntregaPorKm': entity.taxaEntregaPorKm,
        'valorPorKmCentavos': entity.valorPorKmCentavos,
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
    final entity = _mapToEntity(row);
    try {
      final raw = await db.customSelect(
        'SELECT modo_delivery_ativo, cliente_obrigatorio_venda, atendimento_padrao FROM empresa_configuracao_table WHERE id = ?',
        variables: [Variable.withString(id)],
      ).getSingleOrNull();
      if (raw != null) {
        final data = raw.data;
        return entity.copyWith(
          modoDeliveryAtivo: data['modo_delivery_ativo'] == 1 || data['modo_delivery_ativo'] == true,
          clienteObrigatorioVenda: data['cliente_obrigatorio_venda'] == 1 || data['cliente_obrigatorio_venda'] == true,
          atendimentoPadrao: data['atendimento_padrao'] as String? ?? 'Mesa/Balcão',
        );
      }
    } catch (_) {}
    return entity;
  }

  @override
  Future<List<CoreEmpresaConfiguracao>> findAll() async {
    final rows = await (db.select(db.empresaConfiguracaoTable)
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();
    final list = <CoreEmpresaConfiguracao>[];
    for (final row in rows) {
      var entity = _mapToEntity(row);
      try {
        final raw = await db.customSelect(
          'SELECT modo_delivery_ativo, cliente_obrigatorio_venda, atendimento_padrao FROM empresa_configuracao_table WHERE id = ?',
          variables: [Variable.withString(row.id)],
        ).getSingleOrNull();
        if (raw != null) {
          final data = raw.data;
          entity = entity.copyWith(
            modoDeliveryAtivo: data['modo_delivery_ativo'] == 1 || data['modo_delivery_ativo'] == true,
            clienteObrigatorioVenda: data['cliente_obrigatorio_venda'] == 1 || data['cliente_obrigatorio_venda'] == true,
            atendimentoPadrao: data['atendimento_padrao'] as String? ?? 'Mesa/Balcão',
          );
        }
      } catch (_) {}
      list.add(entity);
    }
    return list;
  }

  @override
  Future<void> saveLocal(CoreEmpresaConfiguracao entity) async {
    final now = DateTime.now().toUtc();
    try { await db.customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN modo_delivery_ativo INTEGER DEFAULT 1'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN cliente_obrigatorio_venda INTEGER DEFAULT 0'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE empresa_configuracao_table ADD COLUMN atendimento_padrao TEXT DEFAULT "Mesa/Balcão"'); } catch (_) {}

    await db.into(db.empresaConfiguracaoTable).insertOnConflictUpdate(
          EmpresaConfiguracaoTableCompanion.insert(
            id: entity.id,
            tenantId: entity.tenantId,
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
            mercadoPagoAtivo: Value(entity.mercadoPagoAtivo),
            openPixAtivo: Value(entity.openPixAtivo),
            asaasAtivo: Value(entity.asaasAtivo),
            ifoodAtivo: Value(entity.ifoodAtivo),
            margemSegurancaMinutos: Value(entity.margemSegurancaMinutos),
            taxaEntregaPorKm: Value(entity.taxaEntregaPorKm),
            valorPorKmCentavos: Value(entity.valorPorKmCentavos),
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

    try {
      await db.customStatement(
        'UPDATE empresa_configuracao_table SET modo_delivery_ativo = ?, modo_comandas_ativo = ?, cliente_obrigatorio_venda = ?, atendimento_padrao = ? WHERE id = ?',
        [entity.modoDeliveryAtivo ? 1 : 0, entity.modoComandasAtivo ? 1 : 0, entity.clienteObrigatorioVenda ? 1 : 0, entity.atendimentoPadrao, entity.id],
      );
    } catch (_) {}
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
      modoDeliveryAtivo: data.modoDeliveryAtivo,
      modoComandasAtivo: data.modoComandasAtivo,
      clienteObrigatorioVenda: data.clienteObrigatorioVenda,
      atendimentoPadrao: data.atendimentoPadrao,
      mercadoPagoAtivo: data.mercadoPagoAtivo,
      openPixAtivo: data.openPixAtivo,
      asaasAtivo: data.asaasAtivo,
      ifoodAtivo: data.ifoodAtivo,
      margemSegurancaMinutos: data.margemSegurancaMinutos ?? 10,
      taxaEntregaPorKm: data.taxaEntregaPorKm ?? false,
      valorPorKmCentavos: data.valorPorKmCentavos ?? 0,
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
