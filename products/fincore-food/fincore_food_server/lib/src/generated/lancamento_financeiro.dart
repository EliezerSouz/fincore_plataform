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

abstract class LancamentoFinanceiro
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  LancamentoFinanceiro._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.sessaoCaixaId,
    this.pedidoId,
    required this.tipo,
    this.formaPagamentoId,
    this.formaPagamentoNome,
    required this.valorCentavos,
    String? descricao,
    this.operadorId,
    required this.dataHora,
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
        descricao = descricao ?? '';

  factory LancamentoFinanceiro({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue sessaoCaixaId,
    _i1.UuidValue? pedidoId,
    required String tipo,
    _i1.UuidValue? formaPagamentoId,
    String? formaPagamentoNome,
    required int valorCentavos,
    String? descricao,
    _i1.UuidValue? operadorId,
    required DateTime dataHora,
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
  }) = _LancamentoFinanceiroImpl;

  factory LancamentoFinanceiro.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return LancamentoFinanceiro(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      sessaoCaixaId: _i1.UuidValueJsonExtension.fromJson(
          jsonSerialization['sessaoCaixaId']),
      pedidoId: jsonSerialization['pedidoId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['pedidoId']),
      tipo: jsonSerialization['tipo'] as String,
      formaPagamentoId: jsonSerialization['formaPagamentoId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['formaPagamentoId']),
      formaPagamentoNome: jsonSerialization['formaPagamentoNome'] as String?,
      valorCentavos: jsonSerialization['valorCentavos'] as int,
      descricao: jsonSerialization['descricao'] as String,
      operadorId: jsonSerialization['operadorId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['operadorId']),
      dataHora:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataHora']),
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

  static final t = LancamentoFinanceiroTable();

  static const db = LancamentoFinanceiroRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue sessaoCaixaId;

  _i1.UuidValue? pedidoId;

  String tipo;

  _i1.UuidValue? formaPagamentoId;

  String? formaPagamentoNome;

  int valorCentavos;

  String descricao;

  _i1.UuidValue? operadorId;

  DateTime dataHora;

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

  /// Returns a shallow copy of this [LancamentoFinanceiro]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LancamentoFinanceiro copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? sessaoCaixaId,
    _i1.UuidValue? pedidoId,
    String? tipo,
    _i1.UuidValue? formaPagamentoId,
    String? formaPagamentoNome,
    int? valorCentavos,
    String? descricao,
    _i1.UuidValue? operadorId,
    DateTime? dataHora,
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
      'sessaoCaixaId': sessaoCaixaId.toJson(),
      if (pedidoId != null) 'pedidoId': pedidoId?.toJson(),
      'tipo': tipo,
      if (formaPagamentoId != null)
        'formaPagamentoId': formaPagamentoId?.toJson(),
      if (formaPagamentoNome != null) 'formaPagamentoNome': formaPagamentoNome,
      'valorCentavos': valorCentavos,
      'descricao': descricao,
      if (operadorId != null) 'operadorId': operadorId?.toJson(),
      'dataHora': dataHora.toJson(),
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
      'sessaoCaixaId': sessaoCaixaId.toJson(),
      if (pedidoId != null) 'pedidoId': pedidoId?.toJson(),
      'tipo': tipo,
      if (formaPagamentoId != null)
        'formaPagamentoId': formaPagamentoId?.toJson(),
      if (formaPagamentoNome != null) 'formaPagamentoNome': formaPagamentoNome,
      'valorCentavos': valorCentavos,
      'descricao': descricao,
      if (operadorId != null) 'operadorId': operadorId?.toJson(),
      'dataHora': dataHora.toJson(),
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

  static LancamentoFinanceiroInclude include() {
    return LancamentoFinanceiroInclude._();
  }

  static LancamentoFinanceiroIncludeList includeList({
    _i1.WhereExpressionBuilder<LancamentoFinanceiroTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LancamentoFinanceiroTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LancamentoFinanceiroTable>? orderByList,
    LancamentoFinanceiroInclude? include,
  }) {
    return LancamentoFinanceiroIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LancamentoFinanceiro.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LancamentoFinanceiro.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LancamentoFinanceiroImpl extends LancamentoFinanceiro {
  _LancamentoFinanceiroImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue sessaoCaixaId,
    _i1.UuidValue? pedidoId,
    required String tipo,
    _i1.UuidValue? formaPagamentoId,
    String? formaPagamentoNome,
    required int valorCentavos,
    String? descricao,
    _i1.UuidValue? operadorId,
    required DateTime dataHora,
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
          sessaoCaixaId: sessaoCaixaId,
          pedidoId: pedidoId,
          tipo: tipo,
          formaPagamentoId: formaPagamentoId,
          formaPagamentoNome: formaPagamentoNome,
          valorCentavos: valorCentavos,
          descricao: descricao,
          operadorId: operadorId,
          dataHora: dataHora,
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

  /// Returns a shallow copy of this [LancamentoFinanceiro]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LancamentoFinanceiro copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? sessaoCaixaId,
    Object? pedidoId = _Undefined,
    String? tipo,
    Object? formaPagamentoId = _Undefined,
    Object? formaPagamentoNome = _Undefined,
    int? valorCentavos,
    String? descricao,
    Object? operadorId = _Undefined,
    DateTime? dataHora,
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
    return LancamentoFinanceiro(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      sessaoCaixaId: sessaoCaixaId ?? this.sessaoCaixaId,
      pedidoId: pedidoId is _i1.UuidValue? ? pedidoId : this.pedidoId,
      tipo: tipo ?? this.tipo,
      formaPagamentoId: formaPagamentoId is _i1.UuidValue?
          ? formaPagamentoId
          : this.formaPagamentoId,
      formaPagamentoNome: formaPagamentoNome is String?
          ? formaPagamentoNome
          : this.formaPagamentoNome,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      descricao: descricao ?? this.descricao,
      operadorId: operadorId is _i1.UuidValue? ? operadorId : this.operadorId,
      dataHora: dataHora ?? this.dataHora,
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

class LancamentoFinanceiroTable extends _i1.Table<_i1.UuidValue> {
  LancamentoFinanceiroTable({super.tableRelation})
      : super(tableName: 'lancamento_financeiro') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    sessaoCaixaId = _i1.ColumnUuid(
      'sessaoCaixaId',
      this,
    );
    pedidoId = _i1.ColumnUuid(
      'pedidoId',
      this,
    );
    tipo = _i1.ColumnString(
      'tipo',
      this,
    );
    formaPagamentoId = _i1.ColumnUuid(
      'formaPagamentoId',
      this,
    );
    formaPagamentoNome = _i1.ColumnString(
      'formaPagamentoNome',
      this,
    );
    valorCentavos = _i1.ColumnInt(
      'valorCentavos',
      this,
    );
    descricao = _i1.ColumnString(
      'descricao',
      this,
      hasDefault: true,
    );
    operadorId = _i1.ColumnUuid(
      'operadorId',
      this,
    );
    dataHora = _i1.ColumnDateTime(
      'dataHora',
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

  late final _i1.ColumnUuid sessaoCaixaId;

  late final _i1.ColumnUuid pedidoId;

  late final _i1.ColumnString tipo;

  late final _i1.ColumnUuid formaPagamentoId;

  late final _i1.ColumnString formaPagamentoNome;

  late final _i1.ColumnInt valorCentavos;

  late final _i1.ColumnString descricao;

  late final _i1.ColumnUuid operadorId;

  late final _i1.ColumnDateTime dataHora;

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
        sessaoCaixaId,
        pedidoId,
        tipo,
        formaPagamentoId,
        formaPagamentoNome,
        valorCentavos,
        descricao,
        operadorId,
        dataHora,
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

class LancamentoFinanceiroInclude extends _i1.IncludeObject {
  LancamentoFinanceiroInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => LancamentoFinanceiro.t;
}

class LancamentoFinanceiroIncludeList extends _i1.IncludeList {
  LancamentoFinanceiroIncludeList._({
    _i1.WhereExpressionBuilder<LancamentoFinanceiroTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LancamentoFinanceiro.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => LancamentoFinanceiro.t;
}

class LancamentoFinanceiroRepository {
  const LancamentoFinanceiroRepository._();

  /// Returns a list of [LancamentoFinanceiro]s matching the given query parameters.
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
  Future<List<LancamentoFinanceiro>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LancamentoFinanceiroTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LancamentoFinanceiroTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LancamentoFinanceiroTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<LancamentoFinanceiro>(
      where: where?.call(LancamentoFinanceiro.t),
      orderBy: orderBy?.call(LancamentoFinanceiro.t),
      orderByList: orderByList?.call(LancamentoFinanceiro.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [LancamentoFinanceiro] matching the given query parameters.
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
  Future<LancamentoFinanceiro?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LancamentoFinanceiroTable>? where,
    int? offset,
    _i1.OrderByBuilder<LancamentoFinanceiroTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LancamentoFinanceiroTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<LancamentoFinanceiro>(
      where: where?.call(LancamentoFinanceiro.t),
      orderBy: orderBy?.call(LancamentoFinanceiro.t),
      orderByList: orderByList?.call(LancamentoFinanceiro.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [LancamentoFinanceiro] by its [id] or null if no such row exists.
  Future<LancamentoFinanceiro?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<LancamentoFinanceiro>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [LancamentoFinanceiro]s in the list and returns the inserted rows.
  ///
  /// The returned [LancamentoFinanceiro]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<LancamentoFinanceiro>> insert(
    _i1.Session session,
    List<LancamentoFinanceiro> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<LancamentoFinanceiro>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [LancamentoFinanceiro] and returns the inserted row.
  ///
  /// The returned [LancamentoFinanceiro] will have its `id` field set.
  Future<LancamentoFinanceiro> insertRow(
    _i1.Session session,
    LancamentoFinanceiro row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LancamentoFinanceiro>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LancamentoFinanceiro]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LancamentoFinanceiro>> update(
    _i1.Session session,
    List<LancamentoFinanceiro> rows, {
    _i1.ColumnSelections<LancamentoFinanceiroTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LancamentoFinanceiro>(
      rows,
      columns: columns?.call(LancamentoFinanceiro.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LancamentoFinanceiro]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LancamentoFinanceiro> updateRow(
    _i1.Session session,
    LancamentoFinanceiro row, {
    _i1.ColumnSelections<LancamentoFinanceiroTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LancamentoFinanceiro>(
      row,
      columns: columns?.call(LancamentoFinanceiro.t),
      transaction: transaction,
    );
  }

  /// Deletes all [LancamentoFinanceiro]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LancamentoFinanceiro>> delete(
    _i1.Session session,
    List<LancamentoFinanceiro> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LancamentoFinanceiro>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LancamentoFinanceiro].
  Future<LancamentoFinanceiro> deleteRow(
    _i1.Session session,
    LancamentoFinanceiro row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LancamentoFinanceiro>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LancamentoFinanceiro>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<LancamentoFinanceiroTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LancamentoFinanceiro>(
      where: where(LancamentoFinanceiro.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LancamentoFinanceiroTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LancamentoFinanceiro>(
      where: where?.call(LancamentoFinanceiro.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
