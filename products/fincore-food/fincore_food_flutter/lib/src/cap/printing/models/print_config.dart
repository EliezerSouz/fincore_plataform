import 'dart:convert';

/// Enumeração das vias (destinos) de impressão disponíveis.
enum PrintVia {
  cliente,
  cozinha,
  balcao,
  expedicao;

  String get displayName {
    switch (this) {
      case PrintVia.cliente:
        return 'Via do Cliente';
      case PrintVia.cozinha:
        return 'Via da Cozinha';
      case PrintVia.balcao:
        return 'Via do Balcão';
      case PrintVia.expedicao:
        return 'Via da Expedição';
    }
  }

  String get templateName {
    switch (this) {
      case PrintVia.cliente:
        return 'template_cliente';
      case PrintVia.cozinha:
        return 'template_cozinha';
      case PrintVia.balcao:
        return 'template_balcao';
      case PrintVia.expedicao:
        return 'template_expedicao';
    }
  }
}

/// Configuração de impressão extraída do banco de dados.
/// Imutável — reconstruída a cada operação para garantir consistência.
class PrintConfig {
  final Map<PrintVia, String?> printers;
  final Map<PrintVia, bool> autoprint;
  final Map<PrintVia, int> vias;
  final int larguraPapel;
  final bool cortarPapel;
  final bool abrirGaveta;
  final bool imprimirQRCode;
  final bool imprimirCopiaCola;
  final bool imprimirLogo;
  final bool imprimirRodape;
  final String mensagemRodape;
  final String? pixKey;
  final String? pixFavorecido;
  final String? pixBanco;
  final String pixTipo;
  final String pixCidade;
  final String? nomeEmpresaCupom;
  final String? telefoneEmpresa;
  final String? cnpjEmpresa;
  final String? enderecoEmpresa;
  final String? logoUrl;

  const PrintConfig({
    required this.printers,
    required this.autoprint,
    required this.vias,
    this.larguraPapel = 80,
    this.cortarPapel = true,
    this.abrirGaveta = false,
    this.imprimirQRCode = true,
    this.imprimirCopiaCola = true,
    this.imprimirLogo = false,
    this.imprimirRodape = true,
    this.mensagemRodape = 'Obrigado pela preferência!',
    this.pixKey,
    this.pixFavorecido,
    this.pixBanco,
    this.pixTipo = 'CPF',
    this.pixCidade = 'Sorocaba',
    this.nomeEmpresaCupom,
    this.telefoneEmpresa,
    this.cnpjEmpresa,
    this.enderecoEmpresa,
    this.logoUrl,
  });

  /// Cria PrintConfig a partir do CoreEmpresaConfiguracao.
  factory PrintConfig.fromEntity(dynamic config) {
    String pCidade = 'Sorocaba';
    try {
      pCidade = config.pixCidade ?? 'Sorocaba';
    } catch (_) {
      // pixCidade foi removida do banco de dados na migração de 14/08/2026.
    }

    String? rawPixKey = config.pixKey;
    String? parsedPixKey;
    String? parsedPixTipo;
    String? parsedPixFavorecido;
    String? parsedPixBanco;

    if (rawPixKey != null && rawPixKey.trim().isNotEmpty) {
      final trimmed = rawPixKey.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List && decoded.isNotEmpty) {
            final principal = decoded.firstWhere(
              (x) => x is Map<String, dynamic> && (x['isPrincipal'] == true),
              orElse: () => decoded.first,
            );
            if (principal is Map<String, dynamic>) {
              parsedPixKey = principal['chave']?.toString();
              parsedPixTipo = principal['tipo']?.toString();
              parsedPixFavorecido = principal['favorecido']?.toString();
              parsedPixBanco = principal['banco']?.toString();
            }
          } else if (decoded is Map<String, dynamic>) {
            parsedPixKey = decoded['chave']?.toString();
            parsedPixTipo = decoded['tipo']?.toString();
            parsedPixFavorecido = decoded['favorecido']?.toString();
            parsedPixBanco = decoded['banco']?.toString();
          }
        } catch (_) {
          parsedPixKey = rawPixKey;
        }
      } else {
        parsedPixKey = rawPixKey;
      }
    }

    String? nomeEmpresaCupom;
    try {
      nomeEmpresaCupom = config.nomeEmpresaCupom;
    } catch (_) {}

    String? telefoneEmpresa;
    try {
      telefoneEmpresa = config.telefoneEmpresa;
    } catch (_) {}

    String? cnpjEmpresa;
    try {
      cnpjEmpresa = config.cnpjEmpresa;
    } catch (_) {}

    String? enderecoEmpresa;
    try {
      enderecoEmpresa = config.enderecoEmpresa;
    } catch (_) {}

    return PrintConfig(
      printers: {
        PrintVia.cliente: config.printerCaixa,
        PrintVia.cozinha: config.printerCozinha,
        PrintVia.balcao: config.printerBalcao,
        PrintVia.expedicao: config.printerExpedicao,
      },
      autoprint: {
        PrintVia.cliente: config.autoPrintCaixa,
        PrintVia.cozinha: config.autoPrintCozinha,
        PrintVia.balcao: config.autoPrintBalcao,
        PrintVia.expedicao: config.autoPrintExpedicao,
      },
      vias: {
        PrintVia.cliente: config.viasCliente,
        PrintVia.cozinha: config.viasCozinha,
        PrintVia.balcao: config.viasBalcao,
        PrintVia.expedicao: config.viasExpedicao,
      },
      larguraPapel: config.larguraPapel,
      cortarPapel: config.cortarPapel,
      abrirGaveta: config.abrirGaveta,
      imprimirQRCode: config.imprimirQRCode,
      imprimirCopiaCola: config.imprimirCopiaCola,
      imprimirLogo: config.imprimirLogo,
      imprimirRodape: config.imprimirRodape,
      mensagemRodape: config.mensagemRodape,
      pixKey: parsedPixKey ?? config.pixKey,
      pixFavorecido: parsedPixFavorecido ?? config.pixFavorecido,
      pixBanco: parsedPixBanco ?? config.pixBanco,
      pixTipo: parsedPixTipo ?? config.pixTipo ?? 'CPF',
      pixCidade: pCidade,
      nomeEmpresaCupom: nomeEmpresaCupom,
      telefoneEmpresa: telefoneEmpresa,
      cnpjEmpresa: cnpjEmpresa,
      enderecoEmpresa: enderecoEmpresa,
      logoUrl: config.logoUrl,
    );
  }

  /// Retorna a lista de vias que devem ser impressas automaticamente.
  List<PrintVia> get viasAutoprint =>
      autoprint.entries.where((e) => e.value && isEnabled(e.key)).map((e) => e.key).toList();

  /// Retorna se esta via está ativada (tem impressora e número de cópias > 0).
  bool isEnabled(PrintVia via) => hasPrinter(via) && copias(via) > 0;

  /// Retorna se uma via tem impressora configurada.
  bool hasPrinter(PrintVia via) =>
      (printers[via] ?? '').isNotEmpty;

  /// Retorna o número de cópias para uma via (0 = desativada).
  int copias(PrintVia via) => vias[via] ?? 0;

  /// Retorna o caminho/nome da impressora para uma via.
  String? printer(PrintVia via) => printers[via];
}
