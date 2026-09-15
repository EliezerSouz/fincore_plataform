// ⚠️  ARQUIVO LEGADO — OBSOLETO (Arquitetura Local-First)
//
// O BootstrapMapper convertia tipos do Serverpod (Empresa, Usuario, etc.) 
// para CoreModels. Com a migração para Supabase direto, esses tipos não 
// existem mais. A conversão agora é feita pelo SupabaseSessionService via
// Map<String, dynamic> → CoreModel.
//
// Este arquivo é mantido como stub para não quebrar referências residuais.
// Pode ser deletado após verificação completa.

/// @deprecated Use SupabaseSessionService._mapEmpresa() em vez deste mapper.
class BootstrapMapper {
  // Stub vazio — lógica migrada para SupabaseSessionService
}
