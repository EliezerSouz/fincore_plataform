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

abstract class AuditLog implements _i1.SerializableModel {
  AuditLog._({
    _i1.UuidValue? id,
    required this.entityName,
    required this.entityId,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.diff,
    this.deviceInfo,
    this.origin,
    this.reason,
    this.syncVersion,
    this.tenantId,
  }) : id = id ?? _i1.Uuid().v4obj();

  factory AuditLog({
    _i1.UuidValue? id,
    required String entityName,
    required String entityId,
    required String userId,
    required String action,
    required DateTime timestamp,
    String? diff,
    String? deviceInfo,
    String? origin,
    String? reason,
    int? syncVersion,
    String? tenantId,
  }) = _AuditLogImpl;

  factory AuditLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditLog(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityName: jsonSerialization['entityName'] as String,
      entityId: jsonSerialization['entityId'] as String,
      userId: jsonSerialization['userId'] as String,
      action: jsonSerialization['action'] as String,
      timestamp:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['timestamp']),
      diff: jsonSerialization['diff'] as String?,
      deviceInfo: jsonSerialization['deviceInfo'] as String?,
      origin: jsonSerialization['origin'] as String?,
      reason: jsonSerialization['reason'] as String?,
      syncVersion: jsonSerialization['syncVersion'] as int?,
      tenantId: jsonSerialization['tenantId'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue id;

  String entityName;

  String entityId;

  String userId;

  String action;

  DateTime timestamp;

  String? diff;

  String? deviceInfo;

  String? origin;

  String? reason;

  int? syncVersion;

  String? tenantId;

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuditLog copyWith({
    _i1.UuidValue? id,
    String? entityName,
    String? entityId,
    String? userId,
    String? action,
    DateTime? timestamp,
    String? diff,
    String? deviceInfo,
    String? origin,
    String? reason,
    int? syncVersion,
    String? tenantId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'entityName': entityName,
      'entityId': entityId,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toJson(),
      if (diff != null) 'diff': diff,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (origin != null) 'origin': origin,
      if (reason != null) 'reason': reason,
      if (syncVersion != null) 'syncVersion': syncVersion,
      if (tenantId != null) 'tenantId': tenantId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditLogImpl extends AuditLog {
  _AuditLogImpl({
    _i1.UuidValue? id,
    required String entityName,
    required String entityId,
    required String userId,
    required String action,
    required DateTime timestamp,
    String? diff,
    String? deviceInfo,
    String? origin,
    String? reason,
    int? syncVersion,
    String? tenantId,
  }) : super._(
          id: id,
          entityName: entityName,
          entityId: entityId,
          userId: userId,
          action: action,
          timestamp: timestamp,
          diff: diff,
          deviceInfo: deviceInfo,
          origin: origin,
          reason: reason,
          syncVersion: syncVersion,
          tenantId: tenantId,
        );

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuditLog copyWith({
    _i1.UuidValue? id,
    String? entityName,
    String? entityId,
    String? userId,
    String? action,
    DateTime? timestamp,
    Object? diff = _Undefined,
    Object? deviceInfo = _Undefined,
    Object? origin = _Undefined,
    Object? reason = _Undefined,
    Object? syncVersion = _Undefined,
    Object? tenantId = _Undefined,
  }) {
    return AuditLog(
      id: id ?? this.id,
      entityName: entityName ?? this.entityName,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      diff: diff is String? ? diff : this.diff,
      deviceInfo: deviceInfo is String? ? deviceInfo : this.deviceInfo,
      origin: origin is String? ? origin : this.origin,
      reason: reason is String? ? reason : this.reason,
      syncVersion: syncVersion is int? ? syncVersion : this.syncVersion,
      tenantId: tenantId is String? ? tenantId : this.tenantId,
    );
  }
}
