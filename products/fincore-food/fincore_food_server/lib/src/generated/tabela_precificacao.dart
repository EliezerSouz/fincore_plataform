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

abstract class TabelaPrecificacao
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  TabelaPrecificacao._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.nome,
    required this.descricao,
    required this.tipoPolitica,
    required this.prioridade,
    required this.ativo,
    this.vigenciaInicio,
    this.vigenciaFim,
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

  factory TabelaPrecificacao({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String descricao,
    required String tipoPolitica,
    required int prioridade,
    required bool ativo,
    DateTime? vigenciaInicio,
    DateTime? vigenciaFim,
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
  }) = _TabelaPrecificacaoImpl;

  factory TabelaPrecificacao.fromJson(Map<String, dynamic> jsonSerialization) {
    return TabelaPrecificacao(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      nome: jsonSerialization['nome'] as String,
      descricao: jsonSerialization['descricao'] as String,
      tipoPolitica: jsonSerialization['tipoPolitica'] as String,
      prioridade: jsonSerialization['prioridade'] as int,
      ativo: jsonSerialization['ativo'] as bool,
      vigenciaInicio: jsonSerialization['vigenciaInicio'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['vigenciaInicio']),
      vigenciaFim: jsonSerialization['vigenciaFim'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['vigenciaFim']),
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

  static final t = TabelaPrecificacaoTable();

  static const db = TabelaPrecificacaoRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  String nome;

  String descricao;

  String tipoPolitica;

  int prioridade;

  bool ativo;

  DateTime? vigenciaInicio;

  DateTime? vigenciaFim;

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

  /// Returns a shallow copy of this [TabelaPrecificacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TabelaPrecificacao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? descricao,
    String? tipoPolitica,
    int? prioridade,
    bool? ativo,
    DateTime? vigenciaInicio,
    DateTime? vigenciaFim,
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
      'descricao': descricao,
      'tipoPolitica': tipoPolitica,
      'prioridade': prioridade,
      'ativo': ativo,
      if (vigenciaInicio != null) 'vigenciaInicio': vigenciaInicio?.toJson(),
      if (vigenciaFim != null) 'vigenciaFim': vigenciaFim?.toJson(),
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
      'descricao': descricao,
      'tipoPolitica': tipoPolitica,
      'prioridade': prioridade,
      'ativo': ativo,
      if (vigenciaInicio != null) 'vigenciaInicio': vigenciaInicio?.toJson(),
      if (vigenciaFim != null) 'vigenciaFim': vigenciaFim?.toJson(),
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

  static TabelaPrecificacaoInclude include() {
    return TabelaPrecificacaoInclude._();
  }

  static TabelaPrecificacaoIncludeList includeList({
    _i1.WhereExpressionBuilder<TabelaPrecificacaoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TabelaPrecificacaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TabelaPrecificacaoTable>? orderByList,
    TabelaPrecificacaoInclude? include,
  }) {
    return TabelaPrecificacaoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TabelaPrecificacao.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TabelaPrecificacao.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TabelaPrecificacaoImpl extends TabelaPrecificacao {
  _TabelaPrecificacaoImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required String nome,
    required String descricao,
    required String tipoPolitica,
    required int prioridade,
    required bool ativo,
    DateTime? vigenciaInicio,
    DateTime? vigenciaFim,
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
          descricao: descricao,
          tipoPolitica: tipoPolitica,
          prioridade: prioridade,
          ativo: ativo,
          vigenciaInicio: vigenciaInicio,
          vigenciaFim: vigenciaFim,
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

  /// Returns a shallow copy of this [TabelaPrecificacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TabelaPrecificacao copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    String? nome,
    String? descricao,
    String? tipoPolitica,
    int? prioridade,
    bool? ativo,
    Object? vigenciaInicio = _Undefined,
    Object? vigenciaFim = _Undefined,
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
    return TabelaPrecificacao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipoPolitica: tipoPolitica ?? this.tipoPolitica,
      prioridade: prioridade ?? this.prioridade,
      ativo: ativo ?? this.ativo,
      vigenciaInicio:
          vigenciaInicio is DateTime? ? vigenciaInicio : this.vigenciaInicio,
      vigenciaFim: vigenciaFim is DateTime? ? vigenciaFim : this.vigenciaFim,
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

class TabelaPrecificacaoTable extends _i1.Table<_i1.UuidValue> {
  TabelaPrecificacaoTable({super.tableRelation})
      : super(tableName: 'tabela_precificacao') {
    tenantId = _i1.ColumnString(
      'tenantId',
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
    tipoPolitica = _i1.ColumnString(
      'tipoPolitica',
      this,
    );
    prioridade = _i1.ColumnInt(
      'prioridade',
      this,
    );
    ativo = _i1.ColumnBool(
      'ativo',
      this,
    );
    vigenciaInicio = _i1.ColumnDateTime(
      'vigenciaInicio',
      this,
    );
    vigenciaFim = _i1.ColumnDateTime(
      'vigenciaFim',
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

  late final _i1.ColumnString descricao;

  late final _i1.ColumnString tipoPolitica;

  late final _i1.ColumnInt prioridade;

  late final _i1.ColumnBool ativo;

  late final _i1.ColumnDateTime vigenciaInicio;

  late final _i1.ColumnDateTime vigenciaFim;

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
        descricao,
        tipoPolitica,
        prioridade,
        ativo,
        vigenciaInicio,
        vigenciaFim,
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

class TabelaPrecificacaoInclude extends _i1.IncludeObject {
  TabelaPrecificacaoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => TabelaPrecificacao.t;
}

class TabelaPrecificacaoIncludeList extends _i1.IncludeList {
  TabelaPrecificacaoIncludeList._({
    _i1.WhereExpressionBuilder<TabelaPrecificacaoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TabelaPrecificacao.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => TabelaPrecificacao.t;
}

class TabelaPrecificacaoRepository {
  const TabelaPrecificacaoRepository._();

  /// Returns a list of [TabelaPrecificacao]s matching the given query parameters.
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
  Future<List<TabelaPrecificacao>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TabelaPrecificacaoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TabelaPrecificacaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TabelaPrecificacaoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TabelaPrecificacao>(
      where: where?.call(TabelaPrecificacao.t),
      orderBy: orderBy?.call(TabelaPrecificacao.t),
      orderByList: orderByList?.call(TabelaPrecificacao.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TabelaPrecificacao] matching the given query parameters.
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
  Future<TabelaPrecificacao?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TabelaPrecificacaoTable>? where,
    int? offset,
    _i1.OrderByBuilder<TabelaPrecificacaoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TabelaPrecificacaoTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TabelaPrecificacao>(
      where: where?.call(TabelaPrecificacao.t),
      orderBy: orderBy?.call(TabelaPrecificacao.t),
      orderByList: orderByList?.call(TabelaPrecificacao.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TabelaPrecificacao] by its [id] or null if no such row exists.
  Future<TabelaPrecificacao?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TabelaPrecificacao>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TabelaPrecificacao]s in the list and returns the inserted rows.
  ///
  /// The returned [TabelaPrecificacao]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TabelaPrecificacao>> insert(
    _i1.Session session,
    List<TabelaPrecificacao> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TabelaPrecificacao>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TabelaPrecificacao] and returns the inserted row.
  ///
  /// The returned [TabelaPrecificacao] will have its `id` field set.
  Future<TabelaPrecificacao> insertRow(
    _i1.Session session,
    TabelaPrecificacao row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TabelaPrecificacao>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TabelaPrecificacao]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TabelaPrecificacao>> update(
    _i1.Session session,
    List<TabelaPrecificacao> rows, {
    _i1.ColumnSelections<TabelaPrecificacaoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TabelaPrecificacao>(
      rows,
      columns: columns?.call(TabelaPrecificacao.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TabelaPrecificacao]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TabelaPrecificacao> updateRow(
    _i1.Session session,
    TabelaPrecificacao row, {
    _i1.ColumnSelections<TabelaPrecificacaoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TabelaPrecificacao>(
      row,
      columns: columns?.call(TabelaPrecificacao.t),
      transaction: transaction,
    );
  }

  /// Deletes all [TabelaPrecificacao]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TabelaPrecificacao>> delete(
    _i1.Session session,
    List<TabelaPrecificacao> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TabelaPrecificacao>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TabelaPrecificacao].
  Future<TabelaPrecificacao> deleteRow(
    _i1.Session session,
    TabelaPrecificacao row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TabelaPrecificacao>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TabelaPrecificacao>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TabelaPrecificacaoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TabelaPrecificacao>(
      where: where(TabelaPrecificacao.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TabelaPrecificacaoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TabelaPrecificacao>(
      where: where?.call(TabelaPrecificacao.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
