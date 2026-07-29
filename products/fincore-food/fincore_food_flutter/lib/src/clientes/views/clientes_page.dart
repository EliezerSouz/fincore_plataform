import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:uuid/uuid.dart';

/// Tela de Gestão de Clientes do Fincore Food — Split View Premium
/// Múltiplos endereços (Casa, Escritório...) com Taxas de Entrega associadas por bairro
class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  late final ClienteRepository _clienteRepo;
  late final LocalEntregaRepository _localRepo;
  late final TaxaEntregaRepository _taxaRepo;

  List<Cliente> _clientes = [];
  List<Cliente> _filteredClientes = [];
  Cliente? _selectedCliente;
  List<LocalEntrega> _enderecos = [];
  List<TaxaEntrega> _taxas = [];
  bool _isLoading = true;
  bool _isSaving = false;

  String _searchQuery = '';

  // Controllers do form lateral de cadastro/edição do cliente
  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _clienteRepo = DependencyInjection().get<ClienteRepository>();
    _localRepo = DependencyInjection().get<LocalEntregaRepository>();
    _taxaRepo = DependencyInjection().get<TaxaEntregaRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _documentoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final list = await _clienteRepo.findAll();
      var taxas = await _taxaRepo.findAll();

      // Se não houver taxas de entrega cadastradas, inicializa com as taxas padrão do Fincore Food
      if (taxas.isEmpty) {
        final tenantCtx = DependencyInjection().get<TenantContext>();
        final defaults = [
          TaxaEntrega(
            id: 'taxa_centro',
            tenantId: tenantCtx.tenantId,
            nome: 'Centro / Adjacências',
            tipoRegra: TipoRegraTaxaEntrega.bairro,
            bairro: 'Centro',
            valorCentavos: 500, // R$ 5,00
            ativo: true,
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
            ),
          ),
        ];
        for (final t in defaults) {
          await _taxaRepo.save(t);
        }
        taxas = await _taxaRepo.findAll();
      }

      setState(() {
        _clientes = list;
        _taxas = taxas;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar clientes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      if (_searchQuery.trim().isEmpty) {
        _filteredClientes = _clientes;
      } else {
        final q = _searchQuery.toLowerCase();
        _filteredClientes = _clientes.where((c) {
          return c.nome.toLowerCase().contains(q) ||
              c.telefone.contains(q) ||
              (c.documento?.contains(q) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _selectCliente(Cliente? cliente) async {
    if (cliente == null) {
      setState(() {
        _selectedCliente = null;
        _enderecos = [];
      });
      return;
    }

    setState(() {
      _selectedCliente = cliente;
      _enderecos = [];
    });

    try {
      final ends = await _localRepo.findByClienteId(cliente.id);
      if (mounted && _selectedCliente?.id == cliente.id) {
        setState(() {
          _enderecos = ends;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar endereços do cliente: $e');
    }
  }

  void _openEditorCliente(Cliente? cliente) {
    if (cliente == null) {
      _nomeCtrl.clear();
      _telefoneCtrl.clear();
      _emailCtrl.clear();
      _documentoCtrl.clear();
      _obsCtrl.clear();
      _ativo = true;
    } else {
      _nomeCtrl.text = cliente.nome;
      _telefoneCtrl.text = cliente.telefone;
      _emailCtrl.text = cliente.email ?? '';
      _documentoCtrl.text = cliente.documento ?? '';
      _obsCtrl.text = cliente.observacoes;
      _ativo = cliente.ativo;
    }
    _showClienteEditSheet(cliente);
  }

  void _showClienteEditSheet(Cliente? cliente) {
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
                    cliente == null ? 'Cadastrar Novo Cliente' : 'Editar Dados do Cliente',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DADOS DO CONSUMIDOR', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.primary, fontSize: 12)),
                      const SizedBox(height: 14),
                      FincoreTextField(controller: _nomeCtrl, label: 'Nome Completo / Razão Social'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: FincoreTextField(controller: _telefoneCtrl, label: 'Telefone / WhatsApp', inputFormatters: FincoreFormatters.telefone)),
                          const SizedBox(width: 14),
                          Expanded(child: FincoreTextField(controller: _documentoCtrl, label: 'CPF / CNPJ', inputFormatters: FincoreFormatters.cnpjCpf)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FincoreTextField(controller: _emailCtrl, label: 'E-mail (Opcional)'),
                      const SizedBox(height: 14),
                      FincoreTextField(controller: _obsCtrl, label: 'Observações internas e preferências do cliente', maxLines: 3),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cliente Ativo?'),
                          Switch(
                            value: _ativo,
                            onChanged: (v) => setSheetState(() => _ativo = v),
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
                      onPressed: _isSaving
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _salvarCliente(cliente);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Salvar Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _salvarCliente(Cliente? original) async {
    final nome = _nomeCtrl.text.trim();
    final tel = _telefoneCtrl.text.trim();
    if (nome.isEmpty || tel.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = original == null;
      final id = isNew ? const Uuid().v4() : original.id;

      final cliente = Cliente(
        id: id,
        tenantId: tenantCtx.tenantId,
        nome: nome,
        telefone: tel,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        documento: _documentoCtrl.text.trim().isEmpty ? null : _documentoCtrl.text.trim(),
        observacoes: _obsCtrl.text.trim(),
        ativo: _ativo,
        metadata: original?.metadata.copyWith(
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

      await _clienteRepo.save(cliente);
      await _loadData();
      _selectCliente(cliente);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente salvo e sincronizado com sucesso!'), backgroundColor: Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar cliente: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ─── GESTÃO DE MÚLTIPLOS ENDEREÇOS COM TAXA DE ENTREGA ──────────────────
  void _openEditorEndereco(LocalEntrega? endereco) {
    if (_selectedCliente == null) return;

    final idCtrl = TextEditingController(text: endereco?.nomeIdentificador ?? 'Casa');
    final logrCtrl = TextEditingController(text: endereco?.logradouro ?? '');
    final numCtrl = TextEditingController(text: endereco?.numero ?? '');
    final bairroCtrl = TextEditingController(text: endereco?.bairro ?? '');
    final cidadeCtrl = TextEditingController(text: endereco?.cidade ?? 'São Paulo');
    final refCtrl = TextEditingController(text: endereco?.referencia ?? '');

    // Busca a taxa explicitamente salva (em endereco.cep) ou por bairro/nome
    String? selectedTaxaId;
    if (endereco != null && endereco.cep.isNotEmpty && _taxas.any((t) => t.id == endereco.cep)) {
      selectedTaxaId = endereco.cep;
    } else if (endereco != null && endereco.bairro.isNotEmpty) {
      final match = _taxas.cast<TaxaEntrega?>().firstWhere(
            (t) => t?.bairro?.toLowerCase() == endereco.bairro.toLowerCase() ||
                   t?.nome.toLowerCase().contains(endereco.bairro.toLowerCase()) == true,
            orElse: () => _taxas.isNotEmpty ? _taxas.first : null,
          );
      selectedTaxaId = match?.id;
    } else {
      selectedTaxaId = _taxas.isNotEmpty ? _taxas.first.id : null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        endereco == null ? 'Adicionar Endereço de Entrega' : 'Editar Endereço (${endereco.nomeIdentificador})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Ex: Casa, Escritório, Trabalho ou Residência Adicional', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
                  const SizedBox(height: 20),

                  // Seletor rápido de tipo de endereço (Casa / Escritório / Outro)
                  Row(
                    children: [
                      _ChipTipoEndereco(
                        label: 'Casa',
                        icon: Icons.home_outlined,
                        selected: idCtrl.text == 'Casa',
                        onTap: () => setDialogState(() => idCtrl.text = 'Casa'),
                      ),
                      const SizedBox(width: 8),
                      _ChipTipoEndereco(
                        label: 'Escritório',
                        icon: Icons.business_outlined,
                        selected: idCtrl.text == 'Escritório',
                        onTap: () => setDialogState(() => idCtrl.text = 'Escritório'),
                      ),
                      const SizedBox(width: 8),
                      _ChipTipoEndereco(
                        label: 'Trabalho',
                        icon: Icons.work_outline,
                        selected: idCtrl.text == 'Trabalho',
                        onTap: () => setDialogState(() => idCtrl.text = 'Trabalho'),
                      ),
                      const SizedBox(width: 8),
                      _ChipTipoEndereco(
                        label: 'Outro',
                        icon: Icons.place_outlined,
                        selected: idCtrl.text == 'Outro',
                        onTap: () => setDialogState(() => idCtrl.text = 'Outro'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FincoreTextField(controller: idCtrl, label: 'Nome / Identificador do Endereço'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(flex: 3, child: FincoreTextField(controller: logrCtrl, label: 'Logradouro / Av.')),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: FincoreTextField(controller: numCtrl, label: 'Nº')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FincoreTextField(
                          controller: bairroCtrl,
                          label: 'Bairro',
                          onChanged: (v) {
                            // Tenta associar automaticamente à taxa correta do bairro digitado
                            final match = _taxas.cast<TaxaEntrega?>().firstWhere(
                                  (t) => t?.bairro?.toLowerCase() == v.trim().toLowerCase(),
                                  orElse: () => null,
                                );
                            if (match != null) {
                              setDialogState(() => selectedTaxaId = match.id);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: FincoreTextField(controller: cidadeCtrl, label: 'Cidade')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FincoreTextField(controller: refCtrl, label: 'Complemento / Ponto de Referência'),
                  const SizedBox(height: 18),

                  // Dropdown com as Taxas de Entrega configuradas na empresa
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TAXA DE ENTREGA APLICÁVEL A ESTE ENDEREÇO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: selectedTaxaId,
                        dropdownColor: FincoreColors.surface,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: FincoreColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: _taxas.map((t) {
                          final valorFormatado = 'R\$ ${(t.valorCentavos / 100).toStringAsFixed(2)}';
                          return DropdownMenuItem(
                            value: t.id,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${t.nome} ${t.bairro != null ? "(${t.bairro})" : ""}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                Text(valorFormatado, style: const TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setDialogState(() => selectedTaxaId = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (logrCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          await _salvarEndereco(
                            endereco,
                            idCtrl.text.trim().isEmpty ? 'Principal' : idCtrl.text.trim(),
                            logrCtrl.text.trim(),
                            numCtrl.text.trim(),
                            bairroCtrl.text.trim(),
                            cidadeCtrl.text.trim(),
                            refCtrl.text.trim(),
                            selectedTaxaId,
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
                        child: const Text('Salvar Endereço', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _salvarEndereco(
    LocalEntrega? original,
    String identificador,
    String logradouro,
    String numero,
    String bairro,
    String cidade,
    String ref,
    String? selectedTaxaId,
  ) async {
    if (_selectedCliente == null) return;
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = original == null;
      final id = isNew ? const Uuid().v4() : original.id;

      final local = LocalEntrega(
        id: id,
        tenantId: tenantCtx.tenantId,
        clienteId: _selectedCliente!.id,
        nomeIdentificador: identificador,
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        cep: selectedTaxaId ?? '',
        referencia: ref,
        ativo: true,
        metadata: original?.metadata.copyWith(
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

      await _localRepo.save(local);
      await _selectCliente(_selectedCliente);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Endereço "$identificador" salvo e vinculado ao cliente!'), backgroundColor: const Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar endereço de entrega: $e');
    }
  }

  Future<void> _excluirEndereco(LocalEntrega endereco) async {
    try {
      await _localRepo.delete(endereco.id);
      await _selectCliente(_selectedCliente);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Endereço "${endereco.nomeIdentificador}" removido.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint('Erro ao remover endereço: $e');
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
        _buildSearchBar(),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildTablePanel()),
              if (_selectedCliente != null) ...[
                const SizedBox(width: 18),
                Expanded(flex: 3, child: _buildDetailsPanel()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIs() {
    final total = _clientes.length;
    final ativos = _clientes.where((c) => c.ativo).length;
    final comEnderecos = _clientes.length; // Todo cliente pode ter endereços

    return Row(
      children: [
        _KPIBadge(label: 'Total de Clientes', value: total, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _KPIBadge(label: 'Clientes Ativos', value: ativos, color: const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _KPIBadge(label: 'Taxas Cadastradas', value: _taxas.length, color: const Color(0xFF9333EA)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _openEditorCliente(null),
          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
          icon: const Icon(Icons.person_add_outlined, size: 16),
          label: const Text('Cadastrar Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Pesquisar cliente por nome, telefone ou CPF/CNPJ...',
                prefixIcon: Icon(Icons.search, size: 18, color: FincoreColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablePanel() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('CLIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                Expanded(flex: 2, child: Text('TELEFONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                Expanded(flex: 2, child: Text('ENDEREÇOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                Expanded(flex: 2, child: Text('AÇÕES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
              ],
            ),
          ),
          const Divider(height: 1, color: FincoreColors.border),
          Expanded(
            child: _filteredClientes.isEmpty
                ? const Center(child: Text('Nenhum cliente cadastrado.', style: TextStyle(color: FincoreColors.textMuted)))
                : ListView.separated(
                    itemCount: _filteredClientes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
                    itemBuilder: (context, idx) {
                      final c = _filteredClientes[idx];
                      final isSelected = _selectedCliente?.id == c.id;

                      return InkWell(
                        onTap: () => _selectCliente(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          color: isSelected ? FincoreColors.primary.withOpacity(0.08) : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  c.nome,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: FincoreColors.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  c.telefone,
                                  style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: FincoreColors.primary),
                                    SizedBox(width: 4),
                                    Text('Múltiplos / Delivery', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _openEditorCliente(c),
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      tooltip: 'Editar Cliente',
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _selectCliente(c);
                                        _openEditorEndereco(null);
                                      },
                                      icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: FincoreColors.primary),
                                      tooltip: 'Adicionar Endereço',
                                    ),
                                  ],
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

  // ─── PAINEL COM LISTA DE MÚLTIPLOS ENDEREÇOS (CASA / ESCRITÓRIO) E TAXAS ───
  Widget _buildDetailsPanel() {
    final c = _selectedCliente!;
    final initials = c.nome.trim().isNotEmpty ? c.nome.trim().substring(0, 1).toUpperCase() : '?';

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
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: FincoreColors.primary.withOpacity(0.12),
                child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: FincoreColors.textMuted),
                        const SizedBox(width: 6),
                        Text(c.telefone, style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ATIVO', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: const Text('Novo Pedido para Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _openEditorCliente(c),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar Dados'),
              ),
            ],
          ),
          const Divider(height: 32, color: FincoreColors.border),

          // CABEÇALHO DA SEÇÃO DE ENDEREÇOS E TAXAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: FincoreColors.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text('ENDEREÇOS DE ENTREGA E TAXAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: FincoreColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('${_enderecos.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _openEditorEndereco(null),
                icon: const Icon(Icons.add, size: 16, color: FincoreColors.primary),
                label: const Text('+ Adicionar Endereço', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // LISTA DE ENDEREÇOS (CASA, ESCRITÓRIO, ETC.) DO CLIENTE
          Expanded(
            child: _enderecos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_location_alt_outlined, size: 40, color: FincoreColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('Nenhum endereço de entrega cadastrado', style: TextStyle(color: FincoreColors.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('Adicione endereços para calcular taxas de delivery (Casa, Escritório, etc.)', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openEditorEndereco(null),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Adicionar Primeiro Endereço'),
                          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _enderecos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final e = _enderecos[idx];

                      // Ícone inteligente pelo nome identificador
                      IconData ic = Icons.location_on_outlined;
                      final idUpper = e.nomeIdentificador.toLowerCase();
                      if (idUpper.contains('casa') || idUpper.contains('resid')) ic = Icons.home_outlined;
                      if (idUpper.contains('escrit') || idUpper.contains('trab') || idUpper.contains('comerc')) ic = Icons.business_outlined;

                      // Encontra a taxa exatamente selecionada (salva em e.cep) ou pelo bairro/região
                      TaxaEntrega? taxaMatch;
                      if (e.cep.isNotEmpty) {
                        taxaMatch = _taxas.cast<TaxaEntrega?>().firstWhere(
                              (t) => t?.id == e.cep,
                              orElse: () => null,
                            );
                      }
                      if (taxaMatch == null && e.bairro.isNotEmpty) {
                        taxaMatch = _taxas.cast<TaxaEntrega?>().firstWhere(
                              (t) => t?.bairro?.toLowerCase() == e.bairro.trim().toLowerCase() ||
                                     t?.nome.toLowerCase().contains(e.bairro.trim().toLowerCase()) == true,
                              orElse: () => null,
                            );
                      }
                      taxaMatch ??= _taxas.cast<TaxaEntrega?>().firstWhere(
                            (t) => t?.id == 'taxa_centro',
                            orElse: () => _taxas.isNotEmpty ? _taxas.first : null,
                          );
                      final taxaValor = taxaMatch != null ? (taxaMatch.valorCentavos / 100).toStringAsFixed(2) : '0,00';
                      final taxaNome = taxaMatch?.nome ?? 'Taxa Padrão';

                      return Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(ic, size: 18, color: FincoreColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      e.nomeIdentificador.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _openEditorEndereco(e),
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      tooltip: 'Editar Endereço',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 14),
                                    IconButton(
                                      onPressed: () => _excluirEndereco(e),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                      tooltip: 'Excluir Endereço',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${e.logradouro}, ${e.numero} • ${e.bairro}',
                              style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${e.cidade}${e.referencia.isNotEmpty ? " — Ref: ${e.referencia}" : ""}',
                              style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                            ),
                            const Divider(height: 16, color: FincoreColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.delivery_dining, size: 16, color: FincoreColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      taxaNome,
                                      style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: FincoreColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Taxa: R\$ $taxaValor',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _ChipTipoEndereco extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChipTipoEndereco({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? FincoreColors.primary : FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : FincoreColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
