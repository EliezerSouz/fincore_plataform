import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/pdv_express_controller.dart';
import 'widgets/pix_payment_modal.dart';
import 'widgets/atendimento_destino_panel.dart';
import 'widgets/catalogo_produtos_panel.dart';
import 'widgets/pedido_carrinho_panel.dart';
import 'widgets/confirmacao_agendamento_modal.dart';
import 'widgets/customer_selection_modal.dart';
import 'widgets/dialog_importar_pedido_ia.dart';
import 'package:fincore_core/fincore_core.dart';
import '../../shared/services/whatsapp_service.dart';
import '../../shared/services/pix_generator.dart';
import '../../shared/services/impressao_service.dart';
import '../../shared/presentation/widgets/whatsapp_dialog.dart';
import '../../financeiro/controllers/financeiro_controller.dart';
import '../../financeiro/widgets/dialogs_caixa.dart';
import '../../financeiro/views/fechamento_turno_page.dart';

/// WORKSTATION DE PDV EXPRESS (FASE 1)
/// Arquitetura integrada em 3 colunas simultâneas:
/// [ Atendimento & Destino ] | [ Catálogo & Ações Rápidas ] | [ Pedido, Pagamento & Finalização ]
class PdvExpressScreen extends StatefulWidget {
  final bool isEmbedded;
  final OrdemPreparo? ordemParaEditar;
  final String? repetirPedidoId;
  final Cliente? clienteInicial;
  final VoidCallback? onVoltarOuCancelar;

  const PdvExpressScreen({
    super.key,
    this.isEmbedded = false,
    this.ordemParaEditar,
    this.repetirPedidoId,
    this.clienteInicial,
    this.onVoltarOuCancelar,
  });

  @override
  State<PdvExpressScreen> createState() => _PdvExpressScreenState();
}

