/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class EmpresaConfiguracao
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
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

  static final t = EmpresaConfiguracaoTable();

  static const db = EmpresaConfiguracaoRepository._();

  @override
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

  @override
  _i1.Table<_i1.UuidValue> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static EmpresaConfiguracaoInclude include() {
    return EmpresaConfiguracaoInclude._();
  }

  static EmpresaConfiguracaoIncludeList includeList({
    _i1.WhereExpressionBuilder<EmpresaConfiguracaoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmpresaConfiguracaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaConfiguracaoTable>? orderByList,
    EmpresaConfiguracaoInclude? include,
  }) {
    return EmpresaConfiguracaoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmpresaConfiguracao.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EmpresaConfiguracao.t),
      include: include,
    );
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

class EmpresaConfiguracaoTable extends _i1.Table<_i1.UuidValue> {
  EmpresaConfiguracaoTable({super.tableRelation})
      : super(tableName: 'empresa_configuracao') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    timezone = _i1.ColumnString(
      'timezone',
      this,
    );
    locale = _i1.ColumnString(
      'locale',
      this,
    );
    currency = _i1.ColumnString(
      'currency',
      this,
    );
    printerConfig = _i1.ColumnString(
      'printerConfig',
      this,
    );
    pixKey = _i1.ColumnString(
      'pixKey',
      this,
    );
    taxaServico = _i1.ColumnDouble(
      'taxaServico',
      this,
    );
    usarWhatsApp = _i1.ColumnBool(
      'usarWhatsApp',
      this,
    );
    logoUrl = _i1.ColumnString(
      'logoUrl',
      this,
    );
    tema = _i1.ColumnString(
      'tema',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    createdBy = _i1.ColumnUuid(
      'createdBy',
      this,
    );
    updatedBy = _i1.ColumnUuid(
      'updatedBy',
      this,
    );
    deletedAt = _i1.ColumnDateTime(
      'deletedAt',
      this,
    );
    deletedBy = _i1.ColumnUuid(
      'deletedBy',
      this,
    );
    syncVersion = _i1.ColumnInt(
      'syncVersion',
      this,
    );
    originDeviceId = _i1.ColumnString(
      'originDeviceId',
      this,
    );
    lastModifiedByDevice = _i1.ColumnString(
      'lastModifiedByDevice',
      this,
    );
    entityHash = _i1.ColumnString(
      'entityHash',
      this,
    );
    printerCaixa = _i1.ColumnString(
      'printerCaixa',
      this,
    );
    printerCozinha = _i1.ColumnString(
      'printerCozinha',
      this,
    );
    printerBalcao = _i1.ColumnString(
      'printerBalcao',
      this,
    );
    printerExpedicao = _i1.ColumnString(
      'printerExpedicao',
      this,
    );
    autoPrintCaixa = _i1.ColumnBool(
      'autoPrintCaixa',
      this,
    );
    autoPrintCozinha = _i1.ColumnBool(
      'autoPrintCozinha',
      this,
    );
    autoPrintBalcao = _i1.ColumnBool(
      'autoPrintBalcao',
      this,
    );
    autoPrintExpedicao = _i1.ColumnBool(
      'autoPrintExpedicao',
      this,
    );
    viasCliente = _i1.ColumnInt(
      'viasCliente',
      this,
    );
    viasCozinha = _i1.ColumnInt(
      'viasCozinha',
      this,
    );
    viasBalcao = _i1.ColumnInt(
      'viasBalcao',
      this,
    );
    viasExpedicao = _i1.ColumnInt(
      'viasExpedicao',
      this,
    );
    larguraPapel = _i1.ColumnInt(
      'larguraPapel',
      this,
    );
    cortarPapel = _i1.ColumnBool(
      'cortarPapel',
      this,
    );
    abrirGaveta = _i1.ColumnBool(
      'abrirGaveta',
      this,
    );
    imprimirQRCode = _i1.ColumnBool(
      'imprimirQRCode',
      this,
    );
    imprimirCopiaCola = _i1.ColumnBool(
      'imprimirCopiaCola',
      this,
    );
    imprimirLogo = _i1.ColumnBool(
      'imprimirLogo',
      this,
    );
    imprimirRodape = _i1.ColumnBool(
      'imprimirRodape',
      this,
    );
    mensagemRodape = _i1.ColumnString(
      'mensagemRodape',
      this,
    );
    pixFavorecido = _i1.ColumnString(
      'pixFavorecido',
      this,
    );
    pixBanco = _i1.ColumnString(
      'pixBanco',
      this,
    );
    pixTipo = _i1.ColumnString(
      'pixTipo',
      this,
    );
    pixCidade = _i1.ColumnString(
      'pixCidade',
      this,
    );
    nomeEmpresaCupom = _i1.ColumnString(
      'nomeEmpresaCupom',
      this,
    );
    telefoneEmpresa = _i1.ColumnString(
      'telefoneEmpresa',
      this,
    );
    cnpjEmpresa = _i1.ColumnString(
      'cnpjEmpresa',
      this,
    );
    enderecoEmpresa = _i1.ColumnString(
      'enderecoEmpresa',
      this,
    );
  }

