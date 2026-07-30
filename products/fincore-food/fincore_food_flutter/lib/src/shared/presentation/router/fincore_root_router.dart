import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_food_flutter/main.dart';
import '../auth/login_page.dart';
import '../auth/services/session_initialization_service.dart';
import '../onboarding/workspace_setup_page.dart';
import '../onboarding/onboarding_wizard_page.dart';
import '../onboarding/pending_approval_page.dart';
import '../shell/fincore_shell.dart';
import '../admin/empresas_pendentes_page.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/usuario_repository.dart';
import 'package:fincore_core/repository/empresa_repository.dart';
import 'package:fincore_core/context/tenant_context.dart';

class FincoreRootRouter extends StatefulWidget {
  const FincoreRootRouter({super.key});

  @override
  State<FincoreRootRouter> createState() => _FincoreRootRouterState();
}

class _FincoreRootRouterState extends State<FincoreRootRouter> {
  bool _isLoading = true;
  User? _currentUser;
  AuthUserInfo? _authUserInfo;
  String? _onboardingStatus;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    try {
      _currentUser = Supabase.instance.client.auth.currentUser;
      _listenToAuthChanges();
      if (_currentUser != null) {
        _fetchSessionInfo();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, st) {
      LogService.instance.error(
        LogModule.app,
        'Erro na inicialização do router de navegação',
        exception: e.toString(),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        setState(() {
          _currentUser = data.session?.user;
          _isLoading = true;
        });
        _fetchSessionInfo();
      } else if (event == AuthChangeEvent.signedOut) {
        _syncTimer?.cancel();
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
    CoreUsuario? localUser;
    List<CoreEmpresa> empresas = [];

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      await client.authenticationKeyManager?.put(token);

      final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
      final empresaRepo = DependencyInjection().get<EmpresaRepository>();
      
      final usuarios = await usuarioRepo.findAll();
      empresas = await empresaRepo.findAll();
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      localUser = usuarios.where((u) => u.id == currentUserId).firstOrNull;
      
      if (localUser != null && empresas.isNotEmpty) {
        DependencyInjection().get<TenantContext>().setContext(
          empresa: empresas.first,
          usuario: localUser,
        );

        setState(() {
          _authUserInfo = AuthUserInfo(
            usuarioId: localUser!.id,
            email: localUser.email,
            role: 'owner',
            tenantId: empresas.first.id,
          );
          _isLoading = false;
        });

        _backgroundSync(token);
        return;
      }

      final userInfo = await client.auth.login();
      
      String? onboardingStatus;
      if (userInfo != null) {
        onboardingStatus = await client.onboarding.status();
        
        final sessionSvc = SessionInitializationService(client);
        await sessionSvc.initializeSession(userInfo);
      } else {
        await Supabase.instance.client.auth.signOut();
      }

      setState(() {
        _authUserInfo = userInfo;
        _onboardingStatus = onboardingStatus;
        _isLoading = false;
      });
    } catch (e) {
      LogService.instance.warning(
        LogModule.api,
        'Servidor backend local indisponível — operando com sessão local e banco SQLite',
      );
      final currentSupabaseUser = Supabase.instance.client.auth.currentUser;
      if (currentSupabaseUser != null && localUser != null && empresas.isNotEmpty) {
        setState(() {
          _authUserInfo = AuthUserInfo(
            usuarioId: localUser!.id,
            email: localUser!.email,
            role: 'owner',
            tenantId: empresas.first.id,
          );
          _isLoading = false;
        });
      } else {
        final isNetworkError = e is SocketException ||
            e.toString().contains('SocketException') ||
            e.toString().contains('recusou') ||
            e.toString().contains('1225');
        if (!isNetworkError) {
          try {
            await Supabase.instance.client.auth.signOut();
          } catch (_) {}
          setState(() {
            _authUserInfo = null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _backgroundSync(String token) async {
    try {
      final userInfo = await client.auth.login();
      if (userInfo != null) {
        final status = await client.onboarding.status();
        setState(() {
          _authUserInfo = userInfo;
          _onboardingStatus = status;
        });

        final syncEngine = DependencyInjection().get<SyncEngine>();
        final db = DependencyInjection().get<FincoreDatabase>();
        SupabaseSyncService? supabaseSyncService;
        try {
          supabaseSyncService = DependencyInjection().get<SupabaseSyncService>();
        } catch (_) {}

        LogService.instance.info(
          LogModule.sync,
          'Sincronização em segundo plano iniciada para tenant [${userInfo.tenantId}]',
        );

        // ── PASSO 1: PUSH ─────────────────────────────────────────────────────
        final result = await syncEngine.processPendingQueue();

        // ── PASSO 2: PULL (somente se o Outbox estiver limpo) ─────────────────
        if (result.hasPendingAfter) {
          LogService.instance.warning(
            LogModule.sync,
            'Modo de sincronização degradado: ${result.failureCount} falha(s) pendente(s) na fila. Recebimento suspenso.',
          );
          _syncTimer?.cancel();
          _syncTimer = Timer(const Duration(seconds: 30), () {
            _retryDegradedSync(userInfo, supabaseSyncService);
          });
          return;
        }

        // ── PASSO 3: PULL ─────────────────────────────────────────────────────
        if (supabaseSyncService != null) {
          final prefs = await SharedPreferences.getInstance();
          final lastSyncStr = prefs.getString('last_pull_sync_${userInfo.tenantId}');
          final isFirstSync = lastSyncStr == null;
          final lastSyncAt = lastSyncStr != null
              ? DateTime.parse(lastSyncStr)
              : DateTime.now().subtract(const Duration(days: 30));

          LogService.instance.info(
            LogModule.sync,
            '[Router] 3. Outbox limpo! Executando ${isFirstSync ? "FULL PULL (Carga Inicial)" : "INCREMENTAL PULL"}...',
          );

          final success = await supabaseSyncService.pullAll(db, lastSyncAt);

          if (success) {
            await prefs.setString(
              'last_pull_sync_${userInfo.tenantId}',
              DateTime.now().toUtc().toIso8601String(),
            );
          }

          // ── PASSO 4: REALTIME ─────────────────────────────────────────────────
          LogService.instance.info(
            LogModule.sync,
            '[Router] 4. PULL concluído! Ativando Realtime WebSocket e Polling de 60s...',
          );
          supabaseSyncService.startRealtimeListeners(db);
        }

        // ── PASSO 5: POLLING PERIÓDICO (60s) ─────────────────────────────────
        _syncTimer?.cancel();
        _syncTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
          final prefs = await SharedPreferences.getInstance();
          // Push primeiro, sempre
          final periodicResult = await syncEngine.processPendingQueue();

          if (!periodicResult.hasPendingAfter && supabaseSyncService != null) {
            // Pull somente se o outbox estiver limpo
            final last = prefs.getString('last_pull_sync_${userInfo.tenantId}');
            final dt = last != null
                ? DateTime.parse(last)
                : DateTime.now().subtract(const Duration(minutes: 1));
            final success = await supabaseSyncService.pullAll(db, dt);
            if (success) {
              await prefs.setString(
                'last_pull_sync_${userInfo.tenantId}',
                DateTime.now().toUtc().toIso8601String(),
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[Router] Sync em background falhou: $e');
    }
  }

  /// Tentativa de recuperação automática do Modo Degradado.
  /// Chamado 30 segundos após um ciclo de PUSH que deixou o outbox sujo.
  Future<void> _retryDegradedSync(
    AuthUserInfo userInfo,
    SupabaseSyncService? supabaseSyncService,
  ) async {
    try {
      final syncEngine = DependencyInjection().get<SyncEngine>();
      final db = DependencyInjection().get<FincoreDatabase>();

      LogService.instance.info(
        LogModule.sync,
        '[Router] 🔄 Tentando recuperar do Modo Degradado...',
      );

      final result = await syncEngine.processPendingQueue();

      if (!result.hasPendingAfter && supabaseSyncService != null) {
        // Recuperou! Executa o PULL e volta ao modo normal.
        final prefs = await SharedPreferences.getInstance();
        final lastSyncStr = prefs.getString('last_pull_sync_${userInfo.tenantId}');
        final lastSyncAt = lastSyncStr != null
            ? DateTime.parse(lastSyncStr)
            : DateTime.now().subtract(const Duration(days: 7));

        final success = await supabaseSyncService.pullAll(db, lastSyncAt);

        if (success) {
          await prefs.setString(
            'last_pull_sync_${userInfo.tenantId}',
            DateTime.now().toUtc().toIso8601String(),
          );
        }

        LogService.instance.info(
          LogModule.sync,
          '[Router] ✅ Modo Degradado resolvido. Sistema retornou ao modo normal.',
        );

        // Retoma o polling normal de 60s
        _syncTimer?.cancel();
        _syncTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
          final prefs = await SharedPreferences.getInstance();
          final periodicResult = await syncEngine.processPendingQueue();
          if (!periodicResult.hasPendingAfter) {
            final last = prefs.getString('last_pull_sync_${userInfo.tenantId}');
            final dt = last != null
                ? DateTime.parse(last)
                : DateTime.now().subtract(const Duration(minutes: 1));
            final success = await supabaseSyncService.pullAll(db, dt);
            if (success) {
              await prefs.setString(
                'last_pull_sync_${userInfo.tenantId}',
                DateTime.now().toUtc().toIso8601String(),
              );
            }
          }
        });
      } else {
        // Ainda degradado — tenta novamente em 60s
        LogService.instance.warning(
          LogModule.sync,
          '[Router] ⚠️ Modo Degradado persiste. Nova tentativa em 60s.',
        );
        _syncTimer?.cancel();
        _syncTimer = Timer(const Duration(seconds: 60), () {
          _retryDegradedSync(userInfo, supabaseSyncService);
        });
      }
    } catch (e) {
      debugPrint('[Router] Falha na recuperação do Modo Degradado: $e');
    }
  }

  void refreshState() {
    setState(() {
      _onboardingStatus = null;
      _isLoading = true;
    });
    _fetchSessionInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return LoginPage(onLoginSuccess: refreshState);
    }

    if (_authUserInfo?.role == 'superadmin') {
      return EmpresasPendentesPage(
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          refreshState();
        },
      );
    }

    if (_authUserInfo == null || _authUserInfo!.tenantId == null) {
      return OnboardingWizardPage(onCreated: refreshState);
    }

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

    // Bypass WorkspaceSetupPage directly to the system
    return const FincoreShell();
  }
}
