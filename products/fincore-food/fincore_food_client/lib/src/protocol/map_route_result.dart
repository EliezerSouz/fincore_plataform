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

abstract class MapRouteResult implements _i1.SerializableModel {
  MapRouteResult._({
    required this.distanciaMetros,
    required this.tempoDeslocamentoSegundos,
    required this.status,
    this.mensagem,
  });

  factory MapRouteResult({
    required int distanciaMetros,
    required int tempoDeslocamentoSegundos,
    required String status,
    String? mensagem,
  }) = _MapRouteResultImpl;

  factory MapRouteResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return MapRouteResult(
      distanciaMetros: jsonSerialization['distanciaMetros'] as int,
      tempoDeslocamentoSegundos:
          jsonSerialization['tempoDeslocamentoSegundos'] as int,
      status: jsonSerialization['status'] as String,
      mensagem: jsonSerialization['mensagem'] as String?,
    );
  }

  int distanciaMetros;

  int tempoDeslocamentoSegundos;

  String status;

  String? mensagem;

  /// Returns a shallow copy of this [MapRouteResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MapRouteResult copyWith({
    int? distanciaMetros,
    int? tempoDeslocamentoSegundos,
    String? status,
    String? mensagem,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'distanciaMetros': distanciaMetros,
      'tempoDeslocamentoSegundos': tempoDeslocamentoSegundos,
      'status': status,
      if (mensagem != null) 'mensagem': mensagem,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MapRouteResultImpl extends MapRouteResult {
  _MapRouteResultImpl({
    required int distanciaMetros,
    required int tempoDeslocamentoSegundos,
    required String status,
    String? mensagem,
  }) : super._(
          distanciaMetros: distanciaMetros,
          tempoDeslocamentoSegundos: tempoDeslocamentoSegundos,
          status: status,
          mensagem: mensagem,
        );

  /// Returns a shallow copy of this [MapRouteResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MapRouteResult copyWith({
    int? distanciaMetros,
    int? tempoDeslocamentoSegundos,
    String? status,
    Object? mensagem = _Undefined,
  }) {
    return MapRouteResult(
      distanciaMetros: distanciaMetros ?? this.distanciaMetros,
      tempoDeslocamentoSegundos:
          tempoDeslocamentoSegundos ?? this.tempoDeslocamentoSegundos,
      status: status ?? this.status,
      mensagem: mensagem is String? ? mensagem : this.mensagem,
    );
  }
}
