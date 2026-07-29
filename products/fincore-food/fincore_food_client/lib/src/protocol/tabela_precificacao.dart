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

abstract class TabelaPrecificacao implements _i1.SerializableModel {
  TabelaPrecificacao._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.nome,
    required this.descricao,
    required this.tipoPolitica,
    required this.prioridade,
    required this.ativo,
    this.vigenciaInicio,
    this.vigenciaFim,
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

  factory TabelaPrecificacao({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String descricao,
    required String tipoPolitica,
    required int prioridade,
    required bool ativo,
    DateTime? vigenciaInicio,
    DateTime? vigenciaFim,
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
  }) = _TabelaPrecificacaoImpl;

  factory TabelaPrecificacao.fromJson(Map<String, dynamic> jsonSerialization) {
    return TabelaPrecificacao(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      nome: jsonSerialization['nome'] as String,
      descricao: jsonSerialization['descricao'] as String,
      tipoPolitica: jsonSerialization['tipoPolitica'] as String,
      prioridade: jsonSerialization['prioridade'] as int,
      ativo: jsonSerialization['ativo'] as bool,
      vigenciaInicio: jsonSerialization['vigenciaInicio'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['vigenciaInicio']),
      vigenciaFim: jsonSerialization['vigenciaFim'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['vigenciaFim']),
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

  String descricao;

  String tipoPolitica;

  int prioridade;

  bool ativo;

  DateTime? vigenciaInicio;

  DateTime? vigenciaFim;

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

  /// Returns a shallow copy of this [TabelaPrecificacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TabelaPrecificacao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? descricao,
    String? tipoPolitica,
    int? prioridade,
    bool? ativo,
    DateTime? vigenciaInicio,
    DateTime? vigenciaFim,
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
      'descricao': descricao,
      'tipoPolitica': tipoPolitica,
      'prioridade': prioridade,
      'ativo': ativo,
      if (vigenciaInicio != null) 'vigenciaInicio': vigenciaInicio?.toJson(),
      if (vigenciaFim != null) 'vigenciaFim': vigenciaFim?.toJson(),
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

class _TabelaPrecificacaoImpl extends TabelaPrecificacao {
  _TabelaPrecificacaoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String descricao,
    required String tipoPolitica,
    required int prioridade,
    required bool ativo,
    DateTime? vigenciaInicio,
    DateTime? vigenciaFim,
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
          descricao: descricao,
          tipoPolitica: tipoPolitica,
          prioridade: prioridade,
          ativo: ativo,
          vigenciaInicio: vigenciaInicio,
          vigenciaFim: vigenciaFim,
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

  /// Returns a shallow copy of this [TabelaPrecificacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TabelaPrecificacao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? descricao,
    String? tipoPolitica,
    int? prioridade,
    bool? ativo,
    Object? vigenciaInicio = _Undefined,
    Object? vigenciaFim = _Undefined,
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
    return TabelaPrecificacao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipoPolitica: tipoPolitica ?? this.tipoPolitica,
      prioridade: prioridade ?? this.prioridade,
      ativo: ativo ?? this.ativo,
      vigenciaInicio:
          vigenciaInicio is DateTime? ? vigenciaInicio : this.vigenciaInicio,
      vigenciaFim: vigenciaFim is DateTime? ? vigenciaFim : this.vigenciaFim,
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
