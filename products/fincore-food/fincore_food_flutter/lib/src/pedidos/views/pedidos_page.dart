import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_food_flutter/src/shared/services/impressao_service.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pdv_page.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/cap/printing/print_capability.dart';
import 'package:fincore_core/repository/print_job_repository.dart';

// ─── Central Operacional de Pedidos Kanban Premium ─────────────────────────

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  late final OrdemPreparoRepository _ordemRepo;
  List<OrdemPreparo> _todasOrdens = [];
  List<OrdemPreparo> _filteredOrdens = [];

  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedOrigem = 'Todos';

  @override
  void initState() {
    super.initState();
    _ordemRepo = DependencyInjection().get<OrdemPreparoRepository>();
    _carregarOrdens();
  }

  Map<String, int> _precosProdutosMap = {};

  Future<void> _carregarOrdens() async {
    try {
      final list = await _ordemRepo.findAll();
      
      // Carregar produtos e tabela de precificação para fallback de cálculo de valor real
      final prodRepo = DependencyInjection().get<ProdutoRepository>();
      final assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>();
      final itemTabRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>();

      final prods = await prodRepo.findAll();
      final assocs = await assocRepo.findAll();
      final itensTabela = await itemTabRepo.findAll();

      final map = <String, int>{};
      for (final p in prods) {
        final assoc = assocs.where((a) => a.produtoId == p.id && a.ativo).firstOrNull;
        if (assoc != null) {
          final item = itensTabela.where((i) => i.tabelaPrecificacaoId == assoc.tabelaPrecificacaoId).firstOrNull;
          if (item != null) {
            map[p.id] = item.valorUnitarioCentavos;
          }
        }
      }

      setState(() {
        _precosProdutosMap = map;
        _todasOrdens = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar ordens de preparo: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrdens = _todasOrdens.where((o) {
        // Filtra por data selecionada (dia/mês/ano)
        final matchesDate = o.criadaEm.year == _selectedDate.year &&
            o.criadaEm.month == _selectedDate.month &&
            o.criadaEm.day == _selectedDate.day;

        // Filtra por canal/origem
        final parsed = DadosOrdemKanban.fromOrdem(o);
        final matchesOrigem = _selectedOrigem == 'Todos' ||
            parsed.tipoLogistica.toLowerCase() == _selectedOrigem.toLowerCase();

        return matchesDate && matchesOrigem;
      }).toList();
    });
  }

  String _statusText(StatusOrdemPreparo s) {
    switch (s) {
      case StatusOrdemPreparo.pendente: return 'Pendente';
      case StatusOrdemPreparo.emPreparo: return 'Em Preparo';
      case StatusOrdemPreparo.pronto: return 'Pronto';
      case StatusOrdemPreparo.entregue: return 'Entregue';
      case StatusOrdemPreparo.cancelado: return 'Cancelado';
    }
  }

  Future<String?> _solicitarMotivoReversao(BuildContext context, String deStatus, String paraStatus) async {
    final controller = TextEditingController();
    String? motivoSelecionado;

    final motivosRapidos = [
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
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.undo_outlined, color: Color(0xFFF59E0B), size: 22),
              SizedBox(width: 10),
              Text(
                'Motivo da Reversão',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Container(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revertendo status de "$deStatus" para "$paraStatus". Informe o motivo abaixo:',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                // Chips de seleção rápida
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: motivosRapidos.map((m) {
                    final isSel = motivoSelecionado == m;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          motivoSelecionado = m;
                          controller.text = m;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFF6B2B) : const Color(0xFF2D2D44),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Campo de Texto Livre
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Descreva o motivo detalhado...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141420),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2D2D44)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF6B2B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, informe ou selecione o motivo da reversão.'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                Navigator.pop(ctx, txt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B2B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmar Reversão', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moverStatus(OrdemPreparo ordem, StatusOrdemPreparo novoStatus, {String? motivo}) async {
    final isReversao = (novoStatus.index < ordem.status.index) ||
        (ordem.status == StatusOrdemPreparo.cancelado && novoStatus != StatusOrdemPreparo.cancelado);

    String? motivoFinal = motivo;
    if (isReversao && (motivoFinal == null || motivoFinal.isEmpty)) {
      motivoFinal = await _solicitarMotivoReversao(
        context,
        _statusText(ordem.status),
        _statusText(novoStatus),
      );
      if (motivoFinal == null) return; // Cancelado pelo usuário
    }

    final updated = OrdemPreparo(
      id: ordem.id,
      tenantId: ordem.tenantId,
      pedidoId: ordem.pedidoId,
      itens: ordem.itens,
      status: novoStatus,
      prioridade: ordem.prioridade,
      operadorId: ordem.operadorId,
      criadaEm: ordem.criadaEm,
      iniciadaEm: novoStatus == StatusOrdemPreparo.emPreparo ? DateTime.now() : ordem.iniciadaEm,
      concluidaEm: novoStatus == StatusOrdemPreparo.pronto ? DateTime.now() : ordem.concluidaEm,
      canceladaEm: novoStatus == StatusOrdemPreparo.cancelado ? DateTime.now() : ordem.canceladaEm,
      tempoEstimadoSegundos: ordem.tempoEstimadoSegundos,
      observacoes: ordem.observacoes,
      metadata: ordem.metadata.copyWith(
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.pending,
      ),
    );

    try {
      await _ordemRepo.save(updated);

      final tituloLog = isReversao ? 'Status Revertido' : 'Status alterado';
      final descLog = isReversao
          ? 'Passou de "${_statusText(ordem.status)}" para "${_statusText(novoStatus)}". Motivo: $motivoFinal'
          : 'Passou de "${_statusText(ordem.status)}" para "${_statusText(novoStatus)}"';

      await _ordemRepo.registrarHistorico(
        ordem.id,
        tituloLog,
        descLog,
      );
      await _carregarOrdens();
    } catch (e) {
      debugPrint('Erro ao mover status da ordem: $e');
    }
  }

  Future<void> _cancelarPedido(OrdemPreparo o) async {
    final ok = await confirmarAcaoFincore(
      context,
      titulo: 'Cancelar Pedido #${o.pedidoId}',
      mensagem: 'Tem certeza que deseja cancelar este pedido permanentemente?',
      confirmLabel: 'Cancelar Pedido',
      isDestructive: true,
    );
    if (ok) {
      await _moverStatus(o, StatusOrdemPreparo.cancelado);
    }
  }

  void _mudarDia(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
      _applyFilters();
    });
  }

  Future<void> _imprimirCupom(OrdemPreparo o, DadosOrdemKanban parsed) async {
    try {
      final config = await FincoreImpressaoConfig.carregar();
      
      int totalEfetivo = parsed.totalCentavos;
      final itensCalculados = o.itens.map((i) {
        final pUnit = _precosProdutosMap[i.produtoId] ?? 0;
        final itemTotal = (i.quantidade * pUnit).round();
        return ItemImpressao(
          nome: i.nomeProduto,
          quantidade: i.quantidade,
          precoUnitarioCentavos: pUnit,
          totalCentavos: itemTotal,
        );
      }).toList();

      if (totalEfetivo == 0) {
        for (final item in itensCalculados) {
          totalEfetivo += item.totalCentavos;
        }
      }

      final dados = DadosImpressaoPedido(
        numeroPedido: o.pedidoId,
        nomeCliente: parsed.cliente,
        telefoneCliente: parsed.telefone.isEmpty ? null : parsed.telefone,
        tipoEntrega: parsed.tipoLogistica,
        dataHora: o.criadaEm,
        itens: itensCalculados,
        subtotalCentavos: totalEfetivo,
        totalCentavos: totalEfetivo,
        formaPagamento: parsed.pagamento,
        observacoes: parsed.observacoesLimpa,
      );

      final bytes = await FincorePdfGerador.gerarBytes(dados, config);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Pedido #${o.pedidoId}',
        format: config.larguraMm == 58 ? PdfPageFormat.roll57 : PdfPageFormat.roll80,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao imprimir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exibirOpcoesImpressao(BuildContext context, OrdemPreparo o, DadosOrdemKanban parsed) async {
    final useCase = DependencyInjection().get<PrintUseCase>();
    final config = await useCase.loadConfig();

    int totalEfetivo = parsed.totalCentavos;
    final printItens = o.itens.map((i) {
      final pUnit = _precosProdutosMap[i.produtoId] ?? 0;
      final itemTotal = (i.quantidade * pUnit).round();
      if (parsed.totalCentavos == 0) {
        totalEfetivo += itemTotal;
      }
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

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final showCliente = config == null || config.isEnabled(PrintVia.cliente);
        final showCozinha = config == null || config.isEnabled(PrintVia.cozinha);
        final showBalcao = config == null || config.isEnabled(PrintVia.balcao);
        final showExpedicao = config == null || config.isEnabled(PrintVia.expedicao);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'OPÇÕES DE IMPRESSÃO - PEDIDO #${printData.shortId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Divider(color: Color(0xFF2D2D44)),
              ListTile(
                leading: const Icon(Icons.print, color: Color(0xFFFF6B2B)),
                title: const Text('Imprimir Todas as Vias Habilitadas', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Dispara vias configuradas automaticamente', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _executarImpressao(() => useCase.imprimirPedido(data: printData));
                },
              ),
              if (showCliente)
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueAccent),
                  title: const Text('Reimprimir Via do Cliente (Caixa)', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(via: PrintVia.cliente, data: printData));
                  },
                ),
              if (showCozinha)
                ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.greenAccent),
                  title: const Text('Reimprimir Via da Cozinha', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(via: PrintVia.cozinha, data: printData));
                  },
                ),
              if (showBalcao)
                ListTile(
                  leading: const Icon(Icons.kitchen, color: Colors.amberAccent),
                  title: const Text('Reimprimir Via do Balcão', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(via: PrintVia.balcao, data: printData));
                  },
                ),
              if (showExpedicao)
                ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.purpleAccent),
                  title: const Text('Reimprimir Via da Expedição', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _executarImpressao(() => useCase.reimprimir(via: PrintVia.expedicao, data: printData));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white70),
                title: const Text('Visualizar Histórico de Impressões', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exibirHistoricoImpressao(context, o.pedidoId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executarImpressao(Future<dynamic> Function() action) async {
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
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao imprimir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exibirHistoricoImpressao(BuildContext context, String pedidoId) async {
    final useCase = DependencyInjection().get<PrintUseCase>();
    final jobs = await useCase.historicoPedido(pedidoId);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.history, color: Color(0xFFFF6B2B)),
            SizedBox(width: 10),
            Text('Histórico de Impressão', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: jobs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Nenhuma impressão registrada para este pedido.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: jobs.length,
                  separatorBuilder: (c, i) => const Divider(color: Color(0xFF2D2D44)),
                  itemBuilder: (c, idx) {
                    final job = jobs[idx];
                    final timeStr = DateFormat('dd/MM HH:mm:ss').format(job.dataHora.toLocal());
                    final statusColor = job.status == 'success' ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Via: ${job.tipoVia.toUpperCase()} - ${job.impressora}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Data: $timeStr | Op: ${job.usuario}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          if (job.erro != null)
                            Text('Erro: ${job.erro}', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          job.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _exibirDetalhes(OrdemPreparo o, DadosOrdemKanban parsed) {
    // Determinar etapa ativa (1 a 5)
    int etapaAtiva = 1;
    if (o.status == StatusOrdemPreparo.pendente) {
      etapaAtiva = 2; // Já foi criado/pago
    } else if (o.status == StatusOrdemPreparo.emPreparo) {
      etapaAtiva = 3;
    } else if (o.status == StatusOrdemPreparo.pronto) {
      etapaAtiva = 4;
    } else if (o.status == StatusOrdemPreparo.entregue) {
      etapaAtiva = 5;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 960,
            height: 640,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── PAINEL ESQUERDO: INFORMAÇÕES E AÇÕES (Expandido) ─────────
                Expanded(
                  flex: 11,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do Pedido
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Pedido #${o.pedidoId}',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusText(o.status).toUpperCase(),
                                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                                      const SizedBox(width: 6),
                                      Text(
                                        o.prioridade.name.toUpperCase(),
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white60),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Stepper Horizontal de Lifecycle (Linha de Vida)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181824),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D2D44)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Linha de Vida do Pedido (Lifecycle)',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B2B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Etapa $etapaAtiva de 5',
                                      style: const TextStyle(color: Color(0xFFFF6B2B), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  _buildStepNode('Criado', true, etapaAtiva >= 1),
                                  _buildStepLine(etapaAtiva >= 2),
                                  _buildStepNode('Pagamento', true, etapaAtiva >= 2),
                                  _buildStepLine(etapaAtiva >= 3),
                                  _buildStepNode('Produção', true, etapaAtiva >= 3, isCurrent: etapaAtiva == 3),
                                  _buildStepLine(etapaAtiva >= 4),
                                  _buildStepNode('Pronto', false, etapaAtiva >= 4),
                                  _buildStepLine(etapaAtiva >= 5),
                                  _buildStepNode('Em Rota', false, etapaAtiva >= 5),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dados do Cliente
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: Color(0xFFFF6B2B), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              parsed.cliente,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        if (parsed.telefone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
                            child: Text(
                              'Telefone: ${parsed.telefone}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 26),
                          child: Text(
                            'Entrega: ${parsed.dataAgendada != null ? DateFormat('dd/MM/yyyy HH:mm').format(parsed.dataAgendada!) : "Imediata"}  •  ${parsed.tipoLogistica}  •  ${parsed.pagamento}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Título de Itens
                        const Text(
                          'ITENS DO PEDIDO',
                          style: TextStyle(color: Color(0xFFFF6B2B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 8),
                        
                        // Lista de Itens do Pedido
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF181824).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2D2D44)),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: o.itens.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0xFF2D2D44), height: 16),
                              itemBuilder: (c, idx) {
                                final item = o.itens[idx];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.quantidade.toStringAsFixed(0)}x ${item.nomeProduto}',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      item.unidade,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtotais e Observações
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Subtotal:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 2),
                                const Text('Taxa de entrega:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                if (parsed.observacoesLimpa.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Obs: ${parsed.observacoesLimpa}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$ ${(parsed.totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                const Text('R\$ 0,00', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF2D2D44), height: 24),

                        // Barra de Botões Operacionais
                        Row(
                          children: [
                            // Botão Editar
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PdvPage(ordemParaEditar: o),
                                    ),
                                  );
                                  if (result == true) {
                                    await _carregarOrdens();
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF2D2D44)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Botão Reverter Etapa
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: o.status == StatusOrdemPreparo.pendente
                                    ? null
                                    : () async {
                                        StatusOrdemPreparo anterior = StatusOrdemPreparo.pendente;
                                        if (o.status == StatusOrdemPreparo.emPreparo) {
                                          anterior = StatusOrdemPreparo.pendente;
                                        } else if (o.status == StatusOrdemPreparo.pronto) {
                                          anterior = StatusOrdemPreparo.emPreparo;
                                        } else if (o.status == StatusOrdemPreparo.entregue) {
                                          anterior = StatusOrdemPreparo.pronto;
                                        } else if (o.status == StatusOrdemPreparo.cancelado) {
                                          anterior = StatusOrdemPreparo.pendente;
                                        }
                                        await _moverStatus(o, anterior);
                                        Navigator.pop(ctx);
                                        // Abre novamente para ver rebatido
                                        final reloaded = await _ordemRepo.findById(o.id);
                                        if (reloaded != null) {
                                          _exibirDetalhes(reloaded, DadosOrdemKanban.fromOrdem(reloaded));
                                        }
                                      },
                                icon: const Icon(Icons.undo_outlined, size: 16),
                                label: const Text('Reverter Etapa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF2D2D44)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Botão Cancelar
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _cancelarPedido(o);
                                },
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text('Cancelar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Botão Imprimir Direto
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _exibirOpcoesImpressao(context, o, parsed),
                                icon: const Icon(Icons.print_outlined, size: 16),
                                label: const Text('Imprimir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B2B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── PAINEL DIREITO: LINHA DO TEMPO OPERACIONAL (Lifecycle Logs) ──
                Expanded(
                  flex: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF141420),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
                      border: Border(left: BorderSide(color: Color(0xFF2D2D44))),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.history_toggle_off_outlined, color: Colors.white70, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'LINHA DO TEMPO OPERACIONAL',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF2D2D44), height: 28),
                        
                        Expanded(
                          child: FutureBuilder<List<HistoricoOrdemPreparo>>(
                            future: _ordemRepo.findHistoricoByOrdemId(o.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: FincoreColors.primary));
                              }
                              final logs = snapshot.data ?? [];
                              if (logs.isEmpty) {
                                return const Center(
                                  child: Text('Nenhum log operacional gravado.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                                );
                              }

                              return ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  final isLast = index == logs.length - 1;
                                  
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Bullet e Linha de Conexão Vertical
                                      Column(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: _getLogColor(log.titulo),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFF1E1E2E), width: 2),
                                            ),
                                          ),
                                          if (!isLast)
                                            Container(
                                              width: 2,
                                              height: 54,
                                              color: const Color(0xFF2D2D44),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      // Informações do Log
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  log.titulo,
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  DateFormat('dd/MM - HH:mm').format(log.criadaEm.toLocal()),
                                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              log.descricao,
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Por: ${log.operadorNome}  •  Versão: ${log.versao}',
                                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            ),
                                            const SizedBox(height: 14),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLogColor(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('criado')) return const Color(0xFF3B82F6);
    if (t.contains('pix') || t.contains('pagamento')) return const Color(0xFF10B981);
    if (t.contains('status')) return const Color(0xFFF59E0B);
    return const Color(0xFF9333EA);
  }

  Widget _buildStepNode(String label, bool isSquare, bool isCompleted, {bool isCurrent = false}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? (isCurrent ? const Color(0xFFFF6B2B) : const Color(0xFF10B981))
                : const Color(0xFF2D2D44),
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isSquare ? BorderRadius.circular(6) : null,
            border: isCurrent ? Border.all(color: Colors.white, width: 1.5) : null,
          ),
          child: Icon(
            isCompleted ? (isCurrent ? Icons.access_time : Icons.check) : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.white : Colors.white30,
            size: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isCompleted ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? const Color(0xFF10B981) : const Color(0xFF2D2D44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKPIs(),
        const SizedBox(height: 18),
        _buildControlBar(),
        const SizedBox(height: 18),
        Expanded(child: _buildKanbanBoard()),
      ],
    );
  }

  // ─── KPIs OPERACIONAIS SUPERIORES ──────────────────────────────

  Widget _buildKPIs() {
    final hojeOrdens = _filteredOrdens;
    final totalPedidos = hojeOrdens.length;
    
    int entregas = 0;
    int retiradas = 0;
    int faturamentoCentavos = 0;

    for (final o in hojeOrdens) {
      final parsed = DadosOrdemKanban.fromOrdem(o);
      if (parsed.tipoLogistica.toLowerCase().contains('entrega')) {
        entregas++;
      } else {
        retiradas++;
      }
      faturamentoCentavos += parsed.totalCentavos;
    }

    final ticketMedio = totalPedidos > 0 ? (faturamentoCentavos / totalPedidos) : 0.0;

    return Row(
      children: [
        _StatCard(label: 'PEDIDOS HOJE', value: '$totalPedidos', icon: Icons.receipt_long_outlined, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 14),
        _StatCard(label: 'ENTREGAS', value: '$entregas', icon: Icons.delivery_dining_outlined, color: const Color(0xFF10B981)),
        const SizedBox(width: 14),
        _StatCard(label: 'RETIRADAS', value: '$retiradas', icon: Icons.storefront_outlined, color: const Color(0xFF9333EA)),
        const SizedBox(width: 14),
        _StatCard(
          label: 'FATURAMENTO',
          value: 'R\$ ${(faturamentoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
          icon: Icons.monetization_on_outlined,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 14),
        _StatCard(
          label: 'TICKET MÉDIO',
          value: 'R\$ ${(ticketMedio / 100).toStringAsFixed(2).replaceAll('.', ',')}',
          icon: Icons.analytics_outlined,
          color: const Color(0xFF06B6D4),
        ),
      ],
    );
  }

  // ─── BARRA DE CONTROLE E NAVEGAÇÃO DE DATA ─────────────────────

  Widget _buildControlBar() {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        children: [
          const Text('Data de Entrega:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _mudarDia(-1),
            icon: const Icon(Icons.chevron_left, size: 18),
            splashRadius: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          IconButton(
            onPressed: () => _mudarDia(1),
            icon: const Icon(Icons.chevron_right, size: 18),
            splashRadius: 20,
          ),
          const Spacer(),
          const Text('Origem:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
          const SizedBox(width: 12),
          _OrigemChip(label: 'Todos', selected: _selectedOrigem == 'Todos', onTap: () => _setOrigem('Todos')),
          const SizedBox(width: 8),
          _OrigemChip(label: 'Balcão', selected: _selectedOrigem == 'Balcão', onTap: () => _setOrigem('Balcão')),
          const SizedBox(width: 8),
          _OrigemChip(label: 'Mesa', selected: _selectedOrigem == 'Mesa', onTap: () => _setOrigem('Mesa')),
          const SizedBox(width: 8),
          _OrigemChip(label: 'Entrega', selected: _selectedOrigem == 'Entrega', onTap: () => _setOrigem('Entrega')),
        ],
      ),
    );
  }

  void _setOrigem(String origem) {
    setState(() {
      _selectedOrigem = origem;
      _applyFilters();
    });
  }

  // ─── QUADRO KANBAN REATIVO (KDS) ────────────────────────────────

  Widget _buildKanbanBoard() {
    final pendentes = _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.pendente).toList();
    final preparo = _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.emPreparo).toList();
    final prontos = _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.pronto).toList();
    final expedicao = _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.entregue).toList();
    final concluidos = _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.cancelado).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildKanbanColumn('PENDENTES', pendentes, const Color(0xFF3B82F6), StatusOrdemPreparo.emPreparo, 'Iniciar Preparo')),
        const SizedBox(width: 12),
        Expanded(child: _buildKanbanColumn('EM PREPARO', preparo, const Color(0xFFF59E0B), StatusOrdemPreparo.pronto, '✓ Pronto')),
        const SizedBox(width: 12),
        Expanded(child: _buildKanbanColumn('PRONTOS (SEPARADOS)', prontos, const Color(0xFF9333EA), StatusOrdemPreparo.entregue, '✓ Despachar')),
        const SizedBox(width: 12),
        Expanded(child: _buildKanbanColumn('SAIU / EM EXPEDIÇÃO', expedicao, const Color(0xFF10B981), StatusOrdemPreparo.cancelado, '✓ Finalizar')),
        const SizedBox(width: 12),
        Expanded(child: _buildKanbanColumn('CONCLUÍDOS / OUTROS', concluidos, Colors.grey, StatusOrdemPreparo.pendente, 'Reiniciar')),
      ],
    );
  }

  Widget _buildKanbanColumn(String title, List<OrdemPreparo> ordens, Color accentColor, StatusOrdemPreparo nextStatus, String actionText) {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.3), width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(12)),
                  child: Text('${ordens.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ordens.isEmpty
                ? const Center(child: Text('Nenhum pedido', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)))
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: ordens.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final o = ordens[idx];
                      final parsed = DadosOrdemKanban.fromOrdem(o);

                      // Cálculo de tempo de atraso
                      final tempoLimite = o.criadaEm.add(Duration(seconds: o.tempoEstimadoSegundos));
                      final agora = DateTime.now();
                      final isAtrasado = o.status != StatusOrdemPreparo.cancelado && agora.isAfter(tempoLimite);
                      final minutosAtraso = agora.difference(tempoLimite).inMinutes;

                      final formatHora = parsed.dataAgendada != null
                          ? DateFormat('dd/MM HH:mm').format(parsed.dataAgendada!)
                          : DateFormat('dd/MM HH:mm').format(o.criadaEm);

                      return Container(
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Linha 1: Hora e Tipo ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 13, color: FincoreColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatHora,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: parsed.tipoLogistica == 'Entrega'
                                        ? const Color(0xFF3B82F6).withOpacity(0.12)
                                        : const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    parsed.tipoLogistica.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: parsed.tipoLogistica == 'Entrega' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // ── Linha de Atraso ──
                            if (isAtrasado) ...[
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Atrasado $minutosAtraso min',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],

                            // ── Linha 2: Pedido ID e Prioridade ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pedido #${o.pedidoId.length > 5 ? o.pedidoId.substring(0, 5).toUpperCase() : o.pedidoId.toUpperCase()}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
                                ),
                                if (o.prioridade == PrioridadeOrdem.urgente)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                                    child: const Text('URGENTE', style: TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // ── Linha 3: Cliente ──
                            Builder(
                              builder: (context) {
                                final clienteDisplay = (parsed.cliente == 'Consumidor' && parsed.tipoLogistica != 'Entrega')
                                    ? 'Balcão (Consumidor)'
                                    : parsed.cliente;
                                
                                int totalCalculadoCentavos = parsed.totalCentavos;
                                if (totalCalculadoCentavos == 0) {
                                  for (final item in o.itens) {
                                    final pUnit = _precosProdutosMap[item.produtoId] ?? 0;
                                    totalCalculadoCentavos += (item.quantidade * pUnit).round();
                                  }
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      clienteDisplay,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (parsed.telefone.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(parsed.telefone, style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pagamento: ${parsed.pagamento}',
                                      style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                    ),

                                    const Divider(height: 16, color: FincoreColors.border),

                                    // ── Linha 4: Quantidades e Valores ──
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${parsed.totalUnidades.toStringAsFixed(0)} un. salgados',
                                          style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                                        ),
                                        Text(
                                          'R\$ ${(totalCalculadoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: FincoreColors.primary),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // ── Linha 5: Botões de Ação ──
                            Row(
                              children: [
                                // Imprimir Direto
                                _CardIconButton(
                                  icon: Icons.print_outlined,
                                  tooltip: 'Imprimir Direto (Silencioso)',
                                  onTap: () => _exibirOpcoesImpressao(context, o, parsed),
                                ),
                                const SizedBox(width: 6),

                                // Informações
                                _CardIconButton(
                                  icon: Icons.info_outline,
                                  tooltip: 'Ver Detalhes',
                                  onTap: () => _exibirDetalhes(o, parsed),
                                ),
                                const SizedBox(width: 6),

                                // Cancelar
                                if (o.status != StatusOrdemPreparo.cancelado) ...[
                                  _CardIconButton(
                                    icon: Icons.close,
                                    color: Colors.redAccent,
                                    tooltip: 'Cancelar Pedido',
                                    onTap: () => _cancelarPedido(o),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Avançar Status
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _moverStatus(o, nextStatus),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor.withOpacity(0.12),
                                      foregroundColor: accentColor,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: Text(actionText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets de Apoio ──────────────────────────────────────────────────────

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _CardIconButton({
    required this.icon,
    this.color = const Color(0xFF6B7280),
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FincoreColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrigemChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OrigemChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? FincoreColors.primary : FincoreColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : FincoreColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
