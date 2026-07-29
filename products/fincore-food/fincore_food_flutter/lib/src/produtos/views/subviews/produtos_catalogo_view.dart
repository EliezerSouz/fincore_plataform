import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/lote_insumo_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:uuid/uuid.dart';

/// Catálogo de Produtos Fincore Food — Layout Superior Reativo
/// Suporta visualização em Grid de Cards, Lista Compacta, Side-Sheet de Detalhes
/// e Formulário Lateral de Edição/Criação.
class ProdutosCatalogoView extends StatefulWidget {
  const ProdutosCatalogoView({super.key});

  @override
  State<ProdutosCatalogoView> createState() => _ProdutosCatalogoViewState();
}

class _ProdutosCatalogoViewState extends State<ProdutosCatalogoView> {
  late final ProdutoRepository _produtoRepo;
  late final CategoriaRepository _categoriaRepo;
  late final TabelaPrecificacaoRepository _tabelaRepo;
  late final ItemTabelaPrecificacaoRepository _itemRepo;
  late final ProdutoTabelaPrecificacaoRepository _assocRepo;
  late final LoteInsumoRepository _loteRepo;

  List<Produto> _allProdutos = [];
  List<Produto> _filteredProdutos = [];
  List<Categoria> _categorias = [];
  List<TabelaPrecificacao> _politicasPreco = [];

  // Dados reais de estoque mapeados por produtoId
  Map<String, _EstoqueInfo> _estoqueMap = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGridView = false; // Inicia por padrão no modo Lista / Tabela (padrão Clientes)

  // Filtros ativos
  String _searchQuery = '';
  String? _selectedFilterCategoriaId;

  // Detalhes do Produto
  Produto? _detailsProduto;
  Map<String, dynamic> _detailsPrecoInfo = {};

  // Form
  Produto? _editingProduto;
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _tempoCtrl = TextEditingController();
  final _precoBaseCtrl = TextEditingController();
  String? _selectedCategoriaId;
  String? _selectedPoliticaId;
  UnidadeVenda _unidade = UnidadeVenda.un;
  ProductStatus _status = ProductStatus.disponivel;
  bool _controlaEstoque = true;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _produtoRepo = DependencyInjection().get<ProdutoRepository>();
    _categoriaRepo = DependencyInjection().get<CategoriaRepository>();
    _tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>();
    _itemRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>();
    _assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>();
    _loteRepo = DependencyInjection().get<LoteInsumoRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _codigoCtrl.dispose();
    _tempoCtrl.dispose();
    _precoBaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prods = await _produtoRepo.findAll();
      final cats = await _categoriaRepo.findAll();
      final tabs = await _tabelaRepo.findAll();

      // Carregar estoques reais para cada produto
      final Map<String, _EstoqueInfo> estMap = {};
      for (final p in prods) {
        if (p.controlaEstoque) {
          final lotes = await _loteRepo.findAtivosPorProdutoFIFO(p.id);
          double disponivel = 0.0;
          double reservado = 0.0;
          for (final l in lotes) {
            disponivel += l.quantidadeDisponivel / 100.0;
            reservado += l.quantidadeReservada / 100.0;
          }
          estMap[p.id] = _EstoqueInfo(
            disponivel: disponivel,
            reservado: reservado,
          );
        } else {
          estMap[p.id] = const _EstoqueInfo(disponivel: 0.0, reservado: 0.0);
        }
      }

