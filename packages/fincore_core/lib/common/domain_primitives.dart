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

/// Normaliza o número de telefone removendo pontuações e padronizando
/// telefones móveis brasileiros (adicionando o 9º dígito quando omitido).
/// Ex: (35) 9250-3114 -> 35992503114
/// Ex: (35) 9 9250-3114 -> 35992503114
/// Ex: (35) 3521-1234 -> 3535211234 (Fixo mantido com 10 dígitos)
String normalizarTelefone(String? raw) {
  if (raw == null) return '';
  var digits = raw.replaceAll(RegExp(r'\D'), '');

  // Trata prefixo de país +55 se houver
  if (digits.startsWith('55') && (digits.length == 12 || digits.length == 13)) {
    digits = digits.substring(2);
  }

  // Se tiver 10 dígitos (DDD + 8 dígitos) e for celular (iniciado por 6, 7, 8, 9)
  if (digits.length == 10) {
    final ddd = digits.substring(0, 2);
    final primeiroDigito = digits[2];
    if (['6', '7', '8', '9'].contains(primeiroDigito)) {
      digits = '${ddd}9${digits.substring(2)}';
    }
  }

  return digits;
}

/// Formata o telefone normalizado para exibição amigável.
/// Ex: 35992503114 -> (35) 99250-3114
/// Ex: 3535211234 -> (35) 3521-1234
String formatarTelefone(String? tel) {
  final norm = normalizarTelefone(tel);
  if (norm.length == 11) {
    return '(${norm.substring(0, 2)}) ${norm.substring(2, 7)}-${norm.substring(7)}';
  } else if (norm.length == 10) {
    return '(${norm.substring(0, 2)}) ${norm.substring(2, 6)}-${norm.substring(6)}';
  } else if (norm.isNotEmpty) {
    return tel ?? norm;
  }
  return '';
}

