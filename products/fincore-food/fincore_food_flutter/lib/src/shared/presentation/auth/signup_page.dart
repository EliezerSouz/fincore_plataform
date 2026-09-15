import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_design_system/fincore_design_system.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  const SignupPage({super.key, required this.onSignupSuccess});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0: Credenciais, 1: Empresa
  bool _isLoading = false;
  bool _obscureText = true;

  // Passo 1: Credenciais
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Passo 2: Empresa
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  String _segmento = 'Food Service';
  String _plano = 'prata';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Cadastrar usuário no Supabase Auth com fallback de login para autorrecuperação
      AuthResponse authResponse;
      try {
        authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'name': _nameController.text.trim()},
        );
      } catch (authErr) {
        // Tenta fazer o login com as credenciais. Se funcionar, recupera a sessão.
        // Se falhar (ex: senha errada), rebola o erro de cadastro original.
        try {
          authResponse = await Supabase.instance.client.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (_) {
          rethrow;
        }
      }

      final token = authResponse.session?.accessToken;
      if (token == null) {
        throw Exception('Sessão não iniciada. Verifique suas credenciais.');
      }

      final currentUser = authResponse.user;
      if (currentUser == null) throw Exception('Usuário não autenticado.');

      // 2. Criar ou vincular empresa e membro no Supabase
      final now = DateTime.now().toUtc().toIso8601String();
      final userEmail = _emailController.text.trim();
      final docFiscal = _documentoController.text.trim();
      final nomeFantasiaFinal = _nomeFantasiaController.text.trim().isEmpty
          ? _razaoSocialController.text.trim()
          : _nomeFantasiaController.text.trim();

      // Verificar se a empresa já foi cadastrada previamente (por CPF/CNPJ ou e-mail)
      final existingEmpresas = await Supabase.instance.client
          .from('empresa')
          .select('id, status, nomeFantasia')
          .or('documentoFiscal.eq.$docFiscal,email.eq.$userEmail')
          .limit(1);

      String tenantId;
      if (existingEmpresas.isNotEmpty) {
        tenantId = existingEmpresas.first['id'] as String;
      } else {
        final empresaResult = await Supabase.instance.client.from('empresa').insert({
          'razaoSocial': _razaoSocialController.text.trim(),
          'nomeFantasia': nomeFantasiaFinal,
          'documentoFiscal': docFiscal,
          'email': userEmail,
          'telefone': _telefoneController.text.trim(),
          'segmento': _segmento,
          'plano': _plano,
          'status': 'PENDENTE_ATIVACAO',
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

        tenantId = empresaResult['id'] as String;
      }

      // Buscar ou criar perfil do usuário
      final usuarioRows = await Supabase.instance.client
          .from('usuarios')
          .select('id')
          .or('authUserId.eq.${currentUser.id},email.eq.$userEmail')
          .limit(1);
      String usuarioId;
      if (usuarioRows.isNotEmpty) {
        usuarioId = (usuarioRows.first as Map<String, dynamic>)['id'] as String;
      } else {
        final insertUser = await Supabase.instance.client.from('usuarios').insert({
          'authUserId': currentUser.id,
          'email': currentUser.email ?? userEmail,
          'username': userEmail.split('@').first,
          'nome': _nameController.text.trim(),
          'ativo': true,
          'criadoEm': now,
          'atualizadoEm': now,
        }).select('id').single();
        usuarioId = insertUser['id'] as String;
      }

      // Buscar ou criar vínculo de membro com a empresa
      final existingMembros = await Supabase.instance.client
          .from('membro_empresa')
          .select('id')
          .eq('tenantId', tenantId)
          .eq('usuarioId', usuarioId)
          .limit(1);

      if (existingMembros.isEmpty) {
        await Supabase.instance.client.from('membro_empresa').insert({
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
      }

      // Salvar em cache local para exibição imediata na tela de liberação
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_empresa_nome', nomeFantasiaFinal);
        await prefs.setString('pending_empresa_email', _emailController.text.trim());
        await prefs.setString('pending_empresa_plano', _plano);
        await prefs.setString('pending_empresa_doc', _documentoController.text.trim());
        await prefs.setString('pending_empresa_tel', _telefoneController.text.trim());
        await prefs.setString('pending_empresa_seg', _segmento);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta e Espaço criados com sucesso! Aguardando ativação.'),
          backgroundColor: FincoreColors.success,
        ),
      );

      widget.onSignupSuccess();
      Navigator.of(context).pop();
    } on AuthException catch (e) {
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
          content: Text('Erro ao cadastrar: $e'),
          backgroundColor: FincoreColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validar apenas campos do Passo 1
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          !_emailController.text.contains('@') ||
          _passwordController.text.isEmpty ||
          _passwordController.text.length < 8 ||
          _confirmPasswordController.text != _passwordController.text) {
        // Força validação visual exibindo erros
        _formKey.currentState!.validate();
        return;
      }
      setState(() => _currentStep = 1);
    } else {
      _submitSignup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FincoreColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FincoreColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FincoreColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CRIAR CONTA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 0 
                        ? 'Etapa 1 de 2: Seus Dados de Acesso'
                        : 'Etapa 2 de 2: Dados do Estabelecimento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FincoreColors.primary,
                      fontSize: 13,
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
                  const SizedBox(height: 20),
                  
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _prevStep,
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
                              : Text(_currentStep == 0 ? 'AVANÇAR' : 'CADASTRAR', 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Nome Completo',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.person_outline, color: FincoreColors.textMuted),
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
            if (value == null || value.isEmpty) return 'Informe seu nome';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'E-mail',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.email_outlined, color: FincoreColors.textMuted),
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
            if (value == null || value.isEmpty) return 'Informe seu e-mail';
            if (!value.contains('@')) return 'E-mail inválido';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscureText,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Senha',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.lock_outlined, color: FincoreColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.lock_outlined : Icons.lock_open_outlined,
                color: FincoreColors.textMuted,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
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
          validator: (value) {
            if (value == null || value.isEmpty) return 'Informe uma senha';
            if (value.length < 8) return 'A senha deve ter no mínimo 8 caracteres';
            if (!value.contains(RegExp(r'[0-9]'))) return 'Deve conter pelo menos 1 número';
            if (!value.contains(RegExp(r'[A-Z]'))) return 'Deve conter pelo menos 1 letra maiúscula';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureText,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Repetir Senha',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.lock_outlined, color: FincoreColors.textMuted),
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
            if (value == null || value.isEmpty) return 'Repita sua senha';
            if (value != _passwordController.text) return 'As senhas não coincidem';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _razaoSocialController,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Razão Social',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.business_outlined, color: FincoreColors.textMuted),
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
            if (value == null || value.isEmpty) return 'Informe a Razão Social';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nomeFantasiaController,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Nome Fantasia (Opcional)',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.storefront_outlined, color: FincoreColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        const SizedBox(height: 12),
        TextFormField(
          controller: _documentoController,
          style: const TextStyle(color: FincoreColors.textPrimary),
          inputFormatters: FincoreFormatters.cnpjCpf,
          decoration: InputDecoration(
            labelText: 'CNPJ / CPF',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.badge_outlined, color: FincoreColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            if (value == null || value.isEmpty) return 'Informe o CNPJ/CPF';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telefoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: FincoreColors.textPrimary),
          inputFormatters: FincoreFormatters.telefone,
          decoration: InputDecoration(
            labelText: 'Telefone de Contato',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.phone_outlined, color: FincoreColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            if (value == null || value.isEmpty) return 'Informe o telefone';
            return null;
          },
        ),
        const SizedBox(height: 12),
        const Text('Segmento de Atuação', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _segmento,
          dropdownColor: FincoreColors.surface,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        const SizedBox(height: 12),
        const Text('Plano de Assinatura Desejado', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _plano,
          dropdownColor: FincoreColors.surface,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FincoreColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: FincoreColors.primary),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'bronze', child: Text('Essencial (Bronze) — 30 dias grátis')),
            DropdownMenuItem(value: 'prata', child: Text('Profissional (Prata) — Recomendado')),
            DropdownMenuItem(value: 'ouro', child: Text('Enterprise (Ouro)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _plano = val);
          },
        ),
      ],
    );
  }
}
