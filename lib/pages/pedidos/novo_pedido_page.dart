import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../modules/impressao/widgets/preview_cupom_widget.dart';
import '../../database/app_database.dart';
import '../../models/domain_models.dart';
import '../../providers/app_view_model.dart';
import '../../services/calculadora_preco_grupo.dart';
import '../clientes/clientes_page.dart';
import '../../design_system/components/operational_fields.dart';
import 'package:flutter/services.dart';

class NovoPedidoPage extends StatefulWidget {
  final PedidoCompleto? pedidoParaEditar;
  final Cliente? clientePreSelecionado;
  const NovoPedidoPage({super.key, this.pedidoParaEditar, this.clientePreSelecionado});

  @override
  State<NovoPedidoPage> createState() => _NovoPedidoState();
}

class _NovoPedidoState extends State<NovoPedidoPage> {
  int _passoAtual = 0;
  bool _ehDuplicacao = false;
  Cliente? cliente;
  final itens = <ItemCarrinho>[];
  List<ResumoGrupo> resumos = [];
  Map<int, List<FaixasPrecoData>> faixasPorGrupo = {};
  String tipo = 'Entrega';
  String pagamento = 'Pix';
  String prioridade = 'Normal';
  DateTime entrega = DateTime.now().add(const Duration(hours: 2));

  // Controllers para Entrega Manual
  final logradouroCtrl = TextEditingController();
  final numeroCtrl = TextEditingController();
  final bairroCtrl = TextEditingController();
  final referenciaCtrl = TextEditingController();
  final cidadeCtrl = TextEditingController(text: 'Sorocaba');
  final cepCtrl = TextEditingController();

  // Endereço do Cliente Selecionado
  LocaisEntregaData? enderecoSelecionado;
  bool salvarComoNovoEndereco = false;
  final nomeIdentificadorCtrl = TextEditingController(text: 'Outro');

  final taxa = TextEditingController();
  final troco = TextEditingController();
  final obs = TextEditingController();
  String? erroPreco;
  final _filtroProdutosController = TextEditingController();
  String _filtroProdutos = '';
  String _categoriaSelecionada = 'Todos';
  bool _apenasSelecionados = false;
  bool _apenasEstoqueBaixo = false;
  final _controllers = <int, TextEditingController>{};
  final _focusNodes = <int, FocusNode>{};

  TextEditingController _getController(int prodId, int currentQty) {
    if (!_controllers.containsKey(prodId)) {
      _controllers[prodId] = TextEditingController(text: currentQty == 0 ? '' : '$currentQty');
    } else {
      final text = currentQty == 0 ? '' : '$currentQty';
      final node = _getFocusNode(prodId);
      if (_controllers[prodId]!.text != text && !node.hasFocus) {
        _controllers[prodId]!.text = text;
      }
    }
    return _controllers[prodId]!;
  }

  FocusNode _getFocusNode(int prodId) {
    return _focusNodes.putIfAbsent(prodId, () => FocusNode());
  }

  int cents(String v) {
    final cleanString = v.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleanString) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vm = context.read<AppViewModel>();
      
      if (widget.clientePreSelecionado != null) {
        final c = widget.clientePreSelecionado!;
        setState(() {
          cliente = c;
          logradouroCtrl.text = c.logradouro;
          numeroCtrl.text = c.numero;
          bairroCtrl.text = c.bairro;
          referenciaCtrl.text = c.referencia;
          cidadeCtrl.text = c.cidade;
          cepCtrl.text = c.cep;
        });
      }
      
      bool isDuplicando = false;
      PedidoCompleto? pCompleto = widget.pedidoParaEditar;
      if (pCompleto == null && vm.pedidoParaRepetir != null) {
        pCompleto = vm.pedidoParaRepetir;
        isDuplicando = true;
        setState(() {
          _ehDuplicacao = true;
        });
        vm.limparRepetirPedido();
      }
      
