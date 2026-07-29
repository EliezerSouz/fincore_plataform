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

abstract class AuthUserInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AuthUserInfo._({
    required this.usuarioId,
    required this.email,
    this.tenantId,
    this.role,
    this.vencimento,
  });

  factory AuthUserInfo({
    required String usuarioId,
    required String email,
    String? tenantId,
    String? role,
    DateTime? vencimento,
  }) = _AuthUserInfoImpl;

  factory AuthUserInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthUserInfo(
      usuarioId: jsonSerialization['usuarioId'] as String,
      email: jsonSerialization['email'] as String,
      tenantId: jsonSerialization['tenantId'] as String?,
      role: jsonSerialization['role'] as String?,
      vencimento: jsonSerialization['vencimento'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['vencimento']),
    );
  }

  String usuarioId;

  String email;

  String? tenantId;

  String? role;

  DateTime? vencimento;

  /// Returns a shallow copy of this [AuthUserInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthUserInfo copyWith({
    String? usuarioId,
    String? email,
    String? tenantId,
    String? role,
    DateTime? vencimento,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'email': email,
      if (tenantId != null) 'tenantId': tenantId,
      if (role != null) 'role': role,
      if (vencimento != null) 'vencimento': vencimento?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'usuarioId': usuarioId,
      'email': email,
      if (tenantId != null) 'tenantId': tenantId,
      if (role != null) 'role': role,
      if (vencimento != null) 'vencimento': vencimento?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthUserInfoImpl extends AuthUserInfo {
  _AuthUserInfoImpl({
    required String usuarioId,
    required String email,
    String? tenantId,
    String? role,
    DateTime? vencimento,
  }) : super._(
          usuarioId: usuarioId,
          email: email,
          tenantId: tenantId,
          role: role,
          vencimento: vencimento,
        );

  /// Returns a shallow copy of this [AuthUserInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthUserInfo copyWith({
    String? usuarioId,
    String? email,
    Object? tenantId = _Undefined,
    Object? role = _Undefined,
    Object? vencimento = _Undefined,
  }) {
    return AuthUserInfo(
      usuarioId: usuarioId ?? this.usuarioId,
      email: email ?? this.email,
      tenantId: tenantId is String? ? tenantId : this.tenantId,
      role: role is String? ? role : this.role,
      vencimento: vencimento is DateTime? ? vencimento : this.vencimento,
    );
  }
}
