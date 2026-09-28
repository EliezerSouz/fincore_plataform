import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import '../../controllers/pdv_express_controller.dart';

/// Modal rápido para seleção de Cliente, Canais de Atendimento (Mesa/Balcão vs Delivery)
/// e cálculo automático de Taxas de Entrega.
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
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _logradouroCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _taxaCtrl;
  late final TextEditingController _mesaCtrl;
  late final TextEditingController _garcomCtrl;
  late String _tipoAtendimento;

  @override
  void initState() {
    super.initState();
    final cliente = widget.controller.cliente;
    final entrega = widget.controller.entrega;

    _tipoAtendimento = entrega.tipo;
    _nameCtrl = TextEditingController(text: cliente.nome);
    _phoneCtrl = TextEditingController(text: cliente.telefone);
    _logradouroCtrl = TextEditingController(text: entrega.logradouro);
    _numeroCtrl = TextEditingController(text: entrega.numero);
    _bairroCtrl = TextEditingController(text: entrega.bairro);
    _referenciaCtrl = TextEditingController(text: entrega.referencia);
    _cepCtrl = TextEditingController(text: entrega.cep);
    _taxaCtrl = TextEditingController(
      text: entrega.taxaEntregaCentavos > 0
          ? (entrega.taxaEntregaCentavos / 100).toStringAsFixed(2)
          : '',
    );
    _mesaCtrl = TextEditingController(text: entrega.mesa);
    _garcomCtrl = TextEditingController(text: entrega.garcom);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  void _onCustomerSelected(Cliente c) async {
    _nameCtrl.text = c.nomeExibicao;
    _phoneCtrl.text = c.telefoneFormatado.isNotEmpty ? c.telefoneFormatado : c.telefone;

    widget.controller.updateCliente(
      widget.controller.cliente.copyWith(
        id: c.id,
        nome: c.nome,
        apelido: c.apelido,
        telefone: c.telefone,
      ),
    );

    final locals = await widget.controller.localRepo.findByClienteId(c.id);
    if (locals.isNotEmpty && mounted) {
      final address = locals.first;
      final taxaCadastrada = await widget.controller.taxaRepo.findByBairro(address.bairro);
      final valorCentavos = taxaCadastrada?.valorCentavos ?? 0;

      setState(() {
        _logradouroCtrl.text = address.logradouro;
        _numeroCtrl.text = address.numero;
        _bairroCtrl.text = address.bairro;
        _referenciaCtrl.text = address.referencia;
        _cepCtrl.text = address.cep;
        _taxaCtrl.text = valorCentavos > 0 ? (valorCentavos / 100).toStringAsFixed(2) : '';
      });

      widget.controller.updateEntrega(
        widget.controller.entrega.copyWith(
          logradouro: address.logradouro,
          numero: address.numero,
          bairro: address.bairro,
          referencia: address.referencia,
          cep: address.cep,
          taxaEntregaCentavos: valorCentavos,
        ),
      );
    }
  }

  void _onBairroChanged() async {
    final cleanTaxa = _taxaCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    var taxaReais = double.tryParse(cleanTaxa) ?? 0.0;

    if (taxaReais == 0.0 && _bairroCtrl.text.trim().isNotEmpty) {
      final taxaCadastrada = await widget.controller.taxaRepo.findByBairro(_bairroCtrl.text);
      if (taxaCadastrada != null && taxaCadastrada.valorCentavos > 0) {
        taxaReais = taxaCadastrada.valorCentavos / 100.0;
        setState(() {
          _taxaCtrl.text = taxaReais.toStringAsFixed(2);
        });
      }
    }

    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        logradouro: _logradouroCtrl.text,
        numero: _numeroCtrl.text,
        bairro: _bairroCtrl.text,
        referencia: _referenciaCtrl.text,
        cep: _cepCtrl.text,
        taxaEntregaCentavos: (taxaReais * 100).round(),
      ),
    );
  }

  void _saveAndClose() {
    final cleanTaxa = _taxaCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    final taxaReais = double.tryParse(cleanTaxa) ?? 0.0;

    widget.controller.updateCliente(
      widget.controller.cliente.copyWith(
        nome: _nameCtrl.text,
        telefone: _phoneCtrl.text,
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
        taxaEntregaCentavos: _tipoAtendimento == 'Entrega' ? (taxaReais * 100).round() : 0,
        mesa: _mesaCtrl.text,
        garcom: _garcomCtrl.text,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person_pin, color: FincoreColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Identificação & Canal de Atendimento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2E2E38), height: 28),

              // Escolha de Canal (Mesa / Balcão vs Delivery)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _tipoAtendimento = 'Retirada';
                          _taxaCtrl.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _tipoAtendimento == 'Retirada'
                              ? FincoreColors.primary.withValues(alpha: 0.15)
                              : const Color(0xFF181820),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _tipoAtendimento == 'Retirada'
                                ? FincoreColors.primary
                                : const Color(0xFF2E2E38),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront,
                              color: _tipoAtendimento == 'Retirada'
                                  ? FincoreColors.primary
                                  : FincoreColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '🟢 Mesa / Balcão',
                              style: TextStyle(
                                color: _tipoAtendimento == 'Retirada'
                                    ? Colors.white
                                    : FincoreColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.controller.modoDeliveryAtivo) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _tipoAtendimento = 'Entrega';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _tipoAtendimento == 'Entrega'
                                ? FincoreColors.primary.withValues(alpha: 0.15)
                                : const Color(0xFF181820),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _tipoAtendimento == 'Entrega'
                                  ? FincoreColors.primary
                                  : const Color(0xFF2E2E38),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: _tipoAtendimento == 'Entrega'
                                    ? FincoreColors.primary
                                    : FincoreColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🛵 Delivery',
                                style: TextStyle(
                                  color: _tipoAtendimento == 'Entrega'
                                      ? Colors.white
                                      : FincoreColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Formulário de Mesa / Garçom (Se for atendimento em Mesa/Balcão e comandas ativas)
              if (_tipoAtendimento == 'Mesa' && widget.controller.modoComandasAtivo) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mesaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Mesa / Comanda Nº',
                          hintText: 'Ex: 05 ou Comanda 12',
                          prefixIcon: Icon(Icons.table_restaurant_outlined, color: FincoreColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _garcomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Atendente / Garçom',
                          hintText: 'Ex: João',
                          prefixIcon: Icon(Icons.badge_outlined, color: FincoreColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Autocomplete de Cliente
              Autocomplete<Cliente>(
                initialValue: TextEditingValue(text: _nameCtrl.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final sorted = List<Cliente>.from(widget.controller.clientes)
                    ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
                  if (textEditingValue.text.isEmpty) {
                    return sorted.take(15);
                  }
                  final query = textEditingValue.text.toLowerCase();
                  final qNorm = normalizarTelefone(textEditingValue.text);
                  return sorted.where((c) {
                    final matchNorm = qNorm.length >= 3 && c.telefoneNormalizado.contains(qNorm);
                    return c.nome.toLowerCase().contains(query) ||
                           (c.apelido?.toLowerCase().contains(query) ?? false) ||
                           c.telefone.contains(query) ||
                           matchNorm;
                  }).take(15);
                },
                displayStringForOption: (Cliente c) => c.nomeExibicao,
                onSelected: _onCustomerSelected,
                fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                  textController.text = _nameCtrl.text;
                  textController.addListener(() {
                    if (_nameCtrl.text != textController.text) {
                      _nameCtrl.text = textController.text;
                    }
                  });
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Cliente (Opcional)',
                      hintText: 'Digite para buscar cliente cadastrado...',
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: 'Ex: (11) 99999-9999',
                  prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF)),
                ),
              ),

              // Campos de Endereço & Taxa se for Delivery
              if (_tipoAtendimento == 'Entrega') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _logradouroCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Rua / Logradouro',
                          hintText: 'Endereço de entrega...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _numeroCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Número',
                          hintText: 'Ex: 123',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bairroCtrl,
                        onChanged: (_) => _onBairroChanged(),
                        decoration: const InputDecoration(
                          labelText: 'Bairro',
                          hintText: 'Ex: Centro',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _taxaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _onBairroChanged(),
                        decoration: const InputDecoration(
                          labelText: 'Taxa Entrega (R\$)',
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9CA3AF))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirmar & Aplicar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
