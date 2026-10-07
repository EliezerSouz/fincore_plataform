import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../services/cep_service.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  const SignupPage({super.key, required this.onSignupSuccess});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0: Credenciais, 1: Empresa e Endereço
  bool _isLoading = false;
  bool _obscureText = true;
  bool _buscandoCep = false;

  // Passo 1: Credenciais
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Passo 2: Empresa & Endereço
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
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
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() => _buscandoCep = true);
    final endereco = await CepService.consultarCep(cleanCep);
    if (mounted) {
      setState(() => _buscandoCep = false);
      if (endereco != null && endereco.valido) {
        _logradouroController.text = endereco.logradouro;
        _bairroController.text = endereco.bairro;
        _cidadeController.text = endereco.localidade;
        _estadoController.text = endereco.uf;
      }
    }
  }

  Future<void> _cadastrarComGoogle() async {
    setState(() => _isLoading = true);
    try {
      final redirectUrl = kIsWeb ? null : 'io.supabase.fincore://login-callback/';
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar com Google: $e'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Cadastrar usuário no Supabase Auth com fallback de login para autorrecuperação
      AuthResponse authResponse;
      try {
        authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
          data: {'name': _nameController.text.trim()},
        );
      } catch (authErr) {
        // Tenta fazer o login com as credenciais se já foi cadastrado
        try {
          authResponse = await Supabase.instance.client.auth.signInWithPassword(
            email: _emailController.text.trim().toLowerCase(),
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
      final userEmail = _emailController.text.trim().toLowerCase();
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
          'cep': _cepController.text.trim(),
          'logradouro': _logradouroController.text.trim(),
          'numero': _numeroController.text.trim(),
          'complemento': _complementoController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'cidade': _cidadeController.text.trim(),
          'estado': _estadoController.text.trim().toUpperCase(),
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
        // Botão de Cadastro Rápido com Google
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _cadastrarComGoogle,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: FincoreColors.border, width: 1.2),
              backgroundColor: FincoreColors.background.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Color(0xFF4285F4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cadastrar com o Google',
                  style: TextStyle(
                    color: FincoreColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Divisor
        Row(
          children: [
            Expanded(child: Container(height: 1, color: FincoreColors.border)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou crie com e-mail e senha', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
            ),
            Expanded(child: Container(height: 1, color: FincoreColors.border)),
          ],
        ),
        const SizedBox(height: 14),

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
            if (value == null || value.trim().isEmpty) return 'Informe seu nome completo';
            if (value.trim().length < 3) return 'Nome muito curto';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'E-mail Válido',
            hintText: 'exemplo@seuemail.com',
            hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
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
            if (value == null || value.trim().isEmpty) return 'Informe seu e-mail';
            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Informe um e-mail válido (ex: contato@empresa.com.br)';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscureText,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Senha de Acesso',
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
            if (value.length < 8) return 'Mínimo de 8 caracteres';
            if (!value.contains(RegExp(r'[0-9]'))) return 'Deve conter pelo menos 1 número';
            if (!value.contains(RegExp(r'[A-Z]'))) return 'Deve conter pelo menos 1 letra maiúscula';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureText,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Confirmar Senha',
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
            labelText: 'Razão Social / Nome da Empresa',
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
            if (value == null || value.trim().isEmpty) return 'Informe a Razão Social';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nomeFantasiaController,
          style: const TextStyle(color: FincoreColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Nome Fantasia (Como é conhecido)',
            labelStyle: const TextStyle(color: FincoreColors.textSecondary),
            prefixIcon: const Icon(Icons.storefront_outlined, color: FincoreColors.textMuted),
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _documentoController,
                style: const TextStyle(color: FincoreColors.textPrimary),
                inputFormatters: FincoreFormatters.cnpjCpf,
                decoration: InputDecoration(
                  labelText: 'CNPJ / CPF',
                  labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                  prefixIcon: const Icon(Icons.badge_outlined, color: FincoreColors.textMuted),
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
                  if (value == null || value.trim().isEmpty) return 'Informe CNPJ/CPF';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: FincoreColors.textPrimary),
                inputFormatters: FincoreFormatters.telefone,
                decoration: InputDecoration(
                  labelText: 'Telefone / WhatsApp',
                  labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                  prefixIcon: const Icon(Icons.phone_outlined, color: FincoreColors.textMuted),
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
                  if (value == null || value.trim().isEmpty) return 'Informe o telefone';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── ENDEREÇO DO ESTABELECIMENTO COM VIACEP ─────────────────────────
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
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 6),
                  Text('Endereço do Estabelecimento', style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      inputFormatters: FincoreFormatters.cep,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                        prefixIcon: const Icon(Icons.pin_drop_outlined, color: FincoreColors.textMuted, size: 18),
                        suffixIcon: _buscandoCep
                            ? const SizedBox(width: 16, height: 16, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                            : IconButton(
                                icon: Icon(Icons.search_rounded, size: 18, color: FincoreColors.primary),
                                tooltip: 'Buscar CEP',
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
                      onChanged: (v) {
                        if (v.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                          _buscarCep(v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _logradouroController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Rua / Avenida',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _numeroController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Número',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _complementoController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Compl. (opcional)',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _bairroController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Bairro',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: TextFormField(
                      controller: _cidadeController,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Cidade',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _estadoController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: FincoreColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'UF',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
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
          items: ['Food Service', 'Restaurante / Bar', 'Pizzaria / Hamburgueria', 'Padaria / Confeitaria', 'Cafeteria', 'Varejo Geral', 'Outro']
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
