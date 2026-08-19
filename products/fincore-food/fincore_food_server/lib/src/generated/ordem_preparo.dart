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

abstract class OrdemPreparo
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
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

  static final t = OrdemPreparoTable();

  static const db = OrdemPreparoRepository._();

  @override
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

  @override
  _i1.Table<_i1.UuidValue> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static OrdemPreparoInclude include() {
    return OrdemPreparoInclude._();
  }

  static OrdemPreparoIncludeList includeList({
    _i1.WhereExpressionBuilder<OrdemPreparoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OrdemPreparoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OrdemPreparoTable>? orderByList,
    OrdemPreparoInclude? include,
  }) {
    return OrdemPreparoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OrdemPreparo.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OrdemPreparo.t),
      include: include,
    );
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

class OrdemPreparoTable extends _i1.Table<_i1.UuidValue> {
  OrdemPreparoTable({super.tableRelation})
      : super(tableName: 'ordens_preparo') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    pedidoId = _i1.ColumnString(
      'pedidoId',
      this,
    );
    itensJson = _i1.ColumnString(
      'itensJson',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    prioridade = _i1.ColumnString(
      'prioridade',
      this,
    );
    operadorId = _i1.ColumnString(
      'operadorId',
      this,
    );
    criadaEm = _i1.ColumnDateTime(
      'criadaEm',
      this,
    );
    iniciadaEm = _i1.ColumnDateTime(
      'iniciadaEm',
      this,
    );
    concluidaEm = _i1.ColumnDateTime(
      'concluidaEm',
      this,
    );
    canceladaEm = _i1.ColumnDateTime(
      'canceladaEm',
      this,
    );
    tempoEstimadoSegundos = _i1.ColumnInt(
      'tempoEstimadoSegundos',
      this,
    );
    observacoes = _i1.ColumnString(
      'observacoes',
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

  late final _i1.ColumnString pedidoId;

  late final _i1.ColumnString itensJson;

  late final _i1.ColumnString status;

  late final _i1.ColumnString prioridade;

  late final _i1.ColumnString operadorId;

  late final _i1.ColumnDateTime criadaEm;

  late final _i1.ColumnDateTime iniciadaEm;

  late final _i1.ColumnDateTime concluidaEm;

  late final _i1.ColumnDateTime canceladaEm;

  late final _i1.ColumnInt tempoEstimadoSegundos;

  late final _i1.ColumnString observacoes;

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
        pedidoId,
        itensJson,
        status,
        prioridade,
        operadorId,
        criadaEm,
        iniciadaEm,
        concluidaEm,
        canceladaEm,
        tempoEstimadoSegundos,
        observacoes,
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

class OrdemPreparoInclude extends _i1.IncludeObject {
  OrdemPreparoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => OrdemPreparo.t;
}

class OrdemPreparoIncludeList extends _i1.IncludeList {
  OrdemPreparoIncludeList._({
    _i1.WhereExpressionBuilder<OrdemPreparoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OrdemPreparo.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => OrdemPreparo.t;
}

class OrdemPreparoRepository {
  const OrdemPreparoRepository._();

  /// Returns a list of [OrdemPreparo]s matching the given query parameters.
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
  Future<List<OrdemPreparo>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OrdemPreparoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OrdemPreparoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OrdemPreparoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<OrdemPreparo>(
      where: where?.call(OrdemPreparo.t),
      orderBy: orderBy?.call(OrdemPreparo.t),
      orderByList: orderByList?.call(OrdemPreparo.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [OrdemPreparo] matching the given query parameters.
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
  Future<OrdemPreparo?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OrdemPreparoTable>? where,
    int? offset,
    _i1.OrderByBuilder<OrdemPreparoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OrdemPreparoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<OrdemPreparo>(
      where: where?.call(OrdemPreparo.t),
      orderBy: orderBy?.call(OrdemPreparo.t),
      orderByList: orderByList?.call(OrdemPreparo.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [OrdemPreparo] by its [id] or null if no such row exists.
  Future<OrdemPreparo?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<OrdemPreparo>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [OrdemPreparo]s in the list and returns the inserted rows.
  ///
  /// The returned [OrdemPreparo]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<OrdemPreparo>> insert(
    _i1.Session session,
    List<OrdemPreparo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<OrdemPreparo>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [OrdemPreparo] and returns the inserted row.
  ///
  /// The returned [OrdemPreparo] will have its `id` field set.
  Future<OrdemPreparo> insertRow(
    _i1.Session session,
    OrdemPreparo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OrdemPreparo>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OrdemPreparo]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OrdemPreparo>> update(
    _i1.Session session,
    List<OrdemPreparo> rows, {
    _i1.ColumnSelections<OrdemPreparoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OrdemPreparo>(
      rows,
      columns: columns?.call(OrdemPreparo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OrdemPreparo]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OrdemPreparo> updateRow(
    _i1.Session session,
    OrdemPreparo row, {
    _i1.ColumnSelections<OrdemPreparoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OrdemPreparo>(
      row,
      columns: columns?.call(OrdemPreparo.t),
      transaction: transaction,
    );
  }

  /// Deletes all [OrdemPreparo]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OrdemPreparo>> delete(
    _i1.Session session,
    List<OrdemPreparo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OrdemPreparo>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OrdemPreparo].
  Future<OrdemPreparo> deleteRow(
    _i1.Session session,
    OrdemPreparo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OrdemPreparo>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OrdemPreparo>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<OrdemPreparoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OrdemPreparo>(
      where: where(OrdemPreparo.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OrdemPreparoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OrdemPreparo>(
      where: where?.call(OrdemPreparo.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
