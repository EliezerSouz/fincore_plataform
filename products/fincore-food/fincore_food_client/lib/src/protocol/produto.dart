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

abstract class Produto implements _i1.SerializableModel {
  Produto._({
    _i1.UuidValue? id,
    required this.tenantId,
    this.codigo,
    required this.nome,
    this.descricao,
    required this.categoriaId,
    required this.unidadeVenda,
    required this.statusComercial,
    required this.tempoMedioMinutos,
    required this.controlaEstoque,
    required this.ordemProducao,
    required this.ativo,
    this.sku,
    this.codigoBarras,
    this.imagem,
    this.corEtiqueta,
    this.metadata,
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

  factory Produto({
    _i1.UuidValue? id,
    required String tenantId,
    String? codigo,
    required String nome,
    String? descricao,
    required _i1.UuidValue categoriaId,
    required String unidadeVenda,
    required String statusComercial,
    required int tempoMedioMinutos,
    required bool controlaEstoque,
    required int ordemProducao,
    required bool ativo,
    String? sku,
    String? codigoBarras,
    String? imagem,
    String? corEtiqueta,
    String? metadata,
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
  }) = _ProdutoImpl;

  factory Produto.fromJson(Map<String, dynamic> jsonSerialization) {
    return Produto(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      codigo: jsonSerialization['codigo'] as String?,
      nome: jsonSerialization['nome'] as String,
      descricao: jsonSerialization['descricao'] as String?,
      categoriaId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['categoriaId']),
      unidadeVenda: jsonSerialization['unidadeVenda'] as String,
      statusComercial: jsonSerialization['statusComercial'] as String,
      tempoMedioMinutos: jsonSerialization['tempoMedioMinutos'] as int,
      controlaEstoque: jsonSerialization['controlaEstoque'] as bool,
      ordemProducao: jsonSerialization['ordemProducao'] as int,
      ativo: jsonSerialization['ativo'] as bool,
      sku: jsonSerialization['sku'] as String?,
      codigoBarras: jsonSerialization['codigoBarras'] as String?,
      imagem: jsonSerialization['imagem'] as String?,
      corEtiqueta: jsonSerialization['corEtiqueta'] as String?,
      metadata: jsonSerialization['metadata'] as String?,
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

  String? codigo;

  String nome;

  String? descricao;

  _i1.UuidValue categoriaId;

  String unidadeVenda;

  String statusComercial;

  int tempoMedioMinutos;

  bool controlaEstoque;

  int ordemProducao;

  bool ativo;

  String? sku;

  String? codigoBarras;

  String? imagem;

  String? corEtiqueta;

  String? metadata;

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

  /// Returns a shallow copy of this [Produto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Produto copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? codigo,
    String? nome,
    String? descricao,
    _i1.UuidValue? categoriaId,
    String? unidadeVenda,
    String? statusComercial,
    int? tempoMedioMinutos,
    bool? controlaEstoque,
    int? ordemProducao,
    bool? ativo,
    String? sku,
    String? codigoBarras,
    String? imagem,
    String? corEtiqueta,
    String? metadata,
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
      if (codigo != null) 'codigo': codigo,
      'nome': nome,
      if (descricao != null) 'descricao': descricao,
      'categoriaId': categoriaId.toJson(),
      'unidadeVenda': unidadeVenda,
      'statusComercial': statusComercial,
      'tempoMedioMinutos': tempoMedioMinutos,
      'controlaEstoque': controlaEstoque,
      'ordemProducao': ordemProducao,
      'ativo': ativo,
      if (sku != null) 'sku': sku,
      if (codigoBarras != null) 'codigoBarras': codigoBarras,
      if (imagem != null) 'imagem': imagem,
      if (corEtiqueta != null) 'corEtiqueta': corEtiqueta,
      if (metadata != null) 'metadata': metadata,
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

class _ProdutoImpl extends Produto {
  _ProdutoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    String? codigo,
    required String nome,
    String? descricao,
    required _i1.UuidValue categoriaId,
    required String unidadeVenda,
    required String statusComercial,
    required int tempoMedioMinutos,
    required bool controlaEstoque,
    required int ordemProducao,
    required bool ativo,
    String? sku,
    String? codigoBarras,
    String? imagem,
    String? corEtiqueta,
    String? metadata,
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
          codigo: codigo,
          nome: nome,
          descricao: descricao,
          categoriaId: categoriaId,
          unidadeVenda: unidadeVenda,
          statusComercial: statusComercial,
          tempoMedioMinutos: tempoMedioMinutos,
          controlaEstoque: controlaEstoque,
          ordemProducao: ordemProducao,
          ativo: ativo,
          sku: sku,
          codigoBarras: codigoBarras,
          imagem: imagem,
          corEtiqueta: corEtiqueta,
          metadata: metadata,
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

  /// Returns a shallow copy of this [Produto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Produto copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    Object? codigo = _Undefined,
    String? nome,
    Object? descricao = _Undefined,
    _i1.UuidValue? categoriaId,
    String? unidadeVenda,
    String? statusComercial,
    int? tempoMedioMinutos,
    bool? controlaEstoque,
    int? ordemProducao,
    bool? ativo,
    Object? sku = _Undefined,
    Object? codigoBarras = _Undefined,
    Object? imagem = _Undefined,
    Object? corEtiqueta = _Undefined,
    Object? metadata = _Undefined,
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
    return Produto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      codigo: codigo is String? ? codigo : this.codigo,
      nome: nome ?? this.nome,
      descricao: descricao is String? ? descricao : this.descricao,
      categoriaId: categoriaId ?? this.categoriaId,
      unidadeVenda: unidadeVenda ?? this.unidadeVenda,
      statusComercial: statusComercial ?? this.statusComercial,
      tempoMedioMinutos: tempoMedioMinutos ?? this.tempoMedioMinutos,
      controlaEstoque: controlaEstoque ?? this.controlaEstoque,
      ordemProducao: ordemProducao ?? this.ordemProducao,
      ativo: ativo ?? this.ativo,
      sku: sku is String? ? sku : this.sku,
      codigoBarras: codigoBarras is String? ? codigoBarras : this.codigoBarras,
      imagem: imagem is String? ? imagem : this.imagem,
      corEtiqueta: corEtiqueta is String? ? corEtiqueta : this.corEtiqueta,
      metadata: metadata is String? ? metadata : this.metadata,
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
