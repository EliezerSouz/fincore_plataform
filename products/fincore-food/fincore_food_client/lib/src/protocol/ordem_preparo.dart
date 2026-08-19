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

abstract class OrdemPreparo implements _i1.SerializableModel {
  OrdemPreparo._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.pedidoId,
    required this.itensJson,
    required this.status,
    required this.prioridade,
    this.operadorId,
    required this.criadaEm,
    this.iniciadaEm,
    this.concluidaEm,
    this.canceladaEm,
    required this.tempoEstimadoSegundos,
    this.observacoes,
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

  factory OrdemPreparo({
    _i1.UuidValue? id,
    required String tenantId,
    required String pedidoId,
    required String itensJson,
    required String status,
    required String prioridade,
    String? operadorId,
    required DateTime criadaEm,
    DateTime? iniciadaEm,
    DateTime? concluidaEm,
    DateTime? canceladaEm,
    required int tempoEstimadoSegundos,
    String? observacoes,
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
  }) = _OrdemPreparoImpl;

  factory OrdemPreparo.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrdemPreparo(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      pedidoId: jsonSerialization['pedidoId'] as String,
      itensJson: jsonSerialization['itensJson'] as String,
      status: jsonSerialization['status'] as String,
      prioridade: jsonSerialization['prioridade'] as String,
      operadorId: jsonSerialization['operadorId'] as String?,
      criadaEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['criadaEm']),
      iniciadaEm: jsonSerialization['iniciadaEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['iniciadaEm']),
      concluidaEm: jsonSerialization['concluidaEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['concluidaEm']),
      canceladaEm: jsonSerialization['canceladaEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['canceladaEm']),
      tempoEstimadoSegundos: jsonSerialization['tempoEstimadoSegundos'] as int,
      observacoes: jsonSerialization['observacoes'] as String?,
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

  String pedidoId;

  String itensJson;

  String status;

  String prioridade;

  String? operadorId;

  DateTime criadaEm;

  DateTime? iniciadaEm;

  DateTime? concluidaEm;

  DateTime? canceladaEm;

  int tempoEstimadoSegundos;

  String? observacoes;

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

  /// Returns a shallow copy of this [OrdemPreparo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OrdemPreparo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? pedidoId,
    String? itensJson,
    String? status,
    String? prioridade,
    String? operadorId,
    DateTime? criadaEm,
    DateTime? iniciadaEm,
    DateTime? concluidaEm,
    DateTime? canceladaEm,
    int? tempoEstimadoSegundos,
    String? observacoes,
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
      'pedidoId': pedidoId,
      'itensJson': itensJson,
      'status': status,
      'prioridade': prioridade,
      if (operadorId != null) 'operadorId': operadorId,
      'criadaEm': criadaEm.toJson(),
      if (iniciadaEm != null) 'iniciadaEm': iniciadaEm?.toJson(),
      if (concluidaEm != null) 'concluidaEm': concluidaEm?.toJson(),
      if (canceladaEm != null) 'canceladaEm': canceladaEm?.toJson(),
      'tempoEstimadoSegundos': tempoEstimadoSegundos,
      if (observacoes != null) 'observacoes': observacoes,
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

class _OrdemPreparoImpl extends OrdemPreparo {
  _OrdemPreparoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String pedidoId,
    required String itensJson,
    required String status,
    required String prioridade,
    String? operadorId,
    required DateTime criadaEm,
    DateTime? iniciadaEm,
    DateTime? concluidaEm,
    DateTime? canceladaEm,
    required int tempoEstimadoSegundos,
    String? observacoes,
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
          pedidoId: pedidoId,
          itensJson: itensJson,
          status: status,
          prioridade: prioridade,
          operadorId: operadorId,
          criadaEm: criadaEm,
          iniciadaEm: iniciadaEm,
          concluidaEm: concluidaEm,
          canceladaEm: canceladaEm,
          tempoEstimadoSegundos: tempoEstimadoSegundos,
          observacoes: observacoes,
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

  /// Returns a shallow copy of this [OrdemPreparo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OrdemPreparo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? pedidoId,
    String? itensJson,
    String? status,
    String? prioridade,
    Object? operadorId = _Undefined,
    DateTime? criadaEm,
    Object? iniciadaEm = _Undefined,
    Object? concluidaEm = _Undefined,
    Object? canceladaEm = _Undefined,
    int? tempoEstimadoSegundos,
    Object? observacoes = _Undefined,
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
    return OrdemPreparo(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      pedidoId: pedidoId ?? this.pedidoId,
      itensJson: itensJson ?? this.itensJson,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      operadorId: operadorId is String? ? operadorId : this.operadorId,
      criadaEm: criadaEm ?? this.criadaEm,
      iniciadaEm: iniciadaEm is DateTime? ? iniciadaEm : this.iniciadaEm,
      concluidaEm: concluidaEm is DateTime? ? concluidaEm : this.concluidaEm,
      canceladaEm: canceladaEm is DateTime? ? canceladaEm : this.canceladaEm,
      tempoEstimadoSegundos:
          tempoEstimadoSegundos ?? this.tempoEstimadoSegundos,
      observacoes: observacoes is String? ? observacoes : this.observacoes,
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
