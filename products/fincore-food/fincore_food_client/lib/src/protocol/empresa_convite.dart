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

abstract class EmpresaConvite implements _i1.SerializableModel {
  EmpresaConvite._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.status,
    required this.expiracaoEm,
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

  factory EmpresaConvite({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String email,
    required String role,
    required String status,
    required DateTime expiracaoEm,
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
  }) = _EmpresaConviteImpl;

  factory EmpresaConvite.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmpresaConvite(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['tenantId']),
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
      status: jsonSerialization['status'] as String,
      expiracaoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiracaoEm']),
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

  _i1.UuidValue tenantId;

  String email;

  String role;

  String status;

  DateTime expiracaoEm;

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

  /// Returns a shallow copy of this [EmpresaConvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmpresaConvite copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? email,
    String? role,
    String? status,
    DateTime? expiracaoEm,
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
      'tenantId': tenantId.toJson(),
      'email': email,
      'role': role,
      'status': status,
      'expiracaoEm': expiracaoEm.toJson(),
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

class _EmpresaConviteImpl extends EmpresaConvite {
  _EmpresaConviteImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String email,
    required String role,
    required String status,
    required DateTime expiracaoEm,
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
          email: email,
          role: role,
          status: status,
          expiracaoEm: expiracaoEm,
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

  /// Returns a shallow copy of this [EmpresaConvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmpresaConvite copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? email,
    String? role,
    String? status,
    DateTime? expiracaoEm,
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
    return EmpresaConvite(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      expiracaoEm: expiracaoEm ?? this.expiracaoEm,
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
