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

abstract class EstoqueProduto
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EstoqueProduto._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.produtoId,
    int? quantidadeAtual,
    int? quantidadeMinima,
    int? quantidadeMaxima,
    String? unidade,
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
        quantidadeAtual = quantidadeAtual ?? 0,
        quantidadeMinima = quantidadeMinima ?? 0,
        quantidadeMaxima = quantidadeMaxima ?? 9999,
        unidade = unidade ?? 'un';

  factory EstoqueProduto({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue produtoId,
    int? quantidadeAtual,
    int? quantidadeMinima,
    int? quantidadeMaxima,
    String? unidade,
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
  }) = _EstoqueProdutoImpl;

  factory EstoqueProduto.fromJson(Map<String, dynamic> jsonSerialization) {
    return EstoqueProduto(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      produtoId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['produtoId']),
      quantidadeAtual: jsonSerialization['quantidadeAtual'] as int,
      quantidadeMinima: jsonSerialization['quantidadeMinima'] as int,
      quantidadeMaxima: jsonSerialization['quantidadeMaxima'] as int,
      unidade: jsonSerialization['unidade'] as String,
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

  static final t = EstoqueProdutoTable();

  static const db = EstoqueProdutoRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue produtoId;

  int quantidadeAtual;

  int quantidadeMinima;

  int quantidadeMaxima;

  String unidade;

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

  /// Returns a shallow copy of this [EstoqueProduto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EstoqueProduto copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? produtoId,
    int? quantidadeAtual,
    int? quantidadeMinima,
    int? quantidadeMaxima,
    String? unidade,
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
      'produtoId': produtoId.toJson(),
      'quantidadeAtual': quantidadeAtual,
      'quantidadeMinima': quantidadeMinima,
      'quantidadeMaxima': quantidadeMaxima,
      'unidade': unidade,
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
      'produtoId': produtoId.toJson(),
      'quantidadeAtual': quantidadeAtual,
      'quantidadeMinima': quantidadeMinima,
      'quantidadeMaxima': quantidadeMaxima,
      'unidade': unidade,
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

  static EstoqueProdutoInclude include() {
    return EstoqueProdutoInclude._();
  }

  static EstoqueProdutoIncludeList includeList({
    _i1.WhereExpressionBuilder<EstoqueProdutoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EstoqueProdutoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EstoqueProdutoTable>? orderByList,
    EstoqueProdutoInclude? include,
  }) {
    return EstoqueProdutoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EstoqueProduto.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EstoqueProduto.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EstoqueProdutoImpl extends EstoqueProduto {
  _EstoqueProdutoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue produtoId,
    int? quantidadeAtual,
    int? quantidadeMinima,
    int? quantidadeMaxima,
    String? unidade,
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
          quantidadeAtual: quantidadeAtual,
          quantidadeMinima: quantidadeMinima,
          quantidadeMaxima: quantidadeMaxima,
          unidade: unidade,
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

  /// Returns a shallow copy of this [EstoqueProduto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EstoqueProduto copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? produtoId,
    int? quantidadeAtual,
    int? quantidadeMinima,
    int? quantidadeMaxima,
    String? unidade,
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
    return EstoqueProduto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      produtoId: produtoId ?? this.produtoId,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      quantidadeMaxima: quantidadeMaxima ?? this.quantidadeMaxima,
      unidade: unidade ?? this.unidade,
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

class EstoqueProdutoTable extends _i1.Table<_i1.UuidValue> {
  EstoqueProdutoTable({super.tableRelation})
      : super(tableName: 'estoque_produto') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    produtoId = _i1.ColumnUuid(
      'produtoId',
      this,
    );
    quantidadeAtual = _i1.ColumnInt(
      'quantidadeAtual',
      this,
      hasDefault: true,
    );
    quantidadeMinima = _i1.ColumnInt(
      'quantidadeMinima',
      this,
      hasDefault: true,
    );
    quantidadeMaxima = _i1.ColumnInt(
      'quantidadeMaxima',
      this,
      hasDefault: true,
    );
    unidade = _i1.ColumnString(
      'unidade',
      this,
      hasDefault: true,
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

  late final _i1.ColumnUuid produtoId;

  late final _i1.ColumnInt quantidadeAtual;

  late final _i1.ColumnInt quantidadeMinima;

  late final _i1.ColumnInt quantidadeMaxima;

  late final _i1.ColumnString unidade;

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
        produtoId,
        quantidadeAtual,
        quantidadeMinima,
        quantidadeMaxima,
        unidade,
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

class EstoqueProdutoInclude extends _i1.IncludeObject {
  EstoqueProdutoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EstoqueProduto.t;
}

class EstoqueProdutoIncludeList extends _i1.IncludeList {
  EstoqueProdutoIncludeList._({
    _i1.WhereExpressionBuilder<EstoqueProdutoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EstoqueProduto.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EstoqueProduto.t;
}

class EstoqueProdutoRepository {
  const EstoqueProdutoRepository._();

  /// Returns a list of [EstoqueProduto]s matching the given query parameters.
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
  Future<List<EstoqueProduto>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EstoqueProdutoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EstoqueProdutoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EstoqueProdutoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EstoqueProduto>(
      where: where?.call(EstoqueProduto.t),
      orderBy: orderBy?.call(EstoqueProduto.t),
      orderByList: orderByList?.call(EstoqueProduto.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EstoqueProduto] matching the given query parameters.
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
  Future<EstoqueProduto?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EstoqueProdutoTable>? where,
    int? offset,
    _i1.OrderByBuilder<EstoqueProdutoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EstoqueProdutoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EstoqueProduto>(
      where: where?.call(EstoqueProduto.t),
      orderBy: orderBy?.call(EstoqueProduto.t),
      orderByList: orderByList?.call(EstoqueProduto.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EstoqueProduto] by its [id] or null if no such row exists.
  Future<EstoqueProduto?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EstoqueProduto>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EstoqueProduto]s in the list and returns the inserted rows.
  ///
  /// The returned [EstoqueProduto]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EstoqueProduto>> insert(
    _i1.Session session,
    List<EstoqueProduto> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EstoqueProduto>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EstoqueProduto] and returns the inserted row.
  ///
  /// The returned [EstoqueProduto] will have its `id` field set.
  Future<EstoqueProduto> insertRow(
    _i1.Session session,
    EstoqueProduto row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EstoqueProduto>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EstoqueProduto]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EstoqueProduto>> update(
    _i1.Session session,
    List<EstoqueProduto> rows, {
    _i1.ColumnSelections<EstoqueProdutoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EstoqueProduto>(
      rows,
      columns: columns?.call(EstoqueProduto.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EstoqueProduto]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EstoqueProduto> updateRow(
    _i1.Session session,
    EstoqueProduto row, {
    _i1.ColumnSelections<EstoqueProdutoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EstoqueProduto>(
      row,
      columns: columns?.call(EstoqueProduto.t),
      transaction: transaction,
    );
  }

  /// Deletes all [EstoqueProduto]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EstoqueProduto>> delete(
    _i1.Session session,
    List<EstoqueProduto> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EstoqueProduto>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EstoqueProduto].
  Future<EstoqueProduto> deleteRow(
    _i1.Session session,
    EstoqueProduto row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EstoqueProduto>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EstoqueProduto>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EstoqueProdutoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EstoqueProduto>(
      where: where(EstoqueProduto.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EstoqueProdutoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EstoqueProduto>(
      where: where?.call(EstoqueProduto.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
