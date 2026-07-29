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

abstract class FormaPagamento
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  FormaPagamento._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.nome,
    required this.tipo,
    required this.ordem,
    required this.ativo,
    required this.permiteTroco,
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

  factory FormaPagamento({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String tipo,
    required int ordem,
    required bool ativo,
    required bool permiteTroco,
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
  }) = _FormaPagamentoImpl;

  factory FormaPagamento.fromJson(Map<String, dynamic> jsonSerialization) {
    return FormaPagamento(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      nome: jsonSerialization['nome'] as String,
      tipo: jsonSerialization['tipo'] as String,
      ordem: jsonSerialization['ordem'] as int,
      ativo: jsonSerialization['ativo'] as bool,
      permiteTroco: jsonSerialization['permiteTroco'] as bool,
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

  static final t = FormaPagamentoTable();

  static const db = FormaPagamentoRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String nome;

  String tipo;

  int ordem;

  bool ativo;

  bool permiteTroco;

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

  /// Returns a shallow copy of this [FormaPagamento]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FormaPagamento copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? tipo,
    int? ordem,
    bool? ativo,
    bool? permiteTroco,
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
      'nome': nome,
      'tipo': tipo,
      'ordem': ordem,
      'ativo': ativo,
      'permiteTroco': permiteTroco,
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
      'nome': nome,
      'tipo': tipo,
      'ordem': ordem,
      'ativo': ativo,
      'permiteTroco': permiteTroco,
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

  static FormaPagamentoInclude include() {
    return FormaPagamentoInclude._();
  }

  static FormaPagamentoIncludeList includeList({
    _i1.WhereExpressionBuilder<FormaPagamentoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FormaPagamentoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FormaPagamentoTable>? orderByList,
    FormaPagamentoInclude? include,
  }) {
    return FormaPagamentoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FormaPagamento.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(FormaPagamento.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FormaPagamentoImpl extends FormaPagamento {
  _FormaPagamentoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String tipo,
    required int ordem,
    required bool ativo,
    required bool permiteTroco,
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
          nome: nome,
          tipo: tipo,
          ordem: ordem,
          ativo: ativo,
          permiteTroco: permiteTroco,
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

  /// Returns a shallow copy of this [FormaPagamento]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FormaPagamento copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? tipo,
    int? ordem,
    bool? ativo,
    bool? permiteTroco,
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
    return FormaPagamento(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      permiteTroco: permiteTroco ?? this.permiteTroco,
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

class FormaPagamentoTable extends _i1.Table<_i1.UuidValue> {
  FormaPagamentoTable({super.tableRelation})
      : super(tableName: 'forma_pagamento') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    tipo = _i1.ColumnString(
      'tipo',
      this,
    );
    ordem = _i1.ColumnInt(
      'ordem',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    permiteTroco = _i1.ColumnBool(
      'permiteTroco',
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

  late final _i1.ColumnString nome;

  late final _i1.ColumnString tipo;

  late final _i1.ColumnInt ordem;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnBool permiteTroco;

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
        nome,
        tipo,
        ordem,
        ativo,
        permiteTroco,
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

class FormaPagamentoInclude extends _i1.IncludeObject {
  FormaPagamentoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => FormaPagamento.t;
}

class FormaPagamentoIncludeList extends _i1.IncludeList {
  FormaPagamentoIncludeList._({
    _i1.WhereExpressionBuilder<FormaPagamentoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FormaPagamento.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => FormaPagamento.t;
}

class FormaPagamentoRepository {
  const FormaPagamentoRepository._();

  /// Returns a list of [FormaPagamento]s matching the given query parameters.
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
  Future<List<FormaPagamento>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FormaPagamentoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FormaPagamentoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FormaPagamentoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<FormaPagamento>(
      where: where?.call(FormaPagamento.t),
      orderBy: orderBy?.call(FormaPagamento.t),
      orderByList: orderByList?.call(FormaPagamento.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [FormaPagamento] matching the given query parameters.
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
  Future<FormaPagamento?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FormaPagamentoTable>? where,
    int? offset,
    _i1.OrderByBuilder<FormaPagamentoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FormaPagamentoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<FormaPagamento>(
      where: where?.call(FormaPagamento.t),
      orderBy: orderBy?.call(FormaPagamento.t),
      orderByList: orderByList?.call(FormaPagamento.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [FormaPagamento] by its [id] or null if no such row exists.
  Future<FormaPagamento?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<FormaPagamento>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [FormaPagamento]s in the list and returns the inserted rows.
  ///
  /// The returned [FormaPagamento]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<FormaPagamento>> insert(
    _i1.Session session,
    List<FormaPagamento> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<FormaPagamento>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [FormaPagamento] and returns the inserted row.
  ///
  /// The returned [FormaPagamento] will have its `id` field set.
  Future<FormaPagamento> insertRow(
    _i1.Session session,
    FormaPagamento row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<FormaPagamento>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [FormaPagamento]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<FormaPagamento>> update(
    _i1.Session session,
    List<FormaPagamento> rows, {
    _i1.ColumnSelections<FormaPagamentoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<FormaPagamento>(
      rows,
      columns: columns?.call(FormaPagamento.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FormaPagamento]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FormaPagamento> updateRow(
    _i1.Session session,
    FormaPagamento row, {
    _i1.ColumnSelections<FormaPagamentoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<FormaPagamento>(
      row,
      columns: columns?.call(FormaPagamento.t),
      transaction: transaction,
    );
  }

  /// Deletes all [FormaPagamento]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<FormaPagamento>> delete(
    _i1.Session session,
    List<FormaPagamento> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<FormaPagamento>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [FormaPagamento].
  Future<FormaPagamento> deleteRow(
    _i1.Session session,
    FormaPagamento row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FormaPagamento>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<FormaPagamento>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<FormaPagamentoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<FormaPagamento>(
      where: where(FormaPagamento.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FormaPagamentoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<FormaPagamento>(
      where: where?.call(FormaPagamento.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
