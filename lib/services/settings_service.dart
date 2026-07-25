import '../database/app_database.dart';
import 'package:drift/drift.dart';

class AppSettings {
  final String empresa, telefone, endereco, rodape, impressora, horizonteOperacional;
  final int taxaPadrao, largura;

  // Novos campos do RFC da Empresa e PIX
  final String razaoSocial;
  final String whatsapp;
  final String instagram;
  final String logoPath;
  final bool habilitarPix;
  final String pixTipoChave;
  final String pixChave;
  final String pixFavorecido;
  final String pixBanco;
  final String pixCidade;
  final String pixMensagem;
  final bool pixImprimirQrCode;
  final bool pixImprimirCopiaCola;
  final bool pixGerarQrCodeAuto;

  const AppSettings({
    this.empresa = 'Minha Salgaderia',
    this.telefone = '',
    this.endereco = '',
    this.rodape = 'Obrigado pela preferência!',
    this.impressora = '',
    this.taxaPadrao = 0,
    this.largura = 80,
    this.horizonteOperacional = 'Hoje + Amanhã',
    this.razaoSocial = '',
    this.whatsapp = '',
    this.instagram = '',
    this.logoPath = '',
    this.habilitarPix = false,
    this.pixTipoChave = 'CPF',
    this.pixChave = '',
    this.pixFavorecido = '',
    this.pixBanco = '',
    this.pixCidade = 'Sorocaba',
    this.pixMensagem = 'Envie o comprovante após o pagamento',
    this.pixImprimirQrCode = true,
    this.pixImprimirCopiaCola = true,
    this.pixGerarQrCodeAuto = true,
  });

  AppSettings copyWith({
    String? empresa,
    String? telefone,
    String? endereco,
    String? rodape,
    String? impressora,
    String? horizonteOperacional,
    int? taxaPadrao,
    int? largura,
    String? razaoSocial,
    String? whatsapp,
    String? instagram,
    String? logoPath,
    bool? habilitarPix,
    String? pixTipoChave,
    String? pixChave,
    String? pixFavorecido,
    String? pixBanco,
    String? pixCidade,
    String? pixMensagem,
    bool? pixImprimirQrCode,
    bool? pixImprimirCopiaCola,
    bool? pixGerarQrCodeAuto,
  }) {
    return AppSettings(
      empresa: empresa ?? this.empresa,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      rodape: rodape ?? this.rodape,
      impressora: impressora ?? this.impressora,
      taxaPadrao: taxaPadrao ?? this.taxaPadrao,
      largura: largura ?? this.largura,
      horizonteOperacional: horizonteOperacional ?? this.horizonteOperacional,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      logoPath: logoPath ?? this.logoPath,
      habilitarPix: habilitarPix ?? this.habilitarPix,
      pixTipoChave: pixTipoChave ?? this.pixTipoChave,
      pixChave: pixChave ?? this.pixChave,
      pixFavorecido: pixFavorecido ?? this.pixFavorecido,
      pixBanco: pixBanco ?? this.pixBanco,
      pixCidade: pixCidade ?? this.pixCidade,
      pixMensagem: pixMensagem ?? this.pixMensagem,
      pixImprimirQrCode: pixImprimirQrCode ?? this.pixImprimirQrCode,
      pixImprimirCopiaCola: pixImprimirCopiaCola ?? this.pixImprimirCopiaCola,
      pixGerarQrCodeAuto: pixGerarQrCodeAuto ?? this.pixGerarQrCodeAuto,
    );
  }
}

class SettingsService {
  final AppDatabase db;
  SettingsService(this.db);

