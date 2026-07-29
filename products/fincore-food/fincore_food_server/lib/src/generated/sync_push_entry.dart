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

abstract class SyncPushEntry
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SyncPushEntry._({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
  });

  factory SyncPushEntry({
    required String id,
    required String entity,
    required String entityId,
    required String action,
    required String payload,
    required DateTime createdAt,
  }) = _SyncPushEntryImpl;

  factory SyncPushEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPushEntry(
      id: jsonSerialization['id'] as String,
      entity: jsonSerialization['entity'] as String,
      entityId: jsonSerialization['entityId'] as String,
      action: jsonSerialization['action'] as String,
      payload: jsonSerialization['payload'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  String id;

  String entity;

  String entityId;

  String action;

  String payload;

  DateTime createdAt;

  /// Returns a shallow copy of this [SyncPushEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPushEntry copyWith({
    String? id,
    String? entity,
    String? entityId,
    String? action,
    String? payload,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity': entity,
      'entityId': entityId,
      'action': action,
      'payload': payload,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'id': id,
      'entity': entity,
      'entityId': entityId,
      'action': action,
      'payload': payload,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncPushEntryImpl extends SyncPushEntry {
  _SyncPushEntryImpl({
    required String id,
    required String entity,
    required String entityId,
    required String action,
    required String payload,
    required DateTime createdAt,
  }) : super._(
          id: id,
          entity: entity,
          entityId: entityId,
          action: action,
          payload: payload,
          createdAt: createdAt,
        );

  /// Returns a shallow copy of this [SyncPushEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPushEntry copyWith({
    String? id,
    String? entity,
    String? entityId,
    String? action,
    String? payload,
    DateTime? createdAt,
  }) {
    return SyncPushEntry(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
