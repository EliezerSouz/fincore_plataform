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

abstract class EmpresaConvite
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EmpresaConvite._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.status,
    required this.expiracaoEm,
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

  factory EmpresaConvite({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String email,
    required String role,
    required String status,
    required DateTime expiracaoEm,
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
  }) = _EmpresaConviteImpl;

  factory EmpresaConvite.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmpresaConvite(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['tenantId']),
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
      status: jsonSerialization['status'] as String,
      expiracaoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiracaoEm']),
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

  static final t = EmpresaConviteTable();

  static const db = EmpresaConviteRepository._();

  @override
  _i1.UuidValue id;

  _i1.UuidValue tenantId;

  String email;

  String role;

  String status;

  DateTime expiracaoEm;

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

  /// Returns a shallow copy of this [EmpresaConvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmpresaConvite copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? email,
    String? role,
    String? status,
    DateTime? expiracaoEm,
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
      'tenantId': tenantId.toJson(),
      'email': email,
      'role': role,
      'status': status,
      'expiracaoEm': expiracaoEm.toJson(),
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
      'tenantId': tenantId.toJson(),
      'email': email,
      'role': role,
      'status': status,
      'expiracaoEm': expiracaoEm.toJson(),
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

  static EmpresaConviteInclude include() {
    return EmpresaConviteInclude._();
  }

  static EmpresaConviteIncludeList includeList({
    _i1.WhereExpressionBuilder<EmpresaConviteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmpresaConviteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaConviteTable>? orderByList,
    EmpresaConviteInclude? include,
  }) {
    return EmpresaConviteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmpresaConvite.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EmpresaConvite.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmpresaConviteImpl extends EmpresaConvite {
  _EmpresaConviteImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String email,
    required String role,
    required String status,
    required DateTime expiracaoEm,
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
          email: email,
          role: role,
          status: status,
          expiracaoEm: expiracaoEm,
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

  /// Returns a shallow copy of this [EmpresaConvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmpresaConvite copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? email,
    String? role,
    String? status,
    DateTime? expiracaoEm,
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
    return EmpresaConvite(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      expiracaoEm: expiracaoEm ?? this.expiracaoEm,
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

class EmpresaConviteTable extends _i1.Table<_i1.UuidValue> {
  EmpresaConviteTable({super.tableRelation})
      : super(tableName: 'empresa_convite') {
    tenantId = _i1.ColumnUuid(
      'tenantId',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    role = _i1.ColumnString(
      'role',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    expiracaoEm = _i1.ColumnDateTime(
      'expiracaoEm',
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

  late final _i1.ColumnUuid tenantId;

  late final _i1.ColumnString email;

  late final _i1.ColumnString role;

  late final _i1.ColumnString status;

  late final _i1.ColumnDateTime expiracaoEm;

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
        email,
        role,
        status,
        expiracaoEm,
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

class EmpresaConviteInclude extends _i1.IncludeObject {
  EmpresaConviteInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EmpresaConvite.t;
}

class EmpresaConviteIncludeList extends _i1.IncludeList {
  EmpresaConviteIncludeList._({
    _i1.WhereExpressionBuilder<EmpresaConviteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EmpresaConvite.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EmpresaConvite.t;
}

class EmpresaConviteRepository {
  const EmpresaConviteRepository._();

  /// Returns a list of [EmpresaConvite]s matching the given query parameters.
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
  Future<List<EmpresaConvite>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaConviteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmpresaConviteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaConviteTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EmpresaConvite>(
      where: where?.call(EmpresaConvite.t),
      orderBy: orderBy?.call(EmpresaConvite.t),
      orderByList: orderByList?.call(EmpresaConvite.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EmpresaConvite] matching the given query parameters.
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
  Future<EmpresaConvite?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaConviteTable>? where,
    int? offset,
    _i1.OrderByBuilder<EmpresaConviteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaConviteTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EmpresaConvite>(
      where: where?.call(EmpresaConvite.t),
      orderBy: orderBy?.call(EmpresaConvite.t),
      orderByList: orderByList?.call(EmpresaConvite.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EmpresaConvite] by its [id] or null if no such row exists.
  Future<EmpresaConvite?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EmpresaConvite>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EmpresaConvite]s in the list and returns the inserted rows.
  ///
  /// The returned [EmpresaConvite]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EmpresaConvite>> insert(
    _i1.Session session,
    List<EmpresaConvite> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EmpresaConvite>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EmpresaConvite] and returns the inserted row.
  ///
  /// The returned [EmpresaConvite] will have its `id` field set.
  Future<EmpresaConvite> insertRow(
    _i1.Session session,
    EmpresaConvite row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EmpresaConvite>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EmpresaConvite]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EmpresaConvite>> update(
    _i1.Session session,
    List<EmpresaConvite> rows, {
    _i1.ColumnSelections<EmpresaConviteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EmpresaConvite>(
      rows,
      columns: columns?.call(EmpresaConvite.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmpresaConvite]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EmpresaConvite> updateRow(
    _i1.Session session,
    EmpresaConvite row, {
    _i1.ColumnSelections<EmpresaConviteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EmpresaConvite>(
      row,
      columns: columns?.call(EmpresaConvite.t),
      transaction: transaction,
    );
  }

  /// Deletes all [EmpresaConvite]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EmpresaConvite>> delete(
    _i1.Session session,
    List<EmpresaConvite> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EmpresaConvite>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EmpresaConvite].
  Future<EmpresaConvite> deleteRow(
    _i1.Session session,
    EmpresaConvite row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EmpresaConvite>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EmpresaConvite>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EmpresaConviteTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EmpresaConvite>(
      where: where(EmpresaConvite.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaConviteTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EmpresaConvite>(
      where: where?.call(EmpresaConvite.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
