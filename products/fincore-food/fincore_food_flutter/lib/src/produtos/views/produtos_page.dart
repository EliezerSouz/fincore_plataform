import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_food_flutter/src/categorias/views/categorias_page.dart';
import 'package:fincore_food_flutter/src/produtos/views/subviews/produtos_catalogo_view.dart';
import 'package:fincore_food_flutter/src/produtos/views/subviews/politicas_preco_view.dart';

/// Tela Principal do Módulo de Produtos.
/// Permite alternar entre o Catálogo de Produtos, Categorias e as Políticas de Preço.
class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Header Row (Somente Abas) ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSubTab('Catálogo', Icons.storefront_outlined, 0),
            const SizedBox(width: 16),
            _buildSubTab('Categorias', Icons.category_outlined, 1),
            const SizedBox(width: 16),
            _buildSubTab('Políticas de Preço', Icons.sell_outlined, 2),
          ],
        ),

        const SizedBox(height: 16),

        // ── Conteúdo das Abas ─────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ProdutosCatalogoView(onChanged: () {}),
              CategoriasPage(
                onChanged: () {},
                onAddProduto: (cat) {
                  _tabController.animateTo(0);
                  setState(() => _selectedTab = 0);
                },
              ),
              PoliticasPrecoView(onChanged: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTab(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? FincoreColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? FincoreColors.primary : FincoreColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
