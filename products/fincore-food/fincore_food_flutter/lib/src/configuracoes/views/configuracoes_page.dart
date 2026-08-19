import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:fincore_core/repository/empresa_repository.dart';
import 'package:flutter/services.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_page_header.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/services/fincore_thermal_printer_service.dart';
import 'package:fincore_food_flutter/src/shared/services/impressao_service.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/audit_timeline_panel.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/log_explorer_dialog.dart';
import 'package:fincore_food_flutter/src/configuracoes/views/subviews/personalizacao_view.dart';

/// Tela de Configurações da Empresa — Navegação ERP por Domínios
/// Módulo 1 (Empresa), Módulo 2 (Operação: Regional, Fiscal, PIX), Módulo 3 (Impressão), Módulo 5 (Segurança), Módulo 6 (Auditoria), Módulo 7 (Aparência White-Label)
class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  late final EmpresaConfiguracaoRepository _repo;
  late final EmpresaRepository _empresaRepo;
  CoreEmpresaConfiguracao? _config;
  CoreEmpresa? _empresa;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  int _selectedSection = 0;
  int _operacaoSubSection = 0; // 0: Regional, 1: Fiscal, 2: PIX

  final _personalizacaoKey = GlobalKey<PersonalizacaoViewState>();

  Timer? _debounceTimer;
  String _syncMessage = '';
  SyncStatus _syncStatus = SyncStatus.synced;

  // Controllers
  final _pixKeyCtrl = TextEditingController();
  final _pixFavorecidoCtrl = TextEditingController();
  final _pixBancoCtrl = TextEditingController();
  String _pixTipo = 'CPF';
  bool _exibirQrCode = true;
  bool _exibirCopiaCola = true;

  final _printerCtrl = TextEditingController();
  final _printerCaixaCtrl = TextEditingController(text: 'USB001 / TM-T20');
  final _printerCozinhaCtrl = TextEditingController(text: '192.168.1.200');
  final _printerExpedicaoCtrl = TextEditingController(text: '192.168.1.201');
  final _printerBalcaoCtrl = TextEditingController();
  final _mensagemRodapeCtrl = TextEditingController(text: 'Obrigado pela preferência!');
  final _nomeEmpresaCupomCtrl = TextEditingController();
  final _telefoneEmpresaCtrl = TextEditingController();
  final _cnpjEmpresaCtrl = TextEditingController();
  final _enderecoEmpresaCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _enderecoRuaCtrl = TextEditingController();
  final _enderecoNumeroCtrl = TextEditingController();
  final _enderecoBairroCtrl = TextEditingController();
  final _enderecoComplementoCtrl = TextEditingController();
  final _enderecoCidadeCtrl = TextEditingController();
  final _enderecoEstadoCtrl = TextEditingController();
  final _taxaServicoCtrl = TextEditingController();

  final _razaoSocialCtrl = TextEditingController();
  final _inscricaoEstadualCtrl = TextEditingController();
  final _inscricaoMunicipalCtrl = TextEditingController();
  final _regimeTributarioCtrl = TextEditingController();
  final _emailEmpresaCtrl = TextEditingController();
  String _tipoPessoa = 'JURIDICA';

  String _selectedTimezone = 'America/Sao_Paulo';
  String _selectedLocale = 'pt_BR';
  String _selectedCurrency = 'BRL';
  String _selectedTema = 'dark';
  bool _usarWhatsApp = true;
  bool _usarMercadoPago = true;
  bool _usarOpenPix = true;
  bool _usarAsaas = false;
  bool _usariFood = true;

  String _selectedCrt = '1';
  String _selectedAmbienteFiscal = '2';
  String _selectedModeloFiscal = 'NFCe';
  bool _emissaoFiscalAtiva = true;

  // Parametrização PDV e Vendas
  bool _modoDeliveryAtivo = true;
  bool _modoComandasAtivo = false;
  bool _clienteObrigatorioVenda = false;
  String _atendimentoPadrao = 'Delivery';
  final _margemSegurancaCtrl = TextEditingController();
  bool _taxaEntregaPorKm = false;
  final _valorPorKmCtrl = TextEditingController();

  final List<PixKeyModel> _pixKeys = [];
  final List<PrinterModel> _printers = [];

  bool _autoPrintCaixa = true;
  bool _autoPrintCozinha = true;
  bool _autoPrintExpedicao = true;
  bool _autoPrintBalcao = false;
  int _viasCliente = 1;
  int _viasCozinha = 1;
  int _viasBalcao = 0;
  int _viasExpedicao = 0;
  bool _cortarPapel = true;
  bool _abrirGaveta = false;
  String _larguraBobina = '80mm';

  static const _sections = [
    _SectionItem(icon: Icons.business_outlined, label: 'Empresa'),
    _SectionItem(icon: Icons.settings_outlined, label: 'Operação'),
    _SectionItem(icon: Icons.receipt_long_outlined, label: 'Fiscal'),
    _SectionItem(icon: Icons.pix_outlined, label: 'PIX / Pagamentos'),
    _SectionItem(icon: Icons.print_outlined, label: 'Impressão'),
    _SectionItem(icon: Icons.security_outlined, label: 'Segurança'),
    _SectionItem(icon: Icons.history_outlined, label: 'Auditoria'),
    _SectionItem(icon: Icons.palette_outlined, label: 'Aparência'),
  ];

  @override
  void initState() {
    super.initState();
    _repo = DependencyInjection().get<EmpresaConfiguracaoRepository>();
    _empresaRepo = DependencyInjection().get<EmpresaRepository>();
    _loadConfig();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pixKeyCtrl.dispose();
    _printerCtrl.dispose();
    _printerCaixaCtrl.dispose();
    _printerCozinhaCtrl.dispose();
    _printerExpedicaoCtrl.dispose();
    _printerBalcaoCtrl.dispose();
    _mensagemRodapeCtrl.dispose();
    _nomeEmpresaCupomCtrl.dispose();
    _telefoneEmpresaCtrl.dispose();
    _cnpjEmpresaCtrl.dispose();
    _enderecoEmpresaCtrl.dispose();
    _cepCtrl.dispose();
    _enderecoRuaCtrl.dispose();
    _enderecoNumeroCtrl.dispose();
    _enderecoBairroCtrl.dispose();
    _enderecoComplementoCtrl.dispose();
    _enderecoCidadeCtrl.dispose();
    _enderecoEstadoCtrl.dispose();
    _taxaServicoCtrl.dispose();
    _razaoSocialCtrl.dispose();
    _inscricaoEstadualCtrl.dispose();
    _inscricaoMunicipalCtrl.dispose();
    _regimeTributarioCtrl.dispose();
    _emailEmpresaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final empresas = await _empresaRepo.findAll();
      
      // Logs de Depuração Forense
      print('DEBUG CONFIG: Empresas locais no SQLite: ${empresas.map((e) => "${e.nomeFantasia} (ID: ${e.id})").toList()}');
      print('DEBUG CONFIG: Contexto de Tenant ativo: ${tenantCtx.hasContext ? "${tenantCtx.empresa.nomeFantasia} (ID: ${tenantCtx.empresa.id})" : "Sem contexto"}');

      if (empresas.isNotEmpty) {
        _empresa = empresas.firstWhere(
          (e) => e.nomeFantasia != 'FINCORE Food Demo',
          orElse: () => tenantCtx.hasContext ? tenantCtx.empresa : empresas.first,
        );
      } else if (tenantCtx.hasContext) {
        _empresa = tenantCtx.empresa;
      }

      print('DEBUG CONFIG: Empresa selecionada para exibição: ${_empresa?.nomeFantasia} (CNPJ: ${_empresa?.documentoFiscal}, Fone: ${_empresa?.telefone}, CEP: ${_empresa?.cep}, Cidade: ${_empresa?.cidade})');

      final targetTenantId = _empresa?.id ?? (tenantCtx.hasContext ? tenantCtx.empresa.id : '00000000-0000-4000-a000-000000000001');

      final configs = await _repo.findAll();
      CoreEmpresaConfiguracao? config;
      if (configs.isNotEmpty) {
        config = configs.firstWhere(
          (c) => c.tenantId == targetTenantId,
          orElse: () => configs.first,
        );
      }
      
      if (config == null) {
        config = CoreEmpresaConfiguracao(
          id: targetTenantId,
          tenantId: targetTenantId,
          taxaServico: 0.10,
          usarWhatsApp: true,
          tema: 'dark',
          metadata: SyncMetadata(
            version: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
            updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
            syncStatus: SyncStatus.pending,
          ),
        );
        await _repo.save(config);
      }

      setState(() {
        _config = config;
        _syncStatus = config!.metadata.syncStatus;
        _syncMessage = _syncStatusMessage(config.metadata.syncStatus, config.metadata.lastSyncedAt);
        _isLoading = false;
      });
      _populateControllers(config);
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers(CoreEmpresaConfiguracao config) async {
    _pixKeyCtrl.text = config.pixKey ?? '';
    _printerCtrl.text = config.printerConfig ?? '';
    _selectedTimezone = _empresa?.timezone ?? 'America/Sao_Paulo';
    _selectedLocale = _empresa?.locale ?? 'pt_BR';
    _selectedCurrency = _empresa?.currency ?? 'BRL';
    _selectedTema = config.tema;
    _usarWhatsApp = config.usarWhatsApp;
    _usarMercadoPago = config.mercadoPagoAtivo;
    _usarOpenPix = config.openPixAtivo;
    _usarAsaas = config.asaasAtivo;
    _usariFood = config.ifoodAtivo;
    _modoDeliveryAtivo = config.modoDeliveryAtivo;
    _modoComandasAtivo = config.modoComandasAtivo;
    _clienteObrigatorioVenda = config.clienteObrigatorioVenda;
    _atendimentoPadrao = config.atendimentoPadrao;
    _taxaServicoCtrl.text = (config.taxaServico * 100).toStringAsFixed(1);
    _margemSegurancaCtrl.text = config.margemSegurancaMinutos.toString();
    _taxaEntregaPorKm = config.taxaEntregaPorKm;
    _valorPorKmCtrl.text = (config.valorPorKmCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');

    _printerCaixaCtrl.text = config.printerCaixa ?? '';
    _printerCozinhaCtrl.text = config.printerCozinha ?? '';
    _printerBalcaoCtrl.text = config.printerBalcao ?? '';
    _printerExpedicaoCtrl.text = config.printerExpedicao ?? '';
    _autoPrintCaixa = config.autoPrintCaixa;
    _autoPrintCozinha = config.autoPrintCozinha;
    _autoPrintBalcao = config.autoPrintBalcao;
    _autoPrintExpedicao = config.autoPrintExpedicao;
    _viasCliente = config.viasCliente;
    _viasCozinha = config.viasCozinha;
    _viasBalcao = config.viasBalcao;
    _viasExpedicao = config.viasExpedicao;
    _larguraBobina = '${config.larguraPapel}mm';
    _cortarPapel = config.cortarPapel;
    _abrirGaveta = config.abrirGaveta;
    _exibirQrCode = config.imprimirQRCode;
    _exibirCopiaCola = config.imprimirCopiaCola;
    _mensagemRodapeCtrl.text = config.mensagemRodape;

    // Dados Reais da Empresa no Banco de Dados
    _nomeEmpresaCupomCtrl.text = _empresa?.nomeFantasia ?? '';
    _razaoSocialCtrl.text = _empresa?.razaoSocial ?? '';
    _cnpjEmpresaCtrl.text = _empresa?.documentoFiscal ?? '';
    _telefoneEmpresaCtrl.text = _empresa?.telefone ?? '';
    _emailEmpresaCtrl.text = _empresa?.email ?? '';
    // Endereço estruturado — leitura direta, sem regex
    _cepCtrl.text = _empresa?.cep ?? '';
    _enderecoRuaCtrl.text = _empresa?.logradouro ?? '';
    _enderecoNumeroCtrl.text = _empresa?.numero ?? '';
    _enderecoBairroCtrl.text = _empresa?.bairro ?? '';
    _enderecoComplementoCtrl.text = _empresa?.complemento ?? '';
    _enderecoCidadeCtrl.text = _empresa?.cidade ?? '';
    _enderecoEstadoCtrl.text = _empresa?.estado ?? '';
    _inscricaoEstadualCtrl.text = _empresa?.inscricaoEstadual ?? '';
    _inscricaoMunicipalCtrl.text = _empresa?.inscricaoMunicipal ?? '';
    _regimeTributarioCtrl.text = _empresa?.regimeTributario ?? 'Simples Nacional';
    _tipoPessoa = _empresa?.tipoPessoa ?? 'JURIDICA';

    final rawPix = config.pixKey ?? '';
    _pixKeys.clear();
    if (rawPix.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPix);
        if (decoded is List) {
          _pixKeys.addAll(decoded.map((x) => PixKeyModel.fromJson(x as Map<String, dynamic>)));
        }
      } catch (_) {
        _pixKeys.add(PixKeyModel(
          id: 'legacy',
          favorecido: config.pixFavorecido ?? (_empresa?.nomeFantasia ?? ''),
          banco: config.pixBanco ?? '',
          tipo: config.pixTipo,
          chave: config.pixKey ?? '',
        ));
      }
    } else {
      if ((config.pixFavorecido ?? '').isNotEmpty || (config.pixBanco ?? '').isNotEmpty) {
        _pixKeys.add(PixKeyModel(
          id: 'legacy',
          favorecido: config.pixFavorecido ?? (_empresa?.nomeFantasia ?? ''),
          banco: config.pixBanco ?? '',
          tipo: config.pixTipo,
          chave: config.pixKey ?? '',
        ));
      }
    }

    final rawPrinters = config.printerConfig ?? '';
    _printers.clear();
    if (rawPrinters.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPrinters);
        if (decoded is List) {
          _printers.addAll(decoded.map((x) => PrinterModel.fromJson(x as Map<String, dynamic>)));
        }
      } catch (_) {}
    }
    if (_printers.isEmpty) {
      if ((config.printerCaixa ?? '').isNotEmpty) {
        _printers.add(PrinterModel(
          id: 'caixa',
          nome: 'Impressora Caixa',
          tipo: 'Rede',
          departamento: 'Caixa',
          ip: config.printerCaixa ?? '',
          driver: 'ESC/POS',
          autoImpressao: config.autoPrintCaixa,
          vias: config.viasCliente,
          status: true,
        ));
      }
      if ((config.printerCozinha ?? '').isNotEmpty) {
        _printers.add(PrinterModel(
          id: 'cozinha',
          nome: 'Impressora Cozinha',
          tipo: 'Rede',
          departamento: 'Cozinha',
          ip: config.printerCozinha ?? '',
          driver: 'ESC/POS',
          autoImpressao: config.autoPrintCozinha,
          vias: config.viasCozinha,
          status: true,
        ));
      }
    }
  }

  void _parseRestOfAddress(String addr) {
    try {
      final cleanAddr = addr.trim();
      final parts = cleanAddr.split(',');
      
      // Se contiver hífen após a primeira parte, ex. "Avenida Paulista, 1000 - São Paulo/SP"
      if (parts.length > 1 && parts[1].contains('-')) {
        _enderecoRuaCtrl.text = parts[0].trim();
        final rest = parts[1].split('-');
        if (rest.isNotEmpty) _enderecoNumeroCtrl.text = rest[0].trim();
        if (rest.length > 1) {
          final cityState = rest[1].split('/');
          if (cityState.isNotEmpty) _enderecoCidadeCtrl.text = cityState[0].trim();
          if (cityState.length > 1) _enderecoEstadoCtrl.text = cityState[1].trim();
        }
      } else {
        // Formato alternativo separado por vírgulas: "Rua das Flores, 100, Sorocaba, SP"
        if (parts.length >= 4) {
          _enderecoRuaCtrl.text = parts[0].trim();
          _enderecoNumeroCtrl.text = parts[1].trim();
          _enderecoCidadeCtrl.text = parts[2].trim();
          _enderecoEstadoCtrl.text = parts[3].trim();
        } else if (parts.length == 3) {
          // "Rua das Flores, 100, Sorocaba"
          _enderecoRuaCtrl.text = parts[0].trim();
          _enderecoNumeroCtrl.text = parts[1].trim();
          _enderecoCidadeCtrl.text = parts[2].trim();
        } else if (parts.length == 2) {
          // "Rua das Flores, 100"
          _enderecoRuaCtrl.text = parts[0].trim();
          _enderecoNumeroCtrl.text = parts[1].trim();
        } else {
          _enderecoRuaCtrl.text = cleanAddr;
        }
      }
    } catch (_) {
      _enderecoRuaCtrl.text = addr;
    }
  }

  Future<void> _buscarCep(String cep) async {
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
          setState(() {
            _enderecoRuaCtrl.text = json['logradouro'] ?? '';
            _enderecoBairroCtrl.text = json['bairro'] ?? '';
            _enderecoCidadeCtrl.text = json['localidade'] ?? '';
            _enderecoEstadoCtrl.text = json['uf'] ?? '';
            _onFieldChanged();
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _syncStatus = SyncStatus.processing;
      _syncMessage = 'Salvando alterações...';
    });

    try {
      if (_selectedSection == 7 || _personalizacaoKey.currentState != null) {
        await _personalizacaoKey.currentState?.salvar();
      }

      final impConfig = FincoreImpressaoConfig(
        nomeEmpresa: _nomeEmpresaCupomCtrl.text.trim().isEmpty ? (_empresa?.nomeFantasia ?? '') : _nomeEmpresaCupomCtrl.text.trim(),
        telefone: _telefoneEmpresaCtrl.text.trim(),
        larguraMm: _larguraBobina == '58mm' ? 58 : 80,
        habilitarQrCodePix: _exibirQrCode,
        habilitarCopiaCola: _exibirCopiaCola,
        pixChave: _pixKeys.isNotEmpty ? _pixKeys.first.chave : '',
        pixTipo: _pixKeys.isNotEmpty ? _pixKeys.first.tipo : 'CPF',
        pixFavorecido: _pixKeys.isNotEmpty ? _pixKeys.first.favorecido : '',
        pixBanco: _pixKeys.isNotEmpty ? _pixKeys.first.banco : '',
        rodape: _mensagemRodapeCtrl.text,
      );
      await impConfig.salvar();

      final tenantCtx = DependencyInjection().get<TenantContext>();
      final targetTenantId = _empresa?.id ?? (tenantCtx.hasContext ? tenantCtx.empresa.id : '00000000-0000-4000-a000-000000000001');

      // Fallback seguro se _config estiver nulo
      final baseConfig = _config ?? CoreEmpresaConfiguracao(
        id: targetTenantId,
        tenantId: targetTenantId,
        taxaServico: 0.10,
        usarWhatsApp: true,
        tema: 'dark',
        metadata: SyncMetadata(
          version: 1,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          createdBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          syncStatus: SyncStatus.pending,
        ),
      );

      final taxa = double.tryParse(_taxaServicoCtrl.text.replaceAll(',', '.'));
      final updated = CoreEmpresaConfiguracao(
        id: baseConfig.id,
        tenantId: baseConfig.tenantId,
        taxaServico: taxa != null ? taxa / 100.0 : baseConfig.taxaServico,
        usarWhatsApp: _usarWhatsApp,
        mercadoPagoAtivo: _usarMercadoPago,
        openPixAtivo: _usarOpenPix,
        asaasAtivo: _usarAsaas,
        ifoodAtivo: _usariFood,
        tema: _selectedTema,
        pixKey: _pixKeys.isEmpty ? null : jsonEncode(_pixKeys.map((x) => x.toJson()).toList()),
        printerConfig: _printers.isEmpty ? null : jsonEncode(_printers.map((x) => x.toJson()).toList()),
        printerCaixa: _printers.firstWhere((x) => x.departamento == 'Caixa', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 0, status: false)).ip.isEmpty ? null : _printers.firstWhere((x) => x.departamento == 'Caixa').ip,
        printerCozinha: _printers.firstWhere((x) => x.departamento == 'Cozinha', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 0, status: false)).ip.isEmpty ? null : _printers.firstWhere((x) => x.departamento == 'Cozinha').ip,
        printerBalcao: _printers.firstWhere((x) => x.departamento == 'Balcao', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 0, status: false)).ip.isEmpty ? null : _printers.firstWhere((x) => x.departamento == 'Balcao').ip,
        printerExpedicao: _printers.firstWhere((x) => x.departamento == 'Expedicao', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 0, status: false)).ip.isEmpty ? null : _printers.firstWhere((x) => x.departamento == 'Expedicao').ip,
        autoPrintCaixa: _printers.any((x) => x.departamento == 'Caixa' && x.autoImpressao),
        autoPrintCozinha: _printers.any((x) => x.departamento == 'Cozinha' && x.autoImpressao),
        autoPrintBalcao: _printers.any((x) => x.departamento == 'Balcao' && x.autoImpressao),
        autoPrintExpedicao: _printers.any((x) => x.departamento == 'Expedicao' && x.autoImpressao),
        viasCliente: _printers.firstWhere((x) => x.departamento == 'Caixa', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 1, status: false)).vias,
        viasCozinha: _printers.firstWhere((x) => x.departamento == 'Cozinha', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 1, status: false)).vias,
        viasBalcao: _printers.firstWhere((x) => x.departamento == 'Balcao', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 1, status: false)).vias,
        viasExpedicao: _printers.firstWhere((x) => x.departamento == 'Expedicao', orElse: () => PrinterModel(id: '', nome: '', tipo: '', departamento: '', ip: '', driver: '', autoImpressao: false, vias: 1, status: false)).vias,
        larguraPapel: _larguraBobina == '58mm' ? 58 : 80,
        cortarPapel: _cortarPapel,
        abrirGaveta: _abrirGaveta,
        imprimirQRCode: _exibirQrCode,
        imprimirCopiaCola: _exibirCopiaCola,
        mensagemRodape: _mensagemRodapeCtrl.text,
        pixFavorecido: _pixKeys.isNotEmpty ? _pixKeys.first.favorecido : null,
        pixBanco: _pixKeys.isNotEmpty ? _pixKeys.first.banco : null,
        pixTipo: _pixKeys.isNotEmpty ? _pixKeys.first.tipo : 'CPF',
        modoDeliveryAtivo: _modoDeliveryAtivo,
        modoComandasAtivo: _modoComandasAtivo,
        clienteObrigatorioVenda: _clienteObrigatorioVenda,
        atendimentoPadrao: _atendimentoPadrao,
        margemSegurancaMinutos: int.tryParse(_margemSegurancaCtrl.text) ?? 10,
        taxaEntregaPorKm: _taxaEntregaPorKm,
        valorPorKmCentavos: ((double.tryParse(_valorPorKmCtrl.text.replaceAll(',', '.')) ?? 0.0) * 100).round(),
        metadata: baseConfig.metadata.copyWith(
          updatedAt: DateTime.now().toUtc(),
          updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          syncStatus: SyncStatus.pending,
        ),
      );
      await _repo.save(updated);

      if (_empresa != null) {
        final updatedEmpresa = CoreEmpresa(
          id: _empresa!.id,
          razaoSocial: _tipoPessoa == 'FISICA' ? _nomeEmpresaCupomCtrl.text.trim() : _razaoSocialCtrl.text.trim(),
          nomeFantasia: _nomeEmpresaCupomCtrl.text.trim().isEmpty ? _empresa!.nomeFantasia : _nomeEmpresaCupomCtrl.text.trim(),
          documentoFiscal: _cnpjEmpresaCtrl.text.trim().isEmpty ? _empresa!.documentoFiscal : _cnpjEmpresaCtrl.text.trim(),
          email: _emailEmpresaCtrl.text.trim().isEmpty ? _empresa!.email : _emailEmpresaCtrl.text.trim(),
          telefone: _telefoneEmpresaCtrl.text.trim().isEmpty ? _empresa!.telefone : _telefoneEmpresaCtrl.text.trim(),
          status: _empresa!.status,
          plano: _empresa!.plano,
          timezone: _selectedTimezone,
          locale: _selectedLocale,
          currency: _selectedCurrency,
          country: _empresa!.country,
          createdFrom: _empresa!.createdFrom,
          version: _empresa!.version,
          tipoPessoa: _tipoPessoa,
          inscricaoEstadual: _inscricaoEstadualCtrl.text.trim().isEmpty ? null : _inscricaoEstadualCtrl.text.trim(),
          inscricaoMunicipal: _inscricaoMunicipalCtrl.text.trim().isEmpty ? null : _inscricaoMunicipalCtrl.text.trim(),
          regimeTributario: _regimeTributarioCtrl.text.trim().isEmpty ? null : _regimeTributarioCtrl.text.trim(),
          // Endereço estruturado — salva cada campo diretamente, sem serialização
          cep: _cepCtrl.text.trim().isEmpty ? null : _cepCtrl.text.trim(),
          logradouro: _enderecoRuaCtrl.text.trim().isEmpty ? null : _enderecoRuaCtrl.text.trim(),
          numero: _enderecoNumeroCtrl.text.trim().isEmpty ? null : _enderecoNumeroCtrl.text.trim(),
          bairro: _enderecoBairroCtrl.text.trim().isEmpty ? null : _enderecoBairroCtrl.text.trim(),
          complemento: _enderecoComplementoCtrl.text.trim().isEmpty ? null : _enderecoComplementoCtrl.text.trim(),
          cidade: _enderecoCidadeCtrl.text.trim().isEmpty ? null : _enderecoCidadeCtrl.text.trim(),
          estado: _enderecoEstadoCtrl.text.trim().isEmpty ? null : _enderecoEstadoCtrl.text.trim(),
          metadata: _empresa!.metadata.copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
            syncStatus: SyncStatus.pending,
          ),
        );
        await _empresaRepo.save(updatedEmpresa);
        if (tenantCtx.hasContext) {
          tenantCtx.setContext(empresa: updatedEmpresa, usuario: tenantCtx.usuario);
        }
        _empresa = updatedEmpresa;
      }

      setState(() {
        _config = updated;
        _isSaving = false;
        _hasUnsavedChanges = false;
        _syncStatus = SyncStatus.synced;
        _syncMessage = 'Sincronizado agora';
      });
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      setState(() {
        _isSaving = false;
        _syncStatus = SyncStatus.failed;
        _syncMessage = 'Erro ao salvar';
      });
    }
  }

  String _syncStatusMessage(SyncStatus status, DateTime? lastSyncedAt) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.resolved:
        return 'Sincronizado agora';
      case SyncStatus.pending:
        return 'Pendente de sincronização';
      case SyncStatus.processing:
        return 'Sincronizando...';
      case SyncStatus.failed:
        return 'Falha na sincronização';
      default:
        return 'Sincronizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    final (breadcrumb, title, desc) = _getHeaderInfo(_selectedSection);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog(context);
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Sub-Abas Superiores no TOPO Absoluto (Idêntico a ProdutosPage) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTab('Dados Gerais', Icons.business_outlined, 0),
                const SizedBox(width: 12),
                _buildSubTab('Fiscal', Icons.gavel_outlined, 1),
                const SizedBox(width: 12),
                _buildSubTab('Operação', Icons.settings_outlined, 2),
                const SizedBox(width: 12),
                _buildSubTab('Chaves PIX', Icons.pix_outlined, 3),
                const SizedBox(width: 12),
                _buildSubTab('Impressoras', Icons.print_outlined, 4),
                const SizedBox(width: 12),
                _buildSubTab('Segurança', Icons.security_outlined, 5),
                const SizedBox(width: 12),
                _buildSubTab('Auditoria', Icons.history_outlined, 6),
                const SizedBox(width: 12),
                _buildSubTab('Aparência & Marca', Icons.palette_outlined, 7),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 2. Linha de Ações e Descrição do Subdomínio ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                desc,
                style: const TextStyle(fontSize: 12.5, color: FincoreColors.textMuted),
              ),
              Row(
                children: [
                  if (kDebugMode)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: FincoreColors.textMuted, size: 20),
                      tooltip: 'Opções de Desenvolvedor',
                      onSelected: (val) {
                        if (val == 'auditoria' && _config != null) {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: AuditTimelinePanel(entityName: 'empresa_configuracao', entityId: _config!.id),
                            ),
                          );
                        } else if (val == 'logs') {
                          showDialog(
                            context: context,
                            builder: (ctx) => const Dialog(backgroundColor: Colors.transparent, child: LogExplorerDialog()),
                          );
                        } else if (val == 'db') {
                          final db = DependencyInjection().get<FincoreDatabase>();
                          Navigator.of(context).push(MaterialPageRoute(builder: (c) => DriftDbViewer(db)));
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'auditoria', child: Row(children: [Icon(Icons.history, size: 18), SizedBox(width: 8), Text('Auditoria')])),
                        PopupMenuItem(value: 'logs', child: Row(children: [Icon(Icons.analytics_outlined, size: 18), SizedBox(width: 8), Text('Central de Logs')])),
                        PopupMenuItem(value: 'db', child: Row(children: [Icon(Icons.storage, size: 18), SizedBox(width: 8), Text('Ver DB Local')])),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 3. Conteúdo do Formulário ──────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              padding: const EdgeInsets.all(20),
              child: _buildSectionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(String label, IconData icon, int index) {
    final isSelected = _selectedSection == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSection = index),
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

  Widget _buildHeader() {
    final (breadcrumb, title, desc) = _getHeaderInfo(_selectedSection);
    return FincorePageHeader(
      breadcrumb: breadcrumb,
      title: title,
      description: desc,
      syncStatus: _syncStatus,
      syncMessage: _syncMessage,
      primaryAction: null,
      extraActions: [
        if (kDebugMode)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: FincoreColors.textMuted),
            tooltip: 'Opções de Desenvolvedor',
            onSelected: (val) {
              if (val == 'auditoria' && _config != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: AuditTimelinePanel(entityName: 'empresa_configuracao', entityId: _config!.id),
                  ),
                );
              } else if (val == 'logs') {
                showDialog(
                  context: context,
                  builder: (ctx) => const Dialog(backgroundColor: Colors.transparent, child: LogExplorerDialog()),
                );
              } else if (val == 'db') {
                final db = DependencyInjection().get<FincoreDatabase>();
                Navigator.of(context).push(MaterialPageRoute(builder: (c) => DriftDbViewer(db)));
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'auditoria', child: Row(children: [Icon(Icons.history, size: 18), SizedBox(width: 8), Text('Auditoria')])),
              PopupMenuItem(value: 'logs', child: Row(children: [Icon(Icons.analytics_outlined, size: 18), SizedBox(width: 8), Text('Central de Logs')])),
              PopupMenuItem(value: 'db', child: Row(children: [Icon(Icons.storage, size: 18), SizedBox(width: 8), Text('Ver DB Local')])),
            ],
          ),
      ],
    );
  }

  (List<String>, String, String) _getHeaderInfo(int sectionIndex) {
    switch (sectionIndex) {
      case 0:
        return (['Empresa', 'Dados Gerais'], 'Dados Gerais', 'Dados cadastrais e informações institucionais.');
      case 1:
        return (['Empresa', 'Fiscal'], 'Fiscal', 'Regime tributário, inscrições estaduais e municipais.');
      case 2:
        return (['Empresa', 'Operação'], 'Operação', 'Parâmetros regionais, fuso horário e moeda.');
      case 3:
        return (['Pagamentos', 'Chaves PIX'], 'Chaves PIX', 'Cadastro de recebedores e chaves PIX.');
      case 4:
        return (['Infraestrutura', 'Impressoras'], 'Impressoras', 'Configuração dinâmica de impressoras e parâmetros de bobina.');
      case 5:
        return (['Infraestrutura', 'Segurança'], 'Segurança', 'Controle de sessões ativas e autenticação.');
      case 6:
        return (['Infraestrutura', 'Auditoria'], 'Auditoria', 'Rastreabilidade de eventos e logs do sistema.');
      case 7:
        return (['Personalização', 'Aparência'], 'Aparência & White-Label', 'Personalização de tema (Claro/Escuro), cor primária da marca, densidade, bordas e marca da empresa.');
      default:
        return (['Configurações'], 'Configurações', 'Configurações do sistema.');
    }
  }

  Widget _buildSideNav() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader('EMPRESA'),
            _buildSideNavItem(
              icon: Icons.business_outlined,
              label: 'Dados Gerais',
              isSelected: _selectedSection == 0,
              onTap: () => setState(() => _selectedSection = 0),
            ),
            _buildSideNavItem(
              icon: Icons.gavel_outlined,
              label: 'Fiscal',
              isSelected: _selectedSection == 1,
              onTap: () => setState(() => _selectedSection = 1),
            ),
            _buildSideNavItem(
              icon: Icons.settings_outlined,
              label: 'Operação',
              isSelected: _selectedSection == 2,
              onTap: () => setState(() => _selectedSection = 2),
            ),
            const SizedBox(height: 16),
            _buildGroupHeader('PAGAMENTOS'),
            _buildSideNavItem(
              icon: Icons.pix_outlined,
              label: 'Chaves PIX',
              isSelected: _selectedSection == 3,
              onTap: () => setState(() => _selectedSection = 3),
            ),
            const SizedBox(height: 16),
            _buildGroupHeader('INFRAESTRUTURA'),
            _buildSideNavItem(
              icon: Icons.print_outlined,
              label: 'Impressoras',
              isSelected: _selectedSection == 4,
              onTap: () => setState(() => _selectedSection = 4),
            ),
            _buildSideNavItem(
              icon: Icons.security_outlined,
              label: 'Segurança',
              isSelected: _selectedSection == 5,
              onTap: () => setState(() => _selectedSection = 5),
            ),
            _buildSideNavItem(
              icon: Icons.history_outlined,
              label: 'Auditoria',
              isSelected: _selectedSection == 6,
              onTap: () => setState(() => _selectedSection = 6),
            ),
            const SizedBox(height: 16),
            _buildGroupHeader('PERSONALIZAÇÃO'),
            _buildSideNavItem(
              icon: Icons.palette_outlined,
              label: 'Aparência & Marca',
              isSelected: _selectedSection == 7,
              onTap: () => setState(() => _selectedSection = 7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: FincoreColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? FincoreColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _sectionWidget(_selectedSection),
          ),
        ),
        const SizedBox(height: 16),
        // Barra inferior de ações
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Botão Descartar
            OutlinedButton(
              onPressed: _hasUnsavedChanges ? () => _loadConfig() : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                side: BorderSide(
                  color: _hasUnsavedChanges ? FincoreColors.textMuted : FincoreColors.border,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Descartar',
                style: TextStyle(
                  color: _hasUnsavedChanges ? FincoreColors.textPrimary : FincoreColors.textDisabled,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botão Salvar Alterações (gradiente laranja)
            Container(
              decoration: BoxDecoration(
                gradient: (_hasUnsavedChanges && !_isSaving)
                    ? FincoreColors.primaryGradient
                    : null,
                color: (_hasUnsavedChanges && !_isSaving)
                    ? null
                    : FincoreColors.border,
                borderRadius: BorderRadius.circular(10),
                boxShadow: (_hasUnsavedChanges && !_isSaving)
                    ? FincoreShadows.glow(FincoreColors.primary, intensity: 0.25)
                    : null,
              ),
              child: ElevatedButton(
                onPressed: (_hasUnsavedChanges && !_isSaving) ? _saveConfig : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isSaving ? 'Salvando...' : 'Salvar',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionWidget(int index) {
    switch (index) {
      case 0: return _buildSectionEmpresa();
      case 1: return _buildSectionFiscal();
      case 2: return _buildSectionOperacao();
      case 3: return _buildSectionPix();
      case 4: return _buildSectionImpressao();
      case 5: return _buildSectionSeguranca();
      case 6: return _buildSectionAuditoria();
      case 7:
        return PersonalizacaoView(
          key: _personalizacaoKey,
          onChanged: () {
            if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
          },
        );
      default: return const SizedBox();
    }
  }

  // ─── DOMÍNIO 1: EMPRESA (Institucional) ────────────────────────────────────
  Widget _buildSectionEmpresa() {
    final docLabel = _tipoPessoa == 'FISICA' ? 'CPF' : 'CNPJ';
    final docHint = _tipoPessoa == 'FISICA' ? '123.456.789-00' : '12.345.678/0001-90';
    final docFormatter = _tipoPessoa == 'FISICA'
        ? [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()]
        : [FilteringTextInputFormatter.digitsOnly, CnpjInputFormatter()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── CARD 1: IDENTIFICAÇÃO ───────────────────────────────────────────
        FincoreSectionCard(
          title: 'Identificação',
          subtitle: 'Dados de razão social e registro comercial',
          icon: Icons.badge_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_tipoPessoa == 'JURIDICA') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'Razão Social', isRequired: true),
                          FincoreTextField(
                            controller: _razaoSocialCtrl,
                            hintText: 'Ex: FINCORE FOOD LTDA',
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'Nome Fantasia', isRequired: true),
                          FincoreTextField(
                            controller: _nomeEmpresaCupomCtrl,
                            hintText: 'Ex: FINCORE FOOD',
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(32),
                            ],
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'Nome Completo', isRequired: true),
                    FincoreTextField(
                      controller: _nomeEmpresaCupomCtrl,
                      hintText: 'Ex: João da Silva',
                      onChanged: (_) => _onFieldChanged(),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Tipo de Empresa (Pessoa)'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'JURIDICA',
                              groupValue: _tipoPessoa,
                              activeColor: FincoreColors.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _tipoPessoa = val;
                                    _cnpjEmpresaCtrl.clear();
                                  });
                                  _onFieldChanged();
                                }
                              },
                            ),
                            const Text('Pessoa Jurídica (PJ)', style: TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
                            const SizedBox(width: 16),
                            Radio<String>(
                              value: 'FISICA',
                              groupValue: _tipoPessoa,
                              activeColor: FincoreColors.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _tipoPessoa = val;
                                    _cnpjEmpresaCtrl.clear();
                                  });
                                  _onFieldChanged();
                                }
                              },
                            ),
                            const Text('Pessoa Física (PF)', style: TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FincoreFieldLabel(label: docLabel, isRequired: true),
                        FincoreTextField(
                          controller: _cnpjEmpresaCtrl,
                          hintText: docHint,
                          inputFormatters: docFormatter,
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'E-mail de Contato'),
                        FincoreTextField(
                          controller: _emailEmpresaCtrl,
                          hintText: 'Ex: financeiro@empresa.com',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Telefone Principal'),
                        FincoreTextField(
                          controller: _telefoneEmpresaCtrl,
                          hintText: 'Ex: (11) 98888-7777',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TelefoneInputFormatter(),
                          ],
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── CARD 3: ENDEREÇO FISCAL / COMERCIAL ─────────────────────────────
        FincoreSectionCard(
          title: 'Endereço Comercial / Fiscal',
          subtitle: 'Endereço principal da empresa para vinculação tributária e cupom',
          icon: Icons.location_on_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'CEP', isRequired: true),
                        FincoreTextField(
                          controller: _cepCtrl,
                          hintText: '00000-000',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CepInputFormatter(),
                          ],
                          onChanged: (val) {
                            _onFieldChanged();
                            if (val.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                              _buscarCep(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Nome de Endereço (Rua / Logradouro)'),
                        FincoreTextField(
                          controller: _enderecoRuaCtrl,
                          hintText: 'Nome de Endereço',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Número'),
                        FincoreTextField(
                          controller: _enderecoNumeroCtrl,
                          hintText: '16',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Bairro'),
                        FincoreTextField(
                          controller: _enderecoBairroCtrl,
                          hintText: 'Nome do bairro',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FincoreFieldLabel(label: 'Complemento'),
                  FincoreTextField(
                    controller: _enderecoComplementoCtrl,
                    hintText: 'Apto, Sala, Bloco (opcional)',
                    onChanged: (_) => _onFieldChanged(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Cidade'),
                        FincoreTextField(
                          controller: _enderecoCidadeCtrl,
                          hintText: 'Cidade',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Estado'),
                        FincoreTextField(
                          controller: _enderecoEstadoCtrl,
                          hintText: 'SP',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── DOMÍNIO 1.1: FISCAL (Tributário & Reforma Tributária) ─────────────────
  Widget _buildSectionFiscal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── CARD 1: REGIME TRIBUTÁRIO & INSCRIÇÕES ──────────────────────────
        FincoreSectionCard(
          title: 'Regime Tributário & Registros',
          subtitle: 'Enquadramento tributário nacional, CRT e inscrições estaduais/municipais',
          icon: Icons.gavel_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'CRT (Código de Regime Tributário)'),
                        _buildSimpleDropdown(
                          value: _selectedCrt,
                          items: const ['1', '2', '3', '4'],
                          labels: const ['1 - Simples Nacional', '2 - Simples Nacional (Excesso de Sublimite)', '3 - Regime Normal', '4 - MEI'],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedCrt = v);
                              _onFieldChanged();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Regime Tributário'),
                        _buildSimpleDropdown(
                          value: _regimeTributarioCtrl.text.isEmpty ? 'Simples Nacional' : _regimeTributarioCtrl.text,
                          items: const ['Simples Nacional', 'Lucro Presumido', 'Lucro Real', 'MEI'],
                          labels: const ['Simples Nacional', 'Lucro Presumido', 'Lucro Real', 'MEI'],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _regimeTributarioCtrl.text = v);
                              _onFieldChanged();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Inscrição Estadual (IE)'),
                        FincoreTextField(
                          controller: _inscricaoEstadualCtrl,
                          hintText: 'Ex: 123.456.789.110',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Inscrição Municipal (IM)'),
                        FincoreTextField(
                          controller: _inscricaoMunicipalCtrl,
                          hintText: 'Ex: 98765432-1',
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── CARD 2: AMBIENTE FISCAL & EMISSÃO ────────────────────────────────
        FincoreSectionCard(
          title: 'Ambiente Fiscal & Emissão de Documentos',
          subtitle: 'Ambiente de autorização SEFAZ e emissão de notas/cupons eletrônicos',
          icon: Icons.verified_user_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Módulo de Emissão Fiscal (SEFAZ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                  Row(
                    children: [
                      Switch(
                        value: _emissaoFiscalAtiva,
                        activeColor: FincoreColors.primary,
                        onChanged: (v) {
                          setState(() => _emissaoFiscalAtiva = v);
                          _onFieldChanged();
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _emissaoFiscalAtiva ? 'ATIVO' : 'DESATIVADO',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _emissaoFiscalAtiva ? FincoreColors.success : FincoreColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Ambiente Fiscal SEFAZ'),
                        _buildSimpleDropdown(
                          value: _selectedAmbienteFiscal,
                          items: const ['1', '2'],
                          labels: const ['Produção (Validade Jurídica)', 'Homologação (Testes sem valor)'],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedAmbienteFiscal = v);
                              _onFieldChanged();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'Modelo Principal de Emissão'),
                        _buildSimpleDropdown(
                          value: _selectedModeloFiscal,
                          items: const ['NFCe', 'NFe', 'SAT', 'MFE'],
                          labels: const ['NFC-e (Nota Consumidor Eletrônica)', 'NF-e (Nota Fiscal Eletrônica)', 'SAT-CF-e (SP)', 'MFE (Ceará)'],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedModeloFiscal = v);
                              _onFieldChanged();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── CARD 3: PREPARAÇÃO PARA REFORMA TRIBUTÁRIA (CBS & IBS) ───────────
        FincoreSectionCard(
          title: 'Reforma Tributária (Transição 2026+)',
          subtitle: 'Parâmetros para cálculo unificado de CBS (Federal) e IBS (Estadual/Municipal)',
          icon: Icons.account_balance_outlined,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: FincoreColors.primary, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sistema preparado para a dupla alíquota CBS/IBS da Reforma Tributária. Os campos de apuração automatizada e split de imposto no checkout serão ativados conforme o cronograma nacional.',
                    style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── DOMÍNIO 1.2: OPERAÇÃO ────────────────────────────────────────────────
  Widget _buildSectionOperacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── CARD 1: REGIONAL & INTERFACE ────────────────────────────────────
        FincoreSectionCard(
          title: 'Dados Regionais & Tema',
          subtitle: 'Fuso horário, idioma de operação, moeda corrente e tema do sistema',
          icon: Icons.language_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'FUSO HORÁRIO'),
                        _buildSimpleDropdown(
                          value: _selectedTimezone,
                          items: const ['America/Sao_Paulo', 'America/Fortaleza', 'America/Manaus', 'America/Cuiaba'],
                          labels: const ['Brasília (UTC-3)', 'Fortaleza (UTC-3)', 'Manaus (UTC-4)', 'Cuiabá (UTC-4)'],
                          onChanged: (v) { setState(() => _selectedTimezone = v!); _onFieldChanged(); },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'IDIOMA DE OPERAÇÃO'),
                        _buildSimpleDropdown(
                          value: _selectedLocale,
                          items: const ['pt_BR', 'en_US', 'es_ES'],
                          labels: const ['Português (Brasil)', 'English (US)', 'Español'],
                          onChanged: (v) { setState(() => _selectedLocale = v!); _onFieldChanged(); },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'MOEDA CORRENTE'),
                        _buildSimpleDropdown(
                          value: _selectedCurrency,
                          items: const ['BRL', 'USD', 'EUR'],
                          labels: const ['Real Brasileiro (R\$)', 'Dólar (US\$)', 'Euro (€)'],
                          onChanged: (v) { setState(() => _selectedCurrency = v!); _onFieldChanged(); },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── CARD 2: REGRAS DE ATENDIMENTO ───────────────────────────────────
        FincoreSectionCard(
          title: 'Regras de Atendimento & Produção',
          subtitle: 'Configurações de taxa de serviço do salão, tempo médio e arredondamento',
          icon: Icons.settings_outlined,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'TAXA DE SERVIÇO GERAL (%)'),
                    FincoreTextField(
                      controller: _taxaServicoCtrl,
                      hintText: 'Ex: 10.0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _onFieldChanged(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'TEMPO PADRÃO DE PREPARO (MIN)'),
                    FincoreTextField(
                      hintText: 'Ex: 20 min',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _onFieldChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── CARD: PARAMETRIZAÇÃO DO PDV E VENDAS ────────────────────────────
        FincoreSectionCard(
          title: 'Parametrização do PDV & Vendas',
          subtitle: 'Canais de atendimento ativos, exigência de cliente e padrão operacional',
          icon: Icons.point_of_sale_outlined,
          child: Column(
            children: [
              _buildConnectorRow(
                'Habilitar Modo Delivery no PDV',
                'Permite alternar para entregas a domicílio com taxa de frete no momento da venda',
                Icons.local_shipping_outlined,
                _modoDeliveryAtivo,
                (v) {
                  setState(() => _modoDeliveryAtivo = v);
                  _onFieldChanged();
                },
              ),
              const SizedBox(height: 12),
              _buildConnectorRow(
                'Habilitar Mesas e Comandas Presenciais',
                'Ativa telas e opções de atendimento em mesas/comandas. Mantenha desativado caso opere com foco exclusivo em Delivery / Retirada.',
                Icons.table_restaurant_outlined,
                _modoComandasAtivo,
                (v) {
                  setState(() => _modoComandasAtivo = v);
                  _onFieldChanged();
                },
              ),
              const SizedBox(height: 12),
              _buildConnectorRow(
                'Exigir Identificação de Cliente na Venda',
                'Exige o preenchimento de nome/telefone do cliente antes de avançar para pagamento',
                Icons.person_pin_outlined,
                _clienteObrigatorioVenda,
                (v) {
                  setState(() => _clienteObrigatorioVenda = v);
                  _onFieldChanged();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'CANAL DE ATENDIMENTO PADRÃO INICIAL'),
                        _buildSimpleDropdown(
                          value: _atendimentoPadrao,
                          items: const ['Mesa/Balcão', 'Delivery'],
                          labels: const ['🟢 Mesa / Balcão (Venda Direta Expressa)', '🛵 Delivery (Entrega a Domicílio)'],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _atendimentoPadrao = v);
                              _onFieldChanged();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FincoreFieldLabel(label: 'MARGEM DE SEGURANÇA OPERACIONAL (MINUTOS)'),
                        FincoreTextField(
                          controller: _margemSegurancaCtrl,
                          hintText: 'Ex: 10',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) => _onFieldChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConnectorRow(
                'Calcular Taxa de Entrega por KM',
                'Calcula automaticamente a taxa de entrega baseando-se na distância em quilômetros obtida via rota.',
                Icons.map_outlined,
                _taxaEntregaPorKm,
                (v) {
                  setState(() {
                    _taxaEntregaPorKm = v;
                  });
                  _onFieldChanged();
                },
              ),
              if (_taxaEntregaPorKm) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'VALOR COBRADO POR KM (R\$)'),
                          FincoreTextField(
                            controller: _valorPorKmCtrl,
                            hintText: 'Ex: 2,50',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => _onFieldChanged(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── CARD 3: CONECTORES DE INTEGRAÇÃO (Modulares) ────────────────────
        FincoreSectionCard(
          title: 'Conectores & Integrações Externas',
          subtitle: 'Integrações modulares e independentes para mensageria, pagamento e delivery',
          icon: Icons.hub_outlined,
          child: Column(
            children: [
              _buildConnectorRow('WhatsApp Mensageria', 'Notificações de status de pedidos em tempo real via API oficial', Icons.message, _usarWhatsApp, (v) {
                setState(() => _usarWhatsApp = v);
                _onFieldChanged();
              }),
              const SizedBox(height: 10),
              _buildConnectorRow('Mercado Pago Checkout', 'Processamento de cartões de crédito/débito e Pix automático', Icons.payment, _usarMercadoPago, (v) {
                setState(() => _usarMercadoPago = v);
                _onFieldChanged();
              }),
              const SizedBox(height: 10),
              _buildConnectorRow('OpenPix Direct', 'Conciliação em tempo real de recebimentos Pix sem intermediários', Icons.pix, _usarOpenPix, (v) {
                setState(() => _usarOpenPix = v);
                _onFieldChanged();
              }),
              const SizedBox(height: 10),
              _buildConnectorRow('Asaas Gateway', 'Geração de boletos e cobranças recorrentes para mensalidades', Icons.account_balance, _usarAsaas, (v) {
                setState(() => _usarAsaas = v);
                _onFieldChanged();
              }),
              const SizedBox(height: 10),
              _buildConnectorRow('iFood Delivery Connector', 'Recebimento e injeção automática de pedidos do marketplace iFood no KDS', Icons.delivery_dining, _usariFood, (v) {
                setState(() => _usariFood = v);
                _onFieldChanged();
              }),
              ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorRow(String title, String desc, IconData icon, bool status, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: FincoreColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: status,
            activeColor: FincoreColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPix() {
    return FincoreSectionCard(
      title: 'Chaves PIX Recebedores',
      subtitle: 'Gerencie as chaves PIX para recebimentos automáticos nas vendas do PDV e Delivery',
      icon: Icons.pix_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pixKeys.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: const Center(
                child: Text(
                  'Nenhuma chave PIX cadastrada. Adicione uma para receber no PDV.',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pixKeys.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final key = _pixKeys[index];
                return Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pix_outlined, size: 16, color: Color(0xFFF97316)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key.favorecido,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${key.tipo}: ${key.chave} • ${key.banco}",
                              style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: FincoreColors.textSecondary),
                        onPressed: () => _mostrarModalPix(key),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: FincoreColors.danger),
                        onPressed: () => setState(() {
                          _pixKeys.removeAt(index);
                          _onFieldChanged();
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarModalPix(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.15),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 16, color: Color(0xFFF97316)),
            label: const Text('Adicionar Chave PIX', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const Divider(height: 32, color: FincoreColors.border),
          const Text('CONFIGURAÇÕES DE CONCILIAÇÃO & TELA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _checkOption('Habilitar QR Code automático no PDV', _exibirQrCode, (v) => setState(() { _exibirQrCode = v!; _onFieldChanged(); })),
              _checkOption('Habilitar botão Copia e Cola', _exibirCopiaCola, (v) => setState(() { _exibirCopiaCola = v!; _onFieldChanged(); })),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarModalPix([PixKeyModel? pixKey]) {
    final chaveCtrl = TextEditingController(text: pixKey?.chave ?? '');
    final favCtrl = TextEditingController(text: pixKey?.favorecido ?? '');
    final bancoCtrl = TextEditingController(text: pixKey?.banco ?? '');
    String tipo = pixKey?.tipo ?? 'CPF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: FincoreColors.surface,
            title: Text(pixKey == null ? 'Nova Chave PIX' : 'Editar Chave PIX', style: const TextStyle(color: FincoreColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FincoreFieldLabel(label: 'TIPO DA CHAVE'),
                            _buildSimpleDropdown(
                              value: tipo,
                              items: const ['CPF', 'CNPJ', 'Telefone', 'E-mail', 'Aleatória'],
                              labels: const ['CPF', 'CNPJ', 'Telefone', 'E-mail', 'Chave Aleatória'],
                              onChanged: (v) => setModalState(() => tipo = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const FincoreFieldLabel(label: 'CHAVE PIX', isRequired: true),
                  FincoreTextField(
                    controller: chaveCtrl,
                    hintText: 'Digite a chave PIX',
                  ),
                  const SizedBox(height: 12),
                  const FincoreFieldLabel(label: 'NOME DO FAVORECIDO', isRequired: true),
                  FincoreTextField(
                    controller: favCtrl,
                    hintText: 'Ex: Fincore Alimentos LTDA',
                  ),
                  const SizedBox(height: 12),
                  const FincoreFieldLabel(label: 'BANCO / INSTITUIÇÃO'),
                  FincoreTextField(
                    controller: bancoCtrl,
                    hintText: 'Ex: Itaú',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (chaveCtrl.text.trim().isEmpty || favCtrl.text.trim().isEmpty) return;
                  setState(() {
                    if (pixKey == null) {
                      _pixKeys.add(PixKeyModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        favorecido: favCtrl.text.trim(),
                        banco: bancoCtrl.text.trim(),
                        tipo: tipo,
                        chave: chaveCtrl.text.trim(),
                      ));
                    } else {
                      final idx = _pixKeys.indexWhere((x) => x.id == pixKey.id);
                      if (idx != -1) {
                        _pixKeys[idx] = PixKeyModel(
                          id: pixKey.id,
                          favorecido: favCtrl.text.trim(),
                          banco: bancoCtrl.text.trim(),
                          tipo: tipo,
                          chave: chaveCtrl.text.trim(),
                        );
                      }
                    }
                    _onFieldChanged();
                  });
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                child: Text(pixKey == null ? 'Adicionar' : 'Salvar', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSectionImpressao() {
    return FincoreSectionCard(
      title: 'Destinos de Impressão',
      subtitle: 'Configuração dinâmica e cadastro de impressoras por departamento e parâmetros de bobina',
      icon: Icons.print_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_printers.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: const Center(
                child: Text(
                  'Nenhuma impressora cadastrada. Adicione uma para configurar o fluxo físico.',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _printers.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final printer = _printers[index];
                return Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.print_outlined, size: 16, color: FincoreColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printer.nome,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${printer.tipo} • IP/Porta: ${printer.ip} • Departamento: ${printer.departamento} • Vias: ${printer.vias}",
                              style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _testarImpressora(printer),
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text('Testar', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: FincoreColors.border),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Duplicar Impressora',
                        icon: Icon(Icons.copy_outlined, size: 18, color: FincoreColors.primary),
                        onPressed: () => setState(() {
                          _printers.add(PrinterModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            nome: '${printer.nome} (Cópia)',
                            tipo: printer.tipo,
                            departamento: printer.departamento,
                            ip: printer.ip,
                            driver: printer.driver,
                            autoImpressao: printer.autoImpressao,
                            vias: printer.vias,
                            status: printer.status,
                          ));
                          _onFieldChanged();
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: FincoreColors.textSecondary),
                        onPressed: () => _mostrarModalImpressora(printer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: FincoreColors.danger),
                        onPressed: () => setState(() {
                          _printers.removeAt(index);
                          _onFieldChanged();
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarModalImpressora(),
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.primary.withValues(alpha: 0.15),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.add, size: 16, color: FincoreColors.primary),
            label: Text('Adicionar Impressora', style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const Divider(height: 32, color: FincoreColors.border),
          const Text('OPÇÕES GERAIS DO CUPOM TÉRMICO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: FincoreColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              const FincoreFieldLabel(label: 'LARGURA DA BOBINA: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('80mm (Padrão)'),
                selected: _larguraBobina == '80mm',
                onSelected: (val) { if (val) setState(() { _larguraBobina = '80mm'; _onFieldChanged(); }); },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('58mm (Compacto)'),
                selected: _larguraBobina == '58mm',
                onSelected: (val) { if (val) setState(() { _larguraBobina = '58mm'; _onFieldChanged(); }); },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _checkOption('Cortar papel (Guilhotina)', _cortarPapel, (v) => setState(() { _cortarPapel = v!; _onFieldChanged(); })),
              _checkOption('Abrir gaveta de dinheiro', _abrirGaveta, (v) => setState(() { _abrirGaveta = v!; _onFieldChanged(); })),
              _checkOption('Imprimir QR Code PIX', _exibirQrCode, (v) => setState(() { _exibirQrCode = v!; _onFieldChanged(); })),
              _checkOption('Imprimir Copia e Cola PIX', _exibirCopiaCola, (v) => setState(() { _exibirCopiaCola = v!; _onFieldChanged(); })),
            ],
          ),
          const SizedBox(height: 16),
          const FincoreFieldLabel(label: 'MENSAGEM DO RODAPÉ'),
          FincoreTextField(
            controller: _mensagemRodapeCtrl,
            hintText: 'Ex: Obrigado pela preferência! Volte sempre!',
            onChanged: (_) => _onFieldChanged(),
          ),
        ],
      ),
    );
  }

  void _testarImpressora(PrinterModel printer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: Row(
          children: [
            Icon(Icons.print, color: FincoreColors.primary),
            const SizedBox(width: 8),
            Text('Teste: ${printer.nome}', style: const TextStyle(color: FincoreColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enviando sinal de teste para a impressora...', style: TextStyle(color: FincoreColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('--------------------------------', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: FincoreColors.textPrimary)),
                  Text('TESTE DE IMPRESSAO FINCORE FOOD', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary)),
                  Text('Impressora: ${printer.nome}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: FincoreColors.textPrimary)),
                  Text('IP/Porta: ${printer.ip}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: FincoreColors.textPrimary)),
                  Text('Depto: ${printer.departamento}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: FincoreColors.textPrimary)),
                  Text('Data: ${DateTime.now().toString().substring(0, 19)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: FincoreColors.textPrimary)),
                  const Text('--------------------------------', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: FincoreColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarModalImpressora([PrinterModel? printer]) {
    final nomeCtrl = TextEditingController(text: printer?.nome ?? '');
    final ipCtrl = TextEditingController(text: printer?.ip ?? '');
    String tipo = printer?.tipo ?? 'Rede';
    String depto = printer?.departamento ?? 'Cozinha';
    String driver = printer?.driver ?? 'ESC/POS';
    bool autoPrint = printer?.autoImpressao ?? true;
    int vias = printer?.vias ?? 1;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: FincoreColors.surface,
            title: Text(printer == null ? 'Nova Impressora' : 'Editar Impressora', style: const TextStyle(color: FincoreColors.textPrimary)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'NOME DA IMPRESSORA', isRequired: true),
                    FincoreTextField(
                      controller: nomeCtrl,
                      hintText: 'Ex: Térmica Cozinha',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FincoreFieldLabel(label: 'TIPO DE CONEXÃO'),
                              _buildSimpleDropdown(
                                value: tipo,
                                items: const ['Rede', 'USB'],
                                labels: const ['Rede (TCP/IP)', 'USB Local'],
                                onChanged: (v) => setModalState(() => tipo = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FincoreFieldLabel(label: 'DEPARTAMENTO'),
                              _buildSimpleDropdown(
                                value: depto,
                                items: const ['Caixa', 'Cozinha', 'Balcao', 'Expedicao'],
                                labels: const ['Caixa / Balcão', 'Cozinha / Produção', 'Balcão / Atendimento', 'Expedição / Delivery'],
                                onChanged: (v) => setModalState(() => depto = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const FincoreFieldLabel(label: 'ENDEREÇO IP OU PORTA', isRequired: true),
                    FincoreTextField(
                      controller: ipCtrl,
                      hintText: 'Ex: 192.168.1.200 ou COM1',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Endereço IP ou Porta é obrigatória' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FincoreFieldLabel(label: 'DRIVER / EMULAÇÃO'),
                              _buildSimpleDropdown(
                                value: driver,
                                items: const ['ESC/POS', 'Generic'],
                                labels: const ['ESC/POS Epson', 'Generic Text Only'],
                                onChanged: (v) => setModalState(() => driver = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FincoreFieldLabel(label: 'NÚMERO DE VIAS'),
                              _buildSimpleDropdown(
                                value: vias.toString(),
                                items: const ['0', '1', '2', '3', '4'],
                                labels: const ['Não Imprimir (0)', '1 via', '2 vias', '3 vias', '4 vias'],
                                onChanged: (v) => setModalState(() => vias = int.parse(v!)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: autoPrint,
                          activeColor: FincoreColors.primary,
                          onChanged: (v) => setModalState(() => autoPrint = v),
                        ),
                        const SizedBox(width: 8),
                        const Text('Auto Impressão ao finalizar pedido', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  setState(() {
                    if (printer == null) {
                      _printers.add(PrinterModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nome: nomeCtrl.text.trim(),
                        tipo: tipo,
                        departamento: depto,
                        ip: ipCtrl.text.trim(),
                        driver: driver,
                        autoImpressao: autoPrint,
                        vias: vias,
                        status: true,
                      ));
                    } else {
                      final idx = _printers.indexWhere((x) => x.id == printer.id);
                      if (idx != -1) {
                        _printers[idx] = PrinterModel(
                          id: printer.id,
                          nome: nomeCtrl.text.trim(),
                          tipo: tipo,
                          departamento: depto,
                          ip: ipCtrl.text.trim(),
                          driver: driver,
                          autoImpressao: autoPrint,
                          vias: vias,
                          status: printer.status,
                        );
                      }
                    }
                    _onFieldChanged();
                  });
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                child: Text(printer == null ? 'Adicionar' : 'Salvar', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _checkOption(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          activeColor: FincoreColors.primary,
          onChanged: onChanged,
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary)),
      ],
    );
  }

  // ─── DOMÍNIO 5: SEGURANÇA ──────────────────────────────────────────────────
  Widget _buildSectionSeguranca() {
    return FincoreSectionCard(
      title: 'Dispositivos & Sessões Ativas',
      subtitle: 'Controle de sessões ativas, dispositivos vinculados e políticas de autenticação',
      icon: Icons.security_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DISPOSITIVOS AUTORIZADOS DO TENANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.desktop_windows, color: FincoreColors.primary),
            title: const Text('Terminal Local (Caixa Principal)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary)),
            subtitle: const Text('Sessão Ativa • Dispositivo Atual', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
            trailing: const Text('ESTA MÁQUINA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.success)),
          ),
        ],
      ),
    );
  }

  // ─── DOMÍNIO 6: AUDITORIA & AUDIT TRAIL ───────────────────────────────────
  Widget _buildSectionAuditoria() {
    return const FincoreSectionCard(
      title: 'Audit Trail Centralizado & Linha do Tempo',
      subtitle: 'Rastreabilidade completa de mutações por entidade (Produtos, Categorias, Políticas, Usuários), ações CRUD e diffs visuais',
      icon: Icons.history_outlined,
      child: AuditTimelinePanel(
        isGlobalExplorer: true,
      ),
    );
  }

  Widget _buildSimpleDropdown({
    required String value,
    required List<String> items,
    required List<String> labels,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: FincoreColors.surface,
          style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
          items: List.generate(
            items.length,
            (i) => DropdownMenuItem(value: items[i], child: Text(labels[i])),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<bool?> _showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterações não salvas', style: TextStyle(color: FincoreColors.textPrimary)),
        content: const Text('Existem alterações pendentes. Deseja sair e descartar?', style: TextStyle(color: FincoreColors.textSecondary)),
        backgroundColor: FincoreColors.surface,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.danger),
            child: const Text('Sair e Descartar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionItem {
  final IconData icon;
  final String label;
  const _SectionItem({required this.icon, required this.label});
}

class PixKeyModel {
  final String id;
  final String favorecido;
  final String banco;
  final String tipo;
  final String chave;
  PixKeyModel({
    required this.id,
    required this.favorecido,
    required this.banco,
    required this.tipo,
    required this.chave,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'favorecido': favorecido,
    'banco': banco,
    'tipo': tipo,
    'chave': chave,
  };

  factory PixKeyModel.fromJson(Map<String, dynamic> json) => PixKeyModel(
    id: json['id'] ?? '',
    favorecido: json['favorecido'] ?? '',
    banco: json['banco'] ?? '',
    tipo: json['tipo'] ?? 'CPF',
    chave: json['chave'] ?? '',
  );
}

class PrinterModel {
  final String id;
  final String nome;
  final String tipo; // USB, Rede
  final String departamento; // Caixa, Cozinha, Balcao, Expedicao
  final String ip;
  final String driver; // ESC/POS
  final bool autoImpressao;
  final int vias;
  final bool status;

  PrinterModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.departamento,
    required this.ip,
    required this.driver,
    required this.autoImpressao,
    required this.vias,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'tipo': tipo,
    'departamento': departamento,
    'ip': ip,
    'driver': driver,
    'autoImpressao': autoImpressao,
    'vias': vias,
    'status': status,
  };

  factory PrinterModel.fromJson(Map<String, dynamic> json) => PrinterModel(
    id: json['id'] ?? '',
    nome: json['nome'] ?? '',
    tipo: json['tipo'] ?? 'Rede',
    departamento: json['departamento'] ?? 'Cozinha',
    ip: json['ip'] ?? '',
    driver: json['driver'] ?? 'ESC/POS',
    autoImpressao: json['autoImpressao'] ?? true,
    vias: json['vias'] ?? 1,
    status: json['status'] ?? true,
  );
}
