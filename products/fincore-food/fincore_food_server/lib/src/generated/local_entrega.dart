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

abstract class LocalEntrega
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  LocalEntrega._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.clienteId,
    required this.nomeIdentificador,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.cep,
    required this.referencia,
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

  factory LocalEntrega({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue clienteId,
    required String nomeIdentificador,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String cep,
    required String referencia,
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
  }) = _LocalEntregaImpl;

  factory LocalEntrega.fromJson(Map<String, dynamic> jsonSerialization) {
    return LocalEntrega(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      clienteId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['clienteId']),
      nomeIdentificador: jsonSerialization['nomeIdentificador'] as String,
      logradouro: jsonSerialization['logradouro'] as String,
      numero: jsonSerialization['numero'] as String,
      bairro: jsonSerialization['bairro'] as String,
      cidade: jsonSerialization['cidade'] as String,
      cep: jsonSerialization['cep'] as String,
      referencia: jsonSerialization['referencia'] as String,
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

  static final t = LocalEntregaTable();

  static const db = LocalEntregaRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue clienteId;

  String nomeIdentificador;

  String logradouro;

  String numero;

  String bairro;

  String cidade;

  String cep;

  String referencia;

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

  /// Returns a shallow copy of this [LocalEntrega]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LocalEntrega copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? clienteId,
    String? nomeIdentificador,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? cep,
    String? referencia,
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
      'clienteId': clienteId.toJson(),
      'nomeIdentificador': nomeIdentificador,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'cep': cep,
      'referencia': referencia,
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
      'clienteId': clienteId.toJson(),
      'nomeIdentificador': nomeIdentificador,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'cep': cep,
      'referencia': referencia,
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

  static LocalEntregaInclude include() {
    return LocalEntregaInclude._();
  }

  static LocalEntregaIncludeList includeList({
    _i1.WhereExpressionBuilder<LocalEntregaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LocalEntregaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LocalEntregaTable>? orderByList,
    LocalEntregaInclude? include,
  }) {
    return LocalEntregaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LocalEntrega.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LocalEntrega.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LocalEntregaImpl extends LocalEntrega {
  _LocalEntregaImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue clienteId,
    required String nomeIdentificador,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String cep,
    required String referencia,
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
          clienteId: clienteId,
          nomeIdentificador: nomeIdentificador,
          logradouro: logradouro,
          numero: numero,
          bairro: bairro,
          cidade: cidade,
          cep: cep,
          referencia: referencia,
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

  /// Returns a shallow copy of this [LocalEntrega]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LocalEntrega copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? clienteId,
    String? nomeIdentificador,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? cep,
    String? referencia,
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
    return LocalEntrega(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      clienteId: clienteId ?? this.clienteId,
      nomeIdentificador: nomeIdentificador ?? this.nomeIdentificador,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      cep: cep ?? this.cep,
      referencia: referencia ?? this.referencia,
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

class LocalEntregaTable extends _i1.Table<_i1.UuidValue> {
  LocalEntregaTable({super.tableRelation}) : super(tableName: 'local_entrega') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    clienteId = _i1.ColumnUuid(
      'clienteId',
      this,
    );
    nomeIdentificador = _i1.ColumnString(
      'nomeIdentificador',
      this,
    );
    logradouro = _i1.ColumnString(
      'logradouro',
      this,
    );
    numero = _i1.ColumnString(
      'numero',
      this,
    );
    bairro = _i1.ColumnString(
      'bairro',
      this,
    );
    cidade = _i1.ColumnString(
      'cidade',
      this,
    );
    cep = _i1.ColumnString(
      'cep',
      this,
    );
    referencia = _i1.ColumnString(
      'referencia',
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

  late final _i1.ColumnUuid clienteId;

  late final _i1.ColumnString nomeIdentificador;

  late final _i1.ColumnString logradouro;

  late final _i1.ColumnString numero;

  late final _i1.ColumnString bairro;

  late final _i1.ColumnString cidade;

  late final _i1.ColumnString cep;

  late final _i1.ColumnString referencia;

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
        clienteId,
        nomeIdentificador,
        logradouro,
        numero,
        bairro,
        cidade,
        cep,
        referencia,
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

class LocalEntregaInclude extends _i1.IncludeObject {
  LocalEntregaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => LocalEntrega.t;
}

class LocalEntregaIncludeList extends _i1.IncludeList {
  LocalEntregaIncludeList._({
    _i1.WhereExpressionBuilder<LocalEntregaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LocalEntrega.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => LocalEntrega.t;
}

class LocalEntregaRepository {
  const LocalEntregaRepository._();

  /// Returns a list of [LocalEntrega]s matching the given query parameters.
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
  Future<List<LocalEntrega>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LocalEntregaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LocalEntregaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LocalEntregaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<LocalEntrega>(
      where: where?.call(LocalEntrega.t),
      orderBy: orderBy?.call(LocalEntrega.t),
      orderByList: orderByList?.call(LocalEntrega.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [LocalEntrega] matching the given query parameters.
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
  Future<LocalEntrega?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LocalEntregaTable>? where,
    int? offset,
    _i1.OrderByBuilder<LocalEntregaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LocalEntregaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<LocalEntrega>(
      where: where?.call(LocalEntrega.t),
      orderBy: orderBy?.call(LocalEntrega.t),
      orderByList: orderByList?.call(LocalEntrega.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [LocalEntrega] by its [id] or null if no such row exists.
  Future<LocalEntrega?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<LocalEntrega>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [LocalEntrega]s in the list and returns the inserted rows.
  ///
  /// The returned [LocalEntrega]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<LocalEntrega>> insert(
    _i1.Session session,
    List<LocalEntrega> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<LocalEntrega>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [LocalEntrega] and returns the inserted row.
  ///
  /// The returned [LocalEntrega] will have its `id` field set.
  Future<LocalEntrega> insertRow(
    _i1.Session session,
    LocalEntrega row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LocalEntrega>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LocalEntrega]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LocalEntrega>> update(
    _i1.Session session,
    List<LocalEntrega> rows, {
    _i1.ColumnSelections<LocalEntregaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LocalEntrega>(
      rows,
      columns: columns?.call(LocalEntrega.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LocalEntrega]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LocalEntrega> updateRow(
    _i1.Session session,
    LocalEntrega row, {
    _i1.ColumnSelections<LocalEntregaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LocalEntrega>(
      row,
      columns: columns?.call(LocalEntrega.t),
      transaction: transaction,
    );
  }

  /// Deletes all [LocalEntrega]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LocalEntrega>> delete(
    _i1.Session session,
    List<LocalEntrega> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LocalEntrega>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LocalEntrega].
  Future<LocalEntrega> deleteRow(
    _i1.Session session,
    LocalEntrega row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LocalEntrega>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LocalEntrega>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<LocalEntregaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LocalEntrega>(
      where: where(LocalEntrega.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LocalEntregaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LocalEntrega>(
      where: where?.call(LocalEntrega.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
