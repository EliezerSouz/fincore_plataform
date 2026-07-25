import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/pdv_express_controller.dart';
import 'widgets/pix_payment_modal.dart';

class PdvExpressScreen extends StatefulWidget {
  const PdvExpressScreen({super.key});

  @override
  State<PdvExpressScreen> createState() => _PdvExpressScreenState();
}

class _PdvExpressScreenState extends State<PdvExpressScreen> {
  late final PdvExpressController _controller;
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // Produtos Mockados para o Catálogo (Conforme o MVP da Salgaderia)
  final List<Map<String, dynamic>> _catalogProducts = [
    {'id': '101', 'name': 'Coxinha de Frango', 'price': 600, 'category': 'Salgados'},
    {'id': '102', 'name': 'Kibe Especial', 'price': 550, 'category': 'Salgados'},
    {'id': '103', 'name': 'Bolinho de Queijo', 'price': 500, 'category': 'Salgados'},
    {'id': '104', 'name': 'Empada de Palmito', 'price': 650, 'category': 'Salgados'},
    {'id': '201', 'name': 'Coca-Cola 350ml', 'price': 500, 'category': 'Bebidas'},
    {'id': '202', 'name': 'Suco de Laranja 500ml', 'price': 700, 'category': 'Bebidas'},
    {'id': '301', 'name': 'Mini Churros Lote 10', 'price': 1200, 'category': 'Doces'},
  ];

  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _controller = PdvExpressController();
    _filteredProducts = List.from(_catalogProducts);
    _controller.addListener(_onControllerChanged);
    
