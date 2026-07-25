import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../database/app_database.dart';
import '../../design_system/components/operational_fields.dart';
import '../../providers/app_view_model.dart';

class ProducaoPage extends StatefulWidget {
  const ProducaoPage({super.key});

  @override
  State<ProducaoPage> createState() => _ProducaoPageState();
}

class _ProducaoPageState extends State<ProducaoPage> {
  final _formKey = GlobalKey<FormState>();
  Produto? _produtoSelecionado;
  final _quantidadeController = TextEditingController(text: '1');
  DateTime _dataProducao = DateTime.now();
  final _responsavelController = TextEditingController();
  final _observacaoController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _responsavelController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _limparFormulario() {
    setState(() {
      _produtoSelecionado = null;
      _quantidadeController.text = '1';
      _dataProducao = DateTime.now();
      _responsavelController.clear();
      _observacaoController.clear();
    });
  }

  Future<void> _salvar(AppViewModel vm) async {
    if (!_formKey.currentState!.validate() || _produtoSelecionado == null) {
      AppSnackbar.erro(context, 'Selecione um produto e preencha os campos obrigatórios.');
      return;
    }

    final qtd = int.tryParse(_quantidadeController.text) ?? 0;
    if (qtd <= 0) {
      AppSnackbar.erro(context, 'A quantidade produzida deve ser maior que zero.');
      return;
    }

    setState(() => _salvando = true);

    try {
      await vm.registrarProducaoDiaria(
        produtoId: _produtoSelecionado!.id,
        quantidade: qtd,
        responsavel: _responsavelController.text.trim(),
        observacao: _observacaoController.text.trim(),
        data: _dataProducao,
      );

      if (mounted) {
        AppSnackbar.sucesso(context, 'Produção registrada com sucesso!');
        _limparFormulario();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.erro(context, 'Erro ao registrar produção: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;

    // Buscar produtos ativos para o dropdown
    final qProdutos = db.select(db.produtos)
      ..where((p) => p.ativo.equals(true))
      ..orderBy([(p) => OrderingTerm.asc(p.nome)]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registro de Produção',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Lance a fabricação diária de salgados prontos para alimentar o estoque físico.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: StreamBuilder<List<Produto>>(
                    stream: qProdutos.watch(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produtos = snapshot.data!;

                      if (vm.produtoPreSelecionadoProducao != null) {
                        final pre = vm.produtoPreSelecionadoProducao!;
                        final matching = produtos.where((p) => p.id == pre.id).toList();
                        if (matching.isNotEmpty) {
                          _produtoSelecionado = matching.first;
                          _quantidadeController.text = '${vm.quantidadeSugeridaProducao ?? 1}';
                          // Clear so it does not override on subsequent rebuilds
                          vm.produtoPreSelecionadoProducao = null;
                          vm.quantidadeSugeridaProducao = null;
                        }
                      }

                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seleção de Produto
                            const Text(
                              'Produto *',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Produto>(
                              value: _produtoSelecionado,
                              hint: const Text('Selecione o salgado produzido'),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.fastfood_outlined, size: 20),
                              ),
                              items: produtos.map((p) {
                                return DropdownMenuItem<Produto>(
                                  value: p,
                                  child: Text(p.nome),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _produtoSelecionado = val;
                                });
                              },
                              validator: (val) =>
                                  val == null ? 'Campo obrigatório' : null,
                            ),
                            const SizedBox(height: 20),

                            // Grid Quantidade e Data
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Quantidade Produzida',
                                    hint: 'Ex: 100',
                                    isRequired: true,
                                    controller: _quantidadeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    prefixIcon: const Icon(Icons.production_quantity_limits_outlined, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: AppDateField(
                                    label: 'Data da Produção',
                                    isRequired: true,
                                    value: _dataProducao,
                                    onChanged: (val) {
                                      setState(() {
                                        _dataProducao = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Responsável pela Produção
                            AppTextField(
                              label: 'Responsável',
                              hint: 'Quem produziu ou supervisionou?',
                              isRequired: false,
                              controller: _responsavelController,
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                            ),
                            const SizedBox(height: 20),

                            // Observações
                            AppTextField(
                              label: 'Observações',
                              hint: 'Algum detalhe ou anotação especial sobre o lote?',
                              isRequired: false,
                              controller: _observacaoController,
                              maxLines: 3,
                              prefixIcon: const Icon(Icons.edit_note, size: 20),
                            ),
                            const SizedBox(height: 32),

                            // Ações
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _limparFormulario,
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Limpar'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: _salvando ? null : () => _salvar(vm),
                                  icon: _salvando
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: const Text('Salvar Produção'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
