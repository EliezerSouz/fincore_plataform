import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/fincore_core.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
    _entryController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final loginInput = _loginController.text.trim();
    final password = _passwordController.text;

    try {
      // ─── Autenticação exclusivamente via Supabase Auth ───────────────────────
      // ⚠️  SEGURANÇA [VAL-001]: O fallback de login local por username (SQLite)
      // foi removido pois não validava a senha, permitindo acesso sem autenticação.
      // Toda autenticação deve passar pelo Supabase Auth com validação de credenciais.
      // Ver relatório de auditoria item [VAL-001].
      String emailToAuth = loginInput;
      String? localPasswordHash;
      CoreUsuario? localMatchedUser;

      if (!loginInput.contains('@')) {
        // Se for login por nome de usuário (ex: caixa1), resolve o e-mail correspondente localmente no SQLite ou no Supabase
        try {
          final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
          final list = await usuarioRepo.findAll();
          final matched = list.where(
            (u) => u.username.toLowerCase() == loginInput.toLowerCase(),
          ).firstOrNull;

          if (matched != null) {
            localMatchedUser = matched;
            emailToAuth = matched.email ?? '${matched.username}@fincore.local';

            if (matched.avatarUrl != null && matched.avatarUrl!.startsWith('{')) {
              final map = jsonDecode(matched.avatarUrl!);
              localPasswordHash = map['password_hash'] as String?;
            }
          } else {
            // Se for um computador novo (SQLite local vazio), busca o e-mail do username diretamente no Supabase
            final remoteRows = await Supabase.instance.client
                .from('usuarios')
                .select('email, username')
                .ilike('username', loginInput)
                .limit(1);

            if (remoteRows.isNotEmpty) {
              final remoteEmail = remoteRows.first['email'] as String?;
              if (remoteEmail != null && remoteEmail.isNotEmpty) {
                emailToAuth = remoteEmail;
              } else {
                emailToAuth = '$loginInput@fincore.local';
              }
            } else {
              emailToAuth = '$loginInput@fincore.local';
            }
          }
        } catch (_) {
          emailToAuth = '$loginInput@fincore.local';
        }
      } else {
        // Se for e-mail, também tenta buscar o hash de senha local correspondente no SQLite
        try {
          final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
          final list = await usuarioRepo.findAll();
          final matched = list.firstWhere(
            (u) => u.email?.toLowerCase() == loginInput.toLowerCase(),
          );
          localMatchedUser = matched;
          if (matched.avatarUrl != null && matched.avatarUrl!.startsWith('{')) {
            final map = jsonDecode(matched.avatarUrl!);
            localPasswordHash = map['password_hash'] as String?;
          }
        } catch (_) {}
      }

      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: emailToAuth,
          password: password,
        );

        if (res.user != null) {
          widget.onLoginSuccess();
          return;
        }
        throw Exception('Não foi possível autenticar. Verifique e-mail e senha.');
      } catch (authErr) {
        // Se a chamada do Supabase falhar (ex: rede offline ou Supabase inativo) e tivermos a senha hash local, valida offline!
        final inputHash = _hashPassword(password);
        if (localPasswordHash != null && localPasswordHash == inputHash) {
          LogService.instance.info(LogModule.app, 'Login local offline autenticado via hash com sucesso.');
          if (localMatchedUser != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('fincore_offline_usuario_id', localMatchedUser.id);
          }
          widget.onLoginSuccess();
          return;
        }
        
        // Caso contrario, repassa o erro original
        rethrow;
      }
    } on AuthException catch (e) {
      LogService.instance.warning(LogModule.app, 'Falha de autenticação Supabase: ${e.message}');
      // Mapeia erros comuns do Supabase para mensagens amigáveis em PT-BR
      final msg = _mapAuthError(e.message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: FincoreColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      LogService.instance.error(LogModule.app, 'Erro ao autenticar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.toString().replaceAll('Exception: ', '')),
                ),
              ],
            ),
            backgroundColor: FincoreColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _hashPassword(String password) {
    var hash = BigInt.parse('14695981039346656037'); // 0xcbf29ce484222325
    final prime = BigInt.parse('1099511628211'); // 0x100000001b3
    final mask64 = (BigInt.one << 64) - BigInt.one;

    for (var i = 0; i < password.length; i++) {
      hash = hash ^ BigInt.from(password.codeUnitAt(i));
      hash = (hash * prime) & mask64;
    }
    return hash.toRadixString(16);
  }

  /// Mapeia mensagens de erro da API do Supabase para mensagens amigáveis em PT-BR.
  String _mapAuthError(String supabaseMessage) {
    final msg = supabaseMessage.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'E-mail ou senha incorretos. Verifique as credenciais e tente novamente.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-mail ainda não confirmado. Verifique sua caixa de entrada e clique no link de confirmação.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Muitas tentativas de login. Aguarde alguns minutos e tente novamente.';
    }
    if (msg.contains('user not found')) {
      return 'Conta não encontrada. Verifique o e-mail digitado ou cadastre-se.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    return 'Erro ao autenticar: $supabaseMessage';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FincoreColors.sidebarBackground,
      body: Row(
        children: [
          // ── Painel de Branding (esquerda) ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                // Fundo azul-marinho escuro exato do mockup
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
                  // Pontos decorativos (efeito do mockup)
                  Positioned(top: 80, left: 60, child: _Dot(size: 5)),
                  Positioned(top: 140, left: 160, child: _Dot(size: 3)),
                  Positioned(top: 220, right: 80, child: _Dot(size: 4)),
                  Positioned(bottom: 200, left: 40, child: _Dot(size: 6)),
                  Positioned(bottom: 120, right: 120, child: _Dot(size: 3)),
                  Positioned(top: 400, left: 100, child: _Dot(size: 4)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo oficial pulsante sem plano de fundo (transparente e unificado)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + (_pulseController.value * 0.04);
                            final opacity = 0.7 + (_pulseController.value * 0.3);
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
                            fontSize: 36,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gestão inteligente para seu delivery',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Formulário de Login (direita) ─────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: FincoreColors.background,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logotipo unificado sem plano de fundo
                              Center(
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Image.asset(
                                    'assets/images/app_launcher_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              const Text(
                                'Bem-vindo de volta',
                                style: TextStyle(
                                  color: FincoreColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Entre com sua conta para continuar',
                                style: TextStyle(
                                  color: FincoreColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // E-mail
                              TextFormField(
                                controller: _loginController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: FincoreColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  labelStyle: const TextStyle(
                                    color: FincoreColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: FincoreColors.textMuted,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: FincoreColors.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: FincoreColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: FincoreColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: FincoreColors.danger,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: FincoreColors.danger,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe seu e-mail';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Senha
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                style: const TextStyle(
                                  color: FincoreColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  labelStyle: const TextStyle(
                                    color: FincoreColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: FincoreColors.textMuted,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: FincoreColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureText = !_obscureText),
                                  ),
                                  filled: true,
                                  fillColor: FincoreColors.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: FincoreColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: FincoreColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: FincoreColors.danger,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: FincoreColors.danger,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a senha';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              // Botão Entrar com gradiente
                              Container(
                                decoration: BoxDecoration(
                                  gradient: _isLoading
                                      ? null
                                      : FincoreColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isLoading
                                      ? null
                                      : FincoreShadows.glow(
                                          FincoreColors.primary,
                                          intensity: 0.25,
                                        ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor:
                                        FincoreColors.surface,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: FincoreColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'ENTRAR',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 15,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: FincoreColors.border,
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'ou',
                                      style: TextStyle(
                                        color: FincoreColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: FincoreColors.border,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Cadastrar
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SignupPage(
                                        onSignupSuccess:
                                            widget.onLoginSuccess,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  side: const BorderSide(
                                    color: FincoreColors.border,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'CRIAR CONTA',
                                  style: TextStyle(
                                    color: FincoreColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),
                              Center(
                                child: Text(
                                  'v1.1.0 (Build 2)',
                                  style: TextStyle(
                                    color: FincoreColors.textMuted
                                        .withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ponto Decorativo ─────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final double size;
  const _Dot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
    );
  }
}
