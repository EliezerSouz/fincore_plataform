import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_food_flutter/src/shared/presentation/auth/models/auth_user_info.dart';
import 'package:fincore_food_flutter/src/shared/presentation/auth/services/supabase_session_service.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_wizard_page.dart';
import '../onboarding/pending_approval_page.dart';
import '../shell/fincore_shell.dart';
import '../admin/empresas_pendentes_page.dart';
import '../tenant/empresa_selector_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTA ARQUITETURAL — FincoreRootRouter (Arquitetura Local-First)
//
// O Serverpod Client foi completamente eliminado desta versão.
// Toda a lógica de sessão, bootstrap e onboarding agora é feita via:
//   - Supabase Auth (login/logout)
//   - SupabaseSessionService (bootstrap, status de onboarding)
//   - Drift SQLite local (cache de dados)
//
// Fluxo de inicialização:
//   1. Supabase Auth verifica sessão ativa
//   2. SupabaseSessionService → busca empresa/usuário no Supabase
//   3. Popula SQLite local se necessário (bootstrap)
//   4. Configura TenantContext
//   5. Inicia SyncEngine (push/pull automático)
// ─────────────────────────────────────────────────────────────────────────────

class FincoreRootRouter extends StatefulWidget {
  const FincoreRootRouter({super.key});

  @override
  State<FincoreRootRouter> createState() => _FincoreRootRouterState();
}

