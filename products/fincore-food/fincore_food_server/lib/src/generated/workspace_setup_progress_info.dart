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

abstract class WorkspaceSetupProgressInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceSetupProgressInfo._({
    required this.passos,
    required this.concluidos,
    required this.percentual,
    required this.checklistJson,
  });

  factory WorkspaceSetupProgressInfo({
    required int passos,
    required int concluidos,
    required double percentual,
    required String checklistJson,
  }) = _WorkspaceSetupProgressInfoImpl;

  factory WorkspaceSetupProgressInfo.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return WorkspaceSetupProgressInfo(
      passos: jsonSerialization['passos'] as int,
      concluidos: jsonSerialization['concluidos'] as int,
      percentual: (jsonSerialization['percentual'] as num).toDouble(),
      checklistJson: jsonSerialization['checklistJson'] as String,
    );
  }

  int passos;

  int concluidos;

  double percentual;

  String checklistJson;

  /// Returns a shallow copy of this [WorkspaceSetupProgressInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceSetupProgressInfo copyWith({
    int? passos,
    int? concluidos,
    double? percentual,
    String? checklistJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'passos': passos,
      'concluidos': concluidos,
      'percentual': percentual,
      'checklistJson': checklistJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'passos': passos,
      'concluidos': concluidos,
      'percentual': percentual,
      'checklistJson': checklistJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _WorkspaceSetupProgressInfoImpl extends WorkspaceSetupProgressInfo {
  _WorkspaceSetupProgressInfoImpl({
    required int passos,
    required int concluidos,
    required double percentual,
    required String checklistJson,
  }) : super._(
          passos: passos,
          concluidos: concluidos,
          percentual: percentual,
          checklistJson: checklistJson,
        );

  /// Returns a shallow copy of this [WorkspaceSetupProgressInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceSetupProgressInfo copyWith({
    int? passos,
    int? concluidos,
    double? percentual,
    String? checklistJson,
  }) {
    return WorkspaceSetupProgressInfo(
      passos: passos ?? this.passos,
      concluidos: concluidos ?? this.concluidos,
      percentual: percentual ?? this.percentual,
      checklistJson: checklistJson ?? this.checklistJson,
    );
  }
}
