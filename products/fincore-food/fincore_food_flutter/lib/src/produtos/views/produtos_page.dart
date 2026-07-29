import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/categorias/views/categorias_page.dart';
import 'package:fincore_food_flutter/src/produtos/views/subviews/produtos_catalogo_view.dart';
import 'package:fincore_food_flutter/src/produtos/views/subviews/politicas_preco_view.dart';

/// Tela Principal do Módulo de Produtos.
/// Permite alternar entre o Catálogo de Produtos, Categorias (Split View) e as Políticas de Preço.
class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
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
        TabBar(
          controller: _tabController,
          labelColor: FincoreColors.primary,
          unselectedLabelColor: FincoreColors.textSecondary,
          indicatorColor: FincoreColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Catálogo de Produtos'),
            Tab(text: 'Categorias (Lotes)'),
            Tab(text: 'Políticas de Preço'),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Evita conflitos de gestos
            children: const [
              ProdutosCatalogoView(),
              CategoriasPage(),
              PoliticasPrecoView(),
            ],
          ),
        ),
      ],
    );
  }
}
