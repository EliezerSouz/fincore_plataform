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

abstract class AuditLog
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  AuditLog._({
    _i1.UuidValue? id,
    required this.entityName,
    required this.entityId,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.diff,
    this.deviceInfo,
    this.origin,
    this.reason,
    this.syncVersion,
    this.tenantId,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory AuditLog({
    _i1.UuidValue? id,
    required String entityName,
    required String entityId,
    required String userId,
    required String action,
    required DateTime timestamp,
    String? diff,
    String? deviceInfo,
    String? origin,
    String? reason,
    int? syncVersion,
    String? tenantId,
  }) = _AuditLogImpl;

  factory AuditLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditLog(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityName: jsonSerialization['entityName'] as String,
      entityId: jsonSerialization['entityId'] as String,
      userId: jsonSerialization['userId'] as String,
      action: jsonSerialization['action'] as String,
      timestamp:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['timestamp']),
      diff: jsonSerialization['diff'] as String?,
      deviceInfo: jsonSerialization['deviceInfo'] as String?,
      origin: jsonSerialization['origin'] as String?,
      reason: jsonSerialization['reason'] as String?,
      syncVersion: jsonSerialization['syncVersion'] as int?,
      tenantId: jsonSerialization['tenantId'] as String?,
    );
  }

  static final t = AuditLogTable();

  static const db = AuditLogRepository._();

  @override
  _i1.UuidValue id;

  String entityName;

  String entityId;

  String userId;

  String action;

  DateTime timestamp;

  String? diff;

  String? deviceInfo;

  String? origin;

  String? reason;

  int? syncVersion;

  String? tenantId;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuditLog copyWith({
    _i1.UuidValue? id,
    String? entityName,
    String? entityId,
    String? userId,
    String? action,
    DateTime? timestamp,
    String? diff,
    String? deviceInfo,
    String? origin,
    String? reason,
    int? syncVersion,
    String? tenantId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'entityName': entityName,
      'entityId': entityId,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toJson(),
      if (diff != null) 'diff': diff,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (origin != null) 'origin': origin,
      if (reason != null) 'reason': reason,
      if (syncVersion != null) 'syncVersion': syncVersion,
      if (tenantId != null) 'tenantId': tenantId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'id': id.toJson(),
      'entityName': entityName,
      'entityId': entityId,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toJson(),
      if (diff != null) 'diff': diff,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (origin != null) 'origin': origin,
      if (reason != null) 'reason': reason,
      if (syncVersion != null) 'syncVersion': syncVersion,
      if (tenantId != null) 'tenantId': tenantId,
    };
  }

  static AuditLogInclude include() {
    return AuditLogInclude._();
  }

  static AuditLogIncludeList includeList({
    _i1.WhereExpressionBuilder<AuditLogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuditLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuditLogTable>? orderByList,
    AuditLogInclude? include,
  }) {
    return AuditLogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuditLog.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AuditLog.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditLogImpl extends AuditLog {
  _AuditLogImpl({
    _i1.UuidValue? id,
    required String entityName,
    required String entityId,
    required String userId,
    required String action,
    required DateTime timestamp,
    String? diff,
    String? deviceInfo,
    String? origin,
    String? reason,
    int? syncVersion,
    String? tenantId,
  }) : super._(
          id: id,
          entityName: entityName,
          entityId: entityId,
          userId: userId,
          action: action,
          timestamp: timestamp,
          diff: diff,
          deviceInfo: deviceInfo,
          origin: origin,
          reason: reason,
          syncVersion: syncVersion,
          tenantId: tenantId,
        );

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuditLog copyWith({
    _i1.UuidValue? id,
    String? entityName,
    String? entityId,
    String? userId,
    String? action,
    DateTime? timestamp,
    Object? diff = _Undefined,
    Object? deviceInfo = _Undefined,
    Object? origin = _Undefined,
    Object? reason = _Undefined,
    Object? syncVersion = _Undefined,
    Object? tenantId = _Undefined,
  }) {
    return AuditLog(
      id: id ?? this.id,
      entityName: entityName ?? this.entityName,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      diff: diff is String? ? diff : this.diff,
      deviceInfo: deviceInfo is String? ? deviceInfo : this.deviceInfo,
      origin: origin is String? ? origin : this.origin,
      reason: reason is String? ? reason : this.reason,
      syncVersion: syncVersion is int? ? syncVersion : this.syncVersion,
      tenantId: tenantId is String? ? tenantId : this.tenantId,
    );
  }
}

class AuditLogTable extends _i1.Table<_i1.UuidValue> {
  AuditLogTable({super.tableRelation}) : super(tableName: 'audit_logs') {
    entityName = _i1.ColumnString(
      'entityName',
      this,
    );
    entityId = _i1.ColumnString(
      'entityId',
      this,
    );
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    action = _i1.ColumnString(
      'action',
      this,
    );
    timestamp = _i1.ColumnDateTime(
      'timestamp',
      this,
    );
    diff = _i1.ColumnString(
      'diff',
      this,
    );
    deviceInfo = _i1.ColumnString(
      'deviceInfo',
      this,
    );
    origin = _i1.ColumnString(
      'origin',
      this,
    );
    reason = _i1.ColumnString(
      'reason',
      this,
    );
    syncVersion = _i1.ColumnInt(
      'syncVersion',
      this,
    );
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
  }

  late final _i1.ColumnString entityName;

  late final _i1.ColumnString entityId;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString action;

  late final _i1.ColumnDateTime timestamp;

  late final _i1.ColumnString diff;

  late final _i1.ColumnString deviceInfo;

  late final _i1.ColumnString origin;

  late final _i1.ColumnString reason;

  late final _i1.ColumnInt syncVersion;

  late final _i1.ColumnString tenantId;

  @override
  List<_i1.Column> get columns => [
        id,
        entityName,
        entityId,
        userId,
        action,
        timestamp,
        diff,
        deviceInfo,
        origin,
        reason,
        syncVersion,
        tenantId,
      ];
}

class AuditLogInclude extends _i1.IncludeObject {
  AuditLogInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => AuditLog.t;
}

class AuditLogIncludeList extends _i1.IncludeList {
  AuditLogIncludeList._({
    _i1.WhereExpressionBuilder<AuditLogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuditLog.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => AuditLog.t;
}

class AuditLogRepository {
  const AuditLogRepository._();

  /// Returns a list of [AuditLog]s matching the given query parameters.
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
  Future<List<AuditLog>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AuditLogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuditLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuditLogTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<AuditLog>(
      where: where?.call(AuditLog.t),
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [AuditLog] matching the given query parameters.
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
  Future<AuditLog?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AuditLogTable>? where,
    int? offset,
    _i1.OrderByBuilder<AuditLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuditLogTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<AuditLog>(
      where: where?.call(AuditLog.t),
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [AuditLog] by its [id] or null if no such row exists.
  Future<AuditLog?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<AuditLog>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [AuditLog]s in the list and returns the inserted rows.
  ///
  /// The returned [AuditLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<AuditLog>> insert(
    _i1.Session session,
    List<AuditLog> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<AuditLog>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [AuditLog] and returns the inserted row.
  ///
  /// The returned [AuditLog] will have its `id` field set.
  Future<AuditLog> insertRow(
    _i1.Session session,
    AuditLog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuditLog>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AuditLog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AuditLog>> update(
    _i1.Session session,
    List<AuditLog> rows, {
    _i1.ColumnSelections<AuditLogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AuditLog>(
      rows,
      columns: columns?.call(AuditLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuditLog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuditLog> updateRow(
    _i1.Session session,
    AuditLog row, {
    _i1.ColumnSelections<AuditLogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuditLog>(
      row,
      columns: columns?.call(AuditLog.t),
      transaction: transaction,
    );
  }

  /// Deletes all [AuditLog]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AuditLog>> delete(
    _i1.Session session,
    List<AuditLog> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AuditLog>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AuditLog].
  Future<AuditLog> deleteRow(
    _i1.Session session,
    AuditLog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuditLog>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AuditLog>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AuditLogTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AuditLog>(
      where: where(AuditLog.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AuditLogTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AuditLog>(
      where: where?.call(AuditLog.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
