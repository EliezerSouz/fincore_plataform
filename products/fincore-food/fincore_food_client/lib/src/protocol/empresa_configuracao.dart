/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class EmpresaConfiguracao implements _i1.SerializableModel {
  EmpresaConfiguracao._({
    _i1.UuidValue? id,
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
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    required this.syncVersion,
    this.originDeviceId,
    this.lastModifiedByDevice,
    this.entityHash,
    this.printerCaixa,
    this.printerCozinha,
    this.printerBalcao,
    this.printerExpedicao,
    required this.autoPrintCaixa,
    required this.autoPrintCozinha,
    required this.autoPrintBalcao,
    required this.autoPrintExpedicao,
    required this.viasCliente,
    required this.viasCozinha,
    required this.viasBalcao,
    required this.viasExpedicao,
    required this.larguraPapel,
    required this.cortarPapel,
    required this.abrirGaveta,
    required this.imprimirQRCode,
    required this.imprimirCopiaCola,
    required this.imprimirLogo,
    required this.imprimirRodape,
    required this.mensagemRodape,
    this.pixFavorecido,
    this.pixBanco,
    required this.pixTipo,
    required this.pixCidade,
    this.nomeEmpresaCupom,
    this.telefoneEmpresa,
    this.cnpjEmpresa,
    this.enderecoEmpresa,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory EmpresaConfiguracao({
    _i1.UuidValue? id,
    required String tenantId,
    required String timezone,
    required String locale,
    required String currency,
    String? printerConfig,
    String? pixKey,
    required double taxaServico,
    required bool usarWhatsApp,
    String? logoUrl,
    required String tema,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue createdBy,
    required _i1.UuidValue updatedBy,
    DateTime? deletedAt,
    _i1.UuidValue? deletedBy,
    required int syncVersion,
    String? originDeviceId,
    String? lastModifiedByDevice,
    String? entityHash,
    String? printerCaixa,
    String? printerCozinha,
    String? printerBalcao,
    String? printerExpedicao,
    required bool autoPrintCaixa,
    required bool autoPrintCozinha,
    required bool autoPrintBalcao,
    required bool autoPrintExpedicao,
    required int viasCliente,
    required int viasCozinha,
    required int viasBalcao,
    required int viasExpedicao,
    required int larguraPapel,
    required bool cortarPapel,
    required bool abrirGaveta,
    required bool imprimirQRCode,
    required bool imprimirCopiaCola,
    required bool imprimirLogo,
    required bool imprimirRodape,
    required String mensagemRodape,
    String? pixFavorecido,
    String? pixBanco,
    required String pixTipo,
    required String pixCidade,
    String? nomeEmpresaCupom,
    String? telefoneEmpresa,
    String? cnpjEmpresa,
    String? enderecoEmpresa,
  }) = _EmpresaConfiguracaoImpl;

  factory EmpresaConfiguracao.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmpresaConfiguracao(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      timezone: jsonSerialization['timezone'] as String,
      locale: jsonSerialization['locale'] as String,
      currency: jsonSerialization['currency'] as String,
      printerConfig: jsonSerialization['printerConfig'] as String?,
      pixKey: jsonSerialization['pixKey'] as String?,
      taxaServico: (jsonSerialization['taxaServico'] as num).toDouble(),
      usarWhatsApp: jsonSerialization['usarWhatsApp'] as bool,
      logoUrl: jsonSerialization['logoUrl'] as String?,
      tema: jsonSerialization['tema'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      createdBy:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['createdBy']),
      updatedBy:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['updatedBy']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      deletedBy: jsonSerialization['deletedBy'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['deletedBy']),
      syncVersion: jsonSerialization['syncVersion'] as int,
      originDeviceId: jsonSerialization['originDeviceId'] as String?,
      lastModifiedByDevice:
          jsonSerialization['lastModifiedByDevice'] as String?,
      entityHash: jsonSerialization['entityHash'] as String?,
      printerCaixa: jsonSerialization['printerCaixa'] as String?,
      printerCozinha: jsonSerialization['printerCozinha'] as String?,
      printerBalcao: jsonSerialization['printerBalcao'] as String?,
      printerExpedicao: jsonSerialization['printerExpedicao'] as String?,
      autoPrintCaixa: jsonSerialization['autoPrintCaixa'] as bool,
      autoPrintCozinha: jsonSerialization['autoPrintCozinha'] as bool,
      autoPrintBalcao: jsonSerialization['autoPrintBalcao'] as bool,
      autoPrintExpedicao: jsonSerialization['autoPrintExpedicao'] as bool,
      viasCliente: jsonSerialization['viasCliente'] as int,
      viasCozinha: jsonSerialization['viasCozinha'] as int,
      viasBalcao: jsonSerialization['viasBalcao'] as int,
      viasExpedicao: jsonSerialization['viasExpedicao'] as int,
      larguraPapel: jsonSerialization['larguraPapel'] as int,
      cortarPapel: jsonSerialization['cortarPapel'] as bool,
      abrirGaveta: jsonSerialization['abrirGaveta'] as bool,
      imprimirQRCode: jsonSerialization['imprimirQRCode'] as bool,
      imprimirCopiaCola: jsonSerialization['imprimirCopiaCola'] as bool,
      imprimirLogo: jsonSerialization['imprimirLogo'] as bool,
      imprimirRodape: jsonSerialization['imprimirRodape'] as bool,
      mensagemRodape: jsonSerialization['mensagemRodape'] as String,
      pixFavorecido: jsonSerialization['pixFavorecido'] as String?,
      pixBanco: jsonSerialization['pixBanco'] as String?,
      pixTipo: jsonSerialization['pixTipo'] as String,
      pixCidade: jsonSerialization['pixCidade'] as String,
      nomeEmpresaCupom: jsonSerialization['nomeEmpresaCupom'] as String?,
      telefoneEmpresa: jsonSerialization['telefoneEmpresa'] as String?,
      cnpjEmpresa: jsonSerialization['cnpjEmpresa'] as String?,
      enderecoEmpresa: jsonSerialization['enderecoEmpresa'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue id;

  String tenantId;

  String timezone;

  String locale;

  String currency;

  String? printerConfig;

  String? pixKey;

  double taxaServico;

  bool usarWhatsApp;

  String? logoUrl;

  String tema;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue createdBy;

  _i1.UuidValue updatedBy;

  DateTime? deletedAt;

  _i1.UuidValue? deletedBy;

  int syncVersion;

  String? originDeviceId;

  String? lastModifiedByDevice;

  String? entityHash;

  String? printerCaixa;

  String? printerCozinha;

  String? printerBalcao;

  String? printerExpedicao;

  bool autoPrintCaixa;

  bool autoPrintCozinha;

  bool autoPrintBalcao;

  bool autoPrintExpedicao;

  int viasCliente;

  int viasCozinha;

  int viasBalcao;

  int viasExpedicao;

  int larguraPapel;

  bool cortarPapel;

  bool abrirGaveta;

  bool imprimirQRCode;

  bool imprimirCopiaCola;

  bool imprimirLogo;

  bool imprimirRodape;

  String mensagemRodape;

  String? pixFavorecido;

  String? pixBanco;

  String pixTipo;

  String pixCidade;

  String? nomeEmpresaCupom;

  String? telefoneEmpresa;

  String? cnpjEmpresa;

  String? enderecoEmpresa;

  /// Returns a shallow copy of this [EmpresaConfiguracao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmpresaConfiguracao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? timezone,
    String? locale,
    String? currency,
    String? printerConfig,
    String? pixKey,
    double? taxaServico,
    bool? usarWhatsApp,
    String? logoUrl,
    String? tema,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? createdBy,
    _i1.UuidValue? updatedBy,
    DateTime? deletedAt,
    _i1.UuidValue? deletedBy,
    int? syncVersion,
    String? originDeviceId,
    String? lastModifiedByDevice,
    String? entityHash,
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
    String? pixCidade,
    String? nomeEmpresaCupom,
    String? telefoneEmpresa,
    String? cnpjEmpresa,
    String? enderecoEmpresa,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId,
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      if (printerConfig != null) 'printerConfig': printerConfig,
      if (pixKey != null) 'pixKey': pixKey,
      'taxaServico': taxaServico,
      'usarWhatsApp': usarWhatsApp,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'tema': tema,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'createdBy': createdBy.toJson(),
      'updatedBy': updatedBy.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (deletedBy != null) 'deletedBy': deletedBy?.toJson(),
      'syncVersion': syncVersion,
      if (originDeviceId != null) 'originDeviceId': originDeviceId,
      if (lastModifiedByDevice != null)
        'lastModifiedByDevice': lastModifiedByDevice,
      if (entityHash != null) 'entityHash': entityHash,
      if (printerCaixa != null) 'printerCaixa': printerCaixa,
      if (printerCozinha != null) 'printerCozinha': printerCozinha,
      if (printerBalcao != null) 'printerBalcao': printerBalcao,
      if (printerExpedicao != null) 'printerExpedicao': printerExpedicao,
      'autoPrintCaixa': autoPrintCaixa,
      'autoPrintCozinha': autoPrintCozinha,
      'autoPrintBalcao': autoPrintBalcao,
      'autoPrintExpedicao': autoPrintExpedicao,
      'viasCliente': viasCliente,
      'viasCozinha': viasCozinha,
      'viasBalcao': viasBalcao,
      'viasExpedicao': viasExpedicao,
      'larguraPapel': larguraPapel,
      'cortarPapel': cortarPapel,
      'abrirGaveta': abrirGaveta,
      'imprimirQRCode': imprimirQRCode,
      'imprimirCopiaCola': imprimirCopiaCola,
      'imprimirLogo': imprimirLogo,
      'imprimirRodape': imprimirRodape,
      'mensagemRodape': mensagemRodape,
      if (pixFavorecido != null) 'pixFavorecido': pixFavorecido,
      if (pixBanco != null) 'pixBanco': pixBanco,
      'pixTipo': pixTipo,
      'pixCidade': pixCidade,
      if (nomeEmpresaCupom != null) 'nomeEmpresaCupom': nomeEmpresaCupom,
      if (telefoneEmpresa != null) 'telefoneEmpresa': telefoneEmpresa,
      if (cnpjEmpresa != null) 'cnpjEmpresa': cnpjEmpresa,
      if (enderecoEmpresa != null) 'enderecoEmpresa': enderecoEmpresa,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmpresaConfiguracaoImpl extends EmpresaConfiguracao {
  _EmpresaConfiguracaoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String timezone,
    required String locale,
    required String currency,
    String? printerConfig,
    String? pixKey,
    required double taxaServico,
    required bool usarWhatsApp,
    String? logoUrl,
    required String tema,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue createdBy,
    required _i1.UuidValue updatedBy,
    DateTime? deletedAt,
    _i1.UuidValue? deletedBy,
    required int syncVersion,
    String? originDeviceId,
    String? lastModifiedByDevice,
    String? entityHash,
    String? printerCaixa,
    String? printerCozinha,
    String? printerBalcao,
    String? printerExpedicao,
    required bool autoPrintCaixa,
    required bool autoPrintCozinha,
    required bool autoPrintBalcao,
    required bool autoPrintExpedicao,
    required int viasCliente,
    required int viasCozinha,
    required int viasBalcao,
    required int viasExpedicao,
    required int larguraPapel,
    required bool cortarPapel,
    required bool abrirGaveta,
    required bool imprimirQRCode,
    required bool imprimirCopiaCola,
    required bool imprimirLogo,
    required bool imprimirRodape,
    required String mensagemRodape,
    String? pixFavorecido,
    String? pixBanco,
    required String pixTipo,
    required String pixCidade,
    String? nomeEmpresaCupom,
    String? telefoneEmpresa,
    String? cnpjEmpresa,
    String? enderecoEmpresa,
  }) : super._(
          id: id,
          tenantId: tenantId,
          timezone: timezone,
          locale: locale,
          currency: currency,
          printerConfig: printerConfig,
          pixKey: pixKey,
          taxaServico: taxaServico,
          usarWhatsApp: usarWhatsApp,
          logoUrl: logoUrl,
          tema: tema,
          createdAt: createdAt,
          updatedAt: updatedAt,
          createdBy: createdBy,
          updatedBy: updatedBy,
          deletedAt: deletedAt,
          deletedBy: deletedBy,
          syncVersion: syncVersion,
          originDeviceId: originDeviceId,
          lastModifiedByDevice: lastModifiedByDevice,
          entityHash: entityHash,
          printerCaixa: printerCaixa,
          printerCozinha: printerCozinha,
          printerBalcao: printerBalcao,
          printerExpedicao: printerExpedicao,
          autoPrintCaixa: autoPrintCaixa,
          autoPrintCozinha: autoPrintCozinha,
          autoPrintBalcao: autoPrintBalcao,
          autoPrintExpedicao: autoPrintExpedicao,
          viasCliente: viasCliente,
          viasCozinha: viasCozinha,
          viasBalcao: viasBalcao,
          viasExpedicao: viasExpedicao,
          larguraPapel: larguraPapel,
          cortarPapel: cortarPapel,
          abrirGaveta: abrirGaveta,
          imprimirQRCode: imprimirQRCode,
          imprimirCopiaCola: imprimirCopiaCola,
          imprimirLogo: imprimirLogo,
          imprimirRodape: imprimirRodape,
          mensagemRodape: mensagemRodape,
          pixFavorecido: pixFavorecido,
          pixBanco: pixBanco,
          pixTipo: pixTipo,
          pixCidade: pixCidade,
          nomeEmpresaCupom: nomeEmpresaCupom,
          telefoneEmpresa: telefoneEmpresa,
          cnpjEmpresa: cnpjEmpresa,
          enderecoEmpresa: enderecoEmpresa,
        );

  /// Returns a shallow copy of this [EmpresaConfiguracao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmpresaConfiguracao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? timezone,
    String? locale,
    String? currency,
    Object? printerConfig = _Undefined,
    Object? pixKey = _Undefined,
    double? taxaServico,
    bool? usarWhatsApp,
    Object? logoUrl = _Undefined,
    String? tema,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? createdBy,
    _i1.UuidValue? updatedBy,
    Object? deletedAt = _Undefined,
    Object? deletedBy = _Undefined,
    int? syncVersion,
    Object? originDeviceId = _Undefined,
    Object? lastModifiedByDevice = _Undefined,
    Object? entityHash = _Undefined,
    Object? printerCaixa = _Undefined,
    Object? printerCozinha = _Undefined,
    Object? printerBalcao = _Undefined,
    Object? printerExpedicao = _Undefined,
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
    Object? pixFavorecido = _Undefined,
    Object? pixBanco = _Undefined,
    String? pixTipo,
    String? pixCidade,
    Object? nomeEmpresaCupom = _Undefined,
    Object? telefoneEmpresa = _Undefined,
    Object? cnpjEmpresa = _Undefined,
    Object? enderecoEmpresa = _Undefined,
  }) {
    return EmpresaConfiguracao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      printerConfig:
          printerConfig is String? ? printerConfig : this.printerConfig,
      pixKey: pixKey is String? ? pixKey : this.pixKey,
      taxaServico: taxaServico ?? this.taxaServico,
      usarWhatsApp: usarWhatsApp ?? this.usarWhatsApp,
      logoUrl: logoUrl is String? ? logoUrl : this.logoUrl,
      tema: tema ?? this.tema,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      deletedBy: deletedBy is _i1.UuidValue? ? deletedBy : this.deletedBy,
      syncVersion: syncVersion ?? this.syncVersion,
      originDeviceId:
          originDeviceId is String? ? originDeviceId : this.originDeviceId,
      lastModifiedByDevice: lastModifiedByDevice is String?
          ? lastModifiedByDevice
          : this.lastModifiedByDevice,
      entityHash: entityHash is String? ? entityHash : this.entityHash,
      printerCaixa: printerCaixa is String? ? printerCaixa : this.printerCaixa,
      printerCozinha:
          printerCozinha is String? ? printerCozinha : this.printerCozinha,
      printerBalcao:
          printerBalcao is String? ? printerBalcao : this.printerBalcao,
      printerExpedicao: printerExpedicao is String?
          ? printerExpedicao
          : this.printerExpedicao,
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
      pixFavorecido:
          pixFavorecido is String? ? pixFavorecido : this.pixFavorecido,
      pixBanco: pixBanco is String? ? pixBanco : this.pixBanco,
      pixTipo: pixTipo ?? this.pixTipo,
      pixCidade: pixCidade ?? this.pixCidade,
      nomeEmpresaCupom: nomeEmpresaCupom is String?
          ? nomeEmpresaCupom
          : this.nomeEmpresaCupom,
      telefoneEmpresa:
          telefoneEmpresa is String? ? telefoneEmpresa : this.telefoneEmpresa,
      cnpjEmpresa: cnpjEmpresa is String? ? cnpjEmpresa : this.cnpjEmpresa,
      enderecoEmpresa:
          enderecoEmpresa is String? ? enderecoEmpresa : this.enderecoEmpresa,
    );
  }
}
