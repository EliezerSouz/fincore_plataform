import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/shared/services/permissao_service.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/pedido_card.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/kanban_column.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/producao_necessaria_bar.dart';
import 'package:fincore_food_flutter/src/pedidos/views/widgets/pedido_detail_drawer.dart';
import 'package:fincore_food_flutter/src/cap/printing/print_capability.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pdv_page.dart';
import 'package:fincore_core/database/fincore_database.dart';


// ─── Central Operacional de Pedidos ─────────────────────────────────────────

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  late final CentralPedidosController _controller;
  late final String? _userRole;
  bool _producaoExpanded = true;


  Timer? _deadlinesTimer;

  @override
  void initState() {
    super.initState();
    _controller = CentralPedidosController();
    final tenantCtx = DependencyInjection().get<TenantContext>();
    _userRole =
        tenantCtx.hasContext ? tenantCtx.usuario.role : null;

    // Recalcular prazos em memória a cada 60s
    _deadlinesTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
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

    final printData = PrintData(
      pedidoId: o.pedidoId,
      clienteNome: parsed.cliente,
      clienteTelefone: parsed.telefone,
      tipoLogistica: parsed.tipoLogistica,
      endereco: (parsed.tipoLogistica.toLowerCase().contains('entrega') ||
              parsed.tipoLogistica.toLowerCase().contains('delivery'))
          ? parsed.observacoesLimpa
          : null,
      formaPagamento: parsed.pagamento,
      totalCentavos: totalEfetivo,
      itens: printItens,
      dataHora: o.criadaEm,
      observacao: parsed.observacoesLimpa,
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
    final ok = await confirmarAcaoFincore(
      context,
      titulo: 'Cancelar Pedido #${o.pedidoId}',
      mensagem:
          'Tem certeza que deseja cancelar este pedido permanentemente?',
      confirmLabel: 'Cancelar Pedido',
      isDestructive: true,
    );
    if (ok) {
      await _controller.moverStatus(o, StatusOrdemPreparo.cancelado);
    }
  }

  // ── Diálogo de reversão ──────────────────────────────────────────────────

  Future<String?> _solicitarMotivoReversao(
      BuildContext context, String deStatus, String paraStatus) async {
    final controller = TextEditingController();
    String? motivoSelecionado;

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
            children: const [
              Icon(Icons.undo_outlined,
                  color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 10),
              Text(
                'Motivo da Reversão',
                style: TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            // ── Produção Necessária ──────────────────────────────────
            if (PermissaoService.podeVerProducao(_userRole)) ...[
              ProducaoNecessariaBar(
                controller: _controller,
                isExpanded: _producaoExpanded,
                onToggle: () =>
                    setState(() => _producaoExpanded = !_producaoExpanded),
              ),
              const SizedBox(height: 14),
            ],

            // ── KPIs ────────────────────────────────────────────────
            _buildKPIs(),
            const SizedBox(height: 14),

            // ── Barra de controle ────────────────────────────────────
            _buildControlBar(),
            const SizedBox(height: 14),

            // ── Kanban Board ─────────────────────────────────────────
            Expanded(child: _buildKanbanBoard()),
          ],
        );
      },
    );
  }

  // ── KPIs Operacionais ────────────────────────────────────────────────────

  Widget _buildKPIs() {
    final showFinanceiro =
        PermissaoService.podeVerFinanceiro(_userRole);

    return Row(
      children: [
        _KpiCard(
          label: 'PEDIDOS',
          value: '${_controller.totalPedidos}',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 10),
        _KpiCard(
          label: 'ENTREGAS',
          value: '${_controller.totalEntregas}',
          icon: Icons.delivery_dining_outlined,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 10),
        _KpiCard(
          label: 'RETIRADAS',
          value: '${_controller.totalRetiradas}',
          icon: Icons.storefront_outlined,
          color: const Color(0xFF8B5CF6),
        ),
        if (showFinanceiro) ...[
          const SizedBox(width: 10),
          _KpiCard(
            label: 'FATURAMENTO',
            value:
                'R\$ ${(_controller.faturamentoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
            icon: Icons.monetization_on_outlined,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          _KpiCard(
            label: 'TICKET MÉDIO',
            value:
                'R\$ ${(_controller.ticketMedioCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
            icon: Icons.analytics_outlined,
            color: const Color(0xFF06B6D4),
          ),
        ],
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

  const _EntregueCompactRow({
    required this.ordem,
    required this.parsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = ordem.pedidoId.length > 6
        ? '#${ordem.pedidoId.substring(0, 6).toUpperCase()}'
        : '#${ordem.pedidoId.toUpperCase()}';

    final hora = DateFormat('HH:mm').format(ordem.criadaEm);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Text(
              shortId,
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parsed.cliente.isEmpty ? 'Consumidor' : parsed.cliente,
                style: const TextStyle(
                  color: FincoreColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              hora,
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

// ── Widgets de apoio ─────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FincoreColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: FincoreColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FincoreColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
