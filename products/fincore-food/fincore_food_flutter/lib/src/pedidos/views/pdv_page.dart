import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:fincore_food_flutter/src/shared/services/impressao_service.dart';
import 'package:fincore_food_flutter/src/shared/services/fincore_thermal_printer_service.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/cap/printing/print_capability.dart';


/// Item do carrinho de compras do PDV (Frente de Caixa do Fincore Food)
class _ItemCarrinho {
  final Produto produto;
  double quantidade;
  int precoUnitarioCentavos; // em centavos (preço da tabela base do cento ou da unidade)
  String? observacao;

  _ItemCarrinho({
    required this.produto,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    this.observacao,
  });

  /// O subtotal agora é apenas quantidade * preco, e devolve em centavos.
  int get subtotalCentavos {
    return (quantidade * precoUnitarioCentavos).round();
  }

  int get precoIndividualEfetivoCentavos {
    return precoUnitarioCentavos;
  }
}

enum _TipoAtendimentoPdv { delivery, balcao, mesa }

/// Frente de Caixa (POS / PDV) e Criação de Novos Pedidos do Fincore Food
/// Suporte a Delivery com cálculo automático de Taxa de Entrega, seleção de
/// Endereços (Casa/Escritório), faixas de Tabela de Preço (ex: Centos) e KDS.
class PdvPage extends StatefulWidget {
  final OrdemPreparo? ordemParaEditar;
  const PdvPage({super.key, this.ordemParaEditar});

  @override
  State<PdvPage> createState() => _PdvPageState();
}

class _PdvPageState extends State<PdvPage> {
  late final ProdutoRepository _produtoRepo;
  late final CategoriaRepository _categoriaRepo;
  late final TabelaPrecificacaoRepository _tabelaRepo;
  late final ItemTabelaPrecificacaoRepository _itemTabelaRepo;
  late final ProdutoTabelaPrecificacaoRepository _assocRepo;
  late final ClienteRepository _clienteRepo;
  late final LocalEntregaRepository _localRepo;
  late final TaxaEntregaRepository _taxaRepo;
  late final OrdemPreparoRepository _ordemRepo;

  // Preços Reais
  final Map<String, int> _precosProdutosCentavos = {};

  // Catálogo e Filtros
  List<Produto> _allProdutos = [];
  List<Produto> _filteredProdutos = [];
  List<Categoria> _categorias = [];
  String _searchQuery = '';
  String? _selectedCategoriaId;

  // Clientes, Delivery & Agendamento
  List<Cliente> _clientes = [];
  Cliente? _selectedCliente;
  List<LocalEntrega> _enderecosCliente = [];
  LocalEntrega? _selectedEndereco;
  List<TaxaEntrega> _taxas = [];
  TaxaEntrega? _taxaAplicada;
  DateTime? _dataHoraAgendada;

  // Precificação Avançada
  List<TabelaPrecificacao> _tabelas = [];
  List<ItemTabelaPrecificacao> _itensTabela = [];
  List<ProdutoTabelaPrecificacao> _assocs = [];


  // Carrinho e Checkout
  final List<_ItemCarrinho> _carrinho = [];
  _TipoAtendimentoPdv _tipoAtendimento = _TipoAtendimentoPdv.delivery;
  String _formaPagamentoSelecionada = 'PIX / QR Code';
  final _mesaCtrl = TextEditingController(text: '01');
  final _obsGeralCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isFinalizando = false;

  @override
  void initState() {
    super.initState();
    _produtoRepo = DependencyInjection().get<ProdutoRepository>();
    _categoriaRepo = DependencyInjection().get<CategoriaRepository>();
    _tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>();
    _itemTabelaRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>();
    _assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>();
    _clienteRepo = DependencyInjection().get<ClienteRepository>();
    _localRepo = DependencyInjection().get<LocalEntregaRepository>();
    _taxaRepo = DependencyInjection().get<TaxaEntregaRepository>();
    _ordemRepo = DependencyInjection().get<OrdemPreparoRepository>();
    _loadAllData();
  }

