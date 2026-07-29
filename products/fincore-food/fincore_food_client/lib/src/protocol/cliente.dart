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

abstract class Cliente implements _i1.SerializableModel {
  Cliente._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.nome,
    required this.telefone,
    this.email,
    this.documento,
    required this.observacoes,
    required this.ativo,
    this.apelido,
    this.dataNascimento,
    required this.aceitaWhatsapp,
    required this.aceitaMarketing,
    this.preferenciaEntrega,
    this.limiteCredito,
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

  factory Cliente({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String telefone,
    String? email,
    String? documento,
    required String observacoes,
    required bool ativo,
    String? apelido,
    DateTime? dataNascimento,
    required bool aceitaWhatsapp,
    required bool aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
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
  }) = _ClienteImpl;

  factory Cliente.fromJson(Map<String, dynamic> jsonSerialization) {
    return Cliente(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      nome: jsonSerialization['nome'] as String,
      telefone: jsonSerialization['telefone'] as String,
      email: jsonSerialization['email'] as String?,
      documento: jsonSerialization['documento'] as String?,
      observacoes: jsonSerialization['observacoes'] as String,
      ativo: jsonSerialization['ativo'] as bool,
      apelido: jsonSerialization['apelido'] as String?,
      dataNascimento: jsonSerialization['dataNascimento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dataNascimento']),
      aceitaWhatsapp: jsonSerialization['aceitaWhatsapp'] as bool,
      aceitaMarketing: jsonSerialization['aceitaMarketing'] as bool,
      preferenciaEntrega: jsonSerialization['preferenciaEntrega'] as String?,
      limiteCredito: jsonSerialization['limiteCredito'] as int?,
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

  String tenantId;

  String nome;

  String telefone;

  String? email;

  String? documento;

  String observacoes;

  bool ativo;

  String? apelido;

  DateTime? dataNascimento;

  bool aceitaWhatsapp;

  bool aceitaMarketing;

  String? preferenciaEntrega;

  int? limiteCredito;

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

  /// Returns a shallow copy of this [Cliente]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Cliente copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? telefone,
    String? email,
    String? documento,
    String? observacoes,
    bool? ativo,
    String? apelido,
    DateTime? dataNascimento,
    bool? aceitaWhatsapp,
    bool? aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
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
      'tenantId': tenantId,
      'nome': nome,
      'telefone': telefone,
      if (email != null) 'email': email,
      if (documento != null) 'documento': documento,
      'observacoes': observacoes,
      'ativo': ativo,
      if (apelido != null) 'apelido': apelido,
      if (dataNascimento != null) 'dataNascimento': dataNascimento?.toJson(),
      'aceitaWhatsapp': aceitaWhatsapp,
      'aceitaMarketing': aceitaMarketing,
      if (preferenciaEntrega != null) 'preferenciaEntrega': preferenciaEntrega,
      if (limiteCredito != null) 'limiteCredito': limiteCredito,
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

class _ClienteImpl extends Cliente {
  _ClienteImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String telefone,
    String? email,
    String? documento,
    required String observacoes,
    required bool ativo,
    String? apelido,
    DateTime? dataNascimento,
    required bool aceitaWhatsapp,
    required bool aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
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
          tenantId: tenantId,
          nome: nome,
          telefone: telefone,
          email: email,
          documento: documento,
          observacoes: observacoes,
          ativo: ativo,
          apelido: apelido,
          dataNascimento: dataNascimento,
          aceitaWhatsapp: aceitaWhatsapp,
          aceitaMarketing: aceitaMarketing,
          preferenciaEntrega: preferenciaEntrega,
          limiteCredito: limiteCredito,
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

  /// Returns a shallow copy of this [Cliente]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Cliente copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? telefone,
    Object? email = _Undefined,
    Object? documento = _Undefined,
    String? observacoes,
    bool? ativo,
    Object? apelido = _Undefined,
    Object? dataNascimento = _Undefined,
    bool? aceitaWhatsapp,
    bool? aceitaMarketing,
    Object? preferenciaEntrega = _Undefined,
    Object? limiteCredito = _Undefined,
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
    return Cliente(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email is String? ? email : this.email,
      documento: documento is String? ? documento : this.documento,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      apelido: apelido is String? ? apelido : this.apelido,
      dataNascimento:
          dataNascimento is DateTime? ? dataNascimento : this.dataNascimento,
      aceitaWhatsapp: aceitaWhatsapp ?? this.aceitaWhatsapp,
      aceitaMarketing: aceitaMarketing ?? this.aceitaMarketing,
      preferenciaEntrega: preferenciaEntrega is String?
          ? preferenciaEntrega
          : this.preferenciaEntrega,
      limiteCredito: limiteCredito is int? ? limiteCredito : this.limiteCredito,
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
