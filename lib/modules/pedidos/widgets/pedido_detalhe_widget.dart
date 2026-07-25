import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/domain_models.dart';
import '../../../providers/app_view_model.dart';
import '../../impressao/widgets/preview_cupom_widget.dart';
import '../../../pages/pedidos/novo_pedido_page.dart';
import '../../../database/app_database.dart';

import 'pedido_lifecycle_widget.dart';

class PedidoDetalheWidget extends StatefulWidget {
  final PedidoCompleto pedidoCompleto;
  final VoidCallback? onAtualizado;

  const PedidoDetalheWidget({
    super.key,
    required this.pedidoCompleto,
    this.onAtualizado,
  });

  static Future<void> exibirModal(
    BuildContext context, {
    required PedidoCompleto pedidoCompleto,
    VoidCallback? onAtualizado,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 900,
          height: 600,
          child: PedidoDetalheWidget(
            pedidoCompleto: pedidoCompleto,
            onAtualizado: onAtualizado,
          ),
        ),
      ),
    );
  }

  @override
  State<PedidoDetalheWidget> createState() => _PedidoDetalheWidgetState();
}

class _PedidoDetalheWidgetState extends State<PedidoDetalheWidget> {
  late PedidoCompleto _pedidoCompleto;
  List<EventosPedidoData> _eventos = [];
  bool _carregandoEventos = true;

  @override
  void initState() {
    super.initState();
    _pedidoCompleto = widget.pedidoCompleto;
    _carregarTimeline();
  }

  Future<void> _carregarTimeline() async {
    setState(() => _carregandoEventos = true);
    final vm = context.read<AppViewModel>();
    try {
      final evs = await vm.pedidos.obterEventos(_pedidoCompleto.pedido.id);
      setState(() {
        _eventos = evs;
        _carregandoEventos = false;
      });
    } catch (e) {
      setState(() => _carregandoEventos = false);
    }
  }

  Future<void> _recarregarPedido() async {
    final vm = context.read<AppViewModel>();
    final novoCompleto = await vm.pedidos.completo(_pedidoCompleto.pedido.id);
    setState(() {
      _pedidoCompleto = novoCompleto;
    });
    await _carregarTimeline();
    widget.onAtualizado?.call();
  }

  String _getPriorityBadge(String prioridade) {
    switch (prioridade) {
      case 'VIP':
        return '⭐ VIP';
      case 'Urgente':
        return '🔴 Urgente';
      case 'Entrega Programada':
        return '🟡 Programada';
      default:
        return '🟢 Normal';
    }
  }

