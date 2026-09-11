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

abstract class SessaoCaixa implements _i1.SerializableModel {
  SessaoCaixa._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.operadorId,
    String? operadorNome,
    String? status,
    required this.dataAbertura,
    this.dataFechamento,
    int? valorAberturaCentavos,
    this.valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    this.diferencaCentavos,
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
  })  : id = id ?? _i1.Uuid().v4obj(),
        operadorNome = operadorNome ?? 'Operador',
        status = status ?? 'aberta',
        valorAberturaCentavos = valorAberturaCentavos ?? 0,
        totalVendasCentavos = totalVendasCentavos ?? 0,
        totalDespesasCentavos = totalDespesasCentavos ?? 0;

  factory SessaoCaixa({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue operadorId,
    String? operadorNome,
    String? status,
    required DateTime dataAbertura,
    DateTime? dataFechamento,
    int? valorAberturaCentavos,
    int? valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    int? diferencaCentavos,
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
  }) = _SessaoCaixaImpl;

  factory SessaoCaixa.fromJson(Map<String, dynamic> jsonSerialization) {
    return SessaoCaixa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      operadorId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['operadorId']),
      operadorNome: jsonSerialization['operadorNome'] as String,
      status: jsonSerialization['status'] as String,
      dataAbertura:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataAbertura']),
      dataFechamento: jsonSerialization['dataFechamento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dataFechamento']),
      valorAberturaCentavos: jsonSerialization['valorAberturaCentavos'] as int,
      valorFechamentoCentavos:
          jsonSerialization['valorFechamentoCentavos'] as int?,
      totalVendasCentavos: jsonSerialization['totalVendasCentavos'] as int,
      totalDespesasCentavos: jsonSerialization['totalDespesasCentavos'] as int,
      diferencaCentavos: jsonSerialization['diferencaCentavos'] as int?,
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

  _i1.UuidValue operadorId;

  String operadorNome;

  String status;

  DateTime dataAbertura;

  DateTime? dataFechamento;

  int valorAberturaCentavos;

  int? valorFechamentoCentavos;

  int totalVendasCentavos;

  int totalDespesasCentavos;

  int? diferencaCentavos;

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

  /// Returns a shallow copy of this [SessaoCaixa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SessaoCaixa copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? operadorId,
    String? operadorNome,
    String? status,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    int? valorAberturaCentavos,
    int? valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    int? diferencaCentavos,
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
      'operadorId': operadorId.toJson(),
      'operadorNome': operadorNome,
      'status': status,
      'dataAbertura': dataAbertura.toJson(),
      if (dataFechamento != null) 'dataFechamento': dataFechamento?.toJson(),
      'valorAberturaCentavos': valorAberturaCentavos,
      if (valorFechamentoCentavos != null)
        'valorFechamentoCentavos': valorFechamentoCentavos,
      'totalVendasCentavos': totalVendasCentavos,
      'totalDespesasCentavos': totalDespesasCentavos,
      if (diferencaCentavos != null) 'diferencaCentavos': diferencaCentavos,
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

class _SessaoCaixaImpl extends SessaoCaixa {
  _SessaoCaixaImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue operadorId,
    String? operadorNome,
    String? status,
    required DateTime dataAbertura,
    DateTime? dataFechamento,
    int? valorAberturaCentavos,
    int? valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    int? diferencaCentavos,
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
          operadorId: operadorId,
          operadorNome: operadorNome,
          status: status,
          dataAbertura: dataAbertura,
          dataFechamento: dataFechamento,
          valorAberturaCentavos: valorAberturaCentavos,
          valorFechamentoCentavos: valorFechamentoCentavos,
          totalVendasCentavos: totalVendasCentavos,
          totalDespesasCentavos: totalDespesasCentavos,
          diferencaCentavos: diferencaCentavos,
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

  /// Returns a shallow copy of this [SessaoCaixa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SessaoCaixa copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? operadorId,
    String? operadorNome,
    String? status,
    DateTime? dataAbertura,
    Object? dataFechamento = _Undefined,
    int? valorAberturaCentavos,
    Object? valorFechamentoCentavos = _Undefined,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    Object? diferencaCentavos = _Undefined,
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
    return SessaoCaixa(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      operadorId: operadorId ?? this.operadorId,
      operadorNome: operadorNome ?? this.operadorNome,
      status: status ?? this.status,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataFechamento:
          dataFechamento is DateTime? ? dataFechamento : this.dataFechamento,
      valorAberturaCentavos:
          valorAberturaCentavos ?? this.valorAberturaCentavos,
      valorFechamentoCentavos: valorFechamentoCentavos is int?
          ? valorFechamentoCentavos
          : this.valorFechamentoCentavos,
      totalVendasCentavos: totalVendasCentavos ?? this.totalVendasCentavos,
      totalDespesasCentavos:
          totalDespesasCentavos ?? this.totalDespesasCentavos,
      diferencaCentavos: diferencaCentavos is int?
          ? diferencaCentavos
          : this.diferencaCentavos,
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
