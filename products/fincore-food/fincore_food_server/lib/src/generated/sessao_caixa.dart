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

abstract class SessaoCaixa
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  SessaoCaixa._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.operadorId,
    String? operadorNome,
    String? status,
    required this.dataAbertura,
    this.dataFechamento,
    int? valorAberturaCentavos,
    this.valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    this.diferencaCentavos,
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
  })  : id = id ?? _i1.Uuid().v4obj(),
        operadorNome = operadorNome ?? 'Operador',
        status = status ?? 'aberta',
        valorAberturaCentavos = valorAberturaCentavos ?? 0,
        totalVendasCentavos = totalVendasCentavos ?? 0,
        totalDespesasCentavos = totalDespesasCentavos ?? 0;

  factory SessaoCaixa({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue operadorId,
    String? operadorNome,
    String? status,
    required DateTime dataAbertura,
    DateTime? dataFechamento,
    int? valorAberturaCentavos,
    int? valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    int? diferencaCentavos,
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
  }) = _SessaoCaixaImpl;

  factory SessaoCaixa.fromJson(Map<String, dynamic> jsonSerialization) {
    return SessaoCaixa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      operadorId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['operadorId']),
      operadorNome: jsonSerialization['operadorNome'] as String,
      status: jsonSerialization['status'] as String,
      dataAbertura:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataAbertura']),
      dataFechamento: jsonSerialization['dataFechamento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dataFechamento']),
      valorAberturaCentavos: jsonSerialization['valorAberturaCentavos'] as int,
      valorFechamentoCentavos:
          jsonSerialization['valorFechamentoCentavos'] as int?,
      totalVendasCentavos: jsonSerialization['totalVendasCentavos'] as int,
      totalDespesasCentavos: jsonSerialization['totalDespesasCentavos'] as int,
      diferencaCentavos: jsonSerialization['diferencaCentavos'] as int?,
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

  static final t = SessaoCaixaTable();

  static const db = SessaoCaixaRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue operadorId;

  String operadorNome;

  String status;

  DateTime dataAbertura;

  DateTime? dataFechamento;

  int valorAberturaCentavos;

  int? valorFechamentoCentavos;

  int totalVendasCentavos;

  int totalDespesasCentavos;

  int? diferencaCentavos;

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

  /// Returns a shallow copy of this [SessaoCaixa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SessaoCaixa copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? operadorId,
    String? operadorNome,
    String? status,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    int? valorAberturaCentavos,
    int? valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    int? diferencaCentavos,
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
      'operadorId': operadorId.toJson(),
      'operadorNome': operadorNome,
      'status': status,
      'dataAbertura': dataAbertura.toJson(),
      if (dataFechamento != null) 'dataFechamento': dataFechamento?.toJson(),
      'valorAberturaCentavos': valorAberturaCentavos,
      if (valorFechamentoCentavos != null)
        'valorFechamentoCentavos': valorFechamentoCentavos,
      'totalVendasCentavos': totalVendasCentavos,
      'totalDespesasCentavos': totalDespesasCentavos,
      if (diferencaCentavos != null) 'diferencaCentavos': diferencaCentavos,
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
      'operadorId': operadorId.toJson(),
      'operadorNome': operadorNome,
      'status': status,
      'dataAbertura': dataAbertura.toJson(),
      if (dataFechamento != null) 'dataFechamento': dataFechamento?.toJson(),
      'valorAberturaCentavos': valorAberturaCentavos,
      if (valorFechamentoCentavos != null)
        'valorFechamentoCentavos': valorFechamentoCentavos,
      'totalVendasCentavos': totalVendasCentavos,
      'totalDespesasCentavos': totalDespesasCentavos,
      if (diferencaCentavos != null) 'diferencaCentavos': diferencaCentavos,
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

  static SessaoCaixaInclude include() {
    return SessaoCaixaInclude._();
  }

  static SessaoCaixaIncludeList includeList({
    _i1.WhereExpressionBuilder<SessaoCaixaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SessaoCaixaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SessaoCaixaTable>? orderByList,
    SessaoCaixaInclude? include,
  }) {
    return SessaoCaixaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SessaoCaixa.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SessaoCaixa.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SessaoCaixaImpl extends SessaoCaixa {
  _SessaoCaixaImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue operadorId,
    String? operadorNome,
    String? status,
    required DateTime dataAbertura,
    DateTime? dataFechamento,
    int? valorAberturaCentavos,
    int? valorFechamentoCentavos,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    int? diferencaCentavos,
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
          operadorId: operadorId,
          operadorNome: operadorNome,
          status: status,
          dataAbertura: dataAbertura,
          dataFechamento: dataFechamento,
          valorAberturaCentavos: valorAberturaCentavos,
          valorFechamentoCentavos: valorFechamentoCentavos,
          totalVendasCentavos: totalVendasCentavos,
          totalDespesasCentavos: totalDespesasCentavos,
          diferencaCentavos: diferencaCentavos,
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

  /// Returns a shallow copy of this [SessaoCaixa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SessaoCaixa copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? operadorId,
    String? operadorNome,
    String? status,
    DateTime? dataAbertura,
    Object? dataFechamento = _Undefined,
    int? valorAberturaCentavos,
    Object? valorFechamentoCentavos = _Undefined,
    int? totalVendasCentavos,
    int? totalDespesasCentavos,
    Object? diferencaCentavos = _Undefined,
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
    return SessaoCaixa(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      operadorId: operadorId ?? this.operadorId,
      operadorNome: operadorNome ?? this.operadorNome,
      status: status ?? this.status,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataFechamento:
          dataFechamento is DateTime? ? dataFechamento : this.dataFechamento,
      valorAberturaCentavos:
          valorAberturaCentavos ?? this.valorAberturaCentavos,
      valorFechamentoCentavos: valorFechamentoCentavos is int?
          ? valorFechamentoCentavos
          : this.valorFechamentoCentavos,
      totalVendasCentavos: totalVendasCentavos ?? this.totalVendasCentavos,
      totalDespesasCentavos:
          totalDespesasCentavos ?? this.totalDespesasCentavos,
      diferencaCentavos: diferencaCentavos is int?
          ? diferencaCentavos
          : this.diferencaCentavos,
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

class SessaoCaixaTable extends _i1.Table<_i1.UuidValue> {
  SessaoCaixaTable({super.tableRelation}) : super(tableName: 'sessao_caixa') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    operadorId = _i1.ColumnUuid(
      'operadorId',
      this,
    );
    operadorNome = _i1.ColumnString(
      'operadorNome',
      this,
      hasDefault: true,
    );
    status = _i1.ColumnString(
      'status',
      this,
      hasDefault: true,
    );
    dataAbertura = _i1.ColumnDateTime(
      'dataAbertura',
      this,
    );
    dataFechamento = _i1.ColumnDateTime(
      'dataFechamento',
      this,
    );
    valorAberturaCentavos = _i1.ColumnInt(
      'valorAberturaCentavos',
      this,
      hasDefault: true,
    );
    valorFechamentoCentavos = _i1.ColumnInt(
      'valorFechamentoCentavos',
      this,
    );
    totalVendasCentavos = _i1.ColumnInt(
      'totalVendasCentavos',
      this,
      hasDefault: true,
    );
    totalDespesasCentavos = _i1.ColumnInt(
      'totalDespesasCentavos',
      this,
      hasDefault: true,
    );
    diferencaCentavos = _i1.ColumnInt(
      'diferencaCentavos',
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

  late final _i1.ColumnUuid operadorId;

  late final _i1.ColumnString operadorNome;

  late final _i1.ColumnString status;

  late final _i1.ColumnDateTime dataAbertura;

  late final _i1.ColumnDateTime dataFechamento;

  late final _i1.ColumnInt valorAberturaCentavos;

  late final _i1.ColumnInt valorFechamentoCentavos;

  late final _i1.ColumnInt totalVendasCentavos;

  late final _i1.ColumnInt totalDespesasCentavos;

  late final _i1.ColumnInt diferencaCentavos;

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
        operadorId,
        operadorNome,
        status,
        dataAbertura,
        dataFechamento,
        valorAberturaCentavos,
        valorFechamentoCentavos,
        totalVendasCentavos,
        totalDespesasCentavos,
        diferencaCentavos,
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

class SessaoCaixaInclude extends _i1.IncludeObject {
  SessaoCaixaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => SessaoCaixa.t;
}

class SessaoCaixaIncludeList extends _i1.IncludeList {
  SessaoCaixaIncludeList._({
    _i1.WhereExpressionBuilder<SessaoCaixaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SessaoCaixa.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => SessaoCaixa.t;
}

class SessaoCaixaRepository {
  const SessaoCaixaRepository._();

  /// Returns a list of [SessaoCaixa]s matching the given query parameters.
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
  Future<List<SessaoCaixa>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SessaoCaixaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SessaoCaixaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SessaoCaixaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<SessaoCaixa>(
      where: where?.call(SessaoCaixa.t),
      orderBy: orderBy?.call(SessaoCaixa.t),
      orderByList: orderByList?.call(SessaoCaixa.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [SessaoCaixa] matching the given query parameters.
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
  Future<SessaoCaixa?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SessaoCaixaTable>? where,
    int? offset,
    _i1.OrderByBuilder<SessaoCaixaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SessaoCaixaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<SessaoCaixa>(
      where: where?.call(SessaoCaixa.t),
      orderBy: orderBy?.call(SessaoCaixa.t),
      orderByList: orderByList?.call(SessaoCaixa.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [SessaoCaixa] by its [id] or null if no such row exists.
  Future<SessaoCaixa?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<SessaoCaixa>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [SessaoCaixa]s in the list and returns the inserted rows.
  ///
  /// The returned [SessaoCaixa]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<SessaoCaixa>> insert(
    _i1.Session session,
    List<SessaoCaixa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<SessaoCaixa>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [SessaoCaixa] and returns the inserted row.
  ///
  /// The returned [SessaoCaixa] will have its `id` field set.
  Future<SessaoCaixa> insertRow(
    _i1.Session session,
    SessaoCaixa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SessaoCaixa>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SessaoCaixa]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SessaoCaixa>> update(
    _i1.Session session,
    List<SessaoCaixa> rows, {
    _i1.ColumnSelections<SessaoCaixaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SessaoCaixa>(
      rows,
      columns: columns?.call(SessaoCaixa.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SessaoCaixa]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SessaoCaixa> updateRow(
    _i1.Session session,
    SessaoCaixa row, {
    _i1.ColumnSelections<SessaoCaixaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SessaoCaixa>(
      row,
      columns: columns?.call(SessaoCaixa.t),
      transaction: transaction,
    );
  }

  /// Deletes all [SessaoCaixa]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SessaoCaixa>> delete(
    _i1.Session session,
    List<SessaoCaixa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SessaoCaixa>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SessaoCaixa].
  Future<SessaoCaixa> deleteRow(
    _i1.Session session,
    SessaoCaixa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SessaoCaixa>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SessaoCaixa>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SessaoCaixaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SessaoCaixa>(
      where: where(SessaoCaixa.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SessaoCaixaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SessaoCaixa>(
      where: where?.call(SessaoCaixa.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
