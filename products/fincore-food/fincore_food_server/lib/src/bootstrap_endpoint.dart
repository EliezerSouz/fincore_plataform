import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';

class BootstrapEndpoint extends Endpoint {
  /// Retorna todos os dados necessários para inicializar o aplicativo no dispositivo do cliente.
  Future<BootstrapPayload> bootstrapTenant(Session session) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) {
      throw Exception('Usuário não autenticado');
    }

    final usuarioId = session.context['usuarioId'] as String;
    final email = session.context['email'] as String?;
    final userUuid = UuidValue.fromString(usuarioId);

    session.log('[BOOTSTRAP] Iniciando bootstrap para usuarioId=$usuarioId, email=$email', level: LogLevel.info);

    // 1. Buscar Usuário do domínio (por UUID, authUserId ou email)
    var usuario = await Usuario.db.findById(session, userUuid);
    if (usuario == null && email != null && email.isNotEmpty) {
      usuario = await Usuario.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email) | t.authUserId.equals(usuarioId),
      );
    }

    if (usuario == null) {
      final username = email != null ? email.split('@').first : 'usuario';
      final nome = username.replaceAll('.', ' ');
      usuario = Usuario(
        id: userUuid,
        tenantId: '00000000-0000-4000-a000-000000000001',
        authUserId: usuarioId,
        username: username,
        email: email,
        nome: nome,
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );
      usuario = await Usuario.db.insertRow(session, usuario);
    }

    // 2. Buscar vínculos na tabela MembroEmpresa para o usuário
    final membrosDoUsuario = await MembroEmpresa.db.find(
      session,
      where: (t) => t.usuarioId.equals(userUuid) | t.usuarioId.equals(usuario!.id),
    );

    session.log('[BOOTSTRAP] Membros encontrados para o usuario: ${membrosDoUsuario.length}', level: LogLevel.info);

    Empresa? empresa;
    UuidValue? tenantUuid;

    // Tentar carregar a empresa de cada membro até achar a empresa cadastrada
    for (final m in membrosDoUsuario) {
      final e = await Empresa.db.findById(session, m.tenantId);
      if (e != null) {
        empresa = e;
        tenantUuid = m.tenantId;
        session.log('[BOOTSTRAP] Empresa encontrada via MembroEmpresa: id=${e.id}, nome=${e.nomeFantasia}', level: LogLevel.info);
        break;
      }
    }

    // Se não encontrou via membro, busca por email da empresa ou criado por este usuário
    if (empresa == null && email != null && email.isNotEmpty) {
      empresa = await Empresa.db.findFirstRow(
        session,
        where: (e) => e.email.equals(email) | e.createdBy.equals(userUuid) | (usuario != null ? e.createdBy.equals(usuario.id) : Constant.bool(false)),
      );
      if (empresa != null) {
        tenantUuid = empresa.id;
        session.log('[BOOTSTRAP] Empresa encontrada via Email/CreatedBy: id=${empresa.id}, nome=${empresa.nomeFantasia}', level: LogLevel.info);
      }
    }

    if (empresa == null) {
      throw Exception('Nenhuma empresa cadastrada para o usuário $email. Realize o onboarding para criar sua empresa.');
    }

    final resolvedTenantId = tenantUuid.toString();

    // 3. Buscar os Membros da empresa real encontrada
    final membros = await MembroEmpresa.db.find(
      session,
      where: (t) => t.tenantId.equals(tenantUuid!),
    );

    // 4. Buscar a Configuração da empresa real encontrada
    var configuracao = await EmpresaConfiguracao.db.findFirstRow(
      session,
      where: (t) => t.tenantId.equals(resolvedTenantId),
    );

    if (configuracao == null) {
      configuracao = EmpresaConfiguracao(
        tenantId: resolvedTenantId,
        taxaServico: 0.10,
        usarWhatsApp: true,
        tema: 'light',
        syncVersion: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userUuid,
        updatedBy: userUuid,
        
        autoPrintCaixa: true,
        autoPrintCozinha: true,
        autoPrintBalcao: false,
        autoPrintExpedicao: false,
        viasCliente: 1,
        viasCozinha: 1,
        viasBalcao: 0,
        viasExpedicao: 0,
        larguraPapel: 80,
        cortarPapel: true,
        abrirGaveta: false,
        
        imprimirQRCode: true,
        imprimirCopiaCola: true,
        imprimirLogo: false,
        imprimirRodape: true,
        mensagemRodape: 'Obrigado pela preferência!',
        
        pixTipo: 'CPF',
      );
      configuracao = await EmpresaConfiguracao.db.insertRow(session, configuracao);
    }

    return BootstrapPayload(
      schemaVersion: 1,
      generatedAt: DateTime.now(),
      empresa: empresa,
      configuracao: configuracao,
      usuario: usuario,
      membros: membros,
    );
  }
}
