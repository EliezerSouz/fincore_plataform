import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/main.dart';

class PendingApprovalPage extends StatefulWidget {
  final String tenantId;
  final VoidCallback onApproved;
  final VoidCallback onLogout;

  const PendingApprovalPage({
    super.key,
    required this.tenantId,
    required this.onApproved,
    required this.onLogout,
  });

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage>
    with TickerProviderStateMixin {
  Timer? _pollingTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  String _empresaNome = '';
  String _email = '';
  String _plano = 'Profissional (Prata)';
  String _documentoFiscal = '';
  String _segmento = 'Food Service';

  @override
  void initState() {
    super.initState();
    _startPolling();
    _loadRealDetails();

    // Pulse no ícone
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Entrada da tela
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  Future<void> _loadRealDetails() async {
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {
      // Supabase não inicializado (ex: ambiente de testes)
    }
    final currentEmail = user?.email ?? '';

    // 1. Carregar instantaneamente de SharedPreferences para acesso sem espera
    try {
      final prefs = await SharedPreferences.getInstance();
      final pNome = prefs.getString('pending_empresa_nome');
      final pEmail = prefs.getString('pending_empresa_email');
      final pPlano = prefs.getString('pending_empresa_plano');
      final pDoc = prefs.getString('pending_empresa_doc');
      final pSeg = prefs.getString('pending_empresa_seg');

      if (mounted) {
        setState(() {
          _empresaNome = (pNome != null && pNome.isNotEmpty)
              ? pNome
              : (user?.userMetadata?['nome_fantasia'] ?? 'Minha Empresa');
          _email = (pEmail != null && pEmail.isNotEmpty)
              ? pEmail
              : (currentEmail.isNotEmpty ? currentEmail : 'email@empresa.com');
          _plano = _formatPlano(pPlano ?? 'prata');
          _documentoFiscal = pDoc ?? '';
          _segmento = pSeg ?? 'Food Service';
        });
      }
    } catch (_) {}

    // 2. Atualizar via repositórios locais ou backend Serverpod
    try {
      final empresaRepo = DependencyInjection().get<EmpresaRepository>();
      final empresas = await empresaRepo.findAll();
      final empLocal = empresas.where((e) => e.id == widget.tenantId).firstOrNull ?? empresas.firstOrNull;

      if (empLocal != null && mounted) {
        setState(() {
          _empresaNome = empLocal.nomeFantasia.isNotEmpty ? empLocal.nomeFantasia : empLocal.razaoSocial;
          _email = currentEmail.isNotEmpty ? currentEmail : empLocal.email;
          _plano = _formatPlano(empLocal.plano);
          final doc = empLocal.documentoFiscal;
          if (doc != null && doc.isNotEmpty) _documentoFiscal = doc;
          final seg = empLocal.segmento;
          if (seg != null && seg.isNotEmpty) _segmento = seg;
        });
      }

      final emp = await client.onboarding.minhaEmpresa();
      if (!mounted) return;
      if (emp != null) {
        setState(() {
          _empresaNome = emp.nomeFantasia.isNotEmpty ? emp.nomeFantasia : emp.razaoSocial;
          _email = emp.email.isNotEmpty ? emp.email : currentEmail;
          _plano = _formatPlano(emp.plano);
          final doc = emp.documentoFiscal;
          if (doc != null && doc.isNotEmpty) _documentoFiscal = doc;
          final seg = emp.segmento;
          if (seg != null && seg.isNotEmpty) _segmento = seg;
        });
      }
    } catch (e) {
      debugPrint('Atualização em background: $e');
    }
  }

  String _formatPlano(dynamic raw) {
    final str = (raw is Enum ? raw.name : raw.toString()).toLowerCase();
    switch (str) {
      case 'bronze':
        return 'Essencial (Bronze)';
      case 'prata':
        return 'Profissional (Prata)';
      case 'ouro':
        return 'Enterprise (Ouro)';
      default:
        return str.toUpperCase();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final status = await client.onboarding.status();
        if (status == 'ativo') {
          timer.cancel();
          widget.onApproved();
        }
      } catch (e) {
        debugPrint('Erro no polling de status: $e');
      }
    });
  }

  Future<void> _verificarStatus() async {
    try {
      final status = await client.onboarding.status();
      if (!mounted) return;
      if (status == 'ativo') {
        widget.onApproved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sua conta está em análise final pela equipe comercial.'),
            backgroundColor: FincoreColors.surface,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verificação: $e'), backgroundColor: FincoreColors.danger),
      );
    }
  }

