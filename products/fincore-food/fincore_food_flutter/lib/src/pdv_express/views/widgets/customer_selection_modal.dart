import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_food_flutter/src/clientes/views/widgets/cliente_form_dialog.dart';
import 'package:fincore_food_flutter/src/shared/services/delivery_fee_service.dart';
import '../../controllers/pdv_express_controller.dart';

/// Modal ergonômico de alta performance para Busca e Seleção de Clientes no PDV.
/// Focado 100% em operação por teclado (Autofocus imediato, setas ↑/↓ para navegar, ENTER para selecionar e fechar).
class CustomerSelectionModal extends StatefulWidget {
  final PdvExpressController controller;

  const CustomerSelectionModal({
    super.key,
    required this.controller,
  });

  @override
  State<CustomerSelectionModal> createState() => _CustomerSelectionModalState();
}

class _CustomerSelectionModalState extends State<CustomerSelectionModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _logradouroCtrl = TextEditingController();
  final TextEditingController _numeroCtrl = TextEditingController();
  final TextEditingController _bairroCtrl = TextEditingController();
  final TextEditingController _referenciaCtrl = TextEditingController();
  final TextEditingController _cepCtrl = TextEditingController();
  final TextEditingController _taxaCtrl = TextEditingController();
  final TextEditingController _mesaCtrl = TextEditingController();
  final TextEditingController _garcomCtrl = TextEditingController();

  late String _tipoAtendimento;
  List<Cliente> _filteredClientes = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final cliente = widget.controller.cliente;
    final entrega = widget.controller.entrega;

    _tipoAtendimento = entrega.tipo;
    _searchCtrl.text = cliente.nome ?? '';
    _phoneCtrl.text = cliente.telefone ?? '';
    _logradouroCtrl.text = entrega.logradouro;
    _numeroCtrl.text = entrega.numero;
    _bairroCtrl.text = entrega.bairro;
    _referenciaCtrl.text = entrega.referencia;
    _cepCtrl.text = entrega.cep;
    _taxaCtrl.text = entrega.taxaEntregaCentavos > 0
        ? (entrega.taxaEntregaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '';
    _mesaCtrl.text = entrega.mesa;
    _garcomCtrl.text = entrega.garcom;

    _filtrarClientes(_searchCtrl.text);

    // Foco automático imediato no campo de busca ao abrir o modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        _searchCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchCtrl.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _phoneCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _referenciaCtrl.dispose();
    _cepCtrl.dispose();
    _taxaCtrl.dispose();
    _mesaCtrl.dispose();
    _garcomCtrl.dispose();
    super.dispose();
  }

  void _filtrarClientes(String query) {
    final todos = List<Cliente>.from(widget.controller.clientes)
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredClientes = todos.take(20).toList();
        _selectedIndex = 0;
      });
      return;
    }

    final qNorm = normalizarTelefone(query);
    setState(() {
      _filteredClientes = todos.where((c) {
        final matchNome = c.nome.toLowerCase().contains(q);
        final matchApelido = c.apelido?.toLowerCase().contains(q) ?? false;
        final matchTel = c.telefone.contains(q);
        final matchNorm = qNorm.length >= 3 && c.telefoneNormalizado.contains(qNorm);
        return matchNome || matchApelido || matchTel || matchNorm;
      }).take(20).toList();

      _selectedIndex = 0;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredClientes.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _filteredClientes.length - 1);
        });
        _scrollToSelected();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredClientes.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, _filteredClientes.length - 1);
        });
        _scrollToSelected();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_filteredClientes.isNotEmpty && _selectedIndex >= 0 && _selectedIndex < _filteredClientes.length) {
        _selecionarClienteEFechar(_filteredClientes[_selectedIndex]);
      } else {
        _salvarClienteDigitadoEFechar();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.f1) {
      _definirConsumidorFinalEFechar();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.f2) {
      _cadastrarNovoCliente();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.f6) {
      _alternarCanal();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients) {
      final offset = (_selectedIndex * 58.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _selecionarClienteEFechar(Cliente c) async {
    _searchCtrl.text = c.nomeExibicao;
    _phoneCtrl.text = c.telefoneFormatado.isNotEmpty ? c.telefoneFormatado : c.telefone;

    widget.controller.updateCliente(
      DadosCliente(
        id: c.id,
        nome: c.nome,
        apelido: c.apelido,
        telefone: c.telefone,
      ),
    );

    // Carregar endereços e taxas de entrega automaticamente com regras unificadas
    final locals = await widget.controller.localRepo.findByClienteId(c.id);
    if (locals.isNotEmpty) {
      final address = locals.first;
      int valorCentavos = 0;
      int? distMetros;
      if (_tipoAtendimento == 'Entrega') {
        try {
          final taxas = await widget.controller.taxaRepo.findAll();
          final empresa = widget.controller.tenantContext.empresa;
          final distKm = await DeliveryFeeService.estimarDistanciaKm(
            empresa: empresa,
            clienteCep: address.cep,
            clienteLogradouro: address.logradouro,
            clienteNumero: address.numero,
            clienteBairro: address.bairro,
          );
          if (distKm != null) {
            distMetros = (distKm * 1000).round();
          }
          final res = DeliveryFeeService.calcular(
            taxas: taxas,
            distanciaKm: distKm,
            bairro: address.bairro,
            cep: address.cep,
          );
          valorCentavos = res.taxaCentavos;
        } catch (_) {}
      }

      widget.controller.updateEntrega(
        widget.controller.entrega.copyWith(
          logradouro: address.logradouro,
          numero: address.numero,
          bairro: address.bairro,
          referencia: address.referencia,
          cep: address.cep,
          distanciaMetros: distMetros,
          taxaEntregaCentavos: _tipoAtendimento == 'Entrega' ? valorCentavos : 0,
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _salvarClienteDigitadoEFechar() {
    final nome = _searchCtrl.text.trim();
    if (nome.isEmpty || nome.toLowerCase() == 'consumidor final') {
      _definirConsumidorFinalEFechar();
      return;
    }

    final taxaCentavos = _converterTextoParaCentavos(_taxaCtrl.text);

    widget.controller.updateCliente(
      DadosCliente(
        id: null,
        nome: nome,
        telefone: _phoneCtrl.text.trim(),
      ),
    );

    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        tipo: _tipoAtendimento,
        logradouro: _logradouroCtrl.text,
        numero: _numeroCtrl.text,
        bairro: _bairroCtrl.text,
        referencia: _referenciaCtrl.text,
        cep: _cepCtrl.text,
        taxaEntregaCentavos: _tipoAtendimento == 'Entrega' ? taxaCentavos : 0,
        mesa: _mesaCtrl.text,
        garcom: _garcomCtrl.text,
      ),
    );

    Navigator.of(context).pop(true);
  }

  void _definirConsumidorFinalEFechar() {
    widget.controller.updateCliente(
      const DadosCliente(
        id: null,
        nome: 'Consumidor Final',
        telefone: '',
      ),
    );

    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        tipo: _tipoAtendimento,
        taxaEntregaCentavos: _tipoAtendimento == 'Entrega' ? widget.controller.entrega.taxaEntregaCentavos : 0,
      ),
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _cadastrarNovoCliente() async {
    final novo = await ClienteFormDialog.show(context);
    if (novo != null) {
      await widget.controller.loadCatalog();
      _selecionarClienteEFechar(novo);
    }
  }

  void _alternarCanal() {
    setState(() {
      _tipoAtendimento = (_tipoAtendimento == 'Entrega') ? 'Retirada' : 'Entrega';
    });
  }

  int _converterTextoParaCentavos(String rawText) {
    final clean = rawText.trim();
    if (clean.isEmpty) return 0;

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
    if (apenasDigitos.length <= 2) {
      return valorInt * 100;
    }
    return valorInt;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabeçalho do Modal ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.person_search_rounded, color: FincoreColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buscar & Selecionar Cliente [F4]',
                            style: TextStyle(
                              color: FincoreColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Navegue com [↑ / ↓] e tecle [ENTER] para selecionar',
                            style: TextStyle(
                              color: FincoreColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Botão Consumidor Final Rápido
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_outline, size: 15),
                        label: const Text('Consumidor Final [F1]', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FincoreColors.textSecondary,
                          side: const BorderSide(color: FincoreColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _definirConsumidorFinalEFechar,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                        tooltip: 'Fechar [ESC]',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: FincoreColors.border, height: 22),

              // ── Barra de Busca com Foco Imediato ───────────────────────────
              TextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Nome, Telefone ou Apelido do Cliente',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                  hintText: 'Digite para buscar ou tecle ENTER para selecionar...',
                  hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: FincoreColors.primary),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: FincoreColors.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filtrarClientes('');
                          },
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                        label: const Text('Novo [F2]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        style: TextButton.styleFrom(foregroundColor: FincoreColors.primary),
                        onPressed: _cadastrarNovoCliente,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  filled: true,
                  fillColor: FincoreColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: FincoreColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: FincoreColors.primary, width: 2)),
                ),
                onChanged: _filtrarClientes,
              ),
              const SizedBox(height: 10),

              // ── Lista de Sugestões com Navegação Teclado ───────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: _filteredClientes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, size: 36, color: FincoreColors.textMuted),
                              const SizedBox(height: 8),
                              Text(
                                _searchCtrl.text.trim().isEmpty
                                    ? 'Nenhum cliente cadastrado no momento.'
                                    : 'Nenhum cliente encontrado para "${_searchCtrl.text}".',
                                style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12.5),
                              ),
                              const SizedBox(height: 8),
                              if (_searchCtrl.text.trim().isNotEmpty)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 16),
                                  label: Text('Usar "${_searchCtrl.text}" como Cliente Avulso [ENTER]'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FincoreColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _salvarClienteDigitadoEFechar,
                                ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: _filteredClientes.length,
                          separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                          itemBuilder: (context, index) {
                            final c = _filteredClientes[index];
                            final isSelected = index == _selectedIndex;

                            return InkWell(
                              onTap: () => _selecionarClienteEFechar(c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? FincoreColors.primary.withValues(alpha: 0.18)
                                      : Colors.transparent,
                                  border: isSelected
                                      ? Border(left: BorderSide(color: FincoreColors.primary, width: 4))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected
                                          ? FincoreColors.primary
                                          : FincoreColors.surface,
                                      child: Text(
                                        c.nome.isNotEmpty ? c.nome[0].toUpperCase() : 'C',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : FincoreColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  c.nome,
                                                  style: TextStyle(
                                                    color: isSelected ? FincoreColors.primary : FincoreColors.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (c.apelido != null && c.apelido!.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: FincoreColors.surface,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: FincoreColors.border),
                                                  ),
                                                  child: Text(
                                                    c.apelido!,
                                                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.telefoneFormatado.isNotEmpty ? c.telefoneFormatado : (c.telefone.isNotEmpty ? c.telefone : 'Sem telefone cadastrado'),
                                            style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'ENTER ⏎',
                                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
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
              ),
              const SizedBox(height: 12),

              // ── Rodapé Informativo e Alternância Balcão/Delivery ───────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Canal: ', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                        InkWell(
                          onTap: _alternarCanal,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FincoreColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _tipoAtendimento == 'Entrega' ? Icons.local_shipping_outlined : Icons.storefront_outlined,
                                  color: FincoreColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_tipoAtendimento [F6]',
                                  style: TextStyle(color: FincoreColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar [ESC]', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11.5)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_filteredClientes.isNotEmpty && _selectedIndex >= 0 && _selectedIndex < _filteredClientes.length) {
                              _selecionarClienteEFechar(_filteredClientes[_selectedIndex]);
                            } else {
                              _salvarClienteDigitadoEFechar();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FincoreColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Selecionar [ENTER]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
