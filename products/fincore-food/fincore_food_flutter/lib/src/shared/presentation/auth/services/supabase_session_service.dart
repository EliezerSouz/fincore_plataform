import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_core/fincore_core.dart';
import '../models/auth_user_info.dart';

/// Resultado da inicialização de sessão via Supabase.
class SupabaseSessionResult {
  final AuthUserInfo? authInfo;

  /// null = usuário sem empresa (ir para Onboarding)
  /// 'ATIVO' = empresa ativa (ir para Shell)
  /// 'PENDENTE_ATIVACAO' = aguardando aprovação
  final String? onboardingStatus;

  /// Preenchida quando o usuário tem N>1 empresas vinculadas
  final List<Map<String, dynamic>>? multiEmpresas;

  const SupabaseSessionResult({
    this.authInfo,
    this.onboardingStatus,
    this.multiEmpresas,
  });
}

/// Substitui o SessionInitializationService + todas as chamadas Serverpod no Router.
///
/// Responsabilidades:
/// 1. Buscar dados do usuário autenticado no Supabase (usuários, empresa, membros)
/// 2. Inicializar o banco SQLite local via pull do Supabase (bootstrap)
/// 3. Configurar o TenantContext com empresa e usuário corretos
/// 4. Retornar [SupabaseSessionResult] com AuthUserInfo e status de onboarding
///
/// Fluxo:
/// ```
/// Supabase Auth → SupabaseSessionService → TenantContext → Router
///                       ↓
///                 SQLite local (cache)
/// ```
class SupabaseSessionService {
  final SupabaseClient _supabase;

  SupabaseSessionService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────
  // HEALTH CHECK — substitui client.greeting.hello("ping")
  // ─────────────────────────────────────────────────────────────

