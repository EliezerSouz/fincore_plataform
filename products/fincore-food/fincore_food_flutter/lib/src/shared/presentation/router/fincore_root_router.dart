import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_food_flutter/main.dart';
import '../auth/login_page.dart';
import '../auth/services/session_initialization_service.dart';
import '../onboarding/onboarding_wizard_page.dart';
import '../onboarding/pending_approval_page.dart';
import '../shell/fincore_shell.dart';
import '../admin/empresas_pendentes_page.dart';

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
  Timer? _syncTimer;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isServerOffline = false;
  Timer? _connectionCheckTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    _connectionCheckTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (!mounted) return;
      if (event == AuthChangeEvent.signedIn) {
        setState(() {
          _currentUser = data.session?.user;
          _isLoading = true;
        });
        _fetchSessionInfo();
      } else if (event == AuthChangeEvent.signedOut) {
        _syncTimer?.cancel();
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
    // ── GUARD: Se a base local não possui dados de uma empresa real (ex: apenas demo ou vazia),
    // precisamos ativamente validar se o servidor backend está online antes de continuar.
    try {
      final empresaRepo = DependencyInjection().get<EmpresaRepository>();
      final localCompanies = await empresaRepo.findAll();
      final hasRealCompany = localCompanies.any((e) => e.nomeFantasia != 'FINCORE Food Demo');

      if (!hasRealCompany) {
        bool serverAvailable = false;
        try {
          // Chamada simples sem autenticação
          await client.greeting.hello("ping");
          serverAvailable = true;
        } catch (_) {}

        if (!serverAvailable) {
          if (mounted) {
            setState(() {
              _isServerOffline = true;
              _isLoading = false;
            });
          }
          _startConnectionChecking();
          return;
        }
      }
    } catch (e) {
      debugPrint('[Router] Falha ao verificar empresas locais para guarda de servidor: $e');
    }

    CoreUsuario? localUser;
    List<CoreEmpresa> empresas = [];
    List<CoreUsuario> usuarios = [];
    late final MembroEmpresaRepository membroRepo;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        final offlineUsuarioId = prefs.getString('fincore_offline_usuario_id');
        if (offlineUsuarioId != null) {
          final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
          final empresaRepo = DependencyInjection().get<EmpresaRepository>();
          membroRepo = DependencyInjection().get<MembroEmpresaRepository>();

          usuarios = await usuarioRepo.findAll();
          empresas = await empresaRepo.findAll();

          localUser = usuarios.where((u) => u.id == offlineUsuarioId).firstOrNull;
          if (localUser != null && empresas.isNotEmpty) {
            CoreEmpresa? userEmpresa;
            String? userRole;

            if (localUser.tenantId != null && localUser.tenantId!.isNotEmpty) {
              userEmpresa = empresas.where((e) => e.id == localUser!.tenantId).firstOrNull;
            }

            if (userEmpresa == null) {
              final membros = await membroRepo.findByUsuarioGlobal(localUser.id);
              if (membros.isNotEmpty) {
                final membro = membros.first;
                final targetTenantId = membro.tenantId;
                userEmpresa = empresas.where((e) => e.id == targetTenantId).firstOrNull;
                userRole = membro.role;
              }
            }

            userEmpresa ??= empresas.firstWhere(
              (e) => e.nomeFantasia != 'FINCORE Food Demo',
              orElse: () => empresas.first,
            );

            final membrosDesteUser = await membroRepo.findByUsuarioGlobal(localUser.id);
            final membroDesteTenant = membrosDesteUser.where((m) => m.tenantId == userEmpresa!.id).firstOrNull;
            if (membroDesteTenant != null) {
              userRole = membroDesteTenant.role;
            }

            final usuarioComRole = localUser.copyWith(role: userRole ?? localUser.role ?? 'OPERADOR');

            DependencyInjection().get<TenantContext>().setContext(
              empresa: userEmpresa,
              usuario: usuarioComRole,
            );

            final syncEngine = DependencyInjection().get<SyncEngine>();
            syncEngine.startAutoSync(interval: const Duration(seconds: 30));
            syncEngine.processPendingQueue().catchError((_) => const SyncResult(successCount: 0, failureCount: 0, hasPendingAfter: true));

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

        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await client.authenticationKeyManager?.put(token);

      final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
      final empresaRepo = DependencyInjection().get<EmpresaRepository>();
      membroRepo = DependencyInjection().get<MembroEmpresaRepository>();
      
      usuarios = await usuarioRepo.findAll();
      empresas = await empresaRepo.findAll();
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      localUser = usuarios.where((u) => u.id == currentUserId || u.authUserId == currentUserId).firstOrNull;
      
      final user = localUser;
      if (user != null && empresas.isNotEmpty) {
        // Busca a empresa real vinculada ao usuário pelo tenantId ou tabela de membros
        CoreEmpresa? userEmpresa;
        String? userRole;

        if (user.tenantId != null && user.tenantId!.isNotEmpty) {
          userEmpresa = empresas.where((e) => e.id == user.tenantId).firstOrNull;
        }
        
        if (userEmpresa == null) {
          final membros = await membroRepo.findByUsuarioGlobal(user.id);
          if (membros.isNotEmpty) {
            final membro = membros.first;
            final targetTenantId = membro.tenantId;
            userEmpresa = empresas.where((e) => e.id == targetTenantId).firstOrNull;
            userRole = membro.role;
          }
        }

        userEmpresa ??= empresas.firstWhere(
          (e) => e.nomeFantasia != 'FINCORE Food Demo',
          orElse: () => empresas.first,
        );

        // Busca a role específica deste usuário no tenant ativo na tabela de membros
        final membrosDesteUser = await membroRepo.findByUsuarioGlobal(user.id);
        final membroDesteTenant = membrosDesteUser.where((m) => m.tenantId == userEmpresa!.id).firstOrNull;
        if (membroDesteTenant != null) {
          userRole = membroDesteTenant.role;
        }

        final usuarioComRole = user.copyWith(role: userRole ?? user.role ?? 'OPERADOR');

        if (userEmpresa.nomeFantasia != 'FINCORE Food Demo') {
          DependencyInjection().get<TenantContext>().setContext(
            empresa: userEmpresa,
            usuario: usuarioComRole,
          );

          if (mounted) {
            setState(() {
              _authUserInfo = AuthUserInfo(
                usuarioId: user.id,
                email: user.email ?? '',
                // Usa role real do banco; fallback para 'ADMIN' apenas se o usuário
                // já tem empresa vinculada mas sem membro (situação de dev).
                role: userRole ?? user.role ?? 'ADMIN',
                tenantId: userEmpresa!.id,
              );
              _isLoading = false;
            });
          }

          _backgroundSync(token);
          return;
        }
      }

      final userInfo = await client.auth.login();
      
      String? onboardingStatus;
      bool bootstrapSuccess = false;
      if (userInfo != null) {
        onboardingStatus = await client.onboarding.status();
        
        final sessionSvc = SessionInitializationService(client);
        bootstrapSuccess = await sessionSvc.initializeSession(userInfo);
      } else {
        await Supabase.instance.client.auth.signOut();
      }

      if (mounted) {
        setState(() {
          _authUserInfo = userInfo;
          _onboardingStatus = onboardingStatus;
          _isLoading = false;
        });
      }

      if (bootstrapSuccess) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          _backgroundSync(token);
        }
      }
    } catch (e, st) {
      LogService.instance.warning(
        LogModule.api,
        'Servidor backend local indisponível ou com falha de JWT — operando com sessão local e banco SQLite. Erro: $e\n$st',
      );

      // Se der erro ao tentar inicializar sessão (ex: servidor offline) e a base SQLite local
      // NÃO possuir nenhuma empresa real, bloqueamos na tela de aguardar o servidor iniciar.
      final hasRealCompany = empresas.any((e) => e.nomeFantasia != 'FINCORE Food Demo');
      if (!hasRealCompany) {
        if (mounted) {
          setState(() {
            _isServerOffline = true;
            _isLoading = false;
          });
        }
        _startConnectionChecking();
        return;
      }

      final currentSupabaseUser = Supabase.instance.client.auth.currentUser;
      final u = localUser ?? (currentSupabaseUser != null ? usuarios.where((usr) => usr.authUserId == currentSupabaseUser.id || usr.email?.toLowerCase() == currentSupabaseUser.email?.toLowerCase()).firstOrNull : null);
      
      if (currentSupabaseUser != null && u != null && empresas.isNotEmpty) {
        // Busca a empresa real vinculada ao usuário local
        CoreEmpresa? userEmpresa;
        String? userRole;

        if (u.tenantId != null && u.tenantId!.isNotEmpty) {
          userEmpresa = empresas.where((e) => e.id == u.tenantId).firstOrNull;
        }
        
        final membrosDesteUser = await membroRepo.findByUsuarioGlobal(u.id);
        if (userEmpresa == null) {
          if (membrosDesteUser.isNotEmpty) {
            final membro = membrosDesteUser.first;
            userEmpresa = empresas.where((e) => e.id == membro.tenantId).firstOrNull;
            userRole = membro.role;
          }
        }

        userEmpresa ??= empresas.firstWhere(
          (e) => e.nomeFantasia != 'FINCORE Food Demo',
          orElse: () => empresas.first,
        );

        final membroDesteTenant = membrosDesteUser.where((m) => m.tenantId == userEmpresa!.id).firstOrNull;
        if (membroDesteTenant != null) {
          userRole = membroDesteTenant.role;
        }

        DependencyInjection().get<TenantContext>().setContext(
          empresa: userEmpresa,
          usuario: u.copyWith(role: userRole ?? u.role ?? 'OPERADOR'),
        );

        final syncEngine = DependencyInjection().get<SyncEngine>();
        syncEngine.startAutoSync(interval: const Duration(seconds: 30));
        syncEngine.processPendingQueue().catchError((_) => const SyncResult(successCount: 0, failureCount: 0, hasPendingAfter: true));

        if (mounted) {
          setState(() {
            _authUserInfo = AuthUserInfo(
              usuarioId: u.id,
              email: u.email ?? '',
              role: userRole ?? u.role ?? 'OPERADOR',
              tenantId: userEmpresa!.id,
            );
            _isLoading = false;
          });
        }
      } else {
        // Se a falha for apenas de rede (ex: servidor desligado), mantem o loading false
        // Se for erro de credenciais Supabase expirada/assinatura inválida, limpa a sessao
        final isNetworkOrConfigError = e is SocketException ||
            e.toString().contains('SocketException') ||
            e.toString().contains('recusou') ||
            e.toString().contains('1225') ||
            e.toString().contains('SUPABASE_ANON_KEY') ||
            e.toString().contains('JWT');
            
        if (!isNetworkOrConfigError) {
          try {
            await Supabase.instance.client.auth.signOut();
          } catch (_) {}
          if (mounted) {
            setState(() {
              _authUserInfo = null;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  Future<void> _backgroundSync(String token) async {
    try {
      final userInfo = await client.auth.login();
      if (userInfo != null) {
        final empresaRepo = DependencyInjection().get<EmpresaRepository>();
        final empresas = await empresaRepo.findAll();
        final realEmpresa = empresas.where((e) => e.nomeFantasia != 'FINCORE Food Demo').firstOrNull;
        final effectiveTenantId = realEmpresa?.id ?? userInfo.tenantId;

        if (realEmpresa != null) {
          final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
          final u = (await usuarioRepo.findAll()).firstOrNull;
          if (u != null) {
            final membroRepo = DependencyInjection().get<MembroEmpresaRepository>();
            final membros = await membroRepo.findByUsuarioGlobal(u.id);
            final membroDesteTenant = membros.where((m) => m.tenantId == realEmpresa.id).firstOrNull;
            final uComRole = u.copyWith(role: membroDesteTenant?.role ?? u.role ?? 'OPERADOR');

            DependencyInjection().get<TenantContext>().setContext(
              empresa: realEmpresa,
              usuario: uComRole,
            );
          }
        }

        final status = await client.onboarding.status();
        if (mounted) {
          setState(() {
            _authUserInfo = AuthUserInfo(
              usuarioId: userInfo.usuarioId,
              email: userInfo.email,
              role: userInfo.role,
              tenantId: effectiveTenantId,
            );
            _onboardingStatus = status;
          });
        }

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

        if (result.failureCount > 0) {
          LogService.instance.warning(
            LogModule.sync,
            '[AVISO] ${result.failureCount} item(ns) isolado(s) com falha no Outbox. PUSH continuará tentando em background enquanto o PULL protege apenas as linhas afetadas.',
          );
        }

        // ── PASSO 2: PULL RESILIENTE ─────────────────────────────────────────
        // P1-01: GUARDRAIL — O Pull só é executado se o Outbox estiver limpo.
        // Se hasPendingAfter = true, há mutações locais não enviadas que seriam
        // sobrescritas pelo Pull. O ConflictResolver protege por ID, mas essa
        // camada garante a regra de ouro do sistema: PUSH antes de PULL.
        if (supabaseSyncService != null && !result.hasPendingAfter) {
          final prefs = await SharedPreferences.getInstance();
          final lastSyncStr = prefs.getString('last_pull_sync_${userInfo.tenantId}');
          
          final produtoRepo = DependencyInjection().get<ProdutoRepository>();
          final localProdutos = await produtoRepo.findAll();
          
          final isFirstSync = lastSyncStr == null || localProdutos.isEmpty;
          final lastSyncAt = isFirstSync
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : DateTime.parse(lastSyncStr);

          LogService.instance.info(
            LogModule.sync,
            '[Router] Executando ${isFirstSync ? "FULL PULL (Carga Inicial)" : "INCREMENTAL PULL"} com Escudo de Proteção por ID...',
          );

          final success = await supabaseSyncService.pullAll(db, lastSyncAt);

          if (success) {
            await prefs.setString(
              'last_pull_sync_${userInfo.tenantId}',
              DateTime.now().toUtc().toIso8601String(),
            );
          }
        } else if (result.hasPendingAfter) {
          LogService.instance.warning(
            LogModule.sync,
            '[Router] PULL suspenso — Outbox ainda possui pendências após o PUSH. Aguardando próximo ciclo automático.',
          );
        }

        // ── PASSO 3: REALTIME LISTENERS + POLLING INTERNO (60s) ──────────────
        // P2-01: O startRealtimeListeners() já cria seu próprio Timer.periodic interno.
        // O Router NÃO deve criar um segundo timer — isso causaria duplicidade de PULL.
        if (supabaseSyncService != null) {
          LogService.instance.info(
            LogModule.sync,
            '[Router] Ativando Realtime WebSocket e Polling contínuo de 60s (gerenciado pelo SupabaseSyncService)...',
          );
          supabaseSyncService.startRealtimeListeners(db);
          // ⚠️  Polling periódico NÃO criado aqui — delegado ao startRealtimeListeners()
        }
      }
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

  void _startConnectionChecking() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        await client.greeting.hello("ping");
        // Servidor voltou a responder!
        timer.cancel();
        if (mounted) {
          setState(() {
            _isServerOffline = false;
            _isLoading = true;
          });
          _fetchSessionInfo();
        }
      } catch (_) {
        // Continua tentando
      }
    });
  }

  Widget _buildOfflineConnectingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Sidebar background dark exato
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
            // Bolinhas decorativas de fundo para consistência estética com o login
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
                  // Logo oficial pulsante sem plano de fundo (transparente e unificado)
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
                                color: FincoreColors.primary.withValues(alpha: 0.25 * _pulseController.value),
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
                  
                  // Loader linear elegante e moderno
                  SizedBox(
                    width: 220,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(FincoreColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Textos de status informativos
                  Text(
                    'Conectando ao servidor...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'Aguarde a inicialização completa do servidor local e bancos de dados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Botão elegante de tentar novamente (se demorar mais que o normal)
                  OutlinedButton.icon(
                    onPressed: () {
                      _connectionCheckTimer?.cancel();
                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          _isServerOffline = false;
                        });
                      }
                      _fetchSessionInfo();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                    label: const Text(
                      'TENTAR NOVAMENTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
    if (_isServerOffline) {
      return _buildOfflineConnectingScreen();
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null && _authUserInfo == null) {
      return LoginPage(onLoginSuccess: refreshState);
    }

    // ⚠️  SEGURANÇA: Comparação case-insensitive para evitar bypass por capitalização.
    // A role 'SUPERADMIN' vem do servidor via AuthEndpoint → MembroEmpresa.role.
    if (_authUserInfo?.role?.toUpperCase() == 'SUPERADMIN') {
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
    return FincoreShell(onLogout: refreshState);
  }
}
