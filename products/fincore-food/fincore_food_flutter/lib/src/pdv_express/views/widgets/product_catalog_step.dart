import 'dart:convert';
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
        // Tentar pricing engine
        try {
          basePrice = await widget.controller.pricingEngine.resolvePrice(
            produtoId: p.id,
            quantidade: 1,
          );
        } catch (_) {
          basePrice = 150; // default 1.50
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
        'image': p.imagem,
        'stock': stockVal,
        'stockInfo': stockInfo,
        'controlaEstoque': p.controlaEstoque,
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
                      hintText: 'Pesquise por nome ou SKU do produto [F2]',
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

        // Filtro por Categoria exclusivo (Combobox) + Resumo Projetado do Carrinho
        if (!_isLoading) ...[
          Builder(
            builder: (context) {
              final totalUnits = widget.controller.cart.fold<double>(0, (sum, i) => sum + i.quantity);
              final totalUnitsStr = totalUnits % 1 == 0 ? totalUnits.toStringAsFixed(0) : totalUnits.toStringAsFixed(1);
              final cartSubtotalCents = widget.controller.cart.fold(0, (sum, i) => sum + i.totalInCents);
              final subtotalStr = (cartSubtotalCents / 100).toStringAsFixed(2).replaceAll('.', ',');

              return Row(
                children: [
                  // Dropdown Exclusivo de Categoria
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _categories.contains(_selectedCategory) ? _selectedCategory : 'Todos',
                          dropdownColor: const Color(0xFF1E1E24),
                          icon: Icon(Icons.arrow_drop_down, color: FincoreColors.primary),
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                                _applyFilters(widget.searchController.text);
                              });
                            }
                          },
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat == 'Todos' ? '📂 Todas as Categorias' : '🏷️ $cat'),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Badge do Carrinho Projetado (Total de Itens & Subtotal)
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_basket_outlined, color: FincoreColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'CARRINHO: $totalUnitsStr un | R\$ $subtotalStr',
                          style: TextStyle(
                            color: FincoreColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 16),

        // Grid de Produtos ou Skeleton de Carregamento
        Expanded(
          child: _isLoading
              ? _buildSkeletonGrid()
              : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      itemCount: _filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final name = product['name'].toString();
                        final desc = product['description'].toString();
                        final sku = product['sku'].toString();
                        final category = product['category'].toString();
                        final priceStr = product['price'] > 0
                            ? 'R\$ ${((product['price'] as int) / 100).toStringAsFixed(2)}'
                            : 'R\$ 0,00';

                        final stockInfo = product['stockInfo'] as StockInfo?;
                        final controlaEstoque = product['controlaEstoque'] as bool? ?? false;
                        final double stockProjVal = stockInfo?.projetado ?? (product['stock'] as double? ?? 0.0);
                        final stockProjStr = stockProjVal % 1 == 0 ? stockProjVal.toStringAsFixed(0) : stockProjVal.toStringAsFixed(1);

                        final String stockSummaryLine;
                        if (!controlaEstoque) {
                          stockSummaryLine = 'Estoque: Não controlado';
                        } else {
                          stockSummaryLine = 'Saldo Projetado: $stockProjStr un';
                        }

                        final tooltipMsg = [
                          name,
                          if (desc.isNotEmpty) 'Descrição: $desc',
                          'SKU: $sku | Categoria: $category',
                          stockSummaryLine,
                          if (controlaEstoque && stockInfo != null) ...[
                            '  • Físico: ${stockInfo.fisico % 1 == 0 ? stockInfo.fisico.toStringAsFixed(0) : stockInfo.fisico.toStringAsFixed(1)} un',
                            if (stockInfo.reservado > 0)
                              '  • Reservado p/ entregas: -${stockInfo.reservado % 1 == 0 ? stockInfo.reservado.toStringAsFixed(0) : stockInfo.reservado.toStringAsFixed(1)} un',
                            if (stockInfo.producaoPlanejada > 0)
                              '  • Produção prevista: +${stockInfo.producaoPlanejada % 1 == 0 ? stockInfo.producaoPlanejada.toStringAsFixed(0) : stockInfo.producaoPlanejada.toStringAsFixed(1)} un',
                          ],
                          'Preço: $priceStr',
                        ].join('\n');

                        return Tooltip(
                          message: tooltipMsg,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E28),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: FincoreColors.primary, width: 1.5),
                          ),
                          textStyle: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FincoreColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: InkWell(
                              onTap: () => _abrirDialogQuantidade(context, product),
                              onLongPress: () {
                                widget.controller.addItem(
                                  product['id'].toString(),
                                  product['name'].toString(),
                                  product['price'] as int,
                                  1.0,
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Container Imagem Real do Produto / Fallback + Botão de Info
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final imgUrl = product['image'] as String?;
                                              final hasImg = imgUrl != null && imgUrl.trim().isNotEmpty;
                                              return Container(
                                                width: double.infinity,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(
                                                  color: FincoreColors.background,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: hasImg
                                                    ? Image.network(
                                                        imgUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, stack) => const Center(
                                                          child: Icon(
                                                            Icons.fastfood_outlined,
                                                            color: FincoreColors.textMuted,
                                                            size: 32,
                                                          ),
                                                        ),
                                                      )
                                                    : const Center(
                                                        child: Icon(
                                                          Icons.fastfood_outlined,
                                                          color: FincoreColors.textMuted,
                                                          size: 32,
                                                        ),
                                                      ),
                                              );
                                            },
                                          ),
                                          // Badge de Info com Modal de Detalhes
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    backgroundColor: const Color(0xFF1E1E24),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      side: const BorderSide(color: FincoreColors.border),
                                                    ),
                                                    title: Text(
                                                      name,
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('SKU: $sku | Categoria: $category',
                                                            style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                                                        const SizedBox(height: 10),
                                                        if (controlaEstoque && stockInfo != null) ...[
                                                          Container(
                                                            width: double.infinity,
                                                            padding: const EdgeInsets.all(12),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF141418),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: FincoreColors.border),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    const Text('Físico Atual:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                                                                    Text('${stockInfo.fisico % 1 == 0 ? stockInfo.fisico.toStringAsFixed(0) : stockInfo.fisico.toStringAsFixed(1)} un',
                                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                                  ],
                                                                ),
                                                                if (stockInfo.reservado > 0) ...[
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      const Text('Reservado p/ Entregas:', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                                                      Text('-${stockInfo.reservado % 1 == 0 ? stockInfo.reservado.toStringAsFixed(0) : stockInfo.reservado.toStringAsFixed(1)} un',
                                                                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                                                    ],
                                                                  ),
                                                                ],
                                                                if (stockInfo.producaoPlanejada > 0) ...[
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      const Text('Produção Programada:', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                                                      Text('+${stockInfo.producaoPlanejada % 1 == 0 ? stockInfo.producaoPlanejada.toStringAsFixed(0) : stockInfo.producaoPlanejada.toStringAsFixed(1)} un',
                                                                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                                                    ],
                                                                  ),
                                                                ],
                                                                const SizedBox(height: 6),
                                                                const Divider(color: Color(0xFF2E2E38), height: 1),
                                                                const SizedBox(height: 6),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    const Text('SALDO PROJETADO:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                                                    Text('${stockProjStr} un',
                                                                        style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.w900, fontSize: 13.5)),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                        ] else ...[
                                                          Text('Estoque: $stockSummaryLine',
                                                              style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                                          const SizedBox(height: 10),
                                                        ],
                                                        if (desc.isNotEmpty) ...[
                                                          Text(desc, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                                                          const SizedBox(height: 10),
                                                        ],
                                                        Text('Preço Base: $priceStr',
                                                            style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: Text('OK', style: TextStyle(color: FincoreColors.primary)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.info_outline, size: 16, color: FincoreColors.primary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Nome do Produto (até 2 linhas com Tooltip ao passar o mouse)
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FincoreColors.textPrimary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Preço e Botão Adicionar +
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          priceStr,
                                          style: TextStyle(
                                            color: FincoreColors.primary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: FincoreColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: FincoreColors.primary,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: FincoreColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _focusNode = FocusNode();
    _textCtrl.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirm() {
    final qty = double.tryParse(_textCtrl.text.replaceAll(',', '.'));
    if (qty != null && qty > 0) {
      Navigator.of(context).pop(qty);
    }
  }

  double get _subtotal {
    final qty = double.tryParse(_textCtrl.text.replaceAll(',', '.')) ?? 0;
    return (qty * widget.precoUnitario) / 100;
  }

  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(_textCtrl.text.replaceAll(',', '.')) ?? 0;
    final hasInput = _textCtrl.text.isNotEmpty && qty > 0;

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
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
                        'QUANTIDADE DO SALGADO',
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

            // Campo Digitável Principal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasInput ? FincoreColors.accent : FincoreColors.border,
                  width: hasInput ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final current = double.tryParse(_textCtrl.text) ?? 0;
                      if (current > 1) {
                        final next = (current - 1).toInt();
                        _textCtrl.text = next.toString();
                      }
                    },
                    icon: const Icon(Icons.remove, color: FincoreColors.textSecondary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onSubmitted: (_) => _confirm(),
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final current = double.tryParse(_textCtrl.text) ?? 0;
                      final next = (current + 1).toInt();
                      _textCtrl.text = next.toString();
                    },
                    icon: const Icon(Icons.add, color: FincoreColors.textSecondary),
                  ),
                ],
              ),
            ),

            if (hasInput) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preço unitário base: R\$ ${(widget.precoUnitario / 100).toStringAsFixed(2)}',
                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    'Subtotal: R\$ ${_subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: FincoreColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Atalhos rápidos de quantidade (25, 50, 100, 200, 250)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ATALHOS RÁPIDOS DE LOTE:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in [25, 50, 100, 200, 250])
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _textCtrl.text = q.toString());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textCtrl.text == q.toString()
                          ? Colors.white
                          : FincoreColors.textSecondary,
                      backgroundColor: _textCtrl.text == q.toString()
                          ? FincoreColors.accent.withValues(alpha: 0.2)
                          : Colors.transparent,
                      side: BorderSide(
                        color: _textCtrl.text == q.toString()
                            ? FincoreColors.accent
                            : FincoreColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '$q un',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Botão confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasInput ? _confirm : null,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(
                  hasInput
                      ? 'Adicionar ${qty.toInt()} unidade${qty != 1 ? 's' : ''} ao Pedido'
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
