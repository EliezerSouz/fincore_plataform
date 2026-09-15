// ⚠️  ARQUIVO LEGADO — OBSOLETO (Arquitetura Local-First)
//
// O SessionInitializationService era responsável por inicializar a sessão
// via Serverpod Client. Foi completamente substituído pelo SupabaseSessionService.
//
// Este arquivo é mantido como stub vazio para não quebrar referências residuais.
// Pode ser deletado após verificação completa.
import 'package:fincore_core/fincore_core.dart';

/// @deprecated Use SupabaseSessionService em vez deste serviço.
class SessionInitializationService {
  SessionInitializationService();

  Future<bool> initializeSession(dynamic userInfo) async {
    LogService.instance.warning(
      LogModule.startup,
      '[LEGADO] SessionInitializationService.initializeSession() chamado — use SupabaseSessionService.',
    );
    return false;
  }
}
