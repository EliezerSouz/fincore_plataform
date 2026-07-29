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

abstract class ItemTabelaPrecificacao
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  ItemTabelaPrecificacao._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.tabelaPrecificacaoId,
    required this.quantidadeMinima,
    this.quantidadeMaxima,
    required this.valorUnitarioCentavos,
    required this.ordem,
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

  factory ItemTabelaPrecificacao({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue tabelaPrecificacaoId,
    required int quantidadeMinima,
    int? quantidadeMaxima,
    required int valorUnitarioCentavos,
    required int ordem,
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
  }) = _ItemTabelaPrecificacaoImpl;

  factory ItemTabelaPrecificacao.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return ItemTabelaPrecificacao(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      tabelaPrecificacaoId: _i1.UuidValueJsonExtension.fromJson(
          jsonSerialization['tabelaPrecificacaoId']),
      quantidadeMinima: jsonSerialization['quantidadeMinima'] as int,
      quantidadeMaxima: jsonSerialization['quantidadeMaxima'] as int?,
      valorUnitarioCentavos: jsonSerialization['valorUnitarioCentavos'] as int,
      ordem: jsonSerialization['ordem'] as int,
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

  static final t = ItemTabelaPrecificacaoTable();

  static const db = ItemTabelaPrecificacaoRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue tabelaPrecificacaoId;

  int quantidadeMinima;

  int? quantidadeMaxima;

  int valorUnitarioCentavos;

  int ordem;

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

  /// Returns a shallow copy of this [ItemTabelaPrecificacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ItemTabelaPrecificacao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? tabelaPrecificacaoId,
    int? quantidadeMinima,
    int? quantidadeMaxima,
    int? valorUnitarioCentavos,
    int? ordem,
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
      'tabelaPrecificacaoId': tabelaPrecificacaoId.toJson(),
      'quantidadeMinima': quantidadeMinima,
      if (quantidadeMaxima != null) 'quantidadeMaxima': quantidadeMaxima,
      'valorUnitarioCentavos': valorUnitarioCentavos,
      'ordem': ordem,
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
      'tabelaPrecificacaoId': tabelaPrecificacaoId.toJson(),
      'quantidadeMinima': quantidadeMinima,
      if (quantidadeMaxima != null) 'quantidadeMaxima': quantidadeMaxima,
      'valorUnitarioCentavos': valorUnitarioCentavos,
      'ordem': ordem,
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

  static ItemTabelaPrecificacaoInclude include() {
    return ItemTabelaPrecificacaoInclude._();
  }

  static ItemTabelaPrecificacaoIncludeList includeList({
    _i1.WhereExpressionBuilder<ItemTabelaPrecificacaoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ItemTabelaPrecificacaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ItemTabelaPrecificacaoTable>? orderByList,
    ItemTabelaPrecificacaoInclude? include,
  }) {
    return ItemTabelaPrecificacaoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ItemTabelaPrecificacao.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ItemTabelaPrecificacao.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ItemTabelaPrecificacaoImpl extends ItemTabelaPrecificacao {
  _ItemTabelaPrecificacaoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue tabelaPrecificacaoId,
    required int quantidadeMinima,
    int? quantidadeMaxima,
    required int valorUnitarioCentavos,
    required int ordem,
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
          tabelaPrecificacaoId: tabelaPrecificacaoId,
          quantidadeMinima: quantidadeMinima,
          quantidadeMaxima: quantidadeMaxima,
          valorUnitarioCentavos: valorUnitarioCentavos,
          ordem: ordem,
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

  /// Returns a shallow copy of this [ItemTabelaPrecificacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ItemTabelaPrecificacao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? tabelaPrecificacaoId,
    int? quantidadeMinima,
    Object? quantidadeMaxima = _Undefined,
    int? valorUnitarioCentavos,
    int? ordem,
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
    return ItemTabelaPrecificacao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tabelaPrecificacaoId: tabelaPrecificacaoId ?? this.tabelaPrecificacaoId,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      quantidadeMaxima:
          quantidadeMaxima is int? ? quantidadeMaxima : this.quantidadeMaxima,
      valorUnitarioCentavos:
          valorUnitarioCentavos ?? this.valorUnitarioCentavos,
      ordem: ordem ?? this.ordem,
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

class ItemTabelaPrecificacaoTable extends _i1.Table<_i1.UuidValue> {
  ItemTabelaPrecificacaoTable({super.tableRelation})
      : super(tableName: 'item_tabela_precificacao') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    tabelaPrecificacaoId = _i1.ColumnUuid(
      'tabelaPrecificacaoId',
      this,
    );
    quantidadeMinima = _i1.ColumnInt(
      'quantidadeMinima',
      this,
    );
    quantidadeMaxima = _i1.ColumnInt(
      'quantidadeMaxima',
      this,
    );
    valorUnitarioCentavos = _i1.ColumnInt(
      'valorUnitarioCentavos',
      this,
    );
    ordem = _i1.ColumnInt(
      'ordem',
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

  late final _i1.ColumnUuid tabelaPrecificacaoId;

  late final _i1.ColumnInt quantidadeMinima;

  late final _i1.ColumnInt quantidadeMaxima;

  late final _i1.ColumnInt valorUnitarioCentavos;

  late final _i1.ColumnInt ordem;

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
        tabelaPrecificacaoId,
        quantidadeMinima,
        quantidadeMaxima,
        valorUnitarioCentavos,
        ordem,
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

class ItemTabelaPrecificacaoInclude extends _i1.IncludeObject {
  ItemTabelaPrecificacaoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => ItemTabelaPrecificacao.t;
}

class ItemTabelaPrecificacaoIncludeList extends _i1.IncludeList {
  ItemTabelaPrecificacaoIncludeList._({
    _i1.WhereExpressionBuilder<ItemTabelaPrecificacaoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ItemTabelaPrecificacao.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => ItemTabelaPrecificacao.t;
}

class ItemTabelaPrecificacaoRepository {
  const ItemTabelaPrecificacaoRepository._();

  /// Returns a list of [ItemTabelaPrecificacao]s matching the given query parameters.
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
  Future<List<ItemTabelaPrecificacao>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ItemTabelaPrecificacaoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ItemTabelaPrecificacaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ItemTabelaPrecificacaoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ItemTabelaPrecificacao>(
      where: where?.call(ItemTabelaPrecificacao.t),
      orderBy: orderBy?.call(ItemTabelaPrecificacao.t),
      orderByList: orderByList?.call(ItemTabelaPrecificacao.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [ItemTabelaPrecificacao] matching the given query parameters.
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
  Future<ItemTabelaPrecificacao?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ItemTabelaPrecificacaoTable>? where,
    int? offset,
    _i1.OrderByBuilder<ItemTabelaPrecificacaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ItemTabelaPrecificacaoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ItemTabelaPrecificacao>(
      where: where?.call(ItemTabelaPrecificacao.t),
      orderBy: orderBy?.call(ItemTabelaPrecificacao.t),
      orderByList: orderByList?.call(ItemTabelaPrecificacao.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ItemTabelaPrecificacao] by its [id] or null if no such row exists.
  Future<ItemTabelaPrecificacao?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ItemTabelaPrecificacao>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ItemTabelaPrecificacao]s in the list and returns the inserted rows.
  ///
  /// The returned [ItemTabelaPrecificacao]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ItemTabelaPrecificacao>> insert(
    _i1.Session session,
    List<ItemTabelaPrecificacao> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ItemTabelaPrecificacao>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ItemTabelaPrecificacao] and returns the inserted row.
  ///
  /// The returned [ItemTabelaPrecificacao] will have its `id` field set.
  Future<ItemTabelaPrecificacao> insertRow(
    _i1.Session session,
    ItemTabelaPrecificacao row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ItemTabelaPrecificacao>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ItemTabelaPrecificacao]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ItemTabelaPrecificacao>> update(
    _i1.Session session,
    List<ItemTabelaPrecificacao> rows, {
    _i1.ColumnSelections<ItemTabelaPrecificacaoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ItemTabelaPrecificacao>(
      rows,
      columns: columns?.call(ItemTabelaPrecificacao.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ItemTabelaPrecificacao]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ItemTabelaPrecificacao> updateRow(
    _i1.Session session,
    ItemTabelaPrecificacao row, {
    _i1.ColumnSelections<ItemTabelaPrecificacaoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ItemTabelaPrecificacao>(
      row,
      columns: columns?.call(ItemTabelaPrecificacao.t),
      transaction: transaction,
    );
  }

  /// Deletes all [ItemTabelaPrecificacao]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ItemTabelaPrecificacao>> delete(
    _i1.Session session,
    List<ItemTabelaPrecificacao> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ItemTabelaPrecificacao>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ItemTabelaPrecificacao].
  Future<ItemTabelaPrecificacao> deleteRow(
    _i1.Session session,
    ItemTabelaPrecificacao row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ItemTabelaPrecificacao>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ItemTabelaPrecificacao>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ItemTabelaPrecificacaoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ItemTabelaPrecificacao>(
      where: where(ItemTabelaPrecificacao.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ItemTabelaPrecificacaoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ItemTabelaPrecificacao>(
      where: where?.call(ItemTabelaPrecificacao.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
