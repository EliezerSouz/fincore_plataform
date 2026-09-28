import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/presentation/validators/fincore_validators.dart';
import 'package:fincore_food_flutter/src/shared/services/commercial_pricing_engine.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/audit_timeline_panel.dart';
import 'package:uuid/uuid.dart';

/// Tela de Gerenciamento de Políticas Comerciais Versionadas & Laboratório Comercial (Commercial Sandbox)
class PoliticasPrecoView extends StatefulWidget {
  final VoidCallback? onChanged;
  const PoliticasPrecoView({super.key, this.onChanged});

  @override
  State<PoliticasPrecoView> createState() => _PoliticasPrecoViewState();
}

class _PoliticasPrecoViewState extends State<PoliticasPrecoView> with SingleTickerProviderStateMixin {
  late final TabelaPrecificacaoRepository _tabelaRepo;
  late final ItemTabelaPrecificacaoRepository _itemRepo;
  late final ProdutoTabelaPrecificacaoRepository _assocRepo;
  late final ProdutoRepository _produtoRepo;

  List<TabelaPrecificacao> _tabelas = [];
  List<Produto> _produtos = [];
  Map<String, int> _politicaProdsCountMap = {};
  TabelaPrecificacao? _selectedTabela;
  bool _isInspectorOpen = false;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  late final TabController _rightTabController;

  // Form
  final _politicaFormKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _prioridadeCtrl = TextEditingController();
  PricingPolicyType _tipo = PricingPolicyType.faixaQuantidade;
  bool _ativo = true;
  int _versaoAtual = 1;

  List<_TempFaixa> _tempFaixas = [];
  Set<String> _associatedProductIds = {};

  // Commercial Sandbox Context
  final Map<String, TextEditingController> _simulatedControllers = {};
  PerfilCliente _selectedPerfilCliente = PerfilCliente.pessoaFisica;
  CanalVenda _selectedCanalVenda = CanalVenda.pdvBalcao;
  double _cupomDesconto = 0.0;

