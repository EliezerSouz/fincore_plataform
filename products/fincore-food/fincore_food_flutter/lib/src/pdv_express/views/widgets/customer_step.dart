import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';

class CustomerStep extends StatefulWidget {
  final PdvExpressController controller;

  const CustomerStep({
    super.key,
    required this.controller,
  });

  @override
  State<CustomerStep> createState() => _CustomerStepState();
}

class _CustomerStepState extends State<CustomerStep> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _logradouroCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _taxaCtrl;

  @override
  void initState() {
    super.initState();
    final cliente = widget.controller.cliente;
    final entrega = widget.controller.entrega;

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

    // Listeners para atualizar o controller reativamente
    _nameCtrl.addListener(_updateCliente);
    _phoneCtrl.addListener(_updateCliente);
    _logradouroCtrl.addListener(_updateEntrega);
    _numeroCtrl.addListener(_updateEntrega);
    _bairroCtrl.addListener(_updateEntrega);
    _referenciaCtrl.addListener(_updateEntrega);
    _cepCtrl.addListener(_updateEntrega);
    _taxaCtrl.addListener(_updateEntrega);
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
    super.dispose();
  }

  void _updateCliente() {
    // Se o usuário digitou manualmente e mudou o nome, perdemos a referência do ID (caso fosse um cliente selecionado antes)
    final atual = widget.controller.cliente;
    final isNomeDiferente = atual.nome != _nameCtrl.text && _nameCtrl.text.isNotEmpty;
    
    widget.controller.updateCliente(
      atual.copyWith(
        id: isNomeDiferente ? null : atual.id, // Limpa o ID se editou na mão o nome
        nome: _nameCtrl.text,
        telefone: _phoneCtrl.text,
      ),
    );
  }

  void _updateEntrega() {
    // Remove tudo que não for dígito ou vírgula (como pontos de milhar, cifrão, etc)
    final cleanTaxa = _taxaCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    final taxaReais = double.tryParse(cleanTaxa) ?? 0.0;
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

  @override
  Widget build(BuildContext context) {
    final entrega = widget.controller.entrega;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Identificação do Cliente
          _buildSectionCard(
            title: 'Identificação do Cliente',
            icon: Icons.person_outline,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Autocomplete<Cliente>(
                    initialValue: TextEditingValue(text: _nameCtrl.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Cliente>.empty();
                      }
                      return widget.controller.clientes.where((c) {
                        return c.nome.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                               c.telefone.contains(textEditingValue.text);
                      });
                    },
                    displayStringForOption: (Cliente c) => c.nome,
                    onSelected: (Cliente c) async {
                      // Desativar temporariamente o listener para não apagar o ID acidentalmente
                      _nameCtrl.removeListener(_updateCliente);
                      _nameCtrl.text = c.nome;
                      _phoneCtrl.text = c.telefone;
                      _nameCtrl.addListener(_updateCliente);

                      widget.controller.updateCliente(
                        widget.controller.cliente.copyWith(
                          id: c.id,
                          nome: c.nome,
                          telefone: c.telefone,
                        ),
                      );
                      
                      // Carregar endereço do cliente se for entrega
                      final locals = await widget.controller.localRepo.findByClienteId(c.id);
                      if (locals.isNotEmpty && mounted) {
                        final address = locals.first;
                        setState(() {
                          _logradouroCtrl.text = address.logradouro;
                          _numeroCtrl.text = address.numero;
                          _bairroCtrl.text = address.bairro;
                          _referenciaCtrl.text = address.referencia ?? '';
                          _cepCtrl.text = address.cep;
                        });
                      }
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      // Sincronizar o controller do Autocomplete com o nosso _nameCtrl
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
                          labelText: 'Nome do Cliente',
                          hintText: 'Digite para buscar ou criar...',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: FincoreFormatters.telefone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: 'Ex: (11) 99999-9999',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card de Entrega / Retirada
          _buildSectionCard(
            title: 'Logística de Entrega',
            icon: Icons.local_shipping_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceButton(
                        label: 'Entrega a Domicílio',
                        icon: Icons.home_outlined,
                        isSelected: entrega.tipo == 'Entrega',
                        onTap: () {
                          widget.controller.updateEntrega(
                            widget.controller.entrega.copyWith(tipo: 'Entrega'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildChoiceButton(
                        label: 'Retirada no Balcão',
                        icon: Icons.storefront,
                        isSelected: entrega.tipo == 'Retirada',
                        onTap: () {
                          widget.controller.updateEntrega(
                            widget.controller.entrega.copyWith(
                              tipo: 'Retirada',
                              taxaEntregaCentavos: 0,
                            ),
                          );
                          _taxaCtrl.clear();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Formulário de Endereço (Apenas se for entrega)
                if (entrega.tipo == 'Entrega') ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _logradouroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Rua / Logradouro',
                            hintText: 'Digite o endereço...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bairroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                            hintText: 'Digite o bairro...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _referenciaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Referência',
                            hintText: 'Ex: Próximo à praça',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cepCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: FincoreFormatters.cep,
                          decoration: const InputDecoration(
                            labelText: 'CEP',
                            hintText: 'Ex: 18000-000',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _taxaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: FincoreFormatters.real,
                          decoration: const InputDecoration(
                            labelText: 'Taxa de Entrega (R\$)',
                            hintText: 'Ex: 7,50',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Agendamento & Prioridade
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: entrega.prioridade,
                        decoration: const InputDecoration(
                          labelText: 'Prioridade',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Normal', child: Text('🟢 Normal')),
                          DropdownMenuItem(value: 'Entrega Programada', child: Text('🟡 Programada')),
                          DropdownMenuItem(value: 'Urgente', child: Text('🔴 Urgente')),
                          DropdownMenuItem(value: 'VIP', child: Text('⭐ VIP')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            widget.controller.updateEntrega(
                              widget.controller.entrega.copyWith(prioridade: v),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimePicker(context),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: FincoreColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: FincoreColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Divider(color: FincoreColors.border, height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary.withValues(alpha: 0.1) : FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? FincoreColors.primary : FincoreColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    final dataHora = widget.controller.entrega.dataHora;
    final dateStr = '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}';
    final timeStr = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dataHora,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null && context.mounted) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(dataHora),
          );
          if (pickedTime != null) {
            widget.controller.updateEntrega(
              widget.controller.entrega.copyWith(
                dataHora: DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                ),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FincoreColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: FincoreColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$dateStr - $timeStr',
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
