import 'dart:convert';
import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';
import 'utils/timezone_helper.dart';

class OnboardingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Cria uma nova empresa (tenant) e vincula o usuário autenticado como OWNER.
  ///
  /// O tenantId é gerado pelo servidor, nunca pelo cliente.
  /// Ordem da transação: empresa → usuario → membro_empresa (respeita todas as FKs).
  Future<bool> criarEmpresa(
    Session session, {
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String emailEmpresa,
    required String telefoneEmpresa,
    required String usuarioNome,
    required String segmento,
    String? plano,
  }) async {
    final usuarioId = session.context['usuarioId'] as String;
    final usuarioEmail = session.context['email'] as String? ?? '';
    final now = TimezoneHelper.localNow;

    try {
      final docTrim = documentoFiscal.trim();
      final emailTrim = emailEmpresa.trim().toLowerCase();

      // Validações de Unicidade
      final existingDoc = await Empresa.db.findFirstRow(
        session,
        where: (t) => t.documentoFiscal.equals(docTrim),
      );
      if (existingDoc != null) {
        throw OnboardingException(message: 'Já existe uma empresa cadastrada com este CPF/CNPJ.');
      }

      final existingEmail = await Empresa.db.findFirstRow(
        session,
        where: (t) => t.email.equals(emailTrim),
      );
      if (existingEmail != null) {
        throw OnboardingException(message: 'Já existe uma empresa cadastrada com este e-mail comercial.');
      }

      await session.db.transaction((transaction) async {
        // O servidor gera o UUID do tenant — o cliente nunca deve fazer isso.
        final tenantId = const Uuid().v4();
        final tenantUuid = UuidValue.fromString(tenantId);
        final userUuid = UuidValue.fromString(usuarioId);

        // PASSO 1: Inserir a empresa primeiro.
        // usuarios.activeTenantId é apenas preferência — não tem FK rígida.
        // Mas para clareza e consistência, empresa sempre existe antes do vínculo.
        final tipoPessoa = docTrim.replaceAll(RegExp(r'\D'), '').length <= 11 ? 'FISICA' : 'JURIDICA';
        final empresa = Empresa(
          id: tenantUuid,
          razaoSocial: razaoSocial,
          nomeFantasia: nomeFantasia,
          documentoFiscal: docTrim,
          email: emailTrim,
          telefone: telefoneEmpresa,
          status: 'PENDENTE_ATIVACAO',
          plano: (plano != null && plano.trim().isNotEmpty) ? plano.trim() : 'bronze',
          timezone: 'America/Sao_Paulo',
          locale: 'pt_BR',
          currency: 'BRL',
          country: 'BR',
          createdFrom: 'Web',
          segmento: segmento,
          vencimento: now.add(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
          createdBy: userUuid,
          updatedBy: userUuid,
          syncVersion: 1,
          tipoPessoa: tipoPessoa,
        );
        await Empresa.db.insertRow(session, empresa);

        // PASSO 2: Inserir ou atualizar o usuário com o activeTenantId da nova empresa
        final existingUser = await Usuario.db.findById(session, userUuid);
        if (existingUser == null) {
          final user = Usuario(
            id: userUuid,
            activeTenantId: tenantUuid, // Preferência de contexto ativo (UuidValue)
            authUserId: usuarioId,
            username: usuarioEmail.split('@').first,
            email: usuarioEmail,
            nome: usuarioNome,
            ativo: true,
            criadoEm: now,
            atualizadoEm: now,
          );
          await Usuario.db.insertRow(session, user);
        } else {
          // Usuário já existe (pode ter criado outra empresa antes).
          // Atualiza o nome e define o activeTenantId para a nova empresa.
          existingUser.nome = usuarioNome;
          existingUser.email = usuarioEmail;
          existingUser.activeTenantId = tenantUuid;
          existingUser.atualizadoEm = now;
          await Usuario.db.updateRow(session, existingUser);
        }

        // PASSO 2.2: Log imutável de auditoria da criação da empresa
        final evento = EventoEmpresa(
          id: UuidValue.fromString(const Uuid().v4()),
          tenantId: tenantUuid,
          tipo: 'CRIADA',
          payload: jsonEncode({
            'razaoSocial': razaoSocial,
            'nomeFantasia': nomeFantasia,
            'documentoFiscal': docTrim,
            'segmento': segmento,
          }),
          geradoPor: usuarioId,
          ocorridoEm: now,
        );
        await EventoEmpresa.db.insertRow(session, evento);

        // PASSO 2.3: Configurações padrão da empresa (1:1 obrigatório)
        final config = EmpresaConfiguracao(
          id: UuidValue.fromString(const Uuid().v4()),
          tenantId: tenantId,
          taxaServico: 0.10,
          usarWhatsApp: true,
          tema: 'escuro',
          createdAt: now,
          updatedAt: now,
          createdBy: userUuid,
          updatedBy: userUuid,
          syncVersion: 1,
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
        await EmpresaConfiguracao.db.insertRow(session, config);

        // PASSO 2.4: Cliente padrão "Consumidor Final" (vendas avulsas de balcão)
        final clientePadrao = Cliente(
          id: UuidValue.fromString(const Uuid().v4()),
          tenantId: tenantId,
          nome: 'Consumidor Final',
          telefone: '00000000000',
          observacoes: 'Cliente padrão imutável para vendas avulsas de balcão',
          ativo: true,
          aceitaMarketing: false,
          aceitaWhatsapp: false,
          createdAt: now,
          updatedAt: now,
          createdBy: userUuid,
          updatedBy: userUuid,
          syncVersion: 1,
        );
        await Cliente.db.insertRow(session, clientePadrao);

        // PASSO 3: Vincular usuário à empresa como OWNER (não ADMIN)
        // OWNER = proprietário que criou a empresa, não pode ser removido
        final membro = MembroEmpresa(
          id: UuidValue.fromString(const Uuid().v4()),
          tenantId: tenantUuid,
          usuarioId: userUuid,
          role: 'OWNER',
          ativo: true,
          convidadoEm: now,
          aceitoEm: now,
          createdAt: now,
          updatedAt: now,
          createdBy: userUuid,
          updatedBy: userUuid,
          syncVersion: 1,
        );
        await MembroEmpresa.db.insertRow(session, membro);

        session.log(
          '[ONBOARDING] Empresa "$nomeFantasia" criada. Tenant: $tenantId. Usuário: $usuarioEmail vinculado como OWNER.',
          level: LogLevel.info,
        );
      });
      return true;
    } on OnboardingException {
      rethrow;
    } catch (e) {
      session.log('Erro ao criar empresa no banco central: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Retorna todas as empresas nas quais o usuário logado possui vínculo ativo.
  ///
  /// Usada pelo Flutter para:
  /// - Determinar se o usuário deve ir para o Onboarding (lista vazia)
  /// - Determinar se deve entrar direto (1 empresa)
  /// - Exibir a tela de seleção (2+ empresas)
  Future<List<Empresa>> minhasEmpresas(Session session) async {
    final usuarioId = session.context['usuarioId'] as String?;
    if (usuarioId == null) return [];

    try {
      final userUuid = UuidValue.fromString(usuarioId);

      // Busca todos os vínculos ativos do usuário
      final membros = await MembroEmpresa.db.find(
        session,
        where: (t) => t.usuarioId.equals(userUuid) & t.ativo.equals(true),
      );

      if (membros.isEmpty) return [];

      // Carrega os dados de cada empresa em paralelo
      final empresas = <Empresa>[];
      for (final m in membros) {
        final empresa = await Empresa.db.findById(session, m.tenantId);
        if (empresa != null) {
          empresas.add(empresa);
        }
      }

      session.log(
        '[ONBOARDING] minhasEmpresas: ${empresas.length} empresa(s) encontrada(s) para usuário $usuarioId',
        level: LogLevel.info,
      );

      return empresas;
    } catch (e) {
      session.log('Erro ao listar empresas do usuário: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Troca o contexto ativo para a empresa especificada e retorna os dados de bootstrap.
  ///
  /// Valida se o usuário possui vínculo ativo no tenant antes de permitir a troca.
  /// Atualiza usuarios.activeTenantId para persistir a preferência.
  Future<BootstrapPayload?> trocarEmpresa(Session session, String novoTenantId) async {
    final usuarioId = session.context['usuarioId'] as String?;
    if (usuarioId == null) return null;

    try {
      final userUuid = UuidValue.fromString(usuarioId);
      final tenantUuid = UuidValue.fromString(novoTenantId);

      // Validação de segurança: o usuário deve ter vínculo ativo no tenant
      final membro = await MembroEmpresa.db.findFirstRow(
        session,
        where: (t) => t.usuarioId.equals(userUuid) & t.tenantId.equals(tenantUuid) & t.ativo.equals(true),
      );

      if (membro == null) {
        session.log(
          '[ONBOARDING] trocarEmpresa negado: usuário $usuarioId sem vínculo ativo no tenant $novoTenantId',
          level: LogLevel.warning,
        );
        return null;
      }

      // Atualizar a preferência de contexto ativo do usuário
      final usuario = await Usuario.db.findById(session, userUuid);
      if (usuario != null) {
        usuario.activeTenantId = tenantUuid;
        usuario.atualizadoEm = DateTime.now();
        await Usuario.db.updateRow(session, usuario);
      }

      // Retornar o bootstrap completo da nova empresa
      final empresa = await Empresa.db.findById(session, tenantUuid);
      if (empresa == null) return null;

      final membros = await MembroEmpresa.db.find(
        session,
        where: (t) => t.tenantId.equals(tenantUuid),
      );

      var configuracao = await EmpresaConfiguracao.db.findFirstRow(
        session,
        where: (t) => t.tenantId.equals(novoTenantId),
      );

      // Fallback de configuração (segurança — não deveria acontecer)
      configuracao ??= EmpresaConfiguracao(
        tenantId: novoTenantId,
        taxaServico: 0.10,
        usarWhatsApp: true,
        tema: 'escuro',
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

      session.log(
        '[ONBOARDING] trocarEmpresa: usuário $usuarioId trocou para tenant $novoTenantId (${empresa.nomeFantasia})',
        level: LogLevel.info,
      );

      return BootstrapPayload(
        schemaVersion: 1,
        generatedAt: DateTime.now(),
        empresa: empresa,
        configuracao: configuracao,
        usuario: usuario ?? await Usuario.db.findById(session, userUuid) ?? Usuario(
          id: userUuid,
          authUserId: usuarioId,
          username: usuarioId,
          nome: 'Usuário',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        membros: membros,
      );
    } catch (e) {
      session.log('Erro ao trocar empresa: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Consulta os dados da empresa ativa do usuário autenticado.
  /// Prioridade: X-Tenant-ID header > activeTenantId > primeiro membro.
  Future<Empresa?> minhaEmpresa(Session session) async {
    final usuarioId = session.context['usuarioId'] as String?;
    if (usuarioId == null) return null;
    try {
      final userUuid = UuidValue.fromString(usuarioId);
      final tenantIdCtx = session.context['tenantId'] as String?;

      if (tenantIdCtx != null && tenantIdCtx.isNotEmpty) {
        return await Empresa.db.findById(session, UuidValue.fromString(tenantIdCtx));
      }

      // Fallback: primeiro membro ativo
      final membro = await MembroEmpresa.db.findFirstRow(
        session,
        where: (t) => t.usuarioId.equals(userUuid) & t.ativo.equals(true),
      );
      if (membro == null) return null;

      return await Empresa.db.findById(session, membro.tenantId);
    } catch (e) {
      session.log('Erro ao buscar minha empresa: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Consulta o status de ativação da empresa ativa do usuário.
  Future<String?> status(Session session) async {
    final empresa = await minhaEmpresa(session);
    return empresa?.status;
  }

  /// Calcula o progresso do setup do workspace (categorias, produtos, etc.)
  Future<WorkspaceSetupProgressInfo> progressoSetup(Session session, String tenantId) async {
    try {
      final tenantUuid = UuidValue.fromString(tenantId);

      final empresa = await Empresa.db.findById(session, tenantUuid);
      final bool empresaCriada = empresa != null;
      final bool contaAtiva = empresaCriada && empresa.status == 'ativo';

      final membros = await MembroEmpresa.db.find(
        session,
        where: (t) => t.tenantId.equals(tenantUuid) & t.ativo.equals(true),
        limit: 1,
      );
      final bool loginRealizado = membros.isNotEmpty;

      final categoriasCount = await Categoria.db.count(
        session,
        where: (t) => t.tenantId.equals(tenantId),
      );
      final bool categoriasCadastradas = categoriasCount > 0;

      final produtosCount = await Produto.db.count(
        session,
        where: (t) => t.tenantId.equals(tenantId),
      );
      final bool produtosCadastrados = produtosCount > 0;

      final clientesCount = await Cliente.db.count(
        session,
        where: (t) => t.tenantId.equals(tenantId),
      );
      final bool clientesCadastrados = clientesCount > 0;

      const bool vendaRealizada = false;

      final checklist = {
        'empresa_criada': empresaCriada,
        'conta_ativa': contaAtiva,
        'login_realizado': loginRealizado,
        'categorias_cadastradas': categoriasCadastradas,
        'produtos_cadastrados': produtosCadastrados,
        'clientes_cadastrados': clientesCadastrados,
        'venda_realizada': vendaRealizada,
      };

      final concluidos = checklist.values.where((v) => v).length;
      final passos = checklist.length;
      final percentual = (concluidos / passos) * 100;

      return WorkspaceSetupProgressInfo(
        passos: passos,
        concluidos: concluidos,
        percentual: percentual,
        checklistJson: jsonEncode(checklist),
      );
    } catch (e) {
      session.log('Erro ao calcular progresso do setup: $e', level: LogLevel.error);
      rethrow;
    }
  }
}
