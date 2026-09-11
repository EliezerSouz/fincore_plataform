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

abstract class LancamentoFinanceiro implements _i1.SerializableModel {
  LancamentoFinanceiro._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.sessaoCaixaId,
    this.pedidoId,
    required this.tipo,
    this.formaPagamentoId,
    this.formaPagamentoNome,
    required this.valorCentavos,
    String? descricao,
    this.operadorId,
    required this.dataHora,
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
        descricao = descricao ?? '';

  factory LancamentoFinanceiro({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue sessaoCaixaId,
    _i1.UuidValue? pedidoId,
    required String tipo,
    _i1.UuidValue? formaPagamentoId,
    String? formaPagamentoNome,
    required int valorCentavos,
    String? descricao,
    _i1.UuidValue? operadorId,
    required DateTime dataHora,
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
  }) = _LancamentoFinanceiroImpl;

  factory LancamentoFinanceiro.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return LancamentoFinanceiro(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      sessaoCaixaId: _i1.UuidValueJsonExtension.fromJson(
          jsonSerialization['sessaoCaixaId']),
      pedidoId: jsonSerialization['pedidoId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['pedidoId']),
      tipo: jsonSerialization['tipo'] as String,
      formaPagamentoId: jsonSerialization['formaPagamentoId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['formaPagamentoId']),
      formaPagamentoNome: jsonSerialization['formaPagamentoNome'] as String?,
      valorCentavos: jsonSerialization['valorCentavos'] as int,
      descricao: jsonSerialization['descricao'] as String,
      operadorId: jsonSerialization['operadorId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['operadorId']),
      dataHora:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataHora']),
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

  _i1.UuidValue sessaoCaixaId;

  _i1.UuidValue? pedidoId;

  String tipo;

  _i1.UuidValue? formaPagamentoId;

  String? formaPagamentoNome;

  int valorCentavos;

  String descricao;

  _i1.UuidValue? operadorId;

  DateTime dataHora;

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

  /// Returns a shallow copy of this [LancamentoFinanceiro]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LancamentoFinanceiro copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? sessaoCaixaId,
    _i1.UuidValue? pedidoId,
    String? tipo,
    _i1.UuidValue? formaPagamentoId,
    String? formaPagamentoNome,
    int? valorCentavos,
    String? descricao,
    _i1.UuidValue? operadorId,
    DateTime? dataHora,
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
      'sessaoCaixaId': sessaoCaixaId.toJson(),
      if (pedidoId != null) 'pedidoId': pedidoId?.toJson(),
      'tipo': tipo,
      if (formaPagamentoId != null)
        'formaPagamentoId': formaPagamentoId?.toJson(),
      if (formaPagamentoNome != null) 'formaPagamentoNome': formaPagamentoNome,
      'valorCentavos': valorCentavos,
      'descricao': descricao,
      if (operadorId != null) 'operadorId': operadorId?.toJson(),
      'dataHora': dataHora.toJson(),
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

class _LancamentoFinanceiroImpl extends LancamentoFinanceiro {
  _LancamentoFinanceiroImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue sessaoCaixaId,
    _i1.UuidValue? pedidoId,
    required String tipo,
    _i1.UuidValue? formaPagamentoId,
    String? formaPagamentoNome,
    required int valorCentavos,
    String? descricao,
    _i1.UuidValue? operadorId,
    required DateTime dataHora,
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
          sessaoCaixaId: sessaoCaixaId,
          pedidoId: pedidoId,
          tipo: tipo,
          formaPagamentoId: formaPagamentoId,
          formaPagamentoNome: formaPagamentoNome,
          valorCentavos: valorCentavos,
          descricao: descricao,
          operadorId: operadorId,
          dataHora: dataHora,
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

  /// Returns a shallow copy of this [LancamentoFinanceiro]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LancamentoFinanceiro copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? sessaoCaixaId,
    Object? pedidoId = _Undefined,
    String? tipo,
    Object? formaPagamentoId = _Undefined,
    Object? formaPagamentoNome = _Undefined,
    int? valorCentavos,
    String? descricao,
    Object? operadorId = _Undefined,
    DateTime? dataHora,
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
    return LancamentoFinanceiro(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      sessaoCaixaId: sessaoCaixaId ?? this.sessaoCaixaId,
      pedidoId: pedidoId is _i1.UuidValue? ? pedidoId : this.pedidoId,
      tipo: tipo ?? this.tipo,
      formaPagamentoId: formaPagamentoId is _i1.UuidValue?
          ? formaPagamentoId
          : this.formaPagamentoId,
      formaPagamentoNome: formaPagamentoNome is String?
          ? formaPagamentoNome
          : this.formaPagamentoNome,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      descricao: descricao ?? this.descricao,
      operadorId: operadorId is _i1.UuidValue? ? operadorId : this.operadorId,
      dataHora: dataHora ?? this.dataHora,
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