  late final _i1.ColumnString tenantId;

  late final _i1.ColumnString timezone;

  late final _i1.ColumnString locale;

  late final _i1.ColumnString currency;

  late final _i1.ColumnString printerConfig;

  late final _i1.ColumnString pixKey;

  late final _i1.ColumnDouble taxaServico;

  late final _i1.ColumnBool usarWhatsApp;

  late final _i1.ColumnString logoUrl;

  late final _i1.ColumnString tema;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid createdBy;

  late final _i1.ColumnUuid updatedBy;

  late final _i1.ColumnDateTime deletedAt;

  late final _i1.ColumnUuid deletedBy;

  late final _i1.ColumnInt syncVersion;

  late final _i1.ColumnString originDeviceId;

  late final _i1.ColumnString lastModifiedByDevice;

  late final _i1.ColumnString entityHash;

  late final _i1.ColumnString printerCaixa;

  late final _i1.ColumnString printerCozinha;

  late final _i1.ColumnString printerBalcao;

  late final _i1.ColumnString printerExpedicao;

  late final _i1.ColumnBool autoPrintCaixa;

  late final _i1.ColumnBool autoPrintCozinha;

  late final _i1.ColumnBool autoPrintBalcao;

  late final _i1.ColumnBool autoPrintExpedicao;

  late final _i1.ColumnInt viasCliente;

  late final _i1.ColumnInt viasCozinha;

  late final _i1.ColumnInt viasBalcao;

  late final _i1.ColumnInt viasExpedicao;

  late final _i1.ColumnInt larguraPapel;

  late final _i1.ColumnBool cortarPapel;

  late final _i1.ColumnBool abrirGaveta;

  late final _i1.ColumnBool imprimirQRCode;

  late final _i1.ColumnBool imprimirCopiaCola;

  late final _i1.ColumnBool imprimirLogo;

  late final _i1.ColumnBool imprimirRodape;

  late final _i1.ColumnString mensagemRodape;

  late final _i1.ColumnString pixFavorecido;

  late final _i1.ColumnString pixBanco;

  late final _i1.ColumnString pixTipo;

  late final _i1.ColumnString pixCidade;

  late final _i1.ColumnString nomeEmpresaCupom;

  late final _i1.ColumnString telefoneEmpresa;

  late final _i1.ColumnString cnpjEmpresa;

  late final _i1.ColumnString enderecoEmpresa;

