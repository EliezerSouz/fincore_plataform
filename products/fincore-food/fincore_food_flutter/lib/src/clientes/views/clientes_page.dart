import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/clientes/controllers/clientes_controller.dart';
import 'package:fincore_food_flutter/src/clientes/views/widgets/cliente_form_dialog.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/pdv_express/views/pdv_express_screen.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pdv_page.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/whatsapp_dialog.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import 'package:fincore_food_flutter/src/financeiro/controllers/contas_receber_controller.dart';
import 'package:fincore_food_flutter/src/financeiro/widgets/dialog_baixa_titulo.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/pedido_mirror_dialog.dart';

/// Tela de Gestão de Clientes do Fincore Food — Split View Premium baseada na Salgaderia
/// Tabela master Gmail-style no lado esquerdo com resumo/estatísticas de topo,
/// Gaveta Lateral (Inspector) no lado direito para visualização das abas (Resumo, Pedidos, Endereço, Financeiro),
/// e Formulário de Edição/Criação exibido em Modal Centralizado (tela no meio).
class ClientesPage extends StatefulWidget {
  final int initialTab;
  const ClientesPage({super.key, this.initialTab = 0});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> with SingleTickerProviderStateMixin {
  late final ClientesController _controller;
  late TabController _tabController;
  late final VoidCallback _controllerListener;
  StreamSubscription<String>? _syncSub;

  bool _isInspectorOpen = false;

  // Variáveis da Aba Regiões de Entrega
  late int _selectedTab; // 0 = Clientes, 1 = Regiões de Entrega
  final _regBuscaController = TextEditingController();
  String _regSearchQuery = '';
  String _regFiltroStatus = 'Todos';
  final Set<String> _selectedRegioesIds = {};

  final _regiaoFormKey = GlobalKey<FormState>();
  final _regNomeCtrl = TextEditingController();
  final _regBairroCtrl = TextEditingController();
  final _regCepIniCtrl = TextEditingController();
  final _regCepFinCtrl = TextEditingController();
  final _regDistMinCtrl = TextEditingController();
  final _regDistMaxCtrl = TextEditingController();
  final _regValorCtrl = TextEditingController();
  final _regPedidoMinCtrl = TextEditingController();
  final _regPrazoCtrl = TextEditingController();
  final _regObsCtrl = TextEditingController();
  bool _regAtivo = true;
  TipoRegraTaxaEntrega _regTipoRegra = TipoRegraTaxaEntrega.bairro;

  TaxaEntrega? _selectedRegiao;
  bool _isEditingRegiao = false;
  bool _isInspectorRegiaoOpen = false;

  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _tabController = TabController(length: 4, vsync: this);
    _controller = DependencyInjection().get<ClientesController>();
    _controllerListener = _onControllerChanged;
    _controller.addListener(_controllerListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadData();
      }
    });

    final syncService = DependencyInjection().tryGet<SupabaseSyncService>();
    if (syncService != null) {
      _syncSub = syncService.onDataSynced.listen((entity) {
        if (entity == 'cliente' || entity == 'clientes' || entity == 'pedido' || entity == 'pedidos' || entity.isEmpty) {
          if (mounted) {
            _controller.loadData();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    try {
      _controller.removeListener(_controllerListener);
    } catch (_) {}
    try {
      _tabController.dispose();
    } catch (_) {}
    _buscaController.dispose();

    _regBuscaController.dispose();
    _regNomeCtrl.dispose();
    _regBairroCtrl.dispose();
    _regCepIniCtrl.dispose();
    _regCepFinCtrl.dispose();
    _regDistMinCtrl.dispose();
    _regDistMaxCtrl.dispose();
    _regValorCtrl.dispose();
    _regPedidoMinCtrl.dispose();
    _regPrazoCtrl.dispose();
    _regObsCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectCliente(Cliente? cliente) {
    if (!mounted) return;
    if (cliente == null) {
      setState(() {
        _isInspectorOpen = false;
      });
      _controller.selectCliente(null);
      return;
    }

    setState(() {
      _isInspectorOpen = true;
    });
    _controller.selectCliente(cliente);
  }

  void _openCreateMode() async {
    final novo = await ClienteFormDialog.show(context);
    if (novo != null && mounted) {
      await _controller.loadData();
      _selectCliente(novo);
    }
  }

  void _openEditMode(Cliente c) async {
    final updated = await ClienteFormDialog.show(context, cliente: c);
    if (updated != null && mounted) {
      await _controller.loadData();
      _selectCliente(updated);
    }
  }



  Future<void> _excluirCliente([Cliente? clienteAlvo]) async {
    final client = clienteAlvo ?? _controller.selectedCliente;
    if (client == null) return;

    if (_isConsumidorFinal(client)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O cliente Consumidor Final é protegido pelo sistema e não pode ser excluído.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final pedidosCount = _controller.getCountPedidos(client.id);

    if (pedidosCount > 0) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text('Exclusão Bloqueada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'O cliente "${client.nomeExibicao}" possui $pedidosCount pedido(s) vinculados ao seu histórico.\n\n'
            'Por questões de integridade contábil, fiscal e relatórios de vendas, cadastros com movimentações não podem ser excluídos.\n\n'
            'Dica: Caso não deseje mais vender para este cliente, você pode editá-lo e marcar o status como "Inativo".',
            style: const TextStyle(fontSize: 13, height: 1.4, color: FincoreColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Excluir Cadastro?'),
          ],
        ),
        content: Text(
          'Deseja realmente excluir o cadastro de "${client.nomeExibicao}"?\n\n'
          'Como este cliente não possui histórico de pedidos ou vendas vinculadas, o registro será removido do sistema.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Exclusão'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deletarCliente(client);
      if (success && mounted) {
        _selectCliente(null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente "${client.nomeExibicao}" excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted && _controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _buscarCep(String cep, TextEditingController logrCtrl, TextEditingController bairroCtrl, TextEditingController cidadeCtrl) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        if (json['erro'] != true) {
          logrCtrl.text = json['logradouro'] ?? '';
          bairroCtrl.text = json['bairro'] ?? '';
          cidadeCtrl.text = json['localidade'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    }
  }

  void _openEditorEndereco(LocalEntrega? local) {
    final client = _controller.selectedCliente;
    if (client == null) return;

    final idCtrl = TextEditingController(text: local?.nomeIdentificador ?? 'Casa');
    final logrCtrl = TextEditingController(text: local?.logradouro ?? '');
    final numCtrl = TextEditingController(text: local?.numero ?? '');
    final bairroCtrl = TextEditingController(text: local?.bairro ?? '');
    final cidadeCtrl = TextEditingController(text: local?.cidade ?? '');
    final cepCtrl = TextEditingController(text: local?.cep ?? '');
    final refCtrl = TextEditingController(text: local?.referencia ?? '');
    bool ativo = local?.ativo ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        local == null ? 'Novo Local de Entrega' : 'Editar Local de Entrega',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Nome Identificador', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  FincoreTextField(
                    controller: idCtrl,
                    hintText: 'Ex: Casa, Trabalho, Sítio...',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CEP', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            FincoreTextField(
                              controller: cepCtrl,
                              hintText: '00000-000',
                              inputFormatters: FincoreFormatters.cep,
                              onChanged: (v) {
                                if (v.replaceAll(RegExp(r'\D'), '').length == 8) {
                                  _buscarCep(v, logrCtrl, bairroCtrl, cidadeCtrl);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Número', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            FincoreTextField(
                              controller: numCtrl,
                              hintText: '123',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Logradouro', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  FincoreTextField(
                    controller: logrCtrl,
                    hintText: 'Rua, Avenida...',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bairro', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            FincoreTextField(
                              controller: bairroCtrl,
                              hintText: 'Centro...',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cidade', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            FincoreTextField(
                              controller: cidadeCtrl,
                              hintText: 'Sorocaba...',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Referência / Complemento', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  FincoreTextField(
                    controller: refCtrl,
                    hintText: 'Apto 12, Próximo ao...',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Endereço Ativo?', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                      Switch(
                        value: ativo,
                        activeColor: const Color(0xFFF97316),
                        onChanged: (val) => setDialogState(() => ativo = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                      onPressed: () async {
                        if (idCtrl.text.isEmpty || logrCtrl.text.isEmpty) return;
                        final ok = await _controller.salvarEndereco(
                          original: local,
                          clienteId: client.id,
                          nomeIdentificador: idCtrl.text.trim(),
                          logradouro: logrCtrl.text.trim(),
                          numero: numCtrl.text.trim(),
                          bairro: bairroCtrl.text.trim(),
                          cidade: cidadeCtrl.text.trim(),
                          cep: cepCtrl.text.trim(),
                          referencia: refCtrl.text.trim(),
                          ativo: ativo,
                        );
                        if (ok) {
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Salvar Endereço', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCadastroTaxa(String defaultBairro, String defaultCep) {
    setState(() {
      _selectedTab = 1;
      _selectedRegiao = null;
      _regNomeCtrl.text = defaultBairro.isNotEmpty ? defaultBairro : 'Região de Entrega';
      _regBairroCtrl.text = defaultBairro;
      _regCepIniCtrl.text = defaultCep;
      _regCepFinCtrl.clear();
      _regValorCtrl.text = '0,00';
      _regPedidoMinCtrl.text = '0,00';
      _regPrazoCtrl.clear();
      _regObsCtrl.clear();
      _regAtivo = true;
      _regTipoRegra = defaultBairro.isNotEmpty ? TipoRegraTaxaEntrega.bairro : TipoRegraTaxaEntrega.cep;
      _isEditingRegiao = true;
      _isInspectorRegiaoOpen = false;
    });
  }

  Widget _buildSubTab(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _isInspectorOpen = false;
          _selectedRegiao = null;
          _isInspectorRegiaoOpen = false;
          _isEditingRegiao = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? FincoreColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? FincoreColors.primary : FincoreColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateModeRegiao() {
    setState(() {
      _selectedRegiao = null;
      _regNomeCtrl.clear();
      _regBairroCtrl.clear();
      _regCepIniCtrl.clear();
      _regCepFinCtrl.clear();
      _regDistMinCtrl.clear();
      _regDistMaxCtrl.clear();
      _regValorCtrl.text = '0,00';
      _regPedidoMinCtrl.text = '0,00';
      _regPrazoCtrl.clear();
      _regObsCtrl.clear();
      _regAtivo = true;
      _regTipoRegra = TipoRegraTaxaEntrega.bairro;
      _isEditingRegiao = true;
    });
  }

  void _openEditModeRegiao(TaxaEntrega reg) {
    setState(() {
      _selectedRegiao = reg;
      _regNomeCtrl.text = reg.nome;
      _regBairroCtrl.text = reg.bairro ?? '';
      _regCepIniCtrl.text = reg.cepInicial ?? '';
      _regCepFinCtrl.text = reg.cepFinal ?? '';
      _regDistMinCtrl.text = reg.distanciaMinKm?.toString() ?? '';
      _regDistMaxCtrl.text = reg.distanciaMaxKm?.toString() ?? '';
      _regValorCtrl.text = (reg.valorCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',');
      _regPedidoMinCtrl.text = (reg.pedidoMinimoCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',');
      _regPrazoCtrl.text = reg.prazoEstimado ?? '';
      _regObsCtrl.text = reg.observacoes ?? '';
      _regAtivo = reg.ativo;
      _regTipoRegra = reg.tipoRegra;
      _isEditingRegiao = true;
    });
  }

  void _selectRegiao(TaxaEntrega? reg) {
    setState(() {
      _selectedRegiao = reg;
      _isInspectorRegiaoOpen = reg != null;
    });
  }

  int _parseMoedaParaCentavos(String text) {
    final clean = text.replaceAll('R\$', '').replaceAll(' ', '').trim();
    if (clean.isEmpty) return 0;

    if (clean.contains(',')) {
      final semPontos = clean.replaceAll('.', '').replaceAll(',', '.');
      final val = double.tryParse(semPontos) ?? 0.0;
      return (val * 100).round();
    }

    if (clean.contains('.')) {
      final val = double.tryParse(clean) ?? 0.0;
      return (val * 100).round();
    }

    final val = double.tryParse(clean) ?? 0.0;
    return (val * 100).round();
  }

  Future<void> _salvarRegiao() async {
    if (_regiaoFormKey.currentState?.validate() != true) return;

    final int valorCentavos = _parseMoedaParaCentavos(_regValorCtrl.text);
    final int pedidoMinimoCentavos = _parseMoedaParaCentavos(_regPedidoMinCtrl.text);
    final double? distMin = _regTipoRegra == TipoRegraTaxaEntrega.km
        ? double.tryParse(_regDistMinCtrl.text.replaceAll(',', '.'))
        : null;
    final double? distMax = _regTipoRegra == TipoRegraTaxaEntrega.km
        ? double.tryParse(_regDistMaxCtrl.text.replaceAll(',', '.'))
        : null;

    final ok = await _controller.salvarTaxaEntrega(
      original: _selectedRegiao,
      nome: _regNomeCtrl.text,
      tipoRegra: _regTipoRegra,
      bairro: _regTipoRegra == TipoRegraTaxaEntrega.bairro ? _regBairroCtrl.text : null,
      cepInicial: _regTipoRegra == TipoRegraTaxaEntrega.cep ? _regCepIniCtrl.text : null,
      cepFinal: _regTipoRegra == TipoRegraTaxaEntrega.cep ? _regCepFinCtrl.text : null,
      distanciaMinKm: distMin,
      distanciaMaxKm: distMax,
      valorCentavos: valorCentavos,
      ativo: _regAtivo,
      pedidoMinimoCentavos: pedidoMinimoCentavos,
      prazoEstimado: _regPrazoCtrl.text,
      observacoes: _regObsCtrl.text,
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Região de entrega salva com sucesso!')),
      );
      setState(() {
        _isEditingRegiao = false;
        _isInspectorRegiaoOpen = false;
        _selectedRegiao = null;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${_controller.errorMessage ?? "Falha ao salvar região."}')),
      );
    }
  }

  Future<void> _excluirRegiaoConfirma(TaxaEntrega reg) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Região?'),
        content: Text('Deseja realmente excluir a região "${reg.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: FincoreColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final ok = await _controller.excluirTaxaEntrega(reg.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Região de entrega excluída com sucesso!')),
        );
        setState(() {
          _selectedRegioesIds.remove(reg.id);
          _isInspectorRegiaoOpen = false;
          _selectedRegiao = null;
        });
      }
    }
  }

  Future<void> _excluirRegioesEmLote() async {
    final count = _selectedRegioesIds.length;
    if (count == 0) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir $count região(ões)?'),
        content: Text('Tem certeza que deseja excluir as $count regiões de entrega selecionadas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Todas'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    int excluidas = 0;
    for (final id in _selectedRegioesIds.toList()) {
      final ok = await _controller.excluirTaxaEntrega(id);
      if (ok) excluidas++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FincoreColors.success,
          content: Text('$excluidas região(ões) excluída(s) com sucesso!'),
        ),
      );
      setState(() {
        _selectedRegioesIds.clear();
        _selectedRegiao = null;
        _isInspectorRegiaoOpen = false;
      });
    }
  }

  Future<void> _iniciarNovoPedidoParaCliente(Cliente c) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PdvPage(clienteInicial: c),
      ),
    );
    if (result == true && mounted) {
      _controller.loadData();
    }
  }

  Future<void> _toggleStatusCliente(Cliente c) async {
    final ok = await _controller.toggleAtivoCliente(c);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(c.ativo ? 'Cliente "${c.nomeExibicao}" inativado.' : 'Cliente "${c.nomeExibicao}" ativado com sucesso!'),
          backgroundColor: c.ativo ? Colors.amber[800] : FincoreColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSyncIndicator(SyncStatus status, [DateTime? lastSyncedAt]) {
    IconData icon;
    Color color;
    String label;
    String tooltip;

    final dataFormatada = lastSyncedAt != null
        ? DateFormat('dd/MM HH:mm').format(lastSyncedAt.toLocal())
        : null;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_rounded;
        color = FincoreColors.success;
        label = 'Nuvem OK';
        tooltip = dataFormatada != null
            ? 'Sincronizado com a nuvem em $dataFormatada'
            : 'Sincronizado com a nuvem (Supabase)';
        break;
      case SyncStatus.pending:
      case SyncStatus.processing:
      case SyncStatus.retrying:
        icon = Icons.sync_rounded;
        color = Colors.orange;
        label = 'Pendente';
        tooltip = 'Alterações locais aguardando envio para a nuvem';
        break;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        icon = Icons.cloud_off_rounded;
        color = FincoreColors.danger;
        label = 'Erro Sync';
        tooltip = 'Falha ao sincronizar com a nuvem';
        break;
      default:
        icon = Icons.cloud_queue_rounded;
        color = FincoreColors.textMuted;
        label = 'Offline';
        tooltip = 'Operando em modo local';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String dinheiro(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Header Row (Somente Abas) ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSubTab('Clientes', Icons.people_outline, 0),
            const SizedBox(width: 16),
            _buildSubTab('Regiões de Entrega', Icons.local_shipping_outlined, 1),
          ],
        ),
        const SizedBox(height: 16),

        // ── Conteúdo da Aba Ativa ──────────────────────────────────────────
        Expanded(
          child: _selectedTab == 0
              ? _buildClientesTabContent()
              : _buildRegioesTabContent(),
        ),
      ],
    );
  }

  Widget _buildClientesTabContent() {
    final totalClientes = _controller.clientes.length;
    final totalAtivos = _controller.clientes.where((c) => c.ativo).length;
    final totalVips = _controller.clientes.where((c) => c.observacoes.toLowerCase().contains('vip') || (c.apelido?.toLowerCase().contains('vip') ?? false)).length;

    return Stack(
      children: [
        CrudWorkspace(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Resumo Contextual (Fina linha de status)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    _discreteMetricText('$totalClientes clientes'),
                    const SizedBox(width: 8),
                    const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                    const SizedBox(width: 8),
                    _discreteMetricText('$totalAtivos ativos'),
                    const SizedBox(width: 8),
                    const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                    const SizedBox(width: 8),
                    _discreteMetricText('$totalVips VIPs'),
                    const SizedBox(width: 8),
                    const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                    const SizedBox(width: 8),
                    _discreteMetricText('Faturamento Base: R\$ 0,00'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Linha de Busca + Filtro de Status + Botão "+ Novo cliente"
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
                              controller: _buscaController,
                              onChanged: (val) {
                                setState(() {
                                  _controller.updateSearch(val);
                                });
                              },
                              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Pesquise por nome, apelido, telefone, documento...',
                                hintStyle: TextStyle(fontSize: 13, color: FincoreColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_buscaController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: FincoreColors.textMuted),
                              onPressed: () {
                                setState(() {
                                  _buscaController.clear();
                                  _controller.updateSearch('');
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown de Filtro de Status
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _controller.filtroStatus,
                        dropdownColor: FincoreColors.surfaceOverlay,
                        icon: const Icon(Icons.arrow_drop_down, color: FincoreColors.textMuted),
                        style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _controller.updateFiltroStatus(val);
                            });
                          }
                        },
                        items: ['Todos', 'Ativos', 'Inativos'].map((st) {
                          return DropdownMenuItem<String>(
                            value: st,
                            child: Text('Status: $st'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown de Ordenação (Padrão: A-Z)
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _controller.filtroOrdenacao,
                        dropdownColor: FincoreColors.surfaceOverlay,
                        icon: Icon(Icons.sort_rounded, size: 18, color: FincoreColors.primary),
                        style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _controller.updateFiltroOrdenacao(val);
                            });
                          }
                        },
                        items: [
                          DropdownMenuItem<String>(
                            value: 'nome_asc',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sort_by_alpha_rounded, size: 14, color: FincoreColors.primary),
                                SizedBox(width: 6),
                                Text('Ordem: A-Z (Padrão)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'nome_desc',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sort_by_alpha_rounded, size: 14, color: FincoreColors.textMuted),
                                SizedBox(width: 6),
                                Text('Ordem: Z-A'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'recentes',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: FincoreColors.textMuted),
                                SizedBox(width: 6),
                                Text('Mais Recentes'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'antigos',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_rounded, size: 14, color: FincoreColors.textMuted),
                                SizedBox(width: 6),
                                Text('Mais Antigos'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'faturamento',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_money_rounded, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text('Maior Faturamento'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'pedidos',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF3B82F6)),
                                SizedBox(width: 6),
                                Text('Mais Pedidos'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openCreateMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: Colors.white),
                    label: const Text('Novo Cliente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          master: _buildTablePanel(),
          isInspectorOpen: _isInspectorOpen,
          inspector: FincoreInspectorPanel(
            isOpen: _isInspectorOpen,
            isEditing: false,
            title: '',
            subtitle: '',
            onClose: () => _selectCliente(null),
            child: _buildRightPanelContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildRegioesTabContent() {
    // Filtrar as taxas com base no termo de busca e filtro de status local
    final query = _regSearchQuery.trim().toLowerCase();
    var filtered = _controller.taxas.where((t) {
      final matchesQuery = t.nome.toLowerCase().contains(query) || (t.bairro?.toLowerCase().contains(query) ?? false);
      final matchesStatus = _regFiltroStatus == 'Todos' || (_regFiltroStatus == 'Ativos' && t.ativo) || (_regFiltroStatus == 'Inativos' && !t.ativo);
      return matchesQuery && matchesStatus;
    }).toList();

    final totalRegioes = _controller.taxas.length;
    final totalAtivas = _controller.taxas.where((t) => t.ativo).length;

    return Stack(
      children: [
        CrudWorkspace(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Resumo Contextual (Fina linha de status)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    _discreteMetricText('$totalRegioes regiões cadastradas'),
                    const SizedBox(width: 8),
                    const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                    const SizedBox(width: 8),
                    _discreteMetricText('$totalAtivas ativas'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Linha de Busca + Filtro de Status + Botão "+ Nova Região"
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
                              controller: _regBuscaController,
                              onChanged: (val) {
                                setState(() {
                                  _regSearchQuery = val;
                                });
                              },
                              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Pesquise região por nome ou bairro...',
                                hintStyle: TextStyle(fontSize: 13, color: FincoreColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_regBuscaController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: FincoreColors.textMuted),
                              onPressed: () {
                                setState(() {
                                  _regBuscaController.clear();
                                  _regSearchQuery = '';
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown de Filtro de Status
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _regFiltroStatus,
                        dropdownColor: FincoreColors.surfaceOverlay,
                        icon: const Icon(Icons.arrow_drop_down, color: FincoreColors.textMuted),
                        style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _regFiltroStatus = val;
                            });
                          }
                        },
                        items: ['Todos', 'Ativos', 'Inativos'].map((st) {
                          return DropdownMenuItem<String>(
                            value: st,
                            child: Text('Status: $st'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openCreateModeRegiao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_road_outlined, size: 16, color: Colors.white),
                    label: const Text('Nova Região', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          master: _buildRegioesTablePanel(filtered),
          isInspectorOpen: _isInspectorRegiaoOpen && !_isEditingRegiao,
          inspector: FincoreInspectorPanel(
            isOpen: _isInspectorRegiaoOpen && !_isEditingRegiao,
            isEditing: false,
            title: _selectedRegiao?.nome ?? '',
            subtitle: 'Configuração Comercial de Região',
            onClose: () => _selectRegiao(null),
            child: _buildRegioesRightPanelContent(),
          ),
        ),

        // Slide-in Right Drawer Modal when _isEditingRegiao is true
        if (_isEditingRegiao) ...[
          // Backdrop overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingRegiao = false;
                  if (_selectedRegiao == null) {
                    _isInspectorRegiaoOpen = false;
                  }
                });
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Drawer lateral direito
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 550,
            child: Container(
              decoration: const BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: Offset(-4, 0),
                  ),
                ],
              ),
              child: Scaffold(
                backgroundColor: FincoreColors.surface,
                body: Column(
                  children: [
                    // Drawer Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: FincoreColors.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedRegiao == null ? 'Nova Região de Entrega' : 'Editar Região',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: FincoreColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: FincoreColors.textSecondary),
                            onPressed: () {
                              setState(() {
                                _isEditingRegiao = false;
                                if (_selectedRegiao == null) {
                                  _isInspectorRegiaoOpen = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Drawer Body (Form)
                    Expanded(
                      child: _buildRegioesDetailsPanel(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegioesTablePanel(List<TaxaEntrega> list) {
    final allSelected = list.isNotEmpty && list.every((r) => _selectedRegioesIds.contains(r.id));
    final someSelected = list.any((r) => _selectedRegioesIds.contains(r.id)) && !allSelected;

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de Ações em Lote (quando houver regiões selecionadas)
          if (_selectedRegioesIds.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: FincoreColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: FincoreColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedRegioesIds.length} região(ões) selecionada(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Desmarcar todas'),
                    style: TextButton.styleFrom(foregroundColor: FincoreColors.textSecondary),
                    onPressed: () => setState(() => _selectedRegioesIds.clear()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                    label: Text('Excluir Selecionadas (${_selectedRegioesIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: _excluirRegioesEmLote,
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Cabeçalho da Tabela
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: FincoreColors.surfaceElevated,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Checkbox(
                            value: someSelected ? null : allSelected,
                            tristate: true,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedRegioesIds.addAll(list.map((r) => r.id));
                                } else {
                                  _selectedRegioesIds.clear();
                                }
                              });
                            },
                          ),
                        ),
                        const Expanded(flex: 3, child: Text('REGIÃO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        const Expanded(flex: 2, child: Text('TIPO REGRA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        const Expanded(flex: 2, child: Text('TAXA', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        const Expanded(flex: 2, child: Text('PEDIDO MÍN.', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        const Expanded(flex: 2, child: Text('PRAZO', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        const Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        const SizedBox(width: 84, child: Text('AÇÕES', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: FincoreColors.border),

                  // Linhas da Tabela
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('Nenhuma região de entrega encontrada.', style: TextStyle(color: FincoreColors.textMuted)))
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (c, idx) => const Divider(height: 1, color: FincoreColors.border),
                            itemBuilder: (ctx, index) {
                              final reg = list[index];
                              final isSelected = _selectedRegiao?.id == reg.id && _isInspectorRegiaoOpen;
                              final isChecked = _selectedRegioesIds.contains(reg.id);

                              final taxaStr = 'R\$ ${(reg.valorCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',')}';
                              final minStr = 'R\$ ${(reg.pedidoMinimoCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',')}';

                              String tipoRegraStr = 'Fixo';
                              if (reg.tipoRegra == TipoRegraTaxaEntrega.bairro) {
                                tipoRegraStr = 'Bairro (${reg.bairro ?? ""})';
                              } else if (reg.tipoRegra == TipoRegraTaxaEntrega.cep) {
                                tipoRegraStr = 'CEP (${reg.cepInicial ?? ""} - ${reg.cepFinal ?? ""})';
                              } else if (reg.tipoRegra == TipoRegraTaxaEntrega.km) {
                                tipoRegraStr = 'Faixa KM (${reg.distanciaMinKm ?? 0} a ${reg.distanciaMaxKm ?? "∞"} km)';
                              }

                              return InkWell(
                                onTap: () => _selectRegiao(reg),
                                child: Container(
                                  color: isChecked
                                      ? FincoreColors.primary.withValues(alpha: 0.12)
                                      : (isSelected ? FincoreColors.primary.withValues(alpha: 0.08) : Colors.transparent),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        child: Checkbox(
                                          value: isChecked,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedRegioesIds.add(reg.id);
                                              } else {
                                                _selectedRegioesIds.remove(reg.id);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          reg.nome,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          tipoRegraStr,
                                          style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          taxaStr,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          minStr,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          reg.prazoEstimado ?? '--',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: reg.ativo ? FincoreColors.success.withValues(alpha: 0.15) : FincoreColors.textMuted.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              reg.ativo ? 'ATIVA' : 'INATIVA',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: reg.ativo ? FincoreColors.success : FincoreColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 84,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined, size: 18, color: FincoreColors.primary),
                                              tooltip: 'Editar Região',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              onPressed: () => _openEditModeRegiao(reg),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 18, color: FincoreColors.danger),
                                              tooltip: 'Excluir Região',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              onPressed: () => _excluirRegiaoConfirma(reg),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegioesRightPanelContent() {
    final reg = _selectedRegiao;
    if (reg == null) return const SizedBox();

    final taxaStr = 'R\$ ${(reg.valorCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',')}';
    final minStr = 'R\$ ${(reg.pedidoMinimoCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATUS
          const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: reg.ativo ? FincoreColors.success : FincoreColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reg.ativo ? 'Região Ativa' : 'Região Inativa',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CONFIGURAÇÃO COMERCIAL
          const Text('CONFIGURAÇÃO COMERCIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
          const SizedBox(height: 12),

          _buildInspectorInfoRow('Tipo de Regra', reg.tipoRegra == TipoRegraTaxaEntrega.bairro
              ? 'Por Bairro'
              : reg.tipoRegra == TipoRegraTaxaEntrega.cep
                  ? 'Por CEP'
                  : reg.tipoRegra == TipoRegraTaxaEntrega.km
                      ? 'Por Faixa de Distância (KM)'
                      : 'Taxa Fixa Geral'),
          if (reg.tipoRegra == TipoRegraTaxaEntrega.bairro) ...[
            _buildInspectorInfoRow('Bairro Vinculado', reg.bairro ?? '--'),
          ] else if (reg.tipoRegra == TipoRegraTaxaEntrega.cep) ...[
            _buildInspectorInfoRow('Faixa de CEP', '${reg.cepInicial ?? ""} até ${reg.cepFinal ?? ""}'),
          ] else if (reg.tipoRegra == TipoRegraTaxaEntrega.km) ...[
            _buildInspectorInfoRow('Faixa de Distância', '${reg.distanciaMinKm ?? 0} km até ${reg.distanciaMaxKm ?? "sem limite"} km'),
          ],
          _buildInspectorInfoRow('Taxa de Entrega', taxaStr, isHighlight: true),
          _buildInspectorInfoRow('Pedido Mínimo', minStr),
          _buildInspectorInfoRow('Prazo Estimado', reg.prazoEstimado ?? 'Não informado'),
          _buildInspectorInfoRow('Observações', reg.observacoes ?? 'Sem observações cadastradas'),

          const SizedBox(height: 32),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditModeRegiao(reg),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FincoreColors.textPrimary,
                    side: const BorderSide(color: FincoreColors.border),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _excluirRegiaoConfirma(reg),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FincoreColors.danger,
                    side: BorderSide(color: FincoreColors.danger.withValues(alpha: 0.3)),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Excluir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegioesDetailsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _regiaoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Região / Nome
            const Text('Identificação da Região', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
            const SizedBox(height: 6),
            FincoreTextField(
              controller: _regNomeCtrl,
              hintText: 'Ex: Centro, Zona Sul, Região Metropolitana...',
              validator: (v) => v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
            ),
            const SizedBox(height: 16),

            // Tipo de Regra
            const Text('Tipo de Regra de Entrega', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TipoRegraTaxaEntrega>(
              value: _regTipoRegra,
              isExpanded: true,
              dropdownColor: FincoreColors.surfaceOverlay,
              icon: const Icon(Icons.arrow_drop_down, color: FincoreColors.textMuted),
              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: FincoreColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FincoreColors.primary),
                ),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _regTipoRegra = val;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: TipoRegraTaxaEntrega.km, child: Text('Por Faixa de Distância (KM)')),
                DropdownMenuItem(value: TipoRegraTaxaEntrega.bairro, child: Text('Por Bairro')),
                DropdownMenuItem(value: TipoRegraTaxaEntrega.cep, child: Text('Por Faixa de CEP')),
                DropdownMenuItem(value: TipoRegraTaxaEntrega.fixo, child: Text('Taxa Fixa Geral')),
              ],
            ),
            const SizedBox(height: 16),

            // Faixa de Distância em KM
            if (_regTipoRegra == TipoRegraTaxaEntrega.km) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distância Mínima (KM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        const SizedBox(height: 6),
                        FincoreTextField(
                          controller: _regDistMinCtrl,
                          hintText: 'Ex: 0 ou 2.0',
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _regTipoRegra == TipoRegraTaxaEntrega.km && (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distância Máxima (KM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        const SizedBox(height: 6),
                        FincoreTextField(
                          controller: _regDistMaxCtrl,
                          hintText: 'Ex: 8.0 ou 12.0',
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _regTipoRegra == TipoRegraTaxaEntrega.km && (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Bairro
            if (_regTipoRegra == TipoRegraTaxaEntrega.bairro) ...[
              const Text('Nome do Bairro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 6),
              FincoreTextField(
                controller: _regBairroCtrl,
                hintText: 'Digite o nome exato do bairro',
                validator: (v) => _regTipoRegra == TipoRegraTaxaEntrega.bairro && (v == null || v.trim().isEmpty) ? 'Bairro obrigatório' : null,
              ),
              const SizedBox(height: 16),
            ],

            // CEPs
            if (_regTipoRegra == TipoRegraTaxaEntrega.cep) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CEP Inicial', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        const SizedBox(height: 6),
                        FincoreTextField(
                          controller: _regCepIniCtrl,
                          hintText: '00000-000',
                          inputFormatters: FincoreFormatters.cep,
                          validator: (v) => _regTipoRegra == TipoRegraTaxaEntrega.cep && (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CEP Final', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        const SizedBox(height: 6),
                        FincoreTextField(
                          controller: _regCepFinCtrl,
                          hintText: '00000-000',
                          inputFormatters: FincoreFormatters.cep,
                          validator: (v) => _regTipoRegra == TipoRegraTaxaEntrega.cep && (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Valores (Taxa e Pedido Mínimo)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Taxa de Entrega', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                      const SizedBox(height: 6),
                      FincoreTextField(
                        controller: _regValorCtrl,
                        hintText: 'Ex: 8,50 ou 8.50',
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pedido Mínimo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                      const SizedBox(height: 6),
                      FincoreTextField(
                        controller: _regPedidoMinCtrl,
                        hintText: 'Ex: 20,00 ou 20',
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Prazo Estimado
            const Text('Prazo Estimado de Entrega', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
            const SizedBox(height: 6),
            FincoreTextField(
              controller: _regPrazoCtrl,
              hintText: 'Ex: 30-45 min, 1 hora, Imediato...',
            ),
            const SizedBox(height: 16),

            // Observações
            const Text('Observações Internas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
            const SizedBox(height: 6),
            FincoreTextField(
              controller: _regObsCtrl,
              hintText: 'Observações, detalhes de logística da região...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Status Ativo
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _regAtivo
                    ? FincoreColors.success.withValues(alpha: 0.08)
                    : FincoreColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _regAtivo
                      ? FincoreColors.success.withValues(alpha: 0.35)
                      : FincoreColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _regAtivo
                          ? FincoreColors.success.withValues(alpha: 0.18)
                          : FincoreColors.danger.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _regAtivo ? Icons.check_circle_rounded : Icons.block_rounded,
                      color: _regAtivo ? FincoreColors.success : FincoreColors.danger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _regAtivo ? 'Região Ativa' : 'Região Inativa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _regAtivo ? FincoreColors.success : FincoreColors.danger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _regAtivo
                              ? 'Disponível para entregas e rotas'
                              : 'Indisponível para novas entregas',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FincoreColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _regAtivo,
                    activeColor: FincoreColors.success,
                    inactiveThumbColor: FincoreColors.danger,
                    onChanged: (v) => setState(() => _regAtivo = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botão Salvar
            ElevatedButton(
              onPressed: _salvarRegiao,
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Salvar Região', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [


          // Tabela Estilo Linear / Gmail
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Cabeçalho da Tabela
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: FincoreColors.surfaceElevated,
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('CLIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        Expanded(flex: 2, child: Text('TELEFONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        Expanded(flex: 2, child: Text('ÚLT. PEDIDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        Expanded(flex: 1, child: Text('PEDIDOS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                        Expanded(flex: 2, child: Text('AÇÕES', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: FincoreColors.border),

                  // Linhas da Tabela
                  Expanded(
                    child: _controller.visibleClientes.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum cliente encontrado.',
                              style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _controller.visibleClientes.length + (_controller.hasMoreClientes ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
                            itemBuilder: (context, index) {
                              if (index == _controller.visibleClientes.length) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  color: FincoreColors.surfaceElevated.withValues(alpha: 0.5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _controller.loadMoreClientes(count: 50),
                                        icon: Icon(Icons.expand_more_rounded, size: 18, color: FincoreColors.primary),
                                        label: Text(
                                          'Carregar mais 50 clientes (${_controller.remainingClientes} restantes)',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: FincoreColors.primary.withValues(alpha: 0.4)),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final c = _controller.visibleClientes[index];
                              final isSelected = c.id == _controller.selectedCliente?.id;
                              final isVip = c.observacoes.toLowerCase().contains('vip') || (c.apelido?.toLowerCase().contains('vip') ?? false);
                              final countPedidos = _controller.getCountPedidos(c.id.toString());
                              final totalCentavos = _controller.getTotalGastoCentavos(c.id.toString());
                              final isConsumidor = _isConsumidorFinal(c);

                              return InkWell(
                                onTap: () => _selectCliente(c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? FincoreColors.primary.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? Border(left: BorderSide(color: FincoreColors.primary, width: 4))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Nome + Apelido + VIP + Status Pill
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                c.nome,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  fontSize: 13,
                                                  color: isSelected ? FincoreColors.primary : FincoreColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (c.apelido != null && c.apelido!.trim().isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: FincoreColors.primary.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.25)),
                                                ),
                                                child: Text(
                                                  c.apelido!.trim(),
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                            if (isVip) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                                ),
                                                child: const Text(
                                                  'VIP',
                                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: c.ativo ? FincoreColors.success.withValues(alpha: 0.12) : FincoreColors.textMuted.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                c.ativo ? 'ATIVO' : 'INATIVO',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: c.ativo ? FincoreColors.success : FincoreColors.textMuted,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Telefone Formatado
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          c.telefone.isEmpty ? '--' : c.telefoneFormatado,
                                          style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                                        ),
                                      ),
                                      // Último Pedido
                                      Expanded(
                                        flex: 2,
                                        child: Builder(
                                          builder: (_) {
                                            final ult = _controller.getUltimoPedido(c.id.toString());
                                            if (ult == null) {
                                              return const Text(
                                                'Nunca comprou',
                                                style: TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                                              );
                                            }
                                            final dataRef = ult.dataHoraEntregaPrevista?.toLocal() ?? ult.dataHoraCriacao.toLocal();
                                            final dataStr = DateFormat('dd/MM/yyyy').format(dataRef);
                                            return Text(
                                              '#${ult.numeroPedido.toString().padLeft(4, '0')} ($dataStr)',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                            );
                                          },
                                        ),
                                      ),
                                      // Pedidos
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: FincoreColors.surfaceElevated,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$countPedidos',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Total
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          dinheiro(totalCentavos),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                        ),
                                      ),
                                      // Ações Rápidas por Linha
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 🛍️ Novo Pedido
                                            IconButton(
                                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                              color: FincoreColors.primary,
                                              tooltip: 'Novo Pedido para ${c.nome}',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              onPressed: () => _iniciarNovoPedidoParaCliente(c),
                                            ),
                                            // 💬 WhatsApp (Badge verde destacado)
                                            if (c.telefone.isNotEmpty && c.telefone != '00000000000')
                                              InkWell(
                                                onTap: () => _abrirWhatsAppModal(c),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Tooltip(
                                                  message: 'Chamar ${c.nome} no WhatsApp',
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                                                    ),
                                                    child: const Icon(Icons.chat_bubble_rounded, size: 13, color: Color(0xFF25D366)),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            Container(width: 1, height: 14, color: FincoreColors.border),
                                            const SizedBox(width: 4),
                                            // 🔄 Toggle Ativar/Inativar (Interruptor Liga/Desliga distinto)
                                            if (!isConsumidor)
                                              IconButton(
                                                icon: Icon(
                                                  c.ativo ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                                  size: 22,
                                                ),
                                                color: c.ativo ? FincoreColors.primary : FincoreColors.textMuted,
                                                tooltip: c.ativo ? 'Cliente Ativo (Clique para Inativar)' : 'Cliente Inativo (Clique para Ativar)',
                                                padding: const EdgeInsets.all(2),
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => _toggleStatusCliente(c),
                                              ),
                                            // ✏️ Editar
                                            if (!isConsumidor)
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                color: FincoreColors.textSecondary,
                                                tooltip: 'Editar Cadastro',
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => _openEditMode(c),
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
                  // Rodapé com Contador de Clientes e Paginação
                  const Divider(height: 1, color: FincoreColors.border),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: FincoreColors.surfaceElevated,
                    child: Row(
                      children: [
                        Text(
                          'Exibindo ${_controller.visibleClientes.length} de ${_controller.filteredClientes.length} clientes (${_controller.clientes.length} no total)',
                          style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (_controller.hasMoreClientes)
                          InkWell(
                            onTap: () => _controller.loadMoreClientes(count: 50),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+50 clientes (${_controller.remainingClientes} restantes)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: FincoreColors.primary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanelContent() {
    final c = _controller.selectedCliente;
    if (c == null) return const SizedBox.shrink();

    final initials = c.nome.trim().isNotEmpty ? c.nome.trim().substring(0, 1).toUpperCase() : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho do Painel Lateral
        Container(
          padding: const EdgeInsets.all(16),
          color: FincoreColors.surfaceElevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: FincoreColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.primary, fontSize: 16),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.ativo ? FincoreColors.success.withValues(alpha: 0.15) : FincoreColors.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.ativo ? FincoreColors.success : FincoreColors.textMuted),
                        ),
                        child: Text(
                          c.ativo ? '🟢 ATIVO' : '🔴 INATIVO',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.ativo ? FincoreColors.success : FincoreColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildSyncIndicator(c.metadata.syncStatus, c.metadata.lastSyncedAt),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                c.nome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FincoreColors.textPrimary),
              ),
              if (c.apelido != null && c.apelido!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  c.apelido!,
                  style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: FincoreColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    c.telefone.isEmpty ? 'Sem telefone' : c.telefoneFormatado,
                    style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FincoreColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 12, color: FincoreColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${_controller.getCountPedidos(c.id.toString())} pedidos',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Total: ${dinheiro(_controller.getTotalGastoCentavos(c.id.toString()))}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insights_rounded, size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          'Ticket Médio: ${dinheiro(_controller.getTicketMedioCentavos(c.id.toString()))}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botões de Ação Rápida no Painel (Linha 1: Novo Pedido + WhatsApp)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: () => _iniciarNovoPedidoParaCliente(c),
                      style: FilledButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                      label: const Text('Novo Pedido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  if (c.telefone.isNotEmpty && c.telefone != '00000000000') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _abrirWhatsAppModal(c),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF25D366)),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF25D366))),
                      ),
                    ),
                  ],
                ],
              ),
              if (!_isConsumidorFinal(c)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditMode(c),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: FincoreColors.border),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 15, color: FincoreColors.textPrimary),
                        label: const Text('Editar', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleStatusCliente(c),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: c.ativo ? Colors.amber.withValues(alpha: 0.6) : FincoreColors.success.withValues(alpha: 0.6)),
                        ),
                        icon: Icon(c.ativo ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, size: 18, color: c.ativo ? FincoreColors.primary : FincoreColors.textMuted),
                        label: Text(c.ativo ? 'Inativar' : 'Ativar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ativo ? Colors.amber[800] : FincoreColors.success)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _excluirCliente(c),
                      tooltip: 'Excluir Cliente',
                      style: IconButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: FincoreColors.border),

        // TabBar
        TabBar(
          controller: _tabController,
          labelColor: FincoreColors.primary,
          unselectedLabelColor: FincoreColors.textMuted,
          indicatorColor: FincoreColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            const Tab(text: 'Resumo'),
            Tab(text: 'Pedidos (${_controller.getCountPedidos(c.id.toString())})'),
            const Tab(text: 'Endereço'),
            const Tab(text: 'Financeiro'),
          ],
        ),
        const Divider(height: 1, color: FincoreColors.border),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAbaResumo(c),
              _buildAbaPedidos(c),
              _buildAbaEnderecos(),
              _buildAbaFinanceiro(c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbaResumo(Cliente c) {
    final mainAddressStr = _controller.enderecos.isNotEmpty
        ? '${_controller.enderecos.first.logradouro}, ${_controller.enderecos.first.numero} - ${_controller.enderecos.first.bairro} (${_controller.enderecos.first.cidade})'
        : 'Sem endereço cadastrado';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isConsumidorFinal(c)) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cliente do Sistema: O cadastro de Consumidor Final é imutável e protegido pelo sistema por integridade referencial.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: _panelStatCard(
                'Ticket Médio',
                dinheiro(_controller.getTicketMedioCentavos(c.id.toString())),
                Icons.shopping_bag_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _panelStatCard(
                'Total Gasto',
                dinheiro(_controller.getTotalGastoCentavos(c.id.toString())),
                Icons.monetization_on_outlined,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _panelStatCard(
          'Recorrência de Vendas',
          '${_controller.getCountPedidos(c.id.toString())} pedidos realizados',
          Icons.repeat,
          Colors.blue,
        ),
        const SizedBox(height: 16),

        const Text('Endereço Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Text(
            mainAddressStr,
            style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary),
          ),
        ),

        if (c.observacoes.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Observações / Preferências', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Text(
              c.observacoes,
              style: const TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ),
        ],
      ],
    );
  }

  void _exibirEspelhoPedido(BuildContext context, PedidoData pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<List<ItemPedidoData>>(
              future: _controller.getItensDoPedido(pedido.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: FincoreColors.primary),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Erro ao carregar itens: ${snapshot.error}',
                        style: TextStyle(color: FincoreColors.danger),
                      ),
                    ),
                  );
                }
                final itens = snapshot.data ?? [];
                final dataRef = pedido.dataHoraEntregaPrevista?.toLocal() ?? pedido.dataHoraCriacao.toLocal();
                final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(dataRef);
                final totalUnidades = itens.fold<double>(0.0, (sum, i) => sum + i.quantidade);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Espelho do Pedido #${pedido.numeroPedido.toString().padLeft(4, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: FincoreColors.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: FincoreColors.border, height: 24),

                    // --- Metadata ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              pedido.tipoLogistica.toLowerCase().contains('entrega')
                                  ? Icons.delivery_dining_outlined
                                  : Icons.storefront_outlined,
                              size: 16,
                              color: const Color(0xFF06B6D4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pedido.tipoLogistica.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF06B6D4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dataStr,
                          style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Items List ---
                    Text(
                      'ITENS DO PEDIDO',
                      style: TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final item in itens) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      '${item.quantidade.toInt()}x',
                                      style: TextStyle(
                                        color: FincoreColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.nomeProduto,
                                        style: TextStyle(
                                          color: FincoreColors.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      dinheiro(item.valorTotalCentavos),
                                      style: TextStyle(
                                        color: FincoreColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: FincoreColors.border, height: 1),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Totals Gradient Box ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FincoreColors.primary.withValues(alpha: 0.12),
                            FincoreColors.primary.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Volumes / Itens',
                                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                              ),
                              Text(
                                '${itens.length} item(ns) / ${totalUnidades.toInt()} un.',
                                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (pedido.valorTaxaEntregaCentavos > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Taxa de Entrega',
                                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                                ),
                                Text(
                                  dinheiro(pedido.valorTaxaEntregaCentavos),
                                  style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                          Divider(color: FincoreColors.border, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'VALOR TOTAL',
                                style: TextStyle(
                                  color: FincoreColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dinheiro(pedido.valorTotalCentavos),
                                style: TextStyle(
                                  color: FincoreColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Actions Row ---
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: FincoreColors.textSecondary,
                              side: BorderSide(color: FincoreColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('FECHAR'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FincoreColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.repeat, size: 16),
                            label: const Text('REPETIR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdvExpressScreen(repetirPedidoId: pedido.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbaPedidos(Cliente c) {
    final clientPedidos = _controller.getPedidosDoCliente(c.id.toString());
    if (clientPedidos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum pedido realizado.',
          style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clientPedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = clientPedidos[index];
        final dataRef = p.dataHoraEntregaPrevista?.toLocal() ?? p.dataHoraCriacao.toLocal();
        final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(dataRef);
        final isCancelado = p.status == 'cancelado';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _exibirEspelhoPedido(context, p),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FincoreColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pedido #${p.numeroPedido.toString().padLeft(4, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCancelado
                              ? Colors.red.withValues(alpha: 0.1)
                              : FincoreColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCancelado
                                ? Colors.red.withValues(alpha: 0.3)
                                : FincoreColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          (p.status.isEmpty ? 'Confirmado' : p.status).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isCancelado ? Colors.red : FincoreColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        p.tipoLogistica.toLowerCase().contains('entrega')
                            ? Icons.delivery_dining_outlined
                            : Icons.storefront_outlined,
                        size: 14,
                        color: FincoreColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.tipoLogistica,
                        style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        dataStr,
                        style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                      ),
                    ],
                  ),
                  const Divider(height: 12, color: FincoreColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.formaPagamentoNome ?? 'Sem pagamento',
                        style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                      ),
                      Text(
                        dinheiro(p.valorTotalCentavos),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FincoreColors.primary,
                        side: BorderSide(color: FincoreColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.repeat, size: 14),
                      label: const Text('VER DETALHES & REPETIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _exibirEspelhoPedido(context, p),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbaEnderecos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Locais de Entrega (${_controller.enderecos.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
            ),
            TextButton.icon(
              onPressed: () => _openEditorEndereco(null),
              icon: Icon(Icons.add_location_alt_outlined, size: 14, color: FincoreColors.primary),
              label: Text('Novo Local', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_controller.enderecos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FincoreColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FincoreColors.border),
            ),
            child: const Text(
              'Nenhum endereço cadastrado. Clique em "Novo Local" para adicionar.',
              style: TextStyle(fontSize: 11, color: FincoreColors.textMuted),
            ),
          )
        else
          ...List.generate(_controller.enderecos.length, (index) {
            final loc = _controller.enderecos[index];
            return _buildAddressCard(loc, index == 0);
          }),
      ],
    );
  }

  Widget _buildAddressCard(LocalEntrega loc, bool isPrincipal) {
    final taxa = _controller.resolverTaxaParaEndereco(loc);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do endereço (Nome + Principal Badge)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.nomeIdentificador.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: FincoreColors.textPrimary, letterSpacing: 0.8),
                ),
                if (isPrincipal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place, size: 10, color: FincoreColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'PRINCIPAL',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: FincoreColors.border, height: 1),
          // Conteúdo (Endereço e botões)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc.logradouro}, ${loc.numero}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${loc.bairro} — ${loc.cidade}',
                  style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                ),
                if (taxa != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.map_outlined, size: 12, color: FincoreColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Região: ${taxa.nome}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (taxa.prazoEstimado != null || taxa.pedidoMinimoCentavos > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (taxa.prazoEstimado != null) ...[
                                const Icon(Icons.timer_outlined, size: 12, color: FincoreColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  taxa.prazoEstimado!,
                                  style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                ),
                              ],
                              if (taxa.prazoEstimado != null && taxa.pedidoMinimoCentavos > 0)
                                const Text('  •  ', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                              if (taxa.pedidoMinimoCentavos > 0) ...[
                                const Icon(Icons.shopping_bag_outlined, size: 12, color: FincoreColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'Ped. Mín: R\$ ${(taxa.pedidoMinimoCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',')}',
                                  style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (loc.cep.isNotEmpty || loc.referencia.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (loc.cep.isNotEmpty) 'CEP: ${loc.cep}',
                      if (loc.referencia.isNotEmpty) 'Ref: ${loc.referencia}',
                    ].join('  •  '),
                    style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Taxa de entrega
                    if (taxa != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delivery_dining, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Taxa R\$ ${(taxa.valorCentavos / 100.0).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Sem taxa',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _openCadastroTaxa(loc.bairro, loc.cep),
                            child: Text(
                              '[ Cadastrar ]',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                            ),
                          ),
                        ],
                      ),
                    // Ações
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: FincoreColors.textSecondary),
                          onPressed: () => _openEditorEndereco(loc),
                          tooltip: 'Editar local',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          onPressed: () => _controller.excluirEndereco(loc),
                          tooltip: 'Excluir local',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }



  Widget _discreteMetricText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: FincoreColors.textSecondary,
      ),
    );
  }

  bool _isConsumidorFinal(Cliente? client) {
    if (client == null) return false;
    final nome = client.nome.toLowerCase();
    return nome.contains('consumidor final') ||
        nome.contains('cliente consumidor') ||
        client.telefone == '00000000000' ||
        client.observacoes.toLowerCase().contains('imutável');
  }

  Future<void> _abrirWhatsAppModal(Cliente c) async {
    String? enderecoFormatado;
    final enderecosDoCliente = _controller.enderecos.where((e) => e.clienteId == c.id).toList();
    if (enderecosDoCliente.isNotEmpty) {
      final loc = enderecosDoCliente.first;
      enderecoFormatado = '${loc.logradouro}, ${loc.numero} - ${loc.bairro}, ${loc.cidade}';
    }

    String? empresaNome;
    try {
      if (TenantContext().hasContext) {
        empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
            ? TenantContext().empresa.nomeFantasia
            : TenantContext().empresa.razaoSocial;
      }
    } catch (_) {}

    await WhatsAppDialog.show(
      context,
      rawPhone: c.telefone,
      clienteNome: c.nome,
      enderecoCliente: enderecoFormatado,
      nomeEmpresa: empresaNome,
    );
  }

  Widget _buildInspectorInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
              color: isHighlight ? FincoreColors.primary : FincoreColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Aba Financeiro do Cliente ─────────────────────────────────────────────

  Widget _buildAbaFinanceiro(Cliente c) {
    final contasCtrl = DependencyInjection().tryGet<ContasReceberController>() ?? ContasReceberController();
    bool apenasNotasPrazo = true;

    return StatefulBuilder(
      builder: (context, setAbaState) {
        return FutureBuilder<void>(
          future: contasCtrl.carregar(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && contasCtrl.titulos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final pedidosValidos = _controller.getPedidosDoCliente(c.id.toString())
                .where((p) => p.status != 'cancelado')
                .toList();

            final totalGastoCentavos = _controller.getTotalGastoCentavos(c.id.toString());
            final totalQtdPedidos = _controller.getCountPedidos(c.id.toString());
            final ticketMedioCentavos = _controller.getTicketMedioCentavos(c.id.toString());

            final todosTitulos = contasCtrl.getTitulosPorCliente(c.id, clienteNome: c.nome);

            if (todosTitulos.isEmpty && pedidosValidos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 40, color: FincoreColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'Nenhuma movimentação financeira encontrada para este cliente.',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            // Complementa o histórico completo com pedidos pagos no caixa à vista (ex: Dinheiro)
            // que não geraram duplicata de contas a receber pendente
            final titulosCompletos = List<TituloReceber>.from(todosTitulos);
            for (final p in pedidosValidos) {
              final jaExiste = todosTitulos.any((t) => t.pedidoId == p.id);
              if (!jaExiste) {
                titulosCompletos.add(
                  TituloReceber(
                    id: 'caixa_${p.id}',
                    pedidoId: p.id,
                    numeroPedido: p.numeroPedido,
                    clienteId: p.clienteId,
                    clienteNome: c.nome,
                    clienteTelefone: c.telefone,
                    formaPagamentoNome: p.formaPagamentoNome ?? 'Dinheiro (À Vista)',
                    formaPagamentoTipo: 'dinheiro',
                    valorTotalCentavos: p.valorTotalCentavos,
                    status: StatusTituloReceber.recebido,
                    dataEmissao: p.dataHoraCriacao,
                    dataEntrega: p.dataHoraCriacao,
                    dataVencimento: p.dataHoraCriacao,
                    dataRecebimento: p.dataHoraCriacao,
                    canalOrigem: p.canalOrigem,
                  ),
                );
              }
            }
            titulosCompletos.sort((a, b) => b.dataEmissao.compareTo(a.dataEmissao));

            final titulosExibidos = apenasNotasPrazo
                ? titulosCompletos.where((t) => t.isNotaPrazo).toList()
                : titulosCompletos;

            // Pendências em aberto (Notas a Prazo / Fiado pendente + PIX aguardando validação de conta)
            final totalAReceberCentavos = todosTitulos
                .where((t) => !t.isPagoPeloCliente && t.status != StatusTituloReceber.cancelado)
                .fold<int>(0, (sum, t) => sum + t.valorTotalCentavos);

            final qtdPendentes = todosTitulos
                .where((t) => !t.isPagoPeloCliente && t.status != StatusTituloReceber.cancelado)
                .length;

            final totalQuitadoCentavos = (totalGastoCentavos >= totalAReceberCentavos)
                ? (totalGastoCentavos - totalAReceberCentavos)
                : titulosCompletos.where((t) => t.isPagoPeloCliente).fold<int>(0, (sum, t) => sum + t.valorTotalCentavos);

            final qtdLiquidados = totalQtdPedidos >= qtdPendentes ? (totalQtdPedidos - qtdPendentes) : titulosCompletos.where((t) => t.isPagoPeloCliente).length;

            final totalAtrasadoCentavos = todosTitulos
                .where((t) => t.isNotaPrazo && t.status == StatusTituloReceber.atrasado)
                .fold<int>(0, (sum, t) => sum + t.valorTotalCentavos);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seletor de Filtro de Modalidade (Nota a Prazo vs Completo)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: FincoreColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setAbaState(() => apenasNotasPrazo = true),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: apenasNotasPrazo ? FincoreColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 14, color: apenasNotasPrazo ? Colors.white : FincoreColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Apenas Nota a Prazo (${titulosCompletos.where((t) => t.isNotaPrazo).length})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: apenasNotasPrazo ? Colors.white : FincoreColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => setAbaState(() => apenasNotasPrazo = false),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !apenasNotasPrazo ? FincoreColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 14, color: !apenasNotasPrazo ? Colors.white : FincoreColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Todo o Histórico (${titulosCompletos.length})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: !apenasNotasPrazo ? Colors.white : FincoreColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Resumo de KPIs do Cliente: Total Compras, Ticket Médio, Pendente, Quitado
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FincoreColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL EM COMPRAS',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: FincoreColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dinheiro(totalGastoCentavos),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: FincoreColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalQtdPedidos pedido(s) realizados',
                              style: const TextStyle(fontSize: 9.5, color: FincoreColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TICKET MÉDIO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dinheiro(ticketMedioCentavos),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Gasto médio por pedido',
                              style: TextStyle(fontSize: 9.5, color: FincoreColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: totalAReceberCentavos > 0
                              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                              : FincoreColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: totalAReceberCentavos > 0
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : FincoreColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A RECEBER / PENDENTE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: totalAReceberCentavos > 0 ? const Color(0xFFEF4444) : FincoreColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dinheiro(totalAReceberCentavos),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: totalAReceberCentavos > 0 ? const Color(0xFFEF4444) : FincoreColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalAtrasadoCentavos > 0
                                  ? '${dinheiro(totalAtrasadoCentavos)} vencido'
                                  : '$qtdPendentes pendência(s)',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: totalAtrasadoCentavos > 0 ? const Color(0xFFEF4444) : FincoreColors.textMuted,
                                fontWeight: totalAtrasadoCentavos > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL QUITADO / PAGO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dinheiro(totalQuitadoCentavos),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$qtdLiquidados pedido(s) liquidados',
                              style: const TextStyle(fontSize: 9.5, color: FincoreColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      apenasNotasPrazo
                          ? 'Pendências em Nota a Prazo (${titulosExibidos.length})'
                          : 'Títulos e Pagamentos (${titulosExibidos.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (titulosExibidos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'Nenhum título em Nota a Prazo encontrado para este cliente.',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                    ),
                  )
                else
                  ...titulosExibidos.map((t) => _buildClienteTituloCard(t, c, contasCtrl)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildClienteTituloCard(TituloReceber t, Cliente c, ContasReceberController contasCtrl) {
    final isPixAguardando = t.isPix && !t.isRecebido;
    final isFiadoAtrasado = t.isNotaPrazo && t.status == StatusTituloReceber.atrasado;
    final isFiadoPendente = t.isNotaPrazo && !t.isRecebido;

    final Color statusColor;
    final String statusLabel;

    if (t.isPix) {
      if (t.isRecebido) {
        statusColor = const Color(0xFF10B981);
        statusLabel = 'PIX VALIDADO';
      } else {
        statusColor = const Color(0xFF0284C7);
        statusLabel = 'PIX A VALIDAR EM CONTA';
      }
    } else if (t.isNotaPrazo) {
      if (t.isRecebido) {
        statusColor = const Color(0xFF10B981);
        statusLabel = 'QUITADO / PAGO';
      } else if (isFiadoAtrasado) {
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'ATRASADO (FIADO)';
      } else {
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'A RECEBER (FIADO)';
      }
    } else {
      // Cartão, Dinheiro, etc.
      statusColor = const Color(0xFF10B981);
      statusLabel = 'PAGO PELO CLIENTE';
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isPixAguardando || isFiadoPendente) ? statusColor.withValues(alpha: 0.45) : FincoreColors.border,
          width: (isPixAguardando || isFiadoPendente) ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    t.friendlyNumeroPedido,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      PedidoMirrorDialog.show(
                        context,
                        pedidoId: t.pedidoId,
                        numeroPedido: t.numeroPedido,
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: FincoreColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 12, color: FincoreColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Ver Pedido',
                            style: TextStyle(
                              color: FincoreColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                t.isPix ? Icons.pix_rounded : Icons.payment_outlined,
                size: 14,
                color: t.isPix ? const Color(0xFF32BCAD) : FincoreColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                t.formaPagamentoNome,
                style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
              ),
              const Spacer(),
              Text(
                dinheiro(t.valorTotalCentavos),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: FincoreColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido: ${dateFormat.format(t.dataEmissao)}',
                style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
              ),
              Text(
                'Entrega: ${dateFormat.format(t.dataEntrega)}',
                style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (t.isPix) ...[
            if (t.isRecebido) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'PIX Validado em conta em: ${dateFormat.format(t.dataRecebimento ?? t.dataEmissao)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 12, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  const Text(
                    'Aguardando conferência de comprovante / crédito em conta',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ] else if (t.isNotaPrazo) ...[
            if (t.isRecebido) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Fiado quitado em: ${dateFormat.format(t.dataRecebimento ?? t.dataEmissao)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Vencimento do Fiado: ${dateFormat.format(t.dataVencimento)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isFiadoAtrasado ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  fontWeight: isFiadoAtrasado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  t.isCartao
                      ? 'Pago no ato · Repasse Adquirente: ${t.isRecebido ? "Liquidado" : "Previsão ${dateFormat.format(t.dataVencimento)}"}'
                      : 'Pago no ato · ${dateFormat.format(t.dataEmissao)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          if (isPixAguardando || isFiadoPendente) ...[
            const Divider(height: 14, color: FincoreColors.border),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await DialogBaixaTitulo.show(
                        context,
                        item: t,
                        controller: contasCtrl,
                      );
                      if (ok && mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: FincoreColors.success,
                            content: Text(t.isPix ? 'PIX validado e confirmado em conta!' : 'Baixa de fiado confirmada com sucesso!'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPixAguardando ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: Icon(isPixAguardando ? Icons.verified_user_rounded : Icons.price_check_rounded, size: 16),
                    label: Text(isPixAguardando ? 'Validar PIX em Conta' : 'Dar Baixa no Fiado', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (t.isNotaPrazo && c.telefone.isNotEmpty && c.telefone != '00000000000') ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _abrirWhatsAppCobrancaTitulo(t, c),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Cobrar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _abrirWhatsAppCobrancaTitulo(TituloReceber t, Cliente c) async {
    final tel = t.clienteTelefone ?? c.telefone;
    if (tel.isEmpty || tel == '00000000000') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone não informado para este cliente.')),
      );
      return;
    }

    String? empresaNome;
    try {
      if (TenantContext().hasContext) {
        empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
            ? TenantContext().empresa.nomeFantasia
            : TenantContext().empresa.razaoSocial;
      }
    } catch (_) {}

    PixWhatsAppInfo? pixInfo;
    if (t.isPix && t.pixChave != null && t.pixChave!.isNotEmpty) {
      try {
        final db = DependencyInjection().get<FincoreDatabase>();
        final config = await (db.select(db.empresaConfiguracaoTable)).getSingleOrNull();
        final copiaECola = PixGenerator.gerarCopiaCola(
          chave: t.pixChave!,
          favorecido: (config?.pixFavorecido != null && config!.pixFavorecido!.isNotEmpty)
              ? config.pixFavorecido!
              : (empresaNome ?? 'FINCORE'),
          cidade: 'Sorocaba',
          valor: t.valorTotalCentavos / 100,
          tipoChave: t.pixTipoChave,
        );
        pixInfo = PixWhatsAppInfo(
          chaveDisplay: t.pixChave!,
          tipoChave: t.pixTipoChave ?? 'PIX',
          copiaECola: copiaECola,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    await WhatsAppDialog.show(
      context,
      rawPhone: tel,
      clienteNome: c.nome,
      initialMessage: WhatsAppService.gerarTextoLembretePagamento(
        nomeCliente: c.nome,
        numeroPedidoOuId: t.friendlyNumeroPedido,
        valor: t.valorTotalCentavos / 100,
        nomeEmpresa: empresaNome,
      ),
      pixInfo: pixInfo,
      numeroPedido: t.friendlyNumeroPedido,
      nomeEmpresa: empresaNome,
    );
  }
}
