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

abstract class MembroEmpresa
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  MembroEmpresa._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.usuarioId,
    required this.role,
    required this.ativo,
    required this.convidadoEm,
    this.aceitoEm,
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

  factory MembroEmpresa({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required _i1.UuidValue usuarioId,
    required String role,
    required bool ativo,
    required DateTime convidadoEm,
    DateTime? aceitoEm,
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
  }) = _MembroEmpresaImpl;

  factory MembroEmpresa.fromJson(Map<String, dynamic> jsonSerialization) {
    return MembroEmpresa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['tenantId']),
      usuarioId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['usuarioId']),
      role: jsonSerialization['role'] as String,
      ativo: jsonSerialization['ativo'] as bool,
      convidadoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['convidadoEm']),
      aceitoEm: jsonSerialization['aceitoEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['aceitoEm']),
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

  static final t = MembroEmpresaTable();

  static const db = MembroEmpresaRepository._();

  @override
  _i1.UuidValue id;

  _i1.UuidValue tenantId;

  _i1.UuidValue usuarioId;

  String role;

  bool ativo;

  DateTime convidadoEm;

  DateTime? aceitoEm;

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

  /// Returns a shallow copy of this [MembroEmpresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MembroEmpresa copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    _i1.UuidValue? usuarioId,
    String? role,
    bool? ativo,
    DateTime? convidadoEm,
    DateTime? aceitoEm,
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
      'usuarioId': usuarioId.toJson(),
      'role': role,
      'ativo': ativo,
      'convidadoEm': convidadoEm.toJson(),
      if (aceitoEm != null) 'aceitoEm': aceitoEm?.toJson(),
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
      'usuarioId': usuarioId.toJson(),
      'role': role,
      'ativo': ativo,
      'convidadoEm': convidadoEm.toJson(),
      if (aceitoEm != null) 'aceitoEm': aceitoEm?.toJson(),
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

  static MembroEmpresaInclude include() {
    return MembroEmpresaInclude._();
  }

  static MembroEmpresaIncludeList includeList({
    _i1.WhereExpressionBuilder<MembroEmpresaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MembroEmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MembroEmpresaTable>? orderByList,
    MembroEmpresaInclude? include,
  }) {
    return MembroEmpresaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MembroEmpresa.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MembroEmpresa.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MembroEmpresaImpl extends MembroEmpresa {
  _MembroEmpresaImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required _i1.UuidValue usuarioId,
    required String role,
    required bool ativo,
    required DateTime convidadoEm,
    DateTime? aceitoEm,
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
          usuarioId: usuarioId,
          role: role,
          ativo: ativo,
          convidadoEm: convidadoEm,
          aceitoEm: aceitoEm,
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

  /// Returns a shallow copy of this [MembroEmpresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MembroEmpresa copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    _i1.UuidValue? usuarioId,
    String? role,
    bool? ativo,
    DateTime? convidadoEm,
    Object? aceitoEm = _Undefined,
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
    return MembroEmpresa(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      usuarioId: usuarioId ?? this.usuarioId,
      role: role ?? this.role,
      ativo: ativo ?? this.ativo,
      convidadoEm: convidadoEm ?? this.convidadoEm,
      aceitoEm: aceitoEm is DateTime? ? aceitoEm : this.aceitoEm,
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

class MembroEmpresaTable extends _i1.Table<_i1.UuidValue> {
  MembroEmpresaTable({super.tableRelation})
      : super(tableName: 'membro_empresa') {
    tenantId = _i1.ColumnUuid(
      'tenantId',
      this,
    );
    usuarioId = _i1.ColumnUuid(
      'usuarioId',
      this,
    );
    role = _i1.ColumnString(
      'role',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    convidadoEm = _i1.ColumnDateTime(
      'convidadoEm',
      this,
    );
    aceitoEm = _i1.ColumnDateTime(
      'aceitoEm',
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

  late final _i1.ColumnUuid usuarioId;

  late final _i1.ColumnString role;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnDateTime convidadoEm;

  late final _i1.ColumnDateTime aceitoEm;

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
        usuarioId,
        role,
        ativo,
        convidadoEm,
        aceitoEm,
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

class MembroEmpresaInclude extends _i1.IncludeObject {
  MembroEmpresaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => MembroEmpresa.t;
}

class MembroEmpresaIncludeList extends _i1.IncludeList {
  MembroEmpresaIncludeList._({
    _i1.WhereExpressionBuilder<MembroEmpresaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MembroEmpresa.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => MembroEmpresa.t;
}

class MembroEmpresaRepository {
  const MembroEmpresaRepository._();

  /// Returns a list of [MembroEmpresa]s matching the given query parameters.
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
  Future<List<MembroEmpresa>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MembroEmpresaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MembroEmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MembroEmpresaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<MembroEmpresa>(
      where: where?.call(MembroEmpresa.t),
      orderBy: orderBy?.call(MembroEmpresa.t),
      orderByList: orderByList?.call(MembroEmpresa.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [MembroEmpresa] matching the given query parameters.
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
  Future<MembroEmpresa?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MembroEmpresaTable>? where,
    int? offset,
    _i1.OrderByBuilder<MembroEmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MembroEmpresaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<MembroEmpresa>(
      where: where?.call(MembroEmpresa.t),
      orderBy: orderBy?.call(MembroEmpresa.t),
      orderByList: orderByList?.call(MembroEmpresa.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [MembroEmpresa] by its [id] or null if no such row exists.
  Future<MembroEmpresa?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<MembroEmpresa>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [MembroEmpresa]s in the list and returns the inserted rows.
  ///
  /// The returned [MembroEmpresa]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<MembroEmpresa>> insert(
    _i1.Session session,
    List<MembroEmpresa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<MembroEmpresa>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [MembroEmpresa] and returns the inserted row.
  ///
  /// The returned [MembroEmpresa] will have its `id` field set.
  Future<MembroEmpresa> insertRow(
    _i1.Session session,
    MembroEmpresa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MembroEmpresa>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MembroEmpresa]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MembroEmpresa>> update(
    _i1.Session session,
    List<MembroEmpresa> rows, {
    _i1.ColumnSelections<MembroEmpresaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MembroEmpresa>(
      rows,
      columns: columns?.call(MembroEmpresa.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MembroEmpresa]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MembroEmpresa> updateRow(
    _i1.Session session,
    MembroEmpresa row, {
    _i1.ColumnSelections<MembroEmpresaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MembroEmpresa>(
      row,
      columns: columns?.call(MembroEmpresa.t),
      transaction: transaction,
    );
  }

  /// Deletes all [MembroEmpresa]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MembroEmpresa>> delete(
    _i1.Session session,
    List<MembroEmpresa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MembroEmpresa>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MembroEmpresa].
  Future<MembroEmpresa> deleteRow(
    _i1.Session session,
    MembroEmpresa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MembroEmpresa>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MembroEmpresa>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MembroEmpresaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MembroEmpresa>(
      where: where(MembroEmpresa.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MembroEmpresaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MembroEmpresa>(
      where: where?.call(MembroEmpresa.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
