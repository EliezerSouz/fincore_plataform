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

abstract class Empresa
    implements _i1.TableRow<_i1.UuidValue>, _i1.ProtocolSerialization {
  Empresa._({
    _i1.UuidValue? id,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.documentoFiscal,
    required this.email,
    required this.telefone,
    required this.status,
    required this.plano,
    required this.timezone,
    required this.locale,
    required this.currency,
    required this.country,
    required this.createdFrom,
    this.vencimento,
    this.segmento,
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

  factory Empresa({
    _i1.UuidValue? id,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String email,
    required String telefone,
    required String status,
    required String plano,
    required String timezone,
    required String locale,
    required String currency,
    required String country,
    required String createdFrom,
    DateTime? vencimento,
    String? segmento,
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
  }) = _EmpresaImpl;

  factory Empresa.fromJson(Map<String, dynamic> jsonSerialization) {
    return Empresa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      razaoSocial: jsonSerialization['razaoSocial'] as String,
      nomeFantasia: jsonSerialization['nomeFantasia'] as String,
      documentoFiscal: jsonSerialization['documentoFiscal'] as String,
      email: jsonSerialization['email'] as String,
      telefone: jsonSerialization['telefone'] as String,
      status: jsonSerialization['status'] as String,
      plano: jsonSerialization['plano'] as String,
      timezone: jsonSerialization['timezone'] as String,
      locale: jsonSerialization['locale'] as String,
      currency: jsonSerialization['currency'] as String,
      country: jsonSerialization['country'] as String,
      createdFrom: jsonSerialization['createdFrom'] as String,
      vencimento: jsonSerialization['vencimento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['vencimento']),
      segmento: jsonSerialization['segmento'] as String?,
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

  static final t = EmpresaTable();

  static const db = EmpresaRepository._();

  @override
  _i1.UuidValue id;

  String razaoSocial;

  String nomeFantasia;

  String documentoFiscal;

  String email;

  String telefone;

  String status;

  String plano;

  String timezone;

  String locale;

  String currency;

  String country;

  String createdFrom;

  DateTime? vencimento;

  String? segmento;

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

  /// Returns a shallow copy of this [Empresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Empresa copyWith({
    _i1.UuidValue? id,
    String? razaoSocial,
    String? nomeFantasia,
    String? documentoFiscal,
    String? email,
    String? telefone,
    String? status,
    String? plano,
    String? timezone,
    String? locale,
    String? currency,
    String? country,
    String? createdFrom,
    DateTime? vencimento,
    String? segmento,
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
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'documentoFiscal': documentoFiscal,
      'email': email,
      'telefone': telefone,
      'status': status,
      'plano': plano,
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      'country': country,
      'createdFrom': createdFrom,
      if (vencimento != null) 'vencimento': vencimento?.toJson(),
      if (segmento != null) 'segmento': segmento,
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
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'documentoFiscal': documentoFiscal,
      'email': email,
      'telefone': telefone,
      'status': status,
      'plano': plano,
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      'country': country,
      'createdFrom': createdFrom,
      if (vencimento != null) 'vencimento': vencimento?.toJson(),
      if (segmento != null) 'segmento': segmento,
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

  static EmpresaInclude include() {
    return EmpresaInclude._();
  }

  static EmpresaIncludeList includeList({
    _i1.WhereExpressionBuilder<EmpresaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaTable>? orderByList,
    EmpresaInclude? include,
  }) {
    return EmpresaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Empresa.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Empresa.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmpresaImpl extends Empresa {
  _EmpresaImpl({
    _i1.UuidValue? id,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String email,
    required String telefone,
    required String status,
    required String plano,
    required String timezone,
    required String locale,
    required String currency,
    required String country,
    required String createdFrom,
    DateTime? vencimento,
    String? segmento,
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
          razaoSocial: razaoSocial,
          nomeFantasia: nomeFantasia,
          documentoFiscal: documentoFiscal,
          email: email,
          telefone: telefone,
          status: status,
          plano: plano,
          timezone: timezone,
          locale: locale,
          currency: currency,
          country: country,
          createdFrom: createdFrom,
          vencimento: vencimento,
          segmento: segmento,
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

  /// Returns a shallow copy of this [Empresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Empresa copyWith({
    _i1.UuidValue? id,
    String? razaoSocial,
    String? nomeFantasia,
    String? documentoFiscal,
    String? email,
    String? telefone,
    String? status,
    String? plano,
    String? timezone,
    String? locale,
    String? currency,
    String? country,
    String? createdFrom,
    Object? vencimento = _Undefined,
    Object? segmento = _Undefined,
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
    return Empresa(
      id: id ?? this.id,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      documentoFiscal: documentoFiscal ?? this.documentoFiscal,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      status: status ?? this.status,
      plano: plano ?? this.plano,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      createdFrom: createdFrom ?? this.createdFrom,
      vencimento: vencimento is DateTime? ? vencimento : this.vencimento,
      segmento: segmento is String? ? segmento : this.segmento,
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

class EmpresaTable extends _i1.Table<_i1.UuidValue> {
  EmpresaTable({super.tableRelation}) : super(tableName: 'empresa') {
    razaoSocial = _i1.ColumnString(
      'razaoSocial',
      this,
    );
    nomeFantasia = _i1.ColumnString(
      'nomeFantasia',
      this,
    );
    documentoFiscal = _i1.ColumnString(
      'documentoFiscal',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    telefone = _i1.ColumnString(
      'telefone',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    plano = _i1.ColumnString(
      'plano',
      this,
    );
    timezone = _i1.ColumnString(
      'timezone',
      this,
    );
    locale = _i1.ColumnString(
      'locale',
      this,
    );
    currency = _i1.ColumnString(
      'currency',
      this,
    );
    country = _i1.ColumnString(
      'country',
      this,
    );
    createdFrom = _i1.ColumnString(
      'createdFrom',
      this,
    );
    vencimento = _i1.ColumnDateTime(
      'vencimento',
      this,
    );
    segmento = _i1.ColumnString(
      'segmento',
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

  late final _i1.ColumnString razaoSocial;

  late final _i1.ColumnString nomeFantasia;

  late final _i1.ColumnString documentoFiscal;

  late final _i1.ColumnString email;

  late final _i1.ColumnString telefone;

  late final _i1.ColumnString status;

  late final _i1.ColumnString plano;

  late final _i1.ColumnString timezone;

  late final _i1.ColumnString locale;

  late final _i1.ColumnString currency;

  late final _i1.ColumnString country;

  late final _i1.ColumnString createdFrom;

  late final _i1.ColumnDateTime vencimento;

  late final _i1.ColumnString segmento;

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
        razaoSocial,
        nomeFantasia,
        documentoFiscal,
        email,
        telefone,
        status,
        plano,
        timezone,
        locale,
        currency,
        country,
        createdFrom,
        vencimento,
        segmento,
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

class EmpresaInclude extends _i1.IncludeObject {
  EmpresaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue> get table => Empresa.t;
}

class EmpresaIncludeList extends _i1.IncludeList {
  EmpresaIncludeList._({
    _i1.WhereExpressionBuilder<EmpresaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Empresa.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue> get table => Empresa.t;
}

class EmpresaRepository {
  const EmpresaRepository._();

  /// Returns a list of [Empresa]s matching the given query parameters.
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
  Future<List<Empresa>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Empresa>(
      where: where?.call(Empresa.t),
      orderBy: orderBy?.call(Empresa.t),
      orderByList: orderByList?.call(Empresa.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Empresa] matching the given query parameters.
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
  Future<Empresa?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaTable>? where,
    int? offset,
    _i1.OrderByBuilder<EmpresaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmpresaTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Empresa>(
      where: where?.call(Empresa.t),
      orderBy: orderBy?.call(Empresa.t),
      orderByList: orderByList?.call(Empresa.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Empresa] by its [id] or null if no such row exists.
  Future<Empresa?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Empresa>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Empresa]s in the list and returns the inserted rows.
  ///
  /// The returned [Empresa]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Empresa>> insert(
    _i1.Session session,
    List<Empresa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Empresa>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Empresa] and returns the inserted row.
  ///
  /// The returned [Empresa] will have its `id` field set.
  Future<Empresa> insertRow(
    _i1.Session session,
    Empresa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Empresa>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Empresa]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Empresa>> update(
    _i1.Session session,
    List<Empresa> rows, {
    _i1.ColumnSelections<EmpresaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Empresa>(
      rows,
      columns: columns?.call(Empresa.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Empresa]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Empresa> updateRow(
    _i1.Session session,
    Empresa row, {
    _i1.ColumnSelections<EmpresaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Empresa>(
      row,
      columns: columns?.call(Empresa.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Empresa]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Empresa>> delete(
    _i1.Session session,
    List<Empresa> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Empresa>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Empresa].
  Future<Empresa> deleteRow(
    _i1.Session session,
    Empresa row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Empresa>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Empresa>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<EmpresaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Empresa>(
      where: where(Empresa.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<EmpresaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Empresa>(
      where: where?.call(Empresa.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
