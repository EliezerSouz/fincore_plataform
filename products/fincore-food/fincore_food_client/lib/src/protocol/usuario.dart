/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Usuario implements _i1.SerializableModel {
  Usuario._({
    _i1.UuidValue? id,
    this.activeTenantId,
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
    _i1.UuidValue? activeTenantId,
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
      activeTenantId: jsonSerialization['activeTenantId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['activeTenantId']),
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue id;

  _i1.UuidValue? activeTenantId;

  String? authUserId;

  String username;

  String? email;

  String nome;

  String? avatarUrl;

  bool ativo;

  DateTime criadoEm;

  DateTime atualizadoEm;

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Usuario copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? activeTenantId,
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
      if (activeTenantId != null) 'activeTenantId': activeTenantId?.toJson(),
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
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UsuarioImpl extends Usuario {
  _UsuarioImpl({
    _i1.UuidValue? id,
    _i1.UuidValue? activeTenantId,
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
          activeTenantId: activeTenantId,
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
    Object? activeTenantId = _Undefined,
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
      activeTenantId: activeTenantId is _i1.UuidValue?
          ? activeTenantId
          : this.activeTenantId,
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