class _FincoreRootRouterState extends State<FincoreRootRouter>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  User? _currentUser;
  AuthUserInfo? _authUserInfo;
  String? _onboardingStatus;

  /// Lista de empresas disponíveis quando o usuário tem N>1 empresas vinculadas.
  List<Map<String, dynamic>>? _empresasDisponiveis;
  String? _syncStatusMessage;

  StreamSubscription<AuthState>? _authSubscription;
  late final AnimationController _pulseController;

  late final SupabaseSessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sessionService = SupabaseSessionService(
      supabase: Supabase.instance.client,
    );

    try {
      _currentUser = Supabase.instance.client.auth.currentUser;
      _listenToAuthChanges();
      _fetchSessionInfo();
    } catch (e) {
      LogService.instance.error(
        LogModule.app,
        'Erro na inicialização do router de navegação',
        exception: e.toString(),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _listenToAuthChanges() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (!mounted) return;

      if (event == AuthChangeEvent.signedIn) {
        setState(() {
          _currentUser = data.session?.user;
          _isLoading = true;
        });
        _fetchSessionInfo();
      } else if (event == AuthChangeEvent.signedOut) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('fincore_offline_usuario_id');
        });
        setState(() {
          _currentUser = null;
          _authUserInfo = null;
          _onboardingStatus = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchSessionInfo() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      // ── MODO OFFLINE: sem token Supabase ─────────────────────────────────
      if (session == null) {
        await _tryOfflineSession();
        return;
      }

      // ── ONLINE: inicializar sessão via Supabase ───────────────────────────
      final result = await _sessionService.initializeSession();

      // Múltiplas empresas → seleção
      if (result.multiEmpresas != null && result.multiEmpresas!.length > 1) {
        if (mounted) {
          setState(() {
            _empresasDisponiveis = result.multiEmpresas;
            _isLoading = false;
          });
        }
        return;
      }

      // Sem empresa → Onboarding
      if (result.authInfo == null) {
        if (mounted) {
          setState(() {
            _authUserInfo = null;
            _isLoading = false;
          });
        }
        return;
      }

      // Sessão completa → verificar se é primeira sincronização (Carga Inicial)
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_pull_sync_${result.authInfo!.tenantId}');
      final db = DependencyInjection().get<FincoreDatabase>();
      final currentTenantId = result.authInfo!.tenantId ?? '';
      final localPedidos = await (db.select(db.pedidosTable)
            ..where((t) => t.tenantId.equals(currentTenantId) & t.deletedAt.isNull()))
          .get();
      final produtoRepo = DependencyInjection().get<ProdutoRepository>();
      final localProdutos = await produtoRepo.findAll();

      final isFirstSync = lastSyncStr == null || localProdutos.isEmpty || localPedidos.isEmpty;

      if (isFirstSync && mounted) {
        setState(() {
          _authUserInfo = result.authInfo;
          _onboardingStatus = result.onboardingStatus;
          _syncStatusMessage = 'Realizando carga inicial do sistema...\nSincronizando produtos, clientes e histórico de pedidos.';
          _isLoading = true;
        });
        await _startBackgroundSync(result.authInfo!);
        try {
          final outbox = DependencyInjection().get<OutboxService>();
          final syncEngine = DependencyInjection().get<SyncEngine>();
          await outbox.retryFailedEntries();
          await syncEngine.processPendingQueue();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _syncStatusMessage = null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _authUserInfo = result.authInfo;
            _onboardingStatus = result.onboardingStatus;
            _isLoading = false;
          });
        }
        _startBackgroundSync(result.authInfo!);
      }
    } catch (e, st) {
      LogService.instance.warning(
        LogModule.api,
        'Falha na inicialização de sessão — tentando modo offline. Erro: $e\n$st',
      );
      // Tentar offline como fallback
      await _tryOfflineSession();
    }
  }

  /// Tenta inicializar a sessão usando apenas dados locais SQLite (sem rede).
  Future<void> _tryOfflineSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineUsuarioId = prefs.getString('fincore_offline_usuario_id');

      if (offlineUsuarioId != null) {
        final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
        final empresaRepo = DependencyInjection().get<EmpresaRepository>();
        final membroRepo = DependencyInjection().get<MembroEmpresaRepository>();

        final usuarios = await usuarioRepo.findAll();
        final empresas = await empresaRepo.findAll();

        final localUser =
            usuarios.where((u) => u.id == offlineUsuarioId).firstOrNull;
        if (localUser != null && empresas.isNotEmpty) {
          CoreEmpresa? userEmpresa;
          String? userRole;

          if (localUser.tenantId != null && localUser.tenantId!.isNotEmpty) {
            userEmpresa =
                empresas.where((e) => e.id == localUser.tenantId).firstOrNull;
          }

          if (userEmpresa == null) {
            final membros = await membroRepo.findByUsuarioGlobal(localUser.id);
            if (membros.isNotEmpty) {
              final membro = membros.first;
              userEmpresa =
                  empresas.where((e) => e.id == membro.tenantId).firstOrNull;
              userRole = membro.role;
            }
          }

          userEmpresa ??= empresas.firstWhere(
            (e) => e.nomeFantasia != 'FINCORE Food Demo',
            orElse: () => empresas.first,
          );

          final membrosDesteUser =
              await membroRepo.findByUsuarioGlobal(localUser.id);
          final membroDesteTenant = membrosDesteUser
              .where((m) => m.tenantId == userEmpresa!.id)
              .firstOrNull;
          if (membroDesteTenant != null) {
            userRole = membroDesteTenant.role;
          }

          final usuarioComRole =
              localUser.copyWith(role: userRole ?? localUser.role ?? 'OPERADOR');

          DependencyInjection().get<TenantContext>().setContext(
                empresa: userEmpresa,
                usuario: usuarioComRole,
              );

          // Iniciar auto-sync do SyncEngine (30s)
          final syncEngine = DependencyInjection().get<SyncEngine>();
          syncEngine.startAutoSync(interval: const Duration(seconds: 30));

          if (mounted) {
            setState(() {
              _authUserInfo = AuthUserInfo(
                usuarioId: localUser!.id,
                email: localUser.email ?? '',
                role: userRole ?? localUser.role ?? 'OPERADOR',
                tenantId: userEmpresa!.id,
              );
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[Router] Falha no modo offline: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startBackgroundSync(AuthUserInfo authInfo) async {
    try {
      final syncEngine = DependencyInjection().get<SyncEngine>();
      final db = DependencyInjection().get<FincoreDatabase>();
      SupabaseSyncService? supabaseSyncService;
      try {
        supabaseSyncService = DependencyInjection().get<SupabaseSyncService>();
      } catch (_) {}

      LogService.instance.info(
        LogModule.sync,
        'Sincronização em segundo plano iniciada para tenant [${authInfo.tenantId}]',
      );

      // Salvar ID do usuário para modo offline futuro
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'fincore_offline_usuario_id', authInfo.usuarioId);

      // ── PASSO 1: PUSH ──────────────────────────────────────────────────────
      final result = await syncEngine.processPendingQueue();

      if (result.failureCount > 0) {
        LogService.instance.warning(
          LogModule.sync,
          '[AVISO] ${result.failureCount} item(ns) com falha no Outbox. PUSH continuará tentando em background.',
        );
      }

      // ── PASSO 2: PULL RESILIENTE (Com Proteção Granular do Escudo por ID) ──
      if (supabaseSyncService != null) {
        final lastSyncStr =
            prefs.getString('last_pull_sync_${authInfo.tenantId}');

        final produtoRepo = DependencyInjection().get<ProdutoRepository>();
        final localProdutos = await produtoRepo.findAll();

        final currentTenantId = authInfo.tenantId ?? '';
        final localPedidos = await (db.select(db.pedidosTable)
              ..where((t) => t.tenantId.equals(currentTenantId) & t.deletedAt.isNull()))
            .get();

        final isFirstSync = lastSyncStr == null || localProdutos.isEmpty || localPedidos.isEmpty;
        final lastSyncAt = isFirstSync
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(lastSyncStr).subtract(const Duration(seconds: 10));

        LogService.instance.info(
          LogModule.sync,
          '[Router] Executando ${isFirstSync ? "FULL PULL (Carga Inicial)" : "INCREMENTAL PULL"}...',
        );

        final success = await supabaseSyncService.pullAll(db, lastSyncAt);
        if (success) {
          await prefs.setString(
            'last_pull_sync_${authInfo.tenantId}',
            DateTime.now().toUtc().toIso8601String(),
          );
        }

        // PUSH de pós-pull para flushing de qualquer pendência residual
        await syncEngine.processPendingQueue();
      }

      // ── PASSO 3: REALTIME + POLLING ────────────────────────────────────────
      if (supabaseSyncService != null) {
        LogService.instance.info(
          LogModule.sync,
          '[Router] Ativando Realtime WebSocket e Polling contínuo de 60s...',
        );
        supabaseSyncService.startRealtimeListeners(db);
      }

      // Iniciar auto-sync do SyncEngine (30s)
      syncEngine.startAutoSync(interval: const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[Router] Sync em background falhou: $e');
    }
  }

  void refreshState() {
    if (mounted) {
      setState(() {
        _onboardingStatus = null;
        _isLoading = true;
      });
      _fetchSessionInfo();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0F2E),
              Color(0xFF0D1340),
              Color(0xFF111827),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: 80, left: 60, child: _buildDot(5)),
            Positioned(top: 140, left: 160, child: _buildDot(3)),
            Positioned(top: 220, right: 80, child: _buildDot(4)),
            Positioned(bottom: 200, left: 40, child: _buildDot(6)),
            Positioned(bottom: 120, right: 120, child: _buildDot(3)),
            Positioned(top: 400, left: 100, child: _buildDot(4)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.04);
                      final opacity = 0.6 + (_pulseController.value * 0.4);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: FincoreColors.primary
                                    .withValues(alpha: 0.25 * _pulseController.value),
                                blurRadius: 35,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: opacity,
                            child: Image.asset(
                              'assets/images/app_launcher_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'FINCORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        FincoreColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'FOOD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 220,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            FincoreColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _syncStatusMessage ?? 'Iniciando sistema...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentUser == null && _authUserInfo == null) {
      return LoginPage(onLoginSuccess: refreshState);
    }

    // SUPERADMIN → painel de empresas pendentes
    if (_authUserInfo?.role?.toUpperCase() == 'SUPERADMIN') {
      return EmpresasPendentesPage(
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          refreshState();
        },
      );
    }

    // Múltiplas empresas → seleção
    if (_empresasDisponiveis != null && _empresasDisponiveis!.isNotEmpty && _authUserInfo == null) {
      return _buildEmpresaSelector();
    }

    // Sem empresa vinculada → Onboarding
    if (_authUserInfo == null || _authUserInfo!.tenantId == null) {
      return OnboardingWizardPage(onCreated: refreshState);
    }

    // Empresa pendente de ativação
    if (_onboardingStatus == 'PENDENTE_ATIVACAO') {
      return PendingApprovalPage(
        tenantId: _authUserInfo!.tenantId!,
        onApproved: refreshState,
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          refreshState();
        },
      );
    }

    // Sistema ativo → Shell principal com suporte a Logout limpo
    return FincoreShell(
      onLogout: () async {
        await Supabase.instance.client.auth.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fincore_offline_usuario_id');
        if (mounted) {
          setState(() {
            _currentUser = null;
            _authUserInfo = null;
            _empresasDisponiveis = null;
            _onboardingStatus = null;
            _isLoading = false;
          });
        }
      },
    );
  }

  /// Selector de empresa quando usuário tem múltiplas empresas.
  Widget _buildEmpresaSelector() {
    return EmpresaSelectorPage(
      empresas: _empresasDisponiveis ?? const [],
      onEmpresaSelecionada: refreshState,
    );
  }
}
