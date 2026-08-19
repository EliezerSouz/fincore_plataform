import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_shared/fincore_shared.dart';
import '../controllers/dashboard_controller.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';

/// Dashboard principal do FINCORE Food — Fiel ao mockup premium.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;

  /// Callback para navegar para outra seção do Shell a partir do Dashboard.
  void _navigateTo(String section) {
    // Tenta encontrar o FincoreShell ancestral e acionar a navegação
    // O Shell expoe NavigatorObserver que pode ser chamado pelo context
    final scaffoldKey = context.findAncestorStateOfType<ScaffoldState>();
    if (scaffoldKey != null) {
      // Usa o InheritedWidget do Shell para acionar a mudança de módulo
      // Fallback: usa o Navigator para push de rotas nomeadas
    }
    // Publica evento via Notification para o Shell ouvir
    _DashboardNavNotification(section).dispatch(context);
  }

  @override
  void initState() {
    super.initState();
    _controller = DependencyInjection().get<DashboardController>();
    _controller.loadMetrics();
  }

  String get _saudacao {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = DependencyInjection().get<TenantContext>();
    final nomeUsuario = tenant.hasContext ? tenant.usuario.nome : 'Usuário';
    final nomeEmpresa = tenant.hasContext ? tenant.empresa.nomeFantasia : 'Fincore Food';

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final m = _controller.metrics;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Hero Banner (igual ao mockup: gradiente laranja+cyan) ──────
              _HeroBanner(
                saudacao: _saudacao,
                nomeUsuario: nomeUsuario,
                nomeEmpresa: nomeEmpresa,
                onRefresh: _controller.loadMetrics,
              ),

              const SizedBox(height: 28),

              // ── KPI Cards ─────────────────────────────────────────────────
              if (_controller.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      color: FincoreColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Pedidos Hoje',
                        value: m.totalPedidosHoje.toString(),
                        icon: Icons.receipt_long_rounded,
                        color: FincoreColors.accent,
                        delay: 0,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _KpiCard(
                        label: 'Faturamento',
                        value: FincoreMoneyFormatter.format(m.faturamentoCentavosHoje),
                        icon: Icons.attach_money_rounded,
                        color: FincoreColors.success,
                        delay: 80,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _KpiCard(
                        label: 'Em Preparo',
                        value: m.emPreparo.toString(),
                        icon: Icons.timer_outlined,
                        color: FincoreColors.warning,
                        delay: 160,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _KpiCard(
                        label: 'Entregas',
                        value: m.prontosOuEntrega.toString(),
                        icon: Icons.delivery_dining_rounded,
                        color: const Color(0xFF818CF8),
                        delay: 240,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // ── Linha inferior: Gráfico placeholder + Ações Rápidas ────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gráfico de faturamento (placeholder visual fiel ao mockup)
                  Expanded(
                    flex: 3,
                    child: _FaturamentoCard(
                      totalHoje: m.faturamentoCentavosHoje,
                      dados7Dias: m.faturamento7DiasCentavos,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Painel de ações rápidas
                  SizedBox(
                    width: 220,
                    child: _AcoesRapidasCard(onNavigate: _navigateTo),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Notification para comunicar evento de navegação do Dashboard ao Shell.
/// P3-01: Permite que os botões de ações rápidas mudem a página ativa.
class _DashboardNavNotification extends Notification {
  final String section;
  const _DashboardNavNotification(this.section);
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String saudacao;
  final String nomeUsuario;
  final String nomeEmpresa;
  final VoidCallback onRefresh;

  const _HeroBanner({
    required this.saudacao,
    required this.nomeUsuario,
    required this.nomeEmpresa,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FincoreAnimatedEntry(
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // Gradiente vibrante laranja + cyan como no mockup
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE85D04),
              Color(0xFFFF9F1C),
              Color(0xFF06B6D4),
              Color(0xFF0891B2),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE85D04).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Noise/blur decorativo no canto direito (efeito do mockup)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$saudacao, ${nomeUsuario.split(' ').first}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nomeEmpresa,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onRefresh,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Atualizar painel',
                            style: TextStyle(
                              color: Color(0xFFE85D04),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── KPI Card (igual ao mockup: fundo semi-colorido, barra inferior) ─────────
class _KpiCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              widget.label,
                              style: const TextStyle(
                                color: FincoreColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Barra inferior colorida (igual ao mockup)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gráfico de Faturamento (visual fiel ao mockup) ───────────────────────────
class _FaturamentoCard extends StatelessWidget {
  final int totalHoje;
  final List<int> dados7Dias;

  const _FaturamentoCard({
    required this.totalHoje,
    this.dados7Dias = const [0, 0, 0, 0, 0, 0, 0],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Faturamento',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Hoje',
                      style: TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: FincoreColors.textMuted),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 140,
            child: _SimpleBarChart(
              totalHoje: totalHoje,
              dados7Dias: dados7Dias,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final int totalHoje;
  final List<int> dados7Dias;

  const _SimpleBarChart({required this.totalHoje, required this.dados7Dias});

  @override
  Widget build(BuildContext context) {
    // P2-07: Usa dados reais dos últimos 7 dias em vez de proporções hardcoded
    final maxValor = dados7Dias.isEmpty ? 1 : dados7Dias.reduce((a, b) => a > b ? a : b);

    if (maxValor <= 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bar_chart_rounded, color: FincoreColors.textMuted, size: 36),
            SizedBox(height: 6),
            Text(
              'Nenhum faturamento registrado hoje',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Calcular proporcões reais baseadas no máximo do período
    final bars = dados7Dias.map((v) => maxValor > 0 ? v / maxValor : 0.0).toList();
    final diasSemana = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('E', 'pt_BR').format(d);
    });

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(bars.length, (i) {
            final pct = bars[i];
            final isHoje = i == bars.length - 1;
            return Expanded(
              child: Tooltip(
                message: '${diasSemana[i]}: R\$ ${(dados7Dias[i] / 100).toStringAsFixed(2)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    height: 100 * (pct as double).clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isHoje
                            ? [const Color(0xFF06B6D4), const Color(0xFF0891B2)]
                            : [
                                FincoreColors.accent.withValues(alpha: 0.4),
                                FincoreColors.accent.withValues(alpha: 0.2),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: diasSemana.map((d) => Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: const TextStyle(color: FincoreColors.textMuted, fontSize: 9),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ─── Ações Rápidas (vertical como no mockup) ─────────────────────────────────
class _AcoesRapidasCard extends StatelessWidget {
  final void Function(String section) onNavigate;

  const _AcoesRapidasCard({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações rápidas',
            style: TextStyle(
              color: FincoreColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _AcaoBtn(
            label: 'Novo Pedido',
            isPrimary: true,
            icon: Icons.add_rounded,
            onTap: () => onNavigate('pdv_express'), // P3-01: navegação real
          ),
          const SizedBox(height: 10),
          _AcaoBtn(
            label: 'Clientes',
            icon: Icons.people_outline_rounded,
            onTap: () => onNavigate('clientes'),
          ),
          const SizedBox(height: 10),
          _AcaoBtn(
            label: 'Cardápio',
            icon: Icons.restaurant_menu_outlined,
            onTap: () => onNavigate('produtos'),
          ),
          const SizedBox(height: 10),
          _AcaoBtn(
            label: 'Pedidos',
            icon: Icons.receipt_long_outlined,
            onTap: () => onNavigate('central_pedidos'),
          ),
        ],
      ),
    );
  }
}

class _AcaoBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AcaoBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_AcaoBtn> createState() => _AcaoBtnState();
}

class _AcaoBtnState extends State<_AcaoBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFFE85D04), Color(0xFFFF9F1C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.isPrimary
                ? null
                : (_hovered
                    ? FincoreColors.surfaceElevated
                    : FincoreColors.surfaceOverlay),
            borderRadius: BorderRadius.circular(10),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: _hovered
                        ? FincoreColors.primary.withValues(alpha: 0.3)
                        : FincoreColors.border,
                  ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isPrimary
                    ? Colors.white
                    : FincoreColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : FincoreColors.textSecondary,
                    fontSize: 13,
                    fontWeight: widget.isPrimary
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