  void _abrirSuporteWhatsApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.support_agent_rounded, color: FincoreColors.success),
            SizedBox(width: 10),
            Text('Atendimento Comercial FINCORE', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para agilizar a liberação imediata do seu espaço de trabalho, fale diretamente com nossa equipe comercial:',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android_rounded, color: FincoreColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'WhatsApp: (11) 99999-8888',
                    style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar', style: TextStyle(color: FincoreColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Ícone Animado com Glow Laranja ──────────────────────
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FincoreColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FincoreColors.primary.withValues(alpha: 0.08),
                            border: Border.all(
                              color: FincoreColors.primary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FincoreColors.surface,
                            border: Border.all(
                              color: FincoreColors.primary.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: FincoreColors.primary.withValues(alpha: 0.35),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/app_launcher_icon.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Título & Subtítulo ──────────────────────────────────
                  const Text(
                    'Aguardando Liberação da Conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sua empresa foi enviada para análise! Nossa equipe comercial\nestá liberando o acesso ao seu espaço de trabalho.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Stepper de Pílulas ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _PillStep(
                        number: '1',
                        label: 'Cadastro Enviado',
                        isCompleted: true,
                        isActive: false,
                      ),
                      SizedBox(width: 8),
                      _PillStep(
                        number: '2',
                        label: 'Análise Comercial',
                        isCompleted: false,
                        isActive: true,
                      ),
                      SizedBox(width: 8),
                      _PillStep(
                        number: '3',
                        label: 'Acesso Liberado',
                        isCompleted: false,
                        isActive: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Painel Principal de Informações ───────────────────────
                  Container(
                    constraints: const BoxConstraints(maxWidth: 620),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: FincoreColors.border.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: FincoreColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: FincoreColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: FincoreColors.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Solicitação Recebida • Liberação comercial em andamento (~10 min)',
                                  style: TextStyle(
                                    color: FincoreColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Grid de Detalhes Reais do Cadastro
                        const Text(
                          'DADOS DO SEU ESTABELECIMENTO',
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _DetailTile(
                                icon: Icons.storefront_rounded,
                                label: 'Empresa',
                                value: _empresaNome.isNotEmpty ? _empresaNome : 'Empresa Cadastrada',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DetailTile(
                                icon: Icons.alternate_email_rounded,
                                label: 'Responsável',
                                value: _email.isNotEmpty ? _email : 'Contato Comercial',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            if (_documentoFiscal.isNotEmpty)
                              Expanded(
                                child: _DetailTile(
                                  icon: Icons.badge_outlined,
                                  label: 'Documento Fiscal',
                                  value: _documentoFiscal,
                                ),
                              ),
                            if (_documentoFiscal.isNotEmpty) const SizedBox(width: 12),
                            Expanded(
                              child: _DetailTile(
                                icon: Icons.workspace_premium_rounded,
                                label: 'Plano Solicitado',
                                value: _plano,
                                badge: 'Em Ativação',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: FincoreColors.border, height: 1),
                        const SizedBox(height: 20),

                        // Etapas do Processamento Comercial
                        const Text(
                          'ETAPAS DA LIBERAÇÃO COMERCIAL',
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        const _StepCheckItem(
                          icon: Icons.check_circle_rounded,
                          color: FincoreColors.success,
                          title: '1. Recebimento da Solicitação',
                          subtitle: 'Dados do estabelecimento e plano vinculados ao seu cadastro.',
                        ),
                        const SizedBox(height: 10),
                        const _StepCheckItem(
                          icon: Icons.hourglass_top_rounded,
                          color: FincoreColors.warning,
                          title: '2. Análise Comercial & Ativação de Licença',
                          subtitle: 'Validação da conta e liberação dos módulos operacionais.',
                        ),
                        const SizedBox(height: 10),
                        const _StepCheckItem(
                          icon: Icons.radio_button_unchecked_rounded,
                          color: FincoreColors.textMuted,
                          title: '3. Acesso Liberado ao Espaço de Trabalho',
                          subtitle: 'Você poderá acessar o PDV, Cardápio e Gestão da Cozinha.',
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: FincoreColors.border, height: 1),
                        const SizedBox(height: 20),

                        // O que você poderá fazer ao ser liberado
                        const Text(
                          'PRÓXIMOS PASSOS NO PRIMEIRO ACESSO',
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _StepCheckItem(
                          icon: Icons.restaurant_menu_rounded,
                          color: FincoreColors.primary,
                          title: '1. Cadastrar Categorias e Produtos',
                          subtitle: 'Monte seu cardápio com suporte a herança de regras e estoque.',
                        ),
                        const SizedBox(height: 8),
                        _StepCheckItem(
                          icon: Icons.soup_kitchen_rounded,
                          color: FincoreColors.primary,
                          title: '2. Configurar Rota da Cozinha (KDS)',
                          subtitle: 'Defina impressoras e telas de produção para a equipe.',
                        ),
                        const SizedBox(height: 8),
                        _StepCheckItem(
                          icon: Icons.point_of_sale_rounded,
                          color: FincoreColors.primary,
                          title: '3. Realizar sua Primeira Venda no PDV',
                          subtitle: 'Abra seu caixa e inicie a operação de vendas imediatamente.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Botões de Ação ───────────────────────────────────────
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      // Botão WhatsApp
                      ElevatedButton.icon(
                        onPressed: _abrirSuporteWhatsApp,
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                        label: const Text('FALAR NO WHATSAPP COMERCIAL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Botão Verificar Status
                      OutlinedButton.icon(
                        onPressed: _verificarStatus,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('VERIFICAR STATUS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FincoreColors.primary,
                          side: BorderSide(color: FincoreColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Link Sair ────────────────────────────────────────────
                  TextButton(
                    onPressed: widget.onLogout,
                    child: const Text(
                      'Sair da Conta',
                      style: TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: FincoreColors.textMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Rodapé ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'FIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'CORE',
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        ' FOOD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pílula do Stepper ────────────────────────────────────────────────────────
class _PillStep extends StatelessWidget {
  final String number;
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _PillStep({
    required this.number,
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    if (isCompleted) {
      bg = FincoreColors.success.withValues(alpha: 0.12);
      border = FincoreColors.success;
      text = FincoreColors.success;
    } else if (isActive) {
      bg = FincoreColors.primary.withValues(alpha: 0.12);
      border = FincoreColors.primary;
      text = FincoreColors.primary;
    } else {
      bg = FincoreColors.surface;
      border = FincoreColors.border;
      text = FincoreColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            Icon(Icons.check, size: 14, color: text)
          else
            Text(
              '$number.',
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Componentes Auxiliares de Exibição ─────────────────────────────────────
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? badge;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: FincoreColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: FincoreColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: FincoreColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepCheckItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StepCheckItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FincoreColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
