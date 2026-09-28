import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../controllers/pdv_express_controller.dart';
import 'widgets/pix_payment_modal.dart';
import 'widgets/stepper_header.dart';
import 'widgets/customer_step.dart';
import 'widgets/product_catalog_step.dart';
import 'widgets/payment_step.dart';
import 'widgets/order_summary_panel.dart';
import 'widgets/confirmacao_agendamento_modal.dart';
import 'package:fincore_core/context/tenant_context.dart';
import '../../shared/services/whatsapp_service.dart';
import '../../shared/presentation/widgets/whatsapp_dialog.dart';
import '../../financeiro/controllers/financeiro_controller.dart';
import '../../financeiro/widgets/dialogs_caixa.dart';

class PdvExpressScreen extends StatefulWidget {
  final bool isEmbedded;
  final OrdemPreparo? ordemParaEditar;
  final String? repetirPedidoId;
  final Cliente? clienteInicial;
  const PdvExpressScreen({
    super.key,
    this.isEmbedded = false,
    this.ordemParaEditar,
    this.repetirPedidoId,
    this.clienteInicial,
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
    // Aguarda carregar dados do banco local
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (!_finCtrl.resumo.caixaAberto && widget.ordemParaEditar == null) {
      if (!mounted) return;
      await DialogAbrirCaixa.show(
        context,
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
                  DialogFecharCaixa.show(
                    context,
                    resumo: resumo,
                    controller: _finCtrl,
                    formatarValor: (centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                    onConfirm: (v, obs) => _finCtrl.fecharCaixa(valorContadoCentavos: v, observacoes: obs),
                  );
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

    if (key == LogicalKeyboardKey.f1) {
      _flashKeyLabel('F1');
      _controller.setPassoAtual(0);
      return true;
    } else if (key == LogicalKeyboardKey.f2) {
      _flashKeyLabel('F2');
      _controller.setPassoAtual(1);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        }
      });
      return true;
    } else if (key == LogicalKeyboardKey.f3) {
      _flashKeyLabel('F3');
      _controller.setPassoAtual(2);
      return true;
    } else if (key == LogicalKeyboardKey.f8) {
      _flashKeyLabel('F8');
      _abrirMenuOperacoesCaixa();
      return true;
    } else if (key == LogicalKeyboardKey.f12) {
      _flashKeyLabel('F12');
      if (_controller.passoAtual == 2 || _controller.state == PdvState.selectingPayment) {
        _processarFinalizacaoVenda();
      } else if (!_controller.podeAvancar()) {
        _triggerShake();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Por favor, preencha as informações obrigatórias da etapa atual.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _avancarPasso();
      }
      return true;
    }
    return false;
  }

  /// Diálogo de justificativa para pedidos com data/hora retroativa
  Future<JustificativaRetroativoResult?> _solicitarJustificativaRetroativo(DateTime dataRetroativa) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultMovimentarEstoque = prefs.getBool('pdv_retroativo_movimentar_estoque') ?? false;

    final motivoCtrl = TextEditingController();
    String? motivoSelecionado;
    bool movimentarEstoque = defaultMovimentarEstoque;

    final dataStr = '${dataRetroativa.day.toString().padLeft(2,'0')}/'
        '${dataRetroativa.month.toString().padLeft(2,'0')} '
        '${dataRetroativa.hour.toString().padLeft(2,'0')}:'
        '${dataRetroativa.minute.toString().padLeft(2,'0')}';

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

  void _showShortcutHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final shortcuts = [
          const _ShortcutEntry(key: 'F1', label: 'Selecionar Cliente & Entrega'),
          const _ShortcutEntry(key: 'F2', label: 'Catálogo de Produtos'),
          const _ShortcutEntry(key: 'F3', label: 'Forma de Pagamento'),
          const _ShortcutEntry(key: 'F8', label: 'Operações de Caixa (Abrir / Sangria / Fechar)'),
          const _ShortcutEntry(key: 'F12', label: 'Finalizar / Processar Venda'),
          const _ShortcutEntry(key: 'ESC', label: 'Limpar Venda / Cancelar'),
        ];
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: Row(
            children: [
              Icon(Icons.keyboard, color: FincoreColors.primary),
              const SizedBox(width: 10),
              const Text(
                'Atalhos de Teclado',
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

  // ── Handler Central de Atalhos de Teclado ────────────────────────
  void _handleKeyEvent(KeyEvent event) async {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // F1 — Ir para Identificação do Cliente
    if (key == LogicalKeyboardKey.f1) {
      _flashKeyLabel('F1');
      _controller.setPassoAtual(0);
    }
    // F2 — Ir para Catálogo de Produtos e focar busca
    else if (key == LogicalKeyboardKey.f2) {
      _flashKeyLabel('F2');
      _controller.setPassoAtual(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        }
      });
    }
    // F3 — Ir para Pagamento
    else if (key == LogicalKeyboardKey.f3) {
      _flashKeyLabel('F3');
      _controller.setPassoAtual(2);
    }
    // F4 — Avançar Etapa
    else if (key == LogicalKeyboardKey.f4) {
      _flashKeyLabel('F4');
      _avancarPasso();
    }
    // F5 — Voltar Etapa
    else if (key == LogicalKeyboardKey.f5) {
      _flashKeyLabel('F5');
      _voltarPasso();
    }
    // F9 — Reimprimir cupom do último pedido
    else if (key == LogicalKeyboardKey.f9) {
      _flashKeyLabel('F9');
      _showReimprimirToast();
    }
    // F12 — Confirmar Venda / Finalizar
    else if (key == LogicalKeyboardKey.f12) {
      _flashKeyLabel('F12');
      if (_controller.passoAtual == 2 || _controller.state == PdvState.selectingPayment) {
        _processarFinalizacaoVenda();
      } else if (!_controller.podeAvancar()) {
        _triggerShake();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Por favor, preencha as informações obrigatórias da etapa atual.'),
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

  Future<void> _processarFinalizacaoVenda() async {
    // ── Validação Fundamental: Caixa Aberto Obrigatório ─────────────
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
        onConfirm: (val, turno) async {
          await _finCtrl.abrirCaixa(valorAberturaCentavos: val, nomeTurno: turno);
          if (mounted) setState(() {});
        },
      );
      if (!mounted) return;
      if (!_finCtrl.resumo.caixaAberto) return;
    }

    final result = await ConfirmacaoAgendamentoModal.show(context, _controller);
    if (result == null || result.action == ConfirmAction.cancelar) {
      _controller.setPassoAtual(0);
      return;
    }

    final bool enviarWhats = result.enviarWhatsApp;
    final cliente = _controller.cliente;
    final entrega = _controller.entrega;
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

    final resumoWhats = WhatsAppService.gerarTextoResumoPedido(
      nomeCliente: cliente.nome ?? 'Cliente',
      numeroPedidoOuId: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
      tipoAtendimento: entrega.tipo,
      dataHoraPrevista: dataStr,
      itens: itensCopy,
      subtotal: subtotalCalc,
      taxaEntrega: (entrega.taxaEntregaCentavos / 100),
      taxaServico: (entrega.taxaServicoCentavos / 100),
      total: (totalCentavos / 100),
      formaPagamento: formaPagtoStr,
      enderecoEntrega: enderecoStr,
      observacoes: entrega.observacoes.isNotEmpty ? entrega.observacoes : null,
      nomeEmpresa: empresaNome,
    );

    if (result.action == ConfirmAction.finalizarEImprimir) {
      await _controller.confirmPayment(autoPrint: true);
    } else if (result.action == ConfirmAction.finalizar) {
      await _controller.confirmPayment(autoPrint: false);
    }

    final tel = cliente.telefone;
    if (enviarWhats && mounted && tel != null && tel.isNotEmpty && tel != '00000000000') {
      await WhatsAppDialog.show(
        context,
        rawPhone: tel,
        clienteNome: cliente.nome ?? 'Cliente',
        initialMessage: resumoWhats,
        enderecoCliente: enderecoStr,
        nomeEmpresa: empresaNome,
      );
    }
  }

  void _avancarPasso() {
    if (_controller.podeAvancar()) {
      if (_controller.passoAtual < 2) {
        _controller.setPassoAtual(_controller.passoAtual + 1);
      } else {
        _processarFinalizacaoVenda();
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
    final isEdit = widget.ordemParaEditar != null;

    if (isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FincoreColors.success,
          content: Row(
            children: const [
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
          duration: const Duration(seconds: 3),
        ),
      );
      if (context.mounted) {
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
                  // ── Top Row: Back button, Title, StepperHeader, and Keyboard Help Button ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back, color: FincoreColors.textPrimary),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ordemParaEditar != null ? 'Editar Pedido' : 'Novo Pedido',
                              style: const TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Central de vendas',
                              style: TextStyle(
                                color: FincoreColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _FocusedBorderWrapper(
                            isActive: _keyboardFocusNode.hasFocus,
                            child: StepperHeader(controller: _controller),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _CaixaQuickHeaderWidget(controller: _finCtrl),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.keyboard_outlined, color: FincoreColors.textSecondary),
                          tooltip: 'Atalhos de Teclado',
                          onPressed: _showShortcutHelpDialog,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Coluna Esquerda: Conteúdo das Etapas ──
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildStepView(),
                          ),
                        ),

                        // ── Coluna Direita: Painel Operacional Persistente ──
                        Padding(
                          padding: const EdgeInsets.only(right: 20, bottom: 16),
                          child: OrderSummaryPanel(
                            controller: _controller,
                            onBack: _voltarPasso,
                            onNext: _avancarPasso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Modal PIX (sobreposição quando aguardando PIX) ──────
              if (_controller.state == PdvState.awaitingPix)
                PixPaymentModal(controller: _controller),
            ],
          ),
          bottomNavigationBar: null,
        ),
      ),
    );
  }

  // ── Footer Flutuante de Atalhos em Pílula (Mockup Original) ───────
  Widget _buildShortcutFooter() {
    final shortcuts = [
      const _ShortcutEntry(key: 'F1', label: 'Cliente'),
      const _ShortcutEntry(key: 'F2', label: 'Produtos'),
      const _ShortcutEntry(key: 'F3', label: 'Pagamento'),
      const _ShortcutEntry(key: 'F8', label: 'Caixa'),
      const _ShortcutEntry(key: 'F12', label: 'Finalizar'),
      const _ShortcutEntry(key: 'ESC', label: 'Limpar'),
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: FincoreColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: shortcuts.map((s) {
                  final isActive = _activaKeyLabel == s.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${s.key}: ',
                          style: TextStyle(
                            color: isActive
                                ? FincoreColors.primary
                                : FincoreColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: isActive
                                ? FincoreColors.primary
                                : FincoreColors.textSecondary,
                            fontSize: 13,
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
          color: isActive ? FincoreColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

class _CaixaQuickHeaderWidget extends StatelessWidget {
  final FinanceiroController controller;
  const _CaixaQuickHeaderWidget({required this.controller});

  String _fmt(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final resumo = controller.resumo;
        final aberto = resumo.caixaAberto;

        if (!aberto) {
          return InkWell(
            onTap: () => DialogAbrirCaixa.show(
              context,
              onConfirm: (val, turno) async {
                await controller.abrirCaixa(valorAberturaCentavos: val, nomeTurno: turno);
              },
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.point_of_sale_rounded, color: Color(0xFFEF4444), size: 14),
                  SizedBox(width: 6),
                  Text('Caixa Fechado (Abrir)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        final obsTurno = resumo.sessaoAtiva?.observacoes;
        final labelTurno = (obsTurno != null && obsTurno.startsWith('Turno: '))
            ? obsTurno.replaceAll('Turno: ', '')
            : null;

        return PopupMenuButton<String>(
          tooltip: 'Operações de Caixa (Sangria, Suprimento, Fechar)',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: FincoreColors.surface,
          onSelected: (val) async {
            if (val == 'sangria') {
              DialogMovimentoCaixa.show(context, initialTipo: 'sangria', onConfirm: (t, v, d) => controller.lancarMovimento(tipo: t, valorCentavos: v, descricao: d));
            } else if (val == 'suprimento') {
              DialogMovimentoCaixa.show(context, initialTipo: 'suprimento', onConfirm: (t, v, d) => controller.lancarMovimento(tipo: t, valorCentavos: v, descricao: d));
            } else if (val == 'fechar') {
              DialogFecharCaixa.show(context, resumo: resumo, controller: controller, formatarValor: _fmt, onConfirm: (v, obs) => controller.fecharCaixa(valorContadoCentavos: v, observacoes: obs));
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FincoreColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FincoreColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: FincoreColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  labelTurno != null
                      ? 'Caixa Aberto · $labelTurno (${_fmt(resumo.fundoTrocoCentavos)})'
                      : 'Caixa Aberto (${_fmt(resumo.fundoTrocoCentavos)})',
                  style: const TextStyle(color: FincoreColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: FincoreColors.success, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
