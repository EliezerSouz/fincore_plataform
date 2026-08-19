import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_food_flutter/src/shared/data/mappers/bootstrap_mapper.dart';

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
    final membroRepo = DependencyInjection().get<MembroEmpresaRepository>();

    // 1. Tentar carregar do banco local SQLite
    final empresas = await empresaRepo.findAll();

    // P2-03/AUTH-001: Busca empresa pelo tenantId real do usuário autenticado.
    // NÃO usa firstOrNull cego — garante que o usuário pertence à empresa.
    CoreEmpresa? localEmpresa = empresas.where((e) => e.id == tenantId).firstOrNull;

    // Fallback: empresa não-demo cujo ID coincide com membro do usuário
    if (localEmpresa == null) {
      final membros = await membroRepo.findAll();
      final tenantIds = membros.map((m) => m.tenantId).toSet();
      localEmpresa = empresas
          .where((e) => tenantIds.contains(e.id) && e.nomeFantasia != 'FINCORE Food Demo')
          .firstOrNull;
    }

    // Se ainda null, não existe empresa válida no banco — precisa de bootstrap
    CoreUsuario? localUser = await usuarioRepo.findById(userInfo.usuarioId);
    localUser ??= (await usuarioRepo.findAll())
        .where((u) => u.tenantId == tenantId)
        .firstOrNull;

    final bool hasRealCompany = localEmpresa != null && localEmpresa.nomeFantasia != 'FINCORE Food Demo';
    final bool hasUser = localUser != null;

    // 2. Se já existir empresa real no banco local, configura o contexto e retorna
    if (hasUser && hasRealCompany) {
      tenantContext.setContext(empresa: localEmpresa, usuario: localUser);
      return true;
    }

    if (!hasUser || !hasRealCompany) {
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

          // Salva Empresa
          await empresaRepo.save(localEmpresa!);

          // Salva Usuário
          await usuarioRepo.save(localUser!);
          
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
      } catch (e, st) {
        LogService.instance.error(
          LogModule.startup,
          'Falha na inicialização do bootstrap de sessão',
          exception: e.toString(),
          stackTrace: st.toString(),
        );
        return false;
      }
    }

    // 3. Preencher a Sessão na Memória
    tenantContext.setContext(empresa: localEmpresa!, usuario: localUser!);

    return true;
  }
}