  @override
  List<_i1.Column> get columns => [
        id,
        tenantId,
        timezone,
        locale,
        currency,
        printerConfig,
        pixKey,
        taxaServico,
        usarWhatsApp,
        logoUrl,
        tema,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        deletedAt,
        deletedBy,
        syncVersion,
        originDeviceId,
        lastModifiedByDevice,
        entityHash,
        printerCaixa,
        printerCozinha,
        printerBalcao,
        printerExpedicao,
        autoPrintCaixa,
        autoPrintCozinha,
        autoPrintBalcao,
        autoPrintExpedicao,
        viasCliente,
        viasCozinha,
        viasBalcao,
        viasExpedicao,
        larguraPapel,
        cortarPapel,
        abrirGaveta,
        imprimirQRCode,
        imprimirCopiaCola,
        imprimirLogo,
        imprimirRodape,
        mensagemRodape,
        pixFavorecido,
        pixBanco,
        pixTipo,
        pixCidade,
        nomeEmpresaCupom,
        telefoneEmpresa,
        cnpjEmpresa,
        enderecoEmpresa,
      ];
}

class EmpresaConfiguracaoInclude extends _i1.IncludeObject {
  EmpresaConfiguracaoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EmpresaConfiguracao.t;
}

class EmpresaConfiguracaoIncludeList extends _i1.IncludeList {
  EmpresaConfiguracaoIncludeList._({
    _i1.WhereExpressionBuilder<EmpresaConfiguracaoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EmpresaConfiguracao.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EmpresaConfiguracao.t;
}

class EmpresaConfiguracaoRepository {
  const EmpresaConfiguracaoRepository._();

  /// Returns a list of [EmpresaConfiguracao]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<EmpresaConfiguracao>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaConfiguracaoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmpresaConfiguracaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaConfiguracaoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EmpresaConfiguracao>(
      where: where?.call(EmpresaConfiguracao.t),
      orderBy: orderBy?.call(EmpresaConfiguracao.t),
      orderByList: orderByList?.call(EmpresaConfiguracao.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EmpresaConfiguracao] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<EmpresaConfiguracao?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaConfiguracaoTable>? where,
    int? offset,
    _i1.OrderByBuilder<EmpresaConfiguracaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaConfiguracaoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EmpresaConfiguracao>(
      where: where?.call(EmpresaConfiguracao.t),
      orderBy: orderBy?.call(EmpresaConfiguracao.t),
      orderByList: orderByList?.call(EmpresaConfiguracao.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EmpresaConfiguracao] by its [id] or null if no such row exists.
  Future<EmpresaConfiguracao?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EmpresaConfiguracao>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EmpresaConfiguracao]s in the list and returns the inserted rows.
  ///
  /// The returned [EmpresaConfiguracao]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EmpresaConfiguracao>> insert(
    _i1.Session session,
    List<EmpresaConfiguracao> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EmpresaConfiguracao>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EmpresaConfiguracao] and returns the inserted row.
  ///
  /// The returned [EmpresaConfiguracao] will have its `id` field set.
  Future<EmpresaConfiguracao> insertRow(
    _i1.Session session,
    EmpresaConfiguracao row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EmpresaConfiguracao>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EmpresaConfiguracao]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EmpresaConfiguracao>> update(
    _i1.Session session,
    List<EmpresaConfiguracao> rows, {
    _i1.ColumnSelections<EmpresaConfiguracaoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EmpresaConfiguracao>(
      rows,
      columns: columns?.call(EmpresaConfiguracao.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmpresaConfiguracao]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EmpresaConfiguracao> updateRow(
    _i1.Session session,
    EmpresaConfiguracao row, {
    _i1.ColumnSelections<EmpresaConfiguracaoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EmpresaConfiguracao>(
      row,
      columns: columns?.call(EmpresaConfiguracao.t),
      transaction: transaction,
    );
  }

  /// Deletes all [EmpresaConfiguracao]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EmpresaConfiguracao>> delete(
    _i1.Session session,
    List<EmpresaConfiguracao> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EmpresaConfiguracao>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EmpresaConfiguracao].
  Future<EmpresaConfiguracao> deleteRow(
    _i1.Session session,
    EmpresaConfiguracao row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EmpresaConfiguracao>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EmpresaConfiguracao>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EmpresaConfiguracaoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EmpresaConfiguracao>(
      where: where(EmpresaConfiguracao.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaConfiguracaoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EmpresaConfiguracao>(
      where: where?.call(EmpresaConfiguracao.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
