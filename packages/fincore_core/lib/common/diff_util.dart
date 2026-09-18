/// Utilitário para gerar diff entre dois objetos JSON-serializáveis (ex: CoreModels).
Map<String, dynamic> generateJsonDiff(Map<String, dynamic> original, Map<String, dynamic> copy) {
  final diff = <String, dynamic>{};

  for (final key in copy.keys) {
    // Ignorar propriedades de metadados padrão do sistema
    if (key == 'metadata' || key == 'updatedAt' || key == 'createdAt' ||
        key == 'syncVersion' || key == 'syncStatus' || key == 'lastSyncedAt' ||
        key == 'createdBy' || key == 'updatedBy' || key == 'deletedAt') continue;

    final origVal = original[key];
    final copyVal = copy[key];

    if (origVal != copyVal) {
      diff[key] = {
        'old': origVal,
        'new': copyVal,
      };
    }
  }

  // Verificar chaves que existiam no original e foram removidas na cópia (se aplicável)
  for (final key in original.keys) {
    if (key == 'metadata' || key == 'updatedAt' || key == 'createdAt' ||
        key == 'syncVersion' || key == 'syncStatus' || key == 'lastSyncedAt' ||
        key == 'createdBy' || key == 'updatedBy' || key == 'deletedAt') continue;
    if (!copy.containsKey(key)) {
      diff[key] = {
        'old': original[key],
        'new': null,
      };
    }
  }

  return diff;
}
