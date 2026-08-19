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

abstract class LoteInsumo implements _i1.SerializableModel {
  LoteInsumo._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.produtoId,
    this.codigoLote,
    required this.quantidadeInicial,
    required this.quantidadeDisponivel,
    required this.quantidadeReservada,
    required this.unidade,
    this.dataValidade,
    required this.dataEntrada,
    required this.statusLote,
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

  factory LoteInsumo({
    _i1.UuidValue? id,
    required String tenantId,
    required String produtoId,
    String? codigoLote,
    required int quantidadeInicial,
    required int quantidadeDisponivel,
    required int quantidadeReservada,
    required String unidade,
    DateTime? dataValidade,
    required DateTime dataEntrada,
    required String statusLote,
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
  }) = _LoteInsumoImpl;

  factory LoteInsumo.fromJson(Map<String, dynamic> jsonSerialization) {
    return LoteInsumo(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      produtoId: jsonSerialization['produtoId'] as String,
      codigoLote: jsonSerialization['codigoLote'] as String?,
      quantidadeInicial: jsonSerialization['quantidadeInicial'] as int,
      quantidadeDisponivel: jsonSerialization['quantidadeDisponivel'] as int,
      quantidadeReservada: jsonSerialization['quantidadeReservada'] as int,
      unidade: jsonSerialization['unidade'] as String,
      dataValidade: jsonSerialization['dataValidade'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dataValidade']),
      dataEntrada:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataEntrada']),
      statusLote: jsonSerialization['statusLote'] as String,
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

  String produtoId;

  String? codigoLote;

  int quantidadeInicial;

  int quantidadeDisponivel;

  int quantidadeReservada;

  String unidade;

  DateTime? dataValidade;

  DateTime dataEntrada;

  String statusLote;

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

  /// Returns a shallow copy of this [LoteInsumo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LoteInsumo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? produtoId,
    String? codigoLote,
    int? quantidadeInicial,
    int? quantidadeDisponivel,
    int? quantidadeReservada,
    String? unidade,
    DateTime? dataValidade,
    DateTime? dataEntrada,
    String? statusLote,
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
      'produtoId': produtoId,
      if (codigoLote != null) 'codigoLote': codigoLote,
      'quantidadeInicial': quantidadeInicial,
      'quantidadeDisponivel': quantidadeDisponivel,
      'quantidadeReservada': quantidadeReservada,
      'unidade': unidade,
      if (dataValidade != null) 'dataValidade': dataValidade?.toJson(),
      'dataEntrada': dataEntrada.toJson(),
      'statusLote': statusLote,
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

class _LoteInsumoImpl extends LoteInsumo {
  _LoteInsumoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String produtoId,
    String? codigoLote,
    required int quantidadeInicial,
    required int quantidadeDisponivel,
    required int quantidadeReservada,
    required String unidade,
    DateTime? dataValidade,
    required DateTime dataEntrada,
    required String statusLote,
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
          produtoId: produtoId,
          codigoLote: codigoLote,
          quantidadeInicial: quantidadeInicial,
          quantidadeDisponivel: quantidadeDisponivel,
          quantidadeReservada: quantidadeReservada,
          unidade: unidade,
          dataValidade: dataValidade,
          dataEntrada: dataEntrada,
          statusLote: statusLote,
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

  /// Returns a shallow copy of this [LoteInsumo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LoteInsumo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? produtoId,
    Object? codigoLote = _Undefined,
    int? quantidadeInicial,
    int? quantidadeDisponivel,
    int? quantidadeReservada,
    String? unidade,
    Object? dataValidade = _Undefined,
    DateTime? dataEntrada,
    String? statusLote,
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
    return LoteInsumo(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      produtoId: produtoId ?? this.produtoId,
      codigoLote: codigoLote is String? ? codigoLote : this.codigoLote,
      quantidadeInicial: quantidadeInicial ?? this.quantidadeInicial,
      quantidadeDisponivel: quantidadeDisponivel ?? this.quantidadeDisponivel,
      quantidadeReservada: quantidadeReservada ?? this.quantidadeReservada,
      unidade: unidade ?? this.unidade,
      dataValidade:
          dataValidade is DateTime? ? dataValidade : this.dataValidade,
      dataEntrada: dataEntrada ?? this.dataEntrada,
      statusLote: statusLote ?? this.statusLote,
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