    // Focar teclado automaticamente para escutar atalhos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _keyboardFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    if (_controller.state == PdvState.completed) {
      _showSuccessNotification();
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_catalogProducts);
      } else {
        _filteredProducts = _catalogProducts
            .where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase()) || p['id'].toString() == query)
            .toList();
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;

      if (logicalKey == LogicalKeyboardKey.f1) {
        // Atalho F1: Pesquisa de Itens
        _searchFocusNode.requestFocus();
      } else if (logicalKey == LogicalKeyboardKey.f2) {
        // Atalho F2: Inserir Cliente
        _showCustomerDialog();
      } else if (logicalKey == LogicalKeyboardKey.f3) {
        // Atalho F3: Fluxo de Pagamento
        if (_controller.cart.isNotEmpty) {
          _controller.startCheckout();
        }
      } else if (logicalKey == LogicalKeyboardKey.f9) {
        // Atalho F9: Reimprimir Cupom
        _showReimprimirToast();
      } else if (logicalKey == LogicalKeyboardKey.f12) {
        // Atalho F12: Confirmar Venda
        if (_controller.state == PdvState.selectingPayment) {
          _controller.confirmPayment();
        }
      } else if (logicalKey == LogicalKeyboardKey.escape) {
        // Atalho ESC: Cancelar / Resetar
        _controller.reset();
        _keyboardFocusNode.requestFocus();
      }
    }
  }

  void _showCustomerDialog() {
    final nameCont = TextEditingController(text: _controller.customerName);
    final phoneCont = TextEditingController(text: _controller.customerPhone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text('IDENTIFICAR CLIENTE (F2)', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCont,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome do Cliente',
                  labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCont,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (Ex: 11999999999)',
                  labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
              onPressed: () {
                if (phoneCont.text.isNotEmpty) {
                  _controller.selectCustomer(nameCont.text.isEmpty ? 'Consumidor' : nameCont.text, phoneCont.text);
                }
                Navigator.pop(context);
                _keyboardFocusNode.requestFocus();
              },
              child: const Text('CONFIRMAR'),
            )
          ],
        );
      },
    );
  }

  void _showSuccessNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981), // Verde Esmeralda
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Venda de R\$ ${(_controller.totalInCents / 100).toStringAsFixed(2)} processada e enviada ao Spooler Térmico USB!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DESFAZER',
          textColor: Colors.white,
          onPressed: () {
            _controller.reset();
            _keyboardFocusNode.requestFocus();
          },
        ),
      ),
    );
    _controller.reset();
    _keyboardFocusNode.requestFocus();
  }

  void _showReimprimirToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF06B6D4), // Cyan
        content: Text('Comando de Reimpressão enviado para a impressora USB de etiquetas!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF121214), // Dark background
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Row(
              children: [
                // Painel Esquerdo: Catálogo de Produtos
                Expanded(
                  flex: 3,
                  child: _buildCatalogPanel(),
                ),
                // Divisor Vertical Estético
                Container(
                  width: 2,
                  color: const Color(0xFF1E1E24),
                ),
                // Painel Direito: Carrinho de Compras e Finalização
                Expanded(
                  flex: 2,
                  child: _buildCartPanel(),
                ),
              ],
            ),
            
            // Modal de Pagamento PIX (Sobreposição se aguardando PIX)
            if (_controller.state == PdvState.awaitingPix)
              PixPaymentModal(controller: _controller),
          ],
        ),
        bottomNavigationBar: _buildShortcutFooter(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E24),
      elevation: 0,
      title: Row(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316), // Laranja Forno
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FINCORE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Food service PDV Express',
            style: TextStyle(fontSize: 16, color: Color(0xFFF3F4F6), fontWeight: FontWeight.w300),
          ),
        ],
      ),
      actions: [
        // Badge reativo de Conectividade (Offline-First)
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981)), // Green
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, color: Color(0xFF10B981), size: 16),
              SizedBox(width: 6),
              Text(
                'LOCAL - SYNC OK',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCatalogPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATÁLOGO DE PRODUTOS',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          
          // Campo de Busca com foco Laranja Forno (2px se ativo)
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {});
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _searchFocusNode.hasFocus ? const Color(0xFFF97316) : const Color(0xFF2E2E38),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white),
                onChanged: _filterProducts,
                decoration: const InputDecoration(
                  hintText: 'Digite o nome ou ID do produto [F1]',
                  hintStyle: TextStyle(color: Color(0xFF4B5563)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF4B5563)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Grid de Cards de Produtos
          Expanded(
            child: GridView.builder(
              itemCount: _filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return InkWell(
                  onTap: () {
                    _controller.addItem(
                      product['id'].toString(),
                      product['name'].toString(),
                      product['price'] as int,
                      1.0,
                    );
                    _keyboardFocusNode.requestFocus();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24), // Surface slate
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E2E38)),
                    ),
                    padding: const EdgeInsets.all(16),
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
                                color: const Color(0xFF121214),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product['id'].toString(),
                                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              product['category'].toString().toUpperCase(),
                              style: const TextStyle(color: Color(0xFFF97316), fontSize: 10, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        Text(
                          product['name'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$ ${((product['price'] as int) / 100).toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 15, fontWeight: FontWeight.w900), // Cyan
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCartPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARRINHO DE COMPRAS',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 16),
          
          // Cliente Identificado
          if (_controller.customerPhone != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF97316), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFFF97316), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.customerName ?? 'Consumidor',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          _controller.customerPhone!,
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    onPressed: () {
                      setState(() {
                        _controller.clearCustomer();
                      });
                    },
                  )
                ],
              ),
            ),
          
          // Itens no Carrinho
          Expanded(
            child: _controller.cart.isEmpty
                ? const Center(
                    child: Text(
                      'Carrinho vazio.\nAdicione produtos pelo catálogo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: _controller.cart.length,
                    itemBuilder: (context, index) {
                      final item = _controller.cart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity.toInt()}x R\$ ${(item.priceInCents / 100).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                  )
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'R\$ ${(item.totalInCents / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    _controller.updateQuantity(item.productId, item.quantity - 1);
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          const Divider(color: Color(0xFF1E1E24), thickness: 2, height: 32),
          
          // Seção de Total e Finalização
          if (_controller.state == PdvState.selectingPayment) ...[
            const Text(
              'FORMA DE PAGAMENTO (F12 para Confirmar)',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPaymentOption('Dinheiro', Icons.money),
                const SizedBox(width: 8),
                _buildPaymentOption('PIX', Icons.qr_code),
                const SizedBox(width: 8),
                _buildPaymentOption('Cartão', Icons.credit_card),
              ],
            ),
            const SizedBox(height: 20),
          ],
          
          // Painel de Total Geral
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121214),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E1E24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL GERAL',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'R\$ ${(_controller.totalInCents / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w900, fontSize: 24),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botão de Finalizar Venda
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316), // Laranja Forno
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (_controller.state == PdvState.selectingPayment) {
                  _controller.confirmPayment();
                } else if (_controller.cart.isNotEmpty) {
                  _controller.startCheckout();
                }
              },
              child: Text(
                _controller.state == PdvState.selectingPayment ? 'CONFIRMAR PAGAMENTO [F12]' : 'FINALIZAR VENDA [F3]',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    final isSelected = _controller.paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          _controller.setPaymentMethod(method);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF97316) : const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFF97316) : const Color(0xFF2E2E38)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF9CA3AF), size: 20),
              const SizedBox(height: 4),
              Text(
                method,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutFooter() {
    return Container(
      color: const Color(0xFF1E1E24),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('[F1] Buscar Item', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Text('[F2] Add Cliente', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Text('[F3] Pagamento', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Text('[F9] Reimprimir Spooler', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Text('[F12] Confirmar Venda', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Text('[ESC] Limpar/Sair', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        ],
      ),
    );
  }
}
