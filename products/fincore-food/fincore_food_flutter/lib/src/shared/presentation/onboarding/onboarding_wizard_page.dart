import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingWizardPage extends StatefulWidget {
  final VoidCallback onCreated;
  const OnboardingWizardPage({super.key, required this.onCreated});

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  String _segmento = 'Food Service';

  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailEmpresaController = TextEditingController();



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
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isLoading = true);
    try {
      String usuarioNome = 'Administrador';
      try {
        usuarioNome = Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? 'Administrador';
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
      final emailEmpresa = _emailEmpresaController.text.trim();
      final telefoneEmpresa = _telefoneController.text.trim();

      // 1. Criar empresa no Supabase
      final empresaResult = await supabase.from('empresa').insert({
        'razaoSocial': razaoSocial,
        'nomeFantasia': nomeFantasia,
        'documentoFiscal': documentoFiscal,
        'email': emailEmpresa,
        'telefone': telefoneEmpresa,
        'segmento': _segmento,
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
          'email': currentUser.email,
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
          content: Text('Empresa criada com sucesso! Aguardando ativação.'),
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
            constraints: const BoxConstraints(maxWidth: 480),
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
                  'CONFIGURAÇÃO DO ESPAÇO',
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
                  'Passo ${_currentStep + 1} de 2',
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
                const SizedBox(height: 32),
                
                _buildStepContent(),

                const SizedBox(height: 32),
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
                            : Text(_currentStep == 1 ? 'FINALIZAR' : 'AVANÇAR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
              const Text('Sobre a Empresa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _razaoSocialController,
                style: const TextStyle(color: FincoreColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Razão Social',
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
                validator: (value) => value == null || value.isEmpty ? 'Informe a Razão Social' : null,
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
                items: ['Food Service', 'Varejo Geral', 'Logística', 'Outro']
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
              const Text('Informações Fiscais e Contato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentoController,
                style: const TextStyle(color: FincoreColors.textPrimary),
                inputFormatters: FincoreFormatters.cnpjCpf,
                decoration: InputDecoration(
                  labelText: 'CNPJ / CPF',
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
                validator: (value) => value == null || value.isEmpty ? 'Informe o CNPJ/CPF' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: FincoreColors.textPrimary),
                inputFormatters: FincoreFormatters.telefone,
                decoration: InputDecoration(
                  labelText: 'Telefone de Contato',
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
                validator: (value) => value == null || value.isEmpty ? 'Informe o telefone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailEmpresaController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: FincoreColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'E-mail Comercial',
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
                validator: (value) => value == null || value.isEmpty ? 'Informe o e-mail comercial' : null,
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
