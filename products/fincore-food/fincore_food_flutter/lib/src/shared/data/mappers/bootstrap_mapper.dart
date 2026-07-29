import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_food_client/fincore_food_client.dart';

class BootstrapMapper {
  static CoreEmpresa toCoreEmpresa(Empresa serverEmpresa) {
    return CoreEmpresa(
      id: serverEmpresa.id.toString(),
      razaoSocial: serverEmpresa.razaoSocial,
      nomeFantasia: serverEmpresa.nomeFantasia,
      documentoFiscal: serverEmpresa.documentoFiscal,
      email: serverEmpresa.email,
      telefone: serverEmpresa.telefone,
      status: _mapStatus(serverEmpresa.status),
      plano: _mapPlano(serverEmpresa.plano),
      timezone: serverEmpresa.timezone,
      locale: serverEmpresa.locale,
      currency: serverEmpresa.currency,
      country: serverEmpresa.country,
      createdFrom: serverEmpresa.createdFrom,
      segmento: serverEmpresa.segmento,
      version: serverEmpresa.syncVersion,
      metadata: SyncMetadata(
        version: serverEmpresa.syncVersion,
        createdAt: serverEmpresa.createdAt,
        updatedAt: serverEmpresa.updatedAt,
        createdBy: serverEmpresa.createdBy.toString(),
        updatedBy: serverEmpresa.updatedBy.toString(),
        deletedAt: serverEmpresa.deletedAt,
        syncStatus: SyncStatus.synced,
      ),
    );
  }

  static StatusEmpresa _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ativo': return StatusEmpresa.ativo;
      case 'suspenso': return StatusEmpresa.suspenso;
      case 'bloqueado': return StatusEmpresa.bloqueado;
      default: return StatusEmpresa.ativo;
    }
  }

  static PlanoEmpresa _mapPlano(String plano) {
    switch (plano.toLowerCase()) {
      case 'bronze': return PlanoEmpresa.bronze;
      case 'prata': return PlanoEmpresa.prata;
      case 'ouro': return PlanoEmpresa.ouro;
      default: return PlanoEmpresa.bronze;
    }
  }

  static CoreEmpresaConfiguracao toCoreConfiguracao(EmpresaConfiguracao serverConfig) {
    return CoreEmpresaConfiguracao(
      id: serverConfig.id.toString(),
      tenantId: serverConfig.tenantId,
      timezone: serverConfig.timezone,
      locale: serverConfig.locale,
      currency: serverConfig.currency,
      taxaServico: serverConfig.taxaServico,
      usarWhatsApp: serverConfig.usarWhatsApp,
      tema: serverConfig.tema,
      printerConfig: serverConfig.printerConfig,
      pixKey: serverConfig.pixKey,
      logoUrl: serverConfig.logoUrl,
      metadata: SyncMetadata(
        version: serverConfig.syncVersion,
        createdAt: serverConfig.createdAt,
        updatedAt: serverConfig.updatedAt,
        createdBy: serverConfig.createdBy.toString(),
        updatedBy: serverConfig.updatedBy.toString(),
        deletedAt: serverConfig.deletedAt,
        syncStatus: SyncStatus.synced,
      ),
    );
  }

  static CoreUsuario toCoreUsuario(Usuario serverUsuario) {
    return CoreUsuario(
      id: serverUsuario.id.toString(),
      email: serverUsuario.email,
      nome: serverUsuario.nome,
      criadoEm: serverUsuario.criadoEm,
      atualizadoEm: serverUsuario.atualizadoEm,
    );
  }

  static CoreMembroEmpresa toCoreMembroEmpresa(MembroEmpresa serverMembro) {
    return CoreMembroEmpresa(
      id: serverMembro.id.toString(),
      tenantId: serverMembro.tenantId.toString(),
      usuarioId: serverMembro.usuarioId.toString(),
      role: serverMembro.role,
      ativo: serverMembro.ativo,
      convidadoEm: serverMembro.convidadoEm,
      aceitoEm: serverMembro.aceitoEm,
      metadata: SyncMetadata(
        version: serverMembro.syncVersion,
        createdAt: serverMembro.createdAt,
        updatedAt: serverMembro.updatedAt,
        createdBy: serverMembro.createdBy.toString(),
        updatedBy: serverMembro.updatedBy.toString(),
        deletedAt: serverMembro.deletedAt,
        syncStatus: SyncStatus.synced,
      ),
    );
  }
}
