// ⚠️  ARQUIVO LEGADO — REMOVIDO (Arquitetura Local-First)
//
// O ServerpodSyncHandler era o canal de sync via Serverpod.
// Na arquitetura local-first, o sync é feito exclusivamente pelo
// SupabaseSyncService, que está em:
//   lib/src/shared/data/sync/supabase_sync_service.dart
//
// Este arquivo é mantido apenas para evitar erros de referência durante
// a transição. Pode ser deletado após confirmação de que nenhum código
// o importa diretamente.

// ignore_for_file: avoid_print
import 'package:fincore_core/fincore_core.dart';

/// @deprecated Use SupabaseSyncService em vez deste handler.
class ServerpodSyncHandler {
  ServerpodSyncHandler();

  Future<bool> push(OutboxEntry entry) async {
    LogService.instance.warning(
      LogModule.sync,
      '[LEGADO] ServerpodSyncHandler.push() chamado — use SupabaseSyncService.',
    );
    return false;
  }

  Future<void> pull(DateTime lastSyncAt, FincoreDatabase db) async {
    LogService.instance.warning(
      LogModule.sync,
      '[LEGADO] ServerpodSyncHandler.pull() chamado — use SupabaseSyncService.',
    );
  }
}
