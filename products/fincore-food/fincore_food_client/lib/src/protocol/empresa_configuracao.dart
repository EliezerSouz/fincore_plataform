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
    this.modoDeliveryAtivo,
    this.clienteObrigatorioVenda,
    this.atendimentoPadrao,
    this.margemSegurancaMinutos,
    this.taxaEntregaPorKm,
    this.valorPorKmCentavos,
    this.mercadoPagoAtivo,
    this.openPixAtivo,
    this.asaasAtivo,
    this.ifoodAtivo,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory EmpresaConfiguracao({
    _i1.UuidValue? id,
    required String tenantId,
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
    bool? modoDeliveryAtivo,
    bool? clienteObrigatorioVenda,
    String? atendimentoPadrao,
    int? margemSegurancaMinutos,
    bool? taxaEntregaPorKm,
    int? valorPorKmCentavos,
    bool? mercadoPagoAtivo,
    bool? openPixAtivo,
    bool? asaasAtivo,
    bool? ifoodAtivo,
  }) = _EmpresaConfiguracaoImpl;

  factory EmpresaConfiguracao.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmpresaConfiguracao(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
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
      modoDeliveryAtivo: jsonSerialization['modoDeliveryAtivo'] as bool?,
      clienteObrigatorioVenda:
          jsonSerialization['clienteObrigatorioVenda'] as bool?,
      atendimentoPadrao: jsonSerialization['atendimentoPadrao'] as String?,
      margemSegurancaMinutos:
          jsonSerialization['margemSegurancaMinutos'] as int?,
      taxaEntregaPorKm: jsonSerialization['taxaEntregaPorKm'] as bool?,
      valorPorKmCentavos: jsonSerialization['valorPorKmCentavos'] as int?,
      mercadoPagoAtivo: jsonSerialization['mercadoPagoAtivo'] as bool?,
      openPixAtivo: jsonSerialization['openPixAtivo'] as bool?,
      asaasAtivo: jsonSerialization['asaasAtivo'] as bool?,
      ifoodAtivo: jsonSerialization['ifoodAtivo'] as bool?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue id;

  String tenantId;

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

  bool? modoDeliveryAtivo;

  bool? clienteObrigatorioVenda;

  String? atendimentoPadrao;

  int? margemSegurancaMinutos;

  bool? taxaEntregaPorKm;

  int? valorPorKmCentavos;

  bool? mercadoPagoAtivo;

  bool? openPixAtivo;

  bool? asaasAtivo;

  bool? ifoodAtivo;

  /// Returns a shallow copy of this [EmpresaConfiguracao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmpresaConfiguracao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
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
    bool? modoDeliveryAtivo,
    bool? clienteObrigatorioVenda,
    String? atendimentoPadrao,
    int? margemSegurancaMinutos,
    bool? taxaEntregaPorKm,
    int? valorPorKmCentavos,
    bool? mercadoPagoAtivo,
    bool? openPixAtivo,
    bool? asaasAtivo,
    bool? ifoodAtivo,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId,
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
      if (modoDeliveryAtivo != null) 'modoDeliveryAtivo': modoDeliveryAtivo,
      if (clienteObrigatorioVenda != null)
        'clienteObrigatorioVenda': clienteObrigatorioVenda,
      if (atendimentoPadrao != null) 'atendimentoPadrao': atendimentoPadrao,
      if (margemSegurancaMinutos != null)
        'margemSegurancaMinutos': margemSegurancaMinutos,
      if (taxaEntregaPorKm != null) 'taxaEntregaPorKm': taxaEntregaPorKm,
      if (valorPorKmCentavos != null) 'valorPorKmCentavos': valorPorKmCentavos,
      if (mercadoPagoAtivo != null) 'mercadoPagoAtivo': mercadoPagoAtivo,
      if (openPixAtivo != null) 'openPixAtivo': openPixAtivo,
      if (asaasAtivo != null) 'asaasAtivo': asaasAtivo,
      if (ifoodAtivo != null) 'ifoodAtivo': ifoodAtivo,
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
    bool? modoDeliveryAtivo,
    bool? clienteObrigatorioVenda,
    String? atendimentoPadrao,
    int? margemSegurancaMinutos,
    bool? taxaEntregaPorKm,
    int? valorPorKmCentavos,
    bool? mercadoPagoAtivo,
    bool? openPixAtivo,
    bool? asaasAtivo,
    bool? ifoodAtivo,
  }) : super._(
          id: id,
          tenantId: tenantId,
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
          modoDeliveryAtivo: modoDeliveryAtivo,
          clienteObrigatorioVenda: clienteObrigatorioVenda,
          atendimentoPadrao: atendimentoPadrao,
          margemSegurancaMinutos: margemSegurancaMinutos,
          taxaEntregaPorKm: taxaEntregaPorKm,
          valorPorKmCentavos: valorPorKmCentavos,
          mercadoPagoAtivo: mercadoPagoAtivo,
          openPixAtivo: openPixAtivo,
          asaasAtivo: asaasAtivo,
          ifoodAtivo: ifoodAtivo,
        );

  /// Returns a shallow copy of this [EmpresaConfiguracao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmpresaConfiguracao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
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
    Object? modoDeliveryAtivo = _Undefined,
    Object? clienteObrigatorioVenda = _Undefined,
    Object? atendimentoPadrao = _Undefined,
    Object? margemSegurancaMinutos = _Undefined,
    Object? taxaEntregaPorKm = _Undefined,
    Object? valorPorKmCentavos = _Undefined,
    Object? mercadoPagoAtivo = _Undefined,
    Object? openPixAtivo = _Undefined,
    Object? asaasAtivo = _Undefined,
    Object? ifoodAtivo = _Undefined,
  }) {
    return EmpresaConfiguracao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
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
      modoDeliveryAtivo: modoDeliveryAtivo is bool?
          ? modoDeliveryAtivo
          : this.modoDeliveryAtivo,
      clienteObrigatorioVenda: clienteObrigatorioVenda is bool?
          ? clienteObrigatorioVenda
          : this.clienteObrigatorioVenda,
      atendimentoPadrao: atendimentoPadrao is String?
          ? atendimentoPadrao
          : this.atendimentoPadrao,
      margemSegurancaMinutos: margemSegurancaMinutos is int?
          ? margemSegurancaMinutos
          : this.margemSegurancaMinutos,
      taxaEntregaPorKm:
          taxaEntregaPorKm is bool? ? taxaEntregaPorKm : this.taxaEntregaPorKm,
      valorPorKmCentavos: valorPorKmCentavos is int?
          ? valorPorKmCentavos
          : this.valorPorKmCentavos,
      mercadoPagoAtivo:
          mercadoPagoAtivo is bool? ? mercadoPagoAtivo : this.mercadoPagoAtivo,
      openPixAtivo: openPixAtivo is bool? ? openPixAtivo : this.openPixAtivo,
      asaasAtivo: asaasAtivo is bool? ? asaasAtivo : this.asaasAtivo,
      ifoodAtivo: ifoodAtivo is bool? ? ifoodAtivo : this.ifoodAtivo,
    );
  }
}
