import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_food_flutter/src/clientes/views/widgets/cliente_form_dialog.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_food_client/fincore_food_client.dart' as client;
import '../../controllers/pdv_express_controller.dart';

/// Tela de Identificação do Cliente e Agendamento & Entrega do PDV
/// Fiel às capturas do usuário com Combobox de Clientes, botão +👤 de cadastro rápido,
/// agendamento de data/hora, prioridade, taxa por bairro e opção de salvar endereço.
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController();
  final _mesaCtrl = TextEditingController();
  final _garcomCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  final _rotuloEnderecoCtrl = TextEditingController(text: 'Casa');

  bool _salvarEnderecoFuturo = false;
  Cliente? _selectedCliente;

  List<LocalEntrega> _clienteEnderecos = [];
  LocalEntrega? _selectedLocalEntrega;
  bool _isNovoEndereco = true;
  bool _isSearchingViaCep = false;

  int? _tempoDeslocamentoMinutos;
  int? _distanciaMetros;
  bool _isCalculatingRoute = false;
  Timer? _routeDebounce;

  bool _mostrarAjusteTaxa = false;

  @override
  void initState() {
    super.initState();
    final cliente = widget.controller.cliente;
    final entrega = widget.controller.entrega;

    _mostrarAjusteTaxa = false;

    _nameCtrl.text = cliente.nome ?? '';
    _phoneCtrl.text = cliente.telefone ?? '';
    _logradouroCtrl.text = entrega.logradouro;
    _numeroCtrl.text = entrega.numero;
    _bairroCtrl.text = entrega.bairro;
    _referenciaCtrl.text = entrega.referencia;
    _cidadeCtrl.text = entrega.cidade.isNotEmpty ? entrega.cidade : 'São Paulo';
    _cepCtrl.text = entrega.cep;
    _taxaCtrl.text = entrega.taxaEntregaCentavos > 0
        ? (entrega.taxaEntregaCentavos / 100).toStringAsFixed(2)
        : '0,00';
    _mesaCtrl.text = entrega.mesa;
    _garcomCtrl.text = entrega.garcom;

    final now = entrega.dataHora;
    _dataCtrl.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _horaCtrl.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Tentar parear o cliente selecionado com a lista existente
    if (cliente.id != null) {
      try {
        _selectedCliente = widget.controller.clientes.firstWhere((c) => c.id == cliente.id);
      } catch (_) {}
    }

    _nameCtrl.addListener(_onClienteFieldsChanged);
    _phoneCtrl.addListener(_onClienteFieldsChanged);
    _logradouroCtrl.addListener(_onEntregaFieldsChanged);
    _numeroCtrl.addListener(_onEntregaFieldsChanged);
    _bairroCtrl.addListener(_onEntregaFieldsChanged);
    _referenciaCtrl.addListener(_onEntregaFieldsChanged);
    _cidadeCtrl.addListener(_onEntregaFieldsChanged);
    _cepCtrl.addListener(_onEntregaFieldsChanged);
    _taxaCtrl.addListener(_onEntregaFieldsChanged);
    _rotuloEnderecoCtrl.addListener(_onEntregaFieldsChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _referenciaCtrl.dispose();
    _cidadeCtrl.dispose();
    _cepCtrl.dispose();
    _taxaCtrl.dispose();
    _mesaCtrl.dispose();
    _garcomCtrl.dispose();
    _dataCtrl.dispose();
    _horaCtrl.dispose();
    _rotuloEnderecoCtrl.dispose();
    _routeDebounce?.cancel();
    super.dispose();
  }

  void _onClienteFieldsChanged() {
    widget.controller.updateCliente(
      widget.controller.cliente.copyWith(
        nome: _nameCtrl.text,
        telefone: _phoneCtrl.text,
      ),
    );
  }

  void _onEntregaFieldsChanged() async {
    final cleanTaxa = _taxaCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    var taxaReais = double.tryParse(cleanTaxa) ?? 0.0;

    if (taxaReais == 0.0 && _bairroCtrl.text.trim().isNotEmpty) {
      final taxaCadastrada = await widget.controller.taxaRepo.findByBairro(_bairroCtrl.text);
      if (taxaCadastrada != null && taxaCadastrada.valorCentavos > 0) {
        taxaReais = taxaCadastrada.valorCentavos / 100.0;
        _taxaCtrl.removeListener(_onEntregaFieldsChanged);
        _taxaCtrl.text = taxaReais.toStringAsFixed(2).replaceAll('.', ',');
        _taxaCtrl.addListener(_onEntregaFieldsChanged);
      }
    }

    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        logradouro: _logradouroCtrl.text,
        numero: _numeroCtrl.text,
        bairro: _bairroCtrl.text,
        referencia: _referenciaCtrl.text,
        cidade: _cidadeCtrl.text,
        cep: _cepCtrl.text,
        taxaEntregaCentavos: (taxaReais * 100).round(),
      ),
    );

    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(milliseconds: 800), () {
      _calcularRotaPreview();
    });
  }

  Future<void> _calcularRotaPreview() async {
    var cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length == 7) {
      cep = '${cep}0';
    }
    final numero = _numeroCtrl.text.trim();
    debugPrint('[_calcularRotaPreview] CEP: "$cep" (tamanho: ${cep.length}), Número: "$numero"');
    if (cep.length != 8) {
      debugPrint('[_calcularRotaPreview] Ignorado: CEP diferente de 8 caracteres');
      if (mounted) {
        setState(() {
          _tempoDeslocamentoMinutos = null;
          _distanciaMetros = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCalculatingRoute = true;
        _distanciaMetros = null;
        _tempoDeslocamentoMinutos = null;
      });
    }

    try {
      final empresa = widget.controller.tenantContext.empresa;
      final origin = [
        empresa.logradouro,
        empresa.numero,
        empresa.bairro,
        empresa.cidade,
        empresa.estado,
        empresa.cep
      ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

      final destination = [
        _logradouroCtrl.text,
        if (numero.isNotEmpty) numero,
        _bairroCtrl.text,
        _cidadeCtrl.text,
        cep
      ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

      debugPrint('[_calcularRotaPreview] Requisitando rota no servidor. Origem: "$origin" | Destino: "$destination"');
      if (origin.isNotEmpty && destination.isNotEmpty) {
        final serverpodClient = DependencyInjection().get<client.Client>();
        final routeResult = await serverpodClient.mapRoute.calculateRoute(origin, destination);
        debugPrint('[_calcularRotaPreview] Retorno do servidor: status=${routeResult.status}, distancia=${routeResult.distanciaMetros}m, tempo=${routeResult.tempoDeslocamentoSegundos}s');
        if (routeResult.status != 'error' && mounted) {
          final config = widget.controller.empresaConfig;
          int? calculatedTaxaCentavos;
          if (config != null && config.taxaEntregaPorKm) {
            final distanciaKm = routeResult.distanciaMetros / 1000.0;
            final valorPorKm = config.valorPorKmCentavos / 100.0;
            final taxaBruta = distanciaKm * valorPorKm;
            // Arredondamento para múltiplos de R$ 0,50
            final taxaArredondada = (taxaBruta * 2).round() / 2;
            calculatedTaxaCentavos = (taxaArredondada * 100).round();
          }

          setState(() {
            _distanciaMetros = routeResult.distanciaMetros;
            _tempoDeslocamentoMinutos = (routeResult.tempoDeslocamentoSegundos / 60).round();
            if (calculatedTaxaCentavos != null) {
              _taxaCtrl.removeListener(_onEntregaFieldsChanged);
              _taxaCtrl.text = (calculatedTaxaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
              _taxaCtrl.addListener(_onEntregaFieldsChanged);
            }
          });

          widget.controller.updateEntrega(
            widget.controller.entrega.copyWith(
              distanciaMetros: routeResult.distanciaMetros,
              tempoDeslocamentoSegundos: routeResult.tempoDeslocamentoSegundos,
              taxaEntregaCentavos: calculatedTaxaCentavos ?? widget.controller.entrega.taxaEntregaCentavos,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[_calcularRotaPreview] Erro na chamada à API: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  String _formatTempoDeslocamento(int totalMinutos) {
    if (totalMinutos < 60) {
      return '$totalMinutos min';
    }
    final horas = totalMinutos ~/ 60;
    final minutos = totalMinutos % 60;
    if (minutos == 0) {
      return '$horas h';
    }
    return '${horas}h ${minutos}min';
  }

  String _normalizeString(String str) {
    var s = str.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[áàãâä]'), 'a');
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[íìîï]'), 'i');
    s = s.replaceAll(RegExp(r'[óòõôö]'), 'o');
    s = s.replaceAll(RegExp(r'[úùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ç]'), 'c');
    return s;
  }

  Future<List<LocalEntrega>> _limparELembrarEnderecosValidos(String clienteId) async {
    final todosLocais = await widget.controller.localRepo.findByClienteId(clienteId);
    if (todosLocais.isEmpty) return [];

    final Map<String, List<LocalEntrega>> porRua = {};
    for (final loc in todosLocais) {
      final ruaNorm = _normalizeString(loc.logradouro);
      porRua.putIfAbsent(ruaNorm, () => []).add(loc);
    }

    final List<LocalEntrega> validos = [];
    final List<String> idsParaDeletar = [];

    for (final entry in porRua.entries) {
      final grupoRua = entry.value;
      grupoRua.sort((a, b) {
        final compLogr = b.logradouro.length.compareTo(a.logradouro.length);
        if (compLogr != 0) return compLogr;
        return b.numero.length.compareTo(a.numero.length);
      });

      final List<LocalEntrega> mantidosNaRua = [];

      for (final item in grupoRua) {
        final numClean = _normalizeString(item.numero);
        final logrClean = _normalizeString(item.logradouro);

        final bool eIncompleto = mantidosNaRua.any((rep) {
          final repNum = _normalizeString(rep.numero);
          final repLogr = _normalizeString(rep.logradouro);

          final mesmoNumeroPrefix = repNum == numClean || (repNum.isNotEmpty && repNum.startsWith(numClean));
          final mesmaRuaPrefix = repLogr == logrClean || repLogr.startsWith(logrClean);

          return mesmaRuaPrefix && mesmoNumeroPrefix;
        });

        if (eIncompleto) {
          if (item.id != null) {
            idsParaDeletar.add(item.id!);
          }
        } else {
          mantidosNaRua.add(item);
        }
      }

      validos.addAll(mantidosNaRua);
    }

    for (final id in idsParaDeletar) {
      try {
        await widget.controller.localRepo.delete(id);
      } catch (e) {
        debugPrint('Erro ao deletar endereço incompleto do banco: $e');
      }
    }

    return validos;
  }

  void _persistirEndereco(String clienteId) async {
    final activeTenantId = TenantContext().empresa.id;
    final tenantUserId = TenantContext().hasContext ? TenantContext().usuario.id : '00000000-0000-0000-0000-000000000000';
    final logradouro = _logradouroCtrl.text.trim();
    final numero = _numeroCtrl.text.trim();
    final bairro = _bairroCtrl.text.trim();

    if (logradouro.isEmpty) return;

    // Verificar se já existe um endereço idêntico para este cliente
    final existentes = await widget.controller.localRepo.findByClienteId(clienteId);
    final jaExiste = existentes.any((l) =>
      _normalizeString(l.logradouro) == _normalizeString(logradouro) &&
      _normalizeString(l.numero) == _normalizeString(numero) &&
      _normalizeString(l.bairro) == _normalizeString(bairro)
    );

    if (jaExiste) return;

    final rotulo = _rotuloEnderecoCtrl.text.trim().isNotEmpty
        ? _rotuloEnderecoCtrl.text.trim()
        : 'Casa';
    final novoLocal = LocalEntrega(
      id: const Uuid().v4(),
      tenantId: activeTenantId,
      clienteId: clienteId,
      nomeIdentificador: rotulo,
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      cidade: _cidadeCtrl.text.trim(),
      cep: _cepCtrl.text.trim(),
      referencia: _referenciaCtrl.text.trim(),
      ativo: true,
      metadata: SyncMetadata(
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: tenantUserId,
        updatedBy: tenantUserId,
      ),
    );
    await widget.controller.localRepo.save(novoLocal);

    final atualizados = await _limparELembrarEnderecosValidos(clienteId);
    if (mounted) {
      setState(() {
        _clienteEnderecos = atualizados;
        _selectedLocalEntrega = novoLocal;
        _isNovoEndereco = false;
      });
    }
  }

  void _selectClienteFromCombobox(Cliente? c) async {
    if (c == null) return;

    setState(() {
      _selectedCliente = c;
      _nameCtrl.text = c.nome;
      _phoneCtrl.text = c.telefone;
    });

    widget.controller.updateCliente(
      widget.controller.cliente.copyWith(
        id: c.id,
        nome: c.nome,
        telefone: c.telefone,
      ),
    );

    // Buscar e limpar endereços salvos deste cliente
    if (c.id != null) {
      final validos = await _limparELembrarEnderecosValidos(c.id!);
      if (mounted) {
        setState(() {
          _clienteEnderecos = validos;
          if (validos.isNotEmpty) {
            _selectedLocalEntrega = validos.first;
            _isNovoEndereco = false;
            _salvarEnderecoFuturo = false;
            _preencherEnderecoFromModel(validos.first);
          } else {
            _selectedLocalEntrega = null;
            _isNovoEndereco = true;
            _limparEndereco();
          }
        });
      }
    }
  }

  Future<void> _buscarCepViaApi(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() => _isSearchingViaCep = true);

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        if (json['erro'] != true && mounted) {
          final logradouro = json['logradouro'] ?? '';
          final bairro = json['bairro'] ?? '';
          final cidade = json['localidade'] ?? '';

          // Remover listeners temporariamente para evitar múltiplas chamadas redundantes de debounce
          _logradouroCtrl.removeListener(_onEntregaFieldsChanged);
          _bairroCtrl.removeListener(_onEntregaFieldsChanged);
          _cidadeCtrl.removeListener(_onEntregaFieldsChanged);
          _taxaCtrl.removeListener(_onEntregaFieldsChanged);

          _logradouroCtrl.text = logradouro;
          _bairroCtrl.text = bairro;
          if (cidade.isNotEmpty) {
            _cidadeCtrl.text = cidade;
          }

          if (bairro.isNotEmpty) {
            final taxaCadastrada = await widget.controller.taxaRepo.findByBairro(bairro);
            if (taxaCadastrada != null && taxaCadastrada.valorCentavos > 0) {
              final valorReais = (taxaCadastrada.valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
              _taxaCtrl.text = valorReais;
            }
          }

          _logradouroCtrl.addListener(_onEntregaFieldsChanged);
          _bairroCtrl.addListener(_onEntregaFieldsChanged);
          _cidadeCtrl.addListener(_onEntregaFieldsChanged);
          _taxaCtrl.addListener(_onEntregaFieldsChanged);

          final cleanTaxa = _taxaCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
          final taxaReais = double.tryParse(cleanTaxa) ?? 0.0;

          widget.controller.updateEntrega(
            widget.controller.entrega.copyWith(
              logradouro: _logradouroCtrl.text,
              bairro: _bairroCtrl.text,
              cidade: _cidadeCtrl.text,
              cep: _cepCtrl.text,
              taxaEntregaCentavos: (taxaReais * 100).round(),
            ),
          );

          _routeDebounce?.cancel();
          _calcularRotaPreview();
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar ViaCEP no PDV: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearchingViaCep = false);
      }
    }
  }

  void _preencherEnderecoFromModel(LocalEntrega loc) async {
    debugPrint('[_preencherEnderecoFromModel] Iniciado para id=${loc.id}, cep=${loc.cep}, numero=${loc.numero}, rua=${loc.logradouro}');

    // 1. Atualizar campos de endereço IMEDIATAMENTE e de forma síncrona
    _logradouroCtrl.removeListener(_onEntregaFieldsChanged);
    _numeroCtrl.removeListener(_onEntregaFieldsChanged);
    _bairroCtrl.removeListener(_onEntregaFieldsChanged);
    _referenciaCtrl.removeListener(_onEntregaFieldsChanged);
    _cidadeCtrl.removeListener(_onEntregaFieldsChanged);
    _cepCtrl.removeListener(_onEntregaFieldsChanged);
    _taxaCtrl.removeListener(_onEntregaFieldsChanged);

    setState(() {
      _logradouroCtrl.text = loc.logradouro;
      _numeroCtrl.text = loc.numero;
      _bairroCtrl.text = loc.bairro;
      _referenciaCtrl.text = loc.referencia;
      _cidadeCtrl.text = loc.cidade.isNotEmpty ? loc.cidade : 'São Paulo';
      _cepCtrl.text = loc.cep;
      _taxaCtrl.text = '0,00'; // Valor provisório até buscar a taxa
    });

    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        logradouro: loc.logradouro,
        numero: loc.numero,
        bairro: loc.bairro,
        referencia: loc.referencia,
        cidade: loc.cidade,
        cep: loc.cep,
        taxaEntregaCentavos: 0,
      ),
    );

    // Disparar o cálculo da rota imediatamente sem esperar a taxa
    _routeDebounce?.cancel();
    _calcularRotaPreview();

    // 2. Buscar a taxa de entrega de forma assíncrona
    try {
      final taxaCadastrada = await widget.controller.taxaRepo.findByBairro(loc.bairro);
      final valorCentavos = taxaCadastrada?.valorCentavos ?? 0;
      debugPrint('[_preencherEnderecoFromModel] Taxa encontrada: $valorCentavos centavos');

      if (mounted) {
        setState(() {
          _taxaCtrl.text = (valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
        });
        widget.controller.updateEntrega(
          widget.controller.entrega.copyWith(
            taxaEntregaCentavos: valorCentavos,
          ),
        );
      }
    } catch (e) {
      debugPrint('[_preencherEnderecoFromModel] Erro ao buscar taxa: $e');
    } finally {
      // Re-adicionar os listeners
      _logradouroCtrl.addListener(_onEntregaFieldsChanged);
      _numeroCtrl.addListener(_onEntregaFieldsChanged);
      _bairroCtrl.addListener(_onEntregaFieldsChanged);
      _referenciaCtrl.addListener(_onEntregaFieldsChanged);
      _cidadeCtrl.addListener(_onEntregaFieldsChanged);
      _cepCtrl.addListener(_onEntregaFieldsChanged);
      _taxaCtrl.addListener(_onEntregaFieldsChanged);
    }
  }

  void _limparEndereco() {
    _logradouroCtrl.removeListener(_onEntregaFieldsChanged);
    _numeroCtrl.removeListener(_onEntregaFieldsChanged);
    _bairroCtrl.removeListener(_onEntregaFieldsChanged);
    _referenciaCtrl.removeListener(_onEntregaFieldsChanged);
    _cidadeCtrl.removeListener(_onEntregaFieldsChanged);
    _cepCtrl.removeListener(_onEntregaFieldsChanged);
    _taxaCtrl.removeListener(_onEntregaFieldsChanged);

    setState(() {
      _logradouroCtrl.clear();
      _numeroCtrl.clear();
      _bairroCtrl.clear();
      _referenciaCtrl.clear();
      _cidadeCtrl.text = 'São Paulo';
      _cepCtrl.clear();
      _taxaCtrl.text = '0,00';
      _tempoDeslocamentoMinutos = null;
      _distanciaMetros = null;
    });

    _logradouroCtrl.addListener(_onEntregaFieldsChanged);
    _numeroCtrl.addListener(_onEntregaFieldsChanged);
    _bairroCtrl.addListener(_onEntregaFieldsChanged);
    _referenciaCtrl.addListener(_onEntregaFieldsChanged);
    _cidadeCtrl.addListener(_onEntregaFieldsChanged);
    _cepCtrl.addListener(_onEntregaFieldsChanged);
    _taxaCtrl.addListener(_onEntregaFieldsChanged);

    widget.controller.updateEntrega(
      widget.controller.entrega.copyWith(
        logradouro: '',
        numero: '',
        bairro: '',
        referencia: '',
        cidade: 'São Paulo',
        cep: '',
        taxaEntregaCentavos: 0,
        distanciaMetros: null,
        tempoDeslocamentoSegundos: null,
      ),
    );
    _routeDebounce?.cancel();
  }

  void _abrirModalNovoCliente() async {
    final novo = await ClienteFormDialog.show(context);

    if (novo != null && mounted) {
      // Recarregar clientes no controller
      final clientesAtualizados = await widget.controller.clienteRepo.findAll();
      widget.controller.clientes.clear();
      widget.controller.clientes.addAll(clientesAtualizados);
      _selectClienteFromCombobox(novo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entrega = widget.controller.entrega;
    final isEntrega = entrega.tipo == 'Entrega';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card 1: IDENTIFICAÇÃO DO CLIENTE ──────────────────────
          _buildSectionCard(
            title: 'IDENTIFICAÇÃO DO CLIENTE',
            icon: Icons.person_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCliente == null) ...[
                  Row(
                    children: [
                      // Autocomplete/Busca de cliente
                      Expanded(
                        child: Autocomplete<Cliente>(
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
                          onSelected: _selectClienteFromCombobox,
                          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: '🔍 Buscar cliente por nome ou telefone...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(Icons.person_search_outlined, color: FincoreColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: FincoreColors.border),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botão + Novo Cliente
                      ElevatedButton.icon(
                        onPressed: _abrirModalNovoCliente,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.primary.withValues(alpha: 0.15),
                          foregroundColor: FincoreColors.primary,
                          side: BorderSide(color: FincoreColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Novo Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ] else ...[
                  // Card do cliente selecionado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: FincoreColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            _selectedCliente!.nome.isNotEmpty ? _selectedCliente!.nome[0].toUpperCase() : '?',
                            style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCliente!.nome,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (_selectedCliente!.telefone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _selectedCliente!.telefone,
                                  style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCliente = null;
                              _nameCtrl.clear();
                              _phoneCtrl.clear();
                              _clienteEnderecos = [];
                              _selectedLocalEntrega = null;
                              _isNovoEndereco = true;
                              _limparEndereco();
                            });
                          },
                          icon: const Icon(Icons.close, size: 16, color: FincoreColors.danger),
                          label: const Text('Alterar', style: TextStyle(color: FincoreColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Card 2: LOGÍSTICA & ATENDIMENTO ───────────────────────
          _buildSectionCard(
            title: 'CANAL DE ATENDIMENTO',
            icon: Icons.local_shipping_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pílulas segmentadas: Entrega vs Retirada
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          widget.controller.updateEntrega(
                            widget.controller.entrega.copyWith(tipo: 'Entrega'),
                          );
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isEntrega
                                ? FincoreColors.primary.withValues(alpha: 0.15)
                                : FincoreColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEntrega ? FincoreColors.primary : FincoreColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delivery_dining_outlined,
                                color: isEntrega ? FincoreColors.primary : FincoreColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🚚 ENTREGA (DELIVERY)',
                                style: TextStyle(
                                  color: isEntrega ? Colors.white : FincoreColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          widget.controller.updateEntrega(
                            widget.controller.entrega.copyWith(
                              tipo: 'Retirada',
                              taxaEntregaCentavos: 0,
                            ),
                          );
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !isEntrega && entrega.tipo != 'Mesa'
                                ? FincoreColors.primary.withValues(alpha: 0.15)
                                : FincoreColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !isEntrega && entrega.tipo != 'Mesa' ? FincoreColors.primary : FincoreColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                color: !isEntrega && entrega.tipo != 'Mesa' ? FincoreColors.primary : FincoreColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🏪 RETIRADA NO BALCÃO',
                                style: TextStyle(
                                  color: !isEntrega && entrega.tipo != 'Mesa' ? Colors.white : FincoreColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.controller.modoComandasAtivo) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            widget.controller.updateEntrega(
                              widget.controller.entrega.copyWith(
                                tipo: 'Mesa',
                                taxaEntregaCentavos: 0,
                              ),
                            );
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: entrega.tipo == 'Mesa'
                                  ? FincoreColors.primary.withValues(alpha: 0.15)
                                  : FincoreColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: entrega.tipo == 'Mesa' ? FincoreColors.primary : FincoreColors.border,
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.table_restaurant_outlined,
                                  color: entrega.tipo == 'Mesa' ? FincoreColors.primary : FincoreColors.textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '🍽️ MESA / COMANDA',
                                  style: TextStyle(
                                    color: entrega.tipo == 'Mesa' ? Colors.white : FincoreColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
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

                // Atendimento Presencial: Mesa / Garçom
                if (entrega.tipo == 'Mesa' && widget.controller.modoComandasAtivo) ...[
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
                          onChanged: (v) {
                            widget.controller.updateEntrega(
                              widget.controller.entrega.copyWith(mesa: v),
                            );
                          },
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
                          onChanged: (v) {
                            widget.controller.updateEntrega(
                              widget.controller.entrega.copyWith(garcom: v),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                // Endereços e Taxa de Entrega (Apenas se for Delivery)
                if (isEntrega) ...[
                  // 1. Seletor de Endereço Cadastrado do Cliente
                  if (_clienteEnderecos.isNotEmpty) ...[
                    const Text(
                      'SELECIONAR ENDEREÇO DE ENTREGA',
                      style: TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._clienteEnderecos.map((loc) {
                      final isSelected = _selectedLocalEntrega?.id == loc.id && !_isNovoEndereco;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedLocalEntrega = loc;
                              _isNovoEndereco = false;
                              _salvarEnderecoFuturo = false;
                              _preencherEnderecoFromModel(loc);
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? FincoreColors.primary.withValues(alpha: 0.08) : FincoreColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? FincoreColors.primary : FincoreColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? FincoreColors.primary : FincoreColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.nomeIdentificador.toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : FincoreColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${loc.logradouro}, ${loc.numero} - ${loc.bairro}',
                                        style: TextStyle(
                                          color: isSelected ? FincoreColors.textSecondary : FincoreColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // Opção de Novo Endereço
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLocalEntrega = null;
                          _isNovoEndereco = true;
                          _limparEndereco();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isNovoEndereco ? FincoreColors.primary.withValues(alpha: 0.08) : FincoreColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isNovoEndereco ? FincoreColors.primary : FincoreColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isNovoEndereco ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _isNovoEndereco ? FincoreColors.primary : FincoreColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '➕ ENTREGAR EM UM NOVO ENDEREÇO...',
                              style: TextStyle(
                                color: _isNovoEndereco ? Colors.white : FincoreColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Banner informativo quando for endereço cadastrado selecionado
                  if (!_isNovoEndereco && _selectedLocalEntrega != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: FincoreColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: FincoreColors.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Endereço cadastrado selecionado (Edição protegida). Selecione "➕ Entregar em um Novo Endereço" para alterar.',
                              style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Formulário manual de Endereço (Apenas se for Novo Endereço)
                  if (_isNovoEndereco) ...[
                    // CEP + Cidade
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cepCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: FincoreFormatters.cep,
                            decoration: InputDecoration(
                              labelText: 'CEP (Busca Automática) *',
                              hintText: '00000-000',
                              prefixIcon: Icon(Icons.search_outlined, color: FincoreColors.primary, size: 18),
                              suffixIcon: _isSearchingViaCep
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: FincoreColors.primary),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.arrow_forward, color: FincoreColors.primary, size: 18),
                                      onPressed: () => _buscarCepViaApi(_cepCtrl.text),
                                    ),
                            ),
                            onChanged: (v) {
                              if (v.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                                _buscarCepViaApi(v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _cidadeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Cidade *',
                              hintText: 'Ex: São Paulo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rua + Número
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _logradouroCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Rua / Logradouro *',
                              hintText: 'Ex: Alameda Santos',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _numeroCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Número *',
                              hintText: 'Ex: 1500',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bairro + Referência
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bairroCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Bairro *',
                              hintText: 'Ex: Jardins',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _referenciaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Referência (opcional)',
                              hintText: 'Ex: Apto 12',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Prioridade (Sempre visível para entrega)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: entrega.prioridade,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Prioridade da Entrega',
                            prefixIcon: Icon(Icons.error_outline, color: FincoreColors.textMuted, size: 18),
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
                      // Card de visualização e ajuste da taxa de entrega
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: FincoreColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: FincoreColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'TAXA ENTREGA',
                                    style: TextStyle(color: FincoreColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'R\$ ${_taxaCtrl.text}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _mostrarAjusteTaxa = !_mostrarAjusteTaxa;
                                  });
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                child: Text(
                                  _mostrarAjusteTaxa ? 'Concluir' : 'Ajustar',
                                  style: TextStyle(color: FincoreColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Se o operador está ajustando a taxa, exibir o TextField
                  if (_mostrarAjusteTaxa) ...[
                    TextField(
                      controller: _taxaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: widget.controller.empresaConfig?.taxaEntregaPorKm ?? false,
                      decoration: InputDecoration(
                        labelText: 'Digite a Taxa de Entrega (R\$)',
                        prefixText: 'R\$ ',
                        helperText: (widget.controller.empresaConfig?.taxaEntregaPorKm ?? false)
                            ? 'Calculada automaticamente por KM'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Previsão de Rota
                  if (_tempoDeslocamentoMinutos != null && _distanciaMetros != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: FincoreColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car_filled_outlined, color: FincoreColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Previsão de Entrega: ${_formatTempoDeslocamento(_tempoDeslocamentoMinutos!)} de deslocamento (${(_distanciaMetros! / 1000).toStringAsFixed(1)} km)',
                              style: TextStyle(
                                color: FincoreColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_isCalculatingRoute)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: FincoreColors.primary),
                            ),
                        ],
                      ),
                    ),
                  ] else if (_isCalculatingRoute) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: FincoreColors.primary),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Calculando rota...',
                          style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Checkbox de Salvar Endereço (Apenas se for Novo Endereço)
                  if (_isNovoEndereco) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: _salvarEnderecoFuturo,
                          activeColor: FincoreColors.primary,
                          onChanged: (v) {
                            setState(() {
                              _salvarEnderecoFuturo = v ?? false;
                            });
                            if (_salvarEnderecoFuturo && _selectedCliente?.id != null && _logradouroCtrl.text.isNotEmpty) {
                              _persistirEndereco(_selectedCliente!.id!);
                            }
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Salvar este novo endereço para futuras entregas',
                            style: TextStyle(
                              color: FincoreColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_salvarEnderecoFuturo) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Qual o tipo deste endereço?',
                              style: TextStyle(
                                color: FincoreColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildTipoChip('Casa', '🏡 Casa'),
                                _buildTipoChip('Escritório', '🏢 Escritório'),
                                _buildTipoChip('Trabalho', '💼 Trabalho'),
                                _buildTipoChip('Outros', '📍 Outros'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _rotuloEnderecoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Rótulo / Identificador do Endereço',
                                hintText: 'Ex: Casa, Escritório, Casa da mãe, Sítio...',
                                prefixIcon: Icon(Icons.label_outlined, color: FincoreColors.textMuted, size: 18),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_selectedCliente?.id != null && _logradouroCtrl.text.isNotEmpty) {
                                    _persistirEndereco(_selectedCliente!.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Endereço salvo com sucesso no cadastro do cliente!')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                                label: const Text('Salvar Endereço Agora'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FincoreColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Card 3: DATA & HORÁRIO ───────────────────────────────
          if (isEntrega || entrega.tipo == 'Retirada') ...[
            _buildSectionCard(
              title: 'DATA & HORÁRIO DO ATENDIMENTO',
              icon: Icons.access_time_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dataCtrl,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: isEntrega ? 'Data da Entrega' : 'Data da Retirada',
                            prefixIcon: const Icon(Icons.calendar_today_outlined, color: FincoreColors.textMuted, size: 18),
                          ),
                          onTap: () async {
                            final now = widget.controller.entrega.dataHora;
                            final d = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null && mounted) {
                              _dataCtrl.text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                              widget.controller.updateEntrega(
                                widget.controller.entrega.copyWith(
                                  dataHora: DateTime(d.year, d.month, d.day, now.hour, now.minute),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _horaCtrl,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: isEntrega ? 'Hora da Entrega' : 'Hora da Retirada',
                            prefixIcon: const Icon(Icons.access_time_outlined, color: FincoreColors.textMuted, size: 18),
                          ),
                          onTap: () async {
                            final now = widget.controller.entrega.dataHora;
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(now),
                            );
                            if (t != null && mounted) {
                              _horaCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                              widget.controller.updateEntrega(
                                widget.controller.entrega.copyWith(
                                  dataHora: DateTime(now.year, now.month, now.day, t.hour, t.minute),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoChip(String valor, String label) {
    final isSelected = _rotuloEnderecoCtrl.text == valor;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : FincoreColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: FincoreColors.primary,
      backgroundColor: FincoreColors.surface,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _rotuloEnderecoCtrl.text = valor;
          });
          if (_salvarEnderecoFuturo && _selectedCliente?.id != null && _logradouroCtrl.text.isNotEmpty) {
            _persistirEndereco(_selectedCliente!.id!);
          }
        }
      },
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
        borderRadius: BorderRadius.circular(12),
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
                title,
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
}

/// Dialog para Cadastro Rápido de Novo Cliente no PDV
class _CadastroClienteDialog extends StatefulWidget {
  final PdvExpressController controller;

  const _CadastroClienteDialog({required this.controller});

  @override
  State<_CadastroClienteDialog> createState() => _CadastroClienteDialogState();
}

class _CadastroClienteDialogState extends State<_CadastroClienteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();

  bool _isSearchingCep = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _phoneCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cepCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() => _isSearchingCep = true);

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        if (json['erro'] != true && mounted) {
          setState(() {
            _logradouroCtrl.text = json['logradouro'] ?? '';
            _bairroCtrl.text = json['bairro'] ?? '';
          });
        }
      }
    } catch (_) {
      // Ignorar erros de rede na busca rapida
    } finally {
      if (mounted) {
        setState(() => _isSearchingCep = false);
      }
    }
  }

  void _salvar() async {
    if (_formKey.currentState?.validate() ?? false) {
      final tenantUserId = TenantContext().hasContext ? TenantContext().usuario.id : '00000000-0000-0000-0000-000000000000';
      final activeTenantId = TenantContext().empresa.id;
      final id = const Uuid().v4();
      final novoCliente = Cliente(
        id: id,
        tenantId: activeTenantId,
        nome: _nomeCtrl.text.trim(),
        telefone: _phoneCtrl.text.trim(),
        observacoes: '',
        ativo: true,
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: tenantUserId,
          updatedBy: tenantUserId,
        ),
      );

      await widget.controller.clienteRepo.save(novoCliente);

      if (_logradouroCtrl.text.trim().isNotEmpty) {
        final local = LocalEntrega(
          id: const Uuid().v4(),
          tenantId: activeTenantId,
          clienteId: id,
          nomeIdentificador: 'Principal',
          logradouro: _logradouroCtrl.text.trim(),
          numero: _numeroCtrl.text.trim(),
          bairro: _bairroCtrl.text.trim(),
          cidade: 'São Paulo',
          cep: _cepCtrl.text.trim(),
          referencia: '',
          ativo: true,
          metadata: SyncMetadata(
            version: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: tenantUserId,
            updatedBy: tenantUserId,
          ),
        );
        await widget.controller.localRepo.save(local);
      }

      if (mounted) {
        Navigator.of(context).pop(novoCliente);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_outlined, color: FincoreColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Cadastrar Novo Cliente',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: FincoreColors.border, height: 24),
              TextFormField(
                controller: _nomeCtrl,
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do cliente' : null,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo *',
                  hintText: 'Ex: Buffet Sonho de Festa',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o telefone' : null,
                decoration: const InputDecoration(
                  labelText: 'Telefone *',
                  hintText: 'Ex: (11) 91234-5678',
                ),
              ),
              const SizedBox(height: 16),
              
              // Endereço - CEP em primeiro com Busca Automática
              TextFormField(
                controller: _cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: FincoreFormatters.cep,
                decoration: InputDecoration(
                  labelText: 'CEP (Busca Automática)',
                  hintText: '00000-000',
                  prefixIcon: Icon(Icons.search_outlined, color: FincoreColors.primary, size: 18),
                  suffixIcon: _isSearchingCep
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: FincoreColors.primary),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.arrow_forward, color: FincoreColors.primary, size: 18),
                          onPressed: () => _buscarCep(_cepCtrl.text),
                        ),
                ),
                onChanged: (v) {
                  if (v.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                    _buscarCep(v);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _logradouroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Logradouro (opcional)',
                        hintText: 'Ex: Alameda Santos',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _numeroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nº',
                        hintText: '1500',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bairroCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bairro (opcional)',
                  hintText: 'Jardins',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Salvar Cliente'),
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
