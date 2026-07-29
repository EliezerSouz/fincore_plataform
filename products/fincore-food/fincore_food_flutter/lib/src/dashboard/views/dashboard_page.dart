import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_shared/fincore_shared.dart';
import '../domain/dashboard_service.dart';
import '../data/dashboard_repository.dart';

/// Dashboard analítica principal do FINCORE Food com consumo de dados reais.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;
  DashboardMetrics _metrics = DashboardMetrics.zero();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dashboardService = DependencyInjection().get<DashboardService>();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.getMetrics();
      if (mounted) {
        setState(() {
          _metrics = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha ao carregar métricas operacionais: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantCtx = DependencyInjection().get<TenantContext>();
    final nomeEmpresa = tenantCtx.hasContext ? tenantCtx.empresa.nomeFantasia : 'Empresa';
    final nomeUsuario = tenantCtx.hasContext ? tenantCtx.usuario.nome : '';
    final hora = DateTime.now().hour;
    final saudacao = hora < 12
        ? 'Bom dia'
        : hora < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      color: FincoreColors.primary,
      backgroundColor: FincoreColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de boas-vindas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FincoreColors.accent.withOpacity(0.15),
                    FincoreColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, color: FincoreColors.accent, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$saudacao, $nomeUsuario!',
                          style: const TextStyle(
                            color: FincoreColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nomeEmpresa,
                          style: const TextStyle(
                            color: FincoreColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Resumo operacional do dia • Atualizado ${DateTime.now().formattedTime}',
                          style: const TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão de Refresh Manual
                  IconButton(
                    icon: const Icon(Icons.refresh, color: FincoreColors.textSecondary),
                    onPressed: _loadMetrics,
                    tooltip: 'Atualizar Painel',
                  ),
                  const SizedBox(width: 12),
                  // Indicador de status da sincronização
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              AppErrorState(
                message: _errorMessage!,
                onRetry: _loadMetrics,
              ),
              const SizedBox(height: 24),
            ],

            // KPIs do Dia
            const Text(
              'KPIs DO DIA',
              style: TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: AppLoading(message: 'Carregando dados consolidados...'),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth < 600 ? 1.2 : 1.5,
                    children: [
                      AppMetricCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Pedidos Hoje',
                        value: _metrics.totalPedidosHoje.toString(),
                        color: FincoreColors.accent,
                        subtitle: 'Total de pedidos do PDV',
                      ),
                      AppMetricCard(
                        icon: Icons.monetization_on_outlined,
                        title: 'Faturamento',
                        value: FincoreMoneyFormatter.format(_metrics.faturamentoCentavosHoje),
                        color: FincoreColors.success,
                        subtitle: 'Em caixa ou a receber',
                      ),
                      AppMetricCard(
                        icon: Icons.pending_actions_outlined,
                        title: 'Em Preparo',
                        value: _metrics.emPreparo.toString(),
                        color: FincoreColors.warning,
                        subtitle: 'Fila e Cozinha do KDS',
                      ),
                      AppMetricCard(
                        icon: Icons.delivery_dining_outlined,
                        title: 'Prontos / Entrega',
                        value: _metrics.prontosOuEntrega.toString(),
                        color: const Color(0xFF2196F3),
                        subtitle: 'Aguardando despacho',
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 24),

            // Ações Rápidas
            const Text(
              'AÇÕES RÁPIDAS',
              style: TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth < 600 ? 1.8 : 2.2,
                  children: [
                    _QuickAction(
                      icon: Icons.point_of_sale_outlined,
                      label: 'Novo Pedido',
                      subtitle: 'Abrir PDV',
                      color: FincoreColors.accent,
                      onTap: () {
                        // Nota: O switchTab na FincoreShell pode ser acessado via menu lateral
                      },
                    ),
                    _QuickAction(
                      icon: Icons.people_outline,
                      label: 'Clientes',
                      subtitle: 'Gerenciar base',
                      color: const Color(0xFF9C27B0),
                      onTap: () {},
                    ),
                    _QuickAction(
                      icon: Icons.restaurant_menu_outlined,
                      label: 'Cardápio',
                      subtitle: 'Editar produtos',
                      color: const Color(0xFF00BCD4),
                      onTap: () {},
                    ),
                    _QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Pedidos',
                      subtitle: 'Central de pedidos',
                      color: const Color(0xFFFF5722),
                      onTap: () {},
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Aviso de dados em tempo real consolidado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: FincoreColors.success.withOpacity(0.8), size: 18),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Os dados operacionais acima são consolidados em tempo real a partir das transações salvas localmente no banco Drift (SQLite).',
                      style: TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 13,
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
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