  Future<AppSettings> carregar() async {
    final row = await (db.select(db.configuracoesEmpresa)..limit(1)).getSingleOrNull();
    if (row == null) {
      // Se não houver configurações, cria a primeira linha padrão
      final defaultConf = const AppSettings();
      await db.into(db.configuracoesEmpresa).insert(ConfiguracoesEmpresaCompanion.insert(
        empresa: Value(defaultConf.empresa),
        telefone: Value(defaultConf.telefone),
        endereco: Value(defaultConf.endereco),
        rodape: Value(defaultConf.rodape),
        impressora: Value(defaultConf.impressora),
        taxaPadrao: Value(defaultConf.taxaPadrao),
        largura: Value(defaultConf.largura),
        horizonteOperacional: Value(defaultConf.horizonteOperacional),
        razaoSocial: Value(defaultConf.razaoSocial),
        whatsapp: Value(defaultConf.whatsapp),
        instagram: Value(defaultConf.instagram),
        logoPath: Value(defaultConf.logoPath),
        habilitarPix: Value(defaultConf.habilitarPix),
        pixTipoChave: Value(defaultConf.pixTipoChave),
        pixChave: Value(defaultConf.pixChave),
        pixFavorecido: Value(defaultConf.pixFavorecido),
        pixBanco: Value(defaultConf.pixBanco),
        pixCidade: Value(defaultConf.pixCidade),
        pixMensagem: Value(defaultConf.pixMensagem),
        pixImprimirQrCode: Value(defaultConf.pixImprimirQrCode),
        pixImprimirCopiaCola: Value(defaultConf.pixImprimirCopiaCola),
        pixGerarQrCodeAuto: Value(defaultConf.pixGerarQrCodeAuto),
      ));
      return defaultConf;
    }

    return AppSettings(
      empresa: row.empresa,
      telefone: row.telefone,
      endereco: row.endereco,
      rodape: row.rodape,
      impressora: row.impressora,
      taxaPadrao: row.taxaPadrao,
      largura: row.largura,
      horizonteOperacional: row.horizonteOperacional,
      razaoSocial: row.razaoSocial,
      whatsapp: row.whatsapp,
      instagram: row.instagram,
      logoPath: row.logoPath,
      habilitarPix: row.habilitarPix,
      pixTipoChave: row.pixTipoChave,
      pixChave: row.pixChave,
      pixFavorecido: row.pixFavorecido,
      pixBanco: row.pixBanco,
      pixCidade: row.pixCidade,
      pixMensagem: row.pixMensagem,
      pixImprimirQrCode: row.pixImprimirQrCode,
      pixImprimirCopiaCola: row.pixImprimirCopiaCola,
      pixGerarQrCodeAuto: row.pixGerarQrCodeAuto,
    );
  }

  Future<void> salvar(AppSettings s) async {
    final row = await (db.select(db.configuracoesEmpresa)..limit(1)).getSingleOrNull();
    if (row != null) {
      await (db.update(db.configuracoesEmpresa)..where((c) => c.id.equals(row.id)))
          .write(ConfiguracoesEmpresaCompanion(
        empresa: Value(s.empresa),
        telefone: Value(s.telefone),
        endereco: Value(s.endereco),
        rodape: Value(s.rodape),
        impressora: Value(s.impressora),
        taxaPadrao: Value(s.taxaPadrao),
        largura: Value(s.largura),
        horizonteOperacional: Value(s.horizonteOperacional),
        razaoSocial: Value(s.razaoSocial),
        whatsapp: Value(s.whatsapp),
        instagram: Value(s.instagram),
        logoPath: Value(s.logoPath),
        habilitarPix: Value(s.habilitarPix),
        pixTipoChave: Value(s.pixTipoChave),
        pixChave: Value(s.pixChave),
        pixFavorecido: Value(s.pixFavorecido),
        pixBanco: Value(s.pixBanco),
        pixCidade: Value(s.pixCidade),
        pixMensagem: Value(s.pixMensagem),
        pixImprimirQrCode: Value(s.pixImprimirQrCode),
        pixImprimirCopiaCola: Value(s.pixImprimirCopiaCola),
        pixGerarQrCodeAuto: Value(s.pixGerarQrCodeAuto),
      ));
    }
  }
}
