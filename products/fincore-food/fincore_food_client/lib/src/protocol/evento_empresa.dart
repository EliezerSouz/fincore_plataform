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

abstract class EventoEmpresa implements _i1.SerializableModel {
  EventoEmpresa._({
    _i1.UuidValue? id,
    required this.tenantId,
    required this.tipo,
    this.payload,
    required this.geradoPor,
    required this.ocorridoEm,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory EventoEmpresa({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String tipo,
    String? payload,
    required String geradoPor,
    required DateTime ocorridoEm,
  }) = _EventoEmpresaImpl;

  factory EventoEmpresa.fromJson(Map<String, dynamic> jsonSerialization) {
    return EventoEmpresa(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tenantId:
          _i1.UuidValueJsonExtension.fromJson(jsonSerialization['tenantId']),
      tipo: jsonSerialization['tipo'] as String,
      payload: jsonSerialization['payload'] as String?,
      geradoPor: jsonSerialization['geradoPor'] as String,
      ocorridoEm:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['ocorridoEm']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue id;

  _i1.UuidValue tenantId;

  String tipo;

  String? payload;

  String geradoPor;

  DateTime ocorridoEm;

  /// Returns a shallow copy of this [EventoEmpresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EventoEmpresa copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? tipo,
    String? payload,
    String? geradoPor,
    DateTime? ocorridoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'tenantId': tenantId.toJson(),
      'tipo': tipo,
      if (payload != null) 'payload': payload,
      'geradoPor': geradoPor,
      'ocorridoEm': ocorridoEm.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EventoEmpresaImpl extends EventoEmpresa {
  _EventoEmpresaImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue tenantId,
    required String tipo,
    String? payload,
    required String geradoPor,
    required DateTime ocorridoEm,
  }) : super._(
          id: id,
          tenantId: tenantId,
          tipo: tipo,
          payload: payload,
          geradoPor: geradoPor,
          ocorridoEm: ocorridoEm,
        );

  /// Returns a shallow copy of this [EventoEmpresa]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EventoEmpresa copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? tenantId,
    String? tipo,
    Object? payload = _Undefined,
    String? geradoPor,
    DateTime? ocorridoEm,
  }) {
    return EventoEmpresa(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tipo: tipo ?? this.tipo,
      payload: payload is String? ? payload : this.payload,
      geradoPor: geradoPor ?? this.geradoPor,
      ocorridoEm: ocorridoEm ?? this.ocorridoEm,
    );
  }
}
