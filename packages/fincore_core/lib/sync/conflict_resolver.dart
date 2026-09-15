import '../src/logging/log_service.dart';

/// Estratégias de resolução de conflito disponíveis por tipo de entidade
enum ConflictStrategy {
  /// Last Write Wins (LWW) — A versão mais recente ou com maior `syncVersion` prevalece.
  /// Usada para cadastros base (Cliente, Produto, Categoria, Configurações).
  lww,

  /// Merge de campos independentes — Une dados alterados em campos distintos.
  merge,

  /// Rejeitar/Bloquear Conflito — O servidor nunca sobrescreve automaticamente.
  /// Usado para entidades críticas (Pedidos, Movimentações Financeiras, Estoque).
  rejectAndLock,
}

/// Decisão tomada pelo ConflictResolver para um registro específico
class ConflictDecision {
  final bool allowOverwrite;
  final ConflictStrategy strategy;
  final String reason;
  final Map<String, dynamic>? mergedPayload;

  const ConflictDecision({
    required this.allowOverwrite,
    required this.strategy,
    required this.reason,
    this.mergedPayload,
  });

  @override
  String toString() =>
      'ConflictDecision(allow=$allowOverwrite, strategy=${strategy.name}, reason=$reason)';
}

/// Responsável por avaliar e resolver conflitos de sincronização entre dados locais e remotos.
class ConflictResolver {
  const ConflictResolver();

  /// Avalia se um registro vindo do servidor pode sobrescrever o registro local.
  ///
  /// ## Regras de Ouro:
  /// 1. **Escudo do Outbox**: Se o registro possui pendência local no Outbox, NUNCA sobrescrever,
  ///    independentemente de qual `syncVersion` ou `updatedAt` o servidor possui.
  /// 2. **Nível da Entidade**:
  ///    - **Cadastros (Master Data)**: Usam LWW com base no `syncVersion`.
  ///    - **Entidades Críticas (Pedidos/Financeiro)**: Rejeitam sobrescrita automática em conflito.
  ConflictDecision resolve({
    required String entityName,
    required String entityId,
    required bool hasOutboxPending,
    required int? localVersion,
    required int serverVersion,
    DateTime? localUpdatedAt,
    DateTime? serverUpdatedAt,
  }) {
    final shortId = entityId.length > 8 ? '${entityId.substring(0, 8)}...' : entityId;

    // ── 1. REGRA SUPREMA: Outbox Pendente ────────────────────────────────
    if (hasOutboxPending) {
      LogService.instance.info(
        LogModule.sync,
        '[CONFLICT_RESOLVER] 🛡️ REJEITADO POR OUTBOX PENDENTE\n'
        '  Entidade: $entityName\n'
        '  ID: $shortId\n'
        '  Versão Servidor: v$serverVersion vs Versão Local: v${localVersion ?? 1}\n'
        '  Motivo: Existe mutação pendente de envio no Outbox local.\n'
        '  Decisão: Servidor BLOQUEADO. Dado local preservado.',
      );
      return const ConflictDecision(
        allowOverwrite: false,
        strategy: ConflictStrategy.rejectAndLock,
        reason: 'Outbox local possui mutação pendente de envio.',
      );
    }

    // ── 2. ESTRATÉGIA POR ENTIDADE ───────────────────────────────────────
    final strategy = _getStrategyForEntity(entityName);

    switch (strategy) {
      case ConflictStrategy.rejectAndLock:
        // Para Pedidos/Financeiro: Se o registro já existe localmente e a versão local é diferente,
        // exige intervenção ou fusão explícita.
        if (localVersion != null && localVersion != serverVersion) {
          LogService.instance.warning(
            LogModule.sync,
            '[CONFLICT_RESOLVER] ⚠️ CONFLITO EM ENTIDADE CRÍTICA REJEITADO\n'
            '  Entidade: $entityName\n'
            '  ID: $shortId\n'
            '  Versão Servidor: v$serverVersion vs Versão Local: v$localVersion\n'
            '  Estratégia: rejectAndLock (Documento crítico não pode ser sobrescrito automaticamente)\n'
            '  Decisão: Servidor BLOQUEADO.',
          );
          return const ConflictDecision(
            allowOverwrite: false,
            strategy: ConflictStrategy.rejectAndLock,
            reason: 'Entidade crítica em conflito de versões (Exige tratamento manual).',
          );
        }
        break;

      case ConflictStrategy.lww:
        if (localVersion != null && serverVersion < localVersion) {
          LogService.instance.info(
            LogModule.sync,
            '[CONFLICT_RESOLVER] ⏭️ REJEITADO POR VERSÃO OBSOLETA (LWW)\n'
            '  Entidade: $entityName\n'
            '  ID: $shortId\n'
            '  Versão Servidor: v$serverVersion < Versão Local: v$localVersion\n'
            '  Decisão: Dado do servidor ignorado por ser mais antigo.',
          );
          return ConflictDecision(
            allowOverwrite: false,
            strategy: ConflictStrategy.lww,
            reason: 'Versão do servidor (v$serverVersion) é menor que a local (v$localVersion).',
          );
        }
        break;

      case ConflictStrategy.merge:
        // Reservado para mesclagem de campos futuros
        break;
    }

    // Se passou por todas as regras, o dado pode ser aplicado localmente
    return ConflictDecision(
      allowOverwrite: true,
      strategy: strategy,
      reason: 'Dado do servidor é válido e mais recente (syncVersion v$serverVersion).',
    );
  }

  ConflictStrategy _getStrategyForEntity(String entityName) {
    switch (entityName.toLowerCase()) {
      // Pedidos e KDS usam LWW por syncVersion — precisam sincronizar status entre computadores
      // em tempo real. A proteção do Outbox (Regra 1) garante que mutações locais pendentes
      // nunca sejam sobrescritas. Sem isso, o status de um pedido alterado no PC-A nunca
      // chegaria ao PC-B.
      case 'pedidos':
      case 'pedido':
      case 'ordems_preparo':
      case 'ordens_preparo':
      case 'historicos_ordem_preparo':
      case 'historicoordem_preparo':
      case 'estoque_produto':
      case 'movimentacao_estoque':
      case 'planejamento_producao':
        return ConflictStrategy.lww;

      case 'transacao_financeira':
      case 'financeiro':
        return ConflictStrategy.rejectAndLock;

      default:
        return ConflictStrategy.lww;
    }
  }
}
