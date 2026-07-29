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

abstract class TaxaEntrega
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  TaxaEntrega._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.nome,
    required this.tipoRegra,
    this.bairro,
    this.cepInicial,
    this.cepFinal,
    required this.valorCentavos,
    required this.ativo,
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

  factory TaxaEntrega({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String tipoRegra,
    String? bairro,
    String? cepInicial,
    String? cepFinal,
    required int valorCentavos,
    required bool ativo,
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
  }) = _TaxaEntregaImpl;

  factory TaxaEntrega.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaxaEntrega(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      nome: jsonSerialization['nome'] as String,
      tipoRegra: jsonSerialization['tipoRegra'] as String,
      bairro: jsonSerialization['bairro'] as String?,
      cepInicial: jsonSerialization['cepInicial'] as String?,
      cepFinal: jsonSerialization['cepFinal'] as String?,
      valorCentavos: jsonSerialization['valorCentavos'] as int,
      ativo: jsonSerialization['ativo'] as bool,
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

  static final t = TaxaEntregaTable();

  static const db = TaxaEntregaRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String nome;

  String tipoRegra;

  String? bairro;

  String? cepInicial;

  String? cepFinal;

  int valorCentavos;

  bool ativo;

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

  /// Returns a shallow copy of this [TaxaEntrega]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TaxaEntrega copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? tipoRegra,
    String? bairro,
    String? cepInicial,
    String? cepFinal,
    int? valorCentavos,
    bool? ativo,
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
      'tipoRegra': tipoRegra,
      if (bairro != null) 'bairro': bairro,
      if (cepInicial != null) 'cepInicial': cepInicial,
      if (cepFinal != null) 'cepFinal': cepFinal,
      'valorCentavos': valorCentavos,
      'ativo': ativo,
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
      'tipoRegra': tipoRegra,
      if (bairro != null) 'bairro': bairro,
      if (cepInicial != null) 'cepInicial': cepInicial,
      if (cepFinal != null) 'cepFinal': cepFinal,
      'valorCentavos': valorCentavos,
      'ativo': ativo,
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

  static TaxaEntregaInclude include() {
    return TaxaEntregaInclude._();
  }

  static TaxaEntregaIncludeList includeList({
    _i1.WhereExpressionBuilder<TaxaEntregaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaxaEntregaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaxaEntregaTable>? orderByList,
    TaxaEntregaInclude? include,
  }) {
    return TaxaEntregaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaxaEntrega.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TaxaEntrega.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaxaEntregaImpl extends TaxaEntrega {
  _TaxaEntregaImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String tipoRegra,
    String? bairro,
    String? cepInicial,
    String? cepFinal,
    required int valorCentavos,
    required bool ativo,
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
          tipoRegra: tipoRegra,
          bairro: bairro,
          cepInicial: cepInicial,
          cepFinal: cepFinal,
          valorCentavos: valorCentavos,
          ativo: ativo,
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

  /// Returns a shallow copy of this [TaxaEntrega]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TaxaEntrega copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? tipoRegra,
    Object? bairro = _Undefined,
    Object? cepInicial = _Undefined,
    Object? cepFinal = _Undefined,
    int? valorCentavos,
    bool? ativo,
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
    return TaxaEntrega(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      tipoRegra: tipoRegra ?? this.tipoRegra,
      bairro: bairro is String? ? bairro : this.bairro,
      cepInicial: cepInicial is String? ? cepInicial : this.cepInicial,
      cepFinal: cepFinal is String? ? cepFinal : this.cepFinal,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      ativo: ativo ?? this.ativo,
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

class TaxaEntregaTable extends _i1.Table<_i1.UuidValue> {
  TaxaEntregaTable({super.tableRelation}) : super(tableName: 'taxa_entrega') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    tipoRegra = _i1.ColumnString(
      'tipoRegra',
      this,
    );
    bairro = _i1.ColumnString(
      'bairro',
      this,
    );
    cepInicial = _i1.ColumnString(
      'cepInicial',
      this,
    );
    cepFinal = _i1.ColumnString(
      'cepFinal',
      this,
    );
    valorCentavos = _i1.ColumnInt(
      'valorCentavos',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
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

  late final _i1.ColumnString tipoRegra;

  late final _i1.ColumnString bairro;

  late final _i1.ColumnString cepInicial;

  late final _i1.ColumnString cepFinal;

  late final _i1.ColumnInt valorCentavos;

  late final _i1.ColumnBool ativo;

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
        tipoRegra,
        bairro,
        cepInicial,
        cepFinal,
        valorCentavos,
        ativo,
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

class TaxaEntregaInclude extends _i1.IncludeObject {
  TaxaEntregaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => TaxaEntrega.t;
}

class TaxaEntregaIncludeList extends _i1.IncludeList {
  TaxaEntregaIncludeList._({
    _i1.WhereExpressionBuilder<TaxaEntregaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaxaEntrega.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => TaxaEntrega.t;
}

class TaxaEntregaRepository {
  const TaxaEntregaRepository._();

  /// Returns a list of [TaxaEntrega]s matching the given query parameters.
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
  Future<List<TaxaEntrega>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaxaEntregaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaxaEntregaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaxaEntregaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TaxaEntrega>(
      where: where?.call(TaxaEntrega.t),
      orderBy: orderBy?.call(TaxaEntrega.t),
      orderByList: orderByList?.call(TaxaEntrega.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TaxaEntrega] matching the given query parameters.
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
  Future<TaxaEntrega?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaxaEntregaTable>? where,
    int? offset,
    _i1.OrderByBuilder<TaxaEntregaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaxaEntregaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TaxaEntrega>(
      where: where?.call(TaxaEntrega.t),
      orderBy: orderBy?.call(TaxaEntrega.t),
      orderByList: orderByList?.call(TaxaEntrega.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TaxaEntrega] by its [id] or null if no such row exists.
  Future<TaxaEntrega?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TaxaEntrega>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TaxaEntrega]s in the list and returns the inserted rows.
  ///
  /// The returned [TaxaEntrega]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TaxaEntrega>> insert(
    _i1.Session session,
    List<TaxaEntrega> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TaxaEntrega>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TaxaEntrega] and returns the inserted row.
  ///
  /// The returned [TaxaEntrega] will have its `id` field set.
  Future<TaxaEntrega> insertRow(
    _i1.Session session,
    TaxaEntrega row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaxaEntrega>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TaxaEntrega]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TaxaEntrega>> update(
    _i1.Session session,
    List<TaxaEntrega> rows, {
    _i1.ColumnSelections<TaxaEntregaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TaxaEntrega>(
      rows,
      columns: columns?.call(TaxaEntrega.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaxaEntrega]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaxaEntrega> updateRow(
    _i1.Session session,
    TaxaEntrega row, {
    _i1.ColumnSelections<TaxaEntregaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaxaEntrega>(
      row,
      columns: columns?.call(TaxaEntrega.t),
      transaction: transaction,
    );
  }

  /// Deletes all [TaxaEntrega]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TaxaEntrega>> delete(
    _i1.Session session,
    List<TaxaEntrega> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TaxaEntrega>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TaxaEntrega].
  Future<TaxaEntrega> deleteRow(
    _i1.Session session,
    TaxaEntrega row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaxaEntrega>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TaxaEntrega>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TaxaEntregaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TaxaEntrega>(
      where: where(TaxaEntrega.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaxaEntregaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TaxaEntrega>(
      where: where?.call(TaxaEntrega.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
