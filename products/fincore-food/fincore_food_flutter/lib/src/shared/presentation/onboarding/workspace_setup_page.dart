import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/usecase/tenant/calcular_progresso_setup_usecase.dart';

class WorkspaceSetupPage extends StatefulWidget {
  final AuthUserInfo authUserInfo;
  final VoidCallback onFinishSetup;
  final VoidCallback onLogout;

  const WorkspaceSetupPage({
    super.key,
    required this.authUserInfo,
    required this.onFinishSetup,
    required this.onLogout,
  });

  @override
  State<WorkspaceSetupPage> createState() => _WorkspaceSetupPageState();
}

class _WorkspaceSetupPageState extends State<WorkspaceSetupPage> {
  WorkspaceSetupProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final useCase = CalcularProgressoSetupUseCase(db: db);
      final progress = await useCase.execute(widget.authUserInfo.tenantId!);
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao obter setup progress local: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F11),
        body: Center(child: CircularProgressIndicator(color: FincoreColors.primary)),
      );
    }

    final checklist = _progress?.checklist ?? <String, bool>{};

    final percentual = _progress?.percentual ?? 0.0;

    String vencimentoText = 'Período de testes ativo';
    if (widget.authUserInfo.vencimento != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(widget.authUserInfo.vencimento!);
      vencimentoText = 'Acesso ativo até: $formattedDate';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Stack(
        children: [
          // 1. Esfera de Luz de Fundo
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FincoreColors.primary.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FincoreColors.accent.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 2. Conteúdo Principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                decoration: BoxDecoration(
                  color: FincoreColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: FincoreColors.border.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho da Marca com Logo 3D Oficial
                    Center(
                      child: Image.asset(
                        'assets/images/app_launcher_icon.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'BEM-VINDO AO FINCORE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seu negócio. Mais simples.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FincoreColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card de Vencimento / Pagamento
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: FincoreColors.background.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FincoreColors.border.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card_outlined, color: FincoreColors.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vencimentoText,
                              style: const TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (widget.authUserInfo.vencimento != null) 
                                  ? FincoreColors.success.withValues(alpha: 0.15) 
                                  : FincoreColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              (widget.authUserInfo.vencimento != null) ? 'LICENÇA ATIVA' : 'TESTE ATIVO',
                              style: TextStyle(
                                color: (widget.authUserInfo.vencimento != null) 
                                    ? FincoreColors.success 
                                    : FincoreColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Barra de Progresso
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Passos de Configuração',
                          style: TextStyle(
                            color: FincoreColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${percentual.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: FincoreColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: percentual / 100,
                      backgroundColor: FincoreColors.border,
                      valueColor: AlwaysStoppedAnimation(FincoreColors.primary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 32),

                    // Lista de Checklist
                    _buildChecklistItem(
                      label: 'Criar espaço de trabalho (Empresa)',
                      isCompleted: checklist['empresa_criada'] ?? false,
                    ),
                    _buildChecklistItem(
                      label: 'Aprovação e ativação de conta',
                      isCompleted: checklist['conta_ativa'] ?? false,
                    ),
                    _buildChecklistItem(
                      label: 'Realizar o primeiro login',
                      isCompleted: checklist['login_realizado'] ?? false,
                    ),
                    _buildChecklistItem(
                      label: 'Cadastrar categorias de produtos',
                      isCompleted: checklist['categorias_cadastradas'] ?? false,
                      actionLabel: 'Cadastrar Categorias',
                    ),
                    _buildChecklistItem(
                      label: 'Cadastrar primeiros produtos',
                      isCompleted: checklist['produtos_cadastrados'] ?? false,
                      actionLabel: 'Cadastrar Produtos',
                    ),
                    _buildChecklistItem(
                      label: 'Cadastrar clientes',
                      isCompleted: checklist['clientes_cadastrados'] ?? false,
                      actionLabel: 'Cadastrar Clientes',
                    ),
                    _buildChecklistItem(
                      label: 'Realizar a primeira venda no PDV',
                      isCompleted: checklist['venda_realizada'] ?? false,
                      actionLabel: 'Abrir PDV',
                    ),

                    const SizedBox(height: 32),
                    
                    // Botão Finalizar
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('fincore_setup_completed_${widget.authUserInfo.tenantId}', true);
                        widget.onFinishSetup();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: FincoreColors.primary.withValues(alpha: 0.2),
                      ),
                      child: const Text(
                        'IR PARA O PAINEL PRINCIPAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    TextButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sair da Conta'),
                      style: TextButton.styleFrom(
                        foregroundColor: FincoreColors.danger,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required bool isCompleted,
    String? actionLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FincoreColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? FincoreColors.success.withValues(alpha: 0.3)
              : FincoreColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isCompleted ? FincoreColors.success : FincoreColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isCompleted ? FincoreColors.textMuted : FincoreColors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontSize: 13,
                fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
          if (!isCompleted && actionLabel != null)
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('fincore_setup_completed_${widget.authUserInfo.tenantId}', true);
                widget.onFinishSetup();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: FincoreColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
