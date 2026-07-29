/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class Produto
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
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

  static final t = ProdutoTable();

  static const db = ProdutoRepository._();

  @override
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

  @override
  _i1.Table<_i1.UuidValue> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static ProdutoInclude include() {
    return ProdutoInclude._();
  }

  static ProdutoIncludeList includeList({
    _i1.WhereExpressionBuilder<ProdutoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProdutoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProdutoTable>? orderByList,
    ProdutoInclude? include,
  }) {
    return ProdutoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Produto.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Produto.t),
      include: include,
    );
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

class ProdutoTable extends _i1.Table<_i1.UuidValue> {
  ProdutoTable({super.tableRelation}) : super(tableName: 'produto') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    codigo = _i1.ColumnString(
      'codigo',
      this,
    );
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    descricao = _i1.ColumnString(
      'descricao',
      this,
    );
    categoriaId = _i1.ColumnUuid(
      'categoriaId',
      this,
    );
    unidadeVenda = _i1.ColumnString(
      'unidadeVenda',
      this,
    );
    statusComercial = _i1.ColumnString(
      'statusComercial',
      this,
    );
    tempoMedioMinutos = _i1.ColumnInt(
      'tempoMedioMinutos',
      this,
    );
    controlaEstoque = _i1.ColumnBool(
      'controlaEstoque',
      this,
    );
    ordemProducao = _i1.ColumnInt(
      'ordemProducao',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    sku = _i1.ColumnString(
      'sku',
      this,
    );
    codigoBarras = _i1.ColumnString(
      'codigoBarras',
      this,
    );
    imagem = _i1.ColumnString(
      'imagem',
      this,
    );
    corEtiqueta = _i1.ColumnString(
      'corEtiqueta',
      this,
    );
    metadata = _i1.ColumnString(
      'metadata',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    createdBy = _i1.ColumnUuid(
      'createdBy',
      this,
    );
    updatedBy = _i1.ColumnUuid(
      'updatedBy',
      this,
    );
    deletedAt = _i1.ColumnDateTime(
      'deletedAt',
      this,
    );
    deletedBy = _i1.ColumnUuid(
      'deletedBy',
      this,
    );
    syncVersion = _i1.ColumnInt(
      'syncVersion',
      this,
    );
    originDeviceId = _i1.ColumnString(
      'originDeviceId',
      this,
    );
    lastModifiedByDevice = _i1.ColumnString(
      'lastModifiedByDevice',
      this,
    );
    entityHash = _i1.ColumnString(
      'entityHash',
      this,
    );
  }

  late final _i1.ColumnString tenantId;

  late final _i1.ColumnString codigo;

  late final _i1.ColumnString nome;

  late final _i1.ColumnString descricao;

  late final _i1.ColumnUuid categoriaId;

  late final _i1.ColumnString unidadeVenda;

  late final _i1.ColumnString statusComercial;

  late final _i1.ColumnInt tempoMedioMinutos;

  late final _i1.ColumnBool controlaEstoque;

  late final _i1.ColumnInt ordemProducao;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnString sku;

  late final _i1.ColumnString codigoBarras;

  late final _i1.ColumnString imagem;

  late final _i1.ColumnString corEtiqueta;

  late final _i1.ColumnString metadata;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid createdBy;

  late final _i1.ColumnUuid updatedBy;

  late final _i1.ColumnDateTime deletedAt;

  late final _i1.ColumnUuid deletedBy;

  late final _i1.ColumnInt syncVersion;

  late final _i1.ColumnString originDeviceId;

  late final _i1.ColumnString lastModifiedByDevice;

  late final _i1.ColumnString entityHash;

  @override
  List<_i1.Column> get columns => [
        id,
        tenantId,
        codigo,
        nome,
        descricao,
        categoriaId,
        unidadeVenda,
        statusComercial,
        tempoMedioMinutos,
        controlaEstoque,
        ordemProducao,
        ativo,
        sku,
        codigoBarras,
        imagem,
        corEtiqueta,
        metadata,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        deletedAt,
        deletedBy,
        syncVersion,
        originDeviceId,
        lastModifiedByDevice,
        entityHash,
      ];
}

class ProdutoInclude extends _i1.IncludeObject {
  ProdutoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => Produto.t;
}

class ProdutoIncludeList extends _i1.IncludeList {
  ProdutoIncludeList._({
    _i1.WhereExpressionBuilder<ProdutoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Produto.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => Produto.t;
}

class ProdutoRepository {
  const ProdutoRepository._();

  /// Returns a list of [Produto]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Produto>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ProdutoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProdutoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProdutoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Produto>(
      where: where?.call(Produto.t),
      orderBy: orderBy?.call(Produto.t),
      orderByList: orderByList?.call(Produto.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Produto] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Produto?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ProdutoTable>? where,
    int? offset,
    _i1.OrderByBuilder<ProdutoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProdutoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Produto>(
      where: where?.call(Produto.t),
      orderBy: orderBy?.call(Produto.t),
      orderByList: orderByList?.call(Produto.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Produto] by its [id] or null if no such row exists.
  Future<Produto?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Produto>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Produto]s in the list and returns the inserted rows.
  ///
  /// The returned [Produto]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Produto>> insert(
    _i1.Session session,
    List<Produto> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Produto>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Produto] and returns the inserted row.
  ///
  /// The returned [Produto] will have its `id` field set.
  Future<Produto> insertRow(
    _i1.Session session,
    Produto row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Produto>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Produto]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Produto>> update(
    _i1.Session session,
    List<Produto> rows, {
    _i1.ColumnSelections<ProdutoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Produto>(
      rows,
      columns: columns?.call(Produto.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Produto]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Produto> updateRow(
    _i1.Session session,
    Produto row, {
    _i1.ColumnSelections<ProdutoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Produto>(
      row,
      columns: columns?.call(Produto.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Produto]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Produto>> delete(
    _i1.Session session,
    List<Produto> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Produto>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Produto].
  Future<Produto> deleteRow(
    _i1.Session session,
    Produto row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Produto>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Produto>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ProdutoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Produto>(
      where: where(Produto.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ProdutoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Produto>(
      where: where?.call(Produto.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
