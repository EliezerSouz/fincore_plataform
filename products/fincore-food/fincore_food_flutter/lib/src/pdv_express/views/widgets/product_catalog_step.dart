import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';

class ProductCatalogStep extends StatefulWidget {
  final PdvExpressController controller;
  final FocusNode searchFocusNode;
  final TextEditingController searchController;

  const ProductCatalogStep({
    super.key,
    required this.controller,
    required this.searchFocusNode,
    required this.searchController,
  });

  @override
  State<ProductCatalogStep> createState() => _ProductCatalogStepState();
}

class _ProductCatalogStepState extends State<ProductCatalogStep> {
  final List<Map<String, dynamic>> _catalogProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _categories = ['Todos'];
  String _selectedCategory = 'Todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductsAndCategories();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  Future<void> _loadProductsAndCategories() async {
    setState(() {
      _isLoading = true;
    });

    final cats = widget.controller.categories;
    final catNames = cats.map((c) => c.nome).toList();
    
    final prods = widget.controller.products;
    final List<Map<String, dynamic>> tempProds = [];

    for (final p in prods) {
      int basePrice = 0;
      try {
        basePrice = await widget.controller.pricingEngine.resolvePrice(
          produtoId: p.id,
          quantidade: 1,
        );
      } catch (_) {
        basePrice = 0;
      }

      final category = cats.firstWhere(
        (c) => c.id == p.categoriaId,
        orElse: () => Categoria(
          id: p.categoriaId,
          tenantId: p.tenantId,
          nome: 'Outros',
          descricao: '',
          ordemExibicao: 99,
          ativo: true,
          metadata: p.metadata,
        ),
      );

      tempProds.add({
        'id': p.id,
        'sku': p.codigo ?? (p.id.length > 5 ? p.id.substring(0, 5) : p.id),
        'name': p.nome,
        'price': basePrice,
        'category': category.nome,
      });
    }

