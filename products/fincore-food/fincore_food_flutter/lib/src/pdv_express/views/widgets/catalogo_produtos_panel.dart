import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';

/// Coluna 2 da Workstation: Catálogo de Produtos & Ações Rápidas
/// Exibe a busca global [F2], categorias reais, grade de alta densidade
/// e atalhos rápidos de quantidade (+1, +10, +25, +50, +100).
class CatalogoProdutosPanel extends StatefulWidget {
  final PdvExpressController controller;
  final FocusNode searchFocusNode;
  final TextEditingController searchController;

  const CatalogoProdutosPanel({
    super.key,
    required this.controller,
    required this.searchFocusNode,
    required this.searchController,
  });

  @override
  State<CatalogoProdutosPanel> createState() => _CatalogoProdutosPanelState();
}

class _CatalogoProdutosPanelState extends State<CatalogoProdutosPanel> {
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
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.products.length != _catalogProducts.length) {
      _loadProductsAndCategories();
    }
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
      // 1. Verificar a flag de herança do produto
      bool herdar = true;
      double? customPreco;
      if (p.metadataPayload != null && p.metadataPayload!.isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(p.metadataPayload!);
          herdar = jsonMap['herdar_categoria'] ?? true;
          final precoBaseVal = jsonMap['preco_base'];
          if (precoBaseVal != null) {
            customPreco = (precoBaseVal as num).toDouble();
          }
        } catch (_) {}
      }

      // 2. Determinar o preço base (herança ou customizado)
      double? basePriceDouble;
      if (herdar) {
        final cat = cats.cast<Categoria?>().firstWhere((c) => c?.id == p.categoriaId, orElse: () => null);
        if (cat != null && cat.metadataPayload != null && cat.metadataPayload!.isNotEmpty) {
          try {
            final Map<String, dynamic> jsonMap = jsonDecode(cat.metadataPayload!);
            final precoBaseVal = jsonMap['preco_base'];
            if (precoBaseVal != null) {
              basePriceDouble = (precoBaseVal as num).toDouble();
            }
          } catch (_) {}
        }
        basePriceDouble ??= customPreco;
      } else {
        basePriceDouble = customPreco;
      }

      // 3. Resolver preço em centavos
      int basePrice = 0;
      if (basePriceDouble != null) {
        basePrice = (basePriceDouble * 100).round();
      } else {
        try {
          basePrice = await widget.controller.pricingEngine.resolvePrice(
            produtoId: p.id,
            quantidade: 1,
          );
        } catch (_) {
          basePrice = 150;
        }
      }
      if (basePrice <= 0) {
        basePrice = 150;
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

      final stockVal = widget.controller.estoqueMap[p.id];
      final stockInfo = widget.controller.stockDetailsMap[p.id];

      tempProds.add({
        'id': p.id,
        'sku': p.codigo ?? (p.id.length > 5 ? p.id.substring(0, 5) : p.id),
        'name': p.nome,
        'description': p.descricao ?? '',
        'price': basePrice,
        'category': category.nome,
        'categoryIcon': category.icone,
        'categoryColor': category.cor,
        'image': p.imagem,
        'stock': stockVal,
        'stockInfo': stockInfo,
        'controlaEstoque': p.controlaEstoque,
      });
    }

    if (mounted) {
      setState(() {
        _categories = ['Todos', ...catNames];
        _catalogProducts.clear();
        _catalogProducts.addAll(tempProds);
        _filteredProducts = List.from(_catalogProducts);
        _isLoading = false;
      });
      _applyFilters(widget.searchController.text);
    }
  }

  void _onSearchChanged() {
    _applyFilters(widget.searchController.text);
  }

  void _applyFilters(String query) {
    if (!mounted) return;
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

  Future<void> _abrirDialogQuantidade(BuildContext context, Map<String, dynamic> product) async {
    final qty = await showDialog<double>(
      context: context,
      builder: (ctx) => _QuantidadeCustomDialog(
        nomeProduto: product['name'].toString(),
        precoUnitario: product['price'] as int,
      ),
    );
    if (qty != null && qty > 0) {
      await widget.controller.addItem(
        product['id'].toString(),
        product['name'].toString(),
        product['price'] as int,
        qty,
      );
    }
  }

  Future<void> _adicionarRapido(Map<String, dynamic> product, double qty) async {
    await widget.controller.addItem(
      product['id'].toString(),
      product['name'].toString(),
      product['price'] as int,
      qty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho de Busca & Filtro de Categorias ───────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FincoreColors.border)),
            ),
            child: Column(
              children: [
                // Barra de Busca
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.searchFocusNode.hasFocus
                                ? FincoreColors.primary
                                : FincoreColors.border,
                            width: widget.searchFocusNode.hasFocus ? 1.5 : 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: widget.searchController,
                          focusNode: widget.searchFocusNode,
                          style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Buscar produto por nome, SKU ou código... [F2]',
                            hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                            prefixIcon: const Icon(Icons.search, color: FincoreColors.textSecondary, size: 18),
                            suffixIcon: widget.searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16, color: FincoreColors.textMuted),
                                    onPressed: () {
                                      widget.searchController.clear();
                                      _applyFilters('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Categorias Rápidas em Chips Horizontais
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _applyFilters(widget.searchController.text);
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FincoreColors.primary.withValues(alpha: 0.15)
                                : FincoreColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? FincoreColors.primary : FincoreColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Grade de Produtos de Alta Densidade ──────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 40, color: FincoreColors.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              widget.searchController.text.isNotEmpty
                                  ? 'Nenhum produto encontrado para "${widget.searchController.text}"'
                                  : 'Nenhum produto cadastrado nesta categoria.',
                              style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredProducts.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.88,
                        ),
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _ProductWorkstationCard(
                            product: product,
                            onTap: () => _abrirDialogQuantidade(context, product),
                            onAddQuick: (qty) => _adicionarRapido(product, qty),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Card de Alta Densidade do Produto com Atalhos de Quantidade Integrados
class _ProductWorkstationCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final ValueChanged<double> onAddQuick;

  const _ProductWorkstationCard({
    required this.product,
    required this.onTap,
    required this.onAddQuick,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'].toString();
    final priceCents = product['price'] as int;
    final priceStr = 'R\$ ${(priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
    final imgUrl = product['image'] as String?;
    final hasImg = imgUrl != null && imgUrl.trim().isNotEmpty;

    final stockInfo = product['stockInfo'] as StockInfo?;
    final controlaEstoque = product['controlaEstoque'] as bool? ?? false;
    final double stockProjVal = stockInfo?.projetado ?? (product['stock'] as double? ?? 0.0);
    final stockProjStr = stockProjVal % 1 == 0 ? stockProjVal.toStringAsFixed(0) : stockProjVal.toStringAsFixed(1);

    final catIconKey = product['categoryIcon'] as String?;
    final catColorHex = product['categoryColor'] as String?;
    final iconData = _resolveCategoryIcon(catIconKey);
    final catColor = _resolveCategoryColor(catColorHex);

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Área Superior Clicável (Foto + Nome + Preço)
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Miniatura / Ícone da Categoria
                    Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: hasImg ? FincoreColors.surface : catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasImg ? FincoreColors.border : catColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: hasImg
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                iconData,
                                color: catColor,
                                size: 22,
                              ),
                            )
                          : Icon(
                              iconData,
                              color: catColor,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 8),

                    // Nome e Preço
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: FincoreColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            priceStr,
                            style: TextStyle(
                              color: FincoreColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (controlaEstoque) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Disp: $stockProjStr un',
                              style: const TextStyle(
                                color: FincoreColors.textMuted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barra Inferior de Inclusão Rápida (+1, +10, +25, +50, +100)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: const BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(top: BorderSide(color: FincoreColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickBtn('+1', 1.0),
                _buildQuickBtn('+10', 10.0),
                _buildQuickBtn('+25', 25.0),
                _buildQuickBtn('+50', 50.0),
                _buildQuickBtn('+100', 100.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(String label, double qty) {
    return InkWell(
      onTap: () => onAddQuick(qty),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: FincoreColors.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: FincoreColors.textPrimary,
          ),
        ),
      ),
    );
  }

  IconData _resolveCategoryIcon(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) return Icons.fastfood_outlined;
    const map = {
      'fastfood': Icons.fastfood_outlined,
      'local_pizza': Icons.local_pizza_outlined,
      'lunch_dining': Icons.lunch_dining_outlined,
      'local_bar': Icons.local_bar_outlined,
      'icecream': Icons.icecream_outlined,
      'bakery_dining': Icons.bakery_dining_outlined,
      'restaurant': Icons.restaurant_outlined,
      'coffee': Icons.coffee_outlined,
      'set_meal': Icons.set_meal_outlined,
      'local_cafe': Icons.local_cafe_outlined,
      'cake': Icons.cake_outlined,
      'ramen_dining': Icons.ramen_dining_outlined,
      'liquor': Icons.liquor_outlined,
      'local_drink': Icons.local_drink_outlined,
      'shopping_bag': Icons.shopping_bag_outlined,
      'dinner_dining': Icons.dinner_dining_outlined,
    };
    return map[iconKey] ?? Icons.fastfood_outlined;
  }

  Color _resolveCategoryColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return FincoreColors.primary;
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return FincoreColors.primary;
    }
  }
}

/// Diálogo Numérico com Teclado para Quantidade Customizada
/// Diálogo de Quantidade com Digitação Direta via Teclado Físico (Padrão Desktop Ágil)
class _QuantidadeCustomDialog extends StatefulWidget {
  final String nomeProduto;
  final int precoUnitario;

  const _QuantidadeCustomDialog({
    required this.nomeProduto,
    required this.precoUnitario,
  });

  @override
  State<_QuantidadeCustomDialog> createState() => _QuantidadeCustomDialogState();
}

class _QuantidadeCustomDialogState extends State<_QuantidadeCustomDialog> {
  late final TextEditingController _textCtrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: '1');
    // Seleciona todo o texto para que a primeira tecla digitada substitua o '1' imediatamente
    _textCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _textCtrl.text.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _textCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _textCtrl.text.length);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  double _getQuantidadeAtual() {
    final clean = _textCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }

  void _ajustarQuantidade(double delta) {
    final atual = _getQuantidadeAtual();
    final nova = (atual + delta).clamp(1.0, 9999.0);
    final textoFormatado = nova % 1 == 0 ? nova.toStringAsFixed(0) : nova.toStringAsFixed(2);
    setState(() {
      _textCtrl.text = textoFormatado;
      _textCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _textCtrl.text.length);
    });
  }

  void _definirQuantidade(double valor) {
    final textoFormatado = valor % 1 == 0 ? valor.toStringAsFixed(0) : valor.toStringAsFixed(2);
    setState(() {
      _textCtrl.text = textoFormatado;
      _textCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _textCtrl.text.length);
    });
  }

  void _confirmar() {
    final qty = _getQuantidadeAtual();
    if (qty > 0) {
      Navigator.of(context).pop(qty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = _getQuantidadeAtual();
    final totalCentavos = (qty * widget.precoUnitario).round();
    final totalStr = 'R\$ ${(totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';
    final precoUnitStr = 'R\$ ${(widget.precoUnitario / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop(null);
          }
        }
      },
      child: AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nomeProduto,
              style: const TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$precoUnitStr por unidade',
              style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Campo Principal com foco direto do Teclado
              Row(
                children: [
                  IconButton(
                    onPressed: () => _ajustarQuantidade(-1),
                    icon: const Icon(Icons.remove_circle_outline, color: FincoreColors.textSecondary, size: 28),
                    tooltip: 'Diminuir (-1)',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantidade',
                        floatingLabelAlignment: FloatingLabelAlignment.center,
                        labelStyle: TextStyle(color: FincoreColors.primary, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        filled: true,
                        fillColor: FincoreColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: FincoreColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _confirmar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _ajustarQuantidade(1),
                    icon: Icon(Icons.add_circle_outline, color: FincoreColors.primary, size: 28),
                    tooltip: 'Aumentar (+1)',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Atalhos Rápidos com Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [2.0, 5.0, 10.0, 15.0, 20.0, 50.0].map((val) {
                  return ActionChip(
                    label: Text(
                      val % 1 == 0 ? '${val.toInt()}' : val.toString(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: FincoreColors.surfaceElevated,
                    side: const BorderSide(color: FincoreColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    onPressed: () => _definirQuantidade(val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Total Calculado em Tempo Real
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal do item:',
                      style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      totalStr,
                      style: TextStyle(
                        color: FincoreColors.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'Dica: Digite pelo teclado e aperte [Enter] para confirmar',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar [Esc]', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirmar [Enter]', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _confirmar,
          ),
        ],
      ),
    );
  }
}