      setState(() {
        _allProdutos = prods;
        _categorias = cats;
        _estoqueMap = estMap;
        _politicasPreco = tabs.where((t) => t.tipoPolitica == PricingPolicyType.faixaQuantidade).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do catálogo: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProdutos = _allProdutos.where((p) {
        final matchesSearch = p.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.codigo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesCat = _selectedFilterCategoriaId == null || p.categoriaId == _selectedFilterCategoriaId;
        return matchesSearch && matchesCat;
      }).toList();
    });
  }

  Future<void> _showDetails(Produto produto) async {
    setState(() {
      _detailsProduto = produto;
      _detailsPrecoInfo = {'loading': true};
    });

    try {
      final assocs = await _assocRepo.findByProdutoId(produto.id);
      String tipoPreco = 'Preço Fixo';
      String valorFormatado = 'R\$ 0,00';

      for (final assoc in assocs) {
        if (assoc.ativo) {
          final tabela = await _tabelaRepo.findById(assoc.tabelaPrecificacaoId);
          if (tabela != null) {
            if (tabela.tipoPolitica == PricingPolicyType.faixaQuantidade) {
              tipoPreco = 'Por Lote (${tabela.nome})';
              final itens = await _itemRepo.findByTabelaId(tabela.id);
              if (itens.isNotEmpty) {
                valorFormatado = 'A partir de R\$ ${(itens.first.valorUnitarioCentavos / 100).toStringAsFixed(2)}';
              }
            } else {
              final itens = await _itemRepo.findByTabelaId(tabela.id);
              if (itens.isNotEmpty) {
                valorFormatado = 'R\$ ${(itens.first.valorUnitarioCentavos / 100).toStringAsFixed(2)}';
              }
            }
            break;
          }
        }
      }

      if (mounted && _detailsProduto?.id == produto.id) {
        setState(() {
          _detailsPrecoInfo = {
            'tipo': tipoPreco,
            'valor': valorFormatado,
            'loading': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _detailsPrecoInfo = {'loading': false, 'valor': 'R\$ 0,00', 'tipo': 'Não precificado'});
      }
    }
  }

  void _openEditor(Produto? produto) async {
    _editingProduto = produto;
    if (produto == null) {
      _nomeCtrl.clear();
      _descricaoCtrl.clear();
      _codigoCtrl.clear();
      _tempoCtrl.text = '30';
      _precoBaseCtrl.clear();
      _selectedCategoriaId = _categorias.isNotEmpty ? _categorias.first.id : null;
      _selectedPoliticaId = null;
      _unidade = UnidadeVenda.un;
      _status = ProductStatus.disponivel;
      _controlaEstoque = true;
      _ativo = true;
      _showEditSheet();
      return;
    }

    _nomeCtrl.text = produto.nome;
    _descricaoCtrl.text = produto.descricao ?? '';
    _codigoCtrl.text = produto.codigo ?? '';
    _tempoCtrl.text = produto.tempoMedioMinutos.toString();
    _selectedCategoriaId = produto.categoriaId;
    _unidade = produto.unidadeVenda;
    _status = produto.statusComercial;
    _controlaEstoque = produto.controlaEstoque;
    _ativo = produto.ativo;
    _precoBaseCtrl.text = '';
    _selectedPoliticaId = null;

    _showEditSheet();

    try {
      final assocs = await _assocRepo.findByProdutoId(produto.id);
      for (final assoc in assocs) {
        if (assoc.ativo) {
          final tabela = await _tabelaRepo.findById(assoc.tabelaPrecificacaoId);
          if (tabela != null) {
            if (tabela.tipoPolitica == PricingPolicyType.faixaQuantidade) {
              if (mounted) setState(() => _selectedPoliticaId = tabela.id);
            } else {
              final itens = await _itemRepo.findByTabelaId(tabela.id);
              if (itens.isNotEmpty && mounted) {
                setState(() {
                  _precoBaseCtrl.text = (itens.first.valorUnitarioCentavos / 100).toStringAsFixed(2);
                });
              }
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          width: 500,
          margin: const EdgeInsets.only(left: 100),
          decoration: const BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editingProduto == null ? 'Novo Produto' : 'Editar Produto',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FincoreTextField(controller: _nomeCtrl, label: 'Nome do Produto'),
                      const SizedBox(height: 14),
                      FincoreTextField(controller: _descricaoCtrl, label: 'Descrição'),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Grupo de Preço (Lotes / Faixas)', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedPoliticaId,
                                isExpanded: true,
                                dropdownColor: FincoreColors.surface,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Nenhum (Preço Unitário Fixo)')),
                                  ..._politicasPreco.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
                                ],
                                onChanged: (v) {
                                  setSheetState(() {
                                    _selectedPoliticaId = v;
                                    if (v != null) _precoBaseCtrl.text = '';
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_selectedPoliticaId == null) ...[
                        FincoreTextField(
                          controller: _precoBaseCtrl,
                          label: 'Preço Base Unitário (R\$)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          hint: 'Ex: 4.50',
                        ),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategoriaId,
                              dropdownColor: FincoreColors.surface,
                              decoration: const InputDecoration(labelText: 'Categoria'),
                              items: _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                              onChanged: (v) => setSheetState(() => _selectedCategoriaId = v),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<UnidadeVenda>(
                              value: _unidade,
                              dropdownColor: FincoreColors.surface,
                              decoration: const InputDecoration(labelText: 'Unidade'),
                              items: UnidadeVenda.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name.toUpperCase()))).toList(),
                              onChanged: (v) => setSheetState(() => _unidade = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ProductStatus>(
                              value: _status,
                              dropdownColor: FincoreColors.surface,
                              decoration: const InputDecoration(labelText: 'Status Comercial'),
                              items: ProductStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                              onChanged: (v) => setSheetState(() => _status = v!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FincoreTextField(
                              controller: _tempoCtrl,
                              label: 'Tempo Médio (min)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Controla Estoque?'),
                          Switch(
                            value: _controlaEstoque,
                            onChanged: (v) => setSheetState(() => _controlaEstoque = v),
                            activeColor: FincoreColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () async {
                        Navigator.pop(ctx);
                        await _salvar();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Salvar Produto', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty || _selectedCategoriaId == null) return;

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = _editingProduto == null;
      final id = isNew ? const Uuid().v4() : _editingProduto!.id;

      final produto = Produto(
        id: id,
        tenantId: tenantCtx.tenantId,
        codigo: _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim(),
        nome: nome,
        descricao: _descricaoCtrl.text.trim().isEmpty ? null : _descricaoCtrl.text.trim(),
        categoriaId: _selectedCategoriaId!,
        unidadeVenda: _unidade,
        statusComercial: _status,
        tempoMedioMinutos: int.tryParse(_tempoCtrl.text) ?? 30,
        controlaEstoque: _controlaEstoque,
        ordemProducao: isNew ? _allProdutos.length : _editingProduto!.ordemProducao,
        ativo: _ativo,
        metadata: _editingProduto?.metadata.copyWith(
              updatedAt: DateTime.now().toUtc(),
              syncStatus: SyncStatus.pending,
            ) ??
            SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
              syncStatus: SyncStatus.pending,
            ),
      );

      await _produtoRepo.save(produto);

      final todasAssocs = await _assocRepo.findByProdutoId(id);

      if (_selectedPoliticaId != null) {
        for (final a in todasAssocs) {
          if (a.tabelaPrecificacaoId.startsWith('tab_std_') && a.ativo) {
            await _assocRepo.save(ProdutoTabelaPrecificacao(
              id: a.id,
              tenantId: a.tenantId,
              produtoId: a.produtoId,
              tabelaPrecificacaoId: a.tabelaPrecificacaoId,
              ativo: false,
              prioridade: a.prioridade,
              metadata: a.metadata.copyWith(updatedAt: DateTime.now().toUtc(), syncStatus: SyncStatus.pending),
            ));
          }
        }

        final jaAssociado = todasAssocs.any((a) => a.tabelaPrecificacaoId == _selectedPoliticaId);
        if (!jaAssociado) {
          await _assocRepo.save(ProdutoTabelaPrecificacao(
            id: const Uuid().v4(),
            tenantId: tenantCtx.tenantId,
            produtoId: id,
            tabelaPrecificacaoId: _selectedPoliticaId!,
            ativo: true,
            prioridade: 2,
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
              syncStatus: SyncStatus.pending,
            ),
          ));
        }
      } else {
        for (final a in todasAssocs) {
          if (!a.tabelaPrecificacaoId.startsWith('tab_std_') && a.ativo) {
            await _assocRepo.save(ProdutoTabelaPrecificacao(
              id: a.id,
              tenantId: a.tenantId,
              produtoId: a.produtoId,
              tabelaPrecificacaoId: a.tabelaPrecificacaoId,
              ativo: false,
              prioridade: a.prioridade,
              metadata: a.metadata.copyWith(updatedAt: DateTime.now().toUtc(), syncStatus: SyncStatus.pending),
            ));
          }
        }

        final precoDouble = double.tryParse(_precoBaseCtrl.text.replaceAll(',', '.')) ?? 0.0;
        if (precoDouble > 0) {
          final valorCentavos = (precoDouble * 100).round();
          String tabelaId = 'tab_std_$id';

          await _tabelaRepo.save(TabelaPrecificacao(
            id: tabelaId,
            tenantId: tenantCtx.tenantId,
            nome: 'Preço Base — $nome',
            descricao: 'Preço unitário padrão',
            tipoPolitica: PricingPolicyType.unitario,
            prioridade: 1,
            ativo: true,
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
              syncStatus: SyncStatus.pending,
            ),
          ));

          await _itemRepo.save(ItemTabelaPrecificacao(
            id: 'item_std_$id',
            tenantId: tenantCtx.tenantId,
            tabelaPrecificacaoId: tabelaId,
            quantidadeMinima: 1,
            quantidadeMaxima: null,
            valorUnitarioCentavos: valorCentavos,
            ordem: 0,
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
              syncStatus: SyncStatus.pending,
            ),
          ));

          final assocId = 'assoc_std_$id';
          if (!todasAssocs.any((a) => a.id == assocId)) {
            await _assocRepo.save(ProdutoTabelaPrecificacao(
              id: assocId,
              tenantId: tenantCtx.tenantId,
              produtoId: id,
              tabelaPrecificacaoId: tabelaId,
              ativo: true,
              prioridade: 1,
              metadata: SyncMetadata(
                version: 1,
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
                createdBy: tenantCtx.usuario.id,
                updatedBy: tenantCtx.usuario.id,
                syncStatus: SyncStatus.pending,
              ),
            ));
          }
        }
      }

      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto salvo com sucesso!'), backgroundColor: Color(0xFF22C55E)),
      );
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
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
        _buildFilterBar(),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isGridView ? _buildGridCatalog() : _buildListCatalog(),
              ),
              if (_detailsProduto != null) ...[
                const SizedBox(width: 16),
                _buildDetailsSideSheet(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIs() {
    final total = _allProdutos.length;
    final cats = _categorias.length;
    
    // Contagem real baseada nos lotes em estoque
    int estoqueCritico = 0;
    _estoqueMap.forEach((_, info) {
      if (info.disponivel < 10) { // Limite hipotético de estoque baixo
        estoqueCritico++;
      }
    });

    return Row(
      children: [
        _KPIBadge(label: 'Total de Produtos', value: total, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _KPIBadge(label: 'Categorias', value: cats, color: const Color(0xFF9333EA)),
        const SizedBox(width: 12),
        _KPIBadge(label: 'Estoque Crítico', value: estoqueCritico, color: const Color(0xFFEF4444)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _openEditor(null),
          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Novo Produto', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) { _searchQuery = v; _applyFilters(); },
                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar produto...',
                    prefixIcon: Icon(Icons.search, size: 18, color: FincoreColors.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => setState(() => _isGridView = true),
                icon: Icon(Icons.grid_view_outlined, color: _isGridView ? FincoreColors.primary : FincoreColors.textMuted),
              ),
              IconButton(
                onPressed: () => setState(() => _isGridView = false),
                icon: Icon(Icons.format_list_bulleted, color: !_isGridView ? FincoreColors.primary : FincoreColors.textMuted),
              ),
            ],
          ),
          const Divider(height: 16, color: FincoreColors.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Todos',
                  isSelected: _selectedFilterCategoriaId == null,
                  onTap: () => setState(() { _selectedFilterCategoriaId = null; _applyFilters(); }),
                ),
                ..._categorias.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        label: c.nome,
                        isSelected: _selectedFilterCategoriaId == c.id,
                        onTap: () => setState(() { _selectedFilterCategoriaId = c.id; _applyFilters(); }),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCatalog() {
    if (_filteredProdutos.isEmpty) {
      return const Center(child: Text('Nenhum produto cadastrado.', style: TextStyle(color: FincoreColors.textMuted)));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.45,
      ),
      itemCount: _filteredProdutos.length,
      itemBuilder: (context, idx) {
        final p = _filteredProdutos[idx];
        final cat = _categorias.firstWhere((c) => c.id == p.categoriaId,
            orElse: () => Categoria(id: '', tenantId: '', nome: 'Geral', descricao: '', ordemExibicao: 0, ativo: true, metadata: SyncMetadata(version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: '', updatedBy: '')));

        final hasEstoque = p.controlaEstoque;
        final estInfo = _estoqueMap[p.id] ?? const _EstoqueInfo(disponivel: 0.0, reservado: 0.0);

        // Define a badge de estoque com base nos dados reais dos lotes
        String statusEstoque = 'SEM CONTROLE';
        Color statusColor = Colors.grey;
        if (hasEstoque) {
          if (estInfo.disponivel <= 0) {
            statusEstoque = 'CRÍTICO';
            statusColor = Colors.red;
          } else if (estInfo.disponivel < 50) {
            statusEstoque = 'ESTOQUE BAIXO';
            statusColor = Colors.orange;
          } else {
            statusEstoque = 'ESTOQUE OK';
            statusColor = Colors.green;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cat.nome.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: FincoreColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusEstoque,
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                p.nome,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
              ),
              const Spacer(),
              // Indicadores reais com base nos lotes insumos cadastrados no SQLite local
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StockIndicator(label: 'Físico', value: hasEstoque ? estInfo.disponivel.toStringAsFixed(0) : '—'),
                  _StockIndicator(label: 'Reservado', value: hasEstoque ? estInfo.reservado.toStringAsFixed(0) : '—'),
                  _StockIndicator(label: 'Produzir', value: hasEstoque ? (estInfo.disponivel < 10 ? '100' : '0') : '0'),
                  _StockIndicator(label: 'Cobertura', value: hasEstoque ? '${(estInfo.disponivel / 10).toStringAsFixed(1)} d' : '—'),
                ],
              ),
              const Spacer(),
              const Divider(color: FincoreColors.border, height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _showDetails(p),
                    child: const Text('Painel'),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _openEditor(p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: FincoreColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListCatalog() {
    if (_filteredProdutos.isEmpty) {
      return const Center(child: Text('Nenhum produto cadastrado.', style: TextStyle(color: FincoreColors.textMuted)));
    }

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: ListView.separated(
        itemCount: _filteredProdutos.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
        itemBuilder: (context, idx) {
          final p = _filteredProdutos[idx];
          final cat = _categorias.firstWhere((c) => c.id == p.categoriaId,
              orElse: () => Categoria(id: '', tenantId: '', nome: 'Geral', descricao: '', ordemExibicao: 0, ativo: true, metadata: SyncMetadata(version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: '', updatedBy: '')));

          final estInfo = _estoqueMap[p.id] ?? const _EstoqueInfo(disponivel: 0.0, reservado: 0.0);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: FincoreColors.primary.withOpacity(0.08),
              child: const Text('🍔', style: TextStyle(fontSize: 16)),
            ),
            title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${cat.nome} • Estoque: ${p.controlaEstoque ? estInfo.disponivel.toStringAsFixed(0) : 'Sem Controle'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _showDetails(p),
                  child: const Text('Painel'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _openEditor(p),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSideSheet() {
    final p = _detailsProduto!;
    final isPrecoLoading = _detailsPrecoInfo['loading'] ?? false;
    final valorPreco = _detailsPrecoInfo['valor'] ?? 'R\$ 0,00';
    final tipoPreco = _detailsPrecoInfo['tipo'] ?? 'Preço Fixo';
    final estInfo = _estoqueMap[p.id] ?? const _EstoqueInfo(disponivel: 0.0, reservado: 0.0);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Painel do Produto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                onPressed: () => setState(() => _detailsProduto = null),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: FincoreColors.background,
                  child: Text('🍔', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(p.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(p.statusComercial.name.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 28, color: FincoreColors.border),
          const Text('Preços e Políticas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textSecondary)),
          const SizedBox(height: 10),
          isPrecoLoading
              ? const CircularProgressIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(valorPreco, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                    Text(tipoPreco, style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
                  ],
                ),
          const Divider(height: 28, color: FincoreColors.border),
          const Text('Parâmetros Operacionais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textSecondary)),
          const SizedBox(height: 10),
          _DetailsRow(label: 'Controla Estoque?', value: p.controlaEstoque ? 'Sim' : 'Não'),
          if (p.controlaEstoque) ...[
            _DetailsRow(label: 'Estoque Físico:', value: estInfo.disponivel.toStringAsFixed(0)),
            _DetailsRow(label: 'Estoque Reservado:', value: estInfo.reservado.toStringAsFixed(0)),
          ],
          _DetailsRow(label: 'Tempo de Preparo:', value: '${p.tempoMedioMinutos} min'),
          _DetailsRow(label: 'Unidade de Venda:', value: p.unidadeVenda.name.toUpperCase()),
          const Divider(height: 28, color: FincoreColors.border),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _openEditor(p),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Editar Produto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.background,
              foregroundColor: FincoreColors.textPrimary,
              minimumSize: const Size(double.infinity, 40),
              side: const BorderSide(color: FincoreColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstoqueInfo {
  final double disponivel;
  final double reservado;
  const _EstoqueInfo({required this.disponivel, required this.reservado});
}

class _KPIBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _KPIBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.9)),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary : FincoreColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : FincoreColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StockIndicator extends StatelessWidget {
  final String label;
  final String value;

  const _StockIndicator({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
        ),
      ],
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
        ],
      ),
    );
  }
}
