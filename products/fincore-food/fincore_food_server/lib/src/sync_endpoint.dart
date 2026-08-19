import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';

// ─── NOTA ARQUITETURAL — SyncEndpoint ────────────────────────────────────────
//
// ⚠️  ESTADO: INCOMPLETO (Legado de primeira implementação)
//
// ARQUITETURA REAL DE SINCRONIZAÇÃO:
// A sincronização bidirecional do FINCORE Food ocorre DIRETAMENTE entre o
// app Flutter e o Supabase PostgreSQL via SDK do Supabase (SupabaseSyncService).
// O isolamento multi-tenant é garantido pelas políticas RLS do Supabase.
//
//   Flutter App ←──── SDK Supabase ────→ PostgreSQL (RLS)
//
// Este endpoint (SyncEndpoint) foi concebido para ser uma camada adicional de
// validação de negócio no servidor, mas está incompleto: apenas 'empresa_configuracao'
// é tratado no push(). O pull() também está incompleto.
//
// DECISÃO ARQUITETURAL PENDENTE (ARC-001 — Relatório de Auditoria):
//   Opção A: Completar o SyncEndpoint para ser o único canal de sync.
//            Vantagem: validações de negócio no servidor, logs centralizados.
//            Desvantagem: latência maior, requer reescrever toda a camada de sync.
//   Opção B: Manter sync direto via Supabase SDK e documentar formalmente.
//            Vantagem: menor latência, menos código.
//            Desvantagem: regras de negócio de escrita ficam no cliente.
//
// Status atual: Opção B (sync direto via Supabase) está ativa em produção.
// Este endpoint pode ser removido ou evoluído conforme decisão da equipe.
//
// ─────────────────────────────────────────────────────────────────────────────

class SyncEndpoint extends Endpoint {
  /// Recebe uma lista de alterações geradas no FincoreCore (Outbox)
  /// e as aplica no banco Postgres usando Last-Write-Wins.
  ///
  /// ⚠️  INCOMPLETO: Apenas 'empresa_configuracao' é tratado.
  /// Os demais casos caem no `default` com log de warning.
  /// O sync real acontece via SupabaseSyncService no Flutter.
  Future<bool> push(Session session, List<SyncPushEntry> changes) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) throw Exception('Usuário não autenticado');

    final tenantId = session.context['tenantId'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Sincronização abortada: Usuário sem Tenant');
    }

    // Processar cada mudança da lista
    for (final change in changes) {
      try {
        final payloadMap = jsonDecode(change.payload) as Map<String, dynamic>;
        
        // Mapear e atualizar o banco para cada "change.entity"
        switch (change.entity) {
          case 'empresa_configuracao':
            await _syncConfiguracao(session, tenantId, payloadMap);
            break;
          // Adicionar case para produtos, clientes, etc.
          default:
            session.log('Entidade desconhecida no sync: ${change.entity}', level: LogLevel.warning);
        }
      } catch (e) {
        session.log('Erro ao processar sync da entidade ${change.entity}: $e', level: LogLevel.error);
        return false;
      }
    }

    return true; // Push aplicado com sucesso
  }

  /// Retorna as modificações que ocorreram no servidor desde a última sincronização local
  Future<SyncPullPayload> pull(Session session, DateTime lastSyncAt) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) throw Exception('Usuário não autenticado');

    final tenantId = session.context['tenantId'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Sincronização abortada: Usuário sem Tenant');
    }

    // Buscar todas as configurações, membros, produtos, etc atualizados recentemente
    final configuracoes = await EmpresaConfiguracao.db.find(
      session,
      where: (t) => t.tenantId.equals(tenantId) & (t.updatedAt > lastSyncAt),
    );

    final membros = await MembroEmpresa.db.find(
      session,
      where: (t) => t.tenantId.equals(UuidValue.fromString(tenantId)) & (t.updatedAt > lastSyncAt),
    );

    // O SyncPullPayload encapsula todos os registros que precisam ser atualizados no client
    return SyncPullPayload(
      timestamp: DateTime.now().toUtc(),
      produtos: [],
      clientes: [],
      configuracoes: configuracoes,
      membros: membros,
    );
  }

  Future<void> _syncConfiguracao(Session session, String tenantId, Map<String, dynamic> payload) async {
    // Busca a configuração atual
    var config = await EmpresaConfiguracao.db.findFirstRow(
      session,
      where: (t) => t.tenantId.equals(tenantId)
    );

    if (config == null) return; // Se não existir, ignore o push ou crie (dependendo da lógica)

    // O FincoreCore envia metadados completos
    final syncVersionLocal = payload['syncVersion'] as int? ?? 1;

    // Conflito simplificado: O maior syncVersion vence
    if (syncVersionLocal >= config.syncVersion) {
      config.taxaServico = (payload['taxaServico'] as num?)?.toDouble() ?? config.taxaServico;
      config.usarWhatsApp = payload['usarWhatsApp'] == 1 || payload['usarWhatsApp'] == true;
      config.tema = payload['tema'] ?? config.tema;
      config.margemSegurancaMinutos = payload['margemSegurancaMinutos'] as int? ?? config.margemSegurancaMinutos;
      config.taxaEntregaPorKm = payload['taxaEntregaPorKm'] == 1 || payload['taxaEntregaPorKm'] == true;
      config.valorPorKmCentavos = payload['valorPorKmCentavos'] as int? ?? config.valorPorKmCentavos;
      config.syncVersion = syncVersionLocal;
      config.updatedAt = DateTime.now().toUtc();
      
      await EmpresaConfiguracao.db.updateRow(session, config);
    }
  }
}
