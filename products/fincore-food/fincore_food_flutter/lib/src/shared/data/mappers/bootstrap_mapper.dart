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
      tipoPessoa: serverEmpresa.tipoPessoa,
      inscricaoEstadual: serverEmpresa.inscricaoEstadual,
      inscricaoMunicipal: serverEmpresa.inscricaoMunicipal,
      regimeTributario: serverEmpresa.regimeTributario,
      cep: serverEmpresa.cep,
      logradouro: serverEmpresa.logradouro,
      numero: serverEmpresa.numero,
      complemento: serverEmpresa.complemento,
      bairro: serverEmpresa.bairro,
      cidade: serverEmpresa.cidade,
      estado: serverEmpresa.estado,
      metadata: SyncMetadata(
        version: serverEmpresa.syncVersion,
        createdAt: serverEmpresa.createdAt,
        updatedAt: serverEmpresa.updatedAt,
        createdBy: serverEmpresa.createdBy?.toString() ?? 'system',
        updatedBy: serverEmpresa.updatedBy?.toString() ?? 'system',
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
      taxaServico: serverConfig.taxaServico,
      usarWhatsApp: serverConfig.usarWhatsApp,
      tema: serverConfig.tema,
      printerConfig: serverConfig.printerConfig,
      pixKey: serverConfig.pixKey,
      logoUrl: serverConfig.logoUrl,
      // CAP.PRINTING mappings
      printerCaixa: serverConfig.printerCaixa,
      printerCozinha: serverConfig.printerCozinha,
      printerBalcao: serverConfig.printerBalcao,
      printerExpedicao: serverConfig.printerExpedicao,
      autoPrintCaixa: serverConfig.autoPrintCaixa ?? true,
      autoPrintCozinha: serverConfig.autoPrintCozinha ?? true,
      autoPrintBalcao: serverConfig.autoPrintBalcao ?? false,
      autoPrintExpedicao: serverConfig.autoPrintExpedicao ?? false,
      viasCliente: serverConfig.viasCliente ?? 1,
      viasCozinha: serverConfig.viasCozinha ?? 1,
      viasBalcao: serverConfig.viasBalcao ?? 0,
      viasExpedicao: serverConfig.viasExpedicao ?? 0,
      larguraPapel: serverConfig.larguraPapel ?? 80,
      cortarPapel: serverConfig.cortarPapel ?? true,
      abrirGaveta: serverConfig.abrirGaveta ?? false,
      imprimirQRCode: serverConfig.imprimirQRCode ?? true,
      imprimirCopiaCola: serverConfig.imprimirCopiaCola ?? true,
      imprimirLogo: serverConfig.imprimirLogo ?? false,
      imprimirRodape: serverConfig.imprimirRodape ?? true,
      mensagemRodape: serverConfig.mensagemRodape ?? 'Obrigado pela preferência!',
      pixFavorecido: serverConfig.pixFavorecido,
      pixBanco: serverConfig.pixBanco,
      pixTipo: serverConfig.pixTipo ?? 'CPF',
      modoDeliveryAtivo: serverConfig.modoDeliveryAtivo ?? true,
      modoComandasAtivo: false,
      clienteObrigatorioVenda: serverConfig.clienteObrigatorioVenda ?? false,
      atendimentoPadrao: serverConfig.atendimentoPadrao ?? 'Mesa/Balcão',
      mercadoPagoAtivo: serverConfig.mercadoPagoAtivo ?? false,
      openPixAtivo: serverConfig.openPixAtivo ?? false,
      asaasAtivo: serverConfig.asaasAtivo ?? false,
      ifoodAtivo: serverConfig.ifoodAtivo ?? false,
      margemSegurancaMinutos: serverConfig.margemSegurancaMinutos ?? 10,
      taxaEntregaPorKm: serverConfig.taxaEntregaPorKm ?? false,
      valorPorKmCentavos: serverConfig.valorPorKmCentavos ?? 0,
      metadata: SyncMetadata(
        version: serverConfig.syncVersion,
        createdAt: serverConfig.createdAt,
        updatedAt: serverConfig.updatedAt,
        createdBy: serverConfig.createdBy?.toString() ?? 'system',
        updatedBy: serverConfig.updatedBy?.toString() ?? 'system',
        deletedAt: serverConfig.deletedAt,
        syncStatus: SyncStatus.synced,
      ),
    );
  }

  static CoreUsuario toCoreUsuario(Usuario serverUsuario) {
    return CoreUsuario(
      id: serverUsuario.id.toString(),
      tenantId: serverUsuario.tenantId,
      authUserId: serverUsuario.authUserId,
      username: serverUsuario.username,
      email: serverUsuario.email,
      nome: serverUsuario.nome,
      avatarUrl: serverUsuario.avatarUrl,
      ativo: serverUsuario.ativo,
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
        createdBy: serverMembro.createdBy?.toString() ?? 'system',
        updatedBy: serverMembro.updatedBy?.toString() ?? 'system',
        deletedAt: serverMembro.deletedAt,
        syncStatus: SyncStatus.synced,
      ),
    );
  }
}