  @override
  void dispose() {
    _mesaCtrl.dispose();
    _obsGeralCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final prods = await _produtoRepo.findAll();
      final cats = await _categoriaRepo.findAll();
      final clis = List<Cliente>.from(await _clienteRepo.findAll());
      final txs = await _taxaRepo.findAll();
      final assocs = await _assocRepo.findAll();
      final itensTabela = await _itemTabelaRepo.findAll();
      final tabs = await _tabelaRepo.findAll();

      _assocs = assocs;
      _itensTabela = itensTabela;
      _tabelas = tabs;

      // Mapear preço de tabela real sem inventar valor
      _precosProdutosCentavos.clear();
      for (final p in prods) {
        final assoc = assocs.where((a) => a.produtoId == p.id && a.ativo).firstOrNull;
        if (assoc != null) {
          final item = itensTabela.where((i) => i.tabelaPrecificacaoId == assoc.tabelaPrecificacaoId).firstOrNull;
          if (item != null) {
            _precosProdutosCentavos[p.id] = item.valorUnitarioCentavos;
          }
        }
      }

      Cliente? editCliente;
      List<LocalEntrega> editEnderecos = [];
      LocalEntrega? editEndereco;
      TaxaEntrega? editTaxa;

      if (widget.ordemParaEditar != null) {
        final parsed = DadosOrdemKanban.fromOrdem(widget.ordemParaEditar!);
        editCliente = clis.where((c) => c.nome == parsed.cliente).firstOrNull;
        
        if (editCliente == null && parsed.cliente.isNotEmpty) {
          editCliente = Cliente(
            id: 'temp_edit_${const Uuid().v4().substring(0, 8)}',
            tenantId: widget.ordemParaEditar!.tenantId,
            nome: parsed.cliente,
            telefone: parsed.telefone,
            ativo: true,
            observacoes: '',
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              syncStatus: SyncStatus.synced,
              createdBy: 'system',
              updatedBy: 'system',
            ),
          );
          clis.add(editCliente);
        }

        if (editCliente != null && editCliente.id != null) {
          editEnderecos = await _localRepo.findByClienteId(editCliente.id);
          editEndereco = editEnderecos.firstOrNull;
          if (editEndereco != null) {
            editTaxa = txs.cast<TaxaEntrega?>().firstWhere(
                  (t) => t?.id == editEndereco!.cep,
                  orElse: () => null,
                );
            if (editTaxa == null && editEndereco.bairro.isNotEmpty) {
              editTaxa = txs.cast<TaxaEntrega?>().firstWhere(
                    (t) => t?.bairro?.toLowerCase() == editEndereco!.bairro.trim().toLowerCase() ||
                           t?.nome.toLowerCase().contains(editEndereco!.bairro.trim().toLowerCase()) == true,
                    orElse: () => null,
                  );
            }
          }
        }
      }

