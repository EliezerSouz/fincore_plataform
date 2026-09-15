import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_core/fincore_core.dart';

/// Tela de seleção de empresa exibida quando o usuário possui múltiplos vínculos
/// em [membro_empresa]. Permite que o proprietário escolha com qual contexto
/// (Matriz, Filial, etc.) deseja operar a sessão atual.
class EmpresaSelectorPage extends StatefulWidget {
  /// Lista de empresas às quais o usuário tem acesso (dados do Supabase).
  final List<Map<String, dynamic>> empresas;

  /// Callback invocado após a empresa ser selecionada e o bootstrap concluído.
  final VoidCallback onEmpresaSelecionada;

  const EmpresaSelectorPage({
    super.key,
    required this.empresas,
    required this.onEmpresaSelecionada,
  });

  @override
  State<EmpresaSelectorPage> createState() => _EmpresaSelectorPageState();
}

class _EmpresaSelectorPageState extends State<EmpresaSelectorPage>
    with SingleTickerProviderStateMixin {
  String? _loadingTenantId;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selecionarEmpresa(Map<String, dynamic> empresa) async {
    final empresaId = empresa['id'] as String;
    setState(() => _loadingTenantId = empresaId);

    try {
      // Buscar membro da empresa para obter a role do usuário
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Buscar perfil do usuário local
      final usuarioRows = await supabase
          .from('usuarios')
          .select('id')
          .eq('authUserId', currentUserId)
          .limit(1);

      final usuarioId = usuarioRows.isNotEmpty
          ? (usuarioRows.first as Map<String, dynamic>)['id'] as String
          : currentUserId;

      // Buscar membro nesta empresa
      final membroRows = await supabase
          .from('membro_empresa')
          .select()
          .eq('usuarioId', usuarioId)
          .eq('tenantId', empresaId)
          .limit(1);

      final role = membroRows.isNotEmpty
          ? (membroRows.first as Map<String, dynamic>)['role'] as String? ?? 'OPERADOR'
          : 'OPERADOR';

      // Buscar empresa no banco local
      final di = DependencyInjection();
      final empresaRepo = di.get<EmpresaRepository>();
      final usuarioRepo = di.get<UsuarioRepository>();
      final tenantContext = di.get<TenantContext>();

      final localEmpresas = await empresaRepo.findAll();
      final localUsuarios = await usuarioRepo.findAll();

      CoreEmpresa? localEmpresa = localEmpresas.where((e) => e.id == empresaId).firstOrNull;
      CoreUsuario? localUser = localUsuarios.where((u) => u.id == usuarioId || u.authUserId == currentUserId).firstOrNull;

      if (localEmpresa != null && localUser != null) {
        tenantContext.setContext(
          empresa: localEmpresa,
          usuario: localUser.copyWith(role: role),
        );
      }

      if (!mounted) return;
      widget.onEmpresaSelecionada();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao entrar na empresa: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loadingTenantId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bem-vindo de volta!',
                          style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Text(
                          'Escolha a empresa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'Você tem acesso a ${widget.empresas.length} empresa${widget.empresas.length > 1 ? 's' : ''}. Selecione o contexto para operar.',
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Lista de empresas
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.empresas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final empresa = widget.empresas[index];
                      final empresaId = empresa['id'] as String;
                      final isLoading = _loadingTenantId == empresaId;
                      final isDisabled = _loadingTenantId != null && !isLoading;

                      return _EmpresaCard(
                        empresa: empresa,
                        isLoading: isLoading,
                        isDisabled: isDisabled,
                        onTap: () => _selecionarEmpresa(empresa),
                      );
                    },
                  ),
                ),

                // Rodapé
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Para criar uma nova empresa, acesse Configurações → Nova Empresa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmpresaCard extends StatelessWidget {
  final Map<String, dynamic> empresa;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _EmpresaCard({
    required this.empresa,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  String get _nomeFantasia => empresa['nomeFantasia'] as String? ?? '';
  String get _documentoFiscal => empresa['documentoFiscal'] as String? ?? '';
  String get _status => (empresa['status'] as String? ?? 'ATIVO').toUpperCase();
  String get _plano => (empresa['plano'] as String? ?? '').toUpperCase();

  Color get _statusColor {
    switch (_status) {
      case 'ATIVO':
        return const Color(0xFF3FB950);
      case 'PENDENTE_ATIVACAO':
        return const Color(0xFFD29922);
      case 'SUSPENSO':
        return const Color(0xFFF85149);
      default:
        return const Color(0xFF8B949E);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'ATIVO':
        return 'Ativa';
      case 'PENDENTE_ATIVACAO':
        return 'Pendente';
      case 'SUSPENSO':
        return 'Suspensa';
      default:
        return _status;
    }
  }

  String get _initials {
    final nome = _nomeFantasia.trim();
    final parts = nome.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDisabled ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLoading
                ? const Color(0xFF6C63FF).withValues(alpha: 0.08)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLoading
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                  : const Color(0xFF30363D),
              width: isLoading ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomeFantasia,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _documentoFiscal,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_plano.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _plano,
                              style: const TextStyle(
                                color: Color(0xFF9D8EFF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Indicador de ação
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6C63FF),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF30363D),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
