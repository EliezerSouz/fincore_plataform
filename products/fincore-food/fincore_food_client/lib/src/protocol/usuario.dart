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
    required this.email,
    required this.nome,
    required this.criadoEm,
    required this.atualizadoEm,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory Usuario({
    _i1.UuidValue? id,
    required String email,
    required String nome,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
  }) = _UsuarioImpl;

  factory Usuario.fromJson(Map<String, dynamic> jsonSerialization) {
    return Usuario(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      email: jsonSerialization['email'] as String,
      nome: jsonSerialization['nome'] as String,
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

  String email;

  String nome;

  DateTime criadoEm;

  DateTime atualizadoEm;

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Usuario copyWith({
    _i1.UuidValue? id,
    String? email,
    String? nome,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'email': email,
      'nome': nome,
      'criadoEm': criadoEm.toJson(),
      'atualizadoEm': atualizadoEm.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _UsuarioImpl extends Usuario {
  _UsuarioImpl({
    _i1.UuidValue? id,
    required String email,
    required String nome,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
  }) : super._(
          id: id,
          email: email,
          nome: nome,
          criadoEm: criadoEm,
          atualizadoEm: atualizadoEm,
        );

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Usuario copyWith({
    _i1.UuidValue? id,
    String? email,
    String? nome,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
