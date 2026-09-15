import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_shared/fincore_shared.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/shared/services/permissao_service.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/pedido_card.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/kanban_column.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/pedido_detail_drawer.dart';
import 'package:fincore_food_flutter/src/cap/printing/print_capability.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pdv_page.dart';



// ─── Central Operacional de Pedidos ─────────────────────────────────────────

class PedidosPage extends StatefulWidget {
  static DateTime? dataPreSelecionada;
  static String? filtroPedidoId;

  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  late final CentralPedidosController _controller;
  late final String? _userRole;
  bool _producaoExpanded = true;
  int _activeSubTab = 0;
  String _historySearchQuery = '';
  String _historyStatusFilter = 'Todos';
  String _historyOrigemFilter = 'Todos';
  DateTime? _historyDateFrom;
  DateTime? _historyDateTo;

  Timer? _deadlinesTimer;

  @override
  void initState() {
    super.initState();
    _controller = CentralPedidosController();

    if (PedidosPage.dataPreSelecionada != null) {
      _controller.setSelectedDate(PedidosPage.dataPreSelecionada!);
      PedidosPage.dataPreSelecionada = null;
    }

    if (PedidosPage.filtroPedidoId != null) {
      final pid = PedidosPage.filtroPedidoId!;
      PedidosPage.filtroPedidoId = null;
      _historySearchQuery = pid;
    }

    final tenantCtx = DependencyInjection().get<TenantContext>();
    _userRole =
        tenantCtx.hasContext ? tenantCtx.usuario.role : null;

    // Recarrega ordens em tempo real e atualiza prazos a cada 2s
    _deadlinesTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _controller.carregarOrdens();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _deadlinesTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Drawer lateral ─────────────────────────────────────────────────────────

  void _abrirDrawer(OrdemPreparo ordem) {
    final parsed = DadosOrdemKanban.fromOrdem(ordem);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar drawer',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curvedAnim),
                child: PedidoDetailDrawer(
                  ordem: ordem,
                  parsed: parsed,
                  controller: _controller,
                  userRole: _userRole,
                  onStatusChanged: () => setState(() {}),
                  onImprimir: () {
                    Navigator.of(ctx).pop();
                    _exibirOpcoesImpressao(ordem, parsed);
                  },
                  onEditar: PermissaoService.podeEditarPedido(_userRole)
                      ? () async {
                          Navigator.of(ctx).pop();
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdvPage(ordemParaEditar: ordem),
                            ),
                          );
                          if (result == true) {
                            await _controller.carregarOrdens();
                          }
                        }
                      : null,
                  onCancelar:
                      PermissaoService.podeCancelarPedido(_userRole)
                          ? () async {
                              Navigator.of(ctx).pop();
                              await _cancelarPedido(ordem);
                            }
                          : null,
                  onSolicitarMotivoReversao: (de, para) =>
                      _solicitarMotivoReversao(context, de, para),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Impressão ────────────────────────────────────────────────────────────

  Future<void> _exibirOpcoesImpressao(
      OrdemPreparo o, DadosOrdemKanban parsed) async {
    final useCase = DependencyInjection().get<PrintUseCase>();
    final config = await useCase.loadConfig();

    final db = DependencyInjection().get<FincoreDatabase>();
    Map<String, int> pricesMap = {};
    try {
      final itemRows = await (db.select(db.itensPedidoTable)
            ..where((t) => t.pedidoId.equals(o.pedidoId)))
          .get();
      pricesMap = {
        for (final row in itemRows) row.produtoId: row.valorUnitarioCentavos
      };
    } catch (_) {}

    int totalEfetivo = parsed.totalCentavos;
    final printItens = o.itens.map((i) {
      final pUnit = pricesMap[i.produtoId] ?? _controller.precoUnitarioCentavos(i.produtoId);
      final itemTotal = (i.quantidade * pUnit).round();
      if (parsed.totalCentavos == 0) totalEfetivo += itemTotal;
      return PrintDataItem(
        nome: i.nomeProduto,
        quantidade: i.quantidade,
        precoUnitarioCentavos: pUnit,
        totalCentavos: itemTotal,
      );
    }).toList();

    int? numeroPedido;
    int? taxaEntregaCentavos;
    int? trocoParaCentavos;
    String? cidade;
    String? uf;
    PedidoData? pedidoRow;
    try {
      pedidoRow = await (db.select(db.pedidosTable)
            ..where((t) => t.id.equals(o.pedidoId)))
          .getSingleOrNull();
      if (pedidoRow != null) {
        numeroPedido = pedidoRow.numeroPedido;
        taxaEntregaCentavos = pedidoRow.valorTaxaEntregaCentavos;
        trocoParaCentavos = pedidoRow.trocoParaCentavos;
        if (pedidoRow.enderecoJson != null) {
          try {
            final map = jsonDecode(pedidoRow.enderecoJson!) as Map<String, dynamic>;
            cidade = map['cidade'] as String?;
            uf = map['uf'] as String?;
          } catch (_) {}
        }
      }
    } catch (_) {}

    final printData = PrintData(
      pedidoId: o.pedidoId,
      numeroPedido: numeroPedido,
      clienteNome: parsed.cliente,
      clienteTelefone: parsed.telefone,
      tipoLogistica: parsed.tipoLogistica,
      endereco: parsed.endereco,
      bairro: parsed.bairro,
      formaPagamento: parsed.pagamento,
      totalCentavos: totalEfetivo,
      taxaEntregaCentavos: taxaEntregaCentavos,
      trocoParaCentavos: trocoParaCentavos,
      itens: printItens,
      dataHora: (pedidoRow != null) ? (pedidoRow.dataHoraEntregaPrevista?.toLocal() ?? pedidoRow.dataHoraCriacao.toLocal()) : o.criadaEm.toLocal(),
      observacao: parsed.observacoesLimpa,
      status: o.status.name,
      cidade: cidade,
      uf: uf,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: FincoreColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final showCliente =
            config == null || config.isEnabled(PrintVia.cliente);
        final showCozinha =
            config == null || config.isEnabled(PrintVia.cozinha);
        final showBalcao =
            config == null || config.isEnabled(PrintVia.balcao);
        final showExpedicao =
            config == null || config.isEnabled(PrintVia.expedicao);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'IMPRESSÃO — ${printData.shortId}',
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Divider(height: 1, color: FincoreColors.border),
              ListTile(
                leading: Icon(Icons.print, color: FincoreColors.primary),
                title: const Text('Todas as vias habilitadas',
                    style: TextStyle(color: FincoreColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _executarImpressao(
                      () => useCase.imprimirPedido(data: printData));
                },
              ),
              if (showCliente)
                ListTile(
                  leading: const Icon(Icons.person,
                      color: Colors.blueAccent),
                  title: const Text('Reimprimir — Via do Cliente',
                      style: TextStyle(color: FincoreColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(
                        via: PrintVia.cliente, data: printData));
                  },
                ),
              if (showCozinha)
                ListTile(
                  leading: const Icon(Icons.restaurant,
                      color: Colors.greenAccent),
                  title: const Text('Reimprimir — Via da Cozinha',
                      style: TextStyle(color: FincoreColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(
                        via: PrintVia.cozinha, data: printData));
                  },
                ),
              if (showBalcao)
                ListTile(
                  leading: const Icon(Icons.kitchen,
                      color: Colors.amberAccent),
                  title: const Text('Reimprimir — Via do Balcão',
                      style: TextStyle(color: FincoreColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(
                        via: PrintVia.balcao, data: printData));
                  },
                ),
              if (showExpedicao)
                ListTile(
                  leading: const Icon(Icons.local_shipping,
                      color: Colors.purpleAccent),
                  title: const Text('Reimprimir — Via da Expedição',
                      style: TextStyle(color: FincoreColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(
                        via: PrintVia.expedicao, data: printData));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executarImpressao(
      Future<dynamic> Function() action) async {
    try {
      final res = await action();
      String msg = 'Impressão enviada!';
      bool success = true;
      if (res is PrinterResult) {
        msg = res.message;
        success = res.success;
      } else if (res is PrintUseCaseResult) {
        msg = res.summary;
        success = res.success;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor:
                success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao imprimir: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Cancelamento ─────────────────────────────────────────────────────────

  Future<void> _cancelarPedido(OrdemPreparo o) async {
    final motivoCtrl = TextEditingController();
    String? motivoSelecionado;

    const motivosCancelamento = [
      'Solicitado pelo cliente',
      'Erro no pedido',
      'Produto indisponível',
      'Problemas no pagamento',
      'Endereço não encontrado',
      'Cliente não atendeu',
      'Pedido duplicado',
    ];

    final motivo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 10),
              Text(
                'Motivo do Cancelamento',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                const Text(
                  'Selecione ou descreva o motivo do cancelamento:',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: motivosCancelamento.map((m) {
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
                          color: isSel ? const Color(0xFFDC2626) : FincoreColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? const Color(0xFFDC2626) : FincoreColors.border,
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
                const SizedBox(height: 14),
                TextField(
                  controller: motivoCtrl,
                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Descreva o motivo...',
                    hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: FincoreColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: FincoreColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Voltar', style: TextStyle(color: FincoreColors.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Confirmar Cancelamento'),
              onPressed: () {
                final txt = motivoCtrl.text.trim();
                if (txt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe o motivo do cancelamento.'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, txt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );

    if (motivo != null && motivo.isNotEmpty) {
      await _controller.moverStatus(o, StatusOrdemPreparo.cancelado, motivo: motivo);
    }
  }

  // ── Diálogo de reversão ──────────────────────────────────────────────────

  Future<String?> _solicitarMotivoReversao(
      BuildContext context, String deStatus, String paraStatus) async {
    final controller = TextEditingController();
    String? motivoSelecionado;
    final isReversaoEntregue = deStatus.toLowerCase().contains('entregue');

    const motivosRapidos = [
      'Cliente solicitou alteração',
      'Erro no sabor ou quantidade',
      'Retornado à cozinha',
      'Item incorreto no pedido',
      'Substituição de salgado',
    ];

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isReversaoEntregue ? Icons.warning_amber_rounded : Icons.undo_outlined,
                color: isReversaoEntregue ? FincoreColors.danger : const Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isReversaoEntregue ? '⚠️ Reverter Pedido Entregue' : 'Motivo da Reversão',
                style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isReversaoEntregue) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FincoreColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FincoreColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.inventory_2_outlined, color: FincoreColors.danger, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ESTORNO AUTOMÁTICO DE ESTOQUE:\nEste pedido já foi ENTREGUE. Ao reverter, a baixa física de estoque será ESTORNADA e os itens retornarão para a reserva operacional de preparação.',
                            style: TextStyle(
                              color: FincoreColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  'Revertendo de "$deStatus" para "$paraStatus":',
                  style: const TextStyle(
                      color: FincoreColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: motivosRapidos.map((m) {
                    final isSel = motivoSelecionado == m;
                    return InkWell(
                      onTap: () => setDialogState(() {
                        motivoSelecionado = m;
                        controller.text = m;
                      }),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? FincoreColors.primary
                              : FincoreColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? FincoreColors.primary
                                : FincoreColors.border,
                          ),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: isSel
                                ? Colors.white
                                : FincoreColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                      color: FincoreColors.textPrimary, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Descreva o motivo...',
                    hintStyle: const TextStyle(
                        color: FincoreColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: FincoreColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: FincoreColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: FincoreColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar',
                  style: TextStyle(color: FincoreColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe o motivo da reversão.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, txt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmar Reversão',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ação rápida do card ──────────────────────────────────────────────────

  StatusOrdemPreparo? _proximoStatus(OrdemPreparo o) {
    switch (o.status) {
      case StatusOrdemPreparo.pendente:
        return PermissaoService.podeIniciarPreparo(_userRole)
            ? StatusOrdemPreparo.emPreparo
            : null;
      case StatusOrdemPreparo.emPreparo:
        return PermissaoService.podeConcluirPreparo(_userRole)
            ? StatusOrdemPreparo.pronto
            : null;
      case StatusOrdemPreparo.pronto:
        return PermissaoService.podeEntregar(_userRole)
            ? StatusOrdemPreparo.entregue
            : null;
      default:
        return null;
    }
  }

  String _acaoRapidaLabel(OrdemPreparo o) {
    switch (o.status) {
      case StatusOrdemPreparo.pendente:
        return 'Iniciar';
      case StatusOrdemPreparo.emPreparo:
        return 'Pronto';
      case StatusOrdemPreparo.pronto:
        return 'Entregar';
      default:
        return '';
    }
  }

  // ── Build principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: FincoreColors.primary),
          );
        }

        if (_controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: FincoreColors.danger),
                const SizedBox(height: 12),
                Text(_controller.error!,
                    style: const TextStyle(
                        color: FincoreColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.carregarOrdens,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-Abas Superiores no TOPO Absoluto (Identidade com as demais telas do ERP)
            Row(
              children: [
                _buildSubTab('Painel de Preparação (Kanban)', Icons.view_kanban_outlined, 0),
                const SizedBox(width: 16),
                _buildSubTab('Histórico & Todos os Pedidos', Icons.list_alt_outlined, 1),
              ],
            ),
            const SizedBox(height: 14),

            if (_activeSubTab == 0) ...[
              // ── Barra de controle ────────────────────────────────────
              _buildControlBar(),
              const SizedBox(height: 14),

              // ── Kanban Board ─────────────────────────────────────────
              Expanded(child: _buildKanbanBoard()),
            ] else ...[
              // ── Histórico & Todos os Pedidos (Lista / Tabela) ────────
              Expanded(child: _buildHistoryPanel()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSubTab(String label, IconData icon, int index) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _activeSubTab = index);
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
                color: isSelected ? FincoreColors.primary : FincoreColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'entregue' || s == 'concluido' || s == 'concluído' || s == 'finalizado') {
      return FincoreColors.success;
    }
    if (s == 'cancelado') {
      return FincoreColors.danger;
    }
    if (s == 'em_preparo' || s == 'preparo' || s == 'em-preparo') {
      return const Color(0xFFF59E0B);
    }
    if (s == 'pronto') {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF3B82F6);
  }

  String _labelOrigem(String logistica) {
    final l = logistica.toLowerCase();
    if (l.contains('entrega') || l.contains('delivery')) return 'Entrega';
    if (l.contains('retirada') || l.contains('balcao') || l.contains('balcão')) return 'Retirada';
    return logistica;
  }

  Widget _buildFilterChipDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isActive = value != items.keys.first;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? FincoreColors.primary.withValues(alpha: 0.12)
            : FincoreColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? FincoreColors.primary : FincoreColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Icon(Icons.expand_more, size: 14,
              color: isActive ? FincoreColors.primary : FincoreColors.textMuted),
          dropdownColor: FincoreColors.surface,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? FincoreColors.primary : FincoreColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: FincoreColors.textMuted),
                        const SizedBox(width: 5),
                        Text(e.value),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePickerChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? FincoreColors.primary.withValues(alpha: 0.12)
              : FincoreColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? FincoreColors.primary : FincoreColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: isActive ? FincoreColors.primary : FincoreColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? FincoreColors.primary : FincoreColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 12,
                    color: FincoreColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    final searchLower = _historySearchQuery.toLowerCase().trim();
    final dateFrom = _historyDateFrom != null
        ? DateTime(_historyDateFrom!.year, _historyDateFrom!.month, _historyDateFrom!.day)
        : null;
    final dateTo = _historyDateTo != null
        ? DateTime(_historyDateTo!.year, _historyDateTo!.month, _historyDateTo!.day, 23, 59, 59)
        : null;

    final list = _controller.historicoPedidos.where((p) {
      final st = p.status.toLowerCase().trim();
      final matchesStatus = _historyStatusFilter == 'Todos' ||
          st == _historyStatusFilter.toLowerCase().trim();

      final matchesSearch = searchLower.isEmpty ||
          (p.numeroPedido?.toString() ?? '').contains(searchLower) ||
          (p.clienteNomeAvulso ?? '').toLowerCase().contains(searchLower) ||
          p.id.toLowerCase().contains(searchLower);

      final pedidoData = p.dataHoraCriacao.toLocal();
      final matchesFrom = dateFrom == null || !pedidoData.isBefore(dateFrom);
      final matchesTo = dateTo == null || !pedidoData.isAfter(dateTo);

      final matchesOrigem = _historyOrigemFilter == 'Todos' ||
          _labelOrigem(p.tipoLogistica) == _historyOrigemFilter;

      return matchesStatus && matchesSearch && matchesFrom && matchesTo && matchesOrigem;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Linha 1: Busca textual + Contador de resultados ────────────
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: FincoreColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _historySearchQuery = val),
                        style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Buscar por cliente, número ou ID...',
                          hintStyle: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FincoreColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${list.length} pedido${list.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FincoreColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Linha 2: Filtros avançados ─────────────────────────────────
        Row(
          children: [
            // Status
            _buildFilterChipDropdown<String>(
              label: 'Status',
              icon: Icons.flag_outlined,
              value: _historyStatusFilter,
              items: {
                'Todos': 'Todos',
                'confirmado': 'Confirmado',
                'pendente': 'Pendente',
                'em_preparo': 'Em Preparo',
                'pronto': 'Pronto',
                'entregue': 'Entregue',
                'cancelado': 'Cancelado',
              },
              onChanged: (v) => setState(() => _historyStatusFilter = v ?? 'Todos'),
            ),
            const SizedBox(width: 8),

            // Logística / Origem
            _buildFilterChipDropdown<String>(
              label: 'Logística',
              icon: Icons.local_shipping_outlined,
              value: _historyOrigemFilter,
              items: {
                'Todos': 'Todos',
                'Entrega': 'Entrega',
                'Retirada': 'Retirada',
              },
              onChanged: (v) => setState(() => _historyOrigemFilter = v ?? 'Todos'),
            ),
            const SizedBox(width: 8),

            // Data De
            _buildDatePickerChip(
              label: _historyDateFrom != null
                  ? 'De: ${DateFormat('dd/MM/yy').format(_historyDateFrom!)}'
                  : 'Data inicial',
              icon: Icons.calendar_today_outlined,
              isActive: _historyDateFrom != null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _historyDateFrom ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(primary: FincoreColors.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _historyDateFrom = picked);
              },
              onClear: _historyDateFrom != null
                  ? () => setState(() => _historyDateFrom = null)
                  : null,
            ),
            const SizedBox(width: 8),

            // Data Até
            _buildDatePickerChip(
              label: _historyDateTo != null
                  ? 'Até: ${DateFormat('dd/MM/yy').format(_historyDateTo!)}'
                  : 'Data final',
              icon: Icons.event_outlined,
              isActive: _historyDateTo != null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _historyDateTo ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(primary: FincoreColors.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _historyDateTo = picked);
              },
              onClear: _historyDateTo != null
                  ? () => setState(() => _historyDateTo = null)
                  : null,
            ),

            const Spacer(),

            // Botão limpar todos os filtros
            if (_historyStatusFilter != 'Todos' ||
                _historyOrigemFilter != 'Todos' ||
                _historyDateFrom != null ||
                _historyDateTo != null ||
                _historySearchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() {
                  _historyStatusFilter = 'Todos';
                  _historyOrigemFilter = 'Todos';
                  _historyDateFrom = null;
                  _historyDateTo = null;
                  _historySearchQuery = '';
                }),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpar filtros', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: FincoreColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Lista / Tabela de Pedidos
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum pedido encontrado.',
                    style: TextStyle(color: FincoreColors.textMuted),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(FincoreColors.background),
                          dataRowMaxHeight: 52,
                          columns: const [
                            DataColumn(label: Text('Número', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                            DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                            DataColumn(label: Text('Data / Hora Entrega', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                            DataColumn(label: Text('Origem / Logística', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                            DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                          ],
                          rows: list.map((p) {
                            // Prioridade: hora de entrega prevista > hora de criação do pedido
                            final dataRefEntrega = p.dataHoraEntregaPrevista ?? p.dataHoraCriacao;
                            final dateStr = FinCoreDateFormatter.formatDateTimeWithWeekday(dataRefEntrega.toLocal());
                            final totalStr = 'R\$ ${(p.valorTotalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';
                            final statusColor = _statusColor(p.status);
                            final statusLabel = p.status.toUpperCase();
                            final shortId = p.id.length > 8 ? p.id.substring(0, 8) : p.id;
                            final displayNum = p.numeroPedido != null ? '#${p.numeroPedido}' : '#$shortId';

                            return DataRow(
                              cells: [
                                DataCell(Text(displayNum, style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                                DataCell(Text(p.clienteNomeAvulso ?? 'Consumidor Avulso', style: const TextStyle(color: FincoreColors.textPrimary))),
                                DataCell(Text(dateStr, style: const TextStyle(color: FincoreColors.textSecondary))),
                                DataCell(Text('${p.canalOrigem} / ${p.tipoLogistica}', style: const TextStyle(color: FincoreColors.textSecondary))),
                                DataCell(Text(totalStr, style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18),
                                        tooltip: 'Ver Detalhes',
                                        color: FincoreColors.textSecondary,
                                        onPressed: () {
                                          final matchingOrdens = _controller.todasOrdens.where((ord) => ord.pedidoId == p.id);
                                          final o = matchingOrdens.isNotEmpty
                                              ? matchingOrdens.first
                                              : OrdemPreparo(
                                                  id: p.id,
                                                  tenantId: p.tenantId,
                                                  pedidoId: p.id,
                                                  status: StatusOrdemPreparo.values.firstWhere(
                                                    (v) => v.name.toLowerCase() == p.status.toLowerCase().trim(),
                                                    orElse: () => StatusOrdemPreparo.pendente,
                                                  ),
                                                  itens: const [],
                                                  prioridade: PrioridadeOrdem.normal,
                                                  criadaEm: p.dataHoraCriacao,
                                                  tempoEstimadoSegundos: 600,
                                                  metadata: SyncMetadata(
                                                    version: p.syncVersion,
                                                    createdAt: p.createdAt,
                                                    updatedAt: p.updatedAt,
                                                    createdBy: p.createdBy ?? '',
                                                    updatedBy: p.updatedBy ?? '',
                                                  ),
                                                );
                                          _abrirDrawer(o);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }



  // ── Barra de controle: data + origem + novo pedido ────────────────────────

  Widget _buildControlBar() {
    final formattedDate = _controller.formattedDate();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        children: [
          // Navegação de data
          const Text(
            'Data:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: FincoreColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          _DateNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _controller.mudarDia(-1),
          ),
          const SizedBox(width: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Text(
              formattedDate,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: FincoreColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _DateNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _controller.mudarDia(1),
          ),

          const SizedBox(width: 16),
          Container(
              width: 1, height: 20, color: FincoreColors.borderSubtle),
          const SizedBox(width: 16),

          // Filtro de origem
          const Text(
            'Origem:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: FincoreColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          _OrigemChip(
            label: 'Todos',
            selected: _controller.selectedOrigem == 'Todos',
            onTap: () => _controller.setOrigem('Todos'),
          ),
          const SizedBox(width: 6),
          _OrigemChip(
            label: 'Balcão',
            selected: _controller.selectedOrigem == 'Balcão',
            onTap: () => _controller.setOrigem('Balcão'),
          ),
          const SizedBox(width: 6),
          _OrigemChip(
            label: 'Mesa',
            selected: _controller.selectedOrigem == 'Mesa',
            onTap: () => _controller.setOrigem('Mesa'),
          ),
          const SizedBox(width: 6),
          _OrigemChip(
            label: 'Entrega',
            selected: _controller.selectedOrigem == 'Entrega',
            onTap: () => _controller.setOrigem('Entrega'),
          ),

          const Spacer(),

          // Resumo Operacional Compacto
          Text(
            '${_controller.totalPedidos} pedido${_controller.totalPedidos > 1 ? 's' : ''} · '
            '${_controller.totalEntregas} entrega${_controller.totalEntregas > 1 ? 's' : ''} · '
            '${_controller.totalRetiradas} retirada${_controller.totalRetiradas > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FincoreColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),

          // Botão Novo Pedido
          if (PermissaoService.podeCriarPedido(_userRole))
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PdvPage()),
                );
                if (result == true) await _controller.carregarOrdens();
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Novo Pedido',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Kanban Board ──────────────────────────────────────────────────────────

  Widget _buildKanbanBoard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Coluna PENDENTES
        Expanded(
          child: KanbanColumn(
            title: 'Pendentes',
            accentColor: const Color(0xFFF97316),
            ordens: _controller.pendentes,
            cardBuilder: (o, _) {
              final parsed = DadosOrdemKanban.fromOrdem(o);
              return PedidoCard(
                ordem: o,
                parsed: parsed,
                controller: _controller,
                userRole: _userRole,
                accentColor: const Color(0xFFF97316),
                mostrarAcaoRapida: _proximoStatus(o) != null,
                acaoRapidaLabel: _acaoRapidaLabel(o),
                onAcaoRapida: _proximoStatus(o) != null
                    ? () => _controller.moverStatus(o, _proximoStatus(o)!)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // Coluna EM PREPARO
        Expanded(
          child: KanbanColumn(
            title: 'Em Preparo',
            accentColor: const Color(0xFFF59E0B),
            ordens: _controller.emPreparo,
            cardBuilder: (o, _) {
              final parsed = DadosOrdemKanban.fromOrdem(o);
              return PedidoCard(
                ordem: o,
                parsed: parsed,
                controller: _controller,
                userRole: _userRole,
                accentColor: const Color(0xFFF59E0B),
                mostrarAcaoRapida: _proximoStatus(o) != null,
                acaoRapidaLabel: _acaoRapidaLabel(o),
                onAcaoRapida: _proximoStatus(o) != null
                    ? () => _controller.moverStatus(o, _proximoStatus(o)!)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // Coluna PRONTOS
        Expanded(
          child: KanbanColumn(
            title: 'Prontos',
            accentColor: const Color(0xFF06B6D4),
            ordens: _controller.prontos,
            cardBuilder: (o, _) {
              final parsed = DadosOrdemKanban.fromOrdem(o);
              return PedidoCard(
                ordem: o,
                parsed: parsed,
                controller: _controller,
                userRole: _userRole,
                accentColor: const Color(0xFF06B6D4),
                mostrarAcaoRapida: _proximoStatus(o) != null,
                acaoRapidaLabel: _acaoRapidaLabel(o),
                onAcaoRapida: _proximoStatus(o) != null
                    ? () => _controller.moverStatus(o, _proximoStatus(o)!)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // Coluna ENTREGUES — modo compacto
        Expanded(
          child: KanbanColumn(
            title: 'Entregues',
            accentColor: const Color(0xFF10B981),
            ordens: _controller.entregues,
            modoCompacto: true,
            cardBuilder: (o, _) => _EntregueCompactRow(
              ordem: o,
              parsed: DadosOrdemKanban.fromOrdem(o),
              onTap: () => _abrirDrawer(o),
              controller: _controller,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widget compacto para a coluna Entregues ──────────────────────────────────

class _EntregueCompactRow extends StatelessWidget {
  final OrdemPreparo ordem;
  final DadosOrdemKanban parsed;
  final VoidCallback onTap;
  final CentralPedidosController controller;

  const _EntregueCompactRow({
    required this.ordem,
    required this.parsed,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final numero = controller.getNumeroPedido(ordem.pedidoId);
    final shortId = numero != null
        ? '#${numero.toString().padLeft(4, '0')}'
        : (ordem.pedidoId.length > 6
            ? '#${ordem.pedidoId.substring(0, 6).toUpperCase()}'
            : '#${ordem.pedidoId.toUpperCase()}');

    // Horário de conclusão (concluidaEm) ou fallback para criadaEm
    final horaFinalizada = ordem.concluidaEm != null
        ? DateFormat('HH:mm').format(ordem.concluidaEm!.toLocal())
        : DateFormat('HH:mm').format(ordem.criadaEm.toLocal());

    final isDelivery = parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        parsed.tipoLogistica.toLowerCase().contains('delivery');

    // Total de itens (unidades) obtido do parser
    final totalItens = parsed.totalUnidades;
    final totalItensStr = totalItens % 1 == 0
        ? totalItens.toStringAsFixed(0)
        : totalItens.toStringAsFixed(1);

    // Valor total formatado obtido do parser
    final valorTotal = parsed.totalCentavos;
    final valorFormatado = 'R\$ ${(valorTotal / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            // Ícone de logística
            Icon(
              isDelivery ? Icons.delivery_dining_outlined : Icons.storefront_outlined,
              size: 14,
              color: isDelivery ? const Color(0xFF10B981) : FincoreColors.textMuted,
            ),
            const SizedBox(width: 6),
            // ID do pedido
            Text(
              shortId,
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            // Nome do cliente
            Expanded(
              child: Text(
                parsed.cliente.isEmpty ? 'Consumidor' : parsed.cliente,
                style: const TextStyle(
                  color: FincoreColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // Quantidade de unidades
            Text(
              '${totalItensStr}un',
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            // Valor total
            Text(
              valorFormatado,
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            // Horário de conclusão
            Text(
              horaFinalizada,
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }
}



class _DateNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DateNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Icon(icon, size: 16, color: FincoreColors.textMuted),
      ),
    );
  }
}

class _OrigemChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OrigemChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? FincoreColors.primary : FincoreColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? FincoreColors.primary
                : FincoreColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected
                ? Colors.white
                : FincoreColors.textSecondary,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
