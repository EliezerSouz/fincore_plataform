import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_food_client/fincore_food_client.dart';

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

      final success = await client.onboarding.criarEmpresa(
        razaoSocial: _razaoSocialController.text.trim(),
        nomeFantasia: _nomeFantasiaController.text.trim().isEmpty 
            ? _razaoSocialController.text.trim()
            : _nomeFantasiaController.text.trim(),
        documentoFiscal: _documentoController.text.trim().isEmpty 
            ? '00.000.000/0001-00'
            : _documentoController.text.trim(),
        emailEmpresa: _emailEmpresaController.text.trim(),
        telefoneEmpresa: _telefoneController.text.trim(),
        usuarioNome: usuarioNome,
        segmento: _segmento,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa criada com sucesso! Aguardando ativação.'),
            backgroundColor: FincoreColors.success,
          ),
        );
        widget.onCreated();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao criar empresa. Tente novamente.'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
    } on OnboardingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: FincoreColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
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
