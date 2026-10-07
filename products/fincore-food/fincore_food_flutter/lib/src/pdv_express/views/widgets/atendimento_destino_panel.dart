import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_food_flutter/src/shared/services/cep_service.dart';
import 'package:fincore_food_flutter/src/shared/services/delivery_fee_service.dart';
import '../../controllers/pdv_express_controller.dart';
import 'customer_selection_modal.dart';
import 'package:fincore_food_flutter/src/clientes/views/widgets/cliente_form_dialog.dart';

/// Coluna 1 da Workstation: Atendimento & Destino
/// Permite definir rapidamente o Cliente (Consumidor Final / Cadastrado),
/// Destino (Balcão, Retirada, Delivery), Endereço, Taxa de Entrega, Taxa de Serviço e Data/Hora Agendada.
class AtendimentoDestinoPanel extends StatefulWidget {
  final PdvExpressController controller;
  final VoidCallback? onOpenCustomerSearch;

  const AtendimentoDestinoPanel({
    super.key,
    required this.controller,
    this.onOpenCustomerSearch,
  });

  @override
  State<AtendimentoDestinoPanel> createState() => _AtendimentoDestinoPanelState();
}

class _AtendimentoDestinoPanelState extends State<AtendimentoDestinoPanel> {
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController();
  final _taxaServicoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _novoEnderecoNomeCtrl = TextEditingController(text: 'Trabalho');

  bool _isBuscandoCep = false;
  bool _isCalculandoFrete = false;
  String? _regraTaxaDescricao;
  bool _isAgendado = true;
  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay _horaSelecionada = TimeOfDay.now();

  List<LocalEntrega> _locaisDoCliente = [];
  LocalEntrega? _localSelecionado;
  bool _isNovoEndereco = false;
  String? _lastClienteId;
  Timer? _debounceRecalculo;

  @override
  void initState() {
    super.initState();
    _sincronizarComController(isInitial: true);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounceRecalculo?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _referenciaCtrl.dispose();
    _taxaCtrl.dispose();
    _taxaServicoCtrl.dispose();
    _obsCtrl.dispose();
    _novoEnderecoNomeCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _sincronizarComController(isInitial: false);
  }

