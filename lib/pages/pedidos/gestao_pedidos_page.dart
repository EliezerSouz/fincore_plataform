import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../database/app_database.dart';
import '../../modules/pedidos/widgets/pedido_detalhe_widget.dart';
import '../../providers/app_view_model.dart';

class GestaoPedidosPage extends StatefulWidget {
  const GestaoPedidosPage({super.key});

  @override
  State<GestaoPedidosPage> createState() => _GestaoPedidosPageState();
}

class _GestaoPedidosPageState extends State<GestaoPedidosPage> {
  final _buscaController = TextEditingController();
  String _busca = '';
  Timer? _debounce;

  // Filtros administrativos
  String _filtroRapido = 'Todos'; // Todos, VIP, iFood, PIX Pendente
  String _filtroStatus = 'Todos';
  String _filtroPeriodo = 'Mês'; // Todos, Hoje, Semana, Mês, 30 Dias
  DateTimeRange? _filtroDateRange;

  // Seleção múltipla para ações em lote
  final Set<int> _selecionados = {};

  void _onBuscaChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _busca = value.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<Pedido> _filtrarPedidos(List<Pedido> pedidos, AppViewModel vm, {List<int>? pedidoIdsDoProduto}) {
    final now = DateTime.now();
    final hojeInicio = DateTime(now.year, now.month, now.day);
    final hojeFim = hojeInicio.add(const Duration(days: 1));

    final diaSemana = now.weekday;
    final estaSemanaInicio = hojeInicio.subtract(Duration(days: diaSemana - 1));
    final estaSemanaFim = estaSemanaInicio.add(const Duration(days: 7));

    final esteMesInicio = DateTime(now.year, now.month, 1);
    final esteMesFim = DateTime(now.year, now.month + 1, 1);

    final trintaDiasAtras = hojeInicio.subtract(const Duration(days: 30));

    return pedidos.where((p) {
      // 0. Filtros Cruzados do ERP
      if (vm.clienteFiltroId != null && p.clienteId != vm.clienteFiltroId) {
        return false;
      }
      if (vm.produtoFiltroId != null && pedidoIdsDoProduto != null) {
        if (!pedidoIdsDoProduto.contains(p.id)) return false;
      }

      // 1. Busca Textual
      if (_busca.isNotEmpty) {
        final bLower = _busca.toLowerCase();
        final numMatch = p.numero.toString().contains(bLower);
        final nomeMatch = p.clienteNome.toLowerCase().contains(bLower);
        final telMatch = p.clienteTelefone.contains(bLower);
        if (!numMatch && !nomeMatch && !telMatch) return false;
      }

      // 2. Filtro de Período (ignorar se houver filtro cruzado ativo)
      if (vm.clienteFiltroId == null && vm.produtoFiltroId == null) {
        final refData = p.dataEntrega;
        if (_filtroPeriodo == 'Hoje') {
          if (refData.isBefore(hojeInicio) || refData.isAfter(hojeFim)) return false;
        } else if (_filtroPeriodo == 'Semana') {
          if (refData.isBefore(estaSemanaInicio) || refData.isAfter(estaSemanaFim)) return false;
        } else if (_filtroPeriodo == 'Mês') {
          if (refData.isBefore(esteMesInicio) || refData.isAfter(esteMesFim)) return false;
        } else if (_filtroPeriodo == '30 Dias') {
          if (refData.isBefore(trintaDiasAtras)) return false;
        } else if (_filtroPeriodo == 'Personalizado' && _filtroDateRange != null) {
          final dInicio = DateTime(_filtroDateRange!.start.year, _filtroDateRange!.start.month, _filtroDateRange!.start.day);
          final dFim = DateTime(_filtroDateRange!.end.year, _filtroDateRange!.end.month, _filtroDateRange!.end.day).add(const Duration(days: 1));
          if (refData.isBefore(dInicio) || refData.isAfter(dFim)) return false;
        }
      }

      // 3. Filtro de Status
      if (_filtroStatus != 'Todos') {
        if (p.status != _filtroStatus) return false;
      }

      // 4. Filtro Favorito / Rápido
      if (_filtroRapido == 'VIP') {
        if (p.prioridade != 'VIP') return false;
      } else if (_filtroRapido == 'iFood') {
        final isiFood = p.origemId == 3 || p.observacoes.toLowerCase().contains('ifood');
        if (!isiFood) return false;
      } else if (_filtroRapido == 'PIX Pendente') {
        final isPixPendente = p.formaPagamento.toLowerCase().contains('pix') && !p.pixConfirmado;
        if (!isPixPendente) return false;
      }

      return true;
    }).toList();
  }

