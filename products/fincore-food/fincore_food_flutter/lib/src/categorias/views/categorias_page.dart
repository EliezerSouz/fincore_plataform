import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/audit_timeline_panel.dart';
import 'package:fincore_food_flutter/src/shared/presentation/validators/fincore_validators.dart';
import 'package:fincore_food_flutter/src/shared/services/commercial_pricing_engine.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:uuid/uuid.dart';

/// Tela de Cadastro e Gestão de Categorias — Split View 40/60 Limpo
class CategoriasPage extends StatefulWidget {
  final VoidCallback? onChanged;
  final void Function(Categoria cat)? onAddProduto;
  const CategoriasPage({super.key, this.onChanged, this.onAddProduto});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> with SingleTickerProviderStateMixin {
  late final CategoriaRepository _repo;
  late final TabelaPrecificacaoRepository _tabelaRepo;
  late final CategoriaTabelaPrecificacaoRepository _catAssocRepo;
  late final ProdutoRepository _produtoRepo;

  List<Categoria> _categorias = [];
  List<TabelaPrecificacao> _politicas = [];
  Map<String, int> _prodCountsMap = {};
  Categoria? _selectedCategoria;
  bool _isInspectorOpen = false;
  bool _isEditing = false;
  String? _selectedPoliticaId;
  bool _isLoading = true;
  bool _isSaving = false;

  late final TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController();
  final _tempoMedioCtrl = TextEditingController(text: '30');
  final _estoqueMinCtrl = TextEditingController(text: '100');
  final _estoqueMaxCtrl = TextEditingController(text: '1000');
  final _estoqueSegurancaCtrl = TextEditingController(text: '0');
  final _estoqueCriticoCtrl = TextEditingController(text: '50');
  final _loteProducaoCtrl = TextEditingController(text: '100');
  final _diasCoberturaCtrl = TextEditingController(text: '3');
  final _capacidadeCampanhaCtrl = TextEditingController(text: '0');
  final _tempoPreparacaoCtrl = TextEditingController(text: '0');
  String _estrategiaProducaoPadrao = 'concentrada';
  final _ncmPadraoCtrl = TextEditingController(text: '1902.20.00');
  final _cestPadraoCtrl = TextEditingController(text: '17.049.00');
  final _precoPadraoCtrl = TextEditingController(text: '1.50');

  bool _ativo = true;
  String _icone = 'fastfood';
  String _corHex = '#FF6B00';

  // Defaults Herdáveis para Produtos
  String _setorImpressaoPadrao = 'Cozinha';
  ModoProducao _modoProducaoPadrao = ModoProducao.sobDemanda;
  bool _enviarKdsPadrao = true;
  bool _controlaEstoquePadrao = true;
  TipoItemEstoque _tipoEstoquePadrao = TipoItemEstoque.produtoAcabado;
  bool _loteFifoPadrao = true;

  EstrategiaComercializacao _estrategiaComercialPadrao = EstrategiaComercializacao.porQuantidade;

  // Canais Padrão
  bool _canalPdvPadrao = true;
  bool _canalDeliveryPadrao = true;
  bool _canalAutoatendimentoPadrao = false;
  bool _canaliFoodPadrao = true;
  bool _canalWhatsAppPadrao = true;

  final Map<String, IconData> _iconesMap = const {
    'fastfood': Icons.fastfood_outlined,
    'local_pizza': Icons.local_pizza_outlined,
    'lunch_dining': Icons.lunch_dining_outlined,
    'local_bar': Icons.local_bar_outlined,
    'icecream': Icons.icecream_outlined,
    'bakery_dining': Icons.bakery_dining_outlined,
    'restaurant': Icons.restaurant_outlined,
    'coffee': Icons.coffee_outlined,
    'set_meal': Icons.set_meal_outlined,
  };

  final List<String> _coresDisponiveis = [
    '#FF6B00', // Laranja Fincore
    '#2E7D32', // Verde Sucesso
    '#1565C0', // Azul
    '#6A1B9A', // Roxo
    '#C62828', // Vermelho
    '#F57F17', // Dourado
    '#00838F', // Ciano
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _repo = DependencyInjection().get<CategoriaRepository>();
    _tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>();
    _catAssocRepo = DependencyInjection().get<CategoriaTabelaPrecificacaoRepository>();
    _produtoRepo = DependencyInjection().get<ProdutoRepository>();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _ordemCtrl.dispose();
    _tempoMedioCtrl.dispose();
    _estoqueMinCtrl.dispose();
    _estoqueMaxCtrl.dispose();
    _estoqueSegurancaCtrl.dispose();
    _estoqueCriticoCtrl.dispose();
    _loteProducaoCtrl.dispose();
    _diasCoberturaCtrl.dispose();
    _capacidadeCampanhaCtrl.dispose();
    _tempoPreparacaoCtrl.dispose();
    _ncmPadraoCtrl.dispose();
    _cestPadraoCtrl.dispose();
    _precoPadraoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    try {
      final list = await _repo.findAll();
      final pols = await _tabelaRepo.findAll();
      final prods = await _produtoRepo.findAll();

      final Map<String, int> counts = {};
      for (final p in prods) {
        if (p.categoriaId != null) {
          counts[p.categoriaId!] = (counts[p.categoriaId!] ?? 0) + 1;
        }
      }

      setState(() {
        _categorias = list;
        _politicas = pols;
        _prodCountsMap = counts;
      });
      if (_selectedCategoria != null) {
        final idx = list.indexWhere((c) => c.id == _selectedCategoria!.id);
        await _selectCategoria(idx != -1 ? list[idx] : null, abrirPainel: _isInspectorOpen);
      } else if (_categorias.isNotEmpty) {
        await _selectCategoria(_categorias.first, abrirPainel: false);
      } else {
        await _selectCategoria(null, abrirPainel: false);
      }
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCategoria(Categoria? categoria, {bool abrirPainel = false, bool isEditing = false}) async {
    String? politicaId;
    if (categoria != null) {
      try {
        final catAssocs = await _catAssocRepo.findByCategoriaId(categoria.id);
        final activeAssoc = catAssocs.firstWhere((a) => a.ativo, orElse: () => throw Exception());
        politicaId = activeAssoc.tabelaPrecificacaoId;
      } catch (_) {}
    }

    setState(() {
      _selectedCategoria = categoria;
      _selectedPoliticaId = politicaId;
      _isLoading = false;
      if (categoria != null) {
        _isInspectorOpen = abrirPainel;
        _isEditing = isEditing;
        _nomeCtrl.text = categoria.nome;
        _descricaoCtrl.text = categoria.descricao;
        _ordemCtrl.text = categoria.ordemExibicao.toString();
        _ativo = categoria.ativo;
        _icone = categoria.icone ?? 'fastfood';
        _corHex = categoria.cor ?? '#FF6B00';

        if (categoria.metadataPayload != null && categoria.metadataPayload!.isNotEmpty) {
          try {
            final Map<String, dynamic> jsonMap = jsonDecode(categoria.metadataPayload!);
            _setorImpressaoPadrao = jsonMap['setor_impressao'] ?? 'Cozinha';
            _tempoMedioCtrl.text = (jsonMap['tempo_medio'] ?? 30).toString();
            _controlaEstoquePadrao = jsonMap['controla_estoque'] ?? true;
            _estoqueMinCtrl.text = (jsonMap['estoque_minimo'] ?? 100).toString();
            _estoqueMaxCtrl.text = (jsonMap['estoque_maximo'] ?? 1000).toString();
            _estoqueSegurancaCtrl.text = (jsonMap['estoque_seguranca'] ?? 0).toString();
            _estoqueCriticoCtrl.text = (jsonMap['estoque_critico'] ?? 50).toString();
            _loteProducaoCtrl.text = (jsonMap['lote_producao'] ?? 100).toString();
            _diasCoberturaCtrl.text = (jsonMap['dias_cobertura_alvo'] ?? 3).toString();
            _capacidadeCampanhaCtrl.text = (jsonMap['capacidade_campanha'] ?? 0).toString();
            _tempoPreparacaoCtrl.text = (jsonMap['tempo_preparacao'] ?? 0).toString();
            _estrategiaProducaoPadrao = jsonMap['estrategia_producao'] ?? 'concentrada';
            _ncmPadraoCtrl.text = jsonMap['ncm'] ?? '1902.20.00';
            _cestPadraoCtrl.text = jsonMap['cest'] ?? '17.049.00';
            // Carrega o preço base da categoria
            final precoBase = jsonMap['preco_base'];
            _precoPadraoCtrl.text = precoBase != null
                ? (precoBase as num).toDouble().toStringAsFixed(2)
                : '1.50';

            if (jsonMap['canais'] != null) {
              final canais = jsonMap['canais'] as Map<String, dynamic>;
              _canalPdvPadrao = canais['pdv'] ?? true;
              _canalDeliveryPadrao = canais['delivery'] ?? true;
              _canaliFoodPadrao = canais['ifood'] ?? true;
              _canalWhatsAppPadrao = canais['whatsapp'] ?? true;
            }
          } catch (_) {}
        } else {
          _precoPadraoCtrl.text = '1.50';
        }
      } else {
        _selectedCategoria = null;
        _isInspectorOpen = true; // Novo abre inspector sempre
        _isEditing = true;
        _nomeCtrl.clear();
        _descricaoCtrl.clear();
        _ordemCtrl.text = '0';
        _ativo = true;
        _icone = 'fastfood';
        _corHex = '#FF6B00';
        _selectedPoliticaId = null;
      }
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final nome = _nomeCtrl.text.trim();
      final isNew = _selectedCategoria == null;
      final id = isNew ? const Uuid().v4() : _selectedCategoria!.id;

      final Map<String, dynamic> payloadMap = {
        'setor_impressao': _setorImpressaoPadrao,
        'tempo_medio': int.tryParse(_tempoMedioCtrl.text) ?? 30,
        'modo_producao': _modoProducaoPadrao.name,
        'enviar_kds': _enviarKdsPadrao,
        'controla_estoque': _controlaEstoquePadrao,
        'tipo_estoque': _tipoEstoquePadrao.name,
        'estoque_minimo': int.tryParse(_estoqueMinCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 100,
        'estoque_maximo': int.tryParse(_estoqueMaxCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 1000,
        'estoque_seguranca': int.tryParse(_estoqueSegurancaCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
        'estoque_critico': int.tryParse(_estoqueCriticoCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 50,
        'lote_producao': int.tryParse(_loteProducaoCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 100,
        'dias_cobertura_alvo': int.tryParse(_diasCoberturaCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 3,
        'capacidade_campanha': int.tryParse(_capacidadeCampanhaCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
        'tempo_preparacao': int.tryParse(_tempoPreparacaoCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
        'estrategia_producao': _estrategiaProducaoPadrao,
        'estrategia_comercial': _estrategiaComercialPadrao.name,
        'preco_base': double.tryParse(_precoPadraoCtrl.text.replaceAll(',', '.')) ?? 1.50,
        'ncm': _ncmPadraoCtrl.text.trim(),
        'cest': _cestPadraoCtrl.text.trim(),
        'canais': {
          'pdv': _canalPdvPadrao,
          'delivery': _canalDeliveryPadrao,
          'ifood': _canaliFoodPadrao,
          'whatsapp': _canalWhatsAppPadrao,
          'autoatendimento': _canalAutoatendimentoPadrao,
        },
      };

      final categoria = Categoria(
        id: id,
        tenantId: tenantCtx.tenantId,
        nome: nome,
        descricao: _descricaoCtrl.text.trim(),
        ordemExibicao: int.tryParse(_ordemCtrl.text) ?? 0,
        ativo: _ativo,
        icone: _icone,
        cor: _corHex,
        metadataPayload: jsonEncode(payloadMap),
        metadata: _selectedCategoria?.metadata.copyWith(
              version: (_selectedCategoria?.metadata.version ?? 0) + 1,
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

      await _repo.save(categoria);

      // --- ASSOCIAÇÃO CATEGORIA ➔ POLÍTICA COMERCIAL ---
      // Busca a associação atual para verificar se realmente mudou
      final existingAssocs = await _catAssocRepo.findByCategoriaId(id);
      final activeAssoc = existingAssocs.cast<CategoriaTabelaPrecificacao?>().firstWhere(
        (a) => a?.ativo == true,
        orElse: () => null,
      );
      final currentPoliticaId = activeAssoc?.tabelaPrecificacaoId;

      // Só modifica a associação se a política realmente mudou
      if (currentPoliticaId != _selectedPoliticaId) {
        // 1. Remover associações antigas
        for (final assoc in existingAssocs) {
          await _catAssocRepo.delete(assoc.id);
        }

        // 2. Criar nova associação se uma política foi selecionada
        if (_selectedPoliticaId != null) {
          final newAssoc = CategoriaTabelaPrecificacao(
            id: const Uuid().v4(),
            tenantId: tenantCtx.tenantId,
            categoriaId: id,
            tabelaPrecificacaoId: _selectedPoliticaId!,
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
          );
          await _catAssocRepo.save(newAssoc);
        }
      }

      // Propaga alterações de parâmetros para todos os produtos ativos desta categoria
      final prodsNaCategoria = (await _produtoRepo.findAll())
          .where((p) => p.categoriaId == id && p.controlaEstoque)
          .toList();
      final estoqueCtrl = DependencyInjection().get<EstoqueController>();
      for (final prod in prodsNaCategoria) {
        await estoqueCtrl.aplicarParametrosProduto(prod.id);
      }

      await _carregarCategorias();
      widget.onChanged?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew ? 'Categoria salva com sucesso!' : 'Categoria atualizada!'),
          backgroundColor: FincoreColors.success,
        ),
      );
    } catch (e, stack) {
      debugPrint('Erro ao salvar categoria: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar categoria: $e'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _searchQuery = '';

  List<Categoria> get _filteredCategorias {
    if (_searchQuery.isEmpty) return _categorias;
    final q = _searchQuery.toLowerCase();
    return _categorias.where((c) => c.nome.toLowerCase().contains(q) || c.descricao.toLowerCase().contains(q)).toList();
  }

  Widget _buildMetricBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
    );
  }

  Widget _buildCategoryCard(Categoria cat) {
    final iconData = _iconesMap[cat.icone ?? 'fastfood'] ?? Icons.fastfood_outlined;
    final colorVal = Color(int.parse((cat.cor ?? '#FF6B00').replaceFirst('#', '0xFF')));
    final prodCount = _prodCountsMap[cat.id] ?? 0;
    final isSelected = _selectedCategoria?.id == cat.id && _isInspectorOpen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? FincoreColors.primary : FincoreColors.border,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Ícone + Badge de Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorVal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: colorVal, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cat.ativo ? FincoreColors.success.withValues(alpha: 0.15) : FincoreColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cat.ativo ? '● ATIVA' : '● INATIVA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: cat.ativo ? FincoreColors.success : FincoreColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nome da Categoria
          Text(
            cat.nome,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Descrição Comercial posicionada logo após o nome
          if (cat.descricao.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              cat.descricao,
              style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),

          // Container de Métricas (4 Colunas)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _buildCardMetricCol('Produtos', '$prodCount', FincoreColors.textPrimary)),
                Expanded(child: _buildCardMetricCol('Setor', 'Cozinha', FincoreColors.textSecondary)),
                Expanded(child: _buildCardMetricCol('Produção', 'Demanda', FincoreColors.textSecondary)),
                Expanded(child: _buildCardMetricCol('KDS', 'Ativo', FincoreColors.success)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Ações do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  _selectCategoria(cat, abrirPainel: true);
                },
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 13, color: FincoreColors.textSecondary),
                    SizedBox(width: 2),
                    Text('Painel', style: TextStyle(fontSize: 10.5, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _selectCategoria(cat, abrirPainel: false, isEditing: true);
                },
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, size: 13, color: FincoreColors.textSecondary),
                    SizedBox(width: 2),
                    Text('Editar', style: TextStyle(fontSize: 10.5, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  if (widget.onAddProduto != null) {
                    widget.onAddProduto!(cat);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Para cadastrar produtos em "${cat.nome}", acesse a aba Catálogo de Produtos.'),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 13, color: FincoreColors.primary),
                    const SizedBox(width: 2),
                    Text('Novo Prod', style: TextStyle(fontSize: 10.5, color: FincoreColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetricCol(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: FincoreColors.textMuted)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    final total = _categorias.length;
    final ativas = _categorias.where((c) => c.ativo).length;
    final inspectorTitle = _selectedCategoria == null ? 'Nova Categoria' : _selectedCategoria!.nome;

    return Stack(
      children: [
        // ── Grid Principal de Cards (Full Width) ───────────────────────────
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pílulas de Estatísticas no Topo
              Row(
                children: [
                  _buildMetricBadge('Categorias: $total', FincoreColors.primary.withValues(alpha: 0.15), FincoreColors.primary),
                  const SizedBox(width: 8),
                  _buildMetricBadge('Ativas: $ativas', FincoreColors.success.withValues(alpha: 0.15), FincoreColors.success),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Linha de Pesquisa + Botão "+ Nova Categoria"
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: FincoreColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 18, color: FincoreColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Pesquisar categoria...',
                                hintStyle: TextStyle(fontSize: 13, color: FincoreColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _selectCategoria(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.category_outlined, size: 16, color: Colors.white),
                    label: const Text('Nova Categoria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Grid de Cards
              Expanded(
                child: _filteredCategorias.isEmpty
                    ? const Center(child: Text('Nenhuma categoria encontrada.', style: TextStyle(color: FincoreColors.textMuted)))
                    : LayoutBuilder(
                        builder: (ctx, constraints) {
                          int cols = 4;
                          if (constraints.maxWidth < 700) {
                            cols = 1;
                          } else if (constraints.maxWidth < 1000) {
                            cols = 2;
                          } else if (constraints.maxWidth < 1300) {
                            cols = 3;
                          }

                          return GridView.builder(
                            itemCount: _filteredCategorias.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisExtent: 240,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (ctx, idx) {
                              final cat = _filteredCategorias[idx];
                              return _buildCategoryCard(cat);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // ── Drawer Lateral de Inspector (quando aberto e não editando) ─────
        if (_isInspectorOpen && !_isEditing && _selectedCategoria != null) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isInspectorOpen = false),
              child: Container(color: Colors.black38),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 520,
            child: Container(
              decoration: const BoxDecoration(
                color: FincoreColors.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(-4, 0)),
                ],
              ),
              child: FincoreInspectorPanel(
                isOpen: true,
                isEditing: false,
                title: inspectorTitle,
                subtitle: 'Template de Configurações',
                onEdit: () => setState(() => _isEditing = true),
                onClose: () {
                  setState(() {
                    _isInspectorOpen = false;
                    _selectedCategoria = null;
                  });
                },
                child: _buildRightEditor(),
              ),
            ),
          ),
        ],

        // ── Modal Dialog de Edição Centralizado (quando editando/criando) ───
        if (_isEditing) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                if (_selectedCategoria == null) {
                  _isEditing = false;
                  _isInspectorOpen = false;
                } else {
                  _isEditing = false;
                }
              }),
              child: Container(color: Colors.black54),
            ),
          ),
          Center(
            child: Container(
              width: 620,
              height: MediaQuery.of(context).size.height * 0.85,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FincoreColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FincoreInspectorPanel(
                  isOpen: true,
                  isEditing: true,
                  title: _selectedCategoria == null ? 'Nova Categoria' : inspectorTitle,
                  subtitle: null,
                  onClose: () {
                    setState(() {
                      if (_selectedCategoria == null) {
                        _isEditing = false;
                        _isInspectorOpen = false;
                      } else {
                        _isEditing = false;
                      }
                    });
                  },
                  child: _buildRightEditor(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInspectorSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: FincoreColors.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInspectorDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightEditor() {
    final isNew = _selectedCategoria == null;

    if (!_isEditing) {
      // MODO INSPECTOR
      final prodCount = _selectedCategoria != null ? (_prodCountsMap[_selectedCategoria!.id] ?? 0) : 0;
      final printSector = _setorImpressaoPadrao;
      final tempo = _tempoMedioCtrl.text;
      final ncm = _ncmPadraoCtrl.text;
      final cest = _cestPadraoCtrl.text;
      final preco = _precoPadraoCtrl.text;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalhes Gerais
            _buildInspectorSectionTitle('Dados Gerais & Visual'),
            _buildInspectorDetailRow('Nome', _selectedCategoria?.nome ?? '--'),
            _buildInspectorDetailRow('Descrição', _selectedCategoria?.descricao == null || _selectedCategoria!.descricao.isEmpty ? 'Sem descrição.' : _selectedCategoria!.descricao),
            _buildInspectorDetailRow('Ordem de Exibição', _selectedCategoria?.ordemExibicao.toString() ?? '0'),
            _buildInspectorDetailRow('Produtos Vinculados', '$prodCount produtos ativos'),

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Produção (Padrão)
            _buildInspectorSectionTitle('Produção (Padrão)'),
            _buildInspectorDetailRow('Setor de Rota KDS', printSector),
            _buildInspectorDetailRow('Tempo Médio', '$tempo min'),

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Estoque (Padrão)
            _buildInspectorSectionTitle('Estoque (Padrão)'),
            _buildInspectorDetailRow('Controla Estoque', _controlaEstoquePadrao ? 'Sim' : 'Não'),
            if (_controlaEstoquePadrao) ...[
              _buildInspectorDetailRow('Estoque Segurança', _estoqueSegurancaCtrl.text),
              _buildInspectorDetailRow('Estoque Crítico', _estoqueCriticoCtrl.text),
              _buildInspectorDetailRow('Estoque Mínimo', _estoqueMinCtrl.text),
              _buildInspectorDetailRow('Estoque Máximo', _estoqueMaxCtrl.text),
              _buildInspectorDetailRow('Lote de Produção', _loteProducaoCtrl.text),
              _buildInspectorDetailRow('Dias Cobertura Alvo', '${_diasCoberturaCtrl.text} dias'),
              _buildInspectorDetailRow('Capac. Campanha', _capacidadeCampanhaCtrl.text),
            ],

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Comercial (Padrão)
            _buildInspectorSectionTitle('Comercial (Padrão)'),
            _buildInspectorDetailRow('Preço de Venda Base', 'R\$ $preco'),

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Delivery (Padrão)
            _buildInspectorSectionTitle('Delivery (Padrão)'),
            _buildInspectorDetailRow('Canais Habilitados', [
              if (_canalPdvPadrao) 'PDV',
              if (_canalDeliveryPadrao) 'Delivery App',
              if (_canaliFoodPadrao) 'iFood',
              if (_canalWhatsAppPadrao) 'WhatsApp',
            ].join(', ')),

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Fiscal (Padrão)
            _buildInspectorSectionTitle('Fiscal (Padrão)'),
            _buildInspectorDetailRow('NCM', ncm),
            _buildInspectorDetailRow('CEST', cest),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                label: const Text('Editar Categoria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // MODO EDITOR
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ══════════════════════════════════════════════════════
                  // CARD 1 — IDENTIFICAÇÃO & VISUAL
                  // ══════════════════════════════════════════════════════
                  _buildFormCard(
                    label: 'Identificação & Visual',
                    icon: Icons.label_outline,
                    children: [
                      const FincoreFieldLabel(label: 'NOME DA CATEGORIA', isRequired: true),
                      FincoreTextField(
                        controller: _nomeCtrl,
                        hintText: 'Ex: Mini Salgados Tradicionais',
                        validator: FincoreValidators.compose([
                          FincoreValidators.required,
                          FincoreValidators.minLength(2),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      const FincoreFieldLabel(label: 'DESCRIÇÃO DA CATEGORIA'),
                      FincoreTextField(
                        controller: _descricaoCtrl,
                        hintText: 'Definição das regras de negócio herdadas para os salgados desta categoria',
                      ),
                      const SizedBox(height: 12),

                      const FincoreFieldLabel(label: 'ÍCONE DA CATEGORIA NO CARDÁPIO'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _iconesMap.entries.map((entry) {
                          final isSel = _icone == entry.key;
                          return InkWell(
                            onTap: () => setState(() => _icone = entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel ? FincoreColors.primary.withValues(alpha: 0.15) : FincoreColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? FincoreColors.primary : FincoreColors.border),
                              ),
                              child: Icon(entry.value, size: 20, color: isSel ? FincoreColors.primary : FincoreColors.textMuted),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      const FincoreFieldLabel(label: 'COR DA ETIQUETA VISUAL NO PDV'),
                      const SizedBox(height: 6),
                      Row(
                        children: _coresDisponiveis.map((cHex) {
                          final isSel = _corHex == cHex;
                          final colorVal = Color(int.parse(cHex.replaceFirst('#', '0xFF')));
                          return InkWell(
                            onTap: () => setState(() => _corHex = cHex),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorVal,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 3),
                                boxShadow: isSel ? [BoxShadow(color: colorVal.withValues(alpha: 0.5), blurRadius: 6)] : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'ORDEM DE EXIBIÇÃO NO PDV'),
                                FincoreTextField(
                                  controller: _ordemCtrl,
                                  hintText: '0',
                                  keyboardType: TextInputType.number,
                                  validator: FincoreValidators.integer,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'STATUS DA CATEGORIA'),
                                Row(
                                  children: [
                                    Switch(value: _ativo, activeColor: FincoreColors.primary, onChanged: (v) => setState(() => _ativo = v)),
                                    const SizedBox(width: 6),
                                    Text(_ativo ? 'ATIVA' : 'INATIVA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ativo ? FincoreColors.success : FincoreColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ══════════════════════════════════════════════════════
                  // CARD 2 — PADRÕES DE ESTOQUE (HERDÁVEIS)
                  // ══════════════════════════════════════════════════════
                  _buildFormCard(
                    label: 'Padrões de Estoque (Herdáveis)',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      Row(
                        children: [
                          Switch(value: _controlaEstoquePadrao, activeColor: FincoreColors.primary, onChanged: (v) => setState(() => _controlaEstoquePadrao = v)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Controlar Estoque Físico por Padrão para os Produtos', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const FincoreFieldLabel(label: 'TIPO DE ITEM DE ESTOQUE PADRÃO'),
                      DropdownButtonFormField<TipoItemEstoque>(
                        isExpanded: true,
                        value: _tipoEstoquePadrao,
                        dropdownColor: FincoreColors.surface,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: TipoItemEstoque.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _tipoEstoquePadrao = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'ESTOQUE SEGURANÇA PADRÃO'),
                                FincoreTextField(controller: _estoqueSegurancaCtrl, hintText: '0'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'NÍVEL CRÍTICO PADRÃO'),
                                FincoreTextField(controller: _estoqueCriticoCtrl, hintText: '50'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'ESTOQUE MÍNIMO PADRÃO'),
                                FincoreTextField(controller: _estoqueMinCtrl, hintText: '100'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'CAPACIDADE MÁXIMA PADRÃO'),
                                FincoreTextField(controller: _estoqueMaxCtrl, hintText: '1000'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ══════════════════════════════════════════════════════
                  // CARD 3 — PADRÕES DE PRODUÇÃO (HERDÁVEIS)
                  // ══════════════════════════════════════════════════════
                  _buildFormCard(
                    label: 'Padrões de Produção (Herdáveis)',
                    icon: Icons.restaurant_outlined,
                    children: [
                      const FincoreFieldLabel(label: 'SETOR DE IMPRESSÃO / KDS PADRÃO'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _setorImpressaoPadrao,
                        dropdownColor: FincoreColors.surface,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'Cozinha', child: Text('Cozinha / Salgados', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Balcao', child: Text('Balcão de Atendimento', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Producao', child: Text('Linha de Frituras', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Expedicao', child: Text('Expedição / Embalagens', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => _setorImpressaoPadrao = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'TEMPO MÉDIO DE PREPARO (MIN)'),
                                FincoreTextField(controller: _tempoMedioCtrl, hintText: '30 min', keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'MODO DE PRODUÇÃO PADRÃO'),
                                DropdownButtonFormField<ModoProducao>(
                                  isExpanded: true,
                                  value: _modoProducaoPadrao,
                                  dropdownColor: FincoreColors.surface,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                  items: ModoProducao.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) => setState(() => _modoProducaoPadrao = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'TAMANHO LOTE PADRÃO (UN)'),
                                FincoreTextField(controller: _loteProducaoCtrl, hintText: '100', keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'DIAS COBERTURA ALVO'),
                                FincoreTextField(controller: _diasCoberturaCtrl, hintText: '3', keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'CAPACIDADE CAMPANHA PADRÃO'),
                                FincoreTextField(controller: _capacidadeCampanhaCtrl, hintText: '0', keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FincoreFieldLabel(label: 'TEMPO PREPARAÇÃO (MIN)'),
                                FincoreTextField(controller: _tempoPreparacaoCtrl, hintText: '0 min', keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const FincoreFieldLabel(label: 'ESTRATÉGIA DE PRODUÇÃO PADRÃO'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _estrategiaProducaoPadrao,
                        dropdownColor: FincoreColors.surface,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'concentrada', child: Text('Concentrada (uma campanha por vez)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'mista', child: Text('Mista (múltiplos produtos)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'flexivel', child: Text('Flexível (planejamento dinâmico)', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) => setState(() => _estrategiaProducaoPadrao = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Switch(value: _enviarKdsPadrao, activeColor: FincoreColors.primary, onChanged: (v) => setState(() => _enviarKdsPadrao = v)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Enviar Automaticamente para Monitor KDS da Cozinha', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ══════════════════════════════════════════════════════
                  // CARD 4 — CONFIGURAÇÕES AVANÇADAS (TABBAR)
                  // ══════════════════════════════════════════════════════
                  _buildFormCard(
                    label: 'Configurações Avançadas',
                    icon: Icons.settings_outlined,
                    children: [
                      DefaultTabController(
                        length: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TabBar(
                              tabs: const [
                                Tab(text: 'Comercial'),
                                Tab(text: 'Fiscal'),
                                Tab(text: 'Canais'),
                              ],
                              labelColor: FincoreColors.primary,
                              unselectedLabelColor: FincoreColors.textMuted,
                              indicatorColor: FincoreColors.primary,
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 240,
                              child: TabBarView(
                                children: [
                                  // Comercial
                                  ListView(
                                    shrinkWrap: true,
                                    children: [
                                      const FincoreFieldLabel(label: 'ESTRATÉGIA COMERCIAL PADRÃO'),
                                      DropdownButtonFormField<EstrategiaComercializacao>(
                                        isExpanded: true,
                                        value: _estrategiaComercialPadrao,
                                        dropdownColor: FincoreColors.surface,
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                        items: EstrategiaComercializacao.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                        onChanged: (v) => setState(() => _estrategiaComercialPadrao = v!),
                                      ),
                                      const SizedBox(height: 12),
                                      const FincoreFieldLabel(label: 'PREÇO UNITÁRIO BASE PADRÃO (R\$)'),
                                      FincoreTextField(controller: _precoPadraoCtrl, hintText: '1.50', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                                      const SizedBox(height: 12),
                                      const FincoreFieldLabel(label: 'VINCULAR POLÍTICA COMERCIAL'),
                                      DropdownButtonFormField<String?>(
                                        isExpanded: true,
                                        value: (_selectedPoliticaId != null && _politicas.any((p) => p.id == _selectedPoliticaId)) ? _selectedPoliticaId : null,
                                        dropdownColor: FincoreColors.surface,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          hintText: 'Nenhuma Política Comercial',
                                        ),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Nenhuma (Usar Preço Fixo)', style: TextStyle(fontSize: 13, color: FincoreColors.textMuted)),
                                          ),
                                          ..._politicas.map((p) => DropdownMenuItem<String?>(
                                                value: p.id,
                                                child: Text('${p.nome} (Prioridade: ${p.prioridade})', style: const TextStyle(fontSize: 13)),
                                              )),
                                        ],
                                        onChanged: (v) => setState(() => _selectedPoliticaId = v),
                                      ),
                                    ],
                                  ),
                                  // Fiscal
                                  ListView(
                                    shrinkWrap: true,
                                    children: [
                                      const FincoreFieldLabel(label: 'CÓDIGO NCM PADRÃO'),
                                      FincoreTextField(controller: _ncmPadraoCtrl, hintText: '1902.20.00'),
                                      const SizedBox(height: 12),
                                      const FincoreFieldLabel(label: 'CÓDIGO CEST PADRÃO'),
                                      FincoreTextField(controller: _cestPadraoCtrl, hintText: '17.049.00'),
                                    ],
                                  ),
                                  // Canais
                                  ListView(
                                    shrinkWrap: true,
                                    children: [
                                      _buildChannelSwitch('Disponível no PDV / Balcão', _canalPdvPadrao, (v) => setState(() => _canalPdvPadrao = v)),
                                      const Divider(height: 12, color: FincoreColors.border),
                                      _buildChannelSwitch('Disponível no App Delivery Próprio', _canalDeliveryPadrao, (v) => setState(() => _canalDeliveryPadrao = v)),
                                      const Divider(height: 12, color: FincoreColors.border),
                                      _buildChannelSwitch('Disponível no iFood Marketplace', _canaliFoodPadrao, (v) => setState(() => _canaliFoodPadrao = v)),
                                      const Divider(height: 12, color: FincoreColors.border),
                                      _buildChannelSwitch('Disponível no WhatsApp Bot', _canalWhatsAppPadrao, (v) => setState(() => _canalWhatsAppPadrao = v)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: FincoreColors.surface,
            border: Border(top: BorderSide(color: FincoreColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      if (isNew) {
                        _isInspectorOpen = false;
                        _isEditing = false;
                      } else {
                        _selectCategoria(_selectedCategoria);
                        _isEditing = false;
                      }
                    });
                  },
                  child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    await _salvar();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                  child: const Text('Salvar Categoria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSwitch(String label, bool val, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
        Switch(value: val, activeColor: FincoreColors.primary, onChanged: onChanged),
      ],
    );
  }

  Widget _buildFormCard({
    required String label,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: FincoreColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: FincoreColors.primary),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(height: 16, color: FincoreColors.border),
          ...children,
        ],
      ),
    );
  }
}
