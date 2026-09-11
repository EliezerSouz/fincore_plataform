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

abstract class MovimentacaoEstoque
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  MovimentacaoEstoque._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.produtoId,
    this.pedidoId,
    required this.tipo,
    required this.quantidade,
    required this.quantidadeAntes,
    required this.quantidadeDepois,
    String? motivo,
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
        motivo = motivo ?? '';

  factory MovimentacaoEstoque({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue produtoId,
    _i1.UuidValue? pedidoId,
    required String tipo,
    required int quantidade,
    required int quantidadeAntes,
    required int quantidadeDepois,
    String? motivo,
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
  }) = _MovimentacaoEstoqueImpl;

  factory MovimentacaoEstoque.fromJson(Map<String, dynamic> jsonSerialization) {
    return MovimentacaoEstoque(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId: jsonSerialization['tenantId'] as String,
      produtoId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['produtoId']),
      pedidoId: jsonSerialization['pedidoId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['pedidoId']),
      tipo: jsonSerialization['tipo'] as String,
      quantidade: jsonSerialization['quantidade'] as int,
      quantidadeAntes: jsonSerialization['quantidadeAntes'] as int,
      quantidadeDepois: jsonSerialization['quantidadeDepois'] as int,
      motivo: jsonSerialization['motivo'] as String,
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

  static final t = MovimentacaoEstoqueTable();

  static const db = MovimentacaoEstoqueRepository._();

  @override
  _i1.UuidValue id;

  String tenantId;

  _i1.UuidValue produtoId;

  _i1.UuidValue? pedidoId;

  String tipo;

  int quantidade;

  int quantidadeAntes;

  int quantidadeDepois;

  String motivo;

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

  /// Returns a shallow copy of this [MovimentacaoEstoque]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MovimentacaoEstoque copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? produtoId,
    _i1.UuidValue? pedidoId,
    String? tipo,
    int? quantidade,
    int? quantidadeAntes,
    int? quantidadeDepois,
    String? motivo,
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
      'produtoId': produtoId.toJson(),
      if (pedidoId != null) 'pedidoId': pedidoId?.toJson(),
      'tipo': tipo,
      'quantidade': quantidade,
      'quantidadeAntes': quantidadeAntes,
      'quantidadeDepois': quantidadeDepois,
      'motivo': motivo,
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
      'produtoId': produtoId.toJson(),
      if (pedidoId != null) 'pedidoId': pedidoId?.toJson(),
      'tipo': tipo,
      'quantidade': quantidade,
      'quantidadeAntes': quantidadeAntes,
      'quantidadeDepois': quantidadeDepois,
      'motivo': motivo,
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

  static MovimentacaoEstoqueInclude include() {
    return MovimentacaoEstoqueInclude._();
  }

  static MovimentacaoEstoqueIncludeList includeList({
    _i1.WhereExpressionBuilder<MovimentacaoEstoqueTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MovimentacaoEstoqueTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MovimentacaoEstoqueTable>? orderByList,
    MovimentacaoEstoqueInclude? include,
  }) {
    return MovimentacaoEstoqueIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MovimentacaoEstoque.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MovimentacaoEstoque.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MovimentacaoEstoqueImpl extends MovimentacaoEstoque {
  _MovimentacaoEstoqueImpl({
    _i1.UuidValue? id,
    required String tenantId,
    required _i1.UuidValue produtoId,
    _i1.UuidValue? pedidoId,
    required String tipo,
    required int quantidade,
    required int quantidadeAntes,
    required int quantidadeDepois,
    String? motivo,
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
          produtoId: produtoId,
          pedidoId: pedidoId,
          tipo: tipo,
          quantidade: quantidade,
          quantidadeAntes: quantidadeAntes,
          quantidadeDepois: quantidadeDepois,
          motivo: motivo,
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

  /// Returns a shallow copy of this [MovimentacaoEstoque]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MovimentacaoEstoque copyWith({
    _i1.UuidValue? id,
    String? tenantId,
    _i1.UuidValue? produtoId,
    Object? pedidoId = _Undefined,
    String? tipo,
    int? quantidade,
    int? quantidadeAntes,
    int? quantidadeDepois,
    String? motivo,
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
    return MovimentacaoEstoque(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      produtoId: produtoId ?? this.produtoId,
      pedidoId: pedidoId is _i1.UuidValue? ? pedidoId : this.pedidoId,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      quantidadeAntes: quantidadeAntes ?? this.quantidadeAntes,
      quantidadeDepois: quantidadeDepois ?? this.quantidadeDepois,
      motivo: motivo ?? this.motivo,
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

class MovimentacaoEstoqueTable extends _i1.Table<_i1.UuidValue> {
  MovimentacaoEstoqueTable({super.tableRelation})
      : super(tableName: 'movimentacao_estoque') {
    tenantId = _i1.ColumnString(
      'tenantId',
      this,
    );
    produtoId = _i1.ColumnUuid(
      'produtoId',
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
    quantidade = _i1.ColumnInt(
      'quantidade',
      this,
    );
    quantidadeAntes = _i1.ColumnInt(
      'quantidadeAntes',
      this,
    );
    quantidadeDepois = _i1.ColumnInt(
      'quantidadeDepois',
      this,
    );
    motivo = _i1.ColumnString(
      'motivo',
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

  late final _i1.ColumnUuid produtoId;

  late final _i1.ColumnUuid pedidoId;

  late final _i1.ColumnString tipo;

  late final _i1.ColumnInt quantidade;

  late final _i1.ColumnInt quantidadeAntes;

  late final _i1.ColumnInt quantidadeDepois;

  late final _i1.ColumnString motivo;

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
        produtoId,
        pedidoId,
        tipo,
        quantidade,
        quantidadeAntes,
        quantidadeDepois,
        motivo,
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

class MovimentacaoEstoqueInclude extends _i1.IncludeObject {
  MovimentacaoEstoqueInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => MovimentacaoEstoque.t;
}

class MovimentacaoEstoqueIncludeList extends _i1.IncludeList {
  MovimentacaoEstoqueIncludeList._({
    _i1.WhereExpressionBuilder<MovimentacaoEstoqueTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MovimentacaoEstoque.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => MovimentacaoEstoque.t;
}

class MovimentacaoEstoqueRepository {
  const MovimentacaoEstoqueRepository._();

  /// Returns a list of [MovimentacaoEstoque]s matching the given query parameters.
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
  Future<List<MovimentacaoEstoque>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MovimentacaoEstoqueTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MovimentacaoEstoqueTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MovimentacaoEstoqueTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<MovimentacaoEstoque>(
      where: where?.call(MovimentacaoEstoque.t),
      orderBy: orderBy?.call(MovimentacaoEstoque.t),
      orderByList: orderByList?.call(MovimentacaoEstoque.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [MovimentacaoEstoque] matching the given query parameters.
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
  Future<MovimentacaoEstoque?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MovimentacaoEstoqueTable>? where,
    int? offset,
    _i1.OrderByBuilder<MovimentacaoEstoqueTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MovimentacaoEstoqueTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<MovimentacaoEstoque>(
      where: where?.call(MovimentacaoEstoque.t),
      orderBy: orderBy?.call(MovimentacaoEstoque.t),
      orderByList: orderByList?.call(MovimentacaoEstoque.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [MovimentacaoEstoque] by its [id] or null if no such row exists.
  Future<MovimentacaoEstoque?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<MovimentacaoEstoque>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [MovimentacaoEstoque]s in the list and returns the inserted rows.
  ///
  /// The returned [MovimentacaoEstoque]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<MovimentacaoEstoque>> insert(
    _i1.Session session,
    List<MovimentacaoEstoque> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<MovimentacaoEstoque>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [MovimentacaoEstoque] and returns the inserted row.
  ///
  /// The returned [MovimentacaoEstoque] will have its `id` field set.
  Future<MovimentacaoEstoque> insertRow(
    _i1.Session session,
    MovimentacaoEstoque row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MovimentacaoEstoque>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MovimentacaoEstoque]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MovimentacaoEstoque>> update(
    _i1.Session session,
    List<MovimentacaoEstoque> rows, {
    _i1.ColumnSelections<MovimentacaoEstoqueTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MovimentacaoEstoque>(
      rows,
      columns: columns?.call(MovimentacaoEstoque.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MovimentacaoEstoque]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MovimentacaoEstoque> updateRow(
    _i1.Session session,
    MovimentacaoEstoque row, {
    _i1.ColumnSelections<MovimentacaoEstoqueTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MovimentacaoEstoque>(
      row,
      columns: columns?.call(MovimentacaoEstoque.t),
      transaction: transaction,
    );
  }

  /// Deletes all [MovimentacaoEstoque]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MovimentacaoEstoque>> delete(
    _i1.Session session,
    List<MovimentacaoEstoque> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MovimentacaoEstoque>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MovimentacaoEstoque].
  Future<MovimentacaoEstoque> deleteRow(
    _i1.Session session,
    MovimentacaoEstoque row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MovimentacaoEstoque>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MovimentacaoEstoque>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MovimentacaoEstoqueTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MovimentacaoEstoque>(
      where: where(MovimentacaoEstoque.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MovimentacaoEstoqueTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MovimentacaoEstoque>(
      where: where?.call(MovimentacaoEstoque.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