  @override
  void initState() {
    super.initState();
    _rightTabController = TabController(length: 2, vsync: this);
    _tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>();
    _itemRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>();
    _assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>();
    _produtoRepo = DependencyInjection().get<ProdutoRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _rightTabController.dispose();
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _prioridadeCtrl.dispose();
    for (final ctrl in _simulatedControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData({String? selectTabelaId}) async {
    try {
      final tabs = await _tabelaRepo.findAll();
      final prods = await _produtoRepo.findAll();
      final assocs = await _assocRepo.findAll();

      final Map<String, int> counts = {};
      for (final a in assocs) {
        counts[a.tabelaPrecificacaoId] = (counts[a.tabelaPrecificacaoId] ?? 0) + 1;
      }
      
      // Encontra a tabela a ser selecionada
      TabelaPrecificacao? targetTabela;
      if (selectTabelaId != null) {
        targetTabela = tabs.cast<TabelaPrecificacao?>().firstWhere((t) => t?.id == selectTabelaId, orElse: () => null);
      }
      
      setState(() {
        _tabelas = tabs;
        _produtos = prods;
        _politicaProdsCountMap = counts;
        if (targetTabela != null) {
          _selectTabela(targetTabela, abrirPainel: _isInspectorOpen);
        } else if (_tabelas.isNotEmpty && _selectedTabela == null) {
          _selectedTabela = _tabelas.first;
        } else if (_selectedTabela == null) {
          _selectedTabela = null;
        } else {
          // Atualiza a tabela selecionada atualmente se ela ainda existir
          final refreshed = _tabelas.cast<TabelaPrecificacao?>().firstWhere((t) => t?.id == _selectedTabela!.id, orElse: () => null);
          if (refreshed != null) {
            _selectedTabela = refreshed;
          } else if (_tabelas.isNotEmpty) {
            _selectedTabela = _tabelas.first;
          } else {
            _selectedTabela = null;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar políticas comerciais: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTabela(TabelaPrecificacao? tabela, {bool abrirPainel = false, int initialTabIndex = 0}) async {
    if (tabela == null) {
      setState(() {
        _selectedTabela = null;
        _isInspectorOpen = true; // Novo abre inspector sempre
        _isEditing = true;
        _nomeCtrl.text = 'Mini Salgados Tradicionais (Política Comercial)';
        _descricaoCtrl.text = 'Preço por faixa de quantidade acumulada do lote';
        _prioridadeCtrl.text = '1';
        _tipo = PricingPolicyType.faixaQuantidade;
        _ativo = true;
        _versaoAtual = 1;
        _tempFaixas = [
          const _TempFaixa(id: 'fx1', minima: 25, maxima: 25, valorCentavos: 150),
          const _TempFaixa(id: 'fx2', minima: 26, maxima: 49, valorCentavos: 145),
          const _TempFaixa(id: 'fx3', minima: 50, maxima: 99, valorCentavos: 140),
          const _TempFaixa(id: 'fx4', minima: 100, maxima: 9999, valorCentavos: 130),
        ];
        _associatedProductIds = _produtos.take(4).map((p) => p.id).toSet();
        _resetSimulation();
      });
      return;
    }

    try {
      final itens = await _itemRepo.findByTabelaId(tabela.id);
      final temp = itens.map((item) {
        return _TempFaixa(
          id: item.id,
          minima: item.quantidadeMinima,
          maxima: item.quantidadeMaxima,
          valorCentavos: item.valorUnitarioCentavos,
        );
      }).toList();

      temp.sort((a, b) => a.minima.compareTo(b.minima));

      final assocs = await _assocRepo.findAll();
      final productIds = assocs
          .where((a) => a.tabelaPrecificacaoId == tabela.id && a.ativo)
          .map((a) => a.produtoId)
          .toSet();

      try {
        final catAssocRepo = DependencyInjection().get<CategoriaTabelaPrecificacaoRepository>();
        final catAssocs = (await catAssocRepo.findAll()).where((a) => a.tabelaPrecificacaoId == tabela.id && a.ativo).toList();
        final catIds = catAssocs.map((a) => a.categoriaId).toSet();
        if (catIds.isNotEmpty) {
          final implicitProductIds = _produtos
              .where((p) => catIds.contains(p.categoriaId))
              .map((p) => p.id)
              .toSet();
          productIds.addAll(implicitProductIds);
        }
      } catch (e) {
        debugPrint('Erro ao carregar associações de categoria para tabela: $e');
      }

      if (!mounted) return;
      setState(() {
        _selectedTabela = tabela;
        _isInspectorOpen = abrirPainel;
        if (abrirPainel && initialTabIndex < _rightTabController.length) {
          _rightTabController.animateTo(initialTabIndex);
        }
        _isEditing = false;
        _nomeCtrl.text = tabela.nome;
        _descricaoCtrl.text = tabela.descricao;
        _prioridadeCtrl.text = tabela.prioridade.toString();
        _tipo = tabela.tipoPolitica;
        _ativo = tabela.ativo;
        _versaoAtual = 1;
        _tempFaixas = temp;
        _associatedProductIds = productIds;
        _resetSimulation();
      });
    } catch (e) {
      debugPrint('Erro ao selecionar tabela: $e');
    }
  }

  void _resetSimulation() {
    for (final ctrl in _simulatedControllers.values) {
      ctrl.dispose();
    }
    _simulatedControllers.clear();

    final salgados = _produtos.where((p) => _associatedProductIds.contains(p.id)).toList();
    if (salgados.length >= 4) {
      _simulatedControllers[salgados[0].id] = TextEditingController(text: '10');
      _simulatedControllers[salgados[1].id] = TextEditingController(text: '5');
      _simulatedControllers[salgados[2].id] = TextEditingController(text: '5');
      _simulatedControllers[salgados[3].id] = TextEditingController(text: '5');
    } else {
      for (final p in salgados) {
        _simulatedControllers[p.id] = TextEditingController(text: '10');
      }
    }
  }

  void _adicionarFaixa() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _FaixaDialog(),
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          _tempFaixas.add(_TempFaixa(
            id: const Uuid().v4(),
            minima: result['minima'],
            maxima: result['maxima'],
            valorCentavos: result['valorCentavos'],
          ));
          _tempFaixas.sort((a, b) => a.minima.compareTo(b.minima));
        });
      }
    });
  }

  void _excluirFaixa(int index) {
    setState(() => _tempFaixas.removeAt(index));
  }

  void _editarFaixa(int index) {
    final fx = _tempFaixas[index];
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _FaixaDialog(
        initialMin: fx.minima,
        initialMax: fx.maxima,
        initialValor: fx.valorCentavos / 100.0,
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          _tempFaixas[index] = _TempFaixa(
            id: fx.id,
            minima: result['minima'],
            maxima: result['maxima'],
            valorCentavos: result['valorCentavos'],
          );
          _tempFaixas.sort((a, b) => a.minima.compareTo(b.minima));
        });
      }
    });
  }

  void _toggleProduct(String produtoId) {
    setState(() {
      if (_associatedProductIds.contains(produtoId)) {
        _associatedProductIds.remove(produtoId);
      } else {
        _associatedProductIds.add(produtoId);
      }
    });
  }

  Future<void> _salvar() async {
    if (!_politicaFormKey.currentState!.validate()) return;
    if (_tempFaixas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos uma faixa de preço.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = _selectedTabela == null;
      final tabelaId = isNew ? const Uuid().v4() : _selectedTabela!.id;

      final tabela = TabelaPrecificacao(
        id: tabelaId,
        tenantId: tenantCtx.tenantId,
        nome: _nomeCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        tipoPolitica: _tipo,
        prioridade: int.tryParse(_prioridadeCtrl.text) ?? 1,
        ativo: _ativo,
        metadata: _selectedTabela?.metadata.copyWith(
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

      await _tabelaRepo.save(tabela);

      // --- PERSISTÊNCIA DAS FAIXAS DE PREÇO (ITENS) ---
      // 1. Limpar faixas antigas da tabela
      final existingItems = await _itemRepo.findByTabelaId(tabelaId);
      for (final item in existingItems) {
        await _itemRepo.delete(item.id);
      }

      // 2. Persistir novas faixas
      for (int i = 0; i < _tempFaixas.length; i++) {
        final tf = _tempFaixas[i];
        final item = ItemTabelaPrecificacao(
          id: tf.id.startsWith('fx') ? const Uuid().v4() : tf.id,
          tenantId: tenantCtx.tenantId,
          tabelaPrecificacaoId: tabelaId,
          quantidadeMinima: tf.minima,
          quantidadeMaxima: tf.maxima,
          valorUnitarioCentavos: tf.valorCentavos,
          ordem: i + 1,
          metadata: SyncMetadata(
            version: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            createdBy: tenantCtx.usuario.id,
            updatedBy: tenantCtx.usuario.id,
            syncStatus: SyncStatus.pending,
          ),
        );
        await _itemRepo.save(item);
      }

      // --- PERSISTÊNCIA DAS ASSOCIAÇÕES DE PRODUTO ---
      // 1. Limpar associações antigas desta tabela
      final allAssocs = await _assocRepo.findAll();
      final existingAssocs = allAssocs.where((a) => a.tabelaPrecificacaoId == tabelaId).toList();
      for (final assoc in existingAssocs) {
        await _assocRepo.delete(assoc.id);
      }

      // 2. Persistir novas associações
      for (final prodId in _associatedProductIds) {
        final assoc = ProdutoTabelaPrecificacao(
          id: const Uuid().v4(),
          tenantId: tenantCtx.tenantId,
          produtoId: prodId,
          tabelaPrecificacaoId: tabelaId,
          ativo: true,
          prioridade: 0,
          metadata: SyncMetadata(
            version: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            createdBy: tenantCtx.usuario.id,
            updatedBy: tenantCtx.usuario.id,
            syncStatus: SyncStatus.pending,
          ),
        );
        await _assocRepo.save(assoc);
      }

      await _loadData(selectTabelaId: tabelaId);
      widget.onChanged?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Política comercial e faixas salvas com sucesso!'),
          backgroundColor: FincoreColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar política: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar política: $e'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _excluirTabela(TabelaPrecificacao tabela) async {
    final prodsCount = _politicaProdsCountMap[tabela.id] ?? 0;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Excluir Política Comercial?', style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja excluir a política comercial "${tabela.nome}"?', style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
            if (prodsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta política possui $prodsCount produto(s) vinculado(s). A exclusão desvinculará estes produtos.',
                        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Política', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final items = await _itemRepo.findByTabelaId(tabela.id);
      for (final item in items) {
        await _itemRepo.delete(item.id);
      }
      final assocs = (await _assocRepo.findAll()).where((a) => a.tabelaPrecificacaoId == tabela.id).toList();
      final affectedProductIds = assocs.map((a) => a.produtoId).toList();
      final affectedProductNames = _produtos.where((p) => affectedProductIds.contains(p.id)).map((p) => p.nome).toList();

      for (final assoc in assocs) {
        await _assocRepo.delete(assoc.id);
      }
      await _tabelaRepo.delete(tabela.id);

      // AUDIT LOG COM CONTEXTO E IMPACTO CORPORATIVO ENRIQUECIDO
      try {
        final auditRepo = DependencyInjection().get<AuditLogRepository>();
        final tenantCtx = DependencyInjection().get<TenantContext>();
        await auditRepo.log(
          entityName: 'PoliticaComercial',
          entityId: tabela.id,
          userId: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          action: 'DELETE',
          entityDisplayName: tabela.nome,
          entityModule: 'Produtos',
          diff: {
            '_summary': 'Política Comercial "${tabela.nome}" excluída com faixas e associações',
            '_affectedRecords': affectedProductNames.length,
            '_relatedEntities': affectedProductNames,
            'nome': tabela.nome,
            'descricao': tabela.descricao,
            'faixasCount': items.length,
            'produtosAfetadosCount': affectedProductNames.length,
          },
        );
      } catch (_) {}

      setState(() {
        _isInspectorOpen = false;
        _isEditing = false;
        _selectedTabela = null;
      });
      await _loadData();
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Política "${tabela.nome}" excluída com sucesso.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  String _searchQuery = '';

  List<TabelaPrecificacao> get _filteredTabelas {
    if (_searchQuery.isEmpty) return _tabelas;
    final q = _searchQuery.toLowerCase();
    return _tabelas.where((t) => t.nome.toLowerCase().contains(q) || t.descricao.toLowerCase().contains(q)).toList();
  }

  Widget _buildMetricBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
    );
  }

  Widget _buildPolicyCard(TabelaPrecificacao tab) {
    final prodsCount = _politicaProdsCountMap[tab.id] ?? 0;
    final isSelected = _selectedTabela?.id == tab.id && _isInspectorOpen;

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
          // Top Row: Prioridade + Badge de Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRIORIDADE P${tab.prioridade}',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tab.ativo ? FincoreColors.success.withValues(alpha: 0.15) : FincoreColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab.ativo ? '● ATIVA' : '● INATIVA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: tab.ativo ? FincoreColors.success : FincoreColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nome da Política
          Text(
            tab.nome,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Descrição Comercial posicionada logo após o nome
          if (tab.descricao.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              tab.descricao,
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
                Expanded(child: _buildCardMetricCol('Tipo', 'Faixas Vol.', FincoreColors.textPrimary)),
                Expanded(child: _buildCardMetricCol('Produtos', '$prodsCount', FincoreColors.textSecondary)),
                Expanded(child: _buildCardMetricCol('Versão', 'v1.0', FincoreColors.textSecondary)),
                Expanded(child: _buildCardMetricCol('Status', 'Vigente', FincoreColors.success)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Ações do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _selectTabela(tab, abrirPainel: true),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: FincoreColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Painel', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  await _selectTabela(tab, abrirPainel: false);
                  setState(() => _isEditing = true);
                },
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, size: 14, color: FincoreColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Editar', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openSandboxModal(tab),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, size: 14, color: FincoreColors.primary),
                    const SizedBox(width: 4),
                    Text('Sandbox', style: TextStyle(fontSize: 11.5, color: FincoreColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSandboxModal(TabelaPrecificacao tabela) async {
    await _selectTabela(tabela, abrirPainel: false);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final salgados = _produtos.where((p) => _associatedProductIds.contains(p.id)).toList();
          final itemsCotacao = salgados.map((p) {
            _simulatedControllers.putIfAbsent(p.id, () => TextEditingController(text: '10'));
            final q = double.tryParse(_simulatedControllers[p.id]!.text) ?? 0.0;
            return ItemCotacao(
              produtoId: p.id,
              nomeProduto: p.nome,
              quantidade: q,
              precoUnitarioBase: 1.50,
            );
          }).toList();

          final policyModel = PoliticaComercialModel(
            id: tabela.id,
            nome: tabela.nome,
            descricao: tabela.descricao,
            prioridade: tabela.prioridade,
            faixas: _tempFaixas.map((f) => FaixaPrecificacaoModel(
              id: f.id,
              quantidadeMinima: f.minima.toDouble(),
              quantidadeMaxima: f.maxima?.toDouble(),
              precoUnitario: f.valorCentavos / 100.0,
            )).toList(),
            produtosParticipantesIds: _associatedProductIds,
          );

          final result = CommercialPricingEngine.instance.calculatePolicyQuote(
            policy: policyModel,
            items: itemsCotacao,
            perfilCliente: _selectedPerfilCliente,
            canalVenda: _selectedCanalVenda,
            cupomDescontoPercentual: _cupomDesconto,
          );

          return AlertDialog(
            backgroundColor: FincoreColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FincoreColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.science_outlined, color: FincoreColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Laboratório Commercial Sandbox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Política: ${tabela.nome}', style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                ),
              ],
            ),
            content: SizedBox(
              width: 720,
              height: MediaQuery.of(context).size.height * 0.75,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FincoreFieldLabel(label: 'PERFIL DO CLIENTE'),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<PerfilCliente>(
                                value: _selectedPerfilCliente,
                                dropdownColor: FincoreColors.surface,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: FincoreColors.background,
                                ),
                                items: PerfilCliente.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => _selectedPerfilCliente = v);
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FincoreFieldLabel(label: 'CANAL DE VENDA'),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<CanalVenda>(
                                value: _selectedCanalVenda,
                                dropdownColor: FincoreColors.surface,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: FincoreColors.background,
                                ),
                                items: CanalVenda.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => _selectedCanalVenda = v);
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('1. Digitar Quantidades do Pedido no Sandbox', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        children: List.generate(salgados.length, (idx) {
                          final p = salgados[idx];
                          _simulatedControllers.putIfAbsent(p.id, () => TextEditingController(text: '10'));
                          final ctrl = _simulatedControllers[p.id]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(p.nome, style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold)),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: FincoreColors.textSecondary),
                                      onPressed: () {
                                        final q = int.tryParse(ctrl.text) ?? 0;
                                        if (q > 0) {
                                          ctrl.text = (q - 1).toString();
                                          setModalState(() {});
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 64,
                                      height: 38,
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onChanged: (_) {
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline, size: 20, color: FincoreColors.primary),
                                      onPressed: () {
                                        final q = int.tryParse(ctrl.text) ?? 0;
                                        ctrl.text = (q + 1).toString();
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text('2. Painel de Explicabilidade (Trilha do Pricing Engine)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology_outlined, color: FincoreColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.explicacao.resumoRegra,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: FincoreColors.border),
                          Column(
                            children: result.explicacao.passos.map((passo) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      passo.foiAplicado ? Icons.check_circle_outline : Icons.cancel_outlined,
                                      size: 16,
                                      color: passo.foiAplicado ? FincoreColors.success : FincoreColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(passo.titulo, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: passo.foiAplicado ? FincoreColors.textPrimary : FincoreColors.textMuted)),
                                          Text(passo.detalhe, style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FincoreColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FincoreColors.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VALOR TOTAL SIMULADO:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                              Text('Calculado pelo Commercial Pricing Engine', style: TextStyle(fontSize: 10, color: FincoreColors.textSecondary)),
                            ],
                          ),
                          Text(
                            'R\$ ${result.valorTotalGrupo.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FincoreColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

    final total = _tabelas.length;
    final ativas = _tabelas.where((t) => t.ativo).length;
    final prodsComPolitica = _politicaProdsCountMap.values.fold(0, (a, b) => a + b);

    return Stack(
      children: [
        // ── Grid Operacional Principal em Largura Total ──────────────────
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pílulas de Estatísticas no Topo
              Row(
                children: [
                  _buildMetricBadge('Políticas Comerciais: $total', FincoreColors.primary.withValues(alpha: 0.15), FincoreColors.primary),
                  const SizedBox(width: 8),
                  _buildMetricBadge('Políticas Ativas: $ativas', FincoreColors.success.withValues(alpha: 0.15), FincoreColors.success),
                  const SizedBox(width: 8),
                  _buildMetricBadge('Produtos Vinculados: $prodsComPolitica', FincoreColors.accent.withValues(alpha: 0.15), FincoreColors.accent),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Pesquisa + Botão "+ Nova Política"
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
                                setState(() => _searchQuery = val);
                              },
                              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Pesquisar política comercial...',
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
                    onPressed: () => _selectTabela(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_card_outlined, size: 16, color: Colors.white),
                    label: const Text('Nova Política', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Grid Operacional de Cards
              Expanded(
                child: _filteredTabelas.isEmpty
                    ? const Center(child: Text('Nenhuma política comercial encontrada.', style: TextStyle(color: FincoreColors.textMuted)))
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
                            itemCount: _filteredTabelas.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (ctx, idx) {
                              final tab = _filteredTabelas[idx];
                              return _buildPolicyCard(tab);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // ── Drawer Lateral de Inspector (quando aberto) ────────────────────
        if (_isInspectorOpen && !_isEditing && _selectedTabela != null) ...[
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
                title: _selectedTabela!.nome,
                subtitle: 'Regras de Precificação e Laboratório Sandbox',
                onEdit: () => setState(() => _isEditing = true),
                onDelete: () => _excluirTabela(_selectedTabela!),
                onClose: () {
                  setState(() {
                    _isInspectorOpen = false;
                    _selectedTabela = null;
                  });
                },
                child: _buildRightPanel(),
              ),
            ),
          ),
        ],

        // ── Modal Dialog de Edição Centralizado ─────────────────────────
        if (_isEditing) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isEditing = false),
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
                  title: _selectedTabela == null ? 'Nova Política' : _selectedTabela!.nome,
                  subtitle: null,
                  onClose: () => setState(() => _isEditing = false),
                  child: _buildRightPanel(),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _tabelas.isEmpty
                ? const Center(child: Text('Nenhuma política cadastrada.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tabelas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final tab = _tabelas[idx];
                      final isSelected = _selectedTabela?.id == tab.id;
                      final linkedProds = _politicaProdsCountMap[tab.id] ?? 0;

                      return InkWell(
                        onTap: () => _selectTabela(tab, abrirPainel: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? FincoreColors.primary.withValues(alpha: 0.1) : FincoreColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? FincoreColors.primary : FincoreColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: FincoreColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.gavel_outlined, color: FincoreColors.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          tab.nome,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: FincoreColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('v$_versaoAtual', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$linkedProds produtos vinculados • ${tab.descricao.isEmpty ? "Precificação por faixa acumulada" : tab.descricao}',
                                      style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tab.ativo ? FincoreColors.success.withValues(alpha: 0.15) : FincoreColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tab.ativo ? 'ATIVA' : 'INATIVA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tab.ativo ? FincoreColors.success : FincoreColors.textMuted,
                                  ),
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

  Widget _buildRightPanel() {
    final isNew = _selectedTabela == null;

    if (!_isEditing) {
      // MODO INSPECTOR
      final prodCount = _politicaProdsCountMap[_selectedTabela?.id ?? ''] ?? 0;
      final salgados = _produtos.where((p) => _associatedProductIds.contains(p.id)).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações Gerais
            _buildInspectorSectionTitle('Informações Gerais'),
            _buildInspectorDetailRow('Nome', _selectedTabela?.nome ?? '--'),
            _buildInspectorDetailRow('Descrição', _selectedTabela?.descricao == null || _selectedTabela!.descricao.isEmpty ? 'Sem descrição.' : _selectedTabela!.descricao),
            _buildInspectorDetailRow('Prioridade de Aplicação', _selectedTabela?.prioridade.toString() ?? '1'),
            _buildInspectorDetailRow('Tipo de Política', _tipo.name.toUpperCase()),
            _buildInspectorDetailRow('Status', _ativo ? 'ATIVA' : 'INATIVA'),

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Faixas de Preço Ativas
            _buildInspectorSectionTitle('Faixas de Preço (v$_versaoAtual)'),
            if (_tempFaixas.isEmpty)
              const Text('Nenhuma faixa de preço definida.', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted))
            else ...[
              Builder(
                builder: (context) {
                  final baseCentavos = _tempFaixas.isNotEmpty ? _tempFaixas.first.valorCentavos : 0;
                  return Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(2.5),
                      2: FlexColumnWidth(3.0),
                      3: FlexColumnWidth(2.5),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Qtd Mínima', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Qtd Máxima', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Valor Unitário', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Desconto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        ],
                      ),
                      for (int i = 0; i < _tempFaixas.length; i++) ...[
                        () {
                          final f = _tempFaixas[i];
                          final discountPct = baseCentavos > 0 && f.valorCentavos < baseCentavos
                              ? (((baseCentavos - f.valorCentavos) / baseCentavos) * 100).round()
                              : 0;

                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${f.minima} un', style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(f.maxima == null || f.maxima! >= 9999 ? '∞' : '${f.maxima} un', style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('R\$ ${(f.valorCentavos / 100).toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.primary))),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: discountPct > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.success.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$discountPct% OFF',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.success),
                                        ),
                                      )
                                    : Text(i == 0 ? 'Base' : '-', style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                              ),
                            ],
                          );
                        }(),
                      ],
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            // Produtos Associados
            _buildInspectorSectionTitle('Produtos Vinculados ($prodCount)'),
            if (salgados.isEmpty)
              const Text('Nenhum produto vinculado a esta política.', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: salgados.map((p) {
                  return Chip(
                    label: Text(p.nome, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: FincoreColors.background,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                label: const Text('Editar Política Comercial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        TabBar(
          controller: _rightTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: FincoreColors.primary,
          labelColor: FincoreColors.primary,
          unselectedLabelColor: FincoreColors.textMuted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Regras & Faixas de Preço'),
            Tab(text: '⚡ Commercial Sandbox'),
          ],
        ),
        const Divider(height: 1, color: FincoreColors.border),

        Expanded(
          child: TabBarView(
            controller: _rightTabController,
            children: [
              _buildTabRegrasEFaixas(),
              _buildTabSimuladorComercial(),
            ],
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
                        _selectTabela(_selectedTabela);
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
                    if (!_politicaFormKey.currentState!.validate()) return;
                    if (_tempFaixas.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adicione ao menos uma faixa de preço.')),
                      );
                      return;
                    }
                    await _salvar();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                  child: const Text('Salvar Nova Versão', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabRegrasEFaixas() {
    final faixasModels = _tempFaixas.map((f) => FaixaPrecificacaoModel(
      id: f.id,
      quantidadeMinima: f.minima.toDouble(),
      quantidadeMaxima: f.maxima?.toDouble(),
      precoUnitario: f.valorCentavos / 100.0,
    )).toList();

    final alertas = CommercialPricingEngine.instance.validateFaixas(faixasModels);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _politicaFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alertas.isNotEmpty) ...[
              Column(
                children: alertas.map((alerta) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alerta.isErro ? FincoreColors.danger.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: alerta.isErro ? FincoreColors.danger : Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(alerta.isErro ? Icons.warning_amber_rounded : Icons.info_outline, color: alerta.isErro ? FincoreColors.danger : Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alerta.mensagem,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: alerta.isErro ? FincoreColors.danger : Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // ══════════════════════════════════════════════════════
            // CARD 1 — IDENTIFICAÇÃO DA POLÍTICA
            // ══════════════════════════════════════════════════════
            _buildFormCard(
              label: 'Identificação da Política',
              icon: Icons.label_outline,
              children: [
                const FincoreFieldLabel(label: 'NOME DA POLÍTICA COMERCIAL', isRequired: true),
                FincoreTextField(
                  controller: _nomeCtrl,
                  hintText: 'Ex: Mini Salgados Tradicionais (Lote)',
                  validator: FincoreValidators.required,
                ),
                const SizedBox(height: 12),
                const FincoreFieldLabel(label: 'DESCRIÇÃO DA REGRA'),
                FincoreTextField(
                  controller: _descricaoCtrl,
                  hintText: 'Ex: Aplica preço por faixa de quantidade acumulada de coxinha, kibe e salgados',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'PRIORIDADE DE APLICAÇÃO'),
                          FincoreTextField(controller: _prioridadeCtrl, hintText: '1', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'STATUS DA POLÍTICA'),
                          Row(
                            children: [
                              Switch(
                                value: _ativo,
                                activeColor: FincoreColors.primary,
                                onChanged: (v) => setState(() => _ativo = v),
                              ),
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
            const SizedBox(height: 12),

            // ══════════════════════════════════════════════════════
            // CARD 2 — FAIXAS & PRODUTOS VINCULADOS
            // ══════════════════════════════════════════════════════
            _buildFormCard(
              label: 'Faixas & Produtos Vinculados',
              icon: Icons.inventory_2_outlined,
              trailing: ElevatedButton.icon(
                onPressed: _adicionarFaixa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.primary.withValues(alpha: 0.15),
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(Icons.add, size: 14, color: FincoreColors.primary),
                label: Text('Add Faixa', style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              children: [
                const SizedBox(height: 6),
                _buildFaixasTable(),
                const SizedBox(height: 16),
                const FincoreFieldLabel(label: 'PRODUTOS PARTICIPANTES DESTA POLÍTICA (RELACIONAMENTO N:N)'),
                const SizedBox(height: 8),
                _buildProductsCheckboxList(),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFaixasTable() {
    if (_tempFaixas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FincoreColors.border),
        ),
        child: const Center(
          child: Text('Nenhuma faixa de preço cadastrada.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        children: List.generate(_tempFaixas.length, (idx) {
          final fx = _tempFaixas[idx];
          final text = fx.maxima == null || fx.maxima! >= 9999 ? 'ou mais' : 'até ${fx.maxima}';
          final precoFormatado = (fx.valorCentavos / 100).toStringAsFixed(2);
          final baseCentavos = _tempFaixas.isNotEmpty ? _tempFaixas.first.valorCentavos : 0;
          final discountPct = baseCentavos > 0 && fx.valorCentavos < baseCentavos
              ? (((baseCentavos - fx.valorCentavos) / baseCentavos) * 100).round()
              : 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: idx < _tempFaixas.length - 1 ? const Border(bottom: BorderSide(color: FincoreColors.border)) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('De ${fx.minima} $text un', style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary, fontWeight: FontWeight.w600)),
                ),
                if (discountPct > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FincoreColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$discountPct% OFF',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.success),
                    ),
                  ),
                ] else if (idx == 0) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: FincoreColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Base',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FincoreColors.textMuted),
                    ),
                  ),
                ],
                Text('R\$ $precoFormatado / un', style: TextStyle(fontSize: 12, color: FincoreColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: FincoreColors.textSecondary),
                  onPressed: () => _editarFaixa(idx),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: FincoreColors.danger),
                  onPressed: () => _excluirFaixa(idx),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductsCheckboxList() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _produtos.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
        itemBuilder: (ctx, idx) {
          final prod = _produtos[idx];
          final isChecked = _associatedProductIds.contains(prod.id);

          return CheckboxListTile(
            title: Text(prod.nome, style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
            subtitle: Text(prod.codigo ?? 'Sem código', style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
            value: isChecked,
            activeColor: FincoreColors.primary,
            dense: true,
            onChanged: (_) => _toggleProduct(prod.id),
          );
        },
      ),
    );
  }

  // ── ABA 2: COMMERCIAL SANDBOX COM TRILHA DE EXPLICABILIDADE ────────────────
  Widget _buildTabSimuladorComercial() {
    final faixasModel = _tempFaixas.map((f) => FaixaPrecificacaoModel(
      id: f.id,
      quantidadeMinima: f.minima.toDouble(),
      quantidadeMaxima: f.maxima?.toDouble(),
      precoUnitario: f.valorCentavos / 100.0,
    )).toList();

    final policyModel = PoliticaComercialModel(
      id: _selectedTabela?.id ?? 'temp_policy',
      nome: _nomeCtrl.text,
      descricao: _descricaoCtrl.text,
      versao: _versaoAtual,
      faixas: faixasModel,
      produtosParticipantesIds: _associatedProductIds,
    );

    final List<ItemCotacao> items = [];
    _simulatedControllers.forEach((prodId, ctrl) {
      final qty = double.tryParse(ctrl.text) ?? 0.0;
      if (qty > 0) {
        final prod = _produtos.cast<Produto?>().firstWhere((p) => p?.id == prodId, orElse: () => null);
        if (prod != null) {
          items.add(ItemCotacao(
            produtoId: prod.id,
            nomeProduto: prod.nome,
            quantidade: qty,
          ));
        }
      }
    });

    final result = CommercialPricingEngine.instance.calculatePolicyQuote(
      policy: policyModel,
      items: items,
      perfilCliente: _selectedPerfilCliente,
      canalVenda: _selectedCanalVenda,
      cupomDescontoPercentual: _cupomDesconto,
    );

    final salgados = _produtos.where((p) => _associatedProductIds.contains(p.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'PERFIL DO CLIENTE'),
                    DropdownButtonFormField<PerfilCliente>(
                      isExpanded: true,
                      value: _selectedPerfilCliente,
                      dropdownColor: FincoreColors.surface,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      items: PerfilCliente.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedPerfilCliente = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'CANAL DE VENDA'),
                    DropdownButtonFormField<CanalVenda>(
                      isExpanded: true,
                      value: _selectedCanalVenda,
                      dropdownColor: FincoreColors.surface,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      items: CanalVenda.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedCanalVenda = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('1. Digitar Quantidades do Pedido no Sandbox', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Column(
              children: List.generate(salgados.length, (idx) {
                final p = salgados[idx];
                _simulatedControllers.putIfAbsent(p.id, () => TextEditingController(text: '10'));
                final ctrl = _simulatedControllers[p.id]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(p.nome, style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: FincoreColors.textSecondary),
                            onPressed: () {
                              final q = int.tryParse(ctrl.text) ?? 0;
                              if (q > 0) {
                                setState(() => ctrl.text = (q - 1).toString());
                              }
                            },
                          ),
                          SizedBox(
                            width: 60,
                            height: 36,
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, size: 18, color: FincoreColors.primary),
                            onPressed: () {
                              final q = int.tryParse(ctrl.text) ?? 0;
                              setState(() => ctrl.text = (q + 1).toString());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Painel de Explicabilidade
          const Text('2. Painel de Explicabilidade (Trilha de Raciocínio do Motor)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_outlined, color: FincoreColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.explicacao.resumoRegra,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: FincoreColors.border),

                Column(
                  children: result.explicacao.passos.map((passo) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            passo.foiAplicado ? Icons.check_circle_outline : Icons.cancel_outlined,
                            size: 16,
                            color: passo.foiAplicado ? FincoreColors.success : FincoreColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(passo.titulo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: passo.foiAplicado ? FincoreColors.textPrimary : FincoreColors.textMuted)),
                                Text(passo.detalhe, style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Totalizador Final
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FincoreColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VALOR TOTAL DO PEDIDO:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                    Text('Calculado pelo Commercial Pricing Engine', style: TextStyle(fontSize: 10, color: FincoreColors.textSecondary)),
                  ],
                ),
                Text('R\$ ${result.valorTotalGrupo.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: FincoreColors.primary)),
              ],
            ),
          ),
        ],
      ),
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

class _TempFaixa {
  final String id;
  final int minima;
  final int? maxima;
  final int valorCentavos;

  const _TempFaixa({
    required this.id,
    required this.minima,
    required this.maxima,
    required this.valorCentavos,
  });
}

class _FaixaDialog extends StatefulWidget {
  final int? initialMin;
  final int? initialMax;
  final double? initialValor;

  const _FaixaDialog({this.initialMin, this.initialMax, this.initialValor});

  @override
  State<_FaixaDialog> createState() => _FaixaDialogState();
}

class _FaixaDialogState extends State<_FaixaDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _valorCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: widget.initialMin?.toString() ?? '25');
    _maxCtrl = TextEditingController(text: widget.initialMax?.toString() ?? '25');
    _valorCtrl = TextEditingController(text: widget.initialValor?.toStringAsFixed(2) ?? '1.50');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMin != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Faixa de Quantidade' : 'Adicionar Faixa de Quantidade', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FincoreTextField(controller: _minCtrl, label: 'QTD MÍNIMA', keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          FincoreTextField(controller: _maxCtrl, label: 'QTD MÁXIMA (OU DEIXE VAZIO)', keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          FincoreTextField(controller: _valorCtrl, label: 'PREÇO UNITÁRIO (R\$)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final min = int.tryParse(_minCtrl.text) ?? 1;
            final max = int.tryParse(_maxCtrl.text);
            final valDouble = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
            Navigator.pop(context, {
              'minima': min,
              'maxima': max,
              'valorCentavos': (valDouble * 100).round(),
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
          child: Text(isEditing ? 'Salvar' : 'Adicionar', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