    setState(() {
      _categories = ['Todos', ...catNames];
      _catalogProducts.clear();
      _catalogProducts.addAll(tempProds);
      _filteredProducts = List.from(_catalogProducts);
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    _applyFilters(widget.searchController.text);
  }

  void _applyFilters(String query) {
    setState(() {
      var temp = _catalogProducts;

      // 1. Filtrar por Categoria
      if (_selectedCategory != 'Todos') {
        temp = temp.where((p) => p['category'].toString().toLowerCase() == _selectedCategory.toLowerCase()).toList();
      }

      // 2. Filtrar por busca de texto
      if (query.isNotEmpty) {
        temp = temp.where((p) {
          final nameMatches = p['name'].toString().toLowerCase().contains(query.toLowerCase());
          final skuMatches = p['sku'].toString().toLowerCase().contains(query.toLowerCase());
          final idMatches = p['id'].toString() == query;
          return nameMatches || skuMatches || idMatches;
        }).toList();
      }

      _filteredProducts = temp;
    });
  }

  /// Abre o diálogo numérico de quantidade e adiciona o item ao carrinho
  Future<void> _abrirDialogQuantidade(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    final qty = await showDialog<double>(
      context: context,
      builder: (ctx) => _QuantidadeDialog(
        nomeProduto: product['name'].toString(),
        precoUnitario: product['price'] as int,
      ),
    );
    if (qty != null && qty > 0) {
      widget.controller.addItem(
        product['id'].toString(),
        product['name'].toString(),
        product['price'] as int,
        qty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha de Busca e Filtro de Categoria
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.searchFocusNode.hasFocus ? FincoreColors.primary : FincoreColors.border,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    focusNode: widget.searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Pesquise por nome ou SKU do produto [F1]',
                      hintStyle: TextStyle(color: FincoreColors.textMuted),
                      prefixIcon: Icon(Icons.search, color: FincoreColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filtro por Categoria (Chips horizontais)
        if (!_isLoading)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(cat),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                          _applyFilters(widget.searchController.text);
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),

        // Grid de Produtos ou Skeleton de Carregamento
        Expanded(
          child: _isLoading
              ? _buildSkeletonGrid()
              : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      itemCount: _filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.40,
                      ),
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return InkWell(
                          // Toque: abre diálogo de quantidade
                          onTap: () => _abrirDialogQuantidade(context, product),
                          // Long press: adiciona 1 unidade diretamente (atalho rápido)
                          onLongPress: () {
                            widget.controller.addItem(
                              product['id'].toString(),
                              product['name'].toString(),
                              product['price'] as int,
                              1.0,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FincoreColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: FincoreColors.background,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product['sku'].toString(),
                                        style: const TextStyle(
                                          color: FincoreColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        product['category'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: FincoreColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ),
                                Text(
                                  product['name'].toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FincoreColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product['price'] > 0
                                          ? 'R\$ ${((product['price'] as int) / 100).toStringAsFixed(2)}'
                                          : 'Sob consulta',
                                      style: const TextStyle(
                                        color: FincoreColors.accent,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    // Ícone de dica
                                    const Tooltip(
                                      message: 'Toque: digitar quantidade\nSegure: +1 unidade',
                                      child: Icon(Icons.touch_app_outlined, size: 14, color: FincoreColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }


  Widget _buildSkeletonGrid() {
    return GridView.builder(
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.40,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          padding: const EdgeInsets.all(10),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(width: 50, height: 16),
                  SkeletonLoader(width: 70, height: 12),
                ],
              ),
              SkeletonLoader(width: 120, height: 16),
              SkeletonLoader(width: 60, height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: FincoreColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(color: FincoreColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;

  const SkeletonLoader({super.key, required this.width, required this.height});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_animController.value * 0.4),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: FincoreColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

// ─── Diálogo Numérico de Quantidade ──────────────────────────────────────────

/// Diálogo com teclado numérico para informar quantidade rapidamente.
/// Toque → digitar qualquer número (ex: 500)
/// Confirma com [OK] ou Enter.
class _QuantidadeDialog extends StatefulWidget {
  final String nomeProduto;
  final int precoUnitario;

  const _QuantidadeDialog({
    required this.nomeProduto,
    required this.precoUnitario,
  });

  @override
  State<_QuantidadeDialog> createState() => _QuantidadeDialogState();
}

class _QuantidadeDialogState extends State<_QuantidadeDialog> {
  String _input = '';

  void _press(String digit) {
    setState(() {
      if (_input.length < 6) _input += digit;
    });
  }

  void _backspace() {
    setState(() {
      if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
    });
  }

  void _clear() {
    setState(() => _input = '');
  }

  void _confirm() {
    final qty = double.tryParse(_input);
    if (qty != null && qty > 0) {
      Navigator.of(context).pop(qty);
    }
  }

  double get _subtotal {
    final qty = double.tryParse(_input) ?? 0;
    return (qty * widget.precoUnitario) / 100;
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = _input.isNotEmpty;
    final qty = double.tryParse(_input) ?? 0;

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUANTIDADE',
                        style: TextStyle(
                          color: FincoreColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.nomeProduto,
                        style: const TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Display do número
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasInput ? FincoreColors.accent : FincoreColors.border,
                  width: hasInput ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    hasInput ? _input : '0',
                    style: TextStyle(
                      color: hasInput ? FincoreColors.textPrimary : FincoreColors.textMuted,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (hasInput && qty > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Subtotal: R\$ ${_subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: FincoreColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Teclado numérico
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: [
                ...[
                  '7', '8', '9',
                  '4', '5', '6',
                  '1', '2', '3',
                ].map((d) => _NumKey(
                  label: d,
                  onTap: () => _press(d),
                )),
                _NumKey(
                  label: 'C',
                  onTap: _clear,
                  color: const Color(0xFFEF4444),
                ),
                _NumKey(
                  label: '0',
                  onTap: () => _press('0'),
                ),
                _NumKey(
                  icon: Icons.backspace_outlined,
                  onTap: _backspace,
                  color: FincoreColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Atalhos rápidos de quantidade
            Row(
              children: [
                for (final q in [25, 50, 100, 200])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _input = q.toString());
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FincoreColors.textSecondary,
                          side: BorderSide(
                            color: _input == q.toString()
                                ? FincoreColors.accent
                                : FincoreColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          '+$q',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Botão confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasInput && qty > 0 ? _confirm : null,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(
                  hasInput && qty > 0
                      ? 'Adicionar $qty unidade${qty != 1 ? 's' : ''}'
                      : 'Informe a quantidade',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  disabledBackgroundColor: FincoreColors.border,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  const _NumKey({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FincoreColors.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: color ?? FincoreColors.textPrimary, size: 20)
                : Text(
                    label!,
                    style: TextStyle(
                      color: color ?? FincoreColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
