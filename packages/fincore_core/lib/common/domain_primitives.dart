enum SyncStatus {
  pending,
  processing,
  synced,
  failed,
  retrying,
  resolved,
  conflict,
}

class SyncMetadata {
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;

  const SyncMetadata({
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
  });

  SyncMetadata copyWith({
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? Function()? deletedAt,
    SyncStatus? syncStatus,
    DateTime? Function()? lastSyncedAt,
  }) {
    return SyncMetadata(
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt != null ? lastSyncedAt() : this.lastSyncedAt,
    );
  }
}
