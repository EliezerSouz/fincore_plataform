import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';
import 'utils/timezone_helper.dart';

class OnboardingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Cria uma nova empresa (tenant) e vincula o usuário autenticado como ADMIN.
  Future<bool> criarEmpresa(
    Session session, {
    required String tenantId,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String emailEmpresa,
    required String telefoneEmpresa,
    required String usuarioNome,
    required String segmento,
  }) async {
    final usuarioId = session.context['usuarioId'] as String;
    final usuarioEmail = session.context['email'] as String? ?? '';
    final now = TimezoneHelper.localNow;

    try {
      // Validações de Unicidade
      final docTrim = documentoFiscal.trim();
      final emailTrim = emailEmpresa.trim().toLowerCase();

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
        final tenantUuid = UuidValue.fromString(tenantId);
        final userUuid = UuidValue.fromString(usuarioId);

        // 1. Inserir na tabela usuario (global) - DEVE ser o primeiro devido às FKs nas outras tabelas
        final existingUser = await Usuario.db.findById(session, userUuid);
        if (existingUser == null) {
          final user = Usuario(
            id: userUuid,
            email: usuarioEmail,
            nome: usuarioNome,
            criadoEm: now,
            atualizadoEm: now,
          );
          await Usuario.db.insertRow(session, user);
        } else {
          existingUser.nome = usuarioNome;
          existingUser.email = usuarioEmail;
          existingUser.atualizadoEm = now;
          await Usuario.db.updateRow(session, existingUser);
        }

        // 2. Inserir na tabela empresa
        final empresa = Empresa(
          id: tenantUuid,
          razaoSocial: razaoSocial,
          nomeFantasia: nomeFantasia,
          documentoFiscal: docTrim,
          email: emailTrim,
          telefone: telefoneEmpresa,
          status: 'PENDENTE_ATIVACAO',
          plano: 'bronze',
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
        );
        await Empresa.db.insertRow(session, empresa);

        // 2.2. Criar log imutável de auditoria (EventoEmpresa)
        final evento = EventoEmpresa(
          id: UuidValue.fromString(Uuid().v4()),
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

        // 2.5. Criar configurações padrão (1:1 Obrigatório - CAP.CONFIGURATION)
        final config = EmpresaConfiguracao(
          id: UuidValue.fromString(Uuid().v4()),
          tenantId: tenantId,
          timezone: 'America/Sao_Paulo',
          locale: 'pt_BR',
          currency: 'BRL',
          taxaServico: 0.10,
          usarWhatsApp: true,
          tema: 'escuro',
          createdAt: now,
          updatedAt: now,
          createdBy: userUuid,
          updatedBy: userUuid,
          syncVersion: 1,
          
          // Impressão e Hardware Defaults
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
          
          // QR Code e Layout Defaults
          imprimirQRCode: true,
          imprimirCopiaCola: true,
          imprimirLogo: false,
          imprimirRodape: true,
          mensagemRodape: 'Obrigado pela preferência!',
          
          // PIX Defaults
          pixTipo: 'CPF',
          pixCidade: 'Sorocaba',
        );
        await EmpresaConfiguracao.db.insertRow(session, config);

        // 2.6. Criar Cliente Padrão: "Consumidor Final"
        final clientePadrao = Cliente(
          id: UuidValue.fromString(Uuid().v4()),
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

        // 3. Inserir na tabela membro_empresa
        final membro = MembroEmpresa(
          id: UuidValue.fromString(Uuid().v4()),
          tenantId: tenantUuid,
          usuarioId: userUuid,
          role: 'ADMIN',
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

        session.log('SIMULAÇÃO EMAIL: Enviando email de boas-vindas para $usuarioEmail (Empresa: $razaoSocial)', level: LogLevel.info);
      });
      return true;
    } on OnboardingException catch (e) {
      rethrow;
    } catch (e) {
      session.log('Erro ao criar empresa no banco central: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Consulta o status de ativação da empresa vinculada ao usuário
  Future<String?> status(Session session) async {
    final usuarioId = session.context['usuarioId'] as String;
    try {
      final userUuid = UuidValue.fromString(usuarioId);
      final membro = await MembroEmpresa.db.findFirstRow(
        session,
        where: (t) => t.usuarioId.equals(userUuid),
      );
      if (membro == null) return null;

      final empresa = await Empresa.db.findById(session, membro.tenantId);
      return empresa?.status;
    } catch (e) {
      session.log('Erro ao buscar status: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Calcula o progresso do setup do workspace (categorias, produtos, etc.)
  Future<WorkspaceSetupProgressInfo> progressoSetup(Session session, String tenantId) async {
    try {
      final tenantUuid = UuidValue.fromString(tenantId);

      // 1. Checar Empresa
      final empresa = await Empresa.db.findById(session, tenantUuid);
      final bool empresaCriada = empresa != null;
      final bool contaAtiva = empresaCriada && empresa.status == 'ativo';

      // 2. Checar Primeiro Login (membros ativos)
      final membros = await MembroEmpresa.db.find(
        session,
        where: (t) => t.tenantId.equals(tenantUuid) & t.ativo.equals(true),
        limit: 1,
      );
      final bool loginRealizado = membros.isNotEmpty;

      // 3. Checar Categorias
      final categoriasCount = await Categoria.db.count(
        session,
        where: (t) => t.tenantId.equals(tenantId),
      );
      final bool categoriasCadastradas = categoriasCount > 0;

      // 4. Checar Produtos
      final produtosCount = await Produto.db.count(
        session,
        where: (t) => t.tenantId.equals(tenantId),
      );
      final bool produtosCadastrados = produtosCount > 0;

      // 5. Checar Clientes
      final clientesCount = await Cliente.db.count(
        session,
        where: (t) => t.tenantId.equals(tenantId),
      );
      final bool clientesCadastrados = clientesCount > 0;

      // 6. Checar Vendas (ordens preparadas)
      final bool vendaRealizada = false;

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
