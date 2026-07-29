import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_pricing/common/pricing_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:uuid/uuid.dart';

/// Tela de Gerenciamento de Políticas de Preço (Lotes / Faixas de Quantidade)
/// Split View Premium: Lista à esquerda + Form de Edição à direita
class PoliticasPrecoView extends StatefulWidget {
  const PoliticasPrecoView({super.key});

  @override
  State<PoliticasPrecoView> createState() => _PoliticasPrecoViewState();
}

class _PoliticasPrecoViewState extends State<PoliticasPrecoView> {
  late final TabelaPrecificacaoRepository _tabelaRepo;
  late final ItemTabelaPrecificacaoRepository _itemRepo;
  late final ProdutoTabelaPrecificacaoRepository _assocRepo;
  late final ProdutoRepository _produtoRepo;

  List<TabelaPrecificacao> _tabelas = [];
  List<Produto> _produtos = [];
  TabelaPrecificacao? _selectedTabela;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers do Form
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _prioridadeCtrl = TextEditingController();
  PricingPolicyType _tipo = PricingPolicyType.faixaQuantidade;
  bool _ativo = true;

  // Faixas temporárias na memória durante edição
  List<_TempFaixa> _tempFaixas = [];
  // Lista de ID de produtos associados
  Set<String> _associatedProductIds = {};

