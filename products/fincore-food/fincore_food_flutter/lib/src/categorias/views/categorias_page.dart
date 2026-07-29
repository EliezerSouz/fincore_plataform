import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:uuid/uuid.dart';

/// Tela de Cadastro de Categorias — Split View Premium
/// Lista as categorias à esquerda e exibe o formulário de edição/criação à direita.
class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  late final CategoriaRepository _repo;
  List<Categoria> _categorias = [];
  Categoria? _selectedCategoria;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _repo = DependencyInjection().get<CategoriaRepository>();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _ordemCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    try {
      final list = await _repo.findAll();
      setState(() {
        _categorias = list;
        _isLoading = false;
        if (_selectedCategoria != null) {
          // Mantém a seleção atualizada
          final idx = list.indexWhere((c) => c.id == _selectedCategoria!.id);
          _selectedCategoria = idx != -1 ? list[idx] : null;
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectCategoria(Categoria? categoria) {
    setState(() {
      _selectedCategoria = categoria;
      if (categoria != null) {
        _nomeCtrl.text = categoria.nome;
        _descricaoCtrl.text = categoria.descricao;
        _ordemCtrl.text = categoria.ordemExibicao.toString();
        _ativo = categoria.ativo;
      } else {
        _nomeCtrl.clear();
        _descricaoCtrl.clear();
        _ordemCtrl.text = '0';
        _ativo = true;
      }
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da categoria é obrigatório.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = _selectedCategoria == null;
      final id = isNew ? const Uuid().v4() : _selectedCategoria!.id;

      final categoria = Categoria(
        id: id,
        tenantId: tenantCtx.tenantId,
        nome: nome,
        descricao: _descricaoCtrl.text.trim(),
        ordemExibicao: int.tryParse(_ordemCtrl.text) ?? 0,
        ativo: _ativo,
        metadata: _selectedCategoria?.metadata.copyWith(
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

      await _repo.save(categoria);
      await _carregarCategorias();
      
      if (isNew) {
        _selectCategoria(null);
      } else {
        final updatedIdx = _categorias.indexWhere((c) => c.id == id);
        if (updatedIdx != -1) {
          _selectCategoria(_categorias[updatedIdx]);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoria salva com sucesso e enfileirada para sincronização!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar categoria: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _excluir(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: const Text('Tem certeza que deseja excluir esta categoria? Os produtos vinculados precisarão ser reassociados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repo.delete(id);
      await _carregarCategorias();
      _selectCategoria(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro ao excluir: $e');
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
              Expanded(flex: 5, child: _buildFormPanel()),
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
              'Categorias de Produtos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Organize o seu cardápio de mini salgados, bebidas e combos',
              style: TextStyle(fontSize: 14, color: FincoreColors.textSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _selectCategoria(null),
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildListPanel() {
    final ativas = _categorias.where((c) => c.ativo).toList();
    
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
              'Categorias Cadastradas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
          ),
          const Divider(height: 1, color: FincoreColors.border),
          Expanded(
            child: _categorias.isEmpty
                ? const Center(
                    child: Text('Nenhuma categoria cadastrada.', style: TextStyle(color: FincoreColors.textMuted)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categorias[idx];
                      final isSelected = _selectedCategoria?.id == cat.id;

                      return InkWell(
                        onTap: () => _selectCategoria(cat),
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
                              // Ícone visual fixo ou emoji
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: FincoreColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('🏷️', style: TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.nome,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: FincoreColors.textPrimary,
                                      ),
                                    ),
                                    if (cat.descricao.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        cat.descricao,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Badge de status de sync
                              _SyncIconBadge(status: cat.metadata.syncStatus),
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
    final isNew = _selectedCategoria == null;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isNew ? 'Criar Categoria' : 'Editar Categoria',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
              ),
              if (!isNew)
                IconButton(
                  onPressed: () => _excluir(_selectedCategoria!.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Excluir Categoria',
                ),
            ],
          ),
          const SizedBox(height: 24),
          FincoreTextField(
            controller: _nomeCtrl,
            label: 'Nome da Categoria',
            hint: 'Ex: Mini Salgados, Bebidas, Sobremesas',
          ),
          const SizedBox(height: 16),
          FincoreTextField(
            controller: _descricaoCtrl,
            label: 'Descrição',
            hint: 'Ex: Coxinhas, risoles, empadas e quibes de festa',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FincoreTextField(
                  controller: _ordemCtrl,
                  label: 'Ordem de Exibição',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 24),
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
                          _ativo ? 'Ativa' : 'Inativa',
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
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectCategoria(null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: FincoreColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Limpar', style: TextStyle(color: FincoreColors.textSecondary)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncIconBadge extends StatelessWidget {
  final SyncStatus status;
  const _SyncIconBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.resolved:
        color = const Color(0xFF22C55E);
        icon = Icons.cloud_done_outlined;
        break;
      case SyncStatus.pending:
      case SyncStatus.processing:
      case SyncStatus.retrying:
        color = const Color(0xFFF59E0B);
        icon = Icons.cloud_upload_outlined;
        break;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        color = const Color(0xFFEF4444);
        icon = Icons.cloud_off_outlined;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }
}
