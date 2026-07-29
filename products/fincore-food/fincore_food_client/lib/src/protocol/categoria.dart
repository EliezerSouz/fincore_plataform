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

abstract class Categoria implements _i1.SerializableModel {
  Categoria._({
    _i1.UuidValue? id,
    required this.tenantId,
    this.parentId,
    required this.nome,
    required this.descricao,
    required this.ordemExibicao,
    required this.ativo,
    this.icone,
    this.cor,
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

  factory Categoria({
    _i1.UuidValue? id,
    required String tenantId,
    _i1.UuidValue? parentId,
    required String nome,
    required String descricao,
    required int ordemExibicao,
    required bool ativo,
    String? icone,
    String? cor,
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
  }) = _CategoriaImpl;

  factory Categoria.fromJson(Map<String, dynamic> jsonSerialization) {
    return Categoria(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      parentId: jsonSerialization['parentId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['parentId']),
      nome: jsonSerialization['nome'] as String,
      descricao: jsonSerialization['descricao'] as String,
      ordemExibicao: jsonSerialization['ordemExibicao'] as int,
      ativo: jsonSerialization['ativo'] as bool,
      icone: jsonSerialization['icone'] as String?,
      cor: jsonSerialization['cor'] as String?,
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

  _i1.UuidValue? parentId;

  String nome;

  String descricao;

  int ordemExibicao;

  bool ativo;

  String? icone;

  String? cor;

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

  /// Returns a shallow copy of this [Categoria]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Categoria copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? parentId,
    String? nome,
    String? descricao,
    int? ordemExibicao,
    bool? ativo,
    String? icone,
    String? cor,
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
      if (parentId != null) 'parentId': parentId?.toJson(),
      'nome': nome,
      'descricao': descricao,
      'ordemExibicao': ordemExibicao,
      'ativo': ativo,
      if (icone != null) 'icone': icone,
      if (cor != null) 'cor': cor,
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

class _CategoriaImpl extends Categoria {
  _CategoriaImpl({
    _i1.UuidValue? id,
    required String tenantId,
    _i1.UuidValue? parentId,
    required String nome,
    required String descricao,
    required int ordemExibicao,
    required bool ativo,
    String? icone,
    String? cor,
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
          parentId: parentId,
          nome: nome,
          descricao: descricao,
          ordemExibicao: ordemExibicao,
          ativo: ativo,
          icone: icone,
          cor: cor,
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

  /// Returns a shallow copy of this [Categoria]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Categoria copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    Object? parentId = _Undefined,
    String? nome,
    String? descricao,
    int? ordemExibicao,
    bool? ativo,
    Object? icone = _Undefined,
    Object? cor = _Undefined,
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
    return Categoria(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      parentId: parentId is _i1.UuidValue? ? parentId : this.parentId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      ativo: ativo ?? this.ativo,
      icone: icone is String? ? icone : this.icone,
      cor: cor is String? ? cor : this.cor,
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