  String? _obterStatusAnterior(String statusAtual) {
    switch (statusAtual) {
      case 'Em Preparo':
        return 'Pendente';
      case 'Pronto':
        return 'Em Preparo';
      case 'Em Rota':
      case 'Aguardando Cliente':
        return 'Pronto';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final p = _pedidoCompleto.pedido;
    final c = _pedidoCompleto.cliente;

    final isFinalizado = p.status == 'Finalizado' || p.status == 'Cancelado';
    final isPix = p.formaPagamento.toLowerCase().contains('pix');
    final statusAnterior = _obterStatusAnterior(p.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lado Esquerdo: Detalhes e Ações
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pedido #${pedidoNumero(p.numero)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusBadge(status: p.status),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getPriorityBadge(p.prioridade),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),

                // Linha de Vida (Lifecycle Tracker)
                PedidoLifecycleWidget(
                  status: p.status,
                  statusFinanceiro: p.statusFinanceiro,
                  tipoEntrega: p.tipoEntrega,
                ),
                const SizedBox(height: 16),

                // Informações do Cliente & Entrega
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nome,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Telefone: ${c.telefone}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  if (p.tipoEntrega == 'Entrega') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Endereço: ${c.logradouro}, ${c.numero} - ${c.bairro} (${c.cidade})',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                    ),
                                    if (c.referencia.isNotEmpty)
                                      Text(
                                        'Ref.: ${c.referencia}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(p.dataEntrega)}  •  ${p.tipoEntrega}  •  ${p.formaPagamento}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Itens do Pedido
                        const Text(
                          'ITENS DO PEDIDO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pedidoCompleto.itens.length,
                          itemBuilder: (context, index) {
                            final item = _pedidoCompleto.itens[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.quantidade}x ${item.produtoNome}', style: const TextStyle(fontSize: 13)),
                                  Text(
                                    dinheiro(item.valorTotalCentavos),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),

                        // Totais
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                            Text(dinheiro(p.subtotalCentavos), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Taxa de entrega:', style: TextStyle(fontSize: 13)),
                            Text(dinheiro(p.taxaEntregaCentavos), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              dinheiro(p.totalCentavos),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Seção de Ações
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Botão Editar (Apenas se não finalizado)
                    if (!isFinalizado)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final editado = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: const Text('Editar Pedido')),
                                body: NovoPedidoPage(pedidoParaEditar: _pedidoCompleto),
                              ),
                            ),
                          );
                          if (editado == true && context.mounted) {
                            _recarregarPedido();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                      ),

                    // Botão Reverter Etapa (Apenas se ativo e tiver status anterior)
                    if (!isFinalizado && statusAnterior != null)
                      OutlinedButton.icon(
                        onPressed: () => _abrirReverterEtapaDialog(statusAnterior),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Reverter Etapa'),
                      ),

                    // Botão Reabrir Pedido (Apenas se finalizado/cancelado)
                    if (isFinalizado)
                      FilledButton.icon(
                        onPressed: _abrirReabrirPedidoDialog,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reabrir Pedido'),
                      ),

                    // Botão Confirmar PIX
                    if (isPix && !p.pixConfirmado)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                        onPressed: _abrirConfirmarPixDialog,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Confirmar PIX'),
                      ),

                    // Botão Duplicar
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        vm.navegarRepetirPedido(_pedidoCompleto);
                      },
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: const Text('Duplicar'),
                    ),

                    // Botão Ver Cupom
                    OutlinedButton.icon(
                      onPressed: () {
                        PreviewCupomWidget.exibirDialog(
                          context,
                          pedidoCompleto: _pedidoCompleto,
                          settings: vm.settings,
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Ver Cupom'),
                    ),

                    // Botão Cancelar (Se não finalizado)
                    if (p.status != 'Cancelado' && p.status != 'Finalizado')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () async {
                          final confirmText = (p.status == 'Em Preparo' || p.status == 'Pronto')
                              ? 'A produção deste pedido já foi iniciada/finalizada. Deseja realmente cancelar?'
                              : 'Tem certeza que deseja cancelar o Pedido #${pedidoNumero(p.numero)}?';
                          final sim = await ConfirmDialog.exibir(
                            context,
                            titulo: 'Cancelar Pedido',
                            mensagem: confirmText,
                            textoConfirmar: 'Sim, Cancelar',
                            ehPerigoso: true,
                          );
                          if (sim && context.mounted) {
                            await vm.pedidos.cancelar(p.id);
                            _recarregarPedido();
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancelar'),
                      ),

                    // Botão Imprimir
                    FilledButton.icon(
                      onPressed: () async {
                        await vm.reimprimir(p.id);
                        // Registrar Evento de Reimpressão
                        await vm.pedidos.registrarEvento(
                          pedidoId: p.id,
                          tipoEvento: 'REIMPRESSAO',
                          titulo: 'Pedido reimpresso',
                          descricao: 'Comanda de conferência impressa novamente pelo operador.',
                          versao: p.versao,
                        );
                        if (context.mounted) {
                          AppSnackbar.sucesso(context, 'Comanda enviada para impressão.');
                          _recarregarPedido();
                        }
                      },
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Imprimir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Divisor vertical
        const VerticalDivider(width: 1),

        // Lado Direito: Linha do Tempo
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_outlined, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'LINHA DO TEMPO OPERACIONAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _carregandoEventos
                      ? const Center(child: CircularProgressIndicator())
                      : _eventos.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum evento registrado.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _eventos.length,
                              itemBuilder: (context, index) {
                                final ev = _eventos[index];
                                final hora = DateFormat('dd/MM - HH:mm').format(ev.criadoEm);
                                return _buildTimelineItem(ev, hora);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(EventosPedidoData ev, String dataHora) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e conector vertical
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getEventColor(ev.tipoEvento),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 45,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Conteúdo do evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ev.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      dataHora,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                if (ev.descricao.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ev.descricao,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Por: ${ev.usuarioNome}  •  Versão: v${ev.versao}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String tipo) {
    switch (tipo) {
      case 'CRIADO':
        return Colors.blue.shade600;
      case 'STATUS':
        return Colors.orange.shade600;
      case 'PIX_GERADO':
        return Colors.cyan.shade600;
      case 'PIX_CONFIRMADO':
        return Colors.green.shade600;
      case 'IMPRESSAO':
      case 'REIMPRESSAO':
        return Colors.teal.shade600;
      case 'EDITADO':
        return Colors.purple.shade600;
      case 'REABERTURA':
        return Colors.deepPurple.shade600;
      case 'CANCELAMENTO':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Dialogs de Governança
  Future<void> _abrirReabrirPedidoDialog() async {
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String reabrirStatus = 'Em Preparo';
        String motivo = 'Finalizado por engano';
        final obsCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Reabrir Pedido'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: reabrirStatus,
                    decoration: const InputDecoration(labelText: 'Redefinir Status para'),
                    items: const [
                      DropdownMenuItem(value: 'Em Preparo', child: Text('Em Preparo')),
                      DropdownMenuItem(value: 'Pronto', child: Text('Pronto')),
                    ],
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => reabrirStatus = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: motivo,
                    decoration: const InputDecoration(labelText: 'Motivo da Reabertura'),
                    items: const [
                      DropdownMenuItem(value: 'Cliente não recebeu', child: Text('Cliente não recebeu')),
                      DropdownMenuItem(value: 'Finalizado por engano', child: Text('Finalizado por engano')),
                      DropdownMenuItem(value: 'Correção administrativa', child: Text('Correção administrativa')),
                    ],
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => motivo = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsCtrl,
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Observação detalhada (Obrigatório)',
                      hintText: 'Insira observações adicionais...',
                      errorText: obsCtrl.text.trim().isEmpty ? 'Justificativa é obrigatória' : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: obsCtrl.text.trim().isEmpty ? null : () {
                    Navigator.pop(context, {
                      'status': reabrirStatus,
                      'motivo': '$motivo: ${obsCtrl.text.trim()}',
                      'obs': obsCtrl.text.trim(),
                    });
                  },
                  child: const Text('Confirmar Reabertura'),
                ),
              ],
            );
          },
        );
      },
    );

    if (res != null && mounted) {
      final vm = context.read<AppViewModel>();
      await vm.pedidos.reabrirPedido(
        pedidoId: _pedidoCompleto.pedido.id,
        novoStatus: res['status']!,
        motivo: res['motivo']!,
        observacao: res['obs']!,
      );
      _recarregarPedido();
    }
  }

  Future<void> _abrirReverterEtapaDialog(String statusAnterior) async {
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String motivo = 'Correção de produção';
        final obsCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Reverter de "${_pedidoCompleto.pedido.status}" para "$statusAnterior"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: motivo,
                    decoration: const InputDecoration(labelText: 'Motivo da Reversão'),
                    items: const [
                      DropdownMenuItem(value: 'Correção de produção', child: Text('Correção de produção')),
                      DropdownMenuItem(value: 'Atraso na logística', child: Text('Atraso na logística')),
                      DropdownMenuItem(value: 'Erro do operador', child: Text('Erro do operador')),
                    ],
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => motivo = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsCtrl,
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Observação detalhada (Obrigatório)',
                      hintText: 'Insira o motivo detalhadamente...',
                      errorText: obsCtrl.text.trim().isEmpty ? 'Justificativa é obrigatória' : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: obsCtrl.text.trim().isEmpty ? null : () {
                    Navigator.pop(context, {
                      'motivo': '$motivo: ${obsCtrl.text.trim()}',
                      'obs': obsCtrl.text.trim(),
                    });
                  },
                  child: const Text('Reverter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (res != null && mounted) {
      final vm = context.read<AppViewModel>();
      await vm.pedidos.reverterStatus(
        pedidoId: _pedidoCompleto.pedido.id,
        statusAnterior: statusAnterior,
        motivo: res['motivo']!,
        observacao: res['obs']!,
      );
      _recarregarPedido();
    }
  }

  Future<void> _abrirConfirmarPixDialog() async {
    final ref = await showDialog<String>(
      context: context,
      builder: (context) {
        final refCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Confirmar Recebimento PIX'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Certifique-se de que o valor já consta em sua conta bancária antes de confirmar.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código / Comprovante PIX',
                  hintText: 'Ex: E123456789... ou Nome do pagador',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, refCtrl.text.trim());
              },
              child: const Text('Confirmar Recebimento'),
            ),
          ],
        );
      },
    );

    if (ref != null && ref.isNotEmpty && mounted) {
      final vm = context.read<AppViewModel>();
      await vm.pedidos.confirmarPix(
        pedidoId: _pedidoCompleto.pedido.id,
        comprovantePix: ref,
      );
      _recarregarPedido();
    }
  }
}
