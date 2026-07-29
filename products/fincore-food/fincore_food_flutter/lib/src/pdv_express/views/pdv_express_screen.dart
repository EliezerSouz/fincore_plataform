import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:flutter/services.dart';
import '../controllers/pdv_express_controller.dart';
import 'widgets/pix_payment_modal.dart';
import 'widgets/stepper_header.dart';
import 'widgets/customer_step.dart';
import 'widgets/product_catalog_step.dart';
import 'widgets/payment_step.dart';
import 'widgets/order_summary_panel.dart';
import 'comprovante_pedido_page.dart';

class PdvExpressScreen extends StatefulWidget {
  final bool isEmbedded;
  const PdvExpressScreen({super.key, this.isEmbedded = false});

  @override
  State<PdvExpressScreen> createState() => _PdvExpressScreenState();
}

class _PdvExpressScreenState extends State<PdvExpressScreen>
    with TickerProviderStateMixin {
  late final PdvExpressController _controller;
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _wasCompleted = false;

  // ── Animação de Shake (atalho inválido — PRD-006) ────────────────
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ── Tecla ativa para feedback visual no footer ────────────────────
  String? _activaKeyLabel;

  @override
  void initState() {
    super.initState();
    _controller = PdvExpressController();
    _controller.addListener(_onControllerChanged);

    // Shake: 200ms horizontal (conforme Motion Guidelines PRD-006)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

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
    _shakeController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    if (_controller.state == PdvState.completed) {
      if (!_wasCompleted) {
        _wasCompleted = true;
        _showSuccessNotification();
      }
    } else {
      _wasCompleted = false;
    }
  }

  // ── Feedback visual temporário de tecla pressionada ──────────────
  void _flashKeyLabel(String label) {
    setState(() => _activaKeyLabel = label);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _activaKeyLabel = null);
    });
  }

  // ── Shake de feedback para ação inválida (PRD-006) ────────────────
  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  // ── Handler Central de Atalhos de Teclado ────────────────────────
  // Mapa de atalhos conforme Épico I — Task 1.2 (PRD-008) e PRD-006
  void _handleKeyEvent(KeyEvent event) async {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // F1 — Ir para Catálogo de Produtos e focar busca
    if (key == LogicalKeyboardKey.f1) {
      _flashKeyLabel('F1');
      _controller.setPassoAtual(1);
      _searchFocusNode.requestFocus();
    }
    // F2 — Ir para Identificação do Cliente
    else if (key == LogicalKeyboardKey.f2) {
      _flashKeyLabel('F2');
      _controller.setPassoAtual(0);
      _keyboardFocusNode.requestFocus();
    }
    // F3 — Ir direto para Pagamento
    else if (key == LogicalKeyboardKey.f3) {
      _flashKeyLabel('F3');
      _controller.setPassoAtual(2);
      _keyboardFocusNode.requestFocus();
    }
    // F4 — Avançar para próxima etapa (sequencial)
    else if (key == LogicalKeyboardKey.f4) {
      _flashKeyLabel('F4');
      _avancarPasso();
    }
    // F5 — Voltar para etapa anterior
    else if (key == LogicalKeyboardKey.f5) {
      _flashKeyLabel('F5');
      _voltarPasso();
    }
    // F9 — Reimprimir cupom do último pedido
    else if (key == LogicalKeyboardKey.f9) {
      _flashKeyLabel('F9');
      _showReimprimirToast();
    }
    // F12 — Confirmar Venda / Finalizar pagamento (PRD-006: F12 dispara AguardandoPIX)
    else if (key == LogicalKeyboardKey.f12) {
      _flashKeyLabel('F12');
      if (_controller.passoAtual == 2 || _controller.state == PdvState.selectingPayment) {
        _controller.confirmPayment();
      } else if (!_controller.podeAvancar()) {
        _triggerShake();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('F12: Preencha a etapa atual antes de confirmar.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _avancarPasso();
      }
    }
    // ESC — Resetar completamente o PDV com confirmação
    else if (key == LogicalKeyboardKey.escape) {
      _flashKeyLabel('ESC');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Limpar Pedido', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: const Text('Tem certeza que deseja cancelar e limpar o pedido atual?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Limpar Tudo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (ok == true) {
        _controller.reset();
      }
      _keyboardFocusNode.requestFocus();
    }
  }

  void _avancarPasso() {
    if (_controller.podeAvancar()) {
      if (_controller.passoAtual < 2) {
        _controller.setPassoAtual(_controller.passoAtual + 1);
      } else {
        _controller.confirmPayment();
      }
    } else {
      _triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Text('Por favor, preencha as informações obrigatórias da etapa atual.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _voltarPasso() {
    if (_controller.passoAtual > 0) {
      _controller.setPassoAtual(_controller.passoAtual - 1);
    }
  }

  void _showSuccessNotification() {
    // Abre a tela de comprovante/impressão
    final lastVenda = _controller.lastVenda;
    if (lastVenda != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ComprovantePedidoPage(
            pedidoId: lastVenda.id,
            cliente: _controller.cliente,
            entrega: _controller.entrega,
            itens: _controller.cart.toList(),
            totalCentavos: _controller.totalInCents,
            formaPagamento: _controller.paymentMethod,
          ),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: FincoreColors.success,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Venda de R\$ ${(_controller.totalInCents / 100).toStringAsFixed(2)} processada!',
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
            _controller.undoLastVenda();
            _keyboardFocusNode.requestFocus();
          },
        ),
      ),
    );
    _keyboardFocusNode.requestFocus();
  }

  void _showReimprimirToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: FincoreColors.accent,
        content: Text('Comando de Reimpressão enviado para a impressora USB de etiquetas!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStepView() {
    switch (_controller.passoAtual) {
      case 0:
        return CustomerStep(controller: _controller);
      case 1:
        return ProductCatalogStep(
          controller: _controller,
          searchFocusNode: _searchFocusNode,
          searchController: _searchController,
        );
      case 2:
        return PaymentStep(controller: _controller);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      // Shake aplica-se ao corpo principal (AnimatedBuilder, PRD-006 Motion)
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        ),
        child: Scaffold(
          backgroundColor: widget.isEmbedded ? Colors.transparent : FincoreColors.background,
          appBar: widget.isEmbedded ? null : _buildAppBar(),
          body: Stack(
            children: [
              Row(
                children: [
                  // ── Coluna Esquerda: Wizard de Etapas ──────────────
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // StepperHeader com borda de foco Laranja Forno (PRD-006)
                          _FocusedBorderWrapper(
                            isActive: _keyboardFocusNode.hasFocus,
                            child: StepperHeader(controller: _controller),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: _buildStepView(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Divisor Vertical ──────────────────────────────
                  Container(
                    width: 1.5,
                    color: FincoreColors.border,
                  ),

                  // ── Coluna Direita: Painel Operacional Persistente ─
                  OrderSummaryPanel(
                    controller: _controller,
                    onBack: _voltarPasso,
                    onNext: _avancarPasso,
                  ),
                ],
              ),

              // ── Modal PIX (sobreposição quando aguardando PIX) ──────
              if (_controller.state == PdvState.awaitingPix)
                PixPaymentModal(controller: _controller),
            ],
          ),
          bottomNavigationBar: _buildShortcutFooter(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: FincoreColors.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: FincoreColors.primary,
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
            style: TextStyle(fontSize: 16, color: FincoreColors.textPrimary, fontWeight: FontWeight.w300),
          ),
        ],
      ),
      actions: [
        // Badge de Conectividade Offline-First (PRD-006)
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: FincoreColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.success),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, color: FincoreColors.success, size: 16),
              SizedBox(width: 6),
              Text(
                'LOCAL - SYNC OK',
                style: TextStyle(color: FincoreColors.success, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer de Atalhos (PRD-006 — Navegação por Teclado) ──────────
  Widget _buildShortcutFooter() {
    final shortcuts = [
      _ShortcutEntry(key: 'F1', label: 'Catálogo / Buscar'),
      _ShortcutEntry(key: 'F2', label: 'Dados Cliente'),
      _ShortcutEntry(key: 'F3', label: 'Ir p/ Pagamento'),
      _ShortcutEntry(key: 'F4', label: 'Avançar Etapa'),
      _ShortcutEntry(key: 'F5', label: 'Voltar Etapa'),
      _ShortcutEntry(key: 'F9', label: 'Reimprimir'),
      _ShortcutEntry(key: 'F12', label: 'Confirmar Venda'),
      _ShortcutEntry(key: 'ESC', label: 'Limpar/Sair'),
    ];

    return Container(
      color: FincoreColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: shortcuts.map((s) {
          final isActive = _activaKeyLabel == s.key;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              decoration: BoxDecoration(
                // Borda Laranja Forno 2px no atalho ativo (PRD-006)
                border: Border.all(
                  color: isActive ? FincoreColors.primary : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                color: isActive
                    ? FincoreColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? FincoreColors.primary : FincoreColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.key,
                      style: TextStyle(
                        color: isActive ? Colors.white : FincoreColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? FincoreColors.primary : FincoreColors.textMuted,
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Wrapper de Borda de Foco Laranja Forno 2px (PRD-006) ───────────
// Exibe a borda laranja ao redor do elemento quando o teclado está ativo,
// sinalizando ao operador que os atalhos estão prontos para uso.
class _FocusedBorderWrapper extends StatelessWidget {
  final bool isActive;
  final Widget child;

  const _FocusedBorderWrapper({
    required this.isActive,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // Borda Laranja Forno 2px no modo de teclado ativo (PRD-006)
          color: isActive ? FincoreColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

// ── Model de dados do footer de atalhos ──────────────────────────────
class _ShortcutEntry {
  final String key;
  final String label;
  const _ShortcutEntry({required this.key, required this.label});
}
