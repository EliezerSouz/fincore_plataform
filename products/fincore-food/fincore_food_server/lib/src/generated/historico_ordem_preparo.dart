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

abstract class HistoricoOrdemPreparo
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  HistoricoOrdemPreparo._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.ordemPreparoId,
    required this.titulo,
    required this.descricao,
    required this.operadorNome,
    required this.criadaEm,
    required this.versao,
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

  factory HistoricoOrdemPreparo({
    _i1.UuidValue? id,
    required String tenantId,
    required String ordemPreparoId,
    required String titulo,
    required String descricao,
    required String operadorNome,
    required DateTime criadaEm,
    required String versao,
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
  }) = _HistoricoOrdemPreparoImpl;

  factory HistoricoOrdemPreparo.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return HistoricoOrdemPreparo(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      ordemPreparoId: jsonSerialization['ordemPreparoId'] as String,
      titulo: jsonSerialization['titulo'] as String,
      descricao: jsonSerialization['descricao'] as String,
      operadorNome: jsonSerialization['operadorNome'] as String,
      criadaEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['criadaEm']),
      versao: jsonSerialization['versao'] as String,
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

  static final t = HistoricoOrdemPreparoTable();

  static const db = HistoricoOrdemPreparoRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String ordemPreparoId;

  String titulo;

  String descricao;

  String operadorNome;

  DateTime criadaEm;

  String versao;

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

  /// Returns a shallow copy of this [HistoricoOrdemPreparo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  HistoricoOrdemPreparo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? ordemPreparoId,
    String? titulo,
    String? descricao,
    String? operadorNome,
    DateTime? criadaEm,
    String? versao,
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
      'ordemPreparoId': ordemPreparoId,
      'titulo': titulo,
      'descricao': descricao,
      'operadorNome': operadorNome,
      'criadaEm': criadaEm.toJson(),
      'versao': versao,
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
      'ordemPreparoId': ordemPreparoId,
      'titulo': titulo,
      'descricao': descricao,
      'operadorNome': operadorNome,
      'criadaEm': criadaEm.toJson(),
      'versao': versao,
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

  static HistoricoOrdemPreparoInclude include() {
    return HistoricoOrdemPreparoInclude._();
  }

  static HistoricoOrdemPreparoIncludeList includeList({
    _i1.WhereExpressionBuilder<HistoricoOrdemPreparoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<HistoricoOrdemPreparoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<HistoricoOrdemPreparoTable>? orderByList,
    HistoricoOrdemPreparoInclude? include,
  }) {
    return HistoricoOrdemPreparoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HistoricoOrdemPreparo.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(HistoricoOrdemPreparo.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HistoricoOrdemPreparoImpl extends HistoricoOrdemPreparo {
  _HistoricoOrdemPreparoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String ordemPreparoId,
    required String titulo,
    required String descricao,
    required String operadorNome,
    required DateTime criadaEm,
    required String versao,
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
          ordemPreparoId: ordemPreparoId,
          titulo: titulo,
          descricao: descricao,
          operadorNome: operadorNome,
          criadaEm: criadaEm,
          versao: versao,
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

  /// Returns a shallow copy of this [HistoricoOrdemPreparo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  HistoricoOrdemPreparo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? ordemPreparoId,
    String? titulo,
    String? descricao,
    String? operadorNome,
    DateTime? criadaEm,
    String? versao,
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
    return HistoricoOrdemPreparo(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      ordemPreparoId: ordemPreparoId ?? this.ordemPreparoId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      operadorNome: operadorNome ?? this.operadorNome,
      criadaEm: criadaEm ?? this.criadaEm,
      versao: versao ?? this.versao,
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

class HistoricoOrdemPreparoTable extends _i1.Table<_i1.UuidValue> {
  HistoricoOrdemPreparoTable({super.tableRelation})
      : super(tableName: 'historicos_ordem_preparo') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    ordemPreparoId = _i1.ColumnString(
      'ordemPreparoId',
      this,
    );
    titulo = _i1.ColumnString(
      'titulo',
      this,
    );
    descricao = _i1.ColumnString(
      'descricao',
      this,
    );
    operadorNome = _i1.ColumnString(
      'operadorNome',
      this,
    );
    criadaEm = _i1.ColumnDateTime(
      'criadaEm',
      this,
    );
    versao = _i1.ColumnString(
      'versao',
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

  late final _i1.ColumnString ordemPreparoId;

  late final _i1.ColumnString titulo;

  late final _i1.ColumnString descricao;

  late final _i1.ColumnString operadorNome;

  late final _i1.ColumnDateTime criadaEm;

  late final _i1.ColumnString versao;

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
        ordemPreparoId,
        titulo,
        descricao,
        operadorNome,
        criadaEm,
        versao,
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

class HistoricoOrdemPreparoInclude extends _i1.IncludeObject {
  HistoricoOrdemPreparoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => HistoricoOrdemPreparo.t;
}

class HistoricoOrdemPreparoIncludeList extends _i1.IncludeList {
  HistoricoOrdemPreparoIncludeList._({
    _i1.WhereExpressionBuilder<HistoricoOrdemPreparoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(HistoricoOrdemPreparo.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => HistoricoOrdemPreparo.t;
}

class HistoricoOrdemPreparoRepository {
  const HistoricoOrdemPreparoRepository._();

  /// Returns a list of [HistoricoOrdemPreparo]s matching the given query parameters.
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
  Future<List<HistoricoOrdemPreparo>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<HistoricoOrdemPreparoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<HistoricoOrdemPreparoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<HistoricoOrdemPreparoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<HistoricoOrdemPreparo>(
      where: where?.call(HistoricoOrdemPreparo.t),
      orderBy: orderBy?.call(HistoricoOrdemPreparo.t),
      orderByList: orderByList?.call(HistoricoOrdemPreparo.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [HistoricoOrdemPreparo] matching the given query parameters.
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
  Future<HistoricoOrdemPreparo?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<HistoricoOrdemPreparoTable>? where,
    int? offset,
    _i1.OrderByBuilder<HistoricoOrdemPreparoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<HistoricoOrdemPreparoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<HistoricoOrdemPreparo>(
      where: where?.call(HistoricoOrdemPreparo.t),
      orderBy: orderBy?.call(HistoricoOrdemPreparo.t),
      orderByList: orderByList?.call(HistoricoOrdemPreparo.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [HistoricoOrdemPreparo] by its [id] or null if no such row exists.
  Future<HistoricoOrdemPreparo?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<HistoricoOrdemPreparo>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [HistoricoOrdemPreparo]s in the list and returns the inserted rows.
  ///
  /// The returned [HistoricoOrdemPreparo]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<HistoricoOrdemPreparo>> insert(
    _i1.Session session,
    List<HistoricoOrdemPreparo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<HistoricoOrdemPreparo>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [HistoricoOrdemPreparo] and returns the inserted row.
  ///
  /// The returned [HistoricoOrdemPreparo] will have its `id` field set.
  Future<HistoricoOrdemPreparo> insertRow(
    _i1.Session session,
    HistoricoOrdemPreparo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<HistoricoOrdemPreparo>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [HistoricoOrdemPreparo]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<HistoricoOrdemPreparo>> update(
    _i1.Session session,
    List<HistoricoOrdemPreparo> rows, {
    _i1.ColumnSelections<HistoricoOrdemPreparoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<HistoricoOrdemPreparo>(
      rows,
      columns: columns?.call(HistoricoOrdemPreparo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [HistoricoOrdemPreparo]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<HistoricoOrdemPreparo> updateRow(
    _i1.Session session,
    HistoricoOrdemPreparo row, {
    _i1.ColumnSelections<HistoricoOrdemPreparoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<HistoricoOrdemPreparo>(
      row,
      columns: columns?.call(HistoricoOrdemPreparo.t),
      transaction: transaction,
    );
  }

  /// Deletes all [HistoricoOrdemPreparo]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<HistoricoOrdemPreparo>> delete(
    _i1.Session session,
    List<HistoricoOrdemPreparo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<HistoricoOrdemPreparo>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [HistoricoOrdemPreparo].
  Future<HistoricoOrdemPreparo> deleteRow(
    _i1.Session session,
    HistoricoOrdemPreparo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<HistoricoOrdemPreparo>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<HistoricoOrdemPreparo>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<HistoricoOrdemPreparoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<HistoricoOrdemPreparo>(
      where: where(HistoricoOrdemPreparo.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<HistoricoOrdemPreparoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<HistoricoOrdemPreparo>(
      where: where?.call(HistoricoOrdemPreparo.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
