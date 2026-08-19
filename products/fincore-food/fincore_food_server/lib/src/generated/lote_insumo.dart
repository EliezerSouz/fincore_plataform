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

abstract class LoteInsumo
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  LoteInsumo._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.produtoId,
    this.codigoLote,
    required this.quantidadeInicial,
    required this.quantidadeDisponivel,
    required this.quantidadeReservada,
    required this.unidade,
    this.dataValidade,
    required this.dataEntrada,
    required this.statusLote,
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

  factory LoteInsumo({
    _i1.UuidValue? id,
    required String tenantId,
    required String produtoId,
    String? codigoLote,
    required int quantidadeInicial,
    required int quantidadeDisponivel,
    required int quantidadeReservada,
    required String unidade,
    DateTime? dataValidade,
    required DateTime dataEntrada,
    required String statusLote,
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
  }) = _LoteInsumoImpl;

  factory LoteInsumo.fromJson(Map<String, dynamic> jsonSerialization) {
    return LoteInsumo(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      produtoId: jsonSerialization['produtoId'] as String,
      codigoLote: jsonSerialization['codigoLote'] as String?,
      quantidadeInicial: jsonSerialization['quantidadeInicial'] as int,
      quantidadeDisponivel: jsonSerialization['quantidadeDisponivel'] as int,
      quantidadeReservada: jsonSerialization['quantidadeReservada'] as int,
      unidade: jsonSerialization['unidade'] as String,
      dataValidade: jsonSerialization['dataValidade'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dataValidade']),
      dataEntrada:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataEntrada']),
      statusLote: jsonSerialization['statusLote'] as String,
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

  static final t = LoteInsumoTable();

  static const db = LoteInsumoRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String produtoId;

  String? codigoLote;

  int quantidadeInicial;

  int quantidadeDisponivel;

  int quantidadeReservada;

  String unidade;

  DateTime? dataValidade;

  DateTime dataEntrada;

  String statusLote;

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

  /// Returns a shallow copy of this [LoteInsumo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LoteInsumo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? produtoId,
    String? codigoLote,
    int? quantidadeInicial,
    int? quantidadeDisponivel,
    int? quantidadeReservada,
    String? unidade,
    DateTime? dataValidade,
    DateTime? dataEntrada,
    String? statusLote,
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
      'produtoId': produtoId,
      if (codigoLote != null) 'codigoLote': codigoLote,
      'quantidadeInicial': quantidadeInicial,
      'quantidadeDisponivel': quantidadeDisponivel,
      'quantidadeReservada': quantidadeReservada,
      'unidade': unidade,
      if (dataValidade != null) 'dataValidade': dataValidade?.toJson(),
      'dataEntrada': dataEntrada.toJson(),
      'statusLote': statusLote,
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
      'produtoId': produtoId,
      if (codigoLote != null) 'codigoLote': codigoLote,
      'quantidadeInicial': quantidadeInicial,
      'quantidadeDisponivel': quantidadeDisponivel,
      'quantidadeReservada': quantidadeReservada,
      'unidade': unidade,
      if (dataValidade != null) 'dataValidade': dataValidade?.toJson(),
      'dataEntrada': dataEntrada.toJson(),
      'statusLote': statusLote,
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

  static LoteInsumoInclude include() {
    return LoteInsumoInclude._();
  }

  static LoteInsumoIncludeList includeList({
    _i1.WhereExpressionBuilder<LoteInsumoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LoteInsumoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LoteInsumoTable>? orderByList,
    LoteInsumoInclude? include,
  }) {
    return LoteInsumoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LoteInsumo.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LoteInsumo.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LoteInsumoImpl extends LoteInsumo {
  _LoteInsumoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String produtoId,
    String? codigoLote,
    required int quantidadeInicial,
    required int quantidadeDisponivel,
    required int quantidadeReservada,
    required String unidade,
    DateTime? dataValidade,
    required DateTime dataEntrada,
    required String statusLote,
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
          codigoLote: codigoLote,
          quantidadeInicial: quantidadeInicial,
          quantidadeDisponivel: quantidadeDisponivel,
          quantidadeReservada: quantidadeReservada,
          unidade: unidade,
          dataValidade: dataValidade,
          dataEntrada: dataEntrada,
          statusLote: statusLote,
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

  /// Returns a shallow copy of this [LoteInsumo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LoteInsumo copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? produtoId,
    Object? codigoLote = _Undefined,
    int? quantidadeInicial,
    int? quantidadeDisponivel,
    int? quantidadeReservada,
    String? unidade,
    Object? dataValidade = _Undefined,
    DateTime? dataEntrada,
    String? statusLote,
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
    return LoteInsumo(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      produtoId: produtoId ?? this.produtoId,
      codigoLote: codigoLote is String? ? codigoLote : this.codigoLote,
      quantidadeInicial: quantidadeInicial ?? this.quantidadeInicial,
      quantidadeDisponivel: quantidadeDisponivel ?? this.quantidadeDisponivel,
      quantidadeReservada: quantidadeReservada ?? this.quantidadeReservada,
      unidade: unidade ?? this.unidade,
      dataValidade:
          dataValidade is DateTime? ? dataValidade : this.dataValidade,
      dataEntrada: dataEntrada ?? this.dataEntrada,
      statusLote: statusLote ?? this.statusLote,
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

class LoteInsumoTable extends _i1.Table<_i1.UuidValue> {
  LoteInsumoTable({super.tableRelation}) : super(tableName: 'lotes_insumo') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    produtoId = _i1.ColumnString(
      'produtoId',
      this,
    );
    codigoLote = _i1.ColumnString(
      'codigoLote',
      this,
    );
    quantidadeInicial = _i1.ColumnInt(
      'quantidadeInicial',
      this,
    );
    quantidadeDisponivel = _i1.ColumnInt(
      'quantidadeDisponivel',
      this,
    );
    quantidadeReservada = _i1.ColumnInt(
      'quantidadeReservada',
      this,
    );
    unidade = _i1.ColumnString(
      'unidade',
      this,
    );
    dataValidade = _i1.ColumnDateTime(
      'dataValidade',
      this,
    );
    dataEntrada = _i1.ColumnDateTime(
      'dataEntrada',
      this,
    );
    statusLote = _i1.ColumnString(
      'statusLote',
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

  late final _i1.ColumnString produtoId;

  late final _i1.ColumnString codigoLote;

  late final _i1.ColumnInt quantidadeInicial;

  late final _i1.ColumnInt quantidadeDisponivel;

  late final _i1.ColumnInt quantidadeReservada;

  late final _i1.ColumnString unidade;

  late final _i1.ColumnDateTime dataValidade;

  late final _i1.ColumnDateTime dataEntrada;

  late final _i1.ColumnString statusLote;

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
        codigoLote,
        quantidadeInicial,
        quantidadeDisponivel,
        quantidadeReservada,
        unidade,
        dataValidade,
        dataEntrada,
        statusLote,
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

class LoteInsumoInclude extends _i1.IncludeObject {
  LoteInsumoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => LoteInsumo.t;
}

class LoteInsumoIncludeList extends _i1.IncludeList {
  LoteInsumoIncludeList._({
    _i1.WhereExpressionBuilder<LoteInsumoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LoteInsumo.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => LoteInsumo.t;
}

class LoteInsumoRepository {
  const LoteInsumoRepository._();

  /// Returns a list of [LoteInsumo]s matching the given query parameters.
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
  Future<List<LoteInsumo>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LoteInsumoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LoteInsumoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LoteInsumoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<LoteInsumo>(
      where: where?.call(LoteInsumo.t),
      orderBy: orderBy?.call(LoteInsumo.t),
      orderByList: orderByList?.call(LoteInsumo.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [LoteInsumo] matching the given query parameters.
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
  Future<LoteInsumo?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LoteInsumoTable>? where,
    int? offset,
    _i1.OrderByBuilder<LoteInsumoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LoteInsumoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<LoteInsumo>(
      where: where?.call(LoteInsumo.t),
      orderBy: orderBy?.call(LoteInsumo.t),
      orderByList: orderByList?.call(LoteInsumo.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [LoteInsumo] by its [id] or null if no such row exists.
  Future<LoteInsumo?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<LoteInsumo>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [LoteInsumo]s in the list and returns the inserted rows.
  ///
  /// The returned [LoteInsumo]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<LoteInsumo>> insert(
    _i1.Session session,
    List<LoteInsumo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<LoteInsumo>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [LoteInsumo] and returns the inserted row.
  ///
  /// The returned [LoteInsumo] will have its `id` field set.
  Future<LoteInsumo> insertRow(
    _i1.Session session,
    LoteInsumo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LoteInsumo>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LoteInsumo]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LoteInsumo>> update(
    _i1.Session session,
    List<LoteInsumo> rows, {
    _i1.ColumnSelections<LoteInsumoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LoteInsumo>(
      rows,
      columns: columns?.call(LoteInsumo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LoteInsumo]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LoteInsumo> updateRow(
    _i1.Session session,
    LoteInsumo row, {
    _i1.ColumnSelections<LoteInsumoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LoteInsumo>(
      row,
      columns: columns?.call(LoteInsumo.t),
      transaction: transaction,
    );
  }

  /// Deletes all [LoteInsumo]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LoteInsumo>> delete(
    _i1.Session session,
    List<LoteInsumo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LoteInsumo>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LoteInsumo].
  Future<LoteInsumo> deleteRow(
    _i1.Session session,
    LoteInsumo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LoteInsumo>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LoteInsumo>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<LoteInsumoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LoteInsumo>(
      where: where(LoteInsumo.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LoteInsumoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LoteInsumo>(
      where: where?.call(LoteInsumo.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
