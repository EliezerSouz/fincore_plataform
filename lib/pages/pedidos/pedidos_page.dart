import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_view_model.dart';
import 'central_operacional_page.dart';
import 'gestao_pedidos_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Se o usuário alternou a aba manualmente, limpamos o destaque e filtro sugerido no ViewModel
    final vm = context.read<AppViewModel>();
    if (vm.filtroStatusSugerido != null || vm.pedidoIdParaDestacar != null) {
      vm.limparDestaqueKanban();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escutar alterações do ViewModel para alterar a aba sugerida reativamente
    final vm = context.watch<AppViewModel>();
    
    if (vm.filtroStatusSugerido != null) {
      final status = vm.filtroStatusSugerido!;
      final targetIndex = (status == 'Finalizado' || status == 'Cancelado') ? 1 : 0;
      
      // Agendar a transição de aba para o pós-frame atual, limpando qualquer cache ou PageStorage do Flutter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != targetIndex) {
          _tabController.animateTo(targetIndex);
        }
      });
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 12),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: const [
              Tab(
                iconMargin: EdgeInsets.only(bottom: 4),
                icon: Icon(Icons.kitchen_outlined, size: 20),
                text: 'Central Operacional (Cozinha)',
              ),
              Tab(
                iconMargin: EdgeInsets.only(bottom: 4),
                icon: Icon(Icons.receipt_long_outlined, size: 20),
                text: 'Gestão de Pedidos (Administração)',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CentralOperacionalPage(),
          GestaoPedidosPage(),
        ],
      ),
    );
  }
}
