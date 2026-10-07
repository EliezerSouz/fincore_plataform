import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cep_service.dart';

class OnboardingWizardPage extends StatefulWidget {
  final VoidCallback onCreated;
  const OnboardingWizardPage({super.key, required this.onCreated});

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _buscandoCep = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  String _segmento = 'Food Service';

  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailEmpresaController = TextEditingController();

  // Endereço
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    String userEmail = '';
    try {
      userEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    } catch (_) {}
    _emailEmpresaController.text = userEmail;
  }

  @override
  void dispose() {
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _emailEmpresaController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep(String cepDigitado) async {
    final cepLimpo = cepDigitado.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return;

    setState(() => _buscandoCep = true);
    final endereco = await CepService.consultarCep(cepLimpo);
    setState(() => _buscandoCep = false);

    if (endereco != null && mounted) {
      _logradouroController.text = endereco.logradouro;
      _bairroController.text = endereco.bairro;
      _cidadeController.text = endereco.cidade;
      _estadoController.text = endereco.uf;
      if (endereco.complemento.isNotEmpty && _complementoController.text.isEmpty) {
        _complementoController.text = endereco.complemento;
      }
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isLoading = true);
    try {
      String usuarioNome = 'Administrador';
      try {
        usuarioNome = Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ??
            Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
            'Administrador';
      } catch (_) {}

      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      final now = DateTime.now().toUtc().toIso8601String();
      final razaoSocial = _razaoSocialController.text.trim();
      final nomeFantasia = _nomeFantasiaController.text.trim().isEmpty
          ? razaoSocial
          : _nomeFantasiaController.text.trim();
      final documentoFiscal = _documentoController.text.trim().isEmpty
          ? '00.000.000/0001-00'
          : _documentoController.text.trim();
      final emailEmpresa = _emailEmpresaController.text.trim().toLowerCase();
      final telefoneEmpresa = _telefoneController.text.trim();

      // 1. Criar empresa no Supabase com endereço
      final empresaResult = await supabase.from('empresa').insert({
        'razaoSocial': razaoSocial,
        'nomeFantasia': nomeFantasia,
        'documentoFiscal': documentoFiscal,
        'email': emailEmpresa,
        'telefone': telefoneEmpresa,
        'segmento': _segmento,
        'cep': _cepController.text.trim(),
        'logradouro': _logradouroController.text.trim(),
        'numero': _numeroController.text.trim(),
        'complemento': _complementoController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim().toUpperCase(),
        'status': 'PENDENTE_ATIVACAO',
        'plano': 'bronze',
        'timezone': 'America/Sao_Paulo',
        'locale': 'pt_BR',
        'currency': 'BRL',
        'country': 'BR',
        'createdFrom': 'PDV',
        'createdBy': currentUser.id,
        'updatedBy': currentUser.id,
        'createdAt': now,
        'updatedAt': now,
        'syncVersion': 1,
      }).select('id').single();

      final tenantId = empresaResult['id'] as String;

      // 2. Buscar ou criar perfil do usuário
      final usuarioRows = await supabase
          .from('usuarios')
          .select('id')
          .eq('authUserId', currentUser.id)
          .limit(1);

      String usuarioId;
      if (usuarioRows.isNotEmpty) {
        usuarioId = (usuarioRows.first as Map<String, dynamic>)['id'] as String;
      } else {
        final username = (currentUser.email ?? 'usuario').split('@').first;
        final insertUser = await supabase.from('usuarios').insert({
          'authUserId': currentUser.id,
          'email': currentUser.email?.toLowerCase().trim(),
          'username': username,
          'nome': usuarioNome,
          'ativo': true,
          'criadoEm': now,
          'atualizadoEm': now,
        }).select('id').single();
        usuarioId = insertUser['id'] as String;
      }

      // 3. Criar membro como ADMIN desta empresa
      await supabase.from('membro_empresa').insert({
        'tenantId': tenantId,
        'usuarioId': usuarioId,
        'role': 'ADMIN',
        'ativo': true,
        'convidadoEm': now,
        'aceitoEm': now,
        'createdBy': currentUser.id,
        'updatedBy': currentUser.id,
        'createdAt': now,
        'updatedAt': now,
        'syncVersion': 1,
      });

      // 4. Criar configuração padrão da empresa
      await supabase.from('empresa_configuracao').upsert({
        'tenantId': tenantId,
        'taxaServico': 0.10,
        'usarWhatsApp': true,
        'tema': 'dark',
        'syncVersion': 1,
        'autoPrintCaixa': true,
        'autoPrintCozinha': true,
        'autoPrintBalcao': false,
        'autoPrintExpedicao': false,
        'viasCliente': 1,
        'viasCozinha': 1,
        'viasBalcao': 0,
        'viasExpedicao': 0,
        'larguraPapel': 80,
        'cortarPapel': true,
        'abrirGaveta': false,
        'imprimirQRCode': true,
        'imprimirCopiaCola': true,
        'imprimirLogo': false,
        'imprimirRodape': true,
        'mensagemRodape': 'Obrigado pela preferência!',
        'pixTipo': 'CPF',
        'margemSegurancaMinutos': 10,
        'createdBy': currentUser.id,
        'updatedBy': currentUser.id,
        'createdAt': now,
        'updatedAt': now,
      }, onConflict: 'tenantId');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa cadastrada com sucesso! Bem-vindo ao FINCORE FOOD.'),
          backgroundColor: FincoreColors.success,
        ),
      );
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar empresa: $e'),
          backgroundColor: FincoreColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey1.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKey2.currentState!.validate()) return;
      _submitOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FincoreColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FincoreColors.border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CONFIGURAÇÃO DA EMPRESA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 0
                      ? 'Passo 1 de 2: Dados do Negócio'
                      : 'Passo 2 de 2: Fiscal, Contato e Endereço',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FincoreColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: FincoreColors.border,
                  valueColor: AlwaysStoppedAnimation(FincoreColors.primary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 28),
                
                _buildStepContent(),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: FincoreColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('VOLTAR', style: TextStyle(color: FincoreColors.textPrimary)),
                        ),
                      )
                    else
                      const Spacer(),
                    
                    if (_currentStep > 0) const SizedBox(width: 16),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _currentStep == 1 ? 'CONCLUIR CADASTRO' : 'AVANÇAR',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: FincoreColors.danger),
                  label: const Text('Sair da Conta', style: TextStyle(color: FincoreColors.danger, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Identificação da Empresa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _razaoSocialController,
                style: const TextStyle(color: FincoreColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Razão Social *',
                  labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FincoreColors.primary),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe a Razão Social' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeFantasiaController,
                style: const TextStyle(color: FincoreColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome Fantasia (Opcional)',
                  labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FincoreColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Segmento de Atuação', style: TextStyle(fontSize: 13, color: FincoreColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _segmento,
                dropdownColor: FincoreColors.surface,
                style: const TextStyle(color: FincoreColors.textPrimary),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FincoreColors.primary),
                  ),
                ),
                items: ['Food Service', 'Restaurante / Bar', 'Pizzaria / Hamburgueria', 'Confeitaria / Padaria', 'Varejo Geral', 'Outro']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _segmento = val);
                },
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Fiscal e Contato', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _documentoController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      inputFormatters: FincoreFormatters.cnpjCpf,
                      decoration: InputDecoration(
                        labelText: 'CNPJ / CPF *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Informe o CNPJ/CPF' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      inputFormatters: FincoreFormatters.telefone,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp / Telefone *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Informe o telefone' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailEmpresaController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: FincoreColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'E-mail Comercial *',
                  labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FincoreColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Informe o e-mail comercial';
                  if (!_emailRegExp.hasMatch(value.trim())) return 'Informe um e-mail válido (ex: contato@empresa.com)';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Divider(color: FincoreColors.border),
              const SizedBox(height: 12),
              const Text('Endereço do Estabelecimento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      inputFormatters: FincoreFormatters.cep,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      onChanged: (val) {
                        if (val.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                          _buscarCep(val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'CEP *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        suffixIcon: _buscandoCep
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: FincoreColors.primary),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.search, size: 20, color: FincoreColors.primary),
                                onPressed: () => _buscarCep(_cepController.text),
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
                      validator: (val) => val == null || val.trim().isEmpty ? 'Informe o CEP' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cidadeController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Cidade *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Informe a Cidade' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: _estadoController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'UF *',
                        counterText: '',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'UF' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _logradouroController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Logradouro / Rua *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Informe a Rua/Avenida' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _numeroController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Nº *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nº' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bairroController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Bairro *',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Informe o Bairro' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _complementoController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Complemento',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: FincoreColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