  String pedidoNumero(int num) => num.toString().padLeft(4, '0');
  String dinheiro(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  // Ações em lote
  Future<void> _processarImpressaoLote(AppViewModel vm) async {
    int erros = 0;
    for (final id in _selecionados) {
      try {
        await vm.reimprimir(id);
      } catch (_) {
        erros++;
      }
    }
    if (mounted) {
      if (erros == 0) {
        AppSnackbar.sucesso(context, 'Impressão das comandas enviada com sucesso!');
      } else {
        AppSnackbar.erro(context, 'Erro ao imprimir $erros comanda(s) selecionada(s).');
      }
      setState(() => _selecionados.clear());
    }
  }

  Future<void> _processarConcluirLote(AppViewModel vm) async {
    final confirmar = await ConfirmDialog.exibir(
      context,
      titulo: 'Concluir em Lote',
      mensagem: 'Deseja marcar os ${_selecionados.length} pedidos selecionados como Finalizados?',
      textoConfirmar: 'Concluir',
    );
    if (!confirmar) return;

    int erros = 0;
    for (final id in _selecionados) {
      try {
        await vm.pedidos.alterarStatus(id, 'Finalizado');
      } catch (_) {
        erros++;
      }
    }
    if (mounted) {
      if (erros == 0) {
        AppSnackbar.sucesso(context, 'Pedidos concluídos com sucesso!');
      } else {
        AppSnackbar.erro(context, 'Não foi possível concluir $erros pedido(s) devido a transições inválidas.');
      }
      setState(() => _selecionados.clear());
    }
  }

  Future<void> _processarCancelarLote(AppViewModel vm) async {
    final confirmar = await ConfirmDialog.exibir(
      context,
      titulo: 'Cancelar em Lote',
      mensagem: 'Deseja cancelar os ${_selecionados.length} pedidos selecionados?',
      textoConfirmar: 'Cancelar Pedidos',
      ehPerigoso: true,
    );
    if (!confirmar) return;

    int erros = 0;
    for (final id in _selecionados) {
      try {
        await vm.pedidos.cancelar(id);
      } catch (_) {
        erros++;
      }
    }
    if (mounted) {
      if (erros == 0) {
        AppSnackbar.sucesso(context, 'Pedidos cancelados com sucesso!');
      } else {
        AppSnackbar.erro(context, 'Não foi possível cancelar $erros pedido(s) (ex: já finalizados).');
      }
      setState(() => _selecionados.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Pedidos',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Painel administrativo para reaberturas, auditorias, reimpressões e cancelamentos.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Banner de Filtro Cruzado Ativo (ERP Integration)
          if (vm.clienteFiltroId != null || vm.produtoFiltroId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vm.clienteFiltroId != null
                          ? 'Filtro Ativo: Pedidos do cliente "${vm.clienteFiltroNome}"'
                          : 'Filtro Ativo: Pedidos reservando o produto "${vm.produtoFiltroNome}"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => vm.limparFiltrosCruzados(),
                    icon: const Icon(Icons.close, size: 16, color: AppColors.primary),
                    label: const Text('Limpar Filtro', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Barra de Filtros Favoritos (Tiny ERP Style)
          Row(
            children: [
              const Text('Favoritos: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...['Todos', 'VIP', 'iFood', 'PIX Pendente'].map((f) {
                final active = _filtroRapido == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: active,
                    onSelected: (val) {
                      if (val) setState(() => _filtroRapido = f);
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Pesquisa e filtros avançados
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _buscaController,
                  onChanged: _onBuscaChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscaController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _buscaController.clear();
                              _onBuscaChanged('');
                            },
                          )
                        : null,
                    hintText: 'Buscar por pedido, cliente ou telefone...',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Dropdown Status
              DropdownButton<String>(
                value: _filtroStatus,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                items: const ['Todos', 'Pendente', 'Em Preparo', 'Pronto', 'Em Rota', 'Aguardando Cliente', 'Finalizado', 'Cancelado']
                    .map((st) => DropdownMenuItem<String>(
                          value: st,
                          child: Text('Status: $st'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _filtroStatus = val);
                },
              ),
              const SizedBox(width: 24),
              // Dropdown Período
              DropdownButton<String>(
                value: _filtroPeriodo,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                items: const ['Todos', 'Hoje', 'Semana', 'Mês', '30 Dias', 'Personalizado']
                    .map((per) => DropdownMenuItem<String>(
                          value: per,
                          child: Text(per == 'Personalizado' && _filtroDateRange != null
                              ? 'Pers: ${DateFormat('dd/MM').format(_filtroDateRange!.start)} a ${DateFormat('dd/MM').format(_filtroDateRange!.end)}'
                              : 'Período: $per'),
                        ))
                    .toList(),
                onChanged: (val) async {
                  if (val != null) {
                    if (val == 'Personalizado') {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: _filtroDateRange,
                        builder: (context, child) {
                          return Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
                              child: child,
                            ),
                          );
                        },
                      );
                      if (range != null) {
                        setState(() {
                          _filtroPeriodo = val;
                          _filtroDateRange = range;
                        });
                      }
                    } else {
                      setState(() {
                        _filtroPeriodo = val;
                        _filtroDateRange = null;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Listagem de Pedidos com Drift
          Expanded(
            child: StreamBuilder<List<ItensPedidoData>>(
              stream: vm.produtoFiltroId != null
                  ? (db.select(db.itensPedido)..where((i) => i.produtoId.equals(vm.produtoFiltroId!))).watch()
                  : Stream.value([]),
              builder: (context, sItens) {
                final pedidoIdsDoProduto = vm.produtoFiltroId != null
                    ? (sItens.data ?? []).map((i) => i.pedidoId).toSet().toList()
                    : null;

                return StreamBuilder<List<Pedido>>(
                  stream: db.select(db.pedidos).watch(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final todosPedidos = snapshot.data!;
                    final filtrados = _filtrarPedidos(todosPedidos, vm, pedidoIdsDoProduto: pedidoIdsDoProduto)
                      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm)); // Mais novos primeiro

                if (filtrados.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Nenhum pedido encontrado nos filtros selecionados.'),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: Card(
                        child: ListView.separated(
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final p = filtrados[idx];
                            final selecionado = _selecionados.contains(p.id);
                            final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(p.criadoEm);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: selecionado,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selecionados.add(p.id);
                                        } else {
                                          _selecionados.remove(p.id);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      '#${p.numero}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    p.clienteNome,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 10),
                                  if (p.prioridade == 'VIP')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '⭐ VIP',
                                        style: TextStyle(color: Colors.purple.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Data: $dataFormatada  •  Entrega: ${DateFormat('dd/MM HH:mm').format(p.dataEntrega)}  •  ${p.formaPagamento}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusBadge(status: p.status),
                                  const SizedBox(width: 16),
                                  Text(
                                    dinheiro(p.totalCentavos),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () async {
                                      final completo = await vm.pedidos.completo(p.id);
                                      if (context.mounted) {
                                        PedidoDetalheWidget.exibirModal(
                                          context,
                                          pedidoCompleto: completo,
                                          onAtualizado: () => setState(() {}),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Barra de ações em lote flutuante (somente quando há selecionados)
                    if (_selecionados.isNotEmpty)
                      Card(
                        color: Colors.grey.shade900,
                        margin: const EdgeInsets.only(top: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selecionados.length} pedido(s) selecionado(s)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white54),
                                    ),
                                    onPressed: () => _processarImpressaoLote(vm),
                                    icon: const Icon(Icons.print_outlined),
                                    label: const Text('Imprimir Vias'),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => _processarConcluirLote(vm),
                                    icon: const Icon(Icons.done_all),
                                    label: const Text('Concluir'),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => _processarCancelarLote(vm),
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancelar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
);
  }
}
