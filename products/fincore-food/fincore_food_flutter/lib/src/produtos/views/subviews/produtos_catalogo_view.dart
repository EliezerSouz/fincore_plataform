import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/lote_insumo_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_pricing/pricing_engine.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/presentation/validators/fincore_validators.dart';
import 'package:fincore_food_flutter/src/shared/services/commercial_pricing_engine.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/planejamento_controller.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/database/fincore_database.dart';
import 'package:uuid/uuid.dart';

class _EstoqueSnapshot {
  final int fisico;
  final int reservado;
  final int disponivel;
  final int produzir;
  final double consumoDiario;
  final double coberturaDias;
  final DateTime? ultimaEntrada;
  final DateTime? ultimaSaida;
  final int minimoEstoque;
  final int lote;
  final List<({String numero, int qtd, String status})> pedidosReservando;

  const _EstoqueSnapshot({
    required this.fisico,
    required this.reservado,
    required this.disponivel,
    required this.produzir,
    required this.consumoDiario,
    required this.coberturaDias,
    this.ultimaEntrada,
    this.ultimaSaida,
    required this.minimoEstoque,
    required this.lote,
    this.pedidosReservando = const [],
  });

  const _EstoqueSnapshot.vazio()
      : fisico = 0,
        reservado = 0,
        disponivel = 0,
        produzir = 0,
        consumoDiario = 0.0,
        coberturaDias = 0.0,
        ultimaEntrada = null,
        ultimaSaida = null,
        minimoEstoque = 0,
        lote = 0,
        pedidosReservando = const [];
}

class _FormFieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final bool isOptional;

  const _FormFieldLabel({
    required this.label,
    this.isRequired = false,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: FincoreColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 3),
            const Text(' *', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
          if (isOptional) ...[
            const SizedBox(width: 4),
            const Text('(opcional)', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
          ],
        ],
      ),
    );
  }
}



/// Catálogo de Produtos FINCORE FOOD ERP — Formulário Operacional Limpo (6 Abas) & Resumo Executivo Herdado
class ProdutosCatalogoView extends StatefulWidget {
  final VoidCallback? onChanged;
  const ProdutosCatalogoView({super.key, this.onChanged});

  @override
  State<ProdutosCatalogoView> createState() => _ProdutosCatalogoViewState();
}

class _ProdutosCatalogoViewState extends State<ProdutosCatalogoView> with SingleTickerProviderStateMixin {
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

  Map<String, double> _precosProdutosMap = {};
  Map<String, EstoqueProdutoData> _estoqueMap = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Filtros
  String _searchQuery = '';
  String? _selectedFilterCategoriaId;

  // Seleção e Form
  Produto? _selectedProduto;
  bool _isInspectorOpen = false;
  bool _isEditing = false;
  late final TabController _tabController;

  final _produtoFormKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _codigoInternoCtrl = TextEditingController();
  final _codigoBarrasCtrl = TextEditingController();
  final _imagemUrlCtrl = TextEditingController();
  final _tempoCtrl = TextEditingController();
  final _precoBaseCtrl = TextEditingController();
  final _estoqueMinCtrl = TextEditingController();
  final _estoqueMaxCtrl = TextEditingController();
  final _estoqueSegurancaCtrl = TextEditingController();
  final _estoqueCriticoCtrl = TextEditingController();
  final _loteProducaoCtrl = TextEditingController();
  final _diasCoberturaCtrl = TextEditingController();
  final _capacidadeCampanhaCtrl = TextEditingController();
  final _tempoPreparacaoCtrl = TextEditingController();
  String _estrategiaProducao = 'concentrada';
  final _ncmCtrl = TextEditingController();
  final _cestCtrl = TextEditingController();

  String? _selectedCategoriaId;
  String? _selectedPoliticaId;
  EstrategiaComercializacao _estrategia = EstrategiaComercializacao.porQuantidade;
  TipoItemEstoque _tipoEstoque = TipoItemEstoque.produtoAcabado;
  ModoProducao _modoProducao = ModoProducao.sobDemanda;
  UnidadeVenda _unidade = UnidadeVenda.un;
  ProductStatus _status = ProductStatus.disponivel;

  // Herança por seção (separado da flag global legada)
  bool _herdarCategoria = true;  // mantido para compatibilidade com card antigo
  bool _herdarEstoque = true;    // Card 2 — Estoque herda da categoria
  bool _herdarProducao = true;   // Card 3 — Produção/SLA herda da categoria
  bool _herdarComercial = true;  // Abas Avançadas — Comercial/Fiscal/Canais herdam
  bool _ativo = true;
  bool _controlaEstoque = true;
  bool _disponivelProducao = true;