  /// Verifica se o Supabase está acessível sem autenticação.
  /// Retorna true se online.
  Future<bool> isSupabaseReachable() async {
    try {
      await _supabase.from('empresa').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SESSION INIT — substitui client.auth.login() + SessionInitializationService
  // ─────────────────────────────────────────────────────────────

  /// Inicializa a sessão completa para o usuário autenticado no Supabase.
  ///
  /// 1. Busca o perfil do usuário no banco remoto
  /// 2. Busca as empresas vinculadas ao usuário
  /// 3. Se dados locais ausentes: faz bootstrap via pull do Supabase
  /// 4. Configura o TenantContext
  /// 5. Retorna [SupabaseSessionResult]
  Future<SupabaseSessionResult> initializeSession() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return const SupabaseSessionResult();
    }

    final supabaseUserId = currentUser.id;
    final email = currentUser.email ?? '';
    final traceId = CorrelationIdGenerator.generateCorrelationId();

    await LogService.instance.logOperational(
      process: 'AUTENTICACAO',
      step: 'INICIALIZACAO_SESSAO',
      action: 'INICIO',
      message: 'Iniciando autenticação e verificação de perfil | Email: $email',
      traceId: traceId,
      entityType: 'usuario',
      entityId: supabaseUserId,
    );

    // 1. Buscar perfil de usuário no Supabase (tabela usuarios)
    final usuarioRows = await _supabase
        .from('usuarios')
        .select()
        .or('authUserId.eq.$supabaseUserId,email.eq.$email')
        .limit(1);

    Map<String, dynamic>? usuarioRow =
        usuarioRows.isNotEmpty ? usuarioRows.first as Map<String, dynamic> : null;

    // Se não existe perfil, criar um mínimo
    if (usuarioRow == null) {
      final username = email.isNotEmpty ? email.split('@').first : 'usuario';
      final now = DateTime.now().toUtc().toIso8601String();
      final insertResult = await _supabase.from('usuarios').upsert({
        'authUserId': supabaseUserId,
        'email': email,
        'username': username,
        'nome': username.replaceAll('.', ' '),
        'ativo': true,
        'criadoEm': now,
        'atualizadoEm': now,
      }, onConflict: 'authUserId').select();
      usuarioRow = insertResult.isNotEmpty
          ? insertResult.first as Map<String, dynamic>
          : null;
    }

    if (usuarioRow == null) {
      LogService.instance.warning(
        LogModule.startup,
        '[Session] Não foi possível criar/buscar perfil de usuário no Supabase',
      );
      return const SupabaseSessionResult();
    }

    final usuarioId = usuarioRow['id'] as String? ?? supabaseUserId;

    // Helper interno para carregar membro_empresa + empresa sem depender de autorrelacionamentos do PostgREST (PGRST201)
    Future<List<Map<String, dynamic>>> fetchMembrosComEmpresa({
      String? filterUsuarioId,
      String? filterTenantId,
    }) async {
      try {
        var query = _supabase.from('membro_empresa').select();
        if (filterUsuarioId != null) {
          query = query.eq('usuarioId', filterUsuarioId);
        }
        if (filterTenantId != null) {
          query = query.eq('tenantId', filterTenantId);
        }
        final membrosRows = await query;
        final List<Map<String, dynamic>> resultMembros =
            membrosRows.cast<Map<String, dynamic>>();

        if (resultMembros.isEmpty) return [];

        final tenantIds = resultMembros
            .map((m) => m['tenantId'] as String?)
            .whereType<String>()
            .toSet()
            .toList();

        if (tenantIds.isEmpty) return resultMembros;

        final empresasRows = await _supabase
            .from('empresa')
            .select()
            .inFilter('id', tenantIds);

        final Map<String, Map<String, dynamic>> empresasMap = {
          for (final e in empresasRows.cast<Map<String, dynamic>>())
            e['id'] as String: e
        };

        return resultMembros.map((m) {
          final copy = Map<String, dynamic>.from(m);
          final tId = copy['tenantId'] as String?;
          if (tId != null && empresasMap.containsKey(tId)) {
            copy['empresa'] = empresasMap[tId];
          }
          return copy;
        }).toList();
      } catch (e) {
        LogService.instance.warning(
          LogModule.startup,
          '[Session] Erro ao buscar membros/empresas: $e',
        );
        return [];
      }
    }

    // 2. Buscar vínculos de empresas (membro_empresa + empresa)
    List<Map<String, dynamic>> membros =
        await fetchMembrosComEmpresa(filterUsuarioId: usuarioId);

    // 2b. Autorrecuperação: se o vínculo em membro_empresa não existir, mas a empresa já existe no Supabase
    if (membros.isEmpty) {
      final empresasRecuperadas = await _supabase
          .from('empresa')
          .select()
          .or('createdBy.eq.$supabaseUserId,email.eq.$email')
          .limit(1);

      if (empresasRecuperadas.isNotEmpty) {
        final empRec = empresasRecuperadas.first as Map<String, dynamic>;
        final empId = empRec['id'] as String;
        final now = DateTime.now().toUtc().toIso8601String();

        LogService.instance.info(
          LogModule.startup,
          '[Session] Empresa pré-existente encontrada (tenantId=$empId) — criando vínculo de membro...',
        );

        final checkMembro = await fetchMembrosComEmpresa(
          filterUsuarioId: usuarioId,
          filterTenantId: empId,
        );

        if (checkMembro.isNotEmpty) {
          membros = checkMembro;
        } else {
          await _supabase.from('membro_empresa').insert({
            'tenantId': empId,
            'usuarioId': usuarioId,
            'role': 'ADMIN',
            'ativo': true,
            'convidadoEm': now,
            'aceitoEm': now,
            'createdBy': supabaseUserId,
            'updatedBy': supabaseUserId,
            'createdAt': now,
            'updatedAt': now,
            'syncVersion': 1,
          });

          membros = await fetchMembrosComEmpresa(
            filterUsuarioId: usuarioId,
            filterTenantId: empId,
          );
        }
      }
    }

    // 3. Se ainda assim não tiver nenhum membro/empresa → Onboarding
    if (membros.isEmpty) {
      LogService.instance.info(
        LogModule.startup,
        '[Session] Usuário sem empresa vinculada → Onboarding',
      );
      return const SupabaseSessionResult();
    }

    // 4. Se tem múltiplas empresas → seleção
    if (membros.length > 1) {
      final empresas = membros
          .map((m) => m['empresa'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .toList();
      return SupabaseSessionResult(multiEmpresas: empresas);
    }

    // 5. Exatamente 1 empresa → bootstrap direto
    final membro = membros.first;
    final empresaRow = membro['empresa'] as Map<String, dynamic>?;

    if (empresaRow == null) {
      return const SupabaseSessionResult();
    }

    final tenantId = empresaRow['id'] as String;
    final role = membro['role'] as String? ?? 'OPERADOR';
    final empresaStatus = empresaRow['status'] as String? ?? 'ATIVO';

    // 6. Garantir dados no SQLite local (bootstrap se necessário)
    final bootstrapOk = await _bootstrapLocalDatabase(
      usuarioRow: usuarioRow,
      empresaRow: empresaRow,
      membroRow: membro,
      tenantId: tenantId,
      role: role,
    );

    if (!bootstrapOk) {
      LogService.instance.warning(
        LogModule.startup,
        '[Session] Falha no bootstrap local — operando com dados existentes',
      );
    }

    final onboardingStatus = empresaStatus.toUpperCase() == 'PENDENTE_ATIVACAO'
        ? 'PENDENTE_ATIVACAO'
        : 'ATIVO';

    await LogService.instance.logOperational(
      process: 'AUTENTICACAO',
      step: 'INICIALIZACAO_SESSAO',
      action: 'RESULTADO',
      message: 'Sessão autenticada | Usuário: $usuarioId | Tenant: $tenantId | Role: $role | Onboarding: $onboardingStatus',
      traceId: traceId,
      entityType: 'usuario',
      entityId: usuarioId,
      status: LogStatus.success,
      tenantId: tenantId,
      userId: usuarioId,
    );

    return SupabaseSessionResult(
      authInfo: AuthUserInfo(
        usuarioId: usuarioId,
        email: email,
        role: role,
        tenantId: tenantId,
      ),
      onboardingStatus: onboardingStatus,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ONBOARDING STATUS — substitui client.onboarding.status()
  // ─────────────────────────────────────────────────────────────

  /// Busca o status de onboarding de uma empresa no Supabase.
  /// Retorna 'ATIVO', 'PENDENTE_ATIVACAO' ou null.
  Future<String?> getOnboardingStatus(String tenantId) async {
    try {
      final rows = await _supabase
          .from('empresa')
          .select('status')
          .eq('id', tenantId)
          .limit(1);
      if (rows.isEmpty) return null;
      final status = (rows.first as Map<String, dynamic>)['status'] as String?;
      return status?.toUpperCase();
    } catch (e) {
      LogService.instance.error(
        LogModule.startup,
        '[Session] Falha ao buscar status de onboarding',
        exception: e.toString(),
      );
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BOOTSTRAP LOCAL — substitui client.bootstrap.bootstrapTenant()
  // ─────────────────────────────────────────────────────────────

  /// Popula o SQLite local com dados do Supabase se ainda não existirem.
  /// Replica a lógica do BootstrapEndpoint do Serverpod.
  Future<bool> _bootstrapLocalDatabase({
    required Map<String, dynamic> usuarioRow,
    required Map<String, dynamic> empresaRow,
    required Map<String, dynamic> membroRow,
    required String tenantId,
    required String role,
  }) async {
    final di = DependencyInjection();
    final empresaRepo = di.get<EmpresaRepository>();
    final usuarioRepo = di.get<UsuarioRepository>();
    final tenantContext = di.get<TenantContext>();
    final membroRepo = di.get<MembroEmpresaRepository>();
    final configRepo = di.get<EmpresaConfiguracaoRepository>();
    final db = di.get<FincoreDatabase>();

    // Verificar se já tem dados reais no banco local
    final empresasLocais = await empresaRepo.findAll();
    final hasRealCompany = empresasLocais
        .any((e) => e.id == tenantId && e.nomeFantasia != 'FINCORE Food Demo');

    final usuariosLocais = await usuarioRepo.findAll();
    final hasUser = usuariosLocais.any((u) =>
        u.id == (usuarioRow['id'] as String?) ||
        u.authUserId == (usuarioRow['authUserId'] as String?));

    if (hasRealCompany && hasUser) {
      // Já tem dados — apenas atualizar contexto
      final localEmpresa = empresasLocais.firstWhere((e) => e.id == tenantId);
      final localUser = usuariosLocais.firstWhere(
        (u) =>
            u.id == (usuarioRow['id'] as String?) ||
            u.authUserId == (usuarioRow['authUserId'] as String?),
      );
      tenantContext.setContext(
        empresa: localEmpresa,
        usuario: localUser.copyWith(role: role),
      );
      return true;
    }

    LogService.instance.info(
      LogModule.startup,
      '[Session] Banco local vazio — executando bootstrap via Supabase pull...',
    );

    try {
      // Mapear Empresa
      final coreEmpresa = _mapEmpresa(empresaRow);

      // Mapear Usuário
      final coreUsuario = _mapUsuario(usuarioRow, tenantId, role);

      // Mapear Membro
      final coreMembro = _mapMembro(membroRow);

      await db.transaction(() async {
        // Definir contexto temporário para que os repos aceitem o save
        tenantContext.setContext(empresa: coreEmpresa, usuario: coreUsuario);

        // Salvar empresa localmente sem enfileirar no Outbox (já veio do Supabase)
        await empresaRepo.saveLocal(coreEmpresa);

        // Salvar usuário localmente
        await usuarioRepo.saveLocal(coreUsuario);

        // Salvar membro localmente
        await membroRepo.saveLocal(coreMembro);
      });

      // Buscar configuração da empresa no Supabase e salvar localmente
      await _bootstrapConfig(tenantId, configRepo, tenantContext);

      LogService.instance.info(
        LogModule.startup,
        '[Session] Bootstrap local concluído com sucesso para tenant=$tenantId',
      );
      return true;
    } catch (e, st) {
      LogService.instance.error(
        LogModule.startup,
        '[Session] Falha no bootstrap local',
        exception: e.toString(),
        stackTrace: st.toString(),
      );
      return false;
    }
  }

  Future<void> _bootstrapConfig(
    String tenantId,
    EmpresaConfiguracaoRepository configRepo,
    TenantContext tenantContext,
  ) async {
    try {
      final configRows = await _supabase
          .from('empresa_configuracao')
          .select()
          .eq('tenantId', tenantId)
          .limit(1);

      if (configRows.isNotEmpty) {
        final row = configRows.first as Map<String, dynamic>;
        final config = CoreEmpresaConfiguracao(
          id: row['id'] as String? ?? tenantId,
          tenantId: tenantId,
          taxaServico: (row['taxaServico'] as num?)?.toDouble() ?? 0.10,
          usarWhatsApp: row['usarWhatsApp'] as bool? ?? true,
          tema: row['tema'] as String? ?? 'dark',
          printerConfig: row['printerConfig'] as String?,
          pixKey: row['pixKey'] as String?,
          logoUrl: row['logoUrl'] as String?,
          printerCaixa: row['printerCaixa'] as String?,
          printerCozinha: row['printerCozinha'] as String?,
          printerBalcao: row['printerBalcao'] as String?,
          printerExpedicao: row['printerExpedicao'] as String?,
          autoPrintCaixa: row['autoPrintCaixa'] as bool? ?? true,
          autoPrintCozinha: row['autoPrintCozinha'] as bool? ?? true,
          autoPrintBalcao: row['autoPrintBalcao'] as bool? ?? false,
          autoPrintExpedicao: row['autoPrintExpedicao'] as bool? ?? false,
          viasCliente: row['viasCliente'] as int? ?? 1,
          viasCozinha: row['viasCozinha'] as int? ?? 1,
          viasBalcao: row['viasBalcao'] as int? ?? 0,
          viasExpedicao: row['viasExpedicao'] as int? ?? 0,
          larguraPapel: row['larguraPapel'] as int? ?? 80,
          cortarPapel: row['cortarPapel'] as bool? ?? true,
          abrirGaveta: row['abrirGaveta'] as bool? ?? false,
          imprimirQRCode: row['imprimirQRCode'] as bool? ?? true,
          imprimirCopiaCola: row['imprimirCopiaCola'] as bool? ?? true,
          imprimirLogo: row['imprimirLogo'] as bool? ?? false,
          imprimirRodape: row['imprimirRodape'] as bool? ?? true,
          mensagemRodape: row['mensagemRodape'] as String? ?? 'Obrigado pela preferência!',
          pixFavorecido: row['pixFavorecido'] as String?,
          pixBanco: row['pixBanco'] as String?,
          pixTipo: row['pixTipo'] as String? ?? 'CPF',
          modoDeliveryAtivo: row['modoDeliveryAtivo'] as bool? ?? true,
          modoComandasAtivo: false,
          clienteObrigatorioVenda: row['clienteObrigatorioVenda'] as bool? ?? false,
          atendimentoPadrao: row['atendimentoPadrao'] as String? ?? 'Mesa/Balcão',
          mercadoPagoAtivo: row['mercadoPagoAtivo'] as bool? ?? false,
          openPixAtivo: row['openPixAtivo'] as bool? ?? false,
          asaasAtivo: row['asaasAtivo'] as bool? ?? false,
          ifoodAtivo: row['ifoodAtivo'] as bool? ?? false,
          margemSegurancaMinutos: row['margemSegurancaMinutos'] as int? ?? 10,
          taxaEntregaPorKm: row['taxaEntregaPorKm'] as bool? ?? false,
          valorPorKmCentavos: row['valorPorKmCentavos'] as int? ?? 0,
          metadata: SyncMetadata(
            version: row['syncVersion'] as int? ?? 1,
            createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
            updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
            createdBy: row['createdBy'] as String? ?? 'system',
            updatedBy: row['updatedBy'] as String? ?? 'system',
            syncStatus: SyncStatus.synced,
          ),
        );
        await configRepo.saveLocal(config);
      }
    } catch (e) {
      // Config não crítica — apenas loga
      LogService.instance.warning(
        LogModule.startup,
        '[Session] Não foi possível carregar configuração da empresa: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MAPPERS — Supabase row → CoreModel
  // ─────────────────────────────────────────────────────────────

  CoreEmpresa _mapEmpresa(Map<String, dynamic> row) {
    final statusStr = (row['status'] as String? ?? 'ativo').toLowerCase();
    final StatusEmpresa status;
    switch (statusStr) {
      case 'suspenso':
        status = StatusEmpresa.suspenso;
      case 'bloqueado':
        status = StatusEmpresa.bloqueado;
      default:
        status = StatusEmpresa.ativo;
    }

    final planoStr = (row['plano'] as String? ?? 'bronze').toLowerCase();
    final PlanoEmpresa plano;
    switch (planoStr) {
      case 'prata':
        plano = PlanoEmpresa.prata;
      case 'ouro':
        plano = PlanoEmpresa.ouro;
      default:
        plano = PlanoEmpresa.bronze;
    }

    return CoreEmpresa(
      id: row['id'] as String,
      razaoSocial: row['razaoSocial'] as String? ?? '',
      nomeFantasia: row['nomeFantasia'] as String? ?? '',
      documentoFiscal: row['documentoFiscal'] as String? ?? '',
      email: row['email'] as String? ?? '',
      telefone: row['telefone'] as String? ?? '',
      status: status,
      plano: plano,
      timezone: row['timezone'] as String? ?? 'America/Sao_Paulo',
      locale: row['locale'] as String? ?? 'pt_BR',
      currency: row['currency'] as String? ?? 'BRL',
      country: row['country'] as String? ?? 'BR',
      createdFrom: row['createdFrom'] as String? ?? 'PDV',
      segmento: row['segmento'] as String?,
      tipoPessoa: row['tipoPessoa'] as String? ?? 'JURIDICA',
      inscricaoEstadual: row['inscricaoEstadual'] as String?,
      inscricaoMunicipal: row['inscricaoMunicipal'] as String?,
      regimeTributario: row['regimeTributario'] as String?,
      cep: row['cep'] as String?,
      logradouro: row['logradouro'] as String?,
      numero: row['numero'] as String?,
      complemento: row['complemento'] as String?,
      bairro: row['bairro'] as String?,
      cidade: row['cidade'] as String?,
      estado: row['estado'] as String?,
      version: row['syncVersion'] as int? ?? 1,
      metadata: SyncMetadata(
        version: row['syncVersion'] as int? ?? 1,
        createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
        updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
        createdBy: row['createdBy'] as String? ?? 'system',
        updatedBy: row['updatedBy'] as String? ?? 'system',
        deletedAt: _parseDate(row['deletedAt'] as String?),
        syncStatus: SyncStatus.synced,
      ),
    );
  }

  CoreUsuario _mapUsuario(
    Map<String, dynamic> row,
    String tenantId,
    String role,
  ) {
    return CoreUsuario(
      id: row['id'] as String,
      tenantId: tenantId,
      authUserId: row['authUserId'] as String?,
      username: row['username'] as String? ?? '',
      email: row['email'] as String? ?? '',
      nome: row['nome'] as String? ?? '',
      avatarUrl: row['avatarUrl'] as String?,
      ativo: row['ativo'] as bool? ?? true,
      role: role,
      criadoEm: _parseDate(row['criadoEm'] as String?) ?? DateTime.now(),
      atualizadoEm: _parseDate(row['atualizadoEm'] as String?) ?? DateTime.now(),
    );
  }

  CoreMembroEmpresa _mapMembro(Map<String, dynamic> row) {
    final empresaRow = row['empresa'] as Map<String, dynamic>?;
    final tenantId = row['tenantId'] as String? ??
        (empresaRow != null ? empresaRow['id'] as String? ?? '' : '');

    return CoreMembroEmpresa(
      id: row['id'] as String,
      tenantId: tenantId,
      usuarioId: row['usuarioId'] as String,
      role: row['role'] as String? ?? 'OPERADOR',
      ativo: row['ativo'] as bool? ?? true,
      convidadoEm: _parseDate(row['convidadoEm'] as String?) ?? DateTime.now(),
      aceitoEm: _parseDate(row['aceitoEm'] as String?),
      metadata: SyncMetadata(
        version: row['syncVersion'] as int? ?? 1,
        createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
        updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
        createdBy: row['createdBy'] as String? ?? 'system',
        updatedBy: row['updatedBy'] as String? ?? 'system',
        syncStatus: SyncStatus.synced,
      ),
    );
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
