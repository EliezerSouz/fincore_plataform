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

abstract class Categoria
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  Categoria._({
    _i1.UuidValue? id,
    required this.tenantId,
    this.parentId,
    required this.nome,
    required this.descricao,
    required this.ordemExibicao,
    required this.ativo,
    this.icone,
    this.cor,
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

  factory Categoria({
    _i1.UuidValue? id,
    required String tenantId,
    _i1.UuidValue? parentId,
    required String nome,
    required String descricao,
    required int ordemExibicao,
    required bool ativo,
    String? icone,
    String? cor,
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
  }) = _CategoriaImpl;

  factory Categoria.fromJson(Map<String, dynamic> jsonSerialization) {
    return Categoria(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      parentId: jsonSerialization['parentId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['parentId']),
      nome: jsonSerialization['nome'] as String,
      descricao: jsonSerialization['descricao'] as String,
      ordemExibicao: jsonSerialization['ordemExibicao'] as int,
      ativo: jsonSerialization['ativo'] as bool,
      icone: jsonSerialization['icone'] as String?,
      cor: jsonSerialization['cor'] as String?,
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

  static final t = CategoriaTable();

  static const db = CategoriaRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue? parentId;

  String nome;

  String descricao;

  int ordemExibicao;

  bool ativo;

  String? icone;

  String? cor;

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

  /// Returns a shallow copy of this [Categoria]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Categoria copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? parentId,
    String? nome,
    String? descricao,
    int? ordemExibicao,
    bool? ativo,
    String? icone,
    String? cor,
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
      if (parentId != null) 'parentId': parentId?.toJson(),
      'nome': nome,
      'descricao': descricao,
      'ordemExibicao': ordemExibicao,
      'ativo': ativo,
      if (icone != null) 'icone': icone,
      if (cor != null) 'cor': cor,
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
      if (parentId != null) 'parentId': parentId?.toJson(),
      'nome': nome,
      'descricao': descricao,
      'ordemExibicao': ordemExibicao,
      'ativo': ativo,
      if (icone != null) 'icone': icone,
      if (cor != null) 'cor': cor,
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

  static CategoriaInclude include() {
    return CategoriaInclude._();
  }

  static CategoriaIncludeList includeList({
    _i1.WhereExpressionBuilder<CategoriaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CategoriaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CategoriaTable>? orderByList,
    CategoriaInclude? include,
  }) {
    return CategoriaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Categoria.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Categoria.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CategoriaImpl extends Categoria {
  _CategoriaImpl({
    _i1.UuidValue? id,
    required String tenantId,
    _i1.UuidValue? parentId,
    required String nome,
    required String descricao,
    required int ordemExibicao,
    required bool ativo,
    String? icone,
    String? cor,
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
          parentId: parentId,
          nome: nome,
          descricao: descricao,
          ordemExibicao: ordemExibicao,
          ativo: ativo,
          icone: icone,
          cor: cor,
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

  /// Returns a shallow copy of this [Categoria]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Categoria copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    Object? parentId = _Undefined,
    String? nome,
    String? descricao,
    int? ordemExibicao,
    bool? ativo,
    Object? icone = _Undefined,
    Object? cor = _Undefined,
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
    return Categoria(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      parentId: parentId is _i1.UuidValue? ? parentId : this.parentId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      ativo: ativo ?? this.ativo,
      icone: icone is String? ? icone : this.icone,
      cor: cor is String? ? cor : this.cor,
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

class CategoriaTable extends _i1.Table<_i1.UuidValue> {
  CategoriaTable({super.tableRelation}) : super(tableName: 'categoria') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    parentId = _i1.ColumnUuid(
      'parentId',
      this,
    );
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    descricao = _i1.ColumnString(
      'descricao',
      this,
    );
    ordemExibicao = _i1.ColumnInt(
      'ordemExibicao',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    icone = _i1.ColumnString(
      'icone',
      this,
    );
    cor = _i1.ColumnString(
      'cor',
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

  late final _i1.ColumnUuid parentId;

  late final _i1.ColumnString nome;

  late final _i1.ColumnString descricao;

  late final _i1.ColumnInt ordemExibicao;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnString icone;

  late final _i1.ColumnString cor;

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
        parentId,
        nome,
        descricao,
        ordemExibicao,
        ativo,
        icone,
        cor,
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

class CategoriaInclude extends _i1.IncludeObject {
  CategoriaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => Categoria.t;
}

class CategoriaIncludeList extends _i1.IncludeList {
  CategoriaIncludeList._({
    _i1.WhereExpressionBuilder<CategoriaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Categoria.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => Categoria.t;
}

class CategoriaRepository {
  const CategoriaRepository._();

  /// Returns a list of [Categoria]s matching the given query parameters.
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
  Future<List<Categoria>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<CategoriaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CategoriaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CategoriaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Categoria>(
      where: where?.call(Categoria.t),
      orderBy: orderBy?.call(Categoria.t),
      orderByList: orderByList?.call(Categoria.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Categoria] matching the given query parameters.
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
  Future<Categoria?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<CategoriaTable>? where,
    int? offset,
    _i1.OrderByBuilder<CategoriaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CategoriaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Categoria>(
      where: where?.call(Categoria.t),
      orderBy: orderBy?.call(Categoria.t),
      orderByList: orderByList?.call(Categoria.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Categoria] by its [id] or null if no such row exists.
  Future<Categoria?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Categoria>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Categoria]s in the list and returns the inserted rows.
  ///
  /// The returned [Categoria]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Categoria>> insert(
    _i1.Session session,
    List<Categoria> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Categoria>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Categoria] and returns the inserted row.
  ///
  /// The returned [Categoria] will have its `id` field set.
  Future<Categoria> insertRow(
    _i1.Session session,
    Categoria row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Categoria>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Categoria]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Categoria>> update(
    _i1.Session session,
    List<Categoria> rows, {
    _i1.ColumnSelections<CategoriaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Categoria>(
      rows,
      columns: columns?.call(Categoria.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Categoria]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Categoria> updateRow(
    _i1.Session session,
    Categoria row, {
    _i1.ColumnSelections<CategoriaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Categoria>(
      row,
      columns: columns?.call(Categoria.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Categoria]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Categoria>> delete(
    _i1.Session session,
    List<Categoria> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Categoria>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Categoria].
  Future<Categoria> deleteRow(
    _i1.Session session,
    Categoria row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Categoria>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Categoria>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<CategoriaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Categoria>(
      where: where(Categoria.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<CategoriaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Categoria>(
      where: where?.call(Categoria.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
