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
  final String email;
  final String nome;
  final String? avatarUrl;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const CoreUsuario({
    required this.id,
    required this.email,
    required this.nome,
    this.avatarUrl,
    required this.criadoEm,
    required this.atualizadoEm,
  });
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
  });
}

class CoreEmpresaConfiguracao {
  final String id;
  final String tenantId;
  final String timezone;
  final String locale;
  final String currency;
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
  final String pixCidade;

  // ─── CAP.PRINTING: Dados do Cupom ─────────────────────────────────
  final String? nomeEmpresaCupom;
  final String? telefoneEmpresa;
  final String? cnpjEmpresa;
  final String? enderecoEmpresa;

  const CoreEmpresaConfiguracao({
    required this.id,
    required this.tenantId,
    required this.timezone,
    required this.locale,
    required this.currency,
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
    this.pixCidade = 'Sorocaba',
    this.nomeEmpresaCupom,
    this.telefoneEmpresa,
    this.cnpjEmpresa,
    this.enderecoEmpresa,
  });
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
