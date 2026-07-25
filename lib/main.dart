import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'design_system/app_theme.dart';
import 'database/app_database.dart';
import 'pages/clientes/clientes_page.dart';
import 'pages/configuracoes/configuracoes_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/pedidos/central_operacional_page.dart';
import 'pages/pedidos/pedidos_page.dart';
import 'pages/pedidos/novo_pedido_page.dart';
import 'pages/produtos/produtos_page.dart';
import 'pages/producao/producao_page.dart';
import 'pages/estoque/estoque_page.dart';
import 'pages/producao/agenda_operacional_page.dart';
import 'pages/estoque/movimentacoes_page.dart';
import 'pages/financeiro/financeiro_page.dart';
import 'providers/app_view_model.dart';
import 'design_system/colors.dart'; // import new colors for use in Shell

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppViewModel(AppDatabase()),
      child: const SalgaderiaApp(),
    ),
  );
}

class SalgaderiaApp extends StatelessWidget {
  const SalgaderiaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Salgaderia ERP',
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Shell(),
      );
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final isExtended = MediaQuery.sizeOf(context).width > 1150;

    final pages = [
      const DashboardPage(),            // 0
      const CentralOperacionalPage(),   // 1
      const AgendaOperacionalPage(),    // 2
      const ProducaoPage(),             // 3
      const PedidosPage(),              // 4
      const ClientesPage(),             // 5
      const ProdutosPage(),             // 6
      const EstoquePage(),              // 7
      const MovimentacoesPage(),        // 8
      const FinanceiroPage(),           // 9
      const ConfiguracoesPage(),        // 10
      const NovoPedidoPage(),           // 11
    ];

    final dashboardItems = [
      _SidebarItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
    ];

    final operacaoItems = [
      _SidebarItem(Icons.view_kanban_outlined, Icons.view_kanban, 'Central Operacional', 1),
      _SidebarItem(Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Produção', 3),
      _SidebarItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Expedição & Agenda', 2),
    ];

    final comercialItems = [
      _SidebarItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Pedidos', 4),
      _SidebarItem(Icons.people_outline, Icons.people, 'Clientes', 5),
      _SidebarItem(Icons.fastfood_outlined, Icons.fastfood, 'Produtos', 6),
    ];

    final estoqueItems = [
      _SidebarItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Estoque & MRP', 7),
      _SidebarItem(Icons.history_outlined, Icons.history, 'Movimentações', 8),
    ];

    final financeiroItems = [
      _SidebarItem(Icons.monetization_on_outlined, Icons.monetization_on, 'Financeiro', 9),
    ];

    final sistemaItems = [
      _SidebarItem(Icons.settings_outlined, Icons.settings, 'Configurações', 10),
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isExtended ? 240 : 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header com Logo / Marca
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 0),
                  child: Row(
                    mainAxisAlignment: isExtended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bakery_dining,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      if (isExtended) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vm.settings.empresa.isEmpty
                                    ? 'Salgaderia'
                                    : vm.settings.empresa,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Gestão Operacional',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Módulos
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildModuleSection('DASHBOARD', dashboardItems, vm, isExtended),
                      const SizedBox(height: 16),
                      _buildModuleSection('OPERAÇÃO', operacaoItems, vm, isExtended),
                      const SizedBox(height: 16),
                      _buildModuleSection('COMERCIAL', comercialItems, vm, isExtended),
                      const SizedBox(height: 16),
                      _buildModuleSection('ESTOQUE', estoqueItems, vm, isExtended),
                      const SizedBox(height: 16),
                      _buildModuleSection('FINANCEIRO', financeiroItems, vm, isExtended),
                      const SizedBox(height: 16),
                      _buildModuleSection('SISTEMA', sistemaItems, vm, isExtended),
                    ],
                  ),
                ),

                // Footer status indicator
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: isExtended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (isExtended) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'SnackFlow Ativo',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                return Stack(
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(vm.pagina),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: pages[vm.pagina],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSection(
      String title, List<_SidebarItem> items, AppViewModel vm, bool isExtended) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExtended)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ...items.map((item) {
          final isSelected = vm.pagina == item.pageIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => vm.navegar(item.pageIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: isExtended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    if (isExtended) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int pageIndex;
  const _SidebarItem(this.icon, this.selectedIcon, this.label, this.pageIndex);
}
