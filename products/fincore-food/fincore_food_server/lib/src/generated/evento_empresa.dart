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

abstract class EventoEmpresa
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  EventoEmpresa._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.tipo,
    this.payload,
    required this.geradoPor,
    required this.ocorridoEm,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory EventoEmpresa({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String tipo,
    String? payload,
    required String geradoPor,
    required DateTime ocorridoEm,
  }) = _EventoEmpresaImpl;

  factory EventoEmpresa.fromJson(Map<String, dynamic> jsonSerialization) {
    return EventoEmpresa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['tenantId']),
      tipo: jsonSerialization['tipo'] as String,
      payload: jsonSerialization['payload'] as String?,
      geradoPor: jsonSerialization['geradoPor'] as String,
      ocorridoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['ocorridoEm']),
    );
  }

  static final t = EventoEmpresaTable();

  static const db = EventoEmpresaRepository._();

  @override
  _i1.UuidValue id;

  _i1.UuidValue tenantId;

  String tipo;

  String? payload;

  String geradoPor;

  DateTime ocorridoEm;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [EventoEmpresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EventoEmpresa copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? tipo,
    String? payload,
    String? geradoPor,
    DateTime? ocorridoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId.toJson(),
      'tipo': tipo,
      if (payload != null) 'payload': payload,
      'geradoPor': geradoPor,
      'ocorridoEm': ocorridoEm.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId.toJson(),
      'tipo': tipo,
      if (payload != null) 'payload': payload,
      'geradoPor': geradoPor,
      'ocorridoEm': ocorridoEm.toJson(),
    };
  }

  static EventoEmpresaInclude include() {
    return EventoEmpresaInclude._();
  }

  static EventoEmpresaIncludeList includeList({
    _i1.WhereExpressionBuilder<EventoEmpresaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EventoEmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EventoEmpresaTable>? orderByList,
    EventoEmpresaInclude? include,
  }) {
    return EventoEmpresaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EventoEmpresa.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EventoEmpresa.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EventoEmpresaImpl extends EventoEmpresa {
  _EventoEmpresaImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String tipo,
    String? payload,
    required String geradoPor,
    required DateTime ocorridoEm,
  }) : super._(
          id: id,
          tenantId: tenantId,
          tipo: tipo,
          payload: payload,
          geradoPor: geradoPor,
          ocorridoEm: ocorridoEm,
        );

  /// Returns a shallow copy of this [EventoEmpresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EventoEmpresa copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? tipo,
    Object? payload = _Undefined,
    String? geradoPor,
    DateTime? ocorridoEm,
  }) {
    return EventoEmpresa(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tipo: tipo ?? this.tipo,
      payload: payload is String? ? payload : this.payload,
      geradoPor: geradoPor ?? this.geradoPor,
      ocorridoEm: ocorridoEm ?? this.ocorridoEm,
    );
  }
}

class EventoEmpresaTable extends _i1.Table<_i1.UuidValue> {
  EventoEmpresaTable({super.tableRelation})
      : super(tableName: 'eventos_empresa') {
    tenantId = _i1.ColumnUuid(
      'tenantId',
      this,
    );
    tipo = _i1.ColumnString(
      'tipo',
      this,
    );
    payload = _i1.ColumnString(
      'payload',
      this,
    );
    geradoPor = _i1.ColumnString(
      'geradoPor',
      this,
    );
    ocorridoEm = _i1.ColumnDateTime(
      'ocorridoEm',
      this,
    );
  }

  late final _i1.ColumnUuid tenantId;

  late final _i1.ColumnString tipo;

  late final _i1.ColumnString payload;

  late final _i1.ColumnString geradoPor;

  late final _i1.ColumnDateTime ocorridoEm;

  @override
  List<_i1.Column> get columns => [
        id,
        tenantId,
        tipo,
        payload,
        geradoPor,
        ocorridoEm,
      ];
}

class EventoEmpresaInclude extends _i1.IncludeObject {
  EventoEmpresaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => EventoEmpresa.t;
}

class EventoEmpresaIncludeList extends _i1.IncludeList {
  EventoEmpresaIncludeList._({
    _i1.WhereExpressionBuilder<EventoEmpresaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EventoEmpresa.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => EventoEmpresa.t;
}

class EventoEmpresaRepository {
  const EventoEmpresaRepository._();

  /// Returns a list of [EventoEmpresa]s matching the given query parameters.
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
  Future<List<EventoEmpresa>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EventoEmpresaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EventoEmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EventoEmpresaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<EventoEmpresa>(
      where: where?.call(EventoEmpresa.t),
      orderBy: orderBy?.call(EventoEmpresa.t),
      orderByList: orderByList?.call(EventoEmpresa.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [EventoEmpresa] matching the given query parameters.
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
  Future<EventoEmpresa?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EventoEmpresaTable>? where,
    int? offset,
    _i1.OrderByBuilder<EventoEmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EventoEmpresaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<EventoEmpresa>(
      where: where?.call(EventoEmpresa.t),
      orderBy: orderBy?.call(EventoEmpresa.t),
      orderByList: orderByList?.call(EventoEmpresa.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [EventoEmpresa] by its [id] or null if no such row exists.
  Future<EventoEmpresa?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<EventoEmpresa>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [EventoEmpresa]s in the list and returns the inserted rows.
  ///
  /// The returned [EventoEmpresa]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<EventoEmpresa>> insert(
    _i1.Session session,
    List<EventoEmpresa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<EventoEmpresa>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [EventoEmpresa] and returns the inserted row.
  ///
  /// The returned [EventoEmpresa] will have its `id` field set.
  Future<EventoEmpresa> insertRow(
    _i1.Session session,
    EventoEmpresa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EventoEmpresa>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EventoEmpresa]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EventoEmpresa>> update(
    _i1.Session session,
    List<EventoEmpresa> rows, {
    _i1.ColumnSelections<EventoEmpresaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EventoEmpresa>(
      rows,
      columns: columns?.call(EventoEmpresa.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EventoEmpresa]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EventoEmpresa> updateRow(
    _i1.Session session,
    EventoEmpresa row, {
    _i1.ColumnSelections<EventoEmpresaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EventoEmpresa>(
      row,
      columns: columns?.call(EventoEmpresa.t),
      transaction: transaction,
    );
  }

  /// Deletes all [EventoEmpresa]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EventoEmpresa>> delete(
    _i1.Session session,
    List<EventoEmpresa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EventoEmpresa>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EventoEmpresa].
  Future<EventoEmpresa> deleteRow(
    _i1.Session session,
    EventoEmpresa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EventoEmpresa>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EventoEmpresa>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EventoEmpresaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EventoEmpresa>(
      where: where(EventoEmpresa.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EventoEmpresaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EventoEmpresa>(
      where: where?.call(EventoEmpresa.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
