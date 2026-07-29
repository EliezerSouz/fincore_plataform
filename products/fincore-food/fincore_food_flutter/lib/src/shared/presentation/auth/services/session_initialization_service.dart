import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_food_flutter/src/shared/data/mappers/bootstrap_mapper.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
class SessionInitializationService {
  final Client _serverpodClient;
  
  SessionInitializationService(this._serverpodClient);

  Future<bool> initializeSession(AuthUserInfo userInfo) async {
    final tenantId = userInfo.tenantId;
    if (tenantId == null) {
      return false; // Usuário não tem tenant vinculado ainda (Onboarding pendente)
    }

    final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
    final empresaRepo = DependencyInjection().get<EmpresaRepository>();
    final tenantContext = DependencyInjection().get<TenantContext>();

    // 1. Tentar carregar do banco local SQLite
    CoreUsuario? localUser = await usuarioRepo.findById(userInfo.usuarioId);
    CoreEmpresa? localEmpresa = await empresaRepo.findById(tenantId);

    // 2. Se não existir no banco local (primeiro acesso no dispositivo com este usuário)
    if (localUser == null || localEmpresa == null) {
      final db = DependencyInjection().get<FincoreDatabase>();
      
      try {
        // 1. Faz o pull do Bootstrap da nuvem
        final payload = await _serverpodClient.bootstrap.bootstrapTenant();
        
        // 2. Transação para salvar tudo de uma vez
        await db.transaction(() async {
          // Mapeia do payload
          localUser = BootstrapMapper.toCoreUsuario(payload.usuario);
          localEmpresa = BootstrapMapper.toCoreEmpresa(payload.empresa);
          final localConfig = BootstrapMapper.toCoreConfiguracao(payload.configuracao);
          
          // 3. Preenche temporariamente o contexto na memória para que os Repositórios permitam o Save (segurança do Tenancy)
          tenantContext.setContext(empresa: localEmpresa!, usuario: localUser!);

          // Salva Usuário
          await usuarioRepo.save(localUser!);
          
          // Salva Empresa
          await empresaRepo.save(localEmpresa!);
          
          // Salva Configuração
          final configRepo = DependencyInjection().get<EmpresaConfiguracaoRepository>();
          await configRepo.save(localConfig);
          
          // Salva Membros
          final membroRepo = DependencyInjection().get<MembroEmpresaRepository>();
          for (final serverMembro in payload.membros) {
            final localMembro = BootstrapMapper.toCoreMembroEmpresa(serverMembro);
            await membroRepo.save(localMembro);
          }
        });
      } catch (e) {
        // Se falhar o bootstrap (sem internet ou erro), retornamos false
        print('Erro no bootstrap: $e');
        return false;
      }
    }

    // 3. Preencher a Sessão na Memória
    tenantContext.setContext(empresa: localEmpresa!, usuario: localUser!);

    return true;
  }
}
