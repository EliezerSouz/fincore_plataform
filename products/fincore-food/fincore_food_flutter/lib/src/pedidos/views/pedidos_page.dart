import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
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
import 'package:fincore_food_flutter/src/shared/services/sound_service.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/whatsapp_dialog.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';



// ─── Central Operacional de Pedidos ─────────────────────────────────────────

class PedidosPage extends StatefulWidget {
  static DateTime? dataPreSelecionada;
  static String? filtroPedidoId;
  static _PedidosPageState? _activeState;

  static void navegarParaData(DateTime data, {String? pedidoId}) {
    dataPreSelecionada = data;
    filtroPedidoId = pedidoId;
    if (_activeState != null && _activeState!.mounted) {
      _activeState!._controller.setSelectedDate(data);
      if (pedidoId != null) {
        _activeState!._historySearchQuery = pedidoId;
      }
      _activeState!._controller.carregarOrdens();
      _activeState!._forceRebuild();
    }
  }

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
  final Set<String> _processandoAcaoRapida = {};

  void _forceRebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    PedidosPage._activeState = this;
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

    _controller.addListener(_onControllerChanged);

    // Recarrega ordens em tempo real e atualiza prazos/alertas a cada 2s
    _deadlinesTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _controller.carregarOrdens();
        _controller.checkProximityAudioAlerts();
        setState(() {});
      }
    });
  }

  String? _lastNotifiedNewOrderId;

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.lastNewOrder != null && _controller.lastNewOrder!.id != _lastNotifiedNewOrderId) {
      _lastNotifiedNewOrderId = _controller.lastNewOrder!.id;
      final parsed  = DadosOrdemKanban.fromOrdem(_controller.lastNewOrder!);
      final numPed  = _controller.getNumeroPedido(_controller.lastNewOrder!.pedidoId);
      final numStr  = numPed != null ? '#$numPed' : '';
      final isWeb   = _controller.lastNewOrder!.observacoes?.contains('cardapio_web') == true || _controller.lastNewOrder!.observacoes?.contains('web') == true;

      // Pedidos do Cardápio Web ganham destaque azul e mensagem especial
      final bgColor = isWeb ? const Color(0xFF1D4ED8) : FincoreColors.primary;
      final title   = isWeb
          ? '🌐 PEDIDO WEB CHEGOU $numStr'
          : '🔔 NOVO PEDIDO CHEGOU $numStr';
      final subtitle = isWeb
          ? 'Cliente: ${parsed.cliente} • Cardápio Digital Online'
          : 'Cliente: ${parsed.cliente} • Origem: ${parsed.tipoLogistica}';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(
                isWeb ? Icons.language_rounded : Icons.notifications_active_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (PedidosPage._activeState == this) {
      PedidosPage._activeState = null;
    }
    _deadlinesTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
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
                      ? () {
                          Navigator.of(ctx).pop();
                          FincoreShell.editarPedido(context, ordem);
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
                  onSolicitarReversao: (ordem, opcoes) =>
                      _solicitarReversaoComDestino(context, ordem, opcoes),
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
      final notificado = await _isWhatsAppDisparadoAutomatico(o, WhatsAppService.kEventoPedidoCancelado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notificado
                        ? '❌ Pedido cancelado e cliente notificado via WhatsApp.'
                        : '❌ Pedido cancelado com sucesso.',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<bool> _isWhatsAppDisparadoAutomatico(OrdemPreparo o, String eventoId) async {
    try {
      final hierarquia = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: eventoId,
        tenantId: o.tenantId,
      );
      if (hierarquia.eventoDesativado || !hierarquia.podeDispararAutomatico || !hierarquia.isApiConectada) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Diálogo de reversão avançado com escolha de status destino ──────────

  Future<({StatusOrdemPreparo destino, String motivo})?> _solicitarReversaoComDestino(
    BuildContext context,
    OrdemPreparo ordem,
    List<StatusOrdemPreparo> opcoesDestino,
  ) async {
    if (opcoesDestino.isEmpty) return null;

    final controller = TextEditingController();
    String? motivoSelecionado;
    StatusOrdemPreparo destinoSelecionado = opcoesDestino.first;
    final isReversaoEntregue = ordem.status == StatusOrdemPreparo.entregue;

    const motivosRapidos = [
      'Cliente solicitou alteração',
      'Erro no sabor ou quantidade',
      'Retornado à cozinha',
      'Item incorreto no pedido',
      'Substituição de salgado',
      'Problema logístico / endereço',
    ];

    String formatStatusName(StatusOrdemPreparo s) {
      switch (s) {
        case StatusOrdemPreparo.pendente:
          return '⏳ Pendente';
        case StatusOrdemPreparo.emPreparo:
          return '🍳 Em Preparo';
        case StatusOrdemPreparo.pronto:
          return '✅ Pronto';
        case StatusOrdemPreparo.saiuParaEntrega:
          return '🛵 Saiu p/ Entrega';
        case StatusOrdemPreparo.entregue:
          return '📦 Entregue';
        case StatusOrdemPreparo.cancelado:
          return '🚫 Cancelado';
      }
    }

    Color formatStatusColor(StatusOrdemPreparo s) {
      switch (s) {
        case StatusOrdemPreparo.pendente:
          return const Color(0xFFF97316);
        case StatusOrdemPreparo.emPreparo:
          return const Color(0xFFF59E0B);
        case StatusOrdemPreparo.pronto:
          return const Color(0xFF10B981);
        case StatusOrdemPreparo.saiuParaEntrega:
          return const Color(0xFF06B6D4);
        case StatusOrdemPreparo.entregue:
          return const Color(0xFF10B981);
        case StatusOrdemPreparo.cancelado:
          return const Color(0xFFEF4444);
      }
    }

    return showDialog<({StatusOrdemPreparo destino, String motivo})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isReversaoEntregue ? Icons.warning_amber_rounded : Icons.undo_outlined,
                color: isReversaoEntregue ? FincoreColors.danger : const Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isReversaoEntregue ? '⚠️ Reverter Pedido Entregue' : 'Reverter Status do Pedido',
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
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
                  Row(
                    children: [
                      const Text(
                        'Status Atual: ',
                        style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: formatStatusColor(ordem.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: formatStatusColor(ordem.status).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          formatStatusName(ordem.status),
                          style: TextStyle(
                            color: formatStatusColor(ordem.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecione para qual status deseja reverter:',
                    style: TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: opcoesDestino.map((opt) {
                      final isSelected = opt == destinoSelecionado;
                      final cor = formatStatusColor(opt);
                      return InkWell(
                        onTap: () => setDialogState(() => destinoSelecionado = opt),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? cor.withValues(alpha: 0.18) : FincoreColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? cor : FincoreColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(Icons.check_circle_rounded, color: cor, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                formatStatusName(opt),
                                style: TextStyle(
                                  color: isSelected ? cor : FincoreColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Motivo da Reversão (Obrigatório):',
                    style: TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? FincoreColors.primary : FincoreColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel ? FincoreColors.primary : FincoreColors.border,
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
                    controller: controller,
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Descreva o motivo da reversão...',
                      hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: FincoreColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: FincoreColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: FincoreColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, informe ou selecione o motivo da reversão.'),
                      backgroundColor: FincoreColors.danger,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, (destino: destinoSelecionado, motivo: txt));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirmar Reversão', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Diálogo de reversão legado ───────────────────────────────────────────

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
    final pedido = _controller.pedidosMap[o.pedidoId];
    final parsed = DadosOrdemKanban.fromOrdem(o);
    final isDelivery = (pedido?.tipoLogistica.toLowerCase().contains('entrega') ?? false) ||
        parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        parsed.tipoLogistica.toLowerCase().contains('delivery');

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
        if (isDelivery) {
          return PermissaoService.podeEntregar(_userRole)
              ? StatusOrdemPreparo.saiuParaEntrega
              : null;
        }
        return PermissaoService.podeEntregar(_userRole)
            ? StatusOrdemPreparo.entregue
            : null;
      case StatusOrdemPreparo.saiuParaEntrega:
        return PermissaoService.podeEntregar(_userRole)
            ? StatusOrdemPreparo.entregue
            : null;
      default:
        return null;
    }
  }

  String _acaoRapidaLabel(OrdemPreparo o) {
    final pedido = _controller.pedidosMap[o.pedidoId];
    final parsed = DadosOrdemKanban.fromOrdem(o);
    final isDelivery = (pedido?.tipoLogistica.toLowerCase().contains('entrega') ?? false) ||
        parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        parsed.tipoLogistica.toLowerCase().contains('delivery');

    switch (o.status) {
      case StatusOrdemPreparo.pendente:
        if (_controller.isPedidoAguardandoAprovacao(o)) {
          return 'Aprovar Pedido';
        }
        return 'Iniciar';
      case StatusOrdemPreparo.emPreparo:
        return 'Pronto';
      case StatusOrdemPreparo.pronto:
        return isDelivery ? 'Saiu p/ Entrega' : 'Entregar';
      case StatusOrdemPreparo.saiuParaEntrega:
        return 'Entregar';
      default:
        return '';
    }
  }

  Future<void> _executarAcaoRapida(OrdemPreparo o) async {
    if (_processandoAcaoRapida.contains(o.id)) return;
    _processandoAcaoRapida.add(o.id);

    try {
      // Se for um pedido Web que ainda aguarda aprovação, aprova e mantém na fila como pendente
      if (o.status == StatusOrdemPreparo.pendente && _controller.isPedidoAguardandoAprovacao(o)) {
        await _controller.aprovarPedidoWeb(o);
        final notificado = await _isWhatsAppDisparadoAutomatico(o, WhatsAppService.kEventoPedidoAprovadoWeb);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: FincoreColors.success,
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notificado
                          ? '✅ Pedido Web aceito e cliente notificado via WhatsApp!'
                          : '✅ Pedido Web aceito com sucesso!',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final prox = _proximoStatus(o);
      if (prox == null) return;

      await _controller.moverStatus(o, prox);

      // Se avançou para saiuParaEntrega, notifica o cliente conforme hierarquia
      if (prox == StatusOrdemPreparo.saiuParaEntrega && mounted) {
        final hierarquia = await WhatsAppService.avaliarHierarquiaEvento(
          eventoId: WhatsAppService.kEventoPedidoSaiuEntrega,
          tenantId: o.tenantId,
        );

        if (hierarquia.eventoDesativado) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
                content: Row(
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🛵 Pedido marcado como saiu para entrega!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (hierarquia.podeDispararAutomatico && hierarquia.isApiConectada) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
                content: Row(
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🛵 Pedido saiu para entrega e cliente notificado via WhatsApp!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          // Contingência manual somente se a política for manual ou API desconectada
          _abrirWhatsAppParaOrdem(o, saiuParaEntrega: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _processandoAcaoRapida.remove(o.id));
      } else {
        _processandoAcaoRapida.remove(o.id);
      }
    }
  }

  Future<void> _abrirWhatsAppParaOrdem(OrdemPreparo o, {bool saiuParaEntrega = false}) async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final parsed = DadosOrdemKanban.fromOrdem(o);

      PedidoData? pedidoRow;
      try {
        pedidoRow = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(o.pedidoId)))
            .getSingleOrNull();
      } catch (_) {}

      final pedidoMemoria = _controller.pedidosMap[o.pedidoId];

      String? tel = pedidoRow?.clienteTelefoneAvulso ?? pedidoMemoria?.clienteTelefoneAvulso;
      String nome = pedidoRow?.clienteNomeAvulso ?? pedidoMemoria?.clienteNomeAvulso ?? parsed.cliente;
      final clienteId = pedidoRow?.clienteId ?? pedidoMemoria?.clienteId;

      if (clienteId != null && (tel == null || tel.isEmpty)) {
        try {
          final clienteRow = await (db.select(db.clientesTable)
                ..where((c) => c.id.equals(clienteId) & c.deletedAt.isNull()))
              .getSingleOrNull();
          if (clienteRow != null) {
            tel = clienteRow.telefone;
            if (clienteRow.nome.isNotEmpty) {
              nome = clienteRow.nome;
            }
          }
        } catch (_) {}
      }

      if (tel == null || tel.isEmpty) {
        tel = parsed.telefone;
      }

      if (tel.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: FincoreColors.danger,
              content: Text('Nenhum telefone cadastrado para este cliente.'),
            ),
          );
        }
        return;
      }

      // ── Itens do pedido ──────────────────────────────────────────
      List<ItemPedidoData> itemRows = [];
      try {
        itemRows = await (db.select(db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(o.pedidoId) & t.deletedAt.isNull()))
            .get();
      } catch (_) {}

      List<Map<String, dynamic>> itensWhats = [];
      if (itemRows.isNotEmpty) {
        itensWhats = itemRows.map((it) => {
          'nome': it.nomeProduto,
          'qtd': it.quantidade,
          'unit': it.valorUnitarioCentavos / 100.0,
          'total': it.valorTotalCentavos / 100.0,
          'obs': it.observacoes,
        }).toList();
      } else {
        itensWhats = o.itens.map((it) {
          final pUnit = _controller.precoUnitarioCentavos(it.produtoId);
          final totalItemCentavos = (it.quantidade * pUnit).round();
          return {
            'nome': it.nomeProduto,
            'qtd': it.quantidade,
            'unit': pUnit / 100.0,
            'total': totalItemCentavos / 100.0,
            'obs': null,
          };
        }).toList();
      }

      // ── Endereço de entrega ───────────────────────────────────────
      String? enderecoStr;
      if (pedidoRow?.enderecoJson != null && pedidoRow!.enderecoJson!.isNotEmpty) {
        try {
          final map = jsonDecode(pedidoRow.enderecoJson!) as Map<String, dynamic>;
          final logradouro = (map['logradouro'] as String?)?.trim() ?? '';
          final numero = (map['numero'] as String?)?.trim() ?? '';
          final bairro = (map['bairro'] as String?)?.trim() ?? '';
          final cidade = (map['cidade'] as String?)?.trim() ?? '';
          final complemento = (map['complemento'] as String?)?.trim() ?? '';
          final ref = (map['pontoReferencia'] as String? ?? map['referencia'] as String?)?.trim() ?? '';

          final parts = <String>[];
          if (logradouro.isNotEmpty) {
            parts.add(numero.isNotEmpty ? '$logradouro, $numero' : logradouro);
          }
          if (complemento.isNotEmpty) parts.add(complemento);
          if (bairro.isNotEmpty) parts.add(bairro);
          if (cidade.isNotEmpty) parts.add(cidade);
          if (ref.isNotEmpty) parts.add('(Ref: $ref)');
          if (parts.isNotEmpty) enderecoStr = parts.join(' - ');
        } catch (_) {}
      }
      if (enderecoStr == null || enderecoStr.isEmpty) {
        final endParsed = parsed.endereco;
        final bairroParsed = parsed.bairro;
        if (endParsed != null && endParsed.isNotEmpty) {
          enderecoStr = endParsed + (bairroParsed != null && bairroParsed.isNotEmpty ? ' - $bairroParsed' : '');
        }
      }

      // ── Data e Hora prevista ──────────────────────────────────────
      final dt = pedidoRow?.dataHoraEntregaPrevista?.toLocal() ??
                 pedidoRow?.dataHoraCriacao.toLocal() ??
                 o.criadaEm.toLocal();
      final dataStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      // ── Logística e Pagamento ─────────────────────────────────────
      final tipoAtendimento = pedidoRow?.tipoLogistica ?? parsed.tipoLogistica;
      final formaPagtoStr = pedidoRow?.formaPagamentoNome ?? parsed.pagamento;

      // ── Valores monetários ────────────────────────────────────────
      final subtotal = (pedidoRow != null && pedidoRow.valorSubtotalCentavos > 0)
          ? (pedidoRow.valorSubtotalCentavos / 100.0)
          : itensWhats.fold<double>(0.0, (acc, item) => acc + ((item['total'] as num?)?.toDouble() ?? 0.0));
      final taxaEntrega = (pedidoRow?.valorTaxaEntregaCentavos ?? 0) / 100.0;
      final taxaServico = (pedidoRow?.valorTaxaServicoCentavos ?? 0) / 100.0;
      final total = (pedidoRow != null && pedidoRow.valorTotalCentavos > 0)
          ? (pedidoRow.valorTotalCentavos / 100.0)
          : (_controller.totalOrdemCentavos(o) / 100.0);

      // ── Observações ───────────────────────────────────────────────
      final obs = (pedidoRow?.observacoes != null && pedidoRow!.observacoes!.isNotEmpty)
          ? pedidoRow.observacoes
          : (parsed.observacoesLimpa.isNotEmpty ? parsed.observacoesLimpa : null);

      // ── Busca forma de pagamento para verificar se é PIX ──────────
      String? pixChave;
      String? pixTipoChave;
      bool isPix = false;
      final formaPagamentoId = pedidoRow?.formaPagamentoId ?? pedidoMemoria?.formaPagamentoId;

      if (formaPagamentoId != null) {
        try {
          final fpRow = await (db.select(db.formasPagamentoTable)
                ..where((f) => f.id.equals(formaPagamentoId) & f.deletedAt.isNull()))
              .getSingleOrNull();
          if (fpRow != null) {
            isPix = fpRow.tipo == 'pix' || (fpRow.pixChave != null && fpRow.pixChave!.isNotEmpty);
            if (isPix) {
              pixChave = fpRow.pixChave;
              pixTipoChave = fpRow.pixTipoChave;
            }
          }
        } catch (_) {}
      }

      PixWhatsAppInfo? pixInfo;
      if (isPix && pixChave != null && pixChave.isNotEmpty) {
        try {
          final totalCentavos = (total * 100).round();
          final config = await (db.select(db.empresaConfiguracaoTable)..limit(1)).getSingleOrNull();

          final copiaECola = PixGenerator.gerarCopiaCola(
            chave: pixChave,
            favorecido: (config?.pixFavorecido != null && config!.pixFavorecido!.isNotEmpty)
                ? config.pixFavorecido!
                : nome,
            cidade: 'Sorocaba',
            valor: totalCentavos / 100.0,
            tipoChave: pixTipoChave,
          );

          pixInfo = PixWhatsAppInfo(
            chaveDisplay: pixChave,
            tipoChave: pixTipoChave ?? 'PIX',
            copiaECola: copiaECola,
          );
        } catch (pixErr) {
          debugPrint('[PedidosPage] Erro ao gerar PIX para WhatsApp: $pixErr');
        }
      }

      final numPedido = (pedidoRow?.numeroPedido != null)
          ? '#${pedidoRow!.numeroPedido.toString().padLeft(6, '0')}'
          : (pedidoMemoria?.numeroPedido != null
              ? '#${pedidoMemoria!.numeroPedido.toString().padLeft(6, '0')}'
              : '#${o.pedidoId.length > 6 ? o.pedidoId.substring(0, 6).toUpperCase() : o.pedidoId.toUpperCase()}');

      String? empresaNome;
      try {
        if (TenantContext().hasContext) {
          empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
              ? TenantContext().empresa.nomeFantasia
              : TenantContext().empresa.razaoSocial;
        }
      } catch (_) {}

      if (!mounted) return;

      final resumoWhats = WhatsAppService.gerarTextoResumoPedido(
        nomeCliente: nome,
        numeroPedidoOuId: numPedido.replaceAll('#', ''),
        tipoAtendimento: tipoAtendimento,
        dataHoraPrevista: dataStr,
        itens: itensWhats,
        subtotal: subtotal,
        taxaEntrega: taxaEntrega,
        taxaServico: taxaServico,
        total: total,
        formaPagamento: formaPagtoStr,
        enderecoEntrega: tipoAtendimento.toLowerCase().contains('entrega') ? enderecoStr : null,
        observacoes: obs,
        nomeEmpresa: empresaNome,
      );

      final initialMsg = saiuParaEntrega
          ? WhatsAppService.gerarTextoSaiuParaEntrega(
              nomeCliente: nome,
              numeroPedidoOuId: numPedido,
              nomeEmpresa: empresaNome,
            )
          : resumoWhats;

      final calcDescontoCentavos = (pedidoRow != null)
          ? ((pedidoRow.valorSubtotalCentavos + pedidoRow.valorTaxaEntregaCentavos + pedidoRow.valorTaxaServicoCentavos) - pedidoRow.valorTotalCentavos)
          : 0;
      final descontoCalculado = calcDescontoCentavos > 0 ? (calcDescontoCentavos / 100.0) : 0.0;
      final trocoStr = (pedidoRow?.trocoParaCentavos != null && pedidoRow!.trocoParaCentavos! > 0)
          ? 'R\$ ${(pedidoRow.trocoParaCentavos! / 100.0).toStringAsFixed(2).replaceAll('.', ',')}'
          : null;

      // Verifica se houve recebimento financeiro registrado
      bool isPago = false;
      try {
        final lanc = await (db.select(db.lancamentosFinanceirosTable)
              ..where((l) =>
                  l.pedidoId.equals(o.pedidoId) &
                  l.tipo.equals('receita') &
                  l.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
        isPago = lanc != null;
      } catch (_) {}
      final statusPgto = isPago ? 'Confirmado' : 'Pendente';

      final String templateIdSugerido;
      if (saiuParaEntrega || o.status == StatusOrdemPreparo.saiuParaEntrega) {
        templateIdSugerido = 'saiu_entrega';
      } else if (o.status == StatusOrdemPreparo.pronto) {
        templateIdSugerido = 'pedido_pronto';
      } else if (o.status == StatusOrdemPreparo.entregue) {
        templateIdSugerido = 'avaliacao_pos_venda';
      } else if (o.status == StatusOrdemPreparo.cancelado) {
        templateIdSugerido = 'pedido_cancelado';
      } else if (o.status == StatusOrdemPreparo.pendente) {
        templateIdSugerido = 'comprovante';
      } else {
        templateIdSugerido = 'contato_pedido';
      }

      await WhatsAppDialog.show(
        context,
        rawPhone: tel,
        clienteNome: nome,
        initialMessage: initialMsg,
        initialTemplateId: templateIdSugerido,
        enderecoCliente: enderecoStr,
        enderecoEmpresa: WhatsAppService.formatarEnderecoEmpresa(),
        statusPagamento: statusPgto,
        pagamentoPendente: !isPago,
        isPix: isPix,
        pixInfo: pixInfo,
        numeroPedido: numPedido,
        pedidoId: pedidoRow?.id,
        nomeEmpresa: empresaNome,
        itens: itensWhats,
        subtotal: subtotal,
        desconto: descontoCalculado,
        taxaEntrega: taxaEntrega,
        taxaServico: taxaServico,
        total: total,
        formaPagamento: formaPagtoStr,
        trocoPara: trocoStr,
        tipoPedido: tipoAtendimento,
        observacoes: obs,
        previsaoEntrega: dataStr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir WhatsApp: $e'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
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

        final totalAguardando = _controller.ordensWebAguardandoAprovacao.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-Abas Superiores no TOPO Absoluto (Identidade com as demais telas do ERP)
            Row(
              children: [
                _buildSubTab('Painel de Preparação (Kanban)', Icons.view_kanban_outlined, 0),
                const SizedBox(width: 16),
                _buildSubTab(
                  'Aguardando Aprovação',
                  Icons.hourglass_top_rounded,
                  1,
                  badgeCount: totalAguardando,
                  badgeColor: const Color(0xFFF97316),
                ),
                const SizedBox(width: 16),
                _buildSubTab('Histórico & Todos os Pedidos', Icons.list_alt_outlined, 2),
              ],
            ),
            const SizedBox(height: 14),

            if (_activeSubTab == 0) ...[
              // ── Banner de Alerta se houver pedidos web aguardando ───
              if (totalAguardando > 0) ...[
                _buildAlertBannerAprovacao(totalAguardando),
                const SizedBox(height: 14),
              ],

              // ── Barra de controle ────────────────────────────────────
              _buildControlBar(),
              const SizedBox(height: 14),

              // ── Kanban Board ─────────────────────────────────────────
              Expanded(child: _buildKanbanBoard()),
            ] else if (_activeSubTab == 1) ...[
              // ── Pedidos Web Aguardando Aprovação ──────────────────────
              Expanded(child: _buildAguardandoAprovacaoPanel()),
            ] else ...[
              // ── Histórico & Todos os Pedidos (Lista / Tabela) ────────
              Expanded(child: _buildHistoryPanel()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSubTab(String label, IconData icon, int index, {int badgeCount = 0, Color? badgeColor}) {
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
              color: isSelected ? FincoreColors.primary : (badgeCount > 0 ? (badgeColor ?? const Color(0xFFF97316)) : FincoreColors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? FincoreColors.primary : (badgeCount > 0 ? Colors.white : FincoreColors.textMuted),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBannerAprovacao(int totalAguardando) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🚨 $totalAguardando ${totalAguardando == 1 ? 'Pedido Web Aguardando Aprovação' : 'Pedidos Web Aguardando Aprovação'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Cardápio Digital Online',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Clientes fizeram pedidos pelo cardápio web (inclusive agendamentos futuros) que necessitam de aprovação.',
                  style: TextStyle(
                    fontSize: 12,
                    color: FincoreColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _activeSubTab = 1);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text(
              'Ver e Aprovar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAguardandoAprovacaoPanel() {
    final ordensAguardando = _controller.ordensWebAguardandoAprovacao;

    if (ordensAguardando.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(36),
          constraints: const BoxConstraints(maxWidth: 540),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FincoreColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: FincoreColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nenhum Pedido Web Aguardando Aprovação',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: FincoreColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todos os pedidos recebidos através do Cardápio Web foram aprovados e encaminhados para a esteira operacional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: FincoreColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _activeSubTab = 0);
                },
                icon: const Icon(Icons.view_kanban_outlined, size: 16),
                label: const Text('Voltar para o Kanban de Preparo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FincoreColors.primary,
                  side: BorderSide(color: FincoreColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com resumo e botão de aprovar todos
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF97316), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ordensAguardando.length} ${ordensAguardando.length == 1 ? 'Pedido Web Aguardando Aprovação' : 'Pedidos Web Aguardando Aprovação'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Estes pedidos foram feitos online pelo cliente. Ao aprovar, o status do pedido avança para confirmado e entra na fila.',
                      style: TextStyle(
                        fontSize: 11,
                        color: FincoreColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (ordensAguardando.length > 1)
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: FincoreColors.surface,
                        title: const Text('Aprovar Todos os Pedidos Web?', style: TextStyle(color: Colors.white, fontSize: 16)),
                        content: Text(
                          'Deseja aprovar todos os ${ordensAguardando.length} pedidos web pendentes de uma só vez?',
                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.success),
                            child: const Text('Aprovar Todos', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirmar == true) {
                      for (final o in ordensAguardando) {
                        await _controller.aprovarPedidoWeb(o);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: FincoreColors.success,
                            content: Text('✅ Todos os ${ordensAguardando.length} pedidos foram aprovados!'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Aprovar Todos em Lote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lista de Cards com Scroll
        Expanded(
          child: ListView.separated(
            itemCount: ordensAguardando.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ordem = ordensAguardando[index];
              return _buildCardPedidoAguardando(ordem);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardPedidoAguardando(OrdemPreparo ordem) {
    final parsed = DadosOrdemKanban.fromOrdem(ordem);
    final pedidoRow = _controller.pedidosMap[ordem.pedidoId];
    final numPed = _controller.getNumeroPedido(ordem.pedidoId) ?? pedidoRow?.numeroPedido;
    final numStr = numPed != null ? '#${numPed.toString().padLeft(6, '0')}' : '#${ordem.pedidoId.substring(0, 6).toUpperCase()}';

    final agendada = parsed.dataAgendada ?? pedidoRow?.dataHoraEntregaPrevista?.toLocal();
    final now = DateTime.now();
    String agendamentoStr;
    bool isAgendamentoDestaque = false;
    if (agendada != null) {
      final isHoje = agendada.year == now.year && agendada.month == now.month && agendada.day == now.day;
      final diffDays = agendada.difference(DateTime(now.year, now.month, now.day)).inDays;
      final diasLabel = isHoje
          ? 'HOJE'
          : (diffDays == 1
              ? 'AMANHÃ'
              : (diffDays > 1 ? 'em $diffDays dias' : '${diffDays.abs()} dia(s) atrás'));
      agendamentoStr = '📅 Agendado para: ${DateFormat('dd/MM/yyyy HH:mm').format(agendada)} ($diasLabel)';
      isAgendamentoDestaque = true;
    } else {
      agendamentoStr = '⚡ Pedido para Preparação Imediata';
    }

    final totalCentavos = parsed.totalCentavos > 0
        ? parsed.totalCentavos
        : (pedidoRow?.valorTotalCentavos ?? _controller.totalOrdemCentavos(ordem));
    final totalStr = (totalCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',');

    final dataCriacaoStr = DateFormat('dd/MM/yyyy HH:mm').format(ordem.criadaEm.toLocal());
    final isDelivery = parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        parsed.tipoLogistica.toLowerCase().contains('delivery');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: Cabeçalho com Número, Badge Web, Horário de Criação e Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Text(
                  numStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1D4ED8).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.language_rounded, size: 13, color: Color(0xFF60A5FA)),
                    SizedBox(width: 4),
                    Text(
                      'Cardápio Web',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Criado em: $dataCriacaoStr',
                style: const TextStyle(
                  color: FincoreColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF97316)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFF97316)),
                    SizedBox(width: 4),
                    Text(
                      'Aguardando Aprovação',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Linha 2: Bloco de Agendamento da Entrega / Retirada (Destaque Principal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAgendamentoDestaque
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                  : FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAgendamentoDestaque
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                    : FincoreColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: isAgendamentoDestaque ? const Color(0xFF60A5FA) : FincoreColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    agendamentoStr,
                    style: TextStyle(
                      color: isAgendamentoDestaque ? Colors.white : FincoreColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (agendada != null)
                  InkWell(
                    onTap: () {
                      _controller.setSelectedDate(agendada);
                      setState(() => _activeSubTab = 0);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        children: const [
                          Text(
                            'Ver no Kanban deste dia',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF60A5FA)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Linha 3: Dados do Cliente e Logística
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna Cliente
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 14, color: FincoreColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              parsed.cliente,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (parsed.telefone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: FincoreColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              parsed.telefone,
                              style: const TextStyle(
                                color: FincoreColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Coluna Logística
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded,
                            size: 14,
                            color: isDelivery ? const Color(0xFF60A5FA) : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDelivery ? 'Entrega (Delivery)' : 'Retirada no Balcão',
                            style: TextStyle(
                              color: isDelivery ? const Color(0xFF60A5FA) : const Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (isDelivery && parsed.endereco != null && parsed.endereco!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${parsed.endereco!}${parsed.bairro != null ? ' - ${parsed.bairro}' : ''}',
                          style: const TextStyle(
                            color: FincoreColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Coluna Pagamento & Total
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment_rounded, size: 14, color: FincoreColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            parsed.pagamento.isNotEmpty ? parsed.pagamento : 'Pagamento a definir',
                            style: const TextStyle(
                              color: FincoreColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: R\$ $totalStr',
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Linha 4: Itens do Pedido
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FincoreColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ITENS DO PEDIDO:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ordem.itens.map((item) {
                    final qtdStr = item.quantidade % 1 == 0
                        ? item.quantidade.toInt().toString()
                        : item.quantidade.toStringAsFixed(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FincoreColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Text(
                        '${qtdStr}x ${item.nomeProduto}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (parsed.observacoesLimpa.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Obs: ${parsed.observacoesLimpa}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF59E0B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Linha 5: Botões de Ação
          Row(
            children: [
              // Botão WhatsApp
              OutlinedButton.icon(
                onPressed: () => _abrirWhatsAppParaOrdem(ordem),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF22C55E)),
                label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF22C55E)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Detalhes & Impressão
              OutlinedButton.icon(
                onPressed: () => _abrirDrawer(ordem),
                icon: const Icon(Icons.visibility_outlined, size: 15, color: FincoreColors.textSecondary),
                label: const Text('Ver Detalhes', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: FincoreColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Recusar / Cancelar
              if (PermissaoService.podeCancelarPedido(_userRole))
                OutlinedButton.icon(
                  onPressed: () => _cancelarPedido(ordem),
                  icon: const Icon(Icons.close_rounded, size: 15, color: FincoreColors.danger),
                  label: const Text('Recusar', style: TextStyle(color: FincoreColors.danger, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: FincoreColors.danger.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              const Spacer(),

              // Botão Principal: APROVAR PEDIDO
              ElevatedButton.icon(
                onPressed: _controller.isProcessandoAprovacao(ordem.id)
                    ? null
                    : () async {
                        await _controller.aprovarPedidoWeb(ordem);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: FincoreColors.success,
                              content: Text('✅ Pedido $numStr aprovado com sucesso e integrado à fila!'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                icon: _controller.isProcessandoAprovacao(ordem.id)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  _controller.isProcessandoAprovacao(ordem.id) ? 'APROVANDO...' : 'APROVAR PEDIDO',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
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

    final int totalFaturamentoCentavos = list.where((p) => !p.isUsoInterno).fold(0, (sum, p) => sum + p.valorTotalCentavos);
    final int totalVendasCount = list.where((p) => !p.isUsoInterno).length;
    final double ticketMedioCentavos = totalVendasCount > 0 ? (totalFaturamentoCentavos / totalVendasCount) : 0;
    final String totalFaturamentoStr = (totalFaturamentoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final String ticketMedioStr = (ticketMedioCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Linha 0: Cards de Métricas do Histórico ────────────────────
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL DE PEDIDOS', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${list.length}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FATURAMENTO TOTAL', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('R\$ $totalFaturamentoStr', style: TextStyle(color: FincoreColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TICKET MÉDIO', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('R\$ $ticketMedioStr', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                            final avaliacao = _controller.getAvaliacaoDoPedido(p.id, p.numeroPedido?.toString());

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(displayNum, style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                                      if (avaliacao != null) ...[
                                        const SizedBox(width: 6),
                                        _buildAvaliacaoBadgeSmall(avaliacao),
                                      ],
                                    ],
                                  ),
                                ),
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
                                        icon: const Icon(Icons.print_outlined, size: 18),
                                        tooltip: 'Reimprimir Comprovante',
                                        color: FincoreColors.primary,
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
                                          final parsed = DadosOrdemKanban.fromOrdem(o);
                                          _exibirOpcoesImpressao(o, parsed);
                                        },
                                      ),
                                      const SizedBox(width: 4),
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
          InkWell(
            onTap: () => _abrirCalendarioCentralPedidos(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 14, color: FincoreColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: FincoreColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 14, color: FincoreColors.textMuted),
                ],
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

          // Toggle de Som de Alerta (Apenas Mudo/Ativo)
          GestureDetector(
            onTap: () {
              setState(() {
                SoundService.enabled = !SoundService.enabled;
              });
              if (SoundService.enabled) {
                SoundService.playAttentionSound();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SoundService.enabled ? FincoreColors.primary.withValues(alpha: 0.15) : FincoreColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SoundService.enabled ? FincoreColors.primary : FincoreColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    SoundService.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 16,
                    color: SoundService.enabled ? FincoreColors.primary : FincoreColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    SoundService.enabled ? 'Som Ativo' : 'Som Mudo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: SoundService.enabled ? FincoreColors.primary : FincoreColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Botão Imprimir Pedidos do Dia
          ElevatedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Row(
                    children: [
                      Icon(Icons.print_rounded, color: FincoreColors.primary),
                      const SizedBox(width: 8),
                      const Text('Imprimir Pedidos do Dia', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Text(
                    'Deseja enviar para a impressora todos os ${_controller.filteredOrdens.length} pedidos agendados para ${_controller.formattedDate()}?',
                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('IMPRIMIR EM LOTE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                final printUseCase = DependencyInjection().get<PrintUseCase>();
                final totalPrinted = await _controller.imprimirPedidosDoDia(printUseCase: printUseCase);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: FincoreColors.success,
                      content: Text('⚡ $totalPrinted pedidos impressos em lote com sucesso!'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Imprimir Pedidos do Dia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E2E3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: FincoreColors.border)),
            ),
          ),
          const SizedBox(width: 10),

          // Botão Novo Pedido
          if (PermissaoService.podeCriarPedido(_userRole))
            ElevatedButton.icon(
              onPressed: () {
                FincoreShell.selectTab(context, 'pdv');
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
                    ? () => _executarAcaoRapida(o)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
                onWhatsApp: () => _abrirWhatsAppParaOrdem(o),
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
                    ? () => _executarAcaoRapida(o)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
                onWhatsApp: () => _abrirWhatsAppParaOrdem(o),
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
                    ? () => _executarAcaoRapida(o)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
                onWhatsApp: () => _abrirWhatsAppParaOrdem(o),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // Coluna SAIU PARA ENTREGA
        Expanded(
          child: KanbanColumn(
            title: 'Saiu p/ Entrega',
            accentColor: const Color(0xFF3B82F6),
            ordens: _controller.saiuParaEntrega,
            cardBuilder: (o, _) {
              final parsed = DadosOrdemKanban.fromOrdem(o);
              return PedidoCard(
                ordem: o,
                parsed: parsed,
                controller: _controller,
                userRole: _userRole,
                accentColor: const Color(0xFF3B82F6),
                mostrarAcaoRapida: _proximoStatus(o) != null,
                acaoRapidaLabel: _acaoRapidaLabel(o),
                onAcaoRapida: _proximoStatus(o) != null
                    ? () => _executarAcaoRapida(o)
                    : null,
                onTap: () => _abrirDrawer(o),
                onImprimir: () => _exibirOpcoesImpressao(o, parsed),
                onCancelar: () => _cancelarPedido(o),
                onWhatsApp: () => _abrirWhatsAppParaOrdem(o),
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

  void _abrirCalendarioCentralPedidos(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CentralPedidosCalendarDialog(
        initialDate: _controller.selectedDate,
        controller: _controller,
        onDateSelected: (novaData) {
          _controller.setSelectedDate(novaData);
        },
      ),
    );
  }

  Widget _buildAvaliacaoBadgeSmall(Map<String, dynamic> av) {
    final nota = av['nota'];
    final notaStr = (nota is num) ? nota.toStringAsFixed(nota is int ? 0 : 1) : '$nota';
    final comentario = av['comentario']?.toString();
    final tags = av['tags'];
    final tagsStr = (tags is List && tags.isNotEmpty) ? tags.join(', ') : null;

    final tooltipLines = <String>['⭐ Avaliação do Cliente: $notaStr / 5'];
    if (tagsStr != null && tagsStr.trim().isNotEmpty) tooltipLines.add('Destaques: $tagsStr');
    if (comentario != null && comentario.trim().isNotEmpty) tooltipLines.add('Feedback: "$comentario"');

    return Tooltip(
      message: tooltipLines.join('\n'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFCD34D), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(
              notaStr,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
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

// ─── Modal de Calendário Interativo da Central de Pedidos ────────────────────

class _CentralPedidosCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final CentralPedidosController controller;
  final ValueChanged<DateTime> onDateSelected;

  const _CentralPedidosCalendarDialog({
    required this.initialDate,
    required this.controller,
    required this.onDateSelected,
  });

  @override
  State<_CentralPedidosCalendarDialog> createState() => _CentralPedidosCalendarDialogState();
}

class _CentralPedidosCalendarDialogState extends State<_CentralPedidosCalendarDialog> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _mudarMes(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  String _nomeMes(int month) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final statsMap = widget.controller.getEstatisticasPedidosPorDia();

    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // Domingo = 0, Segunda = 1 ... Sábado = 6
    final startWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    int totalPedidosMes = 0;
    int totalAtrasadosMes = 0;
    int totalEmAbertoMes = 0;
    int totalFinalizadosMes = 0;

    for (int d = 1; d <= daysInMonth; d++) {
      final dateKey = DateTime(year, month, d);
      final st = statsMap[dateKey];
      if (st != null) {
        totalPedidosMes += st.total;
        totalAtrasadosMes += st.atrasados;
        totalEmAbertoMes += st.emAberto;
        totalFinalizadosMes += st.finalizados;
      }
    }

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabeçalho do Mês ──────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22, color: FincoreColors.textPrimary),
                  onPressed: () => _mudarMes(-1),
                  tooltip: 'Mês anterior',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_nomeMes(month)} $year',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22, color: FincoreColors.textPrimary),
                  onPressed: () => _mudarMes(1),
                  tooltip: 'Próximo mês',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Dias da Semana ────────────────────────────────────────────
            Row(
              children: ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'].map((dia) {
                return Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 8),

            // ── Grid dos Dias do Mês ───────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.98,
              ),
              itemCount: 42,
              itemBuilder: (ctx, index) {
                final dayNumber = index - startWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(year, month, dayNumber);
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                final isSelected = date.year == widget.controller.selectedDate.year &&
                    date.month == widget.controller.selectedDate.month &&
                    date.day == widget.controller.selectedDate.day;
                final stats = statsMap[date] ?? const EstatisticasDiaCalendario();

                // Definição de cores de fundo e borda baseadas no status
                final Color cellBg;
                final Color cellBorder;
                final Color dayNumberColor;

                if (isSelected) {
                  cellBg = FincoreColors.primary;
                  cellBorder = FincoreColors.primary;
                  dayNumberColor = Colors.white;
                } else if (stats.temAtraso) {
                  // Destaque de ALERTA para dias com pedidos em atraso
                  cellBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
                  cellBorder = const Color(0xFFEF4444).withValues(alpha: 0.55);
                  dayNumberColor = const Color(0xFFDC2626);
                } else if (stats.todosFinalizados) {
                  // Todos os pedidos do dia já finalizados/entregues
                  cellBg = const Color(0xFF10B981).withValues(alpha: 0.08);
                  cellBorder = const Color(0xFF10B981).withValues(alpha: 0.40);
                  dayNumberColor = isToday ? FincoreColors.primary : const Color(0xFF059669);
                } else if (stats.total > 0) {
                  // Pedidos em aberto / agendados no prazo
                  cellBg = const Color(0xFF3B82F6).withValues(alpha: 0.08);
                  cellBorder = const Color(0xFF3B82F6).withValues(alpha: 0.40);
                  dayNumberColor = isToday ? FincoreColors.primary : const Color(0xFF2563EB);
                } else if (isToday) {
                  cellBg = FincoreColors.primary.withValues(alpha: 0.10);
                  cellBorder = FincoreColors.primary.withValues(alpha: 0.50);
                  dayNumberColor = FincoreColors.primary;
                } else {
                  cellBg = FincoreColors.background;
                  cellBorder = FincoreColors.border;
                  dayNumberColor = FincoreColors.textPrimary;
                }

                final tooltipMsg = stats.total > 0
                    ? '$dayNumber de ${_nomeMes(month)}:\n'
                      '• Total: ${stats.total} pedido(s)\n'
                      '• ${stats.atrasados} em atraso\n'
                      '• ${stats.emAberto} em aberto\n'
                      '• ${stats.finalizados} finalizado(s)'
                    : '$dayNumber de ${_nomeMes(month)} (Nenhum pedido)';

                return Tooltip(
                  message: tooltipMsg,
                  waitDuration: const Duration(milliseconds: 300),
                  child: InkWell(
                    onTap: () {
                      widget.onDateSelected(date);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: cellBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cellBorder,
                          width: isSelected || isToday || stats.temAtraso ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected || isToday || stats.total > 0 ? FontWeight.bold : FontWeight.w600,
                                  color: dayNumberColor,
                                ),
                              ),
                              if (isToday && !isSelected) ...[
                                const SizedBox(width: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: FincoreColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (stats.total > 0) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 2,
                              runSpacing: 2,
                              children: [
                                // Badge de atrasados (Vermelho)
                                if (stats.atrasados > 0)
                                  _buildMiniBadge(
                                    count: stats.atrasados,
                                    bgColor: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                    textColor: isSelected ? Colors.white : const Color(0xFFEF4444),
                                    icon: Icons.error_outline_rounded,
                                  ),
                                // Badge de em aberto (Azul)
                                if (stats.emAberto > 0)
                                  _buildMiniBadge(
                                    count: stats.emAberto,
                                    bgColor: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                    textColor: isSelected ? Colors.white : const Color(0xFF3B82F6),
                                    icon: Icons.schedule_rounded,
                                  ),
                                // Badge de finalizados (Verde)
                                if (stats.finalizados > 0)
                                  _buildMiniBadge(
                                    count: stats.finalizados,
                                    bgColor: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : const Color(0xFF10B981).withValues(alpha: 0.2),
                                    textColor: isSelected ? Colors.white : const Color(0xFF10B981),
                                    icon: Icons.check_circle_outline_rounded,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 8),

            // ── Legenda de Cores ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(color: const Color(0xFFEF4444), label: 'Atrasado'),
                const SizedBox(width: 14),
                _buildLegendItem(color: const Color(0xFF3B82F6), label: 'Em Aberto'),
                const SizedBox(width: 14),
                _buildLegendItem(color: const Color(0xFF10B981), label: 'Finalizado'),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 8),

            // ── Atalhos Rápidos & Total do Mês ───────────────────────────
            Row(
              children: [
                _buildShortcutButton(
                  label: 'Hoje',
                  onTap: () {
                    widget.onDateSelected(today);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 6),
                _buildShortcutButton(
                  label: 'Amanhã',
                  onTap: () {
                    widget.onDateSelected(today.add(const Duration(days: 1)));
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 6),
                _buildShortcutButton(
                  label: 'Ontem',
                  onTap: () {
                    widget.onDateSelected(today.subtract(const Duration(days: 1)));
                    Navigator.of(context).pop();
                  },
                ),
                const Spacer(),
                if (totalPedidosMes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalPedidosMes no mês',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                        if (totalAtrasadosMes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($totalAtrasadosMes 🔴)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                        if (totalEmAbertoMes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($totalEmAbertoMes 🔵)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                        if (totalFinalizadosMes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($totalFinalizadosMes 🟢)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar', style: TextStyle(color: FincoreColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildMiniBadge({
    required int count,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: textColor),
          const SizedBox(width: 1.5),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: FincoreColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: FincoreColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

