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
import 'produto.dart' as _i2;
import 'cliente.dart' as _i3;
import 'empresa_configuracao.dart' as _i4;
import 'membro_empresa.dart' as _i5;

abstract class SyncPullPayload
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SyncPullPayload._({
    required this.timestamp,
    required this.produtos,
    required this.clientes,
    required this.configuracoes,
    required this.membros,
  });

  factory SyncPullPayload({
    required DateTime timestamp,
    required List<_i2.Produto> produtos,
    required List<_i3.Cliente> clientes,
    required List<_i4.EmpresaConfiguracao> configuracoes,
    required List<_i5.MembroEmpresa> membros,
  }) = _SyncPullPayloadImpl;

  factory SyncPullPayload.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPullPayload(
      timestamp:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['timestamp']),
      produtos: (jsonSerialization['produtos'] as List)
          .map((e) => _i2.Produto.fromJson((e as Map<String, dynamic>)))
          .toList(),
      clientes: (jsonSerialization['clientes'] as List)
          .map((e) => _i3.Cliente.fromJson((e as Map<String, dynamic>)))
          .toList(),
      configuracoes: (jsonSerialization['configuracoes'] as List)
          .map((e) =>
              _i4.EmpresaConfiguracao.fromJson((e as Map<String, dynamic>)))
          .toList(),
      membros: (jsonSerialization['membros'] as List)
          .map((e) => _i5.MembroEmpresa.fromJson((e as Map<String, dynamic>)))
          .toList(),
    );
  }

  DateTime timestamp;

  List<_i2.Produto> produtos;

  List<_i3.Cliente> clientes;

  List<_i4.EmpresaConfiguracao> configuracoes;

  List<_i5.MembroEmpresa> membros;

  /// Returns a shallow copy of this [SyncPullPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPullPayload copyWith({
    DateTime? timestamp,
    List<_i2.Produto>? produtos,
    List<_i3.Cliente>? clientes,
    List<_i4.EmpresaConfiguracao>? configuracoes,
    List<_i5.MembroEmpresa>? membros,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toJson(),
      'produtos': produtos.toJson(valueToJson: (v) => v.toJson()),
      'clientes': clientes.toJson(valueToJson: (v) => v.toJson()),
      'configuracoes': configuracoes.toJson(valueToJson: (v) => v.toJson()),
      'membros': membros.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'timestamp': timestamp.toJson(),
      'produtos': produtos.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'clientes': clientes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'configuracoes':
          configuracoes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'membros': membros.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncPullPayloadImpl extends SyncPullPayload {
  _SyncPullPayloadImpl({
    required DateTime timestamp,
    required List<_i2.Produto> produtos,
    required List<_i3.Cliente> clientes,
    required List<_i4.EmpresaConfiguracao> configuracoes,
    required List<_i5.MembroEmpresa> membros,
  }) : super._(
          timestamp: timestamp,
          produtos: produtos,
          clientes: clientes,
          configuracoes: configuracoes,
          membros: membros,
        );

  /// Returns a shallow copy of this [SyncPullPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPullPayload copyWith({
    DateTime? timestamp,
    List<_i2.Produto>? produtos,
    List<_i3.Cliente>? clientes,
    List<_i4.EmpresaConfiguracao>? configuracoes,
    List<_i5.MembroEmpresa>? membros,
  }) {
    return SyncPullPayload(
      timestamp: timestamp ?? this.timestamp,
      produtos: produtos ?? this.produtos.map((e0) => e0.copyWith()).toList(),
      clientes: clientes ?? this.clientes.map((e0) => e0.copyWith()).toList(),
      configuracoes: configuracoes ??
          this.configuracoes.map((e0) => e0.copyWith()).toList(),
      membros: membros ?? this.membros.map((e0) => e0.copyWith()).toList(),
    );
  }
}
