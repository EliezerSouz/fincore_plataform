import 'domain_primitives.dart';

enum PerfilUsuario {
  administrador,
  operadorCaixa,
  cozinha,
  entregador,
}

enum StatusEmpresa {
  ativo,
  suspenso,
  bloqueado,
}

enum PlanoEmpresa {
  bronze,
  prata,
  ouro,
}

class CoreUsuario {
  final String id;
  final String? tenantId;
  final String? authUserId;
  final String username;
  final String? email;
  final String nome;
  final String? role;
  final String? avatarUrl;
  final bool ativo;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  final SyncMetadata? metadata;

  const CoreUsuario({
    required this.id,
    this.tenantId,
    this.authUserId,
    this.username = 'admin',
    this.email,
    required this.nome,
    this.role = 'Administrador',
    this.avatarUrl,
    this.ativo = true,
    required this.criadoEm,
    required this.atualizadoEm,
    this.metadata,
  });

  CoreUsuario copyWith({
    String? id,
    String? tenantId,
    String? authUserId,
    String? username,
    String? email,
    String? nome,
    String? role,
    String? avatarUrl,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    SyncMetadata? metadata,
  }) {
    return CoreUsuario(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      authUserId: authUserId ?? this.authUserId,
      username: username ?? this.username,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CoreEmpresa {
  final String id;
  final String razaoSocial;
  final String nomeFantasia;
  final String documentoFiscal;
  final String email;
  final String telefone;
  final StatusEmpresa status;
  final PlanoEmpresa plano;
  final String timezone;
  final String locale;
  final String currency;
  final String country;
  final String createdFrom;
  final String? segmento;
  final int version;
  final SyncMetadata metadata;

  // Campos fiscais
  final String tipoPessoa;
  final String? inscricaoEstadual;
  final String? inscricaoMunicipal;
  final String? regimeTributario;

  // ─── Endereço Estruturado ──────────────────────────────────────────
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;

  const CoreEmpresa({
    required this.id,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.documentoFiscal,
    required this.email,
    required this.telefone,
    required this.status,
    required this.plano,
    required this.timezone,
    required this.locale,
    required this.currency,
    required this.country,
    required this.createdFrom,
    this.segmento,
    required this.version,
    required this.metadata,
    required this.tipoPessoa,
    this.inscricaoEstadual,
    this.inscricaoMunicipal,
    this.regimeTributario,
    this.cep,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
  });
}

class CoreEmpresaConfiguracao {
  final String id;
  final String tenantId;
  final String? printerConfig; // Legado
  final String? pixKey;
  final double taxaServico;
  final bool usarWhatsApp;
  final String? logoUrl;
  final String tema;
  final SyncMetadata metadata;

  // ─── CAP.PRINTING: Impressoras ────────────────────────────────────
  final String? printerCaixa;
  final String? printerCozinha;
  final String? printerBalcao;
  final String? printerExpedicao;

  // ─── CAP.PRINTING: Auto-print ─────────────────────────────────────
  final bool autoPrintCaixa;
  final bool autoPrintCozinha;
  final bool autoPrintBalcao;
  final bool autoPrintExpedicao;

  // ─── CAP.PRINTING: Vias ───────────────────────────────────────────
  final int viasCliente;
  final int viasCozinha;
  final int viasBalcao;
  final int viasExpedicao;

  // ─── CAP.PRINTING: Papel e Hardware ───────────────────────────────
  final int larguraPapel;
  final bool cortarPapel;
  final bool abrirGaveta;

  // ─── CAP.PRINTING: Layout ─────────────────────────────────────────
  final bool imprimirQRCode;
  final bool imprimirCopiaCola;
  final bool imprimirLogo;
  final bool imprimirRodape;
  final String mensagemRodape;

  // ─── CAP.PRINTING: PIX Expandido ──────────────────────────────────
  final String? pixFavorecido;
  final String? pixBanco;
  final String pixTipo;
  // ─── PARAMETRIZAÇÃO DE VENDAS & PDV ────────────────────────────────
  final bool modoDeliveryAtivo;
  final bool modoComandasAtivo;
  final bool clienteObrigatorioVenda;
  final String atendimentoPadrao;
  // ─── CONECTORES DE INTEGRAÇÃO ──────────────────────────────────────
  final bool mercadoPagoAtivo;
  final bool openPixAtivo;
  final bool asaasAtivo;
  final bool ifoodAtivo;
  final int margemSegurancaMinutos;
  final bool taxaEntregaPorKm;
  final int valorPorKmCentavos;

  const CoreEmpresaConfiguracao({
    required this.id,
    required this.tenantId,
    this.printerConfig,
    this.pixKey,
    required this.taxaServico,
    required this.usarWhatsApp,
    this.logoUrl,
    required this.tema,
    required this.metadata,
    // CAP.PRINTING defaults
    this.printerCaixa,
    this.printerCozinha,
    this.printerBalcao,
    this.printerExpedicao,
    this.autoPrintCaixa = true,
    this.autoPrintCozinha = true,
    this.autoPrintBalcao = false,
    this.autoPrintExpedicao = false,
    this.viasCliente = 1,
    this.viasCozinha = 1,
    this.viasBalcao = 0,
    this.viasExpedicao = 0,
    this.larguraPapel = 80,
    this.cortarPapel = true,
    this.abrirGaveta = false,
    this.imprimirQRCode = true,
    this.imprimirCopiaCola = true,
    this.imprimirLogo = false,
    this.imprimirRodape = true,
    this.mensagemRodape = 'Obrigado pela preferência!',
    this.pixFavorecido,
    this.pixBanco,
    this.pixTipo = 'CPF',
    // Parametrização PDV defaults
    this.modoDeliveryAtivo = true,
    this.modoComandasAtivo = false,
    this.clienteObrigatorioVenda = false,
    this.atendimentoPadrao = 'Delivery',
    // Conectores defaults
    this.mercadoPagoAtivo = false,
    this.openPixAtivo = false,
    this.asaasAtivo = false,
    this.ifoodAtivo = false,
    this.margemSegurancaMinutos = 10,
    this.taxaEntregaPorKm = false,
    this.valorPorKmCentavos = 0,
  });

  CoreEmpresaConfiguracao copyWith({
    String? id,
    String? tenantId,
    String? printerConfig,
    String? pixKey,
    double? taxaServico,
    bool? usarWhatsApp,
    String? logoUrl,
    String? tema,
    SyncMetadata? metadata,
    String? printerCaixa,
    String? printerCozinha,
    String? printerBalcao,
    String? printerExpedicao,
    bool? autoPrintCaixa,
    bool? autoPrintCozinha,
    bool? autoPrintBalcao,
    bool? autoPrintExpedicao,
    int? viasCliente,
    int? viasCozinha,
    int? viasBalcao,
    int? viasExpedicao,
    int? larguraPapel,
    bool? cortarPapel,
    bool? abrirGaveta,
    bool? imprimirQRCode,
    bool? imprimirCopiaCola,
    bool? imprimirLogo,
    bool? imprimirRodape,
    String? mensagemRodape,
    String? pixFavorecido,
    String? pixBanco,
    String? pixTipo,
    bool? modoDeliveryAtivo,
    bool? modoComandasAtivo,
    bool? clienteObrigatorioVenda,
    String? atendimentoPadrao,
    bool? mercadoPagoAtivo,
    bool? openPixAtivo,
    bool? asaasAtivo,
    bool? ifoodAtivo,
    int? margemSegurancaMinutos,
    bool? taxaEntregaPorKm,
    int? valorPorKmCentavos,
  }) {
    return CoreEmpresaConfiguracao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      printerConfig: printerConfig ?? this.printerConfig,
      pixKey: pixKey ?? this.pixKey,
      taxaServico: taxaServico ?? this.taxaServico,
      usarWhatsApp: usarWhatsApp ?? this.usarWhatsApp,
      logoUrl: logoUrl ?? this.logoUrl,
      tema: tema ?? this.tema,
      metadata: metadata ?? this.metadata,
      printerCaixa: printerCaixa ?? this.printerCaixa,
      printerCozinha: printerCozinha ?? this.printerCozinha,
      printerBalcao: printerBalcao ?? this.printerBalcao,
      printerExpedicao: printerExpedicao ?? this.printerExpedicao,
      autoPrintCaixa: autoPrintCaixa ?? this.autoPrintCaixa,
      autoPrintCozinha: autoPrintCozinha ?? this.autoPrintCozinha,
      autoPrintBalcao: autoPrintBalcao ?? this.autoPrintBalcao,
      autoPrintExpedicao: autoPrintExpedicao ?? this.autoPrintExpedicao,
      viasCliente: viasCliente ?? this.viasCliente,
      viasCozinha: viasCozinha ?? this.viasCozinha,
      viasBalcao: viasBalcao ?? this.viasBalcao,
      viasExpedicao: viasExpedicao ?? this.viasExpedicao,
      larguraPapel: larguraPapel ?? this.larguraPapel,
      cortarPapel: cortarPapel ?? this.cortarPapel,
      abrirGaveta: abrirGaveta ?? this.abrirGaveta,
      imprimirQRCode: imprimirQRCode ?? this.imprimirQRCode,
      imprimirCopiaCola: imprimirCopiaCola ?? this.imprimirCopiaCola,
      imprimirLogo: imprimirLogo ?? this.imprimirLogo,
      imprimirRodape: imprimirRodape ?? this.imprimirRodape,
      mensagemRodape: mensagemRodape ?? this.mensagemRodape,
      pixFavorecido: pixFavorecido ?? this.pixFavorecido,
      pixBanco: pixBanco ?? this.pixBanco,
      pixTipo: pixTipo ?? this.pixTipo,
      modoDeliveryAtivo: modoDeliveryAtivo ?? this.modoDeliveryAtivo,
      modoComandasAtivo: modoComandasAtivo ?? this.modoComandasAtivo,
      clienteObrigatorioVenda: clienteObrigatorioVenda ?? this.clienteObrigatorioVenda,
      atendimentoPadrao: atendimentoPadrao ?? this.atendimentoPadrao,
      mercadoPagoAtivo: mercadoPagoAtivo ?? this.mercadoPagoAtivo,
      openPixAtivo: openPixAtivo ?? this.openPixAtivo,
      asaasAtivo: asaasAtivo ?? this.asaasAtivo,
      ifoodAtivo: ifoodAtivo ?? this.ifoodAtivo,
      margemSegurancaMinutos: margemSegurancaMinutos ?? this.margemSegurancaMinutos,
      taxaEntregaPorKm: taxaEntregaPorKm ?? this.taxaEntregaPorKm,
      valorPorKmCentavos: valorPorKmCentavos ?? this.valorPorKmCentavos,
    );
  }
}

class CoreMembroEmpresa {
  final String id;
  final String tenantId;
  final String usuarioId;
  final String role;
  final bool ativo;
  final DateTime convidadoEm;
  final DateTime? aceitoEm;
  final SyncMetadata metadata;

  const CoreMembroEmpresa({
    required this.id,
    required this.tenantId,
    required this.usuarioId,
    required this.role,
    required this.ativo,
    required this.convidadoEm,
    this.aceitoEm,
    required this.metadata,
  });
}

/// Convite de usuário para ingressar em uma empresa.
///
/// Criado exclusivamente pelo backend/admin. O cliente apenas
/// lê (Pull-only) e pode aceitar/rejeitar o convite por fora do app.
///
/// Máquina de estados:
/// ```
/// PENDENTE → ACEITO | CANCELADO | EXPIRADO
/// ```
class CoreEmpresaConvite {
  final String id;
  final String tenantId;
  final String email;

  /// Papel que o usuário receberá ao aceitar: ADMIN | GESTOR | OPERADOR | VIEWER
  final String role;

  /// PENDENTE | ACEITO | CANCELADO | EXPIRADO
  final String status;

  final DateTime expiracaoEm;
  final SyncMetadata metadata;

  const CoreEmpresaConvite({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.status,
    required this.expiracaoEm,
    required this.metadata,
  });

  bool get isPendente => status == 'PENDENTE';
  bool get isAceito => status == 'ACEITO';
  bool get isExpirado =>
      status == 'EXPIRADO' || DateTime.now().isAfter(expiracaoEm);

  CoreEmpresaConvite copyWith({
    String? status,
    SyncMetadata? metadata,
  }) {
    return CoreEmpresaConvite(
      id: id,
      tenantId: tenantId,
      email: email,
      role: role,
      status: status ?? this.status,
      expiracaoEm: expiracaoEm,
      metadata: metadata ?? this.metadata,
    );
  }
}
