library fincore_core;

/// Utilitário para garantir a monotonicidade e precedência de estados do ciclo de vida
/// dos Pedidos e Ordens de Preparo (KDS) em ambientes multi-terminal.
///
/// Hierarquia de Precedência de Estados:
/// - 0: rascunho
/// - 1: confirmado / pendente
/// - 2: em_preparo / emPreparo
/// - 3: pronto
/// - 4: entregue / finalizado / concluido
/// - 99: cancelado (Estado Terminal de Cancelamento)
class StatusPrecedence {
  static int getRank(String? status) {
    if (status == null) return 0;
    final normalized = status.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'rascunho':
        return 0;
      case 'pendente':
      case 'confirmado':
        return 1;
      case 'em_preparo':
      case 'empreparo':
        return 2;
      case 'pronto':
        return 3;
      case 'entregue':
      case 'finalizado':
      case 'concluido':
        return 4;
      case 'cancelado':
        return 99;
      default:
        return 1;
    }
  }

  /// Retorna `true` se [existingStatus] já está em uma precedência maior ou igual a [incomingStatus].
  /// Impede a regressão de estado em atualizações concorrentes de sincronização (ex: `entregue` voltando para `pronto`).
  static bool isHigherOrEqual(String? existingStatus, String? incomingStatus) {
    final existingRank = getRank(existingStatus);
    final incomingRank = getRank(incomingStatus);

    // Cancelado é terminal absoluto — nenhuma transição para estado ativo é permitida
    if (existingRank == 99 && incomingRank != 99) return true;

    return existingRank >= incomingRank;
  }

  /// Retorna `true` se a transição de [existingStatus] para [incomingStatus] é uma progressão válida.
  static bool shouldAllowTransition(String? existingStatus, String? incomingStatus) {
    final existingRank = getRank(existingStatus);
    final incomingRank = getRank(incomingStatus);

    // Cancelamento é sempre permitido a partir de qualquer estado não cancelado
    if (incomingRank == 99) return true;

    // Se o estado atual for terminal de sucesso (entregue/finalizado/concluido), não aceita regressão
    if (existingRank == 4 && incomingRank < 4) return false;

    // Se o estado atual for cancelado, não aceita mudança
    if (existingRank == 99) return false;

    return incomingRank > existingRank;
  }

  /// Retorna o status de maior precedência entre dois estados.
  static String resolveHighestStatus(String statusA, String statusB) {
    final rankA = getRank(statusA);
    final rankB = getRank(statusB);
    return rankA >= rankB ? statusA : statusB;
  }
}