  void _sincronizarComController({bool isInitial = false}) {
    final entrega = widget.controller.entrega;
    final clienteId = widget.controller.cliente.id;

    if (clienteId != _lastClienteId) {
      _lastClienteId = clienteId;
      _carregarLocaisDoCliente(clienteId);
    }

    if (_cepCtrl.text != entrega.cep) {
      _cepCtrl.text = entrega.cep;
    }
    if (_logradouroCtrl.text != entrega.logradouro) {
      _logradouroCtrl.text = entrega.logradouro;
    }
    if (_numeroCtrl.text != entrega.numero) {
      _numeroCtrl.text = entrega.numero;
    }
    if (_bairroCtrl.text != entrega.bairro) {
      _bairroCtrl.text = entrega.bairro;
    }
    if (_referenciaCtrl.text != entrega.referencia) {
      _referenciaCtrl.text = entrega.referencia;
    }

    final taxaFormatada = entrega.taxaEntregaCentavos > 0
        ? (entrega.taxaEntregaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '0,00';
    if (_taxaCtrl.text != taxaFormatada && !_taxaCtrl.selection.isValid) {
      _taxaCtrl.text = taxaFormatada;
    }

    final servicoFormatado = entrega.taxaServicoCentavos > 0
        ? (entrega.taxaServicoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '0,00';
    if (_taxaServicoCtrl.text != servicoFormatado && !_taxaServicoCtrl.selection.isValid) {
      _taxaServicoCtrl.text = servicoFormatado;
    }

    if (_obsCtrl.text != entrega.observacoes) {
      _obsCtrl.text = entrega.observacoes;
    }

    final dataHora = entrega.dataHora;
    if (isInitial) {
      _isAgendado = true;
      if (dataHora.difference(DateTime.now()).inMinutes.abs() < 15) {
        _dataSelecionada = DateTime.now().add(const Duration(hours: 2));
        _horaSelecionada = TimeOfDay.fromDateTime(_dataSelecionada);
        WidgetsBinding.instance.addPostFrameCallback((_) => _salvarDataHoraAgendada());
      } else {
        _dataSelecionada = dataHora;
        _horaSelecionada = TimeOfDay(hour: dataHora.hour, minute: dataHora.minute);
      }
    }
  }

  Future<void> _carregarLocaisDoCliente(String? clienteId) async {
    if (clienteId == null || clienteId.isEmpty) {
      if (mounted) {
        setState(() {
          _locaisDoCliente = [];
          _localSelecionado = null;
          _isNovoEndereco = false;
        });
      }
      return;
    }

    try {
      final locais = await widget.controller.localRepo.findByClienteId(clienteId);
      if (mounted) {
        setState(() {
          _locaisDoCliente = locais;
          if (locais.isNotEmpty) {
            final entrega = widget.controller.entrega;
            final match = locais.where((l) =>
              l.logradouro.trim().toLowerCase() == entrega.logradouro.trim().toLowerCase() &&
              l.numero.trim() == entrega.numero.trim()
            ).firstOrNull;

            _localSelecionado = match ?? locais.first;
            _isNovoEndereco = false;

            if (entrega.logradouro.isEmpty && _localSelecionado != null) {
              _preencherComLocal(_localSelecionado!);
            }
          } else {
            _localSelecionado = null;
            _isNovoEndereco = true;
          }
        });
      }
    } catch (e) {
      debugPrint('[AtendimentoDestinoPanel] Erro ao carregar locais do cliente: $e');
    }
  }

  void _preencherComLocal(LocalEntrega local) {
    setState(() {
      _localSelecionado = local;
      _isNovoEndereco = false;
      _cepCtrl.text = local.cep;
      _logradouroCtrl.text = local.logradouro;
      _numeroCtrl.text = local.numero;
      _bairroCtrl.text = local.bairro;
      _referenciaCtrl.text = local.referencia;
    });
    _atualizarEndereco();
    _recalcularTaxaEntrega();
  }

  void _selecionarOutroEndereco() {
    setState(() {
      _localSelecionado = null;
      _isNovoEndereco = true;
      _cepCtrl.clear();
      _logradouroCtrl.clear();
      _numeroCtrl.clear();
      _bairroCtrl.clear();
      _referenciaCtrl.clear();
      _regraTaxaDescricao = null;
      _taxaCtrl.text = '0,00';
    });
    _atualizarEndereco();
  }

  Future<void> _salvarEnderecoNoCadastroCliente() async {
    final clienteId = widget.controller.cliente.id;
    if (clienteId == null) return;

    final logradouro = _logradouroCtrl.text.trim();
    final numero = _numeroCtrl.text.trim();
    final bairro = _bairroCtrl.text.trim();
    final cep = _cepCtrl.text.trim();
    final referencia = _referenciaCtrl.text.trim();
    final nomeId = _novoEnderecoNomeCtrl.text.trim().isNotEmpty
        ? _novoEnderecoNomeCtrl.text.trim()
        : 'Outro';

    if (logradouro.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha ao menos a rua antes de salvar o endereço.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final tenantCtx = widget.controller.tenantContext;
      final now = DateTime.now().toUtc();
      final novoLocal = LocalEntrega(
        id: const Uuid().v4(),
        tenantId: tenantCtx.tenantId,
        clienteId: clienteId,
        nomeIdentificador: nomeId,
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        cidade: tenantCtx.empresa.cidade?.isNotEmpty == true ? tenantCtx.empresa.cidade! : 'Pouso Alegre',
        cep: cep,
        referencia: referencia,
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: now,
          updatedAt: now,
          createdBy: tenantCtx.usuario.id,
          updatedBy: tenantCtx.usuario.id,
          syncStatus: SyncStatus.pending,
        ),
      );

      await widget.controller.localRepo.save(novoLocal);
      await _carregarLocaisDoCliente(clienteId);

      if (mounted) {
        setState(() {
          _localSelecionado = novoLocal;
          _isNovoEndereco = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Novo endereço "$nomeId" salvo com sucesso para o cliente!'),
            backgroundColor: FincoreColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AtendimentoDestinoPanel] Erro ao salvar endereço no cliente: $e');
    }
  }

  Future<void> _abrirDialogEditarEndereco(LocalEntrega local) async {
    final clienteId = widget.controller.cliente.id;
    if (clienteId == null) return;

    final idCtrl = TextEditingController(text: local.nomeIdentificador);
    final cepCtrl = TextEditingController(text: local.cep);
    final logrCtrl = TextEditingController(text: local.logradouro);
    final numCtrl = TextEditingController(text: local.numero);
    final bairroCtrl = TextEditingController(text: local.bairro);
    final refCtrl = TextEditingController(text: local.referencia);
    bool buscandoCepDialog = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_location_alt_outlined, color: FincoreColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Alterar Endereço: ${local.nomeIdentificador}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildCompactInput(
                    label: 'Identificador (ex: Casa, Trabalho)',
                    controller: idCtrl,
                    hint: 'Ex: Casa',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildCompactInput(
                          label: 'CEP',
                          controller: cepCtrl,
                          hint: '00000-000',
                          keyboardType: TextInputType.number,
                          suffix: buscandoCepDialog
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  icon: Icon(Icons.search, size: 14, color: FincoreColors.primary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final clean = cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                                    if (clean.length == 8) {
                                      setDlgState(() => buscandoCepDialog = true);
                                      try {
                                        final end = await CepService.consultarCep(clean);
                                        if (end != null) {
                                          if (end.logradouro.isNotEmpty) logrCtrl.text = end.logradouro;
                                          if (end.bairro.isNotEmpty) bairroCtrl.text = end.bairro;
                                        }
                                      } finally {
                                        setDlgState(() => buscandoCepDialog = false);
                                      }
                                    }
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildCompactInput(
                          label: 'Número',
                          controller: numCtrl,
                          hint: '123',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCompactInput(
                    label: 'Logradouro / Rua',
                    controller: logrCtrl,
                    hint: 'Rua, Avenida...',
                  ),
                  const SizedBox(height: 10),
                  _buildCompactInput(
                    label: 'Bairro',
                    controller: bairroCtrl,
                    hint: 'Bairro',
                  ),
                  const SizedBox(height: 10),
                  _buildCompactInput(
                    label: 'Ponto de Referência',
                    controller: refCtrl,
                    hint: 'Ex: Próximo à padaria',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Salvar Alterações'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () async {
                          if (logrCtrl.text.trim().isEmpty) return;
                          final tenantCtx = widget.controller.tenantContext;
                          final now = DateTime.now().toUtc();
                          final atualizado = LocalEntrega(
                            id: local.id,
                            tenantId: local.tenantId,
                            clienteId: local.clienteId,
                            nomeIdentificador: idCtrl.text.trim().isNotEmpty ? idCtrl.text.trim() : local.nomeIdentificador,
                            logradouro: logrCtrl.text.trim(),
                            numero: numCtrl.text.trim(),
                            bairro: bairroCtrl.text.trim(),
                            cidade: local.cidade,
                            cep: cepCtrl.text.trim(),
                            referencia: refCtrl.text.trim(),
                            ativo: local.ativo,
                            metadata: SyncMetadata(
                              version: local.metadata.version + 1,
                              createdAt: local.metadata.createdAt,
                              updatedAt: now,
                              createdBy: local.metadata.createdBy,
                              updatedBy: tenantCtx.usuario.id,
                              syncStatus: SyncStatus.pending,
                            ),
                          );
                          await widget.controller.localRepo.save(atualizado);
                          await _carregarLocaisDoCliente(clienteId);
                          _preencherComLocal(atualizado);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
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

  Future<void> _abrirDialogNovoEndereco() async {
    final clienteId = widget.controller.cliente.id;
    if (clienteId == null) return;

    final idCtrl = TextEditingController(text: 'Trabalho');
    final cepCtrl = TextEditingController();
    final logrCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    final bairroCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    bool buscandoCepDialog = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: FincoreColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_location_alt_outlined, color: FincoreColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Novo Local de Entrega',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildCompactInput(
                    label: 'Identificador (ex: Casa, Trabalho, Mãe)',
                    controller: idCtrl,
                    hint: 'Ex: Trabalho',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildCompactInput(
                          label: 'CEP',
                          controller: cepCtrl,
                          hint: '00000-000',
                          keyboardType: TextInputType.number,
                          suffix: buscandoCepDialog
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  icon: Icon(Icons.search, size: 14, color: FincoreColors.primary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final clean = cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                                    if (clean.length == 8) {
                                      setDlgState(() => buscandoCepDialog = true);
                                      try {
                                        final end = await CepService.consultarCep(clean);
                                        if (end != null) {
                                          if (end.logradouro.isNotEmpty) logrCtrl.text = end.logradouro;
                                          if (end.bairro.isNotEmpty) bairroCtrl.text = end.bairro;
                                        }
                                      } finally {
                                        setDlgState(() => buscandoCepDialog = false);
                                      }
                                    }
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildCompactInput(
                          label: 'Número',
                          controller: numCtrl,
                          hint: '123',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCompactInput(
                    label: 'Logradouro / Rua',
                    controller: logrCtrl,
                    hint: 'Rua, Avenida...',
                  ),
                  const SizedBox(height: 10),
                  _buildCompactInput(
                    label: 'Bairro',
                    controller: bairroCtrl,
                    hint: 'Bairro',
                  ),
                  const SizedBox(height: 10),
                  _buildCompactInput(
                    label: 'Ponto de Referência',
                    controller: refCtrl,
                    hint: 'Ex: Próximo à padaria',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Salvar e Selecionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () async {
                          if (logrCtrl.text.trim().isEmpty) return;
                          final tenantCtx = widget.controller.tenantContext;
                          final now = DateTime.now().toUtc();
                          final novo = LocalEntrega(
                            id: const Uuid().v4(),
                            tenantId: tenantCtx.tenantId,
                            clienteId: clienteId,
                            nomeIdentificador: idCtrl.text.trim().isNotEmpty ? idCtrl.text.trim() : 'Outro',
                            logradouro: logrCtrl.text.trim(),
                            numero: numCtrl.text.trim(),
                            bairro: bairroCtrl.text.trim(),
                            cidade: tenantCtx.empresa.cidade?.isNotEmpty == true ? tenantCtx.empresa.cidade! : 'Pouso Alegre',
                            cep: cepCtrl.text.trim(),
                            referencia: refCtrl.text.trim(),
                            ativo: true,
                            metadata: SyncMetadata(
                              version: 1,
                              createdAt: now,
                              updatedAt: now,
                              createdBy: tenantCtx.usuario.id,
                              updatedBy: tenantCtx.usuario.id,
                              syncStatus: SyncStatus.pending,
                            ),
                          );
                          await widget.controller.localRepo.save(novo);
                          await _carregarLocaisDoCliente(clienteId);
                          _preencherComLocal(novo);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
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

  void _selecionarConsumidorFinal() {
    widget.controller.updateCliente(
      const DadosCliente(
        id: null,
        nome: 'Consumidor Final',
        telefone: '',
      ),
    );
    if (widget.controller.entrega.tipo != 'Entrega') {
      widget.controller.updateEntrega(
        widget.controller.entrega.copyWith(taxaEntregaCentavos: 0),
      );
    }
  }

  Future<void> _abrirBuscaCliente() async {
    await showDialog(
      context: context,
      builder: (ctx) => CustomerSelectionModal(controller: widget.controller),
    );
    if (mounted) setState(() {});
  }

  Future<void> _cadastrarNovoCliente() async {
    final novoCliente = await showDialog<Cliente>(
      context: context,
      builder: (ctx) => const ClienteFormDialog(),
    );
    if (novoCliente != null && mounted) {
      widget.controller.selectCustomer(
        novoCliente.nome,
        novoCliente.telefone,
        clienteId: novoCliente.id,
      );
      await widget.controller.loadCatalog();
      if (mounted) setState(() {});
    }
  }

  int _converterTextoParaCentavos(String rawText) {
    final clean = rawText.trim();
    if (clean.isEmpty) return 0;

    // Se tiver vírgula ou ponto decimal explícito (ex: "5,00", "5.50", "12,30")
    if (clean.contains(',') || clean.contains('.')) {
      final partes = clean.replaceAll(',', '.').split('.');
      if (partes.length == 2) {
        final inteiros = int.tryParse(partes[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        var decimaisStr = partes[1].replaceAll(RegExp(r'[^0-9]'), '');
        if (decimaisStr.length == 1) decimaisStr += '0';
        if (decimaisStr.length > 2) decimaisStr = decimaisStr.substring(0, 2);
        final decimais = int.tryParse(decimaisStr) ?? 0;
        return (inteiros * 100) + decimais;
      }
    }

    final apenasDigitos = clean.replaceAll(RegExp(r'[^0-9]'), '');
    if (apenasDigitos.isEmpty) return 0;
    final valorInt = int.tryParse(apenasDigitos) ?? 0;

    // Se digitou até 2 dígitos (ex: "5" ou "12"), considera valor em reais: 5 -> 500 centavos (R$ 5,00)
    if (apenasDigitos.length <= 2) {
      return valorInt * 100;
    }

    return valorInt;
  }

  void _alterarModalidade(String tipo) {
    int taxa = 0;
    if (tipo == 'Entrega') {
      taxa = _converterTextoParaCentavos(_taxaCtrl.text);
      if (taxa <= 0 && widget.controller.entrega.taxaEntregaCentavos > 0) {
        taxa = widget.controller.entrega.taxaEntregaCentavos;
      }
    }
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        tipo: tipo,
        taxaEntregaCentavos: taxa,
      ),
    );
    if (tipo == 'Entrega') {
      _recalcularTaxaEntrega();
    }
  }

  Future<void> _buscarCep() async {
    final clean = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 8) return;

    setState(() => _isBuscandoCep = true);
    try {
      final end = await CepService.consultarCep(clean);
      if (end != null && mounted) {
        if (end.logradouro.isNotEmpty) _logradouroCtrl.text = end.logradouro;
        if (end.bairro.isNotEmpty) _bairroCtrl.text = end.bairro;

        widget.controller.updateEntrega(
          widget.controller.entrega.copyWith(
            logradouro: _logradouroCtrl.text.trim(),
            bairro: _bairroCtrl.text.trim(),
            cidade: end.localidade,
            cep: clean,
          ),
        );

        await _recalcularTaxaEntrega();
      }
    } finally {
      if (mounted) setState(() => _isBuscandoCep = false);
    }
  }

  Future<void> _recalcularTaxaEntrega() async {
    setState(() => _isCalculandoFrete = true);
    try {
      final taxas = await widget.controller.taxaRepo.findAll();
      final empresa = widget.controller.tenantContext.empresa;
      final bairro = _bairroCtrl.text.trim();
      final cep = _cepCtrl.text.trim();
      final logradouro = _logradouroCtrl.text.trim();
      final numero = _numeroCtrl.text.trim();

      // Procura a taxa fixa / fallback salva
      final fallbackTaxa = taxas.where((t) => t.ativo && t.tipoRegra == TipoRegraTaxaEntrega.fixo).firstOrNull;
      final fallback = fallbackTaxa?.valorCentavos ?? 0;

      if (logradouro.isEmpty && cep.isEmpty && bairro.isEmpty) {
        if (mounted) {
          setState(() {
            _regraTaxaDescricao = null;
            _taxaCtrl.text = '0,00';
          });
        }
        return;
      }

      // 1. Estima a distância real em KM entre a loja e o endereço do cliente
      double? distanciaKm = await DeliveryFeeService.estimarDistanciaKm(
        empresa: empresa,
        clienteCep: cep.isNotEmpty ? cep : null,
        clienteLogradouro: logradouro.isNotEmpty ? logradouro : null,
        clienteNumero: numero.isNotEmpty ? numero : null,
        clienteBairro: bairro.isNotEmpty ? bairro : null,
        clienteCidade: widget.controller.entrega.cidade.isNotEmpty
            ? widget.controller.entrega.cidade
            : (empresa.cidade ?? 'Pouso Alegre'),
      );

      // 2. Se não calculou distância mas já havia no controller, usa o existente
      if (distanciaKm == null) {
        final m = widget.controller.entrega.distanciaMetros;
        if (m != null && m > 0) distanciaKm = m / 1000.0;
      }

      // 3. Aplica a regra da tabela de frete por KM com paridade ao Cardápio Web
      final subtotal = widget.controller.cart.fold(0, (sum, i) => sum + i.totalInCents);
      final res = DeliveryFeeService.calcular(
        taxas: taxas,
        distanciaKm: distanciaKm,
        bairro: bairro.isNotEmpty ? bairro : null,
        cep: cep.isNotEmpty ? cep : null,
        fallbackCentavos: fallback,
        subtotalCentavos: subtotal,
      );

      if (mounted) {
        setState(() {
          _regraTaxaDescricao = distanciaKm != null
              ? '${distanciaKm.toStringAsFixed(1)} km · ${res.descricaoRegra}'
              : res.descricaoRegra;
          _taxaCtrl.text = (res.taxaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
        });
        widget.controller.updateEntrega(
          widget.controller.entrega.copyWith(
            distanciaMetros: distanciaKm != null ? (distanciaKm * 1000).round() : null,
            taxaEntregaCentavos: res.taxaCentavos,
          ),
        );
      }
    } catch (e) {
      debugPrint('[AtendimentoDestinoPanel] Erro ao recalcular taxa: $e');
    } finally {
      if (mounted) setState(() => _isCalculandoFrete = false);
    }
  }

  void _agendarRecalculoTaxa() {
    _debounceRecalculo?.cancel();
    _debounceRecalculo = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _recalcularTaxaEntrega();
      }
    });
  }

  void _onLogradouroChanged(String val) {
    _atualizarEndereco();
    if (val.trim().length >= 3) {
      _agendarRecalculoTaxa();
    }
  }

  void _onNumeroChanged(String val) {
    _atualizarEndereco();
    _agendarRecalculoTaxa();
  }

  void _onBairroChanged(String bairro) {
    _atualizarEndereco();
    if (bairro.trim().length >= 2) {
      _agendarRecalculoTaxa();
    }
  }

  void _atualizarEndereco() {
    final taxaCentavos = _converterTextoParaCentavos(_taxaCtrl.text);
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        cep: _cepCtrl.text.trim(),
        logradouro: _logradouroCtrl.text.trim(),
        numero: _numeroCtrl.text.trim(),
        bairro: _bairroCtrl.text.trim(),
        referencia: _referenciaCtrl.text.trim(),
        taxaEntregaCentavos: taxaCentavos,
      ),
    );
  }

  void _atualizarTaxaServico() {
    final servicoCentavos = _converterTextoParaCentavos(_taxaServicoCtrl.text);
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        taxaServicoCentavos: servicoCentavos,
      ),
    );
  }

  void _aplicarTaxaServicoPorcentagem(double pct) {
    final subtotalCentavos = widget.controller.cart.fold(0, (sum, i) => sum + i.totalInCents);
    final valorCentavos = (subtotalCentavos * (pct / 100)).round();
    _taxaServicoCtrl.text = (valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(taxaServicoCentavos: valorCentavos),
    );
  }

  void _atualizarObservacoes() {
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        observacoes: _obsCtrl.text.trim(),
      ),
    );
  }

  void _alternarParaImediato() {
    setState(() {
      _isAgendado = false;
      _dataSelecionada = DateTime.now();
      _horaSelecionada = TimeOfDay.now();
    });
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(dataHora: DateTime.now()),
    );
  }

  void _alternarParaAgendado() {
    setState(() {
      _isAgendado = true;
      if (_dataSelecionada.difference(DateTime.now()).inMinutes.abs() < 15) {
        _dataSelecionada = DateTime.now().add(const Duration(hours: 2));
        _horaSelecionada = TimeOfDay.fromDateTime(_dataSelecionada);
      }
    });
    _salvarDataHoraAgendada();
  }

  void _salvarDataHoraAgendada() {
    final finalDate = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
      _horaSelecionada.hour,
      _horaSelecionada.minute,
    );
    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(dataHora: finalDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.controller.cliente;
    final entrega = widget.controller.entrega;
    final isConsumidorFinal = cliente.nome == 'Consumidor Final' && (cliente.telefone == null || cliente.telefone!.isEmpty);
    final hasClienteIdentificado = !cliente.isEmpty && !isConsumidorFinal;
    final tipoDestino = entrega.tipo;

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho da Seção ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FincoreColors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin_circle_outlined, color: FincoreColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'ATENDIMENTO & DESTINO',
                  style: TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '[F4]',
                  style: TextStyle(
                    color: FincoreColors.primary.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Conteúdo Rolável ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. IDENTIFICAÇÃO DO CLIENTE ──────────────────────
                  const Text(
                    'Cliente',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (hasClienteIdentificado)
                    // Card do Cliente Selecionado
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FincoreColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: FincoreColors.primary.withValues(alpha: 0.2),
                            child: Icon(Icons.person, color: FincoreColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cliente.nomeExibicao ?? cliente.nome ?? 'Cliente',
                                  style: const TextStyle(
                                    color: FincoreColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cliente.telefone != null && cliente.telefone!.isNotEmpty)
                                  Text(
                                    cliente.telefone!,
                                    style: const TextStyle(
                                      color: FincoreColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: FincoreColors.textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Remover Cliente',
                            onPressed: () {
                              widget.controller.clearCustomer();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    // Ações Rápidas de Cliente
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.flash_on,
                              size: 14,
                              color: isConsumidorFinal ? FincoreColors.primary : FincoreColors.textSecondary,
                            ),
                            label: Text(
                              'Consumidor Final',
                              style: TextStyle(
                                fontSize: 11,
                                color: isConsumidorFinal ? FincoreColors.primary : FincoreColors.textPrimary,
                                fontWeight: isConsumidorFinal ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              backgroundColor: isConsumidorFinal
                                  ? FincoreColors.primary.withValues(alpha: 0.12)
                                  : FincoreColors.background,
                              side: BorderSide(
                                color: isConsumidorFinal ? FincoreColors.primary : FincoreColors.border,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _selecionarConsumidorFinal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 4,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search, size: 14),
                            label: const Text('Buscar', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              backgroundColor: FincoreColors.surfaceElevated,
                              foregroundColor: FincoreColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: FincoreColors.border),
                              ),
                            ),
                            onPressed: _abrirBuscaCliente,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.person_add_alt_1, size: 18, color: FincoreColors.primary),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          tooltip: 'Cadastrar Novo Cliente',
                          onPressed: _cadastrarNovoCliente,
                        ),
                      ],
                    ),
                  if (!hasClienteIdentificado && !isConsumidorFinal) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.info_outline, size: 12, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          'Obrigatório selecionar para finalizar a venda',
                          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border, height: 1),
                  const SizedBox(height: 14),

                  // ── 2. MODALIDADE / DESTINO ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Destino',
                        style: TextStyle(
                          color: FincoreColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '[F6]',
                        style: TextStyle(
                          color: FincoreColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildModalidadeBtn('Balcão', Icons.storefront_outlined, tipoDestino == 'Balcão' || tipoDestino == 'Mesa/Balcão'),
                      const SizedBox(width: 6),
                      _buildModalidadeBtn('Retirada', Icons.takeout_dining_outlined, tipoDestino == 'Retirada'),
                      const SizedBox(width: 6),
                      _buildModalidadeBtn('Entrega', Icons.two_wheeler_outlined, tipoDestino == 'Entrega'),
                    ],
                  ),

                  // Se for Entrega (Delivery), campos compactos de Endereço & Frete
                  if (tipoDestino == 'Entrega') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Abas compactas apenas se o cliente tiver mais de 1 endereço cadastrado
                          if (hasClienteIdentificado && _locaisDoCliente.length > 1) ...[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ..._locaisDoCliente.map((loc) {
                                    final isSelected = !_isNovoEndereco && _localSelecionado?.id == loc.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(
                                          loc.nomeIdentificador,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : FincoreColors.textPrimary,
                                          ),
                                        ),
                                        avatar: Icon(
                                          isSelected ? Icons.check_circle : Icons.place_outlined,
                                          size: 12,
                                          color: isSelected ? Colors.white : FincoreColors.textSecondary,
                                        ),
                                        selected: isSelected,
                                        selectedColor: FincoreColors.primary,
                                        backgroundColor: FincoreColors.surface,
                                        side: BorderSide(color: isSelected ? FincoreColors.primary : FincoreColors.border),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                        onSelected: (_) => _preencherComLocal(loc),
                                      ),
                                    );
                                  }),
                                  ChoiceChip(
                                    label: Text(
                                      'Outro',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: _isNovoEndereco ? FontWeight.bold : FontWeight.normal,
                                        color: _isNovoEndereco ? Colors.white : FincoreColors.primary,
                                      ),
                                    ),
                                    avatar: Icon(
                                      _isNovoEndereco ? Icons.check_circle : Icons.add,
                                      size: 12,
                                      color: _isNovoEndereco ? Colors.white : FincoreColors.primary,
                                    ),
                                    selected: _isNovoEndereco,
                                    selectedColor: FincoreColors.primary,
                                    backgroundColor: FincoreColors.surface,
                                    side: BorderSide(color: _isNovoEndereco ? FincoreColors.primary : FincoreColors.border),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onSelected: (_) => _selecionarOutroEndereco(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // 2. CORPO: Endereço Selecionado (Cenário 1) OU Novo Endereço (Cenário 2)
                          if (!_isNovoEndereco && _localSelecionado != null) ...[
                            // Header do Endereço
                            Row(
                              children: [
                                Icon(Icons.place, size: 15, color: FincoreColors.primary),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _localSelecionado!.nomeIdentificador,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: FincoreColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Botão Alterar
                                InkWell(
                                  onTap: () => _abrirDialogEditarEndereco(_localSelecionado!),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: FincoreColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: FincoreColors.border),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 11, color: FincoreColors.textSecondary),
                                        SizedBox(width: 3),
                                        Text(
                                          'Alterar',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FincoreColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                // Botão Novo
                                InkWell(
                                  onTap: _abrirDialogNovoEndereco,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: FincoreColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 11, color: FincoreColors.primary),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Novo',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Detalhes do Endereço
                            Text(
                              '${_localSelecionado!.logradouro}, ${_localSelecionado!.numero}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_localSelecionado!.bairro.isNotEmpty ? _localSelecionado!.bairro : ""}${_localSelecionado!.bairro.isNotEmpty && _localSelecionado!.cidade.isNotEmpty ? " - " : ""}${_localSelecionado!.cidade}',
                              style: const TextStyle(fontSize: 10.5, color: FincoreColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_localSelecionado!.cep.isNotEmpty || _localSelecionado!.referencia.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (_localSelecionado!.cep.isNotEmpty) 'CEP: ${_localSelecionado!.cep}',
                                  if (_localSelecionado!.referencia.isNotEmpty) 'Ref: ${_localSelecionado!.referencia}',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ] else ...[
                            // Header do Modo Inserção Novo Endereço
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.add_location_alt_outlined, size: 14, color: FincoreColors.primary),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Novo Endereço de Entrega',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                    ),
                                  ],
                                ),
                                if (_locaisDoCliente.isNotEmpty)
                                  InkWell(
                                    onTap: () => _preencherComLocal(_locaisDoCliente.first),
                                    child: Text(
                                      '↩ Cancelar',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FincoreColors.primary),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (hasClienteIdentificado) ...[
                              _buildCompactInput(
                                label: 'Identificador (ex: Trabalho, Praia)',
                                controller: _novoEnderecoNomeCtrl,
                                hint: 'Ex: Trabalho',
                              ),
                              const SizedBox(height: 6),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildCompactInput(
                                    label: 'CEP',
                                    controller: _cepCtrl,
                                    hint: '00000-000',
                                    keyboardType: TextInputType.number,
                                    onChanged: (c) {
                                      _atualizarEndereco();
                                      if (c.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                                        _buscarCep();
                                      }
                                    },
                                    suffix: _isBuscandoCep
                                        ? const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.search, size: 14, color: FincoreColors.primary),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Buscar Endereço e Calcular Taxa',
                                            onPressed: _buscarCep,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: _buildCompactInput(
                                    label: 'Nº',
                                    controller: _numeroCtrl,
                                    hint: '123',
                                    onChanged: (n) => _onNumeroChanged(n),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildCompactInput(
                              label: 'Rua / Endereço',
                              controller: _logradouroCtrl,
                              hint: 'Rua, Av...',
                              onChanged: (r) => _onLogradouroChanged(r),
                            ),
                            const SizedBox(height: 6),
                            _buildCompactInput(
                              label: 'Bairro',
                              controller: _bairroCtrl,
                              hint: 'Bairro',
                              onChanged: (b) => _onBairroChanged(b),
                            ),
                            const SizedBox(height: 6),
                            _buildCompactInput(
                              label: 'Ponto de Referência',
                              controller: _referenciaCtrl,
                              hint: 'Próximo ao...',
                              onChanged: (_) => _atualizarEndereco(),
                            ),
                            if (hasClienteIdentificado) ...[
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.bookmark_add_outlined, size: 13),
                                  label: const Text('Salvar no cadastro do cliente', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FincoreColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  onPressed: _salvarEnderecoNoCadastroCliente,
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 8),
                          const Divider(color: FincoreColors.border, height: 1),
                          const SizedBox(height: 8),

                          // 3. FAIXA DE FRETE & TAXA DE ENTREGA (Sempre unificada e perfeitamente alinhada)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Frete & Distância',
                                      style: TextStyle(fontSize: 9.5, color: FincoreColors.textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    if (_isCalculandoFrete)
                                      Row(
                                        children: [
                                          const SizedBox(width: 9, height: 9, child: CircularProgressIndicator(strokeWidth: 1.5)),
                                          const SizedBox(width: 4),
                                          Text('Calculando...', style: TextStyle(fontSize: 10, color: FincoreColors.primary, fontWeight: FontWeight.w600)),
                                        ],
                                      )
                                    else
                                      Text(
                                        _regraTaxaDescricao != null ? '✓ $_regraTaxaDescricao' : 'Sem frete calculado',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: _regraTaxaDescricao != null ? FincoreColors.primary : FincoreColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 95,
                                child: _buildCompactInput(
                                  label: 'Taxa R\$',
                                  controller: _taxaCtrl,
                                  hint: '0,00',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _atualizarEndereco(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border, height: 1),
                  const SizedBox(height: 14),

                  // ── 3. TAXA DE SERVIÇO / CONVENIÊNCIA ────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Taxa de Serviço / Garçom',
                        style: TextStyle(
                          color: FincoreColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _aplicarTaxaServicoPorcentagem(10),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FincoreColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: FincoreColors.border),
                              ),
                              child: const Text(
                                '+10%',
                                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              _taxaServicoCtrl.text = '0,00';
                              widget.controller.updateEntrega(
                                widget.controller.entrega.copyWith(taxaServicoCentavos: 0),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FincoreColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: FincoreColors.border),
                              ),
                              child: const Text(
                                'Zerar',
                                style: TextStyle(color: FincoreColors.textMuted, fontSize: 9.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildCompactInput(
                    label: 'Valor da Taxa de Serviço (R\$)',
                    controller: _taxaServicoCtrl,
                    hint: '0,00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _atualizarTaxaServico(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border, height: 1),
                  const SizedBox(height: 14),

                  // ── 4. DATA & HORÁRIO DA OPERAÇÃO (AGENDAMENTO) ──────
                  const Text(
                    'Previsão de Entrega / Retirada',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _alternarParaImediato,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isAgendado
                                  ? FincoreColors.primary.withValues(alpha: 0.12)
                                  : FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !_isAgendado ? FincoreColors.primary : FincoreColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Hoje / Imediato',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: !_isAgendado ? FontWeight.bold : FontWeight.normal,
                                  color: !_isAgendado ? FincoreColors.primary : FincoreColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: _alternarParaAgendado,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isAgendado
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                                  : FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isAgendado ? const Color(0xFFF59E0B) : FincoreColors.border,
                                width: _isAgendado ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 14,
                                    color: _isAgendado ? const Color(0xFFF59E0B) : FincoreColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Agendado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _isAgendado ? FontWeight.bold : FontWeight.normal,
                                      color: _isAgendado ? const Color(0xFFF59E0B) : FincoreColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isAgendado) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Seletor de Data
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _dataSelecionada,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) {
                                setState(() {
                                  _dataSelecionada = d;
                                  _salvarDataHoraAgendada();
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: FincoreColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}',
                                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.edit_calendar, size: 14, color: Color(0xFFF59E0B)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Seletor de Hora
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _horaSelecionada,
                              );
                              if (t != null) {
                                setState(() {
                                  _horaSelecionada = t;
                                  _salvarDataHoraAgendada();
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: FincoreColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_horaSelecionada.hour.toString().padLeft(2, '0')}:${_horaSelecionada.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.access_time, size: 14, color: Color(0xFFF59E0B)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildQuickScheduleChip('+1h', () {
                          final nova = DateTime.now().add(const Duration(hours: 1));
                          setState(() {
                            _dataSelecionada = nova;
                            _horaSelecionada = TimeOfDay.fromDateTime(nova);
                            _salvarDataHoraAgendada();
                          });
                        }),
                        _buildQuickScheduleChip('+2h', () {
                          final nova = DateTime.now().add(const Duration(hours: 2));
                          setState(() {
                            _dataSelecionada = nova;
                            _horaSelecionada = TimeOfDay.fromDateTime(nova);
                            _salvarDataHoraAgendada();
                          });
                        }),
                        _buildQuickScheduleChip('+3h', () {
                          final nova = DateTime.now().add(const Duration(hours: 3));
                          setState(() {
                            _dataSelecionada = nova;
                            _horaSelecionada = TimeOfDay.fromDateTime(nova);
                            _salvarDataHoraAgendada();
                          });
                        }),
                        _buildQuickScheduleChip('Amanhã 11:30', () {
                          final am = DateTime.now().add(const Duration(days: 1));
                          setState(() {
                            _dataSelecionada = DateTime(am.year, am.month, am.day, 11, 30);
                            _horaSelecionada = const TimeOfDay(hour: 11, minute: 30);
                            _salvarDataHoraAgendada();
                          });
                        }),
                        _buildQuickScheduleChip('Amanhã 18:00', () {
                          final am = DateTime.now().add(const Duration(days: 1));
                          setState(() {
                            _dataSelecionada = DateTime(am.year, am.month, am.day, 18, 0);
                            _horaSelecionada = const TimeOfDay(hour: 18, minute: 0);
                            _salvarDataHoraAgendada();
                          });
                        }),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: FincoreColors.border, height: 1),
                  const SizedBox(height: 14),

                  // ── 5. OBSERVAÇÕES DO PEDIDO ─────────────────────────
                  const Text(
                    'Observações da Operação',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _obsCtrl,
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
                    maxLines: 2,
                    onChanged: (_) => _atualizarObservacoes(),
                    decoration: InputDecoration(
                      hintText: 'Ex: Entregar na portaria, troco em moedas...',
                      hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: FincoreColors.background,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FincoreColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FincoreColors.border),
                      ),
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

  Widget _buildModalidadeBtn(String label, IconData icon, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => _alterarModalidade(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? FincoreColors.primary.withValues(alpha: 0.15) : FincoreColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? FincoreColors.primary : FincoreColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? FincoreColors.primary : FincoreColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
              filled: true,
              fillColor: FincoreColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: FincoreColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: FincoreColors.border),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickScheduleChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF59E0B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