class _PdvExpressScreenState extends State<PdvExpressScreen>
    with TickerProviderStateMixin {
  late final PdvExpressController _controller;
  late final FinanceiroController _finCtrl;
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
    _finCtrl = FinanceiroController();
    _finCtrl.addListener(_onFinChanged);

    _controller = PdvExpressController(
      ordemParaEditar: widget.ordemParaEditar,
      repetirPedidoId: widget.repetirPedidoId,
      clienteInicial: widget.clienteInicial,
    );
    _controller.addListener(_onControllerChanged);

    // Injeta callback para pedidos com data retroativa
    _controller.onPedidoRetroativo = (dataRetroativa) => _solicitarJustificativaRetroativo(dataRetroativa);

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

    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _keyboardFocusNode.requestFocus();
      await _verificarAberturaCaixaObrigatoria();
    });
  }

  void _onFinChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _verificarAberturaCaixaObrigatoria() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (!_finCtrl.resumo.caixaAberto && widget.ordemParaEditar == null) {
      if (!mounted) return;
      await DialogAbrirCaixa.show(
        context,
        controller: _finCtrl,
        onConfirm: (val, turno) async {
          await _finCtrl.abrirCaixa(valorAberturaCentavos: val, nomeTurno: turno);
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _finCtrl.removeListener(_onFinChanged);
    _finCtrl.dispose();
    _keyboardFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _abrirMenuOperacoesCaixa() {
    final resumo = _finCtrl.resumo;
    if (!resumo.caixaAberto) {
      DialogAbrirCaixa.show(
        context,
        controller: _finCtrl,
        onConfirm: (val, turno) async {
          await _finCtrl.abrirCaixa(valorAberturaCentavos: val, nomeTurno: turno);
          if (mounted) setState(() {});
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: FincoreColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Operações de Caixa & Turno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              ),
              ListTile(
                leading: const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444)),
                title: const Text('Conferência & Fechamento de Caixa', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  FechamentoTurnoPage.show(context, controller: _finCtrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.output_rounded, color: Color(0xFFEF4444)),
                title: const Text('Registrar Sangria (Retirada de Dinheiro)', style: TextStyle(color: FincoreColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  DialogMovimentoCaixa.show(
                    context,
                    initialTipo: 'sangria',
                    onConfirm: (t, v, d) => _finCtrl.lancarMovimento(tipo: t, valorCentavos: v, descricao: d),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.input_rounded, color: Color(0xFF10B981)),
                title: const Text('Reforço de Troco (Suprimento)', style: TextStyle(color: FincoreColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  DialogMovimentoCaixa.show(
                    context,
                    initialTipo: 'suprimento',
                    onConfirm: (t, v, d) => _finCtrl.lancarMovimento(tipo: t, valorCentavos: v, descricao: d),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;

    // F2 — Focar busca de produtos
    if (key == LogicalKeyboardKey.f2) {
      _flashKeyLabel('F2');
      _focarBuscaProdutos();
      return true;
    }
    // F4 — Buscar/Selecionar Cliente
    else if (key == LogicalKeyboardKey.f4) {
      _flashKeyLabel('F4');
      _abrirModalCliente();
      return true;
    }
    // F6 — Alternar Modalidade (Balcão -> Retirada -> Entrega)
    else if (key == LogicalKeyboardKey.f6) {
      _flashKeyLabel('F6');
      _alternarCicloDestino();
      return true;
    }
    // F7 — Captura Inteligente WhatsApp (IA)
    else if (key == LogicalKeyboardKey.f7) {
      _flashKeyLabel('F7');
      _abrirImportadorPedidoIa();
      return true;
    }
    // F8 — Operações de Caixa
    else if (key == LogicalKeyboardKey.f8) {
      _flashKeyLabel('F8');
      _abrirMenuOperacoesCaixa();
      return true;
    }
    // F10 ou F12 — Finalizar/Receber Venda
    else if (key == LogicalKeyboardKey.f10 || key == LogicalKeyboardKey.f12) {
      _flashKeyLabel(key == LogicalKeyboardKey.f10 ? 'F10' : 'F12');
      _processarFinalizacaoVenda();
      return true;
    }
    // ESC — Limpar pedido ou Sair da Edição
    else if (key == LogicalKeyboardKey.escape) {
      if (widget.ordemParaEditar != null) {
        _flashKeyLabel('ESC');
        _confirmarSaidaEdicao();
        return true;
      } else if (_controller.cart.isNotEmpty) {
        _flashKeyLabel('ESC');
        _confirmarLimpezaPedido();
        return true;
      } else if (widget.onVoltarOuCancelar != null) {
        _flashKeyLabel('ESC');
        widget.onVoltarOuCancelar!();
        return true;
      } else if (Navigator.of(context).canPop()) {
        _flashKeyLabel('ESC');
        Navigator.of(context).pop(false);
        return true;
      }
    }
    return false;
  }

  void _abrirImportadorPedidoIa() {
    DialogImportarPedidoIa.show(context, controller: _controller);
  }

  Future<void> _confirmarSaidaEdicao() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 24),
            SizedBox(width: 10),
            Text('Sair do Modo de Edição?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'As alterações deste pedido não salvas serão descartadas.\nDeseja realmente voltar para a Central de Pedidos?',
          style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar Editando', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair da Edição', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (widget.onVoltarOuCancelar != null) {
        widget.onVoltarOuCancelar!();
      } else if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(false);
      }
    }
  }

  void _focarBuscaProdutos() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  Future<void> _abrirModalCliente() async {
    await showDialog(
      context: context,
      builder: (ctx) => CustomerSelectionModal(controller: _controller),
    );
    if (mounted) {
      setState(() {});
      _focarBuscaProdutos();
    }
  }

  void _alternarCicloDestino() {
    final atual = _controller.entrega.tipo;
    String proximo = 'Balcão';
    if (atual == 'Balcão' || atual == 'Mesa/Balcão') {
      proximo = 'Retirada';
    } else if (atual == 'Retirada') {
      proximo = 'Entrega';
    } else {
      proximo = 'Balcão';
    }
    _controller.updateEntrega(
      _controller.entrega.copyWith(
        tipo: proximo,
        taxaEntregaCentavos: proximo == 'Entrega' ? _controller.entrega.taxaEntregaCentavos : 0,
      ),
    );
  }

  Future<void> _confirmarLimpezaPedido() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpar Pedido', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza que deseja cancelar e limpar os itens do pedido atual?', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
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
      if (mounted) setState(() {});
    }
    _keyboardFocusNode.requestFocus();
  }

  /// Diálogo de justificativa para pedidos com data/hora retroativa
  Future<JustificativaRetroativoResult?> _solicitarJustificativaRetroativo(DateTime dataRetroativa) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultMovimentarEstoque = prefs.getBool('pdv_retroativo_movimentar_estoque') ?? false;

    final motivoCtrl = TextEditingController();
    String? motivoSelecionado;
    bool movimentarEstoque = defaultMovimentarEstoque;

    final dataStr = '${dataRetroativa.day.toString().padLeft(2, '0')}/'
        '${dataRetroativa.month.toString().padLeft(2, '0')} '
        '${dataRetroativa.hour.toString().padLeft(2, '0')}:'
        '${dataRetroativa.minute.toString().padLeft(2, '0')}';

    const motivosRetroativo = [
      'Pedido recebido por telefone anteriormente',
      'Sistema fora do ar no momento do pedido',
      'Erro de digitação da hora',
      'Pedido antecipado confirmado com cliente',
      'Reprocessamento de pedido cancelado',
    ];

    return showDialog<JustificativaRetroativoResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.history_outlined, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedido com Data Retroativa',
                      style: TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hora informada: $dataStr (no passado)',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este pedido possui data/hora no passado. É obrigatório informar o motivo para registro em auditoria.',
                          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Selecione ou descreva o motivo:',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: motivosRetroativo.map((m) {
                    final isSel = motivoSelecionado == m;
                    return InkWell(
                      onTap: () => setDialogState(() {
                        motivoSelecionado = m;
                        motivoCtrl.text = m;
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFF59E0B) : FincoreColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? const Color(0xFFF59E0B) : FincoreColors.border,
                          ),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: isSel ? Colors.white : FincoreColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoCtrl,
                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Descreva o motivo da data retroativa...',
                    hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: FincoreColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: FincoreColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: FincoreColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Movimentar estoque',
                              style: TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              movimentarEstoque
                                  ? 'Dará baixa nos itens deste pedido'
                                  : 'Não alterará o saldo atual de estoque',
                              style: const TextStyle(
                                color: FincoreColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: movimentarEstoque,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          setDialogState(() {
                            movimentarEstoque = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Confirmar com Justificativa'),
              onPressed: () {
                final txt = motivoCtrl.text.trim();
                if (txt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe o motivo para criar um pedido retroativo.'),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  ctx,
                  JustificativaRetroativoResult(
                    motivo: txt,
                    movimentarEstoque: movimentarEstoque,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _flashKeyLabel(String label) {
    setState(() => _activaKeyLabel = label);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _activaKeyLabel = null);
    });
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  void _showShortcutHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final shortcuts = [
          const _ShortcutEntry(key: 'F2', label: 'Focar Busca de Produtos'),
          const _ShortcutEntry(key: 'F4', label: 'Selecionar / Cadastrar Cliente'),
          const _ShortcutEntry(key: 'F6', label: 'Alternar Destino (Balcão / Retirada / Delivery)'),
          const _ShortcutEntry(key: 'F8', label: 'Operações de Caixa (Abrir / Sangria / Fechar)'),
          const _ShortcutEntry(key: 'F10', label: 'Receber / Finalizar Pedido'),
          const _ShortcutEntry(key: 'ESC', label: 'Limpar Pedido Atual'),
        ];
        return AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.keyboard, color: FincoreColors.primary),
              const SizedBox(width: 10),
              const Text(
                'Atalhos da Workstation PDV',
                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: shortcuts.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Text(
                        s.key,
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.label,
                        style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('FECHAR', style: TextStyle(color: FincoreColors.primary)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processarFinalizacaoVenda() async {
    // 1. Validação de Itens
    if (_controller.cart.isEmpty) {
      _triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Text('Adicione pelo menos 1 produto ao pedido antes de finalizar.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. Validação: Caixa Aberto Obrigatório
    if (!_finCtrl.resumo.caixaAberto) {
      _triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Text('⚠️ Caixa fechado! É obrigatório abrir o caixa para iniciar as vendas.'),
          duration: Duration(seconds: 4),
        ),
      );
      await DialogAbrirCaixa.show(
        context,
        controller: _finCtrl,
        onConfirm: (val, turno) async {
          await _finCtrl.abrirCaixa(valorAberturaCentavos: val, nomeTurno: turno);
          if (mounted) setState(() {});
        },
      );
      if (!mounted) return;
      if (!_finCtrl.resumo.caixaAberto) return;
    }

    // 3. Validação: Quantidade Mínima por Categoria / Grupo com Preço Escalonado
    final erroMinimo = await _controller.validarQuantidadesMinimasGrupos();
    if (erroMinimo != null) {
      _triggerShake();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  erroMinimo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // 4. Validação: Cliente ou Consumidor Final Obrigatório
    final cliente = _controller.cliente;
    final isSemCliente = cliente.isEmpty || cliente.nome == null || cliente.nome!.trim().isEmpty;
    if (isSemCliente) {
      _triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Row(
            children: [
              Icon(Icons.person_off_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Identificação obrigatória! Selecione um Cliente [F4] ou marque "Consumidor Final" antes de finalizar a venda.'),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // 4. Validação: Endereço obrigatório para modalidade de Entrega
    final entrega = _controller.entrega;
    if (entrega.tipo == 'Entrega' && entrega.logradouro.trim().isEmpty && entrega.bairro.trim().isEmpty) {
      _triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Row(
            children: [
              Icon(Icons.location_off_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Para pedidos de Entrega, informe o endereço (rua ou bairro) do cliente antes de finalizar.'),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final result = await ConfirmacaoAgendamentoModal.show(context, _controller);
    if (result == null || result.action == ConfirmAction.cancelar) {
      return;
    }

    final bool enviarWhats = result.enviarWhatsApp;
    final totalCentavos = _controller.totalInCents;
    final itensCopy = _controller.cart.map((item) {
      return {
        'nome': item.name,
        'qtd': item.quantity,
        'total': (item.totalInCents / 100),
        'obs': null,
      };
    }).toList();

    final dataHora = entrega.dataHora;
    final dataStr = '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year} às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
    final formaPagtoStr = _controller.selectedFormaPagamento?.nome ?? 'Dinheiro';
    final enderecoStr = (entrega.tipo == 'Entrega' && (entrega.logradouro.isNotEmpty || entrega.bairro.isNotEmpty))
        ? '${entrega.logradouro}${entrega.numero.isNotEmpty ? ", ${entrega.numero}" : ""}${entrega.bairro.isNotEmpty ? " - ${entrega.bairro}" : ""}${entrega.cidade.isNotEmpty ? ", ${entrega.cidade}" : ""}${entrega.referencia.isNotEmpty ? " (Ref: ${entrega.referencia})" : ""}'
        : null;

    String? empresaNome;
    try {
      if (TenantContext().hasContext) {
        empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
            ? TenantContext().empresa.nomeFantasia
            : TenantContext().empresa.razaoSocial;
      }
    } catch (_) {}

    final subtotalCalc = _controller.cart.fold<int>(0, (sum, i) => sum + i.totalInCents) / 100;

    if (result.action == ConfirmAction.finalizarEImprimir) {
      await _controller.confirmPayment(autoPrint: true);
    } else if (result.action == ConfirmAction.finalizar) {
      await _controller.confirmPayment(autoPrint: false);
    }

    final tel = cliente.telefone;
    if (enviarWhats && mounted && tel != null && tel.isNotEmpty && tel != '00000000000') {
      String? tenantId;
      try {
        if (TenantContext().hasContext) tenantId = TenantContext().tenantId;
      } catch (_) {}

      // ── HIERARQUIA DE MENSAGERIA (Nível 1 & 2) ──
      final hierarquia = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tenantId: tenantId,
        empresaUsarWhatsApp: _controller.empresaConfig?.usarWhatsApp,
      );

      // Se a política do evento estiver DESATIVADA (OFF), bloqueio total:
      if (hierarquia.eventoDesativado) {
        debugPrint('[PDV Express] Envio de WhatsApp cancelado: evento pedido_criado_pdv está DESATIVADO (OFF) nas configurações de política.');
        return;
      }

      final numeroPedidoReal = _controller.lastNumeroPedido != null ? '#${_controller.lastNumeroPedido}' : '';

      final isPix = formaPagtoStr.toLowerCase().contains('pix') ||
          (_controller.selectedFormaPagamento?.tipo == TipoFormaPagamento.pix);

      // ── Resolução Contextual de PIX (Chave, Favorecido e Copia e Cola) ──
      PixWhatsAppInfo? pixInfo;
      if (isPix) {
        try {
          final selectedForma = _controller.selectedFormaPagamento;
          final impConfig = await FincoreImpressaoConfig.carregar();

          String chavePix = (selectedForma?.pixChave != null && selectedForma!.pixChave!.isNotEmpty)
              ? selectedForma.pixChave!
              : impConfig.pixChave;

          String? favEmpresa;
          try {
            final db = DependencyInjection().get<FincoreDatabase>();
            final empCfg = await (db.select(db.empresaConfiguracaoTable)..limit(1)).getSingleOrNull();
            favEmpresa = empCfg?.pixFavorecido;
          } catch (_) {}

          final tipoPix = (selectedForma?.pixTipoChave != null && selectedForma!.pixTipoChave!.isNotEmpty)
              ? selectedForma.pixTipoChave!
              : (impConfig.pixTipo.isNotEmpty ? impConfig.pixTipo : 'PIX');

          final favorecido = impConfig.pixFavorecido.isNotEmpty
              ? impConfig.pixFavorecido
              : ((favEmpresa != null && favEmpresa.isNotEmpty)
                  ? favEmpresa
                  : ((selectedForma?.pixTipoBanco != null && selectedForma!.pixTipoBanco!.isNotEmpty)
                      ? selectedForma.pixTipoBanco!
                      : ((empresaNome != null && empresaNome.isNotEmpty) ? empresaNome : 'Estabelecimento')));

          String copiaCola = '';
          if (chavePix.isNotEmpty) {
            copiaCola = PixGenerator.gerarCopiaCola(
              chave: chavePix,
              favorecido: favorecido,
              cidade: 'Sorocaba',
              valor: (totalCentavos / 100.0),
              tipoChave: tipoPix,
            );
          }

          if (chavePix.isNotEmpty || copiaCola.isNotEmpty) {
            pixInfo = PixWhatsAppInfo(
              chaveDisplay: chavePix.isNotEmpty ? chavePix : '(Chave não configurada)',
              tipoChave: tipoPix,
              copiaECola: copiaCola,
              confirmado: false,
            );
          }
        } catch (e) {
          debugPrint('[PDV Express] Erro ao resolver dados PIX para WhatsApp: $e');
        }
      }

      // ── Resolução de Template Dinâmico do PDV ──

      final pdvConfig = await WhatsAppService.getPdvConfig(tenantId: tenantId);
      final templates = await WhatsAppService.getTemplates(tenantId: tenantId, nomeEmpresa: empresaNome);
      final mappingEventos = await WhatsAppService.getTemplatesEventosConfigurados(tenantId: tenantId);
      final templateIdEventoPdv = mappingEventos[WhatsAppService.kEventoPedidoCriadoPdv] ?? pdvConfig.templateId;

      // Localiza o template configurado para o PDV nas Políticas por Evento ou config PDV
      final templateEscolhido = templates.firstWhere(
        (t) => t.ativo && t.id == templateIdEventoPdv,
        orElse: () => templates.firstWhere(
          (t) => t.ativo && (t.id == 'comprovante' || t.evento == 'pedido_criado' || t.evento == WhatsAppService.kEventoPedidoCriadoPdv),
          orElse: () => templates.firstWhere(
            (t) => t.ativo && t.id == 'contato_pedido',
            orElse: () => templates.first,
          ),
        ),
      );

      final taxaEntregaCalc = (entrega.taxaEntregaCentavos / 100.0);
      final taxaServicoCalc = (entrega.taxaServicoCentavos / 100.0);
      final totalCalc = (totalCentavos / 100.0);
      final descontoCentavosCalc = (subtotalCalc * 100 + entrega.taxaEntregaCentavos + entrega.taxaServicoCentavos) - totalCentavos;
      final descontoCalc = descontoCentavosCalc > 0 ? (descontoCentavosCalc / 100.0) : 0.0;

      final vars = WhatsAppService.gerarVariaveisInterpolacao(
        clienteNome: cliente.nome ?? 'Cliente',
        nomeEmpresa: (empresaNome != null && empresaNome.isNotEmpty) ? empresaNome : 'Nossa Loja',
        numeroPedido: numeroPedidoReal.isNotEmpty ? numeroPedidoReal : null,
        pedidoId: _controller.lastPedidoId,
        tenantId: tenantId,
        itens: itensCopy,
        subtotal: subtotalCalc,
        desconto: descontoCalc,
        taxaEntrega: taxaEntregaCalc,
        taxaServico: taxaServicoCalc,
        total: totalCalc,
        formaPagamento: formaPagtoStr,
        statusPagamento: isPix ? 'Pendente' : 'Confirmado',
        pagamentoPendente: isPix,
        isPix: isPix,
        tipoPedido: entrega.tipo,
        endereco: enderecoStr,
        enderecoEmpresa: WhatsAppService.formatarEnderecoEmpresa(),
        observacoes: entrega.observacoes.isNotEmpty ? entrega.observacoes : null,
        previsaoEntrega: dataStr,
        chavePix: pixInfo?.chaveDisplay,
        chavePixCopiaCola: pixInfo?.copiaECola,
        formatoPix: pdvConfig.formatoPixPadrao,
      );

      final msgInterpolada = WhatsAppService.interpolarTemplate(templateEscolhido.conteudo, vars);

      final bool isApiConectada = await EvolutionApiClient.isInstanciaConectada(tenantId: tenantId);

      if (isApiConectada) {
        // Disparo Automático Silencioso via Evolution API (sem abrir telas/modais)
        final res = await WhatsAppService.enviarMensagem(
          rawPhone: tel,
          mensagem: msgInterpolada,
          tenantId: tenantId,
          pedidoId: _controller.lastPedidoId ?? numeroPedidoReal,
          eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
          isManualIntent: true,
        );

        // Se configurado para enviar Copia e Cola em 2ª mensagem e PIX pendente
        if (pdvConfig.enviarPix2MsgPadrao && isPix && pixInfo != null && pixInfo.copiaECola.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 1200));
          await WhatsAppService.enviarMensagem(
            rawPhone: tel,
            mensagem: pixInfo.copiaECola,
            tenantId: tenantId,
            pedidoId: _controller.lastPedidoId ?? numeroPedidoReal,
            eventoId: 'pix_copia_cola_2msg',
            isManualIntent: true,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      res.sucesso
                          ? 'Comprovante do Pedido $numeroPedidoReal enviado ao cliente via WhatsApp! 📱'
                          : 'Tentativa de WhatsApp: ${res.erro ?? "Verifique a conexão"}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // Contingência Manual: Abre diálogo apenas se a API estiver desconectada
        await WhatsAppDialog.show(
          context,
          rawPhone: tel,
          clienteNome: cliente.nome ?? 'Cliente',
          initialMessage: msgInterpolada,
          initialTemplateId: pdvConfig.templateId,
          enderecoCliente: enderecoStr,
          enderecoEmpresa: WhatsAppService.formatarEnderecoEmpresa(),
          statusPagamento: isPix ? 'Pendente' : 'Confirmado',
          pagamentoPendente: isPix,
          isPix: isPix,
          pixInfo: pixInfo,
          nomeEmpresa: empresaNome,
          numeroPedido: numeroPedidoReal.isNotEmpty ? numeroPedidoReal : null,
          pedidoId: _controller.lastPedidoId,
          itens: itensCopy,
          subtotal: subtotalCalc,
          desconto: descontoCalc,
          taxaEntrega: taxaEntregaCalc,
          taxaServico: taxaServicoCalc,
          total: totalCalc,
          formaPagamento: formaPagtoStr,
          tipoPedido: entrega.tipo,
          observacoes: entrega.observacoes.isNotEmpty ? entrega.observacoes : null,
          previsaoEntrega: dataStr,
        );
      }
    }
  }

  void _showSuccessNotification() {
    final isEdit = widget.ordemParaEditar != null;

    if (isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Alterações salvas com sucesso!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
      if (widget.onVoltarOuCancelar != null) {
        widget.onVoltarOuCancelar!();
      } else if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      return;
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
                'Venda de R\$ ${(_controller.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',')} processada com sucesso!',
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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        // HardwareKeyboard já intercepta; aqui garante foco
      },
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        ),
        child: Scaffold(
          backgroundColor: widget.isEmbedded ? Colors.transparent : FincoreColors.background,
          body: Stack(
            children: [
              Column(
                children: [
                  // ── Barra Operacional de Caixa & Turno ──────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: _CaixaOperacionalBar(
                      controller: _finCtrl,
                      ordemParaEditar: widget.ordemParaEditar,
                      onVoltar: widget.onVoltarOuCancelar != null
                          ? (widget.ordemParaEditar != null
                              ? _confirmarSaidaEdicao
                              : widget.onVoltarOuCancelar)
                          : (widget.ordemParaEditar != null
                              ? _confirmarSaidaEdicao
                              : (Navigator.of(context).canPop()
                                  ? () => Navigator.of(context).pop(false)
                                  : null)),
                      onHelpShortcuts: _showShortcutHelpDialog,
                    ),
                  ),

                  // ── ÁREA PRINCIPAL EM 3 COLUNAS SIMULTÂNEAS ─────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Coluna 1: Atendimento & Destino (~300px) ──
                          SizedBox(
                            width: 300,
                            child: AtendimentoDestinoPanel(
                              controller: _controller,
                              onOpenCustomerSearch: _abrirModalCliente,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ── Coluna 2: Catálogo & Ações Rápidas (Flex) ─
                          Expanded(
                            child: CatalogoProdutosPanel(
                              controller: _controller,
                              searchFocusNode: _searchFocusNode,
                              searchController: _searchController,
                              onImportarWhatsApp: _abrirImportadorPedidoIa,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ── Coluna 3: Pedido, Pagamento & Finalizar (~360px)
                          SizedBox(
                            width: 360,
                            child: PedidoCarrinhoPanel(
                              controller: _controller,
                              onFinalizar: _processarFinalizacaoVenda,
                              onLimpar: _confirmarLimpezaPedido,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Rodapé Flutuante de Atalhos Rápidos ─────────────
                  _buildShortcutFooter(),
                ],
              ),

              // ── Modal PIX (sobreposição quando aguardando PIX) ──────
              if (_controller.state == PdvState.awaitingPix)
                PixPaymentModal(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutFooter() {
    final shortcuts = [
      const _ShortcutEntry(key: 'F2', label: 'Busca Produtos'),
      const _ShortcutEntry(key: 'F4', label: 'Cliente'),
      const _ShortcutEntry(key: 'F6', label: 'Destino'),
      const _ShortcutEntry(key: 'F7', label: 'WhatsApp IA'),
      const _ShortcutEntry(key: 'F8', label: 'Caixa'),
      const _ShortcutEntry(key: 'F10', label: 'Finalizar'),
      const _ShortcutEntry(key: 'ESC', label: 'Limpar'),
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FincoreColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: shortcuts.map((s) {
                  final isActive = _activaKeyLabel == s.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${s.key}: ',
                          style: TextStyle(
                            color: isActive ? FincoreColors.primary : FincoreColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: isActive ? FincoreColors.primary : FincoreColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutEntry {
  final String key;
  final String label;
  const _ShortcutEntry({required this.key, required this.label});
}

class _CaixaOperacionalBar extends StatelessWidget {
  final FinanceiroController controller;
  final OrdemPreparo? ordemParaEditar;
  final VoidCallback? onVoltar;
  final VoidCallback onHelpShortcuts;

  const _CaixaOperacionalBar({
    required this.controller,
    this.ordemParaEditar,
    this.onVoltar,
    required this.onHelpShortcuts,
  });

  String _fmt(int centavos) =>
      'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final resumo = controller.resumo;
        final aberto = resumo.caixaAberto;
        final sessao = resumo.sessaoAtiva;

        // Caso 1: Modo Edição de Pedido Existente
        if (ordemParaEditar != null) {
          final pedId = ordemParaEditar!.pedidoId.length > 6
              ? ordemParaEditar!.pedidoId.substring(0, 6).toUpperCase()
              : ordemParaEditar!.pedidoId.toUpperCase();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                if (onVoltar != null) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text(
                      'Sair da Edição [ESC]',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: onVoltar,
                  ),
                  const SizedBox(width: 14),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF97316)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFF97316)),
                      SizedBox(width: 4),
                      Text(
                        'MODO DE EDIÇÃO ATIVO',
                        style: TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Editando Pedido #$pedId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.keyboard_outlined, color: FincoreColors.textSecondary, size: 20),
                  tooltip: 'Atalhos de Teclado',
                  onPressed: onHelpShortcuts,
                ),
              ],
            ),
          );
        }

        // Caso 2: Caixa Fechado
        if (!aberto) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                if (onVoltar != null) ...[
                  Tooltip(
                    message: 'Voltar ao menu / Sair do PDV',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onVoltar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: FincoreColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 16, color: FincoreColors.textPrimary),
                            SizedBox(width: 6),
                            Text(
                              'Voltar / Sair',
                              style: TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Color(0xFFEF4444), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Caixa Fechado',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Abra um turno de caixa para iniciar as operações de venda da estação.',
                  style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => DialogAbrirCaixa.show(
                    context,
                    controller: controller,
                    onConfirm: (val, turno) async {
                      await controller.abrirCaixa(valorAberturaCentavos: val, nomeTurno: turno);
                    },
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 15),
                  label: const Text('Abrir Caixa [F8]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.keyboard_outlined, color: FincoreColors.textSecondary, size: 20),
                  tooltip: 'Atalhos de Teclado',
                  onPressed: onHelpShortcuts,
                ),
              ],
            ),
          );
        }

        // Caso 3: Caixa Aberto (Exibição Completa de Dia, Turno, Operador e Ações)
        final dataAbertura = (sessao?.dataAbertura ?? DateTime.now()).toLocal();
        final dataStr = DateFormat('dd/MM/yyyy').format(dataAbertura);

        // Turno
        String turnoStr = 'Turno 01';
        if (sessao?.observacoes != null && sessao!.observacoes!.startsWith('TURNO:')) {
          final partes = sessao.observacoes!.split(':');
          if (partes.length >= 2) {
            final numT = int.tryParse(partes[1]) ?? 1;
            turnoStr = 'Turno ${numT.toString().padLeft(2, '0')}';
          }
        }

        // Operador
        final operadorNome = (sessao?.operadorNome != null &&
                sessao!.operadorNome.isNotEmpty &&
                sessao.operadorNome != 'Operador')
            ? sessao.operadorNome
            : (TenantContext().hasContext ? TenantContext().usuario.nome : 'Operador');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            children: [
              if (onVoltar != null) ...[
                Tooltip(
                  message: 'Voltar ao menu / Sair do PDV',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onVoltar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 16, color: FincoreColors.textPrimary),
                          SizedBox(width: 6),
                          Text(
                            'Voltar / Sair',
                            style: TextStyle(
                              color: FincoreColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Badge Caixa Aberto com Indicador Verde
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FincoreColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FincoreColors.success.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: FincoreColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Caixa Aberto',
                      style: TextStyle(
                        color: FincoreColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),
              _buildDivider(),
              const SizedBox(width: 14),

              // Dia / Data
              _buildInfoItem(
                icon: Icons.calendar_today_rounded,
                label: 'Data',
                value: dataStr,
              ),

              const SizedBox(width: 14),
              _buildDivider(),
              const SizedBox(width: 14),

              // Turno
              _buildInfoItem(
                icon: Icons.schedule_rounded,
                label: 'Turno',
                value: turnoStr,
              ),

              const SizedBox(width: 14),
              _buildDivider(),
              const SizedBox(width: 14),

              // Quem abriu o caixa
              _buildInfoItem(
                icon: Icons.person_outline_rounded,
                label: 'Aberto por',
                value: operadorNome,
              ),

              const SizedBox(width: 14),
              _buildDivider(),
              const SizedBox(width: 14),

              // Fundo de Troco Inicial
              _buildInfoItem(
                icon: Icons.point_of_sale_rounded,
                label: 'Fundo Inicial',
                value: _fmt(resumo.fundoTrocoCentavos),
              ),

              const Spacer(),

              // Botão Dropdown de Operações (Sangria, Suprimento, Fechamento de Caixa)
              PopupMenuButton<String>(
                tooltip: 'Operações de Caixa (Sangria, Suprimento, Fechar)',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: FincoreColors.surface,
                onSelected: (val) async {
                  if (val == 'sangria') {
                    DialogMovimentoCaixa.show(
                      context,
                      initialTipo: 'sangria',
                      onConfirm: (t, v, d) => controller.lancarMovimento(tipo: t, valorCentavos: v, descricao: d),
                    );
                  } else if (val == 'suprimento') {
                    DialogMovimentoCaixa.show(
                      context,
                      initialTipo: 'suprimento',
                      onConfirm: (t, v, d) => controller.lancarMovimento(tipo: t, valorCentavos: v, descricao: d),
                    );
                  } else if (val == 'fechar') {
                    FechamentoTurnoPage.show(context, controller: controller);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'sangria',
                    child: Row(
                      children: [
                        Icon(Icons.output_rounded, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Registrar Sangria (Retirada)', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'suprimento',
                    child: Row(
                      children: [
                        Icon(Icons.input_rounded, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Reforço de Troco (Suprimento)', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'fechar',
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock_rounded, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Conferência & Fechamento de Turno', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: FincoreColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Operações [F8]',
                        style: TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: FincoreColors.textMuted, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botão de Ajuda de Atalhos
              IconButton(
                icon: const Icon(Icons.keyboard_outlined, color: FincoreColors.textSecondary, size: 20),
                tooltip: 'Atalhos de Teclado',
                onPressed: onHelpShortcuts,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      color: FincoreColors.border,
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: FincoreColors.textMuted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