  @override
  void initState() {
    super.initState();
    _tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>();
    _itemRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>();
    _assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>();
    _produtoRepo = DependencyInjection().get<ProdutoRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _prioridadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final tabs = await _tabelaRepo.findAll();
      final prods = await _produtoRepo.findAll();
      setState(() {
        _tabelas = tabs;
        _produtos = prods;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados de políticas: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTabela(TabelaPrecificacao? tabela) async {
    if (tabela == null) {
      setState(() {
        _selectedTabela = null;
        _nomeCtrl.clear();
        _descricaoCtrl.clear();
        _prioridadeCtrl.text = '1';
        _tipo = PricingPolicyType.faixaQuantidade;
        _ativo = true;
        _tempFaixas = [];
        _associatedProductIds = {};
      });
      return;
    }

    setState(() => _isSaving = true); // Bloqueia interações enquanto carrega subdados

    try {
      // 1. Carregar faixas/itens da tabela
      final itens = await _itemRepo.findByTabelaId(tabela.id);
      final temp = itens.map((item) {
        return _TempFaixa(
          id: item.id,
          minima: item.quantidadeMinima,
          maxima: item.quantidadeMaxima,
          valorCentavos: item.valorUnitarioCentavos,
        );
      }).toList();

      // Ordena as faixas por quantidade mínima
      temp.sort((a, b) => a.minima.compareTo(b.minima));

      // 2. Carregar produtos associados
      final assocs = await _assocRepo.findAll();
      final productIds = assocs
          .where((a) => a.tabelaPrecificacaoId == tabela.id && a.ativo)
          .map((a) => a.produtoId)
          .toSet();

      setState(() {
        _selectedTabela = tabela;
        _nomeCtrl.text = tabela.nome;
        _descricaoCtrl.text = tabela.descricao;
        _prioridadeCtrl.text = tabela.prioridade.toString();
        _tipo = tabela.tipoPolitica;
        _ativo = tabela.ativo;
        _tempFaixas = temp;
        _associatedProductIds = productIds;
        _isSaving = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar subdados da tabela: $e');
      setState(() => _isSaving = false);
    }
  }

  void _adicionarFaixa() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _FaixaDialog(),
    ).then((result) {
      if (result != null) {
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
    setState(() {
      _tempFaixas.removeAt(index);
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
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da política de precificação é obrigatório.')),
      );
      return;
    }

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

      // 1. Instanciar e salvar a Tabela de Precificação
      final tabela = TabelaPrecificacao(
        id: tabelaId,
        tenantId: tenantCtx.tenantId,
        nome: nome,
        descricao: _descricaoCtrl.text.trim(),
        tipoPolitica: _tipo,
        prioridade: int.tryParse(_prioridadeCtrl.text) ?? 1,
        ativo: _ativo,
        metadata: _selectedTabela?.metadata.copyWith(
              updatedAt: DateTime.now().toUtc(),
              updatedBy: tenantCtx.usuario.id,
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

      // 2. Salvar Faixas/Itens (Exclui as antigas do SQLite local e insere as novas para sync)
      if (!isNew) {
        final antigas = await _itemRepo.findByTabelaId(tabelaId);
        for (final item in antigas) {
          await _itemRepo.delete(item.id);
        }
      }

      int idx = 0;
      for (final temp in _tempFaixas) {
        final item = ItemTabelaPrecificacao(
          id: temp.id,
          tenantId: tenantCtx.tenantId,
          tabelaPrecificacaoId: tabelaId,
          quantidadeMinima: temp.minima,
          quantidadeMaxima: temp.maxima,
          valorUnitarioCentavos: temp.valorCentavos,
          ordem: idx++,
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

      // 3. Salvar associações de produtos (Desativa associações antigas não marcadas)
      final todasAssocs = await _assocRepo.findAll();
      final assocsDaTabela = todasAssocs.where((a) => a.tabelaPrecificacaoId == tabelaId);

      for (final assoc in assocsDaTabela) {
        if (!_associatedProductIds.contains(assoc.produtoId)) {
          // Desativa
          await _assocRepo.save(ProdutoTabelaPrecificacao(
            id: assoc.id,
            tenantId: assoc.tenantId,
            produtoId: assoc.produtoId,
            tabelaPrecificacaoId: assoc.tabelaPrecificacaoId,
            ativo: false,
            prioridade: assoc.prioridade,
            metadata: assoc.metadata.copyWith(
              updatedAt: DateTime.now().toUtc(),
              syncStatus: SyncStatus.pending,
            ),
          ));
        }
      }

      for (final prodId in _associatedProductIds) {
        final existe = assocsDaTabela.any((a) => a.produtoId == prodId);
        if (!existe) {
          // Cria nova associação
          final nova = ProdutoTabelaPrecificacao(
            id: const Uuid().v4(),
            tenantId: tenantCtx.tenantId,
            produtoId: prodId,
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
          );
          await _assocRepo.save(nova);
        } else {
          // Reativa se estivesse desativada
          final desativada = assocsDaTabela.firstWhere((a) => a.produtoId == prodId);
          if (!desativada.ativo) {
            await _assocRepo.save(ProdutoTabelaPrecificacao(
              id: desativada.id,
              tenantId: desativada.tenantId,
              produtoId: desativada.produtoId,
              tabelaPrecificacaoId: desativada.tabelaPrecificacaoId,
              ativo: true,
              prioridade: desativada.prioridade,
              metadata: desativada.metadata.copyWith(
                updatedAt: DateTime.now().toUtc(),
                syncStatus: SyncStatus.pending,
              ),
            ));
          }
        }
      }

      await _loadData();
      _selectTabela(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Política de precificação salva com sucesso!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar política: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
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
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lista à Esquerda
              Expanded(flex: 4, child: _buildListPanel()),
              const SizedBox(width: 24),
              // Formulário à Direita
              Expanded(flex: 6, child: _buildFormPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Políticas de Preço',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Configure descontos em lote e faixas de preços por quantidade de venda',
              style: TextStyle(fontSize: 14, color: FincoreColors.textSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _selectTabela(null),
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Novo Grupo de Preço', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildListPanel() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Políticas Ativas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
          ),
          const Divider(height: 1, color: FincoreColors.border),
          Expanded(
            child: _tabelas.isEmpty
                ? const Center(
                    child: Text('Nenhuma política cadastrada.', style: TextStyle(color: FincoreColors.textMuted)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tabelas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final tab = _tabelas[idx];
                      final isSelected = _selectedTabela?.id == tab.id;

                      return InkWell(
                        onTap: () => _selectTabela(tab),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FincoreColors.primary.withOpacity(0.08)
                                : FincoreColors.background,
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
                                  color: FincoreColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.price_change_outlined, color: FincoreColors.primary, size: 20),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tab.nome,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: FincoreColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tab.descricao.isEmpty ? 'Preço por faixas de quantidade' : tab.descricao,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                tab.metadata.syncStatus == SyncStatus.synced
                                    ? Icons.cloud_done_outlined
                                    : Icons.cloud_upload_outlined,
                                color: tab.metadata.syncStatus == SyncStatus.synced
                                    ? Colors.green
                                    : Colors.orange,
                                size: 16,
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

  Widget _buildFormPanel() {
    final isNew = _selectedTabela == null;

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNew ? 'Criar Grupo de Preço' : 'Editar Grupo de Preço',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FincoreTextField(
                    controller: _nomeCtrl,
                    label: 'Nome do Grupo de Preço',
                    hint: 'Ex: Salgados Tradicionais (Lote)',
                  ),
                  const SizedBox(height: 12),
                  FincoreTextField(
                    controller: _descricaoCtrl,
                    label: 'Descrição Curta',
                    hint: 'Ex: Preço promocional para centos de salgados mistos',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FincoreTextField(
                          controller: _prioridadeCtrl,
                          label: 'Prioridade da Política',
                          hint: '1',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(fontSize: 12, color: FincoreColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Switch(
                                  value: _ativo,
                                  onChanged: (v) => setState(() => _ativo = v),
                                  activeColor: FincoreColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _ativo ? 'Ativo' : 'Inativo',
                                  style: TextStyle(
                                    color: _ativo ? FincoreColors.primary : FincoreColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Bloco de Faixas de Preço
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Faixas de Quantidade & Preço Unitário',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: _adicionarFaixa,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Faixa', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFaixasTable(),
                  const SizedBox(height: 24),

                  // Bloco de Produtos Vinculados
                  const Text(
                    'Produtos Aplicados a esta Política',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildProductsCheckboxList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectTabela(null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: FincoreColors.border),
                  ),
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar Grupo de Preço', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
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
          child: Text('Nenhuma faixa adicionada ainda.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)),
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
          final text = fx.maxima == null ? 'ou mais' : 'até ${fx.maxima}';
          final precoFormatado = (fx.valorCentavos / 100).toStringAsFixed(2);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: idx < _tempFaixas.length - 1
                  ? const Border(bottom: BorderSide(color: FincoreColors.border))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'De ${fx.minima} $text unidades',
                    style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'R\$ $precoFormatado / un',
                    style: const TextStyle(fontSize: 13, color: FincoreColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _excluirFaixa(idx),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductsCheckboxList() {
    if (_produtos.isEmpty) {
      return const Text('Nenhum produto cadastrado no catálogo.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13));
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _produtos.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
        itemBuilder: (context, idx) {
          final p = _produtos[idx];
          final checked = _associatedProductIds.contains(p.id);

          return CheckboxListTile(
            value: checked,
            title: Text(p.nome, style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
            subtitle: Text(p.unidadeVenda.name.toUpperCase(), style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
            activeColor: FincoreColors.primary,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (_) => _toggleProduct(p.id),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          );
        },
      ),
    );
  }
}

class _TempFaixa {
  final String id;
  final int minima;
  final int? maxima;
  final int valorCentavos;
  _TempFaixa({required this.id, required this.minima, this.maxima, required this.valorCentavos});
}

class _FaixaDialog extends StatefulWidget {
  @override
  State<_FaixaDialog> createState() => _FaixaDialogState();
}

class _FaixaDialogState extends State<_FaixaDialog> {
  final _minCtrl = TextEditingController(text: '1');
  final _maxCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Faixa de Preço'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FincoreTextField(
              controller: _minCtrl,
              label: 'Quantidade Mínima',
              keyboardType: TextInputType.number,
              hint: 'Ex: 25',
            ),
            const SizedBox(height: 12),
            FincoreTextField(
              controller: _maxCtrl,
              label: 'Quantidade Máxima (Deixe vazio para infinito)',
              keyboardType: TextInputType.number,
              hint: 'Ex: 49',
            ),
            const SizedBox(height: 12),
            FincoreTextField(
              controller: _precoCtrl,
              label: 'Preço Unitário (R\$)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hint: 'Ex: 2.50',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final min = int.tryParse(_minCtrl.text) ?? 1;
            final max = int.tryParse(_maxCtrl.text);
            final precoDouble = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0.0;
            final valorCentavos = (precoDouble * 100).round();

            if (valorCentavos <= 0) return;

            Navigator.pop(context, {
              'minima': min,
              'maxima': max,
              'valorCentavos': valorCentavos,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
