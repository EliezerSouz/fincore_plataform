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

abstract class Cliente
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  Cliente._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.nome,
    required this.telefone,
    this.email,
    this.documento,
    required this.observacoes,
    required this.ativo,
    this.apelido,
    this.dataNascimento,
    required this.aceitaWhatsapp,
    required this.aceitaMarketing,
    this.preferenciaEntrega,
    this.limiteCredito,
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

  factory Cliente({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String telefone,
    String? email,
    String? documento,
    required String observacoes,
    required bool ativo,
    String? apelido,
    DateTime? dataNascimento,
    required bool aceitaWhatsapp,
    required bool aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
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
  }) = _ClienteImpl;

  factory Cliente.fromJson(Map<String, dynamic> jsonSerialization) {
    return Cliente(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      nome: jsonSerialization['nome'] as String,
      telefone: jsonSerialization['telefone'] as String,
      email: jsonSerialization['email'] as String?,
      documento: jsonSerialization['documento'] as String?,
      observacoes: jsonSerialization['observacoes'] as String,
      ativo: jsonSerialization['ativo'] as bool,
      apelido: jsonSerialization['apelido'] as String?,
      dataNascimento: jsonSerialization['dataNascimento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dataNascimento']),
      aceitaWhatsapp: jsonSerialization['aceitaWhatsapp'] as bool,
      aceitaMarketing: jsonSerialization['aceitaMarketing'] as bool,
      preferenciaEntrega: jsonSerialization['preferenciaEntrega'] as String?,
      limiteCredito: jsonSerialization['limiteCredito'] as int?,
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

  static final t = ClienteTable();

  static const db = ClienteRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String nome;

  String telefone;

  String? email;

  String? documento;

  String observacoes;

  bool ativo;

  String? apelido;

  DateTime? dataNascimento;

  bool aceitaWhatsapp;

  bool aceitaMarketing;

  String? preferenciaEntrega;

  int? limiteCredito;

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

  /// Returns a shallow copy of this [Cliente]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Cliente copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? telefone,
    String? email,
    String? documento,
    String? observacoes,
    bool? ativo,
    String? apelido,
    DateTime? dataNascimento,
    bool? aceitaWhatsapp,
    bool? aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
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
      'telefone': telefone,
      if (email != null) 'email': email,
      if (documento != null) 'documento': documento,
      'observacoes': observacoes,
      'ativo': ativo,
      if (apelido != null) 'apelido': apelido,
      if (dataNascimento != null) 'dataNascimento': dataNascimento?.toJson(),
      'aceitaWhatsapp': aceitaWhatsapp,
      'aceitaMarketing': aceitaMarketing,
      if (preferenciaEntrega != null) 'preferenciaEntrega': preferenciaEntrega,
      if (limiteCredito != null) 'limiteCredito': limiteCredito,
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
      'telefone': telefone,
      if (email != null) 'email': email,
      if (documento != null) 'documento': documento,
      'observacoes': observacoes,
      'ativo': ativo,
      if (apelido != null) 'apelido': apelido,
      if (dataNascimento != null) 'dataNascimento': dataNascimento?.toJson(),
      'aceitaWhatsapp': aceitaWhatsapp,
      'aceitaMarketing': aceitaMarketing,
      if (preferenciaEntrega != null) 'preferenciaEntrega': preferenciaEntrega,
      if (limiteCredito != null) 'limiteCredito': limiteCredito,
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

  static ClienteInclude include() {
    return ClienteInclude._();
  }

  static ClienteIncludeList includeList({
    _i1.WhereExpressionBuilder<ClienteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ClienteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ClienteTable>? orderByList,
    ClienteInclude? include,
  }) {
    return ClienteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Cliente.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Cliente.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ClienteImpl extends Cliente {
  _ClienteImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String telefone,
    String? email,
    String? documento,
    required String observacoes,
    required bool ativo,
    String? apelido,
    DateTime? dataNascimento,
    required bool aceitaWhatsapp,
    required bool aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
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
          telefone: telefone,
          email: email,
          documento: documento,
          observacoes: observacoes,
          ativo: ativo,
          apelido: apelido,
          dataNascimento: dataNascimento,
          aceitaWhatsapp: aceitaWhatsapp,
          aceitaMarketing: aceitaMarketing,
          preferenciaEntrega: preferenciaEntrega,
          limiteCredito: limiteCredito,
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

  /// Returns a shallow copy of this [Cliente]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Cliente copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? telefone,
    Object? email = _Undefined,
    Object? documento = _Undefined,
    String? observacoes,
    bool? ativo,
    Object? apelido = _Undefined,
    Object? dataNascimento = _Undefined,
    bool? aceitaWhatsapp,
    bool? aceitaMarketing,
    Object? preferenciaEntrega = _Undefined,
    Object? limiteCredito = _Undefined,
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
    return Cliente(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email is String? ? email : this.email,
      documento: documento is String? ? documento : this.documento,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      apelido: apelido is String? ? apelido : this.apelido,
      dataNascimento:
          dataNascimento is DateTime? ? dataNascimento : this.dataNascimento,
      aceitaWhatsapp: aceitaWhatsapp ?? this.aceitaWhatsapp,
      aceitaMarketing: aceitaMarketing ?? this.aceitaMarketing,
      preferenciaEntrega: preferenciaEntrega is String?
          ? preferenciaEntrega
          : this.preferenciaEntrega,
      limiteCredito: limiteCredito is int? ? limiteCredito : this.limiteCredito,
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

class ClienteTable extends _i1.Table<_i1.UuidValue> {
  ClienteTable({super.tableRelation}) : super(tableName: 'cliente') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    telefone = _i1.ColumnString(
      'telefone',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    documento = _i1.ColumnString(
      'documento',
      this,
    );
    observacoes = _i1.ColumnString(
      'observacoes',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    apelido = _i1.ColumnString(
      'apelido',
      this,
    );
    dataNascimento = _i1.ColumnDateTime(
      'dataNascimento',
      this,
    );
    aceitaWhatsapp = _i1.ColumnBool(
      'aceitaWhatsapp',
      this,
    );
    aceitaMarketing = _i1.ColumnBool(
      'aceitaMarketing',
      this,
    );
    preferenciaEntrega = _i1.ColumnString(
      'preferenciaEntrega',
      this,
    );
    limiteCredito = _i1.ColumnInt(
      'limiteCredito',
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

  late final _i1.ColumnString telefone;

  late final _i1.ColumnString email;

  late final _i1.ColumnString documento;

  late final _i1.ColumnString observacoes;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnString apelido;

  late final _i1.ColumnDateTime dataNascimento;

  late final _i1.ColumnBool aceitaWhatsapp;

  late final _i1.ColumnBool aceitaMarketing;

  late final _i1.ColumnString preferenciaEntrega;

  late final _i1.ColumnInt limiteCredito;

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
        telefone,
        email,
        documento,
        observacoes,
        ativo,
        apelido,
        dataNascimento,
        aceitaWhatsapp,
        aceitaMarketing,
        preferenciaEntrega,
        limiteCredito,
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

class ClienteInclude extends _i1.IncludeObject {
  ClienteInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => Cliente.t;
}

class ClienteIncludeList extends _i1.IncludeList {
  ClienteIncludeList._({
    _i1.WhereExpressionBuilder<ClienteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Cliente.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => Cliente.t;
}

class ClienteRepository {
  const ClienteRepository._();

  /// Returns a list of [Cliente]s matching the given query parameters.
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
  Future<List<Cliente>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ClienteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ClienteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ClienteTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Cliente>(
      where: where?.call(Cliente.t),
      orderBy: orderBy?.call(Cliente.t),
      orderByList: orderByList?.call(Cliente.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Cliente] matching the given query parameters.
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
  Future<Cliente?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ClienteTable>? where,
    int? offset,
    _i1.OrderByBuilder<ClienteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ClienteTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Cliente>(
      where: where?.call(Cliente.t),
      orderBy: orderBy?.call(Cliente.t),
      orderByList: orderByList?.call(Cliente.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Cliente] by its [id] or null if no such row exists.
  Future<Cliente?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Cliente>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Cliente]s in the list and returns the inserted rows.
  ///
  /// The returned [Cliente]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Cliente>> insert(
    _i1.Session session,
    List<Cliente> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Cliente>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Cliente] and returns the inserted row.
  ///
  /// The returned [Cliente] will have its `id` field set.
  Future<Cliente> insertRow(
    _i1.Session session,
    Cliente row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Cliente>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Cliente]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Cliente>> update(
    _i1.Session session,
    List<Cliente> rows, {
    _i1.ColumnSelections<ClienteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Cliente>(
      rows,
      columns: columns?.call(Cliente.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Cliente]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Cliente> updateRow(
    _i1.Session session,
    Cliente row, {
    _i1.ColumnSelections<ClienteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Cliente>(
      row,
      columns: columns?.call(Cliente.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Cliente]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Cliente>> delete(
    _i1.Session session,
    List<Cliente> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Cliente>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Cliente].
  Future<Cliente> deleteRow(
    _i1.Session session,
    Cliente row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Cliente>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Cliente>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ClienteTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Cliente>(
      where: where(Cliente.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ClienteTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Cliente>(
      where: where?.call(Cliente.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
