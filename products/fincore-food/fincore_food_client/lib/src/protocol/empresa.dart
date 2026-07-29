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

abstract class Empresa implements _i1.SerializableModel {
  Empresa._({
    _i1.UuidValue? id,
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
    this.vencimento,
    this.segmento,
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
  }) : id = id ?? _i1.Uuid().v4obj();

  factory Empresa({
    _i1.UuidValue? id,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String email,
    required String telefone,
    required String status,
    required String plano,
    required String timezone,
    required String locale,
    required String currency,
    required String country,
    required String createdFrom,
    DateTime? vencimento,
    String? segmento,
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
  }) = _EmpresaImpl;

  factory Empresa.fromJson(Map<String, dynamic> jsonSerialization) {
    return Empresa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      razaoSocial: jsonSerialization['razaoSocial'] as String,
      nomeFantasia: jsonSerialization['nomeFantasia'] as String,
      documentoFiscal: jsonSerialization['documentoFiscal'] as String,
      email: jsonSerialization['email'] as String,
      telefone: jsonSerialization['telefone'] as String,
      status: jsonSerialization['status'] as String,
      plano: jsonSerialization['plano'] as String,
      timezone: jsonSerialization['timezone'] as String,
      locale: jsonSerialization['locale'] as String,
      currency: jsonSerialization['currency'] as String,
      country: jsonSerialization['country'] as String,
      createdFrom: jsonSerialization['createdFrom'] as String,
      vencimento: jsonSerialization['vencimento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['vencimento']),
      segmento: jsonSerialization['segmento'] as String?,
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
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue id;

  String razaoSocial;

  String nomeFantasia;

  String documentoFiscal;

  String email;

  String telefone;

  String status;

  String plano;

  String timezone;

  String locale;

  String currency;

  String country;

  String createdFrom;

  DateTime? vencimento;

  String? segmento;

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

  /// Returns a shallow copy of this [Empresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Empresa copyWith({
    _i1.UuidValue? id,
    String? razaoSocial,
    String? nomeFantasia,
    String? documentoFiscal,
    String? email,
    String? telefone,
    String? status,
    String? plano,
    String? timezone,
    String? locale,
    String? currency,
    String? country,
    String? createdFrom,
    DateTime? vencimento,
    String? segmento,
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
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'documentoFiscal': documentoFiscal,
      'email': email,
      'telefone': telefone,
      'status': status,
      'plano': plano,
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      'country': country,
      'createdFrom': createdFrom,
      if (vencimento != null) 'vencimento': vencimento?.toJson(),
      if (segmento != null) 'segmento': segmento,
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
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmpresaImpl extends Empresa {
  _EmpresaImpl({
    _i1.UuidValue? id,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String email,
    required String telefone,
    required String status,
    required String plano,
    required String timezone,
    required String locale,
    required String currency,
    required String country,
    required String createdFrom,
    DateTime? vencimento,
    String? segmento,
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
  }) : super._(
          id: id,
          razaoSocial: razaoSocial,
          nomeFantasia: nomeFantasia,
          documentoFiscal: documentoFiscal,
          email: email,
          telefone: telefone,
          status: status,
          plano: plano,
          timezone: timezone,
          locale: locale,
          currency: currency,
          country: country,
          createdFrom: createdFrom,
          vencimento: vencimento,
          segmento: segmento,
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
        );

  /// Returns a shallow copy of this [Empresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Empresa copyWith({
    _i1.UuidValue? id,
    String? razaoSocial,
    String? nomeFantasia,
    String? documentoFiscal,
    String? email,
    String? telefone,
    String? status,
    String? plano,
    String? timezone,
    String? locale,
    String? currency,
    String? country,
    String? createdFrom,
    Object? vencimento = _Undefined,
    Object? segmento = _Undefined,
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
  }) {
    return Empresa(
      id: id ?? this.id,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      documentoFiscal: documentoFiscal ?? this.documentoFiscal,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      status: status ?? this.status,
      plano: plano ?? this.plano,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      createdFrom: createdFrom ?? this.createdFrom,
      vencimento: vencimento is DateTime? ? vencimento : this.vencimento,
      segmento: segmento is String? ? segmento : this.segmento,
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
    );
  }
}