      if (pCompleto != null) {
        final p = pCompleto.pedido;
        final c = pCompleto.cliente;
        
        setState(() {
          cliente = c;
          tipo = p.tipoEntrega;
          pagamento = p.formaPagamento;
          prioridade = p.prioridade;
          entrega = isDuplicando ? DateTime.now().add(const Duration(hours: 2)) : p.dataEntrega;
          
          logradouroCtrl.text = c.logradouro;
          numeroCtrl.text = c.numero;
          bairroCtrl.text = c.bairro;
          referenciaCtrl.text = c.referencia;
          cidadeCtrl.text = c.cidade;
          cepCtrl.text = c.cep;
          
          taxa.text = NumberFormat.simpleCurrency(locale: 'pt_BR').format(p.taxaEntregaCentavos / 100);
          troco.text = p.trocoParaCentavos != null 
              ? NumberFormat.simpleCurrency(locale: 'pt_BR').format(p.trocoParaCentavos! / 100)
              : '';
          obs.text = p.observacoes;
        });

        // Converter itens do banco para ItemCarrinho
        final db = vm.db;
        for (final i in pCompleto.itens) {
          final prod = await (db.select(db.produtos)..where((pt) => pt.id.equals(i.produtoId))).getSingleOrNull();
          if (prod != null && prod.grupoPrecoId != null) {
            final gp = await (db.select(db.gruposPreco)..where((g) => g.id.equals(prod.grupoPrecoId!))).getSingleOrNull();
            if (gp != null) {
              setState(() {
                itens.add(ItemCarrinho(
                  produto: prod,
                  grupo: gp,
                  quantidade: i.quantidade,
                  valorUnitarioCentavos: i.valorUnitarioCentavos,
                ));
              });
            }
          }
        }
        
        await _recalcular(vm);
      } else {
        if (taxa.text.isEmpty) {
          final double valor = vm.settings.taxaPadrao / 100;
          taxa.text = NumberFormat.simpleCurrency(locale: 'pt_BR').format(valor);
        }
      }
    });
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    taxa.dispose();
    troco.dispose();
    obs.dispose();
    logradouroCtrl.dispose();
    numeroCtrl.dispose();
    bairroCtrl.dispose();
    referenciaCtrl.dispose();
    cidadeCtrl.dispose();
    cepCtrl.dispose();
    nomeIdentificadorCtrl.dispose();
    _filtroProdutosController.dispose();
    super.dispose();
  }

  void _limparFormularioManual() {
    logradouroCtrl.clear();
    numeroCtrl.clear();
    bairroCtrl.clear();
    referenciaCtrl.clear();
    cidadeCtrl.text = 'Sorocaba';
    cepCtrl.clear();
  }

  void _preencherFormularioManual(String log, String num, String bai, String ref, String cid, String cep) {
    logradouroCtrl.text = log;
    numeroCtrl.text = num;
    bairroCtrl.text = bai;
    referenciaCtrl.text = ref;
    cidadeCtrl.text = cid;
    cepCtrl.text = cep;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ehDuplicacao
                        ? 'Repetir Pedido'
                        : (widget.pedidoParaEditar != null ? 'Editar Pedido' : 'Novo Pedido'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preencha as informações na central de vendas.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal Stepper Indicator
          _buildStepperIndicator(),
          const SizedBox(height: 20),

          // 2-Column Operational Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna da Esquerda (Formulários das etapas)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildStepContent(vm),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Coluna da Direita (Resumo do Pedido persistente)
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    child: _buildPersistentResumo(vm),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _podeAvancar() {
    if (_passoAtual == 0) {
      if (cliente == null) return false;
      if (tipo == 'Entrega') {
        return logradouroCtrl.text.isNotEmpty &&
            numeroCtrl.text.isNotEmpty &&
            bairroCtrl.text.isNotEmpty;
      }
      return true;
    }
    if (_passoAtual == 1) {
      return itens.isNotEmpty && erroPreco == null;
    }
    return true;
  }

  Widget _buildStepperIndicator() {
    final etapas = ['Cliente & Entrega', 'Produtos', 'Pagamento & Confirmação'];
    return Row(
      children: List.generate(etapas.length, (index) {
        final ativo = index <= _passoAtual;
        final corrente = index == _passoAtual;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: corrente
                    ? AppColors.primary
                    : (ativo ? AppColors.primary.withAlpha(50) : Colors.grey.shade300),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: corrente || !ativo ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (MediaQuery.sizeOf(context).width > 700)
                Text(
                  etapas[index],
                  style: TextStyle(
                    fontWeight: corrente ? FontWeight.bold : FontWeight.normal,
                    color: ativo ? AppColors.textPrimary : Colors.grey.shade500,
                  ),
                ),
              if (index < etapas.length - 1)
                Expanded(
                  child: Divider(
                    color: ativo ? AppColors.primary : Colors.grey.shade300,
                    thickness: 2,
                    indent: 8,
                    endIndent: 8,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(AppViewModel vm) {
    switch (_passoAtual) {
      case 0:
        return _buildStepClienteEntrega(vm);
      case 1:
        return _buildStepProdutos(vm);
      case 2:
        return _buildStepPagamento(vm);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepClienteEntrega(AppViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card do Cliente
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('IDENTIFICAÇÃO DO CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Cliente>>(
                        stream: vm.clientes.observar(),
                        builder: (_, s) => DropdownButtonFormField<Cliente>(
                          value: cliente,
                          decoration: const InputDecoration(
                            labelText: 'Selecionar Cliente *',
                            prefixIcon: Icon(Icons.person_search_outlined),
                          ),
                          items: (s.data ?? [])
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text('${c.nome} • ${c.telefone}'),
                                  ))
                              .toList(),
                          onChanged: (widget.clientePreSelecionado != null || (widget.pedidoParaEditar != null && !_ehDuplicacao))
                              ? null
                              : (v) {
                                  setState(() {
                                    cliente = v;
                                    enderecoSelecionado = null;
                                    if (v != null) {
                                      _preencherFormularioManual(
                                        v.logradouro,
                                        v.numero,
                                        v.bairro,
                                        v.referencia,
                                        v.cidade,
                                        v.cep,
                                      );
                                    }
                                  });
                                },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Cadastro rápido de cliente',
                      onPressed: (widget.clientePreSelecionado != null || (widget.pedidoParaEditar != null && !_ehDuplicacao))
                          ? null
                          : () async {
                              final c = await abrirCliente(context);
                              if (c != null && mounted) {
                                setState(() {
                                  cliente = c;
                                  enderecoSelecionado = null;
                                  _preencherFormularioManual(
                                    c.logradouro,
                                    c.numero,
                                    c.bairro,
                                    c.referencia,
                                    c.cidade,
                                    c.cep,
                                  );
                                });
                              }
                            },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                    ),
                  ],
                ),
                if (cliente != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.contact_phone_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Nome: ${cliente!.nome}  |  Telefone: ${cliente!.telefone}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card de Entrega
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('AGENDAMENTO & ENTREGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Entrega'),
                        value: 'Entrega',
                        groupValue: tipo,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              tipo = v;
                              if (v == 'Entrega') {
                                final double valor = vm.settings.taxaPadrao / 100;
                                taxa.text = NumberFormat.simpleCurrency(locale: 'pt_BR').format(valor);
                              } else {
                                taxa.text = 'R\$ 0,00';
                              }
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Retirada'),
                        value: 'Retirada',
                        groupValue: tipo,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              tipo = v;
                              taxa.text = 'R\$ 0,00';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDateField(
                        label: tipo == 'Entrega' ? 'Data da Entrega' : 'Data da Retirada',
                        value: entrega,
                        onChanged: (picked) {
                          setState(() {
                            entrega = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              entrega.hour,
                              entrega.minute,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTimeField(
                        label: tipo == 'Entrega' ? 'Hora da Entrega' : 'Hora da Retirada',
                        value: TimeOfDay(hour: entrega.hour, minute: entrega.minute),
                        onChanged: (picked) {
                          setState(() {
                            entrega = DateTime(
                              entrega.year,
                              entrega.month,
                              entrega.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: prioridade,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade do Pedido',
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Normal', child: Text('🟢 Normal')),
                    DropdownMenuItem(value: 'Entrega Programada', child: Text('🟡 Entrega Programada')),
                    DropdownMenuItem(value: 'Urgente', child: Text('🔴 Urgente')),
                    DropdownMenuItem(value: 'VIP', child: Text('⭐ VIP')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        prioridade = v;
                      });
                    }
                  },
                ),
                if (tipo == 'Entrega') ...[
                  const SizedBox(height: 16),
                  // Selecionar locais salvos do cliente
                  StreamBuilder<List<LocaisEntregaData>>(
                    stream: cliente == null ? const Stream.empty() : vm.observarLocaisEntrega(cliente!.id),
                    builder: (context, snapshot) {
                      final locais = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (locais.isNotEmpty) ...[
                            DropdownButtonFormField<LocaisEntregaData>(
                              value: enderecoSelecionado,
                              decoration: const InputDecoration(
                                labelText: 'Endereço Salvo',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                              items: locais
                                  .map((l) => DropdownMenuItem(
                                        value: l,
                                        child: Text('${l.nomeIdentificador}: ${l.logradouro}, ${l.numero}'),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  enderecoSelecionado = v;
                                  if (v != null) {
                                    _preencherFormularioManual(
                                      v.logradouro,
                                      v.numero,
                                      v.bairro,
                                      v.referencia,
                                      v.cidade,
                                      v.cep,
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  label: 'Rua / Logradouro',
                                  isRequired: true,
                                  controller: logradouroCtrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Número',
                                  isRequired: true,
                                  controller: numeroCtrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Bairro',
                                  isRequired: true,
                                  controller: bairroCtrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Referência',
                                  controller: referenciaCtrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Cidade',
                                  controller: cidadeCtrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppCepField(
                                  label: 'CEP',
                                  controller: cepCtrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppMoneyField(
                                  label: 'Taxa de Entrega',
                                  controller: taxa,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Salvar como novo local
                          Row(
                            children: [
                              Checkbox(
                                value: salvarComoNovoEndereco,
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => salvarComoNovoEndereco = v);
                                  }
                                },
                              ),
                              const Text('Salvar este endereço para futuras entregas', style: TextStyle(fontSize: 12)),
                              if (salvarComoNovoEndereco) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: nomeIdentificadorCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Apelido (Ex: Casa, Trabalho)',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProdutos(AppViewModel vm) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.primary),
                SizedBox(width: 8),
                Text('SELEÇÃO DE PRODUTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
            const Divider(height: 20),
            AppSearchField(
              label: 'Filtrar produtos',
              hint: 'Pesquise por nome, código ou categoria...',
              controller: _filtroProdutosController,
              onChanged: (v) => setState(() => _filtroProdutos = v),
              onClear: () {
                _filtroProdutosController.clear();
                setState(() => _filtroProdutos = '');
              },
            ),
            const SizedBox(height: 12),

            // Horizontal Categoria Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'Salgados', 'Assados', 'Doces', 'Bebidas'].map((cat) {
                  final isSelected = _categoriaSelecionada == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      onSelected: (selected) {
                        setState(() {
                          _categoriaSelecionada = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Checkboxes de Filtros Adicionais
            Row(
              children: [
                Checkbox(
                  value: _apenasSelecionados,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _apenasSelecionados = v);
                    }
                  },
                ),
                const Text('Apenas adicionados', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Checkbox(
                  value: _apenasEstoqueBaixo,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _apenasEstoqueBaixo = v);
                    }
                  },
                ),
                const Text('Estoque crítico', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<ProdutoComEstoque>>(
              stream: vm.observarEstoque(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var prods = snapshot.data!;

                // 1. Filtro de Texto
                if (_filtroProdutos.isNotEmpty) {
                  final search = _filtroProdutos.toLowerCase().trim();
                  prods = prods.where((p) {
                    final matchesId = p.produto.id.toString() == search;
                    final matchesNome = p.produto.nome.toLowerCase().contains(search);
                    final matchesCategoria = p.produto.categoria.toLowerCase().contains(search);
                    return matchesId || matchesNome || matchesCategoria;
                  }).toList();
                }

                // 2. Filtro de Categoria
                if (_categoriaSelecionada != 'Todos') {
                  prods = prods.where((p) => p.produto.categoria.toLowerCase() == _categoriaSelecionada.toLowerCase()).toList();
                }

                // 3. Mostrar apenas itens selecionados (quantidade > 0)
                if (_apenasSelecionados) {
                  prods = prods.where((p) {
                    final qt = itens.where((i) => i.produto.id == p.produto.id).firstOrNull?.quantidade ?? 0;
                    return qt > 0;
                  }).toList();
                }

                // 4. Mostrar apenas itens com estoque crítico (disponivel < 0)
                if (_apenasEstoqueBaixo) {
                  prods = prods.where((p) {
                    final disponivel = p.saldoAtual - p.reservado;
                    return disponivel < 0;
                  }).toList();
                }

                if (prods.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhum produto encontrado com os filtros selecionados.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prods.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final pe = prods[index];
                    final p = pe.produto;
                    final qt = itens.where((i) => i.produto.id == p.id).firstOrNull?.quantidade ?? 0;

                    return _PedidoProdutoLinha(
                      produtoComEstoque: pe,
                      vm: vm,
                      quantidade: qt,
                      controller: _getController(p.id, qt),
                      focusNode: _getFocusNode(p.id),
                      onQuantidadeChanged: (novaQt) => _alterarQuantidade(vm, p, novaQt),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPagamento(AppViewModel vm) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary),
                SizedBox(width: 8),
                Text('PAGAMENTO & OBSERVAÇÕES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildPaymentCard(
                  label: 'Pix',
                  icon: Icons.qr_code_scanner_outlined,
                  isSelected: pagamento.startsWith('Pix'),
                  onTap: () => setState(() => pagamento = 'Pix'),
                ),
                const SizedBox(width: 12),
                _buildPaymentCard(
                  label: 'Cartão',
                  icon: Icons.credit_card_outlined,
                  isSelected: pagamento.startsWith('Cartão'),
                  onTap: () => setState(() => pagamento = 'Cartão (Débito)'),
                ),
                const SizedBox(width: 12),
                _buildPaymentCard(
                  label: 'Dinheiro',
                  icon: Icons.payments_outlined,
                  isSelected: pagamento.startsWith('Dinheiro'),
                  onTap: () => setState(() => pagamento = 'Dinheiro'),
                ),
              ],
            ),
            
            // Sub-opções de Cartão
            if (pagamento.startsWith('Cartão')) ...[
              const SizedBox(height: 20),
              const Text('TIPO DE CARTÃO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSubPaymentChip('Débito'),
                  const SizedBox(width: 8),
                  _buildSubPaymentChip('Crédito'),
                  const SizedBox(width: 8),
                  _buildSubPaymentChip('Parcelado'),
                ],
              ),
            ],

            // Chave Pix com cópia rápida
            if (pagamento.startsWith('Pix')) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chave Pix para Pagamento (${vm.settings.pixTipoChave}):',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vm.settings.pixChave.isNotEmpty ? vm.settings.pixChave : 'Nenhuma chave cadastrada',
                            style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: Colors.blue.shade800),
                      onPressed: () {
                        final chave = vm.settings.pixChave.isNotEmpty ? vm.settings.pixChave : '';
                        if (chave.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: chave));
                          AppSnackbar.sucesso(context, 'Chave Pix copiada!');
                        } else {
                          AppSnackbar.erro(context, 'Nenhuma chave Pix para copiar.');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Campo de Troco para Dinheiro
            if (pagamento == 'Dinheiro') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                child: AppMoneyField(
                  label: 'Troco para:',
                  controller: troco,
                ),
              ),
            ],

            const SizedBox(height: 20),
            TextField(
              controller: obs,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações do Pedido',
                hintText: 'Ex: Entregar na porta lateral, salgados bem fritos...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubPaymentChip(String tipoCartao) {
    final target = 'Cartão ($tipoCartao)';
    final isSelected = pagamento == target;
    return ChoiceChip(
      selected: isSelected,
      label: Text(tipoCartao),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            pagamento = target;
          });
        }
      },
    );
  }

  Widget _buildPersistentResumo(AppViewModel vm) {
    final subtotal = itens.fold<int>(0, (a, b) => a + b.totalCentavos);
    final frete = tipo == 'Entrega' ? cents(taxa.text) : 0;
    final total = subtotal + frete;
    final totalProdutos = itens.length;
    final totalUnidades = itens.fold<int>(0, (sum, i) => sum + i.quantidade);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'RESUMO DO PEDIDO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                if (totalProdutos > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalProdutos prod • $totalUnidades un.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Cliente Info
            const Text('CLIENTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              cliente != null ? '${cliente!.nome}\n${cliente!.telefone}' : 'Nenhum cliente selecionado',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: cliente != null ? FontWeight.bold : FontWeight.normal,
                color: cliente != null ? AppColors.textPrimary : Colors.grey,
              ),
            ),
            const Divider(height: 16),

            // Agendamento Info
            const Text('ENTREGA / RETIRADA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              '$tipo: ${DateFormat('dd/MM/yyyy HH:mm').format(entrega)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            if (tipo == 'Entrega' && logradouroCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${logradouroCtrl.text}, ${numeroCtrl.text} - ${bairroCtrl.text}',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Detalhes por Grupo de Preço & Faixa Aplicada
            if (resumos.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('GRUPOS DE PREÇO & FAIXAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              ...resumos.map((resumo) {
                final grupoNome = resumo.grupo.nome;
                final qtdGrupo = resumo.quantidade;
                final faixas = faixasPorGrupo[resumo.grupo.id] ?? [];
                
                FaixasPrecoData? faixaAtual;
                for (final f in faixas) {
                  if (qtdGrupo >= f.quantidadeMinima && (f.quantidadeMaxima == null || qtdGrupo <= f.quantidadeMaxima!)) {
                    faixaAtual = f;
                    break;
                  }
                }
                
                String faixaTexto = 'Padrão';
                if (faixaAtual != null) {
                  faixaTexto = faixaAtual.quantidadeMaxima == null 
                      ? '${faixaAtual.quantidadeMinima}+ un.'
                      : '${faixaAtual.quantidadeMinima}-${faixaAtual.quantidadeMaxima} un.';
                }

                // Achar próxima faixa
                FaixasPrecoData? faixaProxima;
                if (faixaAtual != null && faixas.isNotEmpty) {
                  final sorted = List<FaixasPrecoData>.from(faixas)
                    ..sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));
                  final currIdx = sorted.indexWhere((f) => f.id == faixaAtual!.id);
                  if (currIdx >= 0 && currIdx < sorted.length - 1) {
                    faixaProxima = sorted[currIdx + 1];
                  }
                }

                Widget upsellWidget = const SizedBox();
                if (faixaProxima != null) {
                  final faltam = faixaProxima.quantidadeMinima - qtdGrupo;
                  final diffUnitario = resumo.valorUnitarioCentavos - faixaProxima.valorUnitarioCentavos;
                  final economia = diffUnitario * qtdGrupo;

                  if (faltam > 0 && economia > 0) {
                    upsellWidget = Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber.shade900),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Faltam $faltam un. para a faixa ${faixaProxima.quantidadeMinima}+ un.',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Economia estimada: ${dinheiro(economia)} nos itens atuais!',
                            style: TextStyle(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }
                } else if (faixaAtual != null) {
                  upsellWidget = Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 12, color: Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Melhor faixa aplicada: $faixaTexto',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(grupoNome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$qtdGrupo un. ($faixaTexto)', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      upsellWidget,
                    ],
                  ),
                );
              }),
            ],

            const Divider(height: 16),

            // Itens List
            const Text('ITENS NO CARRINHO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            if (itens.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhum item selecionado',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: itens.length,
                  itemBuilder: (context, idx) {
                    final item = itens[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantidade}x ${item.produto.nome}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dinheiro(item.totalCentavos),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 20),

            // Financeiro
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                Text(dinheiro(subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Taxa de entrega:', style: TextStyle(fontSize: 13)),
                Text(dinheiro(frete), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  Text(dinheiro(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                ],
              ),
            ),
            const Divider(height: 20),

            // Observações & Pagamento
            const Text('FORMA DE PAGAMENTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pagamento, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                if (pagamento == 'Dinheiro' && troco.text.isNotEmpty)
                  Text('Troco para: ${dinheiro(cents(troco.text))}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            if (obs.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('OBSERVAÇÕES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                obs.text,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (erroPreco != null) ...[
              const SizedBox(height: 12),
              Text(
                erroPreco!,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
            const Divider(height: 20),

            // Ações do Wizard
            Row(
              children: [
                if (_passoAtual > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _passoAtual--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_passoAtual > 0) const SizedBox(width: 8),
                if (_passoAtual < 2)
                  Expanded(
                    child: FilledButton(
                      onPressed: _podeAvancar() ? () => setState(() => _passoAtual++) : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Avançar'),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: vm.ocupado || cliente == null || itens.isEmpty || erroPreco != null
                              ? null
                              : () => _salvar(vm, imprimir: true),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Salvar e Imprimir', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          onPressed: vm.ocupado || cliente == null || itens.isEmpty || erroPreco != null
                              ? null
                              : () => _salvar(vm, imprimir: false),
                          child: const Text('Apenas Salvar'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alterarQuantidade(AppViewModel vm, Produto p, int novaQt) async {
    if (novaQt == 0) {
      itens.removeWhere((i) => i.produto.id == p.id);
    } else {
      final existente = itens.where((i) => i.produto.id == p.id).firstOrNull;
      if (existente == null) {
        final pg = await vm.produtos.comGrupo(p);
        if (pg == null) {
          if (mounted) {
            AppSnackbar.erro(
                context, 'Defina um grupo de preço para este produto primeiro.');
          }
          return;
        }
        itens.add(ItemCarrinho(produto: p, grupo: pg.grupo, quantidade: novaQt));
      } else {
        existente.quantidade = novaQt;
      }
    }
    await _recalcular(vm);
  }

  Future<void> _recalcular(AppViewModel vm) async {
    try {
      final r = await CalculadoraPrecoGrupo(vm.gruposPreco).recalcular(itens);
      
      final novasFaixas = <int, List<FaixasPrecoData>>{};
      for (final item in itens) {
        if (!novasFaixas.containsKey(item.grupo.id)) {
          final fx = await vm.gruposPreco.faixas(item.grupo.id);
          novasFaixas[item.grupo.id] = fx;
        }
      }

      if (mounted) {
        setState(() {
          resumos = r;
          faixasPorGrupo = novasFaixas;
          erroPreco = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          resumos = [];
          faixasPorGrupo = {};
          erroPreco = e.toString().replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  Future<void> _salvar(AppViewModel vm, {required bool imprimir}) async {
    try {
      // 1. Se necessário, atualizar o endereço do cliente ou cadastrar novo local de entrega
      if (cliente != null && tipo == 'Entrega') {
        final comp = ClientesCompanion(
          logradouro: Value(logradouroCtrl.text),
          numero: Value(numeroCtrl.text),
          bairro: Value(bairroCtrl.text),
          referencia: Value(referenciaCtrl.text),
          cidade: Value(cidadeCtrl.text),
          cep: Value(cepCtrl.text),
        );
        // Atualizar endereço principal do cliente no banco
        await vm.clientes.salvar(comp, id: cliente!.id);

        // Se pediu para salvar novo endereço nas opções de locais do cliente
        if (salvarComoNovoEndereco) {
          final locComp = LocaisEntregaCompanion.insert(
            clienteId: cliente!.id,
            nomeIdentificador: Value(nomeIdentificadorCtrl.text.trim()),
            logradouro: logradouroCtrl.text.trim(),
            numero: numeroCtrl.text.trim(),
            bairro: bairroCtrl.text.trim(),
            cidade: Value(cidadeCtrl.text.trim()),
            cep: Value(cepCtrl.text.trim()),
            referencia: Value(referenciaCtrl.text.trim()),
          );
          await vm.salvarLocalEntrega(locComp);
        }
      }

      // 2. Criar e salvar o pedido
      final id = await vm.salvarPedido(
        id: _ehDuplicacao ? null : widget.pedidoParaEditar?.pedido.id,
        cliente: cliente!,
        entrega: entrega,
        tipo: tipo,
        pagamento: pagamento,
        troco: pagamento == 'Dinheiro' && troco.text.isNotEmpty
            ? cents(troco.text)
            : null,
        observacoes: obs.text,
        taxa: tipo == 'Entrega' ? cents(taxa.text) : 0,
        itens: itens,
        prioridade: prioridade,
      );

      if (mounted) {
        AppSnackbar.sucesso(context, _ehDuplicacao ? 'Pedido repetido com sucesso!' : 'Pedido salvo com sucesso!');
        
        if (widget.pedidoParaEditar != null && !_ehDuplicacao) {
          Navigator.pop(context, true);
        } else {
          if (imprimir) {
            final pedidoCompleto = await vm.pedidos.completo(id);
            if (mounted) {
              PreviewCupomWidget.exibirDialog(
                context,
                pedidoCompleto: pedidoCompleto,
                settings: vm.settings,
              );
            }
          }

          setState(() {
            _passoAtual = 0;
            cliente = null;
            itens.clear();
            resumos.clear();
            obs.clear();
            troco.clear();
            _limparFormularioManual();
            enderecoSelecionado = null;
            salvarComoNovoEndereco = false;
            _controllers.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.erro(context, 'Erro ao salvar pedido: $e');
      }
    }
  }
}

class _PedidoProdutoLinha extends StatefulWidget {
  final ProdutoComEstoque produtoComEstoque;
  final AppViewModel vm;
  final int quantidade;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<int> onQuantidadeChanged;

  const _PedidoProdutoLinha({
    required this.produtoComEstoque,
    required this.vm,
    required this.quantidade,
    required this.controller,
    required this.focusNode,
    required this.onQuantidadeChanged,
  });

  @override
  State<_PedidoProdutoLinha> createState() => _PedidoProdutoLinhaState();
}

class _PedidoProdutoLinhaState extends State<_PedidoProdutoLinha> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pe = widget.produtoComEstoque;
    final p = pe.produto;
    final qt = widget.quantidade;

    // Calculo do estoque disponível e a produzir
    final disponivel = pe.saldoAtual - pe.reservado;
    final aProduzir = disponivel < 0 ? -disponivel : 0;

    return FutureBuilder<List<FaixasPrecoData>>(
      future: widget.vm.gruposPreco.faixas(p.grupoPrecoId ?? 0),
      builder: (context, sFaixas) {
        final faixas = sFaixas.data ?? [];
        int precoUnitario = faixas.isEmpty ? 0 : faixas.first.valorUnitarioCentavos;
        FaixasPrecoData? faixaAplicada;

        if (qt > 0) {
          final localItem = context.findAncestorStateOfType<_NovoPedidoState>()?.itens.firstWhere((i) => i.produto.id == p.id);
          if (localItem != null) {
            precoUnitario = localItem.valorUnitarioCentavos;
            final totalGrupo = context.findAncestorStateOfType<_NovoPedidoState>()?.itens
                .where((i) => i.grupo.id == localItem.grupo.id)
                .fold<int>(0, (sum, i) => sum + i.quantidade) ?? qt;
            
            for (final f in faixas) {
              if (totalGrupo >= f.quantidadeMinima && (f.quantidadeMaxima == null || totalGrupo <= f.quantidadeMaxima!)) {
                faixaAplicada = f;
                break;
              }
            }
          }
        } else {
          if (faixas.isNotEmpty) {
            faixaAplicada = faixas.first;
            precoUnitario = faixaAplicada.valorUnitarioCentavos;
          }
        }

        final subtotal = qt * precoUnitario;

        String faixaTexto = '';
        if (faixaAplicada != null) {
          if (faixaAplicada.quantidadeMaxima == null) {
            faixaTexto = '(${faixaAplicada.quantidadeMinima}+ un.)';
          } else {
            faixaTexto = '(${faixaAplicada.quantidadeMinima}-${faixaAplicada.quantidadeMaxima} un.)';
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: Row(
            children: [
              // Nome e Info do estoque
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Físico: ${pe.saldoAtual} un.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        Text(
                          '| Reservado: ${pe.reservado} un.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        if (aProduzir > 0)
                          Text(
                            '| ⚠ A Produzir: $aProduzir un.',
                            style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                          )
                        else
                          Text(
                            '| Disp: $disponivel un.',
                            style: TextStyle(fontSize: 11, color: disponivel < pe.estoqueMinimo ? Colors.orange.shade800 : Colors.green.shade800, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Preço Unitário e Faixa Aplicada
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço: ${dinheiro(precoUnitario)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: qt > 0 ? AppColors.primary : Colors.grey.shade800,
                      ),
                    ),
                    if (faixaTexto.isNotEmpty)
                      Text(
                        'Faixa: $faixaTexto',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),

              // Botões +/- e Input Numérico
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: qt > 0 ? () => widget.onQuantidadeChanged(qt - 1) : null,
                    icon: const Icon(Icons.remove, size: 14),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val) ?? 0;
                        widget.onQuantidadeChanged(parsed.clamp(0, 99999));
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onQuantidadeChanged(qt + 1),
                    icon: const Icon(Icons.add, size: 14),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Subtotal
              SizedBox(
                width: 90,
                child: Text(
                  qt > 0 ? dinheiro(subtotal) : 'R\$ 0,00',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: qt > 0 ? AppColors.primary : Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
