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

abstract class Usuario
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  Usuario._({
    _i1.UuidValue? id,
    required this.tenantId,
    this.authUserId,
    required this.username,
    this.email,
    required this.nome,
    this.avatarUrl,
    required this.ativo,
    required this.criadoEm,
    required this.atualizadoEm,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory Usuario({
    _i1.UuidValue? id,
    required String tenantId,
    String? authUserId,
    required String username,
    String? email,
    required String nome,
    String? avatarUrl,
    required bool ativo,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
  }) = _UsuarioImpl;

  factory Usuario.fromJson(Map<String, dynamic> jsonSerialization) {
    return Usuario(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      authUserId: jsonSerialization['authUserId'] as String?,
      username: jsonSerialization['username'] as String,
      email: jsonSerialization['email'] as String?,
      nome: jsonSerialization['nome'] as String,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      ativo: jsonSerialization['ativo'] as bool,
      criadoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['criadoEm']),
      atualizadoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['atualizadoEm']),
    );
  }

  static final t = UsuarioTable();

  static const db = UsuarioRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String? authUserId;

  String username;

  String? email;

  String nome;

  String? avatarUrl;

  bool ativo;

  DateTime criadoEm;

  DateTime atualizadoEm;

  @override
  _i1.Table<_i1.UuidValue> get table => t;

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Usuario copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? authUserId,
    String? username,
    String? email,
    String? nome,
    String? avatarUrl,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId,
      if (authUserId != null) 'authUserId': authUserId,
      'username': username,
      if (email != null) 'email': email,
      'nome': nome,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'ativo': ativo,
      'criadoEm': criadoEm.toJson(),
      'atualizadoEm': atualizadoEm.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId,
      if (authUserId != null) 'authUserId': authUserId,
      'username': username,
      if (email != null) 'email': email,
      'nome': nome,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'ativo': ativo,
      'criadoEm': criadoEm.toJson(),
      'atualizadoEm': atualizadoEm.toJson(),
    };
  }

  static UsuarioInclude include() {
    return UsuarioInclude._();
  }

  static UsuarioIncludeList includeList({
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    UsuarioInclude? include,
  }) {
    return UsuarioIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Usuario.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Usuario.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UsuarioImpl extends Usuario {
  _UsuarioImpl({
    _i1.UuidValue? id,
    required String tenantId,
    String? authUserId,
    required String username,
    String? email,
    required String nome,
    String? avatarUrl,
    required bool ativo,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
  }) : super._(
          id: id,
          tenantId: tenantId,
          authUserId: authUserId,
          username: username,
          email: email,
          nome: nome,
          avatarUrl: avatarUrl,
          ativo: ativo,
          criadoEm: criadoEm,
          atualizadoEm: atualizadoEm,
        );

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Usuario copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    Object? authUserId = _Undefined,
    String? username,
    Object? email = _Undefined,
    String? nome,
    Object? avatarUrl = _Undefined,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Usuario(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      authUserId: authUserId is String? ? authUserId : this.authUserId,
      username: username ?? this.username,
      email: email is String? ? email : this.email,
      nome: nome ?? this.nome,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}

class UsuarioTable extends _i1.Table<_i1.UuidValue> {
  UsuarioTable({super.tableRelation}) : super(tableName: 'usuarios') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    authUserId = _i1.ColumnString(
      'authUserId',
      this,
    );
    username = _i1.ColumnString(
      'username',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    avatarUrl = _i1.ColumnString(
      'avatarUrl',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    criadoEm = _i1.ColumnDateTime(
      'criadoEm',
      this,
    );
    atualizadoEm = _i1.ColumnDateTime(
      'atualizadoEm',
      this,
    );
  }

  late final _i1.ColumnString tenantId;

  late final _i1.ColumnString authUserId;

  late final _i1.ColumnString username;

  late final _i1.ColumnString email;

  late final _i1.ColumnString nome;

  late final _i1.ColumnString avatarUrl;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnDateTime criadoEm;

  late final _i1.ColumnDateTime atualizadoEm;

  @override
  List<_i1.Column> get columns => [
        id,
        tenantId,
        authUserId,
        username,
        email,
        nome,
        avatarUrl,
        ativo,
        criadoEm,
        atualizadoEm,
      ];
}

class UsuarioInclude extends _i1.IncludeObject {
  UsuarioInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => Usuario.t;
}

class UsuarioIncludeList extends _i1.IncludeList {
  UsuarioIncludeList._({
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Usuario.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => Usuario.t;
}

class UsuarioRepository {
  const UsuarioRepository._();

  /// Returns a list of [Usuario]s matching the given query parameters.
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
  Future<List<Usuario>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Usuario>(
      where: where?.call(Usuario.t),
      orderBy: orderBy?.call(Usuario.t),
      orderByList: orderByList?.call(Usuario.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Usuario] matching the given query parameters.
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
  Future<Usuario?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Usuario>(
      where: where?.call(Usuario.t),
      orderBy: orderBy?.call(Usuario.t),
      orderByList: orderByList?.call(Usuario.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Usuario] by its [id] or null if no such row exists.
  Future<Usuario?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Usuario>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Usuario]s in the list and returns the inserted rows.
  ///
  /// The returned [Usuario]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Usuario>> insert(
    _i1.Session session,
    List<Usuario> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Usuario>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Usuario] and returns the inserted row.
  ///
  /// The returned [Usuario] will have its `id` field set.
  Future<Usuario> insertRow(
    _i1.Session session,
    Usuario row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Usuario>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Usuario]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Usuario>> update(
    _i1.Session session,
    List<Usuario> rows, {
    _i1.ColumnSelections<UsuarioTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Usuario>(
      rows,
      columns: columns?.call(Usuario.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Usuario]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Usuario> updateRow(
    _i1.Session session,
    Usuario row, {
    _i1.ColumnSelections<UsuarioTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Usuario>(
      row,
      columns: columns?.call(Usuario.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Usuario]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Usuario>> delete(
    _i1.Session session,
    List<Usuario> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Usuario>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Usuario].
  Future<Usuario> deleteRow(
    _i1.Session session,
    Usuario row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Usuario>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Usuario>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UsuarioTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Usuario>(
      where: where(Usuario.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Usuario>(
      where: where?.call(Usuario.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
