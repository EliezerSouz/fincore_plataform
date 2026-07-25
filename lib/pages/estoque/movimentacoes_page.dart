import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../database/app_database.dart';
import '../../design_system/components/app_text_field.dart';
import '../../providers/app_view_model.dart';

class MovimentacoesPage extends StatefulWidget {
  const MovimentacoesPage({super.key});

  @override
  State<MovimentacoesPage> createState() => _MovimentacoesPageState();
}

class _MovimentacoesPageState extends State<MovimentacoesPage> {
  final _buscaController = TextEditingController();
  String _busca = '';
  int? _produtoFiltroId;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Obter legenda bonita para o tipo de movimentação
  String _obterLegendaTipo(String tipo) {
    switch (tipo) {
      case 'ENTRADA_PRODUCAO':
        return 'Entrada por Produção';
      case 'RESERVA':
        return 'Reserva de Estoque';
      case 'LIBERACAO_RESERVA':
        return 'Liberação de Reserva';
      case 'BAIXA_ENTREGA':
        return 'Baixa por Entrega';
      case 'BAIXA_RETIRADA':
        return 'Baixa por Retirada';
      case 'AJUSTE_POSITIVO':
        return 'Ajuste de Entrada';
      case 'AJUSTE_NEGATIVO':
        return 'Ajuste de Saída';
      default:
        return tipo;
    }
  }

  Color _obterCorTipo(String tipo) {
    if (tipo.contains('ENTRADA') || tipo.contains('PRODUCAO') || tipo == 'LIBERACAO_RESERVA' || tipo == 'AJUSTE_POSITIVO') {
      return Colors.green;
    }
    if (tipo == 'RESERVA') {
      return Colors.orange;
    }
    return Colors.red;
  }

  IconData _obterIconeTipo(String tipo) {
    if (tipo == 'RESERVA') return Icons.lock_outline;
    if (tipo == 'LIBERACAO_RESERVA') return Icons.lock_open_outlined;
    if (tipo.contains('ENTRADA') || tipo.contains('PRODUCAO') || tipo == 'AJUSTE_POSITIVO') {
      return Icons.arrow_upward;
    }
    return Icons.arrow_downward;
  }