  // Canais
  bool _canalPdv = true;
  bool _canalDeliveryApp = true;
  bool _canalAutoatendimento = false;
  bool _canaliFood = true;
  bool _canalWhatsApp = true;
  bool _destaqueApp = false;
  String _setorImpressao = 'Cozinha';



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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
    _tabController.dispose();
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _skuCtrl.dispose();
    _codigoInternoCtrl.dispose();
    _codigoBarrasCtrl.dispose();
    _imagemUrlCtrl.dispose();
    _tempoCtrl.dispose();
    _precoBaseCtrl.dispose();
    _estoqueMinCtrl.dispose();
    _estoqueMaxCtrl.dispose();
    _estoqueSegurancaCtrl.dispose();
    _estoqueCriticoCtrl.dispose();
    _loteProducaoCtrl.dispose();
    _diasCoberturaCtrl.dispose();
    _capacidadeCampanhaCtrl.dispose();
    _tempoPreparacaoCtrl.dispose();
    _ncmCtrl.dispose();
    _cestCtrl.dispose();
    super.dispose();
  }

  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) return false;
    final lower = url.toLowerCase().trim();
    if (lower.contains('google.com/imgres') || lower.contains('search?q=')) return false;
    return lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('data:image/');
  }

  Future<void> _loadData() async {
    try {
      final prods = await _produtoRepo.findAll();
      final cats = await _categoriaRepo.findAll();
      final tabs = await _tabelaRepo.findAll();

      final pricingEngine = DependencyInjection().get<PricingEngine>();
      final Map<String, double> precosMap = {};

      for (final p in prods) {
        // 1. Verificar a flag de herança do produto
        bool herdar = true;
        double? customPreco;
        if (p.metadataPayload != null && p.metadataPayload!.isNotEmpty) {
          try {
            final Map<String, dynamic> jsonMap = jsonDecode(p.metadataPayload!);
            herdar = jsonMap['herdar_categoria'] ?? true;
            final precoBaseVal = jsonMap['preco_base'];
            if (precoBaseVal != null) {
              customPreco = (precoBaseVal as num).toDouble();
            }
          } catch (_) {}
        }

        // 2. Determinar o preço base (herança ou customizado)
        double? basePriceDouble;
        if (herdar) {
          final cat = cats.cast<Categoria?>().firstWhere((c) => c?.id == p.categoriaId, orElse: () => null);
          if (cat != null && cat.metadataPayload != null && cat.metadataPayload!.isNotEmpty) {
            try {
              final Map<String, dynamic> jsonMap = jsonDecode(cat.metadataPayload!);
              final precoBaseVal = jsonMap['preco_base'];
              if (precoBaseVal != null) {
                basePriceDouble = (precoBaseVal as num).toDouble();
              }
            } catch (_) {}
          }
          basePriceDouble ??= customPreco;
        } else {
          basePriceDouble = customPreco;
        }

        // 3. Resolver preço em centavos
        int priceInCents = 0;
        if (basePriceDouble != null) {
          priceInCents = (basePriceDouble * 100).round();
        } else {
          // Tentar pricing engine
          try {
            priceInCents = await pricingEngine.resolvePrice(
              produtoId: p.id,
              quantidade: 1,
            );
          } catch (_) {
            priceInCents = 150; // default 1.50
          }
        }
        if (priceInCents <= 0) {
          priceInCents = 150;
        }

        precosMap[p.id] = priceInCents / 100.0;
      }

      // Carregar saldo atual do estoque para todos os produtos
      final db = DependencyInjection().get<FincoreDatabase>();
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final tenantId = tenantCtx.hasContext ? tenantCtx.tenantId : '';

      final Map<String, EstoqueProdutoData> estoqueMap = {};
      if (tenantId.isNotEmpty) {
        final estoques = await (db.select(db.estoqueProdutosTable)
              ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true)))
            .get();
        for (final est in estoques) {
          estoqueMap[est.produtoId] = est;
        }
      }

      setState(() {
        _allProdutos = prods;
        _categorias = cats;
        _precosProdutosMap = precosMap;
        _estoqueMap = estoqueMap;
        _politicasPreco = tabs.where((t) => t.tipoPolitica == PricingPolicyType.faixaQuantidade).toList();
        _applyFilters();
        // Seleciona o primeiro produto mas NÃO abre o painel lateralmente
        if (_allProdutos.isNotEmpty && _selectedProduto == null) {
          _selectedProduto = _allProdutos.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar catálogo de produtos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProdutos = _allProdutos.where((p) {
        final matchesSearch = p.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (p.codigo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesCat = _selectedFilterCategoriaId == null || p.categoriaId == _selectedFilterCategoriaId;
        return matchesSearch && matchesCat;
      }).toList();
    });
  }

  void _applyCategoryInheritanceDefaults(String? categoryId) {
    // Aplica defaults somente para seções com herança ativa
    final nenhuma = !_herdarEstoque && !_herdarProducao && !_herdarComercial;
    if (nenhuma) return;

    final cat = _categorias.cast<Categoria?>().firstWhere((c) => c?.id == categoryId, orElse: () => null);
    if (cat != null && cat.metadataPayload != null && cat.metadataPayload!.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(cat.metadataPayload!);

        if (_herdarProducao) {
          final rawSetor = jsonMap['setor_impressao'] ?? 'Cozinha';
          _setorImpressao = rawSetor == 'Balcão' ? 'Balcao' : (rawSetor == 'Copa' || rawSetor == 'Produção' ? 'Producao' : (rawSetor == 'Expedição' ? 'Expedicao' : rawSetor));
          _tempoCtrl.text = (jsonMap['tempo_medio'] ?? 30).toString();
          _loteProducaoCtrl.text = (jsonMap['lote_producao'] ?? 100).toString();
          _diasCoberturaCtrl.text = (jsonMap['dias_cobertura_alvo'] ?? 3).toString();
          _capacidadeCampanhaCtrl.text = (jsonMap['capacidade_campanha'] ?? 0).toString();
          _tempoPreparacaoCtrl.text = (jsonMap['tempo_preparacao'] ?? 0).toString();
          _estrategiaProducao = jsonMap['estrategia_producao'] ?? 'concentrada';
          if (jsonMap['modo_producao'] != null) {
            _modoProducao = ModoProducao.values.firstWhere(
              (e) => e.name == jsonMap['modo_producao'],
              orElse: () => ModoProducao.sobDemanda,
            );
          }
        }

        if (_herdarEstoque) {
          _controlaEstoque = jsonMap['controla_estoque'] ?? true;
          _estoqueMinCtrl.text = (jsonMap['estoque_minimo'] ?? 100).toString();
          _estoqueMaxCtrl.text = (jsonMap['estoque_maximo'] ?? 1000).toString();
          _estoqueSegurancaCtrl.text = (jsonMap['estoque_seguranca'] ?? 0).toString();
          _estoqueCriticoCtrl.text = (jsonMap['estoque_critico'] ?? 50).toString();
          if (jsonMap['tipo_estoque'] != null) {
            _tipoEstoque = TipoItemEstoque.values.firstWhere(
              (e) => e.name == jsonMap['tipo_estoque'],
              orElse: () => TipoItemEstoque.produtoAcabado,
            );
          }
        }

        if (_herdarComercial) {
          _ncmCtrl.text = jsonMap['ncm'] ?? '1902.20.00';
          _cestCtrl.text = jsonMap['cest'] ?? '17.049.00';
          final catPreco = jsonMap['preco_base'];
          if (catPreco != null) {
            _precoBaseCtrl.text = (catPreco as num).toDouble().toStringAsFixed(2);
          } else {
            _precoBaseCtrl.text = '1.50';
          }
          if (jsonMap['canais'] != null) {
            final canais = jsonMap['canais'] as Map<String, dynamic>;
            _canalPdv = canais['pdv'] ?? true;
            _canalDeliveryApp = canais['delivery'] ?? true;
            _canaliFood = canais['ifood'] ?? true;
            _canalWhatsApp = canais['whatsapp'] ?? true;
          }
        }
      } catch (_) {}
    } else {
      if (_herdarProducao) {
        _setorImpressao = 'Cozinha';
        _tempoCtrl.text = '30';
        _loteProducaoCtrl.text = '100';
        _diasCoberturaCtrl.text = '3';
        _capacidadeCampanhaCtrl.text = '0';
        _tempoPreparacaoCtrl.text = '0';
        _estrategiaProducao = 'concentrada';
      }
      if (_herdarEstoque) {
        _controlaEstoque = true;
        _estoqueMinCtrl.text = '100';
        _estoqueMaxCtrl.text = '1000';
        _estoqueSegurancaCtrl.text = '0';
        _estoqueCriticoCtrl.text = '50';
      }
      if (_herdarComercial) {
        _ncmCtrl.text = '1902.20.00';
        _cestCtrl.text = '17.049.00';
        _precoBaseCtrl.text = '1.50';
        _canalPdv = true;
        _canalDeliveryApp = true;
        _canaliFood = true;
        _canalWhatsApp = true;
      }
    }
  }

  void _generateAutoSku() {
    final prefix = _nomeCtrl.text.trim().isNotEmpty ? _nomeCtrl.text.trim().substring(0, 3).toUpperCase() : 'PRD';
    final randomId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    setState(() {
      _skuCtrl.text = 'SKU-$prefix-$randomId';
    });
  }

  void _selectProduto(Produto? produto, {bool abrirPainel = false}) async {
    if (produto == null) {
      setState(() {
        _selectedProduto = null;
        _isInspectorOpen = false;
        _isEditing = true;
        _nomeCtrl.clear();
        _descricaoCtrl.clear();
        _codigoInternoCtrl.clear();
        _codigoBarrasCtrl.clear();
        _imagemUrlCtrl.clear();
        _generateAutoSku();
        _precoBaseCtrl.text = '1.50';
        _selectedCategoriaId = _categorias.isNotEmpty ? _categorias.first.id : null;
        _selectedPoliticaId = _politicasPreco.isNotEmpty ? _politicasPreco.first.id : null;
        _estrategia = EstrategiaComercializacao.porQuantidade;
        _unidade = UnidadeVenda.un;
        _status = ProductStatus.disponivel;
        _herdarCategoria = true;
        _herdarEstoque = true;
        _herdarProducao = true;
        _herdarComercial = true;
        _ativo = true;
        _disponivelProducao = true;
        _destaqueApp = false;
        _applyCategoryInheritanceDefaults(_selectedCategoriaId);
      });
      return;
    }

    setState(() {
      _selectedProduto = produto;
      _isInspectorOpen = abrirPainel;
      _isEditing = false;
      _nomeCtrl.text = produto.nome;
    _descricaoCtrl.text = produto.descricao ?? '';
    _codigoInternoCtrl.text = produto.codigo ?? '';
    _skuCtrl.text = (produto.sku != null && produto.sku!.isNotEmpty)
        ? produto.sku!
        : 'SKU-${produto.nome.substring(0, 3).toUpperCase()}-${produto.id.substring(0, 4).toUpperCase()}';
    _codigoBarrasCtrl.text = (produto.codigoBarras != null && produto.codigoBarras!.isNotEmpty)
        ? produto.codigoBarras!
        : '78912345678${produto.id.hashCode.abs() % 10}';
    _imagemUrlCtrl.text = produto.imagem ?? '';
    _selectedCategoriaId = produto.categoriaId;
    _unidade = produto.unidadeVenda;
    _status = produto.statusComercial;
    _controlaEstoque = produto.controlaEstoque;
    _ativo = produto.ativo;
    double precoExibicao = _precosProdutosMap[produto.id] ?? 1.50;

    if (produto.metadataPayload != null && produto.metadataPayload!.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(produto.metadataPayload!);
        _herdarComercial = jsonMap['herdar_comercial'] ?? jsonMap['herdar_categoria'] ?? true;
        _herdarCategoria = jsonMap['herdar_categoria'] ?? _herdarComercial;
        _herdarEstoque   = jsonMap['herdar_estoque']   ?? true;
        _herdarProducao  = jsonMap['herdar_producao']  ?? true;
        final customPreco = jsonMap['preco_base'];
        if (!_herdarComercial && customPreco != null) {
          precoExibicao = (customPreco as num).toDouble();
        }
        // Se não herda estoque, carrega valores salvos
        if (!_herdarEstoque) {
          _estoqueMinCtrl.text = (jsonMap['estoque_minimo'] ?? 100).toString();
          _estoqueMaxCtrl.text = (jsonMap['estoque_maximo'] ?? 1000).toString();
          _estoqueSegurancaCtrl.text = (jsonMap['estoque_seguranca'] ?? 0).toString();
          _estoqueCriticoCtrl.text = (jsonMap['estoque_critico'] ?? 50).toString();
          if (jsonMap['tipo_estoque'] != null) {
            _tipoEstoque = TipoItemEstoque.values.firstWhere(
              (e) => e.name == jsonMap['tipo_estoque'],
              orElse: () => TipoItemEstoque.produtoAcabado,
            );
          }
        }
        // Se não herda produção, carrega valores salvos
        if (!_herdarProducao) {
          _tempoCtrl.text = (jsonMap['tempo_medio'] ?? 30).toString();
          final rawSetor = jsonMap['setor_impressao'] ?? 'Cozinha';
          _setorImpressao = rawSetor == 'Balcão' ? 'Balcao' : (rawSetor == 'Copa' || rawSetor == 'Produção' ? 'Producao' : (rawSetor == 'Expedição' ? 'Expedicao' : rawSetor));
          _loteProducaoCtrl.text = (jsonMap['lote_producao'] ?? 100).toString();
          _diasCoberturaCtrl.text = (jsonMap['dias_cobertura_alvo'] ?? 3).toString();
          _capacidadeCampanhaCtrl.text = (jsonMap['capacidade_campanha'] ?? 0).toString();
          _tempoPreparacaoCtrl.text = (jsonMap['tempo_preparacao'] ?? 0).toString();
          _estrategiaProducao = jsonMap['estrategia_producao'] ?? 'concentrada';
          if (jsonMap['modo_producao'] != null) {
            _modoProducao = ModoProducao.values.firstWhere(
              (e) => e.name == jsonMap['modo_producao'],
              orElse: () => ModoProducao.sobDemanda,
            );
          }
        }
        // Fiscal/Canais customizados
        if (!_herdarComercial) {
          _ncmCtrl.text = jsonMap['ncm'] ?? '1902.20.00';
          _cestCtrl.text = jsonMap['cest'] ?? '17.049.00';
          if (jsonMap['canais'] != null) {
            final canais = jsonMap['canais'] as Map<String, dynamic>;
            _canalPdv = canais['pdv'] ?? true;
            _canalDeliveryApp = canais['delivery'] ?? true;
            _canaliFood = canais['ifood'] ?? true;
            _canalWhatsApp = canais['whatsapp'] ?? true;
          }
        }
      } catch (_) {
        _herdarCategoria = true;
        _herdarEstoque = true;
        _herdarProducao = true;
        _herdarComercial = true;
      }
    } else {
      _herdarCategoria = true;
      _herdarEstoque = true;
      _herdarProducao = true;
      _herdarComercial = true;
    }

    _precoBaseCtrl.text = precoExibicao.toStringAsFixed(2);
    _applyCategoryInheritanceDefaults(_selectedCategoriaId);
    });

    try {
      final assocs = await _assocRepo.findByProdutoId(produto.id);
      for (final assoc in assocs) {
        if (assoc.ativo) {
          final tabela = await _tabelaRepo.findById(assoc.tabelaPrecificacaoId);
          if (tabela != null && tabela.tipoPolitica == PricingPolicyType.faixaQuantidade) {
            if (mounted) setState(() => _selectedPoliticaId = tabela.id);
            break;
          }
        }
      }
    } catch (_) {}

    setState(() {});
  }

  void _openImagePickerModal() {
    final tempUrlCtrl = TextEditingController(text: _imagemUrlCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.photo_library_outlined, color: FincoreColors.primary),
            const SizedBox(width: 10),
            const Text('Selecionar Foto do Produto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: FincoreColors.primary),
                    const SizedBox(height: 8),
                    const Text('Upload de Imagem (Supabase Storage)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Selecione uma imagem .png ou .jpg do seu computador', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _imagemUrlCtrl.text = 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?w=400';
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                      icon: const Icon(Icons.folder_open, size: 16, color: Colors.white),
                      label: const Text('Escolher Arquivo do Computador', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('▼ Opções Avançadas (Link / URL Direto)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: FincoreTextField(
                      controller: tempUrlCtrl,
                      hintText: 'https://site.com/imagem.jpg',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempUrlCtrl.text.trim().isNotEmpty) {
                setState(() => _imagemUrlCtrl.text = tempUrlCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
            child: const Text('Aplicar Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_produtoFormKey.currentState!.validate()) return;
    if (_selectedCategoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria para o produto.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = _selectedProduto == null;
      final id = isNew ? const Uuid().v4() : _selectedProduto!.id;

      // Validação de segurança operacional: Não permitir inativar produto com estoque negativo ou reservas ativas sem ajuste
      if (!_ativo && !isNew) {
        final db = DependencyInjection().get<FincoreDatabase>();
        final estoqueRow = await (db.select(db.estoqueProdutosTable)
              ..where((t) => t.tenantId.equals(tenantCtx.tenantId) & t.produtoId.equals(id) & t.deletedAt.isNull()))
            .getSingleOrNull();

        if (estoqueRow != null) {
          final fisico = estoqueRow.quantidadeAtual;
          final reservado = estoqueRow.quantidadeReservada;

          // Se o saldo físico no galpão estiver negativo (< 0), oferece ajuste para regularizar o inventário
          if (fisico < 0) {
            setState(() => _isSaving = false);
            if (!mounted) return;
            final bool? confirmarAjuste = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: FincoreColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: FincoreColors.border)),
                title: const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Color(0xFFFFA726), size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Regularizar Saldo Físico Negativo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FincoreColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O produto "${_nomeCtrl.text}" possui saldo físico negativo no inventário:',
                      style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Saldo Físico Atual:', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                              Text('$fisico un.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE05C5C))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Reservas em Aberto:', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                              Text('$reservado un.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deseja regularizar o saldo físico para 0 un.?\n\n🔒 As reservas e os pedidos dos clientes continuarão 100% PRESERVADOS para que a cozinha continue atendendo os pedidos já contratados.',
                      style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Regularizar Físico & Inativar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirmarAjuste != true) {
              return;
            }

            setState(() => _isSaving = true);

            // Ajusta apenas o saldo físico negativo para 0, preservando as reservas dos pedidos existentes
            final agora = DateTime.now();
            await db.into(db.movimentacoesEstoqueTable).insert(
              MovimentacoesEstoqueTableCompanion.insert(
                id: const Uuid().v4(),
                tenantId: tenantCtx.tenantId,
                produtoId: id,
                tipo: 'inventario',
                quantidade: (-fisico).abs(),
                quantidadeAntes: fisico,
                quantidadeDepois: 0,
                quantidadeReservadaAntes: Value(reservado),
                quantidadeReservadaDepois: Value(reservado),
                motivo: const Value('Ajuste de saldo físico negativo para inativação comercial'),
                operadorId: Value(tenantCtx.usuario.id),
                dataHora: agora,
                syncVersion: const Value(1),
                syncStatus: SyncStatus.pending,
                createdAt: agora,
                updatedAt: agora,
                createdBy: tenantCtx.usuario.id,
                updatedBy: tenantCtx.usuario.id,
              ),
            );

            await (db.update(db.estoqueProdutosTable)
                  ..where((t) => t.id.equals(estoqueRow.id)))
                .write(EstoqueProdutosTableCompanion(
              quantidadeAtual: const Value(0),
              updatedAt: Value(agora),
              syncStatus: const Value(SyncStatus.pending),
            ));
          }
        }
      }

      final Map<String, dynamic> payloadMap = {
        'herdar_categoria': _herdarComercial,
        'herdar_estoque':   _herdarEstoque,
        'herdar_producao':  _herdarProducao,
        'herdar_comercial': _herdarComercial,
        'preco_base': double.tryParse(_precoBaseCtrl.text.replaceAll(',', '.')) ?? 1.50,
        'setor_impressao': _setorImpressao,
        'tempo_medio': int.tryParse(_tempoCtrl.text) ?? 30,
        'modo_producao': _modoProducao.name,
        'tipo_estoque': _tipoEstoque.name,
        'estoque_minimo': _herdarEstoque ? null : (int.tryParse(_estoqueMinCtrl.text) ?? 100),
        'estoque_maximo': _herdarEstoque ? null : (int.tryParse(_estoqueMaxCtrl.text) ?? 1000),
        'estoque_seguranca': _herdarEstoque ? null : (int.tryParse(_estoqueSegurancaCtrl.text) ?? 0),
        'estoque_critico': _herdarEstoque ? null : (int.tryParse(_estoqueCriticoCtrl.text) ?? 50),
        'lote_producao': _herdarProducao ? null : (int.tryParse(_loteProducaoCtrl.text) ?? 100),
        'dias_cobertura_alvo': _herdarProducao ? null : (int.tryParse(_diasCoberturaCtrl.text) ?? 3),
        'capacidade_campanha': _herdarProducao ? null : (int.tryParse(_capacidadeCampanhaCtrl.text) ?? 0),
        'tempo_preparacao': _herdarProducao ? null : (int.tryParse(_tempoPreparacaoCtrl.text) ?? 0),
        'estrategia_producao': _herdarProducao ? null : _estrategiaProducao,
        'ncm': _ncmCtrl.text.trim(),
        'cest': _cestCtrl.text.trim(),
        'canais': {
          'pdv': _canalPdv,
          'delivery': _canalDeliveryApp,
          'ifood': _canaliFood,
          'whatsapp': _canalWhatsApp,
          'autoatendimento': _canalAutoatendimento,
        },
      };

      final skuToSave = _skuCtrl.text.trim().isNotEmpty ? _skuCtrl.text.trim() : 'SKU-PRD-${id.substring(0, 4)}';
      final imgUrlVal = _isValidImageUrl(_imagemUrlCtrl.text) ? _imagemUrlCtrl.text.trim() : null;

      final produto = Produto(
        id: id,
        tenantId: tenantCtx.tenantId,
        codigo: _codigoInternoCtrl.text.trim().isEmpty ? null : _codigoInternoCtrl.text.trim(),
        nome: _nomeCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim().isEmpty ? null : _descricaoCtrl.text.trim(),
        categoriaId: _selectedCategoriaId!,
        unidadeVenda: _unidade,
        statusComercial: _status,
        tempoMedioMinutos: int.tryParse(_tempoCtrl.text) ?? 30,
        controlaEstoque: _controlaEstoque,
        ordemProducao: isNew ? _allProdutos.length : _selectedProduto!.ordemProducao,
        ativo: _ativo,
        sku: skuToSave,
        codigoBarras: _codigoBarrasCtrl.text.trim().isEmpty ? null : _codigoBarrasCtrl.text.trim(),
        imagem: imgUrlVal,
        corEtiqueta: '#FF6B00',
        metadataPayload: jsonEncode(payloadMap),
        metadata: _selectedProduto?.metadata.copyWith(
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

      // Aplica os parâmetros no registro de estoque do produto
      final estoqueCtrl = DependencyInjection().get<EstoqueController>();
      await estoqueCtrl.aplicarParametrosProduto(produto.id);
      await estoqueCtrl.carregarEstoque();
      try {
        final planeCtrl = DependencyInjection().get<PlanoProducaoController>();
        await planeCtrl.refresh();
      } catch (_) {}

      // Auto-vincular produto a tabelas de preço da categoria
      try {
        final catAssocRepo = DependencyInjection().get<CategoriaTabelaPrecificacaoRepository>();
        final catAssocs = await catAssocRepo.findByCategoriaId(produto.categoriaId);
        if (catAssocs.isNotEmpty) {
          final prodAssocs = await _assocRepo.findByProdutoId(produto.id);
          final existingTabelaIds = prodAssocs.where((pa) => pa.ativo).map((pa) => pa.tabelaPrecificacaoId).toSet();

          for (final catAssoc in catAssocs) {
            if (catAssoc.ativo && !existingTabelaIds.contains(catAssoc.tabelaPrecificacaoId)) {
              final newAssoc = ProdutoTabelaPrecificacao(
                id: const Uuid().v4(),
                tenantId: tenantCtx.tenantId,
                produtoId: produto.id,
                tabelaPrecificacaoId: catAssoc.tabelaPrecificacaoId,
                ativo: true,
                prioridade: catAssoc.prioridade,
                dataInicio: catAssoc.dataInicio,
                dataFim: catAssoc.dataFim,
                metadata: SyncMetadata(
                  version: 1,
                  createdAt: DateTime.now().toUtc(),
                  updatedAt: DateTime.now().toUtc(),
                  createdBy: tenantCtx.usuario.id,
                  updatedBy: tenantCtx.usuario.id,
                  syncStatus: SyncStatus.pending,
                ),
              );
              await _assocRepo.save(newAssoc);
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao auto-vincular produto à política de preço da categoria: $e');
      }

      _selectedProduto = produto;
      await _loadData();
      widget.onChanged?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produto salvo no banco com SKU ($skuToSave) e Foto Protagonista!'),
          backgroundColor: FincoreColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar produto: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  int _getEstoqueBaixoCount() {
    return _allProdutos.where((p) {
      if (!p.controlaEstoque) return false;
      final est = _estoqueMap[p.id];
      if (est != null) {
        final disponivel = est.quantidadeAtual - est.quantidadeReservada;
        return disponivel < est.quantidadeMinima;
      }
      int fisico = 0;
      int minEstoque = 0;
      if (p.metadataPayload != null && p.metadataPayload!.isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(p.metadataPayload!);
          fisico = (jsonMap['estoque_atual'] ?? jsonMap['estoqueFisico'] ?? 0) as int;
          minEstoque = (jsonMap['estoque_minimo'] ?? jsonMap['estoqueMinimo'] ?? 0) as int;
        } catch (_) {}
      }
      return fisico < minEstoque;
    }).length;
  }


  Widget _discreteMetricText(String text, {bool isWarning = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isWarning ? FincoreColors.danger : FincoreColors.textSecondary,
      ),
    );
  }

  ({
    int fisico,
    int reservado,
    int produzir,
    String cobertura,
    int minEstoque,
    int maxEstoque,
    bool herdarCat,
    String? imagemUrl,
    String canalVenda,
  }) _getProdutoMetrics(Produto prod) {
    int fisico = 0;
    int reservado = 0;
    int minEstoque = 100;
    int maxEstoque = 1000;
    bool herdarCat = true;
    String? imagemUrl = prod.imagem;

    final est = _estoqueMap[prod.id];
    if (est != null) {
      fisico = est.quantidadeAtual;
      reservado = est.quantidadeReservada;
      minEstoque = est.quantidadeMinima;
      maxEstoque = est.quantidadeMaxima;
    } else if (prod.metadataPayload != null && prod.metadataPayload!.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(prod.metadataPayload!);
        herdarCat = jsonMap['herdar_comercial'] ?? jsonMap['herdar_categoria'] ?? true;
        fisico = (jsonMap['estoque_atual'] ?? jsonMap['estoqueFisico'] ?? 0) as int;
        reservado = (jsonMap['estoque_reservado'] ?? jsonMap['reservado'] ?? 0) as int;
        minEstoque = (jsonMap['estoque_minimo'] ?? jsonMap['estoqueMinimo'] ?? 100) as int;
        maxEstoque = (jsonMap['estoque_maximo'] ?? jsonMap['estoqueMaximo'] ?? 1000) as int;
        if (imagemUrl == null || imagemUrl.trim().isEmpty) {
          imagemUrl = jsonMap['imagem_url'] ?? jsonMap['imagem'];
        }
      } catch (_) {}
    }

    final disponivel = (fisico - reservado).clamp(-999999, 999999);
    final produzir = disponivel < minEstoque ? (minEstoque - disponivel) : 0;
    final String cobertura = fisico > 0 ? '${(disponivel / 25.0).toStringAsFixed(1)} d' : '0.0 d';

    if (herdarCat && prod.categoriaId != null) {
      final cat = _categorias.cast<Categoria?>().firstWhere((c) => c?.id == prod.categoriaId, orElse: () => null);
      if (cat != null && cat.metadataPayload != null && cat.metadataPayload!.isNotEmpty) {
        try {
          final Map<String, dynamic> cJson = jsonDecode(cat.metadataPayload!);
          minEstoque = (cJson['estoque_minimo'] ?? 100) as int;
          maxEstoque = (cJson['estoque_maximo'] ?? 1000) as int;
        } catch (_) {}
      }
    }

    return (
      fisico: fisico,
      reservado: reservado,
      produzir: produzir,
      cobertura: cobertura,
      minEstoque: minEstoque,
      maxEstoque: maxEstoque,
      herdarCat: herdarCat,
      imagemUrl: imagemUrl,
      canalVenda: 'Varejo',
    );
  }

  Widget _buildCardMetricCol(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: FincoreColors.textMuted)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  Widget _buildProductCard(Produto prod) {
    final cat = _categorias.cast<Categoria?>().firstWhere((c) => c?.id == prod.categoriaId, orElse: () => null);
    final metrics = _getProdutoMetrics(prod);

    // Resolver preço (já está em Reais em _precosProdutosMap)
    double precoVal = _precosProdutosMap[prod.id] ?? 0.0;
    if (precoVal <= 0 && cat != null && cat.metadataPayload != null && cat.metadataPayload!.isNotEmpty) {
      try {
        final Map<String, dynamic> cJson = jsonDecode(cat.metadataPayload!);
        final pBase = cJson['preco_base'];
        if (pBase != null) precoVal = (pBase as num).toDouble();
      } catch (_) {}
    }
    if (precoVal <= 0) precoVal = 1.50;

    final precoFormatado = 'R\$ ${precoVal.toStringAsFixed(2).replaceAll('.', ',')}';

    // Status do Estoque
    String statusEstoque = 'ESTOQUE OK';
    Color statusEstoqueColor = FincoreColors.success;
    if (metrics.fisico <= 0) {
      statusEstoque = 'SEM ESTOQUE';
      statusEstoqueColor = FincoreColors.danger;
    } else if (metrics.fisico < metrics.minEstoque) {
      statusEstoque = 'ESTOQUE BAIXO';
      statusEstoqueColor = FincoreColors.warning;
    }

    final hasValidImg = _isValidImageUrl(metrics.imagemUrl ?? '');
    final catIconData = _iconesMap[cat?.icone ?? 'fastfood'] ?? Icons.fastfood_outlined;
    final catColorVal = Color(int.parse((cat?.cor ?? '#FF6B00').replaceFirst('#', '0xFF')));
    final isSelected = _selectedProduto?.id == prod.id && _isInspectorOpen;

    return Container(
      padding: const EdgeInsets.all(12),
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
          // 1. Top Bar: Categoria Pill (Left) + Status Estoque Pill (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Text(
                  (cat?.nome ?? 'GERAL').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusEstoqueColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusEstoque,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusEstoqueColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Main Row: Imagem/Ícone da Categoria + Nome, Subtítulo, Preço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: catColorVal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                  image: hasValidImg
                      ? DecorationImage(image: NetworkImage(metrics.imagemUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: !hasValidImg
                    ? Icon(catIconData, color: catColorVal, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.nome,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prod.descricao != null && prod.descricao!.isNotEmpty
                          ? prod.descricao!
                          : 'Grupo: ${metrics.canalVenda}',
                      style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          precoFormatado,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: FincoreColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          metrics.herdarCat ? 'Herdado da categoria' : 'Customizado',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: metrics.herdarCat ? FincoreColors.success : FincoreColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Container de Métricas Operacionais (4 Colunas: Físico, Reservado, Produzir, Cobertura)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _buildCardMetricCol('Físico', '${metrics.fisico}', FincoreColors.textPrimary)),
                Expanded(child: _buildCardMetricCol('Reservado', '${metrics.reservado}', metrics.reservado > 0 ? FincoreColors.danger : FincoreColors.textSecondary)),
                Expanded(child: _buildCardMetricCol('Produzir', '${metrics.produzir}', FincoreColors.textSecondary)),
                Expanded(child: _buildCardMetricCol('Cobertura', metrics.cobertura, FincoreColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 4. Rodapé Informativo (Última entrada | Última movimentação)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Última entrada: Nenhuma', style: TextStyle(fontSize: 9, color: FincoreColors.textMuted)),
              Text('Última mov.: Nenhuma', style: TextStyle(fontSize: 9, color: FincoreColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: FincoreColors.border, height: 1),
          const SizedBox(height: 4),

          // 5. Linha de Ações (Painel, Editar, Produzir)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _selectProduto(prod, abrirPainel: true),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 13, color: FincoreColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Painel', style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _selectProduto(prod, abrirPainel: false);
                  setState(() => _isEditing = true);
                },
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, size: 13, color: FincoreColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Editar', style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ordem de produção para "${prod.nome}" iniciada com sucesso.'),
                      backgroundColor: FincoreColors.primary,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 13, color: FincoreColors.primary),
                    const SizedBox(width: 4),
                    Text('Produzir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final prod = _selectedProduto;
    final cat = _categorias.cast<Categoria?>().firstWhere((c) => c?.id == prod?.categoriaId, orElse: () => null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FincoreColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FincoreColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fastfood, color: FincoreColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        prod?.nome ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: FincoreColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, size: 10, color: FincoreColors.success),
                          SizedBox(width: 4),
                          Text('DISPONÍVEL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: FincoreColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (prod?.descricao?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    prod!.descricao!,
                    style: const TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${cat?.nome ?? "Salgados Fritos"} • Grupo Varejo',
                  style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _isInspectorOpen = false),
            icon: const Icon(Icons.close, size: 20, color: FincoreColors.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    return Stack(
      children: [
        // ── Conteúdo Principal da Página (Grid em Largura Total) ───────────
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Resumo Contextual Pequeno (Fina linha de status)
              Row(
                children: [
                  _discreteMetricText('${_allProdutos.length} produtos'),
                  const SizedBox(width: 8),
                  const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                  const SizedBox(width: 8),
                  _discreteMetricText('${_categorias.length} categorias'),
                  const SizedBox(width: 8),
                  const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                  const SizedBox(width: 8),
                  _discreteMetricText('${_getEstoqueBaixoCount()} com estoque baixo', isWarning: _getEstoqueBaixoCount() > 0),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Linha de Pesquisa + Filtro de Categoria + Botão "+ Novo produto"
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
                                  _applyFilters();
                                });
                              },
                              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Pesquisar produto...',
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
                  // Dropdown de Filtro de Categoria
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedFilterCategoriaId,
                        hint: const Text('Categoria: Todas', style: TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
                        dropdownColor: FincoreColors.surfaceOverlay,
                        icon: const Icon(Icons.arrow_drop_down, color: FincoreColors.textMuted),
                        style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                        onChanged: (val) {
                          setState(() {
                            _selectedFilterCategoriaId = val;
                            _applyFilters();
                          });
                        },
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Categoria: Todas'),
                          ),
                          ..._categorias.map((cat) {
                            return DropdownMenuItem<String?>(
                              value: cat.id,
                              child: Text(cat.nome),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _selectProduto(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.fastfood_outlined, size: 16, color: Colors.white),
                    label: const Text('Novo Produto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Grid Operacional de Cards (Full Width)
              Expanded(
                child: _filteredProdutos.isEmpty
                    ? const Center(child: Text('Nenhum produto encontrado.', style: TextStyle(color: FincoreColors.textMuted)))
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
                            itemCount: _filteredProdutos.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisExtent: 260,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (ctx, idx) {
                              final prod = _filteredProdutos[idx];
                              return _buildProductCard(prod);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // ── Drawer Lateral de Inspector (quando aberto) ────────────────────
        if (_isInspectorOpen && _selectedProduto != null) ...[
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
            width: 440,
            child: Container(
              decoration: const BoxDecoration(
                color: FincoreColors.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(-4, 0)),
                ],
              ),
              child: Column(
                children: [
                  _buildDrawerHeader(),
                  Expanded(child: _buildRightPanel()),
                ],
              ),
            ),
          ),
        ],

        // ── Modal Dialog de Edição Centralizado ─────────────────────────
        if (_isEditing) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _isEditing = false;
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
                child: _buildEditorSideSheet(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: _filteredProdutos.isEmpty
                ? const Center(child: Text('NENHUM PRODUTO ENCONTRADO.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredProdutos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final prod = _filteredProdutos[idx];
                      final isSelected = _selectedProduto?.id == prod.id;
                      final preco = _precosProdutosMap[prod.id] ?? 1.50;
                      final skuVal = prod.sku ?? 'SKU-${prod.nome.substring(0, 3).toUpperCase()}';
                      final cat = _categorias.cast<Categoria?>().firstWhere((c) => c?.id == prod.categoriaId, orElse: () => null);
                      final iconData = _iconesMap[cat?.icone ?? 'fastfood'] ?? Icons.fastfood_outlined;
                      final hasValidImg = _isValidImageUrl(prod.imagem ?? '');

                      return InkWell(
                        onTap: () => _selectProduto(prod, abrirPainel: true),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? FincoreColors.primary.withValues(alpha: 0.08) : FincoreColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? FincoreColors.primary.withValues(alpha: 0.5) : FincoreColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected) ...[
                                Container(
                                  width: 4,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: FincoreColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: FincoreColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: FincoreColors.border),
                                  image: hasValidImg
                                      ? DecorationImage(image: NetworkImage(prod.imagem!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: !hasValidImg
                                    ? Icon(iconData, color: FincoreColors.primary, size: 22)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.nome,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(skuVal, style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                                        const Text(' • ', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                                        Text(cat?.nome ?? "Geral", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FincoreColors.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: prod.ativo ? FincoreColors.success.withValues(alpha: 0.12) : FincoreColors.textMuted.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            prod.ativo ? '● Ativo' : '● Inativo',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: prod.ativo ? FincoreColors.success : FincoreColors.textMuted),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: FincoreColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '🏷️ ${_herdarCategoria ? "Herança" : "Custom"}',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: FincoreColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: FincoreColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: FincoreColors.border),
                                ),
                                child: Text(
                                  'R\$ ${preco.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: FincoreColors.primary),
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

  Future<void> _duplicarProduto(Produto prod) async {
    final newProd = prod.copyWith(
      id: const Uuid().v4(),
      nome: '${prod.nome} (Cópia)',
      sku: 'SKU-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      metadataPayload: prod.metadataPayload,
    );
    await _produtoRepo.saveWithSync(newProd);
    await _loadData();
    _selectProduto(newProd);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto "${prod.nome}" duplicado com sucesso!'), backgroundColor: FincoreColors.success),
      );
    }
  }

  Future<void> _excluirProduto(Produto prod) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: const Text('Excluir Produto?', style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Deseja realmente excluir "${prod.nome}"? Esta ação não poderá ser desfeita.', style: const TextStyle(color: FincoreColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _produtoRepo.delete(prod.id);
      setState(() {
        _isInspectorOpen = false;
        _isEditing = false;
        _selectedProduto = null;
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto removido do catálogo.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Widget _buildStripePillarChip(String label, bool isInherited) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isInherited ? FincoreColors.success.withValues(alpha: 0.06) : FincoreColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isInherited ? FincoreColors.success.withValues(alpha: 0.2) : FincoreColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 11, color: isInherited ? FincoreColors.success : FincoreColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isInherited ? FincoreColors.textSecondary : FincoreColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String date, String description, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11.5, color: FincoreColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildKpiBox(String title, String val, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textCol)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildParameterRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FincoreColors.textMuted),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
        const Spacer(),
        Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
      ],
    );
  }

  Widget _buildReservationOrderCard(String title, String qtd, String status, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 2),
              Text('Status: $status • $sub', style: const TextStyle(fontSize: 9.5, color: FincoreColors.textMuted)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(qtd, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<_EstoqueSnapshot> _carregarSnapshot(
    Produto prod,
    bool controlaEstoque,
    int minEstoque,
    int lotePadrao,
  ) async {
    final tenantCtx = DependencyInjection().get<TenantContext>();
    if (!tenantCtx.hasContext || !controlaEstoque) {
      return const _EstoqueSnapshot.vazio();
    }
    final db = DependencyInjection().get<FincoreDatabase>();
    final tenantId = tenantCtx.tenantId;

    final estoque = await (db.select(db.estoqueProdutosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.produtoId.equals(prod.id) &
              t.deletedAt.isNull().equals(true)))
        .getSingleOrNull();

    final fisico = estoque?.quantidadeAtual ?? 0;
    final reservado = estoque?.quantidadeReservada ?? 0;
    final disponivel = (fisico - reservado).clamp(-999999, 999999);
    final minimoEstoque = estoque?.quantidadeMinima ?? minEstoque;
    final lote = estoque?.quantidadeProducaoLote ?? lotePadrao;

    final limite30d = DateTime.now().toUtc().subtract(const Duration(days: 30));
    final movs30d = await (db.select(db.movimentacoesEstoqueTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.produtoId.equals(prod.id) &
              t.deletedAt.isNull().equals(true) &
              (t.tipo.equals('saida') | t.tipo.equals('expedicao')) &
              t.dataHora.isBiggerThanValue(limite30d)))
        .get();

    final totalSaidas30d = movs30d.fold<int>(0, (sum, m) => sum + m.quantidade);
    final consumoDiario = totalSaidas30d / 30.0;
    final coberturaDias = consumoDiario > 0 ? disponivel / consumoDiario : 0.0;

    final produzir = disponivel < minimoEstoque
        ? ((minimoEstoque - disponivel) / (lote > 0 ? lote : 1)).ceil() * (lote > 0 ? lote : 1)
        : 0;

    // Busca pedidos ativos que contêm este produto
    final listItens = await (db.select(db.itensPedidoTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.produtoId.equals(prod.id) &
              t.deletedAt.isNull().equals(true)))
        .get();

    final statusFinalizados = {'entregue', 'concluido', 'concluído', 'cancelado', 'finalizado', 'despachado', 'enviado'};
    final List<({String numero, int qtd, String status})> pedidosReservando = [];

    if (listItens.isNotEmpty) {
      final pedidoIds = listItens.map((i) => i.pedidoId).toSet();
      final pRows = await (db.select(db.pedidosTable)
            ..where((t) => t.id.isIn(pedidoIds) & t.deletedAt.isNull().equals(true)))
          .get();

      for (final p in pRows) {
        if (!statusFinalizados.contains(p.status.toLowerCase().trim())) {
          final itemDoPedido = listItens.firstWhere((i) => i.pedidoId == p.id);
          pedidosReservando.add((
            numero: p.numeroPedido != null ? '#${p.numeroPedido}' : 'Ped #${p.id.substring(0, 4)}',
            qtd: itemDoPedido.quantidade.toInt(),
            status: p.status,
          ));
        }
      }
    }

    return _EstoqueSnapshot(
      fisico: fisico,
      reservado: reservado,
      disponivel: disponivel,
      produzir: produzir,
      consumoDiario: consumoDiario,
      coberturaDias: coberturaDias,
      minimoEstoque: minimoEstoque,
      lote: lote,
      pedidosReservando: pedidosReservando,
    );
  }

  Widget _buildRightPanel() {
    final prod = _selectedProduto;
    if (prod == null) {
      return const Center(
        child: Text('Selecione um produto para inspecionar.', style: TextStyle(color: FincoreColors.textMuted)),
      );
    }

    final preco = _precosProdutosMap[prod.id] ?? 1.50;
    final skuVal = prod.sku ?? 'SKU-${prod.nome.substring(0, 3).toUpperCase()}';
    final catNome = _categorias.cast<Categoria?>().firstWhere((c) => c?.id == prod.categoriaId, orElse: () => null)?.nome ?? 'Geral';

    Map<String, dynamic> meta = {};
    if (prod.metadataPayload != null && prod.metadataPayload!.isNotEmpty) {
      try {
        meta = jsonDecode(prod.metadataPayload!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final bool herdarCat = meta['herdar_categoria'] ?? true;
    final bool controlaEstoque = meta['controla_estoque'] ?? prod.controlaEstoque;
    final int minEstoque = (meta['estoque_minimo'] ?? meta['estoqueMinimo'] ?? 0) as int;
    final int idealEstoque = (meta['estoque_maximo'] ?? meta['estoqueIdeal'] ?? 0) as int;
    final int lotePadrao = (meta['lotePadrao'] ?? 0) as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── BANNER EXPLICATIVO DE HERANÇA DE CATEGORIA ──────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: herdarCat ? FincoreColors.primary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: herdarCat ? FincoreColors.primary.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      herdarCat ? Icons.verified_outlined : Icons.tune_outlined,
                      size: 16,
                      color: herdarCat ? FincoreColors.primary : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        herdarCat ? 'Parâmetros Herdados da Categoria ($catNome)' : 'Parâmetros Customizados Manualmente',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  herdarCat
                      ? 'Preço base, setor de produção, tempo de preparo e regras fiscais/estoque são mantidos automaticamente pela categoria.'
                      : 'Este produto possui configurações manuais exclusivas.',
                  style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    _selectProduto(prod);
                    setState(() {
                      _herdarCategoria = !herdarCat;
                      _isEditing = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: const BorderSide(color: FincoreColors.border),
                  ),
                  icon: Icon(herdarCat ? Icons.edit_note : Icons.link, size: 14, color: FincoreColors.primary),
                  label: Text(
                    herdarCat ? 'Desativar Herança e Alterar Manualmente' : 'Reativar Herança da Categoria',
                    style: TextStyle(fontSize: 11, color: FincoreColors.primary),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<_EstoqueSnapshot>(
            future: _carregarSnapshot(prod, controlaEstoque, minEstoque, lotePadrao),
            builder: (context, snap) {
              final s = snap.data ?? const _EstoqueSnapshot.vazio();
              final bool carregando = snap.connectionState == ConnectionState.waiting;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. TOP 4 KPI CARDS COLORIDOS ──────────────────────
                  if (carregando)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else
                    Row(
                      children: [
                        Expanded(child: _buildKpiBox('Físico', controlaEstoque ? '${s.fisico}' : '--', Colors.blue.withValues(alpha: 0.12), Colors.blue[700]!)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildKpiBox('Reservado', controlaEstoque ? '${s.reservado}' : '--', Colors.amber.withValues(alpha: 0.12), Colors.amber[800]!)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildKpiBox('Produzir', controlaEstoque ? '${s.produzir}' : 'Demanda', Colors.orange.withValues(alpha: 0.12), Colors.orange[800]!)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildKpiBox(
                          'Cobertura',
                          controlaEstoque
                            ? (s.coberturaDias > 0
                                ? '${s.coberturaDias.toStringAsFixed(1)}d'
                                : s.fisico > 0 ? 'Sem hist.' : '0d')
                            : 'N/A',
                          Colors.purple.withValues(alpha: 0.12),
                          Colors.purple[700]!,
                        )),
                      ],
                    ),

                  const SizedBox(height: 8),
                  if (controlaEstoque && !carregando && s.consumoDiario > 0)
                    Text(
                      'Média de consumo: ${s.consumoDiario.toStringAsFixed(1)} un/dia (base: 30 dias)',
                      style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  if (controlaEstoque && !carregando && s.consumoDiario == 0 && s.fisico > 0)
                    const Text(
                      'Sem vendas nos últimos 30 dias — projeção aguardando histórico',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
                    ),

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border),
                  const SizedBox(height: 12),

                  // ─── 2. PARÂMETROS DE PRODUÇÃO ─────────────────────────
                  _buildInspectorSectionTitle('PARÂMETROS DE PRODUÇÃO'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildParameterRow(Icons.inventory_2_outlined, 'Estoque Mínimo (Disponível)', '${s.minimoEstoque} unidades'),
                        const SizedBox(height: 8),
                        _buildParameterRow(Icons.bookmark_outline, 'Estoque Ideal', '$idealEstoque unidades'),
                        const SizedBox(height: 8),
                        _buildParameterRow(Icons.grid_view_outlined, 'Lote Padrão de Produção', '${s.lote > 0 ? s.lote : lotePadrao} unidades'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border),
                  const SizedBox(height: 12),

                  // ─── 3. PEDIDOS RESERVANDO ESTE PRODUTO ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInspectorSectionTitle('PEDIDOS RESERVANDO ESTE PRODUTO'),
                      Text('Filtrar Pedidos', style: TextStyle(fontSize: 10.5, color: FincoreColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (s.pedidosReservando.isNotEmpty) ...[
                    for (final p in s.pedidosReservando) ...[
                      _buildReservationOrderCard(
                        'Pedido ${p.numero}',
                        '${p.qtd} unid.',
                        p.status.toUpperCase(),
                        'Reserva Ativa',
                      ),
                      const SizedBox(height: 6),
                    ],
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: const Text(
                        'Nenhum pedido reservando este produto no momento.',
                        style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border),
                  const SizedBox(height: 12),

                  // ─── 4. AÇÕES DE RESUMO DE RODAPÉ ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: FincoreColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.description_outlined, size: 14, color: FincoreColors.textSecondary),
                          label: Text('Ver Pedidos (${s.reservado})', style: const TextStyle(fontSize: 10.5, color: FincoreColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.build_outlined, size: 14, color: Colors.white),
                          label: const Text('Enviar p/ Produção', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),


          const SizedBox(height: 16),
          const Divider(color: FincoreColors.border),
          const SizedBox(height: 8),

          // ─── 5. MAIS DETALHES (SANFONA ACCORDION) ─────────────────────────
          ExpansionTile(
            title: const Text('Mais Detalhes TÉCNICOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            collapsedIconColor: FincoreColors.textMuted,
            iconColor: FincoreColors.primary,
            children: [
              _buildInspectorDetailRow('SKU', skuVal),
              _buildInspectorDetailRow('Preço de Venda', 'R\$ ${preco.toStringAsFixed(2)}'),
              _buildInspectorDetailRow('Código de Barras (EAN)', prod.codigoBarras?.isNotEmpty == true ? prod.codigoBarras! : 'Sem EAN'),
              _buildInspectorDetailRow('Unidade de Venda', prod.unidadeVenda.name.toUpperCase()),
              _buildInspectorDetailRow('NCM Fiscal', _ncmCtrl.text.isEmpty ? 'Não informado' : _ncmCtrl.text),
              _buildInspectorDetailRow('CEST Fiscal', _cestCtrl.text.isEmpty ? 'Não informado' : _cestCtrl.text),
              _buildInspectorDetailRow('Setor KDS/Cozinha', _setorImpressao),
              _buildInspectorDetailRow('Tempo de Produção', '${_tempoCtrl.text} min'),
              _buildInspectorDetailRow('Controle de Estoque FIFO', _controlaEstoque ? 'Ativo' : 'Inativo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSideSheet() {
    final isNew = _selectedProduto == null;
    final imgUrl = _imagemUrlCtrl.text.trim();
    final hasValidImg = _isValidImageUrl(imgUrl);

    return Container(
      color: FincoreColors.surface,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FincoreColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isNew ? 'NOVO' : 'EDITANDO',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isNew ? 'Novo Produto' : 'Editar Produto',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isEditing = false),
                  icon: const Icon(Icons.close, size: 20, color: FincoreColors.textMuted),
                ),
              ],
            ),
          ),

          // ── Corpo — 3 Cards Salgaderia ─────────────────────────────────
          Expanded(
            child: Form(
              key: _produtoFormKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ══════════════════════════════════════════════════════
                    // CARD 1 — IDENTIFICAÇÃO & PRECIFICAÇÃO
                    // ══════════════════════════════════════════════════════
                    _buildFormCard(
                      label: 'Identificação & Precificação',
                      icon: Icons.label_outline,
                      children: [
                        // Foto miniatura
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: FincoreColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: FincoreColors.border, width: 1.5),
                                  image: hasValidImg
                                      ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: !hasValidImg
                                    ? const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.fastfood_outlined, size: 28, color: FincoreColors.textMuted),
                                          SizedBox(height: 3),
                                          Text('Sem Foto', style: TextStyle(fontSize: 9, color: FincoreColors.textMuted)),
                                        ],
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: _openImagePickerModal,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: const BorderSide(color: FincoreColors.border),
                                ),
                                icon: Icon(Icons.camera_alt_outlined, size: 13, color: FincoreColors.primary),
                                label: Text(
                                  hasValidImg ? 'Alterar Foto' : 'Selecionar Foto',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Nome do Produto
                        const _FormFieldLabel(label: 'Nome do produto', isRequired: true),
                        FincoreTextField(
                          controller: _nomeCtrl,
                          hintText: 'Ex.: Coxinha de Frango',
                          validator: FincoreValidators.required,
                        ),
                        const SizedBox(height: 12),

                        // Descrição Comercial — LOGO ABAIXO DO NOME
                        const _FormFieldLabel(label: 'Descrição comercial'),
                        FincoreTextField(
                          controller: _descricaoCtrl,
                          hintText: 'Ex.: Massa crocante, recheio de frango com catupiry',
                        ),
                        const SizedBox(height: 12),

                        // Categoria / Grupo de Preço
                        const _FormFieldLabel(label: 'Categoria / Grupo de Preço', isRequired: true),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: (_selectedCategoriaId != null &&
                                  _categorias.any((c) => c.id == _selectedCategoriaId))
                              ? _selectedCategoriaId
                              : null,
                          dropdownColor: FincoreColors.surface,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: FincoreColors.background,
                            hintText: _categorias.isEmpty ? 'Nenhuma categoria cadastrada' : 'Selecione a categoria',
                            hintStyle: const TextStyle(fontSize: 13, color: FincoreColors.textMuted),
                          ),
                          style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                          items: _categorias
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.nome, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCategoriaId = v;
                              if (_herdarCategoria) _applyCategoryInheritanceDefaults(v);
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // SKU
                        Row(
                          children: [
                            Expanded(child: _FormFieldLabel(label: 'SKU do produto')),
                            InkWell(
                              onTap: _generateAutoSku,
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, size: 12, color: FincoreColors.primary),
                                  const SizedBox(width: 3),
                                  Text('Regerar', style: TextStyle(fontSize: 11, color: FincoreColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        FincoreTextField(controller: _skuCtrl, hintText: 'Ex.: SKU-COX-01'),
                        const SizedBox(height: 12),

                        // Código de Barras
                        const _FormFieldLabel(label: 'Código de barras (EAN-13)'),
                        FincoreTextField(controller: _codigoBarrasCtrl, hintText: '7891234567890'),
                        const SizedBox(height: 12),

                        // Status Ativo/Inativo
                        Row(
                          children: [
                            Switch(
                              value: _ativo,
                              activeColor: FincoreColors.primary,
                              onChanged: (v) => setState(() => _ativo = v),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _ativo ? 'Produto ATIVO' : 'Produto INATIVO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _ativo ? FincoreColors.success : FincoreColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ══════════════════════════════════════════════════════
                    // CARD 2 — CONTROLE DE ESTOQUE FÍSICO
                    // ══════════════════════════════════════════════════════
                    _buildFormCard(
                      label: 'Controle de Estoque Físico',
                      icon: Icons.inventory_2_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Herdar ', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                          SizedBox(
                            height: 20,
                            child: Switch(
                              value: _herdarEstoque,
                              activeColor: FincoreColors.primary,
                              onChanged: (v) {
                                setState(() {
                                  _herdarEstoque = v;
                                  if (v) _applyCategoryInheritanceDefaults(_selectedCategoriaId);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!_herdarEstoque) ...[
                            const Text('Controlar ', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                            SizedBox(
                              height: 20,
                              child: Switch(
                                value: _controlaEstoque,
                                activeColor: FincoreColors.primary,
                                onChanged: (v) => setState(() => _controlaEstoque = v),
                              ),
                            ),
                          ],
                        ],
                      ),
                      children: [
                        if (_herdarEstoque) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: FincoreColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, size: 14, color: FincoreColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Dados herdados da categoria: ${_controlaEstoque ? "Controla estoque" : "Não controla estoque"} (Mín: ${_estoqueMinCtrl.text} | Máx: ${_estoqueMaxCtrl.text})',
                                    style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          if (_controlaEstoque) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _FormFieldLabel(label: 'Estoque de Segurança', isOptional: true),
                                      FincoreTextField(
                                        controller: _estoqueSegurancaCtrl,
                                        hintText: 'Ex.: 10',
                                        keyboardType: TextInputType.number,
                                        validator: FincoreValidators.nonNegativeInteger,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _FormFieldLabel(label: 'Estoque Crítico (Alerta Vermelho)', isOptional: true),
                                      FincoreTextField(
                                        controller: _estoqueCriticoCtrl,
                                        hintText: 'Ex.: 30',
                                        keyboardType: TextInputType.number,
                                        validator: FincoreValidators.nonNegativeInteger,
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
                                      const _FormFieldLabel(label: 'Estoque Mínimo (Atenção Laranja)', isOptional: true),
                                      FincoreTextField(
                                        controller: _estoqueMinCtrl,
                                        hintText: 'Ex.: 50',
                                        keyboardType: TextInputType.number,
                                        validator: FincoreValidators.nonNegativeInteger,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _FormFieldLabel(label: 'Capacidade Máxima / Teto', isOptional: true),
                                      FincoreTextField(
                                        controller: _estoqueMaxCtrl,
                                        hintText: 'Ex.: 300',
                                        keyboardType: TextInputType.number,
                                        validator: FincoreValidators.nonNegativeInteger,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            const Text(
                              'O controle de estoque está desativado para este produto. Nenhuma movimentação ou projeção será calculada.',
                              style: TextStyle(fontSize: 11, color: FincoreColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ══════════════════════════════════════════════════════
                    // CARD 3 — PREPARAÇÃO NA COZINHA & TEMPOS (SLA)
                    // ══════════════════════════════════════════════════════
                    _buildFormCard(
                      label: 'Preparação na Cozinha & Tempos de Entrega',
                      icon: Icons.restaurant_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Herdar ', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                          SizedBox(
                            height: 20,
                            child: Switch(
                              value: _herdarProducao,
                              activeColor: FincoreColors.primary,
                              onChanged: (v) {
                                setState(() {
                                  _herdarProducao = v;
                                  if (v) _applyCategoryInheritanceDefaults(_selectedCategoriaId);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      children: [
                        if (_herdarProducao) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: FincoreColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, size: 14, color: FincoreColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Dados herdados da categoria: Setor: $_setorImpressao | Tempo: ${_tempoCtrl.text} min',
                                    style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FormFieldLabel(label: 'Tempo por Fritura (min)', isOptional: true),
                                    FincoreTextField(
                                      controller: _tempoCtrl,
                                      hintText: 'Tempo por fornada (ex: 15)',
                                      keyboardType: TextInputType.number,
                                      validator: FincoreValidators.nonNegativeInteger,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FormFieldLabel(label: 'Setor / Rota KDS', isOptional: true),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: ['Cozinha', 'Balcao', 'Producao', 'Expedicao'].contains(_setorImpressao) ? _setorImpressao : 'Cozinha',
                                      dropdownColor: FincoreColors.surface,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: FincoreColors.background,
                                      ),
                                      style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                                      items: const [
                                        DropdownMenuItem(value: 'Cozinha', child: Text('Cozinha')),
                                        DropdownMenuItem(value: 'Balcao', child: Text('Balcão')),
                                        DropdownMenuItem(value: 'Producao', child: Text('Produção')),
                                        DropdownMenuItem(value: 'Expedicao', child: Text('Expedição')),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) setState(() => _setorImpressao = v);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: FincoreColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 13, color: FincoreColors.primary.withValues(alpha: 0.7)),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Dica: O sistema calcula o tempo total de fritura dividindo a quantidade do pedido pela capacidade do lote.',
                                  style: TextStyle(fontSize: 10, color: FincoreColors.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ══════════════════════════════════════════════════════
                    // CARD 4 — CONFIGURAÇÕES AVANÇADAS (ABAS COM HERANÇA)
                    // ══════════════════════════════════════════════════════
                    _buildFormCard(
                      label: 'Configurações Avançadas',
                      icon: Icons.settings_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Herdar da categoria ', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                          SizedBox(
                            height: 20,
                            child: Switch(
                              value: _herdarComercial,
                              activeColor: FincoreColors.primary,
                              onChanged: (v) {
                                setState(() {
                                  _herdarComercial = v;
                                  if (v) _applyCategoryInheritanceDefaults(_selectedCategoriaId);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      children: [
                        if (_herdarComercial) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: FincoreColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, size: 14, color: FincoreColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Preço, tributação e canais herdados da categoria: Preço Base: R\$ ${_precoBaseCtrl.text} | NCM: ${_ncmCtrl.text} | Canais Ativos: PDV (${_canalPdv ? "Sim" : "Não"}), Delivery (${_canalDeliveryApp ? "Sim" : "Não"}), iFood (${_canaliFood ? "Sim" : "Não"}), WhatsApp (${_canalWhatsApp ? "Sim" : "Não"})',
                                    style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
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
                                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 160,
                                  child: TabBarView(
                                    children: [
                                      // Comercial
                                      ListView(
                                        shrinkWrap: true,
                                        children: [
                                          const _FormFieldLabel(label: 'Preço Base (R\$)'),
                                          FincoreTextField(
                                            controller: _precoBaseCtrl,
                                            hintText: '1.50',
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          ),
                                          const SizedBox(height: 8),
                                          const _FormFieldLabel(label: 'Estratégia de Precificação'),
                                          DropdownButtonFormField<EstrategiaComercializacao>(
                                            value: _estrategia,
                                            dropdownColor: FincoreColors.surface,
                                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                            items: EstrategiaComercializacao.values
                                                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) setState(() => _estrategia = v);
                                            },
                                          ),
                                        ],
                                      ),
                                      // Fiscal
                                      ListView(
                                        shrinkWrap: true,
                                        children: [
                                          const _FormFieldLabel(label: 'NCM'),
                                          FincoreTextField(controller: _ncmCtrl, hintText: '1902.20.00'),
                                          const SizedBox(height: 8),
                                          const _FormFieldLabel(label: 'CEST'),
                                          FincoreTextField(controller: _cestCtrl, hintText: '17.049.00'),
                                        ],
                                      ),
                                      // Canais
                                      ListView(
                                        shrinkWrap: true,
                                        children: [
                                          CheckboxListTile(
                                            title: const Text('Disponível no PDV', style: TextStyle(fontSize: 12)),
                                            value: _canalPdv,
                                            onChanged: (v) => setState(() => _canalPdv = v ?? false),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: FincoreColors.primary,
                                          ),
                                          CheckboxListTile(
                                            title: const Text('Disponível no App/Delivery', style: TextStyle(fontSize: 12)),
                                            value: _canalDeliveryApp,
                                            onChanged: (v) => setState(() => _canalDeliveryApp = v ?? false),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: FincoreColors.primary,
                                          ),
                                          CheckboxListTile(
                                            title: const Text('Disponível no iFood', style: TextStyle(fontSize: 12)),
                                            value: _canaliFood,
                                            onChanged: (v) => setState(() => _canaliFood = v ?? false),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: FincoreColors.primary,
                                          ),
                                          CheckboxListTile(
                                            title: const Text('Disponível no WhatsApp', style: TextStyle(fontSize: 12)),
                                            value: _canalWhatsApp,
                                            onChanged: (v) => setState(() => _canalWhatsApp = v ?? false),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: FincoreColors.primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Rodapé Fixo ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: FincoreColors.surface,
              border: Border(top: BorderSide(color: FincoreColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: FincoreColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!_produtoFormKey.currentState!.validate()) return;
                            if (_selectedCategoriaId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Selecione uma categoria para o produto.')),
                              );
                              return;
                            }
                            await _salvar();
                            if (mounted) setState(() => _isEditing = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Salvando...' : 'Salvar produto',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card temático Salgaderia-style com borda esquerda colorida
  Widget _buildFormCard({
    required String label,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
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

  Widget _buildTabDadosGeraisShopifyStyle() {
    final imgUrl = _imagemUrlCtrl.text.trim();
    final hasValidImg = _isValidImageUrl(imgUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: hasValidImg
                        ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: !hasValidImg
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fastfood_outlined, size: 40, color: FincoreColors.textMuted),
                            SizedBox(height: 4),
                            Text('Sem Foto', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openImagePickerModal,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: Icon(Icons.camera_alt_outlined, size: 14, color: FincoreColors.primary),
                  label: Text(
                    hasValidImg ? 'Alterar Foto' : 'Selecionar Foto',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const FincoreFieldLabel(label: 'NOME DO PRODUTO', isRequired: true),
          FincoreTextField(
            controller: _nomeCtrl,
            hintText: 'Ex: Coxinha de Frango com Catupiry',
            validator: FincoreValidators.required,
          ),
          const SizedBox(height: 12),

          const FincoreFieldLabel(label: 'CATEGORIA DO PRODUTO', isRequired: true),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: (_selectedCategoriaId != null && _categorias.any((c) => c.id == _selectedCategoriaId)) ? _selectedCategoriaId : null,
            dropdownColor: FincoreColors.surface,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedCategoriaId = v;
                if (_herdarCategoria) _applyCategoryInheritanceDefaults(v);
              });
            },
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const FincoreFieldLabel(label: 'SKU DO PRODUTO'),
              InkWell(
                onTap: _generateAutoSku,
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 12, color: FincoreColors.primary),
                    const SizedBox(width: 2),
                    Text('Regerar', style: TextStyle(fontSize: 11, color: FincoreColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          FincoreTextField(controller: _skuCtrl, hintText: 'Ex: SKU-COX-01'),
          const SizedBox(height: 12),

          const FincoreFieldLabel(label: 'DESCRIÇÃO COMERCIAL'),
          FincoreTextField(controller: _descricaoCtrl, hintText: 'Descrição dos ingredientes do salgado'),
          const SizedBox(height: 12),

          const FincoreFieldLabel(label: 'CÓDIGO DE BARRAS (EAN-13)'),
          FincoreTextField(controller: _codigoBarrasCtrl, hintText: '7891234567890'),
          const SizedBox(height: 12),

          const FincoreFieldLabel(label: 'STATUS DO PRODUTO'),
          Row(
            children: [
              Switch(value: _ativo, activeColor: FincoreColors.primary, onChanged: (v) => setState(() => _ativo = v)),
              const SizedBox(width: 6),
              Text(_ativo ? 'ATIVO' : 'INATIVO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ativo ? FincoreColors.success : FincoreColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabComercial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FincoreFieldLabel(label: 'PREÇO BASE DE VENDA (EM CENTAVOS / R\$)'),
          FincoreTextField(controller: _precoBaseCtrl, hintText: 'Ex: 500 para R\$ 5,00', enabled: !_herdarCategoria),
          const SizedBox(height: 12),
          const FincoreFieldLabel(label: 'ESTRATÉGIA DE COMERCIALIZAÇÃO'),
          DropdownButtonFormField<EstrategiaComercializacao>(
            isExpanded: true,
            value: _estrategia,
            dropdownColor: FincoreColors.surface,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: EstrategiaComercializacao.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: _herdarCategoria ? null : (v) {
              if (v != null) setState(() => _estrategia = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabProducao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FincoreFieldLabel(label: 'TEMPO MÉDIO DE PREPARO (MINUTOS)'),
          FincoreTextField(controller: _tempoCtrl, hintText: '30 min', enabled: !_herdarCategoria),
          const SizedBox(height: 12),
          const FincoreFieldLabel(label: 'SETOR DE IMPRESSÃO / ROTA KDS'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: ['Cozinha', 'Balcao', 'Producao', 'Expedicao'].contains(_setorImpressao) ? _setorImpressao : 'Cozinha',
            dropdownColor: FincoreColors.surface,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: const [
              DropdownMenuItem(value: 'Cozinha', child: Text('Cozinha', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Balcao', child: Text('Balcão', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Producao', child: Text('Produção', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Expedicao', child: Text('Expedição', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _herdarCategoria ? null : (v) {
              if (v != null) setState(() => _setorImpressao = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabEstoque() {
    final est = _selectedProduto != null ? _estoqueMap[_selectedProduto!.id] : null;
    final int fisico = est?.quantidadeAtual ?? 0;
    final int reservado = est?.quantidadeReservada ?? 0;
    final int disponivel = fisico - reservado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: _controlaEstoque,
                activeColor: FincoreColors.primary,
                onChanged: _herdarCategoria ? null : (v) => setState(() => _controlaEstoque = v),
              ),
              const SizedBox(width: 8),
              const Text('Controlar Estoque Físico', style: TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),

          if (_controlaEstoque && _selectedProduto != null) ...[
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
                  const Text('VISÃO DE ESTOQUE EM TEMPO REAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: Column(
                            children: [
                              const Text('Físico (Freezer)', style: TextStyle(fontSize: 10, color: Colors.blue)),
                              const SizedBox(height: 2),
                              Text('$fisico un', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: Column(
                            children: [
                              const Text('Reservado', style: TextStyle(fontSize: 10, color: Colors.amber)),
                              const SizedBox(height: 2),
                              Text('$reservado un', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (disponivel >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text('Disponível', style: TextStyle(fontSize: 10, color: disponivel >= 0 ? Colors.green : Colors.red)),
                              const SizedBox(height: 2),
                              Text('$disponivel un', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: disponivel >= 0 ? Colors.green : Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'ESTOQUE MÍNIMO'),
                    FincoreTextField(controller: _estoqueMinCtrl, hintText: '10', enabled: !_herdarCategoria && _controlaEstoque),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'ESTOQUE MÁXIMO'),
                    FincoreTextField(controller: _estoqueMaxCtrl, hintText: '500', enabled: !_herdarCategoria && _controlaEstoque),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabFiscal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FincoreFieldLabel(label: 'NCM (NOMENCLATURA COMUM DO MERCOSUL)'),
          FincoreTextField(controller: _ncmCtrl, hintText: '2106.90.90', enabled: !_herdarCategoria),
          const SizedBox(height: 12),
          const FincoreFieldLabel(label: 'CEST (CÓDIGO ESPECIFICADOR DA SUBSTITUIÇÃO TRIBUTÁRIA)'),
          FincoreTextField(controller: _cestCtrl, hintText: '17.008.00', enabled: !_herdarCategoria),
        ],
      ),
    );
  }

  Widget _buildTabDelivery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(value: _canalDeliveryApp, activeColor: FincoreColors.primary, onChanged: _herdarCategoria ? null : (v) => setState(() => _canalDeliveryApp = v)),
              const SizedBox(width: 8),
              const Text('Ativo no Aplicativo de Delivery', style: TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(value: _canalWhatsApp, activeColor: FincoreColors.primary, onChanged: _herdarCategoria ? null : (v) => setState(() => _canalWhatsApp = v ?? false)),
              const Text('Disponível no WhatsApp', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
              const SizedBox(width: 16),
              Checkbox(value: _canaliFood, activeColor: FincoreColors.primary, onChanged: _herdarCategoria ? null : (v) => setState(() => _canaliFood = v ?? false)),
              const Text('Disponível no iFood', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}



