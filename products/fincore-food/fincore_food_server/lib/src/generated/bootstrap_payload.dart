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
import 'empresa.dart' as _i2;
import 'empresa_configuracao.dart' as _i3;
import 'usuario.dart' as _i4;
import 'membro_empresa.dart' as _i5;

abstract class BootstrapPayload
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  BootstrapPayload._({
    required this.schemaVersion,
    required this.generatedAt,
    required this.empresa,
    required this.configuracao,
    required this.usuario,
    required this.membros,
  });

  factory BootstrapPayload({
    required int schemaVersion,
    required DateTime generatedAt,
    required _i2.Empresa empresa,
    required _i3.EmpresaConfiguracao configuracao,
    required _i4.Usuario usuario,
    required List<_i5.MembroEmpresa> membros,
  }) = _BootstrapPayloadImpl;

  factory BootstrapPayload.fromJson(Map<String, dynamic> jsonSerialization) {
    return BootstrapPayload(
      schemaVersion: jsonSerialization['schemaVersion'] as int,
      generatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['generatedAt']),
      empresa: _i2.Empresa.fromJson(
          (jsonSerialization['empresa'] as Map<String, dynamic>)),
      configuracao: _i3.EmpresaConfiguracao.fromJson(
          (jsonSerialization['configuracao'] as Map<String, dynamic>)),
      usuario: _i4.Usuario.fromJson(
          (jsonSerialization['usuario'] as Map<String, dynamic>)),
      membros: (jsonSerialization['membros'] as List)
          .map((e) => _i5.MembroEmpresa.fromJson((e as Map<String, dynamic>)))
          .toList(),
    );
  }

  int schemaVersion;

  DateTime generatedAt;

  _i2.Empresa empresa;

  _i3.EmpresaConfiguracao configuracao;

  _i4.Usuario usuario;

  List<_i5.MembroEmpresa> membros;

  /// Returns a shallow copy of this [BootstrapPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BootstrapPayload copyWith({
    int? schemaVersion,
    DateTime? generatedAt,
    _i2.Empresa? empresa,
    _i3.EmpresaConfiguracao? configuracao,
    _i4.Usuario? usuario,
    List<_i5.MembroEmpresa>? membros,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'generatedAt': generatedAt.toJson(),
      'empresa': empresa.toJson(),
      'configuracao': configuracao.toJson(),
      'usuario': usuario.toJson(),
      'membros': membros.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'schemaVersion': schemaVersion,
      'generatedAt': generatedAt.toJson(),
      'empresa': empresa.toJsonForProtocol(),
      'configuracao': configuracao.toJsonForProtocol(),
      'usuario': usuario.toJsonForProtocol(),
      'membros': membros.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BootstrapPayloadImpl extends BootstrapPayload {
  _BootstrapPayloadImpl({
    required int schemaVersion,
    required DateTime generatedAt,
    required _i2.Empresa empresa,
    required _i3.EmpresaConfiguracao configuracao,
    required _i4.Usuario usuario,
    required List<_i5.MembroEmpresa> membros,
  }) : super._(
          schemaVersion: schemaVersion,
          generatedAt: generatedAt,
          empresa: empresa,
          configuracao: configuracao,
          usuario: usuario,
          membros: membros,
        );

  /// Returns a shallow copy of this [BootstrapPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BootstrapPayload copyWith({
    int? schemaVersion,
    DateTime? generatedAt,
    _i2.Empresa? empresa,
    _i3.EmpresaConfiguracao? configuracao,
    _i4.Usuario? usuario,
    List<_i5.MembroEmpresa>? membros,
  }) {
    return BootstrapPayload(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      empresa: empresa ?? this.empresa.copyWith(),
      configuracao: configuracao ?? this.configuracao.copyWith(),
      usuario: usuario ?? this.usuario.copyWith(),
      membros: membros ?? this.membros.map((e0) => e0.copyWith()).toList(),
    );
  }
}