  void _dialogAjusteManual(BuildContext context, AppViewModel vm) {
    final formKey = GlobalKey<FormState>();
    Produto? produtoSelecionado;
    bool ehEntrada = true;
    String tipoAjuste = 'Quebra';
    final quantidadeCtrl = TextEditingController(text: '1');
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final db = vm.db;
            final qProdutos = db.select(db.produtos)
              ..where((p) => p.ativo.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.nome)]);

            final motivosEntrada = ['Entrada Manual', 'Devolução', 'Correção', 'Outro'];
            final motivosSaida = ['Quebra', 'Perda', 'Doação', 'Saída Manual', 'Correção', 'Outro'];

            return AlertDialog(
              title: const Text('Lançar Ajuste Manual de Estoque'),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selecionar Produto
                        const Text('Produto *', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StreamBuilder<List<Produto>>(
                          stream: qProdutos.watch(),
                          builder: (context, snapshot) {
                            final produtos = snapshot.data ?? [];
                            return DropdownButtonFormField<Produto>(
                              value: produtoSelecionado,
                              hint: const Text('Selecione o produto'),
                              items: produtos.map((p) {
                                return DropdownMenuItem<Produto>(
                                  value: p,
                                  child: Text(p.nome),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setStateDialog(() {
                                  produtoSelecionado = val;
                                });
                              },
                              validator: (val) => val == null ? 'Campo obrigatório' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Direção: Entrada ou Saída
                        const Text('Operação', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Entrada (+)'),
                                value: true,
                                groupValue: ehEntrada,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    ehEntrada = val!;
                                    tipoAjuste = motivosEntrada.first;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Saída (-)'),
                                value: false,
                                groupValue: ehEntrada,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    ehEntrada = val!;
                                    tipoAjuste = motivosSaida.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Motivo do ajuste
                        const Text('Motivo *', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: tipoAjuste,
                          items: (ehEntrada ? motivosEntrada : motivosSaida).map((m) {
                            return DropdownMenuItem<String>(
                              value: m,
                              child: Text(m),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateDialog(() {
                              tipoAjuste = val!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Quantidade
                        AppTextField(
                          label: 'Quantidade',
                          isRequired: true,
                          controller: quantidadeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 16),

                        // Observação
                        AppTextField(
                          label: 'Justificativa / Detalhes',
                          isRequired: true,
                          controller: motivoCtrl,
                          hint: 'Descreva o motivo do ajuste físico',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate() || produtoSelecionado == null) return;
                    final qtd = int.tryParse(quantidadeCtrl.text) ?? 0;
                    if (qtd <= 0) {
                      AppSnackbar.erro(context, 'A quantidade deve ser maior que zero.');
                      return;
                    }

                    try {
                      await vm.registrarAjusteManual(
                        produtoId: produtoSelecionado!.id,
                        ehEntrada: ehEntrada,
                        quantidade: qtd,
                        tipoAjuste: tipoAjuste,
                        motivo: motivoCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        AppSnackbar.sucesso(context, 'Ajuste manual de estoque salvo!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.erro(context, 'Erro ao salvar ajuste: $e');
                      }
                    }
                  },
                  child: const Text('Registrar Ajuste'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;

    // Buscar logs de movimentação de estoque
    final qMovs = db.select(db.movimentacoesEstoque).join([
      leftOuterJoin(db.produtos, db.produtos.id.equalsExp(db.movimentacoesEstoque.produtoId)),
    ])..orderBy([OrderingTerm.desc(db.movimentacoesEstoque.criadoEm)]);

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
                    'Movimentações de Estoque',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acompanhe o histórico de todas as entradas, reservas e saídas de estoque.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _dialogAjusteManual(context, vm),
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Lançar Ajuste Manual'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Filtros
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _buscaController,
                  onChanged: (val) => setState(() => _busca = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busca.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _buscaController.clear();
                              setState(() => _busca = '');
                            },
                          )
                        : null,
                    hintText: 'Filtrar por motivo...',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<List<Produto>>(
                  stream: vm.produtos.observar(),
                  builder: (context, snapshot) {
                    final produtos = snapshot.data ?? [];
                    return DropdownButtonFormField<int?>(
                      value: _produtoFiltroId,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por Produto',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Todos os produtos'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos os produtos'),
                        ),
                        ...produtos.map((p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.nome),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _produtoFiltroId = val;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<TypedResult>>(
              stream: qMovs.watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var dados = snapshot.data!;

                // Filtrar em memória
                if (_produtoFiltroId != null) {
                  dados = dados.where((row) => row.readTable(db.movimentacoesEstoque).produtoId == _produtoFiltroId).toList();
                }
                if (_busca.isNotEmpty) {
                  dados = dados.where((row) {
                    final prod = row.readTableOrNull(db.produtos);
                    final mov = row.readTable(db.movimentacoesEstoque);
                    final prodNome = prod?.nome.toLowerCase() ?? '';
                    final movMotivo = mov.motivo.toLowerCase();
                    return prodNome.contains(_busca) || movMotivo.contains(_busca);
                  }).toList();
                }

                if (dados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma movimentação registrada.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    itemCount: dados.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = dados[index];
                      final mov = row.readTable(db.movimentacoesEstoque);
                      final prod = row.readTableOrNull(db.produtos);
                      final cor = _obterCorTipo(mov.tipoMovimentacao);
                      final icone = _obterIconeTipo(mov.tipoMovimentacao);

                      final String signal = (mov.tipoMovimentacao.contains('ENTRADA') || mov.tipoMovimentacao.contains('CANCELAMENTO') || mov.tipoMovimentacao == 'PRODUCAO' || mov.tipoMovimentacao == 'AJUSTE_POSITIVO' || mov.tipoMovimentacao == 'LIBERACAO_RESERVA') ? '+' : '-';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cor.withAlpha(20),
                          child: Icon(icone, color: cor, size: 20),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              prod?.nome ?? 'Produto Excluído',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$signal${mov.quantidade} un.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cor,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${_obterLegendaTipo(mov.tipoMovimentacao)}  •  ${mov.motivo}',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Anterior: ${mov.saldoAnterior} un. → Atual: ${mov.saldoNovo} un.  |  Horário: ${DateFormat('dd/MM HH:mm').format(mov.criadoEm)}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
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
