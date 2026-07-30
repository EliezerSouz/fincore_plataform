import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:fincore_food_flutter/src/shared/services/fincore_thermal_printer_service.dart';
import 'package:fincore_food_flutter/src/shared/services/impressao_service.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import 'package:fincore_food_flutter/src/cap/printing/print_capability.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/audit_timeline_panel.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/log_explorer_dialog.dart';

/// Tela de Configurações da Empresa — navegação lateral com 5 seções
/// Auto-save com debounce de 2s + indicador de sync em tempo real
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
  final _taxaServicoCtrl = TextEditingController();
  String _selectedTimezone = 'America/Sao_Paulo';
  String _selectedLocale = 'pt_BR';
  String _selectedCurrency = 'BRL';
  String _selectedTema = 'dark';
  bool _usarWhatsApp = true;
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
    _SectionItem(icon: Icons.language_outlined, label: 'Regional'),
    _SectionItem(icon: Icons.percent_outlined, label: 'Fiscal'),
    _SectionItem(icon: Icons.pix_outlined, label: 'PIX'),
    _SectionItem(icon: Icons.print_outlined, label: 'Impressão'),
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
    _taxaServicoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final configs = await _repo.findAll();
      CoreEmpresaConfiguracao config;
      if (configs.isNotEmpty) {
        config = configs.first;
      } else {
        final tenantCtx = DependencyInjection().get<TenantContext>();
        final tenantId = tenantCtx.hasContext ? tenantCtx.empresa.id : 'unknown';
        config = CoreEmpresaConfiguracao(
          id: tenantId,
          tenantId: tenantId,
          timezone: 'America/Sao_Paulo',
          locale: 'pt_BR',
          currency: 'BRL',
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
      
      final tenantCtx = DependencyInjection().get<TenantContext>();
      if (tenantCtx.hasContext) {
        _empresa = tenantCtx.empresa;
      } else {
        final empresas = await _empresaRepo.findAll();
        if (empresas.isNotEmpty) _empresa = empresas.first;
      }

      setState(() {
        _config = config;
        _syncStatus = config.metadata.syncStatus;
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
    _selectedTimezone = config.timezone;
    _selectedLocale = config.locale;
    _selectedCurrency = config.currency;
    _selectedTema = config.tema;
    _usarWhatsApp = config.usarWhatsApp;
    _taxaServicoCtrl.text = (config.taxaServico * 100).toStringAsFixed(1);

    // Carregar configurações da impressora do DB Drift (com fallback de SharedPreferences)
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
    
    // Prioriza dados da CoreEmpresa, e usa fallback para config antiga se vazio
    _nomeEmpresaCupomCtrl.text = _empresa?.nomeFantasia ?? config.nomeEmpresaCupom ?? '';
    if (_nomeEmpresaCupomCtrl.text == _empresa?.id) {
      _nomeEmpresaCupomCtrl.text = config.nomeEmpresaCupom ?? '';
    }
    
    _telefoneEmpresaCtrl.text = _empresa?.telefone ?? config.telefoneEmpresa ?? '';
    _cnpjEmpresaCtrl.text = _empresa?.documentoFiscal ?? config.cnpjEmpresa ?? '';
    _enderecoEmpresaCtrl.text = config.enderecoEmpresa ?? '';

    _pixFavorecidoCtrl.text = config.pixFavorecido ?? '';
    _pixBancoCtrl.text = config.pixBanco ?? '';
    _pixTipo = config.pixTipo;

    // Se as impressoras estiverem vazias no DB, tentar carregar do SharedPreferences antigo para migrar
    if (_printerCaixaCtrl.text.isEmpty && _printerCozinhaCtrl.text.isEmpty) {
      final pConfigs = await FincoreThermalPrinterService.loadPrinters();
      final impConfig = await FincoreImpressaoConfig.carregar();
      
      setState(() {
        if ((pConfigs['caixa'] as String? ?? '').isNotEmpty) _printerCaixaCtrl.text = pConfigs['caixa'];
        if ((pConfigs['cozinha'] as String? ?? '').isNotEmpty) _printerCozinhaCtrl.text = pConfigs['cozinha'];
        if ((pConfigs['expedicao'] as String? ?? '').isNotEmpty) _printerExpedicaoCtrl.text = pConfigs['expedicao'];
        _autoPrintCaixa = pConfigs['autoCaixa'] ?? true;
        _autoPrintCozinha = pConfigs['autoCozinha'] ?? true;
        _autoPrintExpedicao = pConfigs['autoExpedicao'] ?? true;
        _larguraBobina = pConfigs['largura'] ?? '80mm';
        _exibirQrCode = pConfigs['exibirQrCode'] ?? false;
        
        _pixFavorecidoCtrl.text = impConfig.pixFavorecido;
        _pixBancoCtrl.text = impConfig.pixBanco;
        _pixTipo = impConfig.pixTipo;
        _exibirCopiaCola = impConfig.habilitarCopiaCola;
      });

      // Salvar imediatamente no banco de dados Drift para consolidar a migração
      await _saveConfig();
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null || _isSaving) return;
    setState(() {
      _isSaving = true;
      _syncStatus = SyncStatus.pending;
      _syncMessage = 'Salvando...';
    });
    try {
      // 1. Salvar no SharedPreferences para compatibilidade com legados
      await FincoreThermalPrinterService.savePrinters(
        caixa: _printerCaixaCtrl.text,
        cozinha: _printerCozinhaCtrl.text,
        expedicao: _printerExpedicaoCtrl.text,
        autoCaixa: _autoPrintCaixa,
        autoCozinha: _autoPrintCozinha,
        autoExpedicao: _autoPrintExpedicao,
        largura: _larguraBobina,
        exibirQrCode: _exibirQrCode,
      );

      final impConfig = FincoreImpressaoConfig(
        nomeEmpresa: _nomeEmpresaCupomCtrl.text.trim().isEmpty ? 'SALGADERIA' : _nomeEmpresaCupomCtrl.text.trim(),
        telefone: _telefoneEmpresaCtrl.text.trim(),
        larguraMm: _larguraBobina == '58mm' ? 58 : 80,
        habilitarQrCodePix: _exibirQrCode,
        habilitarCopiaCola: _exibirCopiaCola,
        pixChave: _pixKeyCtrl.text.trim(),
        pixTipo: _pixTipo,
        pixFavorecido: _pixFavorecidoCtrl.text.trim(),
        pixBanco: _pixBancoCtrl.text.trim(),
        rodape: _mensagemRodapeCtrl.text,
      );
      await impConfig.salvar();

      // 2. Salvar no Drift SQLite (Offline-First + Sync Supabase)
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final taxa = double.tryParse(_taxaServicoCtrl.text.replaceAll(',', '.'));
      final updated = CoreEmpresaConfiguracao(
        id: _config!.id,
        tenantId: _config!.tenantId,
        timezone: _selectedTimezone,
        locale: _selectedLocale,
        currency: _selectedCurrency,
        taxaServico: taxa != null ? taxa / 100.0 : _config!.taxaServico,
        usarWhatsApp: _usarWhatsApp,
        tema: _selectedTema,
        pixKey: _pixKeyCtrl.text.trim().isEmpty ? null : _pixKeyCtrl.text.trim(),
        printerConfig: _printerCtrl.text.trim().isEmpty ? null : _printerCtrl.text.trim(),
        
        // Novos campos CAP.PRINTING
        printerCaixa: _printerCaixaCtrl.text.trim().isEmpty ? null : _printerCaixaCtrl.text.trim(),
        printerCozinha: _printerCozinhaCtrl.text.trim().isEmpty ? null : _printerCozinhaCtrl.text.trim(),
        printerBalcao: _printerBalcaoCtrl.text.trim().isEmpty ? null : _printerBalcaoCtrl.text.trim(),
        printerExpedicao: _printerExpedicaoCtrl.text.trim().isEmpty ? null : _printerExpedicaoCtrl.text.trim(),
        autoPrintCaixa: _autoPrintCaixa,
        autoPrintCozinha: _autoPrintCozinha,
        autoPrintBalcao: _autoPrintBalcao,
        autoPrintExpedicao: _autoPrintExpedicao,
        viasCliente: _viasCliente,
        viasCozinha: _viasCozinha,
        viasBalcao: _viasBalcao,
        viasExpedicao: _viasExpedicao,
        larguraPapel: _larguraBobina == '58mm' ? 58 : 80,
        cortarPapel: _cortarPapel,
        abrirGaveta: _abrirGaveta,
        imprimirQRCode: _exibirQrCode,
        imprimirCopiaCola: _exibirCopiaCola,
        mensagemRodape: _mensagemRodapeCtrl.text,
        nomeEmpresaCupom: _nomeEmpresaCupomCtrl.text.trim().isEmpty ? null : _nomeEmpresaCupomCtrl.text.trim(),
        telefoneEmpresa: _telefoneEmpresaCtrl.text.trim().isEmpty ? null : _telefoneEmpresaCtrl.text.trim(),
        cnpjEmpresa: _cnpjEmpresaCtrl.text.trim().isEmpty ? null : _cnpjEmpresaCtrl.text.trim(),
        enderecoEmpresa: _enderecoEmpresaCtrl.text.trim().isEmpty ? null : _enderecoEmpresaCtrl.text.trim(),
        
        // PIX unificado no DB
        pixFavorecido: _pixFavorecidoCtrl.text.trim().isEmpty ? null : _pixFavorecidoCtrl.text.trim(),
        pixBanco: _pixBancoCtrl.text.trim().isEmpty ? null : _pixBancoCtrl.text.trim(),
        pixTipo: _pixTipo,
        pixCidade: 'Sorocaba',

        metadata: _config!.metadata.copyWith(
          updatedAt: DateTime.now().toUtc(),
          updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          syncStatus: SyncStatus.pending,
        ),
      );
      await _repo.save(updated);
      
      // Salva os dados na tabela Empresas também, garantindo que o Tenant fique com os nomes corretos
      if (_empresa != null) {
        final updatedEmpresa = CoreEmpresa(
          id: _empresa!.id,
          razaoSocial: _empresa!.razaoSocial,
          nomeFantasia: _nomeEmpresaCupomCtrl.text.trim().isEmpty ? _empresa!.nomeFantasia : _nomeEmpresaCupomCtrl.text.trim(),
          documentoFiscal: _cnpjEmpresaCtrl.text.trim().isEmpty ? _empresa!.documentoFiscal : _cnpjEmpresaCtrl.text.trim(),
          email: _empresa!.email,
          telefone: _telefoneEmpresaCtrl.text.trim().isEmpty ? _empresa!.telefone : _telefoneEmpresaCtrl.text.trim(),
          status: _empresa!.status,
          plano: _empresa!.plano,
          timezone: _selectedTimezone,
          locale: _selectedLocale,
          currency: _selectedCurrency,
          country: _empresa!.country,
          createdFrom: _empresa!.createdFrom,
          version: _empresa!.version,
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
        _syncStatus = SyncStatus.pending;
        _syncMessage = 'Sincronizando com a nuvem...';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _syncStatus = SyncStatus.synced;
          _syncMessage = 'Sincronizado agora';
        });
      }
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      setState(() {
        _isSaving = false;
        _syncStatus = SyncStatus.failed;
        _syncMessage = 'Erro ao sincronizar';
      });
    }
  }

  String _syncStatusMessage(SyncStatus status, DateTime? lastSyncedAt) {
    switch (status) {
      case SyncStatus.synced:
        if (lastSyncedAt == null) return 'Sincronizado';
        final diff = DateTime.now().difference(lastSyncedAt);
        if (diff.inMinutes < 1) return 'Sincronizado agora';
        if (diff.inMinutes < 60) return 'Sincronizado há ${diff.inMinutes}min';
        return 'Sincronizado há ${diff.inHours}h';
      case SyncStatus.pending:
        return 'Pendente de sincronização';
      case SyncStatus.processing:
        return 'Sincronizando...';
      case SyncStatus.failed:
        return 'Falha na sincronização';
      case SyncStatus.retrying:
        return 'Tentando novamente...';
      case SyncStatus.resolved:
        return 'Sincronizado';
      case SyncStatus.conflict:
        return 'Conflito detectado';
    }
  }

  Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.resolved:
        return const Color(0xFF22C55E);
      case SyncStatus.pending:
      case SyncStatus.processing:
      case SyncStatus.retrying:
        return const Color(0xFFF59E0B);
      case SyncStatus.failed:
      case SyncStatus.conflict:
        return const Color(0xFFEF4444);
    }
  }

  IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.resolved:
        return Icons.cloud_done_outlined;
      case SyncStatus.pending:
      case SyncStatus.retrying:
        return Icons.cloud_upload_outlined;
      case SyncStatus.processing:
        return Icons.sync;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        return Icons.cloud_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

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
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSideNav(),
                const SizedBox(width: 24),
                Expanded(child: _buildSectionContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterações não salvas', style: TextStyle(color: FincoreColors.textPrimary)),
        content: const Text('Existem alterações que não foram salvas. Deseja sair e descartar as alterações?', style: TextStyle(color: FincoreColors.textSecondary)),
        backgroundColor: FincoreColors.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.danger),
            child: const Text('Sair e Descartar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurações da Empresa',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Gerencie os dados, parâmetros e integrações da sua empresa',
                style: TextStyle(fontSize: 14, color: FincoreColors.textSecondary),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _syncColor(_syncStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _syncColor(_syncStatus).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _syncStatus == SyncStatus.processing
                  ? SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _syncColor(_syncStatus)),
                    )
                  : Icon(_syncIcon(_syncStatus), size: 16, color: _syncColor(_syncStatus)),
              const SizedBox(width: 8),
              Text(
                _syncMessage.isEmpty ? 'Sincronizado' : _syncMessage,
                style: TextStyle(fontSize: 13, color: _syncColor(_syncStatus), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: (_hasUnsavedChanges && !_isSaving) ? _saveConfig : null,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 20),
          label: const Text('Salvar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            disabledBackgroundColor: FincoreColors.border,
            disabledForegroundColor: FincoreColors.textMuted,
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              if (_config != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: AuditTimelinePanel(
                      entityName: 'empresa_configuracao',
                      entityId: _config!.id,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.history, color: FincoreColors.textMuted),
            tooltip: 'Auditoria (Dev Mode)',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const Dialog(
                  backgroundColor: Colors.transparent,
                  child: LogExplorerDialog(),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined, color: FincoreColors.textMuted),
            tooltip: 'Central de Diagnóstico (Dev Mode)',
          ),
          IconButton(
            onPressed: () {
              final db = DependencyInjection().get<FincoreDatabase>();
              Navigator.of(context).push(MaterialPageRoute(builder: (c) => DriftDbViewer(db)));
            },
            icon: const Icon(Icons.storage, color: FincoreColors.textMuted),
            tooltip: 'Ver DB local',
          ),
        ],
      ],
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(_sections.length, (index) {
          final section = _sections[index];
          final isSelected = _selectedSection == index;
          return _SideNavItem(
            icon: section.icon,
            label: section.label,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedSection = index),
          );
        }),
      ),
    );
  }

  Widget _buildSectionContent() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_selectedSection),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: _sectionWidget(_selectedSection),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionWidget(int index) {
    switch (index) {
      case 0: return _buildSectionEmpresa();
      case 1: return _buildSectionRegional();
      case 2: return _buildSectionFiscal();
      case 3: return _buildSectionPix();
      case 4: return _buildSectionImpressao();
      default: return const SizedBox();
    }
  }

  // ─── SEÇÃO 1: EMPRESA ───────────────────────────────────────
  Widget _buildSectionEmpresa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.business_outlined,
          title: 'Dados da Empresa',
          subtitle: 'Informações gerais e dados do cupom',
        ),
        const SizedBox(height: 24),
        _FieldGroup(children: [
          FincoreTextField(
            controller: _nomeEmpresaCupomCtrl,
            label: 'Nome Fantasia (Exibido na Impressão)',
            hint: 'Ex: Salgaderia do Eliezer',
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          FincoreTextField(
            controller: _cnpjEmpresaCtrl,
            label: 'CNPJ / CPF da Empresa',
            hint: 'Ex: 12.345.678/0001-90',
            inputFormatters: FincoreFormatters.cnpjCpf,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          FincoreTextField(
            controller: _telefoneEmpresaCtrl,
            label: 'Telefone de Contato',
            hint: 'Ex: (15) 99999-9999',
            inputFormatters: FincoreFormatters.telefone,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          FincoreTextField(
            controller: _enderecoEmpresaCtrl,
            label: 'Endereço da Empresa',
            hint: 'Ex: Rua das Flores, 123 - Centro',
            onChanged: (_) => _onFieldChanged(),
          ),
        ]),
        const SizedBox(height: 16),
        _InfoBanner(
          icon: Icons.info_outline,
          color: const Color(0xFF3B82F6),
          message:
              'Estes dados serão impressos no cabeçalho dos seus cupons e comprovantes térmicos.',
        ),
      ],
    );
  }

  // ─── SEÇÃO 2: REGIONAL ──────────────────────────────────────
  Widget _buildSectionRegional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.language_outlined,
          title: 'Configurações Regionais',
          subtitle: 'Fuso horário, idioma, moeda e tema',
        ),
        const SizedBox(height: 24),
        _FieldGroup(children: [
          Row(children: [
            Expanded(
              child: _FincoreDropdown<String>(
                label: 'Fuso Horário',
                icon: Icons.schedule_outlined,
                value: _selectedTimezone,
                items: const [
                  'America/Sao_Paulo', 'America/Fortaleza', 'America/Manaus',
                  'America/Belem', 'America/Cuiaba', 'America/Porto_Velho',
                ],
                labels: const [
                  'Brasília (UTC-3)', 'Fortaleza (UTC-3)', 'Manaus (UTC-4)',
                  'Belém (UTC-3)', 'Cuiabá (UTC-4)', 'Porto Velho (UTC-4)',
                ],
                onChanged: (v) { _selectedTimezone = v; _onFieldChanged(); },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FincoreDropdown<String>(
                label: 'Idioma',
                icon: Icons.translate_outlined,
                value: _selectedLocale,
                items: const ['pt_BR', 'en_US', 'es_ES'],
                labels: const ['Português (Brasil)', 'English (US)', 'Español'],
                onChanged: (v) { _selectedLocale = v; _onFieldChanged(); },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _FincoreDropdown<String>(
                label: 'Moeda',
                icon: Icons.attach_money_outlined,
                value: _selectedCurrency,
                items: const ['BRL', 'USD', 'EUR'],
                labels: const ['Real Brasileiro (R\$)', 'Dólar (US\$)', 'Euro (€)'],
                onChanged: (v) { _selectedCurrency = v; _onFieldChanged(); },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FincoreDropdown<String>(
                label: 'Tema do App',
                icon: Icons.palette_outlined,
                value: _selectedTema,
                items: const ['dark', 'light', 'system'],
                labels: const ['Escuro', 'Claro', 'Sistema'],
                onChanged: (v) { _selectedTema = v; _onFieldChanged(); },
              ),
            ),
          ]),
        ]),
      ],
    );
  }

  // ─── SEÇÃO 3: FISCAL ────────────────────────────────────────
  Widget _buildSectionFiscal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.percent_outlined,
          title: 'Configurações Fiscais',
          subtitle: 'Taxa de serviço e notificações',
        ),
        const SizedBox(height: 24),
        _FieldGroup(children: [
          Row(children: [
            Expanded(
              child: FincoreTextField(
                controller: _taxaServicoCtrl,
                label: 'Taxa de Serviço (%)',
                prefixIcon: const Icon(Icons.percent_outlined, size: 18),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _onFieldChanged(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usar WhatsApp', style: TextStyle(fontSize: 14, color: FincoreColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: _usarWhatsApp,
                        onChanged: (v) { setState(() => _usarWhatsApp = v); _onFieldChanged(); },
                        activeColor: FincoreColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _usarWhatsApp ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          color: _usarWhatsApp ? FincoreColors.primary : FincoreColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ]),
      ],
    );
  }

  // ─── SEÇÃO 4: PIX ───────────────────────────────────────────
  Widget _buildSectionPix() {
    final chave = _pixKeyCtrl.text.trim().isNotEmpty ? _pixKeyCtrl.text.trim() : '07389215640';
    final favorecido = _pixFavorecidoCtrl.text.trim().isNotEmpty ? _pixFavorecidoCtrl.text.trim() : 'Salgaderia';
    final copiaColaTeste = PixGenerator.gerarCopiaCola(
      chave: chave,
      favorecido: favorecido,
      cidade: 'Sorocaba',
      valor: 10.00,
      mensagem: 'Teste Pix',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.pix_outlined,
          title: 'Configuração de Recebimentos via PIX',
          subtitle: 'Chaves, favorecido, exibição no cupom e gerador de PIX Copia e Cola',
        ),
        const SizedBox(height: 24),
        _FieldGroup(children: [
          FincoreTextField(
            controller: _pixKeyCtrl,
            label: 'Chave PIX Principal',
            prefixIcon: const Icon(Icons.pix_outlined, size: 18),
            hint: 'CPF, CNPJ, telefone, e-mail ou chave aleatória',
            inputFormatters: _pixTipo == 'CPF' || _pixTipo == 'CNPJ'
                ? FincoreFormatters.cnpjCpf
                : _pixTipo == 'Telefone'
                    ? FincoreFormatters.telefone
                    : null,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          _FincoreDropdown<String>(
            label: 'Tipo da Chave PIX',
            icon: Icons.badge_outlined,
            value: _pixTipo,
            items: const ['CPF', 'CNPJ', 'Telefone', 'E-mail', 'Aleatória'],
            labels: const ['CPF', 'CNPJ', 'Telefone (com DDD)', 'E-mail', 'Chave Aleatória (EVP)'],
            onChanged: (v) {
              if (v != null) {
                setState(() => _pixTipo = v);
                _onFieldChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          FincoreTextField(
            controller: _pixFavorecidoCtrl,
            label: 'Nome do Favorecido (Titular da Conta)',
            prefixIcon: const Icon(Icons.person_outline, size: 18),
            hint: 'Ex: Solange Salgados Artesanais LTDA',
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          FincoreTextField(
            controller: _pixBancoCtrl,
            label: 'Banco / Cidade',
            prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
            hint: 'Ex: Mercado Pago / Sorocaba',
            onChanged: (_) => _onFieldChanged(),
          ),
        ]),
        const SizedBox(height: 24),

        // Opções de Impressão do PIX no Cupom
        const Text(
          'OPÇÕES DE IMPRESSÃO NO CUPOM TÉRMICO',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.accent),
        ),
        const SizedBox(height: 12),
        _FieldGroup(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exibir QR Code PIX no Cupom',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Renderiza o gráfico do QR Code nativo ESC/POS e no PDF do comprovante',
                    style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                  ),
                ],
              ),
              Switch(
                value: _exibirQrCode,
                onChanged: (v) {
                  setState(() => _exibirQrCode = v);
                  _onFieldChanged();
                },
                activeColor: FincoreColors.accent,
              ),
            ],
          ),
          const Divider(color: FincoreColors.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exibir Chave PIX Copia e Cola no Cupom',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Imprime a string de pagamento do PIX Copia e Cola no cupom impresso',
                    style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                  ),
                ],
              ),
              Switch(
                value: _exibirCopiaCola,
                onChanged: (v) {
                  setState(() => _exibirCopiaCola = v);
                  _onFieldChanged();
                },
                activeColor: FincoreColors.accent,
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // Testador de PIX Copia e Cola & QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D2D44)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_2_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TESTE DO PIX COPIA E COLA EM TEMPO REAL',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                copiaColaTeste,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: copiaColaTeste));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Chave PIX Copia e Cola copiada para a área de transferência!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar PIX Copia e Cola de Teste'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SEÇÃO 5: IMPRESSÃO & TERMINAIS OPERACIONAIS ───────────────
  Widget _buildSectionImpressao() {
    final useCase = DependencyInjection().get<PrintUseCase>();

    Widget _viasDropdown({required String label, required int value, required ValueChanged<int> onChanged}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
          SizedBox(
            width: 80,
            child: DropdownButtonFormField<int>(
              value: value,
              dropdownColor: FincoreColors.surface,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
              ),
              items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text('$i x'))),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.print_outlined,
          title: 'Impressoras Térmicas e Terminais',
          subtitle: 'Configure e personalize as vias do Caixa, Cozinha, Balcão e Expedição',
        ),
        const SizedBox(height: 20),
        _InfoBanner(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF10B981),
          message:
              'No app nativo Windows/Desktop, as impressoras ESC/POS ou filas do sistema operam via USB, Rede Local (IP) ou Compartilhamento SMB.',
        ),
        const SizedBox(height: 20),

        // VIA 1: CAIXA / COMPROVANTE DO CLIENTE
        _FieldGroup(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. VIA DO CAIXA (CUPOM DO CLIENTE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
              Row(
                children: [
                  Switch(
                    value: _autoPrintCaixa,
                    onChanged: (v) {
                      setState(() => _autoPrintCaixa = v);
                      _onFieldChanged();
                    },
                    activeColor: FincoreColors.primary,
                  ),
                  const Text('Auto-imprimir', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FincoreTextField(
                  controller: _printerCaixaCtrl,
                  label: 'Impressora do Caixa / Recepção',
                  hint: 'Ex: USB001 ou \\\\localhost\\EPSON',
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🖨️ Enviando teste para a impressora do Caixa...'), backgroundColor: FincoreColors.primary),
                  );
                  final res = await useCase.testarImpressora(
                    printerPath: _printerCaixaCtrl.text,
                    via: PrintVia.cliente,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: FincoreColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Testar Via', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _viasDropdown(
            label: 'Número de Cópias (Caixa/Cliente)',
            value: _viasCliente,
            onChanged: (v) {
              setState(() => _viasCliente = v);
              _onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          _FincoreDropdown<String>(
            label: 'Largura da Bobina - Caixa',
            icon: Icons.linear_scale,
            value: _larguraBobina,
            items: const ['80mm', '58mm'],
            labels: const ['80 mm (Bobina Padrão ESC/POS)', '58 mm (Bobina Compacta)'],
            onChanged: (v) {
              setState(() => _larguraBobina = v);
              _onFieldChanged();
            },
          ),
        ]),
        const SizedBox(height: 16),

        // VIA 2: COZINHA / PRODUÇÃO
        _FieldGroup(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. VIA DE PRODUÇÃO (COZINHA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
              Row(
                children: [
                  Switch(
                    value: _autoPrintCozinha,
                    onChanged: (v) {
                      setState(() => _autoPrintCozinha = v);
                      _onFieldChanged();
                    },
                    activeColor: const Color(0xFFF59E0B),
                  ),
                  const Text('Auto-imprimir', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FincoreTextField(
                  controller: _printerCozinhaCtrl,
                  label: 'Impressora da Cozinha (Produção)',
                  hint: 'Ex: 192.168.1.200 (Rede IP) ou Porta COM',
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🍳 Enviando teste para a impressora da Cozinha...'), backgroundColor: Color(0xFFF59E0B)),
                  );
                  final res = await useCase.testarImpressora(
                    printerPath: _printerCozinhaCtrl.text,
                    via: PrintVia.cozinha,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: FincoreColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Testar Via', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _viasDropdown(
            label: 'Número de Cópias (Cozinha)',
            value: _viasCozinha,
            onChanged: (v) {
              setState(() => _viasCozinha = v);
              _onFieldChanged();
            },
          ),
        ]),
        const SizedBox(height: 16),

        // VIA 3: BALCÃO / COPA
        _FieldGroup(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('3. VIA DO BALCÃO (RETIRADA / COPA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              Row(
                children: [
                  Switch(
                    value: _autoPrintBalcao,
                    onChanged: (v) {
                      setState(() => _autoPrintBalcao = v);
                      _onFieldChanged();
                    },
                    activeColor: const Color(0xFF3B82F6),
                  ),
                  const Text('Auto-imprimir', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FincoreTextField(
                  controller: _printerBalcaoCtrl,
                  label: 'Impressora do Balcão',
                  hint: 'Ex: USB002 ou \\\\localhost\\Balcao',
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🏪 Enviando teste para a impressora do Balcão...'), backgroundColor: Color(0xFF3B82F6)),
                  );
                  final res = await useCase.testarImpressora(
                    printerPath: _printerBalcaoCtrl.text,
                    via: PrintVia.balcao,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: FincoreColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Testar Via', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _viasDropdown(
            label: 'Número de Cópias (Balcão)',
            value: _viasBalcao,
            onChanged: (v) {
              setState(() => _viasBalcao = v);
              _onFieldChanged();
            },
          ),
        ]),
        const SizedBox(height: 16),

        // VIA 4: EXPEDIÇÃO / DELIVERY
        _FieldGroup(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('4. VIA DE EXPEDIÇÃO & DELIVERY (MOTOBOY)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              Row(
                children: [
                  Switch(
                    value: _autoPrintExpedicao,
                    onChanged: (v) {
                      setState(() => _autoPrintExpedicao = v);
                      _onFieldChanged();
                    },
                    activeColor: const Color(0xFF10B981),
                  ),
                  const Text('Auto-imprimir', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FincoreTextField(
                  controller: _printerExpedicaoCtrl,
                  label: 'Impressora de Expedição / Delivery',
                  hint: 'Ex: 192.168.1.201 ou Impressora Etiquetadora',
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🛵 Enviando teste para a impressora de Expedição...'), backgroundColor: Color(0xFF10B981)),
                  );
                  final res = await useCase.testarImpressora(
                    printerPath: _printerExpedicaoCtrl.text,
                    via: PrintVia.expedicao,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: FincoreColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Testar Via', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _viasDropdown(
            label: 'Número de Cópias (Expedição)',
            value: _viasExpedicao,
            onChanged: (v) {
              setState(() => _viasExpedicao = v);
              _onFieldChanged();
            },
          ),
        ]),
        const SizedBox(height: 16),

        // CONFIGURAÇÕES DE HARDWARE (GUILHOTINA / GAVETA)
        _FieldGroup(children: [
          const Text('AÇÕES DE HARDWARE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Acionar Guilhotina (Cortar Papel)', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
              Switch(
                value: _cortarPapel,
                onChanged: (v) {
                  setState(() => _cortarPapel = v);
                  _onFieldChanged();
                },
                activeColor: FincoreColors.primary,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Abrir Gaveta de Dinheiro após Impressão', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
              Switch(
                value: _abrirGaveta,
                onChanged: (v) {
                  setState(() => _abrirGaveta = v);
                  _onFieldChanged();
                },
                activeColor: FincoreColors.primary,
              ),
            ],
          ),
        ]),
        const SizedBox(height: 16),

        // PERSONALIZAÇÃO DO CUPOM (MENSAGEM RODAPÉ)
        _FieldGroup(children: [
          const Text('PERSONALIZAÇÃO DO CUPOM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
          const SizedBox(height: 12),
          FincoreTextField(
            controller: _mensagemRodapeCtrl,
            label: 'Mensagem do Rodapé',
            hint: 'Ex: Obrigado pela preferência! Bom apetite!',
            onChanged: (_) => _onFieldChanged(),
          ),
        ]),
        const SizedBox(height: 16),

        _FieldGroup(children: [
          const Text('DIAGNÓSTICO E LOGS (LOCAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrindo diretório do LogService no Windows Explorer...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.background,
              foregroundColor: FincoreColors.textPrimary,
              elevation: 0,
              side: const BorderSide(color: FincoreColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.folder_open_outlined, size: 16),
            label: const Text('Abrir Pasta de Logs no Windows Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ]),
      ],
    );
  }
}

// ─── WIDGETS COMPARTILHADOS ───────────────────────────────────

class _SectionItem {
  final IconData icon;
  final String label;
  const _SectionItem({required this.icon, required this.label});
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? FincoreColors.primary : FincoreColors.textMuted),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: FincoreColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: FincoreColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final List<Widget> children;
  const _FieldGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final String? hint;

  const _FieldCard({required this.label, required this.icon, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: FincoreColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        child,
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
        ],
      ],
    );
  }
}

class _FincoreDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final List<String> labels;
  final void Function(T) onChanged;

  const _FincoreDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final T safeValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: FincoreColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: FincoreColors.surface,
              style: const TextStyle(fontSize: 14, color: FincoreColors.textPrimary),
              items: List.generate(
                items.length,
                (i) => DropdownMenuItem<T>(value: items[i], child: Text(labels[i])),
              ),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBanner({required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 13, color: color.withOpacity(0.9))),
          ),
        ],
      ),
    );
  }
}