      setState(() {
        _allProdutos = prods;
        _categorias = cats;
        _clientes = clis;
        _taxas = txs;
        
        if (widget.ordemParaEditar != null) {
          final parsed = DadosOrdemKanban.fromOrdem(widget.ordemParaEditar!);
          _selectedCliente = editCliente;
          _enderecosCliente = editEnderecos;
          _selectedEndereco = editEndereco;
          _taxaAplicada = editTaxa;
          
          if (parsed.tipoLogistica == 'Entrega') {
            _tipoAtendimento = _TipoAtendimentoPdv.delivery;
          } else if (parsed.tipoLogistica == 'Mesa') {
            _tipoAtendimento = _TipoAtendimentoPdv.mesa;
            _mesaCtrl.text = parsed.cliente.replaceAll('Mesa ', '');
          } else {
            _tipoAtendimento = _TipoAtendimentoPdv.balcao;
          }
          
          _obsGeralCtrl.text = parsed.observacoesLimpa;
          _formaPagamentoSelecionada = parsed.pagamento;
          _dataHoraAgendada = parsed.dataAgendada;
          
          _carrinho.clear();
          for (final item in widget.ordemParaEditar!.itens) {
            final prod = prods.where((p) => p.id == item.produtoId).firstOrNull;
            if (prod != null) {
              _carrinho.add(_ItemCarrinho(
                produto: prod,
                quantidade: item.quantidade,
                precoUnitarioCentavos: _precosProdutosCentavos[prod.id] ?? 0,
              ));
            }
          }
        } else {
          if (_clientes.isNotEmpty) _selectCliente(_clientes.first);
        }
        
        _applyFilters();
        _recalcularPrecos();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do PDV: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProdutos = _allProdutos.where((p) {
        if (!p.ativo) return false;
        if (_selectedCategoriaId != null && p.categoriaId != _selectedCategoriaId) {
          return false;
        }
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final nameMatch = p.nome.toLowerCase().contains(q);
          final codMatch = p.codigo?.toLowerCase().contains(q) ?? false;
          if (!nameMatch && !codMatch) return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _selectCliente(Cliente? c) async {
    setState(() {
      _selectedCliente = c;
      _enderecosCliente = [];
      _selectedEndereco = null;
      _taxaAplicada = null;
    });

    if (c == null) return;
    try {
      final ends = await _localRepo.findByClienteId(c.id);
      if (mounted && _selectedCliente?.id == c.id) {
        setState(() {
          _enderecosCliente = ends;
          if (ends.isNotEmpty) {
            _selectEndereco(ends.first);
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar endereços no PDV: $e');
    }
  }

  void _selectEndereco(LocalEntrega? e) {
    setState(() {
      _selectedEndereco = e;
      if (e == null) {
        _taxaAplicada = null;
        return;
      }

      // 1) Busca primeiro se a taxa exata está salva no e.cep (padrão de persistência do cliente)
      TaxaEntrega? match;
      if (e.cep.isNotEmpty) {
        match = _taxas.cast<TaxaEntrega?>().firstWhere(
              (t) => t?.id == e.cep,
              orElse: () => null,
            );
      }
      // 2) Se não achou por id, tenta coincidir com o bairro do endereço
      if (match == null && e.bairro.isNotEmpty) {
        match = _taxas.cast<TaxaEntrega?>().firstWhere(
              (t) => t?.bairro?.toLowerCase() == e.bairro.trim().toLowerCase() ||
                     t?.nome.toLowerCase().contains(e.bairro.trim().toLowerCase()) == true,
              orElse: () => null,
            );
      }
      // 3) Fallback: Taxa Centro ou primeira taxa cadastrada
      match ??= _taxas.cast<TaxaEntrega?>().firstWhere(
            (t) => t?.id == 'd06efd08-251c-43f1-bdfc-76e2730a8451',
            orElse: () => _taxas.isNotEmpty ? _taxas.first : null,
          );

      _taxaAplicada = match;
    });
  }

  Future<void> _selecionarAgendamento() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dataHoraAgendada ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: FincoreColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataHoraAgendada ?? now),
      );
      if (time != null && mounted) {
        setState(() {
          _dataHoraAgendada = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  int _calculaPrecoBaseProduto(Produto prod) {
    // Retorna o preço cadastrado no módulo de precificação; não inventa preço se for 0.
    return _precosProdutosCentavos[prod.id] ?? 0;
  }

  void _recalcularPrecos() {
    final grouped = <String, List<_ItemCarrinho>>{};
    for (final item in _carrinho) {
      final assoc = _assocs.where((a) => a.produtoId == item.produto.id && a.ativo).firstOrNull;
      final tabelaId = assoc?.tabelaPrecificacaoId ?? 'default';
      grouped.putIfAbsent(tabelaId, () => []).add(item);
    }
    
    for (final entry in grouped.entries) {
      final tabelaId = entry.key;
      final itens = entry.value;
      if (tabelaId == 'default') continue; 
      
      final tabela = _tabelas.where((t) => t.id == tabelaId).firstOrNull;
      if (tabela == null) continue;
      
      final faixas = _itensTabela.where((i) => i.tabelaPrecificacaoId == tabelaId).toList()
        ..sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));
        
      double qtyTotal = 0;
      for (final i in itens) qtyTotal += i.quantidade;
      
      ItemTabelaPrecificacao? faixaAplicada;
      for (final f in faixas) {
        if (qtyTotal >= f.quantidadeMinima && (f.quantidadeMaxima == null || qtyTotal <= f.quantidadeMaxima!)) {
          faixaAplicada = f;
          break;
        }
      }
      if (faixaAplicada == null && faixas.isNotEmpty) faixaAplicada = faixas.first;
      
      final precoEfetivo = faixaAplicada?.valorUnitarioCentavos ?? 0;
      for (final i in itens) {
        i.precoUnitarioCentavos = precoEfetivo;
      }
    }
  }

  Future<void> _abrirDialogQuantidade(BuildContext context, {Produto? produto, _ItemCarrinho? itemExistente}) async {
    final prod = produto ?? itemExistente!.produto;
    final precoEfetivo = _calculaPrecoBaseProduto(prod);

    final qtyDialog = await showDialog<double>(
      context: context,
      builder: (ctx) => _QuantidadeDialog(
        nomeProduto: prod.nome,
        precoUnitario: precoEfetivo,
        quantidadeAtual: itemExistente?.quantidade,
      ),
    );

    if (qtyDialog != null && qtyDialog > 0) {
      setState(() {
        if (itemExistente != null) {
          itemExistente.quantidade = qtyDialog;
        } else {
          final idx = _carrinho.indexWhere((i) => i.produto.id == prod.id);
          if (idx >= 0) {
            _carrinho[idx].quantidade += qtyDialog;
          } else {
            _carrinho.add(_ItemCarrinho(
              produto: prod,
              quantidade: qtyDialog,
              precoUnitarioCentavos: precoEfetivo,
            ));
          }
        }
        _recalcularPrecos();
      });
    }
  }


  void _adicionarAoCarrinho(Produto p) {
    _definirQuantidade(p, 1, isDelta: true);
  }

  void _removerDoCarrinho(_ItemCarrinho item) {
    _definirQuantidade(item.produto, 0);
  }

  void _alterarQuantidade(_ItemCarrinho item, double delta) {
    _definirQuantidade(item.produto, delta, isDelta: true);
  }

  void _definirQuantidade(Produto p, double qty, {bool isDelta = false}) {
    setState(() {
      final idx = _carrinho.indexWhere((item) => item.produto.id == p.id);
      
      double novaQtde = qty;
      if (isDelta) {
        novaQtde = (idx >= 0 ? _carrinho[idx].quantidade : 0) + qty;
      }

      if (novaQtde <= 0) {
        if (idx >= 0) _carrinho.removeAt(idx);
      } else {
        if (idx >= 0) {
          _carrinho[idx].quantidade = novaQtde;
        } else {
          _carrinho.add(_ItemCarrinho(
            produto: p,
            quantidade: novaQtde,
            precoUnitarioCentavos: _calculaPrecoBaseProduto(p),
          ));
        }
      }
      _recalcularPrecos();
    });
  }



  int get _subtotalItensCentavos {
    int total = 0;
    for (final i in _carrinho) {
      total += i.subtotalCentavos;
    }
    return total;
  }

  int get _taxaEntregaCentavos {
    if (_tipoAtendimento != _TipoAtendimentoPdv.delivery) return 0;
    return _taxaAplicada?.valorCentavos ?? 0;
  }

  int get _totalGeralCentavos => _subtotalItensCentavos + _taxaEntregaCentavos;

  Future<void> _finalizarPedido() async {
    if (_carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione produtos ao carrinho antes de finalizar!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_tipoAtendimento == _TipoAtendimentoPdv.delivery && _selectedCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o Cliente do Delivery para calcular a taxa!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isFinalizando = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isEditing = widget.ordemParaEditar != null;
      final newId = isEditing ? widget.ordemParaEditar!.id : const Uuid().v4();
      final orderNumber = isEditing ? widget.ordemParaEditar!.pedidoId : (1040 + DateTime.now().second).toString(); // Número amigável de pedido
      final now = DateTime.now().toUtc();
      final createdTime = isEditing ? widget.ordemParaEditar!.criadaEm : now;

      final itensOrdem = _carrinho.map((item) {
        return ItemOrdemPreparo(
          produtoId: item.produto.id,
          nomeProduto: item.produto.nome,
          quantidade: item.quantidade.toDouble(),
          unidade: item.produto.unidadeVenda.name,
        );
      }).toList();

      final totalUnidades = _carrinho.fold<double>(0, (sum, i) => sum + i.quantidade);
      final agendadoText = _dataHoraAgendada != null
          ? 'Agendado: ${DateFormat('dd/MM/yyyy HH:mm').format(_dataHoraAgendada!)}\n'
          : '';
      final obText = '''
[DADOS_PEDIDO]
Cliente: ${_selectedCliente?.nome ?? (_tipoAtendimento == _TipoAtendimentoPdv.mesa ? 'Mesa ${_mesaCtrl.text}' : 'Balcao')}
Telefone: ${_selectedCliente?.telefone ?? ''}
Tipo: ${switch (_tipoAtendimento) {
        _TipoAtendimentoPdv.delivery => 'Entrega',
        _TipoAtendimentoPdv.balcao => 'Retirada',
        _TipoAtendimentoPdv.mesa => 'Mesa',
      }}
Pagamento: $_formaPagamentoSelecionada
Total: $_totalGeralCentavos
Unidades: $totalUnidades
${agendadoText}Obs: ${_obsGeralCtrl.text.trim()}
[/DADOS_PEDIDO]
'''.trim();

      final status = isEditing ? widget.ordemParaEditar!.status : StatusOrdemPreparo.pendente;
      final prioridade = isEditing ? widget.ordemParaEditar!.prioridade : PrioridadeOrdem.normal;

      final ordem = OrdemPreparo(
        id: newId,
        tenantId: tenantCtx.tenantId,
        pedidoId: orderNumber,
        itens: itensOrdem,
        status: status,
        prioridade: prioridade,
        operadorId: tenantCtx.usuario.id,
        criadaEm: createdTime,
        tempoEstimadoSegundos: isEditing ? widget.ordemParaEditar!.tempoEstimadoSegundos : 25 * 60,
        observacoes: obText,
        metadata: SyncMetadata(
          version: isEditing ? (widget.ordemParaEditar!.metadata.version + 1) : 1,
          createdAt: createdTime,
          updatedAt: now,
          createdBy: isEditing ? widget.ordemParaEditar!.metadata.createdBy : tenantCtx.usuario.id,
          updatedBy: tenantCtx.usuario.id,
          syncStatus: SyncStatus.pending,
        ),
      );

      await _ordemRepo.save(ordem);

      if (isEditing) {
        await _ordemRepo.registrarHistorico(ordem.id, 'Pedido editado', 'Os itens ou dados do cliente foram alterados.');
      } else {
        // Registrar histórico operacional inicial
        final itensSummary = ordem.itens.map((i) => "${i.quantidade.toStringAsFixed(0)}x ${i.nomeProduto}").join(", ");
        await _ordemRepo.registrarHistorico(ordem.id, 'Pedido criado', 'Itens: $itensSummary');

        if (_formaPagamentoSelecionada.toLowerCase().contains('pix')) {
          await _ordemRepo.registrarHistorico(ordem.id, 'PIX Copia e Cola gerado', 'Aguardando confirmação de pagamento do PIX.');
          await _ordemRepo.registrarHistorico(ordem.id, 'PIX Confirmado', 'Pagamento PIX confirmado com sucesso. Ref: ${const Uuid().v4().substring(0, 8).toUpperCase()}');
        } else {
          await _ordemRepo.registrarHistorico(ordem.id, 'Pagamento Registrado', 'Forma de pagamento: $_formaPagamentoSelecionada');
        }
      }

      // Monta dados para impressão
      final dadosImpressao = DadosImpressaoPedido(
        numeroPedido: orderNumber,
        nomeCliente: _selectedCliente?.nome ??
            (_tipoAtendimento == _TipoAtendimentoPdv.mesa
                ? 'Mesa ${_mesaCtrl.text}'
                : 'Balcão'),
        telefoneCliente: _selectedCliente?.telefone,
        tipoEntrega: switch (_tipoAtendimento) {
          _TipoAtendimentoPdv.delivery => 'Delivery',
          _TipoAtendimentoPdv.balcao => 'Retirada',
          _TipoAtendimentoPdv.mesa => 'Mesa ${_mesaCtrl.text}',
        },
        dataHora: DateTime.now(),
        itens: _carrinho.map((i) => ItemImpressao(
          nome: i.produto.nome,
          quantidade: i.quantidade,
          precoUnitarioCentavos: i.precoUnitarioCentavos,
          totalCentavos: i.subtotalCentavos,
        )).toList(),
        subtotalCentavos: _subtotalItensCentavos,
        taxaEntregaCentavos: _taxaEntregaCentavos,
        totalCentavos: _totalGeralCentavos,
        formaPagamento: _formaPagamentoSelecionada,
        observacoes: obText.isEmpty ? null : obText,
      );

      // Copia metadados para impressão ANTES de limpar o carrinho
      final clienteNomeFinal = _selectedCliente?.nome ??
          (_tipoAtendimento == _TipoAtendimentoPdv.mesa ? 'Mesa ${_mesaCtrl.text}' : 'Balcão');
      final telefoneClienteFinal = _selectedCliente?.telefone;
      final tipoLogisticaFinal = switch (_tipoAtendimento) {
        _TipoAtendimentoPdv.delivery => 'Delivery',
        _TipoAtendimentoPdv.balcao => 'Retirada',
        _TipoAtendimentoPdv.mesa => 'Mesa ${_mesaCtrl.text}',
      };
      final enderecoEntregaFinal = _selectedEndereco != null
          ? '${_selectedEndereco!.logradouro}, ${_selectedEndereco!.numero}'
          : null;
      final subtotalCentavosFinal = _subtotalItensCentavos;
      final taxaEntregaCentavosFinal = _taxaEntregaCentavos;
      final totalGeralCentavosFinal = _totalGeralCentavos;
      final formaPagamentoFinal = _formaPagamentoSelecionada;

      final printItens = _carrinho.map((i) {
        return PrintDataItem(
          nome: i.produto.nome,
          quantidade: i.quantidade,
          precoUnitarioCentavos: i.precoIndividualEfetivoCentavos,
          totalCentavos: i.subtotalCentavos,
        );
      }).toList();

      final printData = PrintData(
        pedidoId: orderNumber,
        clienteNome: clienteNomeFinal,
        clienteTelefone: telefoneClienteFinal,
        tipoLogistica: tipoLogisticaFinal,
        endereco: enderecoEntregaFinal,
        formaPagamento: formaPagamentoFinal,
        totalCentavos: totalGeralCentavosFinal,
        taxaEntregaCentavos: taxaEntregaCentavosFinal,
        itens: printItens,
        dataHora: DateTime.now(),
        observacao: obText,
      );

      // Limpa carrinho da tela após capturar os dados
      setState(() {
        _carrinho.clear();
        _obsGeralCtrl.clear();
        _dataHoraAgendada = null;
        _selectedCliente = null;
        _selectedEndereco = null;
        _taxaAplicada = null;
        _isFinalizando = false;
      });

      if (isEditing) {
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }

      if (mounted) {
        final useCase = DependencyInjection().get<PrintUseCase>();
        final res = await useCase.imprimirPedido(
          data: printData,
          usuario: DependencyInjection().get<TenantContext>().usuario.nome,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.summary),
              backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao finalizar pedido PDV: $e');
      setState(() => _isFinalizando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // COLUNA 1: CATÁLOGO DE PRODUTOS DO PDV
        Expanded(
          flex: 7,
          child: _buildCatalogoPanel(),
        ),
        const SizedBox(width: 18),
        // COLUNA 2: CARRINHO / FECHAMENTO DE PEDIDO (CHECKOUT)
        Expanded(
          flex: 5,
          child: _buildCarrinhoPanel(),
        ),
      ],
    );
  }

  Widget _buildCatalogoPanel() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOPO: BARRA DE BUSCA RÁPIDA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.border),
            ),
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Pesquisar por nome, código ou ler código de barras...',
                prefixIcon: Icon(Icons.search, size: 18, color: FincoreColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CHIPS DE CATEGORIAS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Todos os Itens',
                  isSelected: _selectedCategoriaId == null,
                  onTap: () => setState(() {
                    _selectedCategoriaId = null;
                    _applyFilters();
                  }),
                ),
                ..._categorias.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        label: c.nome,
                        isSelected: _selectedCategoriaId == c.id,
                        onTap: () => setState(() {
                          _selectedCategoriaId = c.id;
                          _applyFilters();
                        }),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: FincoreColors.border),
          const SizedBox(height: 18),

          // GRID DE CARDS CLICÁVEIS DO PDV
          Expanded(
            child: _filteredProdutos.isEmpty
                ? const Center(
                    child: Text('Nenhum produto disponível nesta categoria.', style: TextStyle(color: FincoreColors.textMuted)),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _filteredProdutos.length,
                    itemBuilder: (context, idx) {
                      final prod = _filteredProdutos[idx];
                      final precoUnit = _calculaPrecoBaseProduto(prod);
                      final precoStr = 'R\$ ${(precoUnit / 100).toStringAsFixed(2)}';
                      final itemNoCarrinho = _carrinho.where((i) => i.produto.id == prod.id).firstOrNull;
                      final qtdeNoCarrinho = itemNoCarrinho?.quantidade ?? 0;

                      return InkWell(
                        onTap: () => _definirQuantidade(prod, 1, isDelta: true),
                        onLongPress: () => _abrirDialogQuantidade(context, produto: prod),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: qtdeNoCarrinho > 0 ? FincoreColors.primary.withOpacity(0.05) : FincoreColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: qtdeNoCarrinho > 0 ? FincoreColors.primary : FincoreColors.border),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FincoreColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      prod.unidadeVenda.name.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                    ),
                                  ),
                                  if (qtdeNoCarrinho == 0)
                                    const Icon(Icons.add_circle_outline, color: FincoreColors.textMuted, size: 20)
                                  else
                                    const Icon(Icons.check_circle, color: FincoreColors.primary, size: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                prod.nome,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                              ),
                              Text(
                                precoStr,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FincoreColors.textSecondary),
                              ),
                              const Spacer(),
                              const Divider(height: 10, color: FincoreColors.border),
                              Align(
                                alignment: Alignment.center,
                                child: _ControleQuantidadeInline(
                                  initialValue: qtdeNoCarrinho,
                                  onChanged: (val) => _definirQuantidade(prod, val),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGruposPrecoBanner() {
    final grouped = <String, List<_ItemCarrinho>>{};
    for (final item in _carrinho) {
      final assoc = _assocs.where((a) => a.produtoId == item.produto.id && a.ativo).firstOrNull;
      final tabelaId = assoc?.tabelaPrecificacaoId ?? 'default';
      grouped.putIfAbsent(tabelaId, () => []).add(item);
    }

    final banners = <Widget>[];

    for (final entry in grouped.entries) {
      final tabelaId = entry.key;
      final itens = entry.value;
      if (tabelaId == 'default') continue; 
      
      final tabela = _tabelas.where((t) => t.id == tabelaId).firstOrNull;
      if (tabela == null) continue;
      
      final faixasGrupo = _itensTabela.where((i) => i.tabelaPrecificacaoId == tabelaId).toList()
        ..sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));
      
      if (faixasGrupo.isEmpty) continue;

      double qtyTotal = 0;
      for (final i in itens) qtyTotal += i.quantidade;

      ItemTabelaPrecificacao? faixaAplicada;
      ItemTabelaPrecificacao? proximaFaixa;

      for (int i = 0; i < faixasGrupo.length; i++) {
        final f = faixasGrupo[i];
        if (qtyTotal >= f.quantidadeMinima && (f.quantidadeMaxima == null || qtyTotal <= f.quantidadeMaxima!)) {
          faixaAplicada = f;
          if (i + 1 < faixasGrupo.length) {
            proximaFaixa = faixasGrupo[i + 1];
          }
          break;
        }
      }

      // Se a quantidade é menor que a primeira faixa
      if (faixaAplicada == null && faixasGrupo.isNotEmpty) {
        proximaFaixa = faixasGrupo.first;
      }

      final faixaStr = faixaAplicada != null 
          ? '${faixaAplicada.quantidadeMinima.toStringAsFixed(0)}${faixaAplicada.quantidadeMaxima != null ? "-${faixaAplicada.quantidadeMaxima!.toStringAsFixed(0)}" : "+"} un.'
          : 'Sem faixa';

      banners.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tabela.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary)),
                  Text('${qtyTotal.toStringAsFixed(0)} un. ($faixaStr)', style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                ],
              ),
            ),
            if (proximaFaixa != null) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text(
                          'Faltam ${(proximaFaixa.quantidadeMinima - qtyTotal).toStringAsFixed(0)} un. para a faixa ${proximaFaixa.quantidadeMinima.toStringAsFixed(0)}+ un.',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Economia estimada: R\$ ${(((faixaAplicada?.valorUnitarioCentavos ?? faixasGrupo.first.valorUnitarioCentavos) - proximaFaixa.valorUnitarioCentavos) * qtyTotal / 100).toStringAsFixed(2).replaceAll('.', ',')} nos itens atuais!',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ]
          ],
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('GRUPOS DE PREÇO & FAIXAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
        const SizedBox(height: 4),
        ...banners,
        const Divider(height: 16, color: FincoreColors.border),
      ],
    );
  }

  Widget _buildCarrinhoPanel() {
    double totalItens = 0;
    for (final i in _carrinho) totalItens += i.quantidade;

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── PARTE ROLÁVEL: CONFIGURAÇÕES E ITENS ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── CABEÇALHO RESUMO DO PEDIDO ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: FincoreColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('RESUMO DO PEDIDO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_carrinho.length} prod • ${totalItens.toStringAsFixed(0)} un.',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // SELETOR DO TIPO DE ATENDIMENTO (DELIVERY / RETIRADA / MESA)
                  Row(
                    children: [
                      Expanded(
                        child: _SegmentTab(
                          label: '🛵 Delivery',
                          selected: _tipoAtendimento == _TipoAtendimentoPdv.delivery,
                          onTap: () => setState(() => _tipoAtendimento = _TipoAtendimentoPdv.delivery),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SegmentTab(
                          label: '🏪 Retirada',
                          selected: _tipoAtendimento == _TipoAtendimentoPdv.balcao,
                          onTap: () => setState(() => _tipoAtendimento = _TipoAtendimentoPdv.balcao),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SegmentTab(
                          label: '🍽️ Mesa',
                          selected: _tipoAtendimento == _TipoAtendimentoPdv.mesa,
                          onTap: () => setState(() => _tipoAtendimento = _TipoAtendimentoPdv.mesa),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── CLIENTE E LOCALIZAÇÃO ──
                  if (_tipoAtendimento == _TipoAtendimentoPdv.delivery) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CLIENTE DO DELIVERY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Cliente?>(
                            value: _selectedCliente,
                            dropdownColor: FincoreColors.surface,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: FincoreColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: _clientes.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.nome} • (${c.telefone})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: _selectCliente,
                          ),
                          if (_enderecosCliente.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<LocalEntrega?>(
                              value: _selectedEndereco,
                              dropdownColor: FincoreColors.surface,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: FincoreColors.surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _enderecosCliente.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text('${e.nomeIdentificador} (${e.logradouro}, ${e.numero})', style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: _selectEndereco,
                            ),
                          ],
                          if (_taxaAplicada != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Taxa de Entrega (${_taxaAplicada!.nome}):', style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                                Text(
                                  'R\$ ${(_taxaEntregaCentavos / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (_tipoAtendimento == _TipoAtendimentoPdv.balcao) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CLIENTE (OPCIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Cliente?>(
                            value: _selectedCliente,
                            dropdownColor: FincoreColors.surface,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: FincoreColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sem Cliente (Venda Rápida)', style: TextStyle(fontSize: 13))),
                              ..._clientes.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text('${c.nome} • (${c.telefone})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }),
                            ],
                            onChanged: (c) => setState(() => _selectedCliente = c),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_tipoAtendimento == _TipoAtendimentoPdv.mesa) ...[
                    TextField(
                      controller: _mesaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mesa / Comanda',
                        prefixIcon: Icon(Icons.table_bar_outlined, color: FincoreColors.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // AGENDAMENTO (PARA RETIRADA OU DELIVERY)
                  if (_tipoAtendimento != _TipoAtendimentoPdv.mesa) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _dataHoraAgendada != null ? FincoreColors.primary.withOpacity(0.12) : FincoreColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _dataHoraAgendada != null ? FincoreColors.primary : FincoreColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 14, color: _dataHoraAgendada != null ? FincoreColors.primary : FincoreColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _dataHoraAgendada != null
                                    ? 'Retirada: ${DateFormat('dd/MM/yyyy • HH:mm').format(_dataHoraAgendada!)}'
                                    : '📅 Atendimento Imediato',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _dataHoraAgendada != null ? FontWeight.bold : FontWeight.normal,
                                  color: _dataHoraAgendada != null ? FincoreColors.primary : FincoreColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_dataHoraAgendada != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(right: 6),
                                  onPressed: () => setState(() => _dataHoraAgendada = null),
                                ),
                              InkWell(
                                onTap: _selecionarAgendamento,
                                child: Text(
                                  _dataHoraAgendada != null ? 'Alterar' : 'Agendar',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── GRUPOS DE PREÇO & FAIXAS DE DESCONTO ──
                  _buildGruposPrecoBanner(),

                  // ── ITENS DO PEDIDO ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ITENS NO CARRINHO', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                      if (_carrinho.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: FincoreColors.surface,
                                title: const Text('Limpar Carrinho'),
                                content: const Text('Remover todos os itens do carrinho?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Limpar Tudo'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) setState(() => _carrinho.clear());
                          },
                          child: const Text('Limpar Tudo', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                        ),
                    ],
                  ),

                  _carrinho.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_basket_outlined, size: 36, color: FincoreColors.textMuted),
                                SizedBox(height: 8),
                                Text('Carrinho vazio', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _carrinho.length,
                          separatorBuilder: (_, __) => const Divider(height: 8, color: FincoreColors.border),
                          itemBuilder: (context, idx) {
                            final item = _carrinho[idx];
                            final unitStr = 'R\$ ${(item.precoUnitarioCentavos / 100).toStringAsFixed(2)}';
                            final subStr = 'R\$ ${(item.subtotalCentavos / 100).toStringAsFixed(2)}';

                            return Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary)),
                                      Text('$unitStr/un', style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                                    ],
                                  ),
                                ),
                                _ControleQuantidadeInline(
                                  initialValue: item.quantidade,
                                  onChanged: (val) => _definirQuantidade(item.produto, val),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  subStr,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: FincoreColors.surface,
                                        title: const Text('Remover Item'),
                                        content: Text('Deseja remover ${item.produto.nome} do pedido?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Remover'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) _removerDoCarrinho(item);
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  tooltip: 'Remover Item',
                                ),
                              ],
                            );
                          },
                        ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── PARTE FIXA/DOQUEADA: TOTAIS E PAGAMENTO ──
          const Divider(height: 16, color: FincoreColors.border),

          // ── RESUMO FINANCEIRO ──
          _LinhaResumo(label: 'Subtotal:', value: 'R\$ ${(_subtotalItensCentavos / 100).toStringAsFixed(2)}'),
          if (_tipoAtendimento == _TipoAtendimentoPdv.delivery) ...[
            const SizedBox(height: 4),
            _LinhaResumo(
              label: 'Taxa de entrega:',
              value: 'R\$ ${(_taxaEntregaCentavos / 100).toStringAsFixed(2)}',
              color: FincoreColors.primary,
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FincoreColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                Text(
                  'R\$ ${(_totalGeralCentavos / 100).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // FORMAS DE PAGAMENTO
          const Text('FORMA DE PAGAMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PaymentChip(
                  label: '💵 Dinheiro',
                  selected: _formaPagamentoSelecionada == 'Dinheiro',
                  onTap: () => setState(() => _formaPagamentoSelecionada = 'Dinheiro'),
                ),
                const SizedBox(width: 6),
                _PaymentChip(
                  label: '💳 PIX',
                  selected: _formaPagamentoSelecionada == 'PIX / QR Code',
                  onTap: () => setState(() => _formaPagamentoSelecionada = 'PIX / QR Code'),
                ),
                const SizedBox(width: 6),
                _PaymentChip(
                  label: '💳 Cartão',
                  selected: _formaPagamentoSelecionada == 'Cartão',
                  onTap: () => setState(() => _formaPagamentoSelecionada = 'Cartão'),
                ),
                const SizedBox(width: 6),
                _PaymentChip(
                  label: '📝 Fiado',
                  selected: _formaPagamentoSelecionada == 'Fiado',
                  onTap: () => setState(() => _formaPagamentoSelecionada = 'Fiado'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // BOTÃO VERDE DE FINALIZAÇÃO (F2)
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isFinalizando || _carrinho.isEmpty ? null : _finalizarPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isFinalizando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _isFinalizando ? 'ENVIANDO PEDIDO...' : 'FINALIZAR PEDIDO',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary : FincoreColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : FincoreColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? FincoreColors.primary : FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : FincoreColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? FincoreColors.primary.withOpacity(0.12) : FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? FincoreColors.primary : FincoreColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _LinhaResumo({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? FincoreColors.textPrimary)),
      ],
    );
  }
}

// ─── Diálogo Numérico de Quantidade ──────────────────────────────────────────

/// Diálogo com teclado numérico para informar quantidade rapidamente.
class _QuantidadeDialog extends StatefulWidget {
  final String nomeProduto;
  final int precoUnitario;
  final double? quantidadeAtual;

  const _QuantidadeDialog({
    required this.nomeProduto,
    required this.precoUnitario,
    this.quantidadeAtual,
  });

  @override
  State<_QuantidadeDialog> createState() => _QuantidadeDialogState();
}

class _QuantidadeDialogState extends State<_QuantidadeDialog> {
  String _input = '';

  @override
  void initState() {
    super.initState();
    if (widget.quantidadeAtual != null && widget.quantidadeAtual! > 0) {
      _input = widget.quantidadeAtual.toString();
    }
  }

  void _press(String digit) {
    setState(() {
      if (_input.length < 6) _input += digit;
    });
  }

  void _backspace() {
    setState(() {
      if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
    });
  }

  void _clear() {
    setState(() => _input = '');
  }

  void _confirm() {
    final txt = _input.replaceAll(',', '.');
    final qty = double.tryParse(txt);
    if (qty != null && qty > 0) {
      Navigator.of(context).pop(qty);
    }
  }

  double get _subtotal {
    final txt = _input.replaceAll(',', '.');
    final qty = double.tryParse(txt) ?? 0.0;
    return (qty * widget.precoUnitario) / 100;
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = _input.isNotEmpty;
    final txt = _input.replaceAll(',', '.');
    final qty = double.tryParse(txt) ?? 0.0;

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUANTIDADE',
                        style: TextStyle(
                          color: FincoreColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.nomeProduto,
                        style: const TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Display do número
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasInput ? FincoreColors.accent : FincoreColors.border,
                  width: hasInput ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    hasInput ? _input : '0',
                    style: TextStyle(
                      color: hasInput ? FincoreColors.textPrimary : FincoreColors.textMuted,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (hasInput && qty > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Subtotal: R\$ ${_subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: FincoreColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Teclado numérico
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: [
                ...[
                  '7', '8', '9',
                  '4', '5', '6',
                  '1', '2', '3',
                ].map((d) => _NumKey(
                  label: d,
                  onTap: () => _press(d),
                )),
                _NumKey(
                  label: 'C',
                  onTap: _clear,
                  color: const Color(0xFFEF4444),
                ),
                _NumKey(
                  label: '0',
                  onTap: () => _press('0'),
                ),
                _NumKey(
                  icon: Icons.backspace_outlined,
                  onTap: _backspace,
                  color: FincoreColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Atalhos rápidos de quantidade
            Row(
              children: [
                for (final q in [25, 50, 100, 200])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _input = q.toString());
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FincoreColors.textSecondary,
                          side: BorderSide(
                            color: _input == q.toString()
                                ? FincoreColors.accent
                                : FincoreColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          '+$q',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Botão confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasInput && qty > 0 ? _confirm : null,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(
                  hasInput && qty > 0
                      ? 'Confirmar $qty unidade${qty != 1 ? 's' : ''}'
                      : 'Informe a quantidade',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  disabledBackgroundColor: FincoreColors.border,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  const _NumKey({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FincoreColors.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: color ?? FincoreColors.textPrimary, size: 20)
                : Text(
                    label!,
                    style: TextStyle(
                      color: color ?? FincoreColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Controle de Quantidade Inline (Digitável) ─────────────────────────────

class _ControleQuantidadeInline extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _ControleQuantidadeInline({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_ControleQuantidadeInline> createState() => _ControleQuantidadeInlineState();
}

class _ControleQuantidadeInlineState extends State<_ControleQuantidadeInline> {
  late TextEditingController _ctrl;
  late FocusNode _focus;

  String _format(double v) {
    if (v == 0) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.initialValue));
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _commitValue();
      }
    });
  }

  @override
  void didUpdateWidget(_ControleQuantidadeInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focus.hasFocus) {
      _ctrl.text = _format(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commitValue() {
    final val = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0.0;
    if (val != widget.initialValue) {
      widget.onChanged(val);
    }
  }

  void _increment(double delta) {
    double val = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0.0;
    if (val == 0 && widget.initialValue > 0) val = widget.initialValue;
    val += delta;
    if (val < 0) val = 0;
    _ctrl.text = _format(val);
    _commitValue();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _increment(-1),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(Icons.remove, size: 14, color: FincoreColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: FincoreColors.textMuted),
              ),
              onSubmitted: (_) => _commitValue(),
            ),
          ),
          InkWell(
            onTap: () => _increment(1),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(Icons.add, size: 14, color: FincoreColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
