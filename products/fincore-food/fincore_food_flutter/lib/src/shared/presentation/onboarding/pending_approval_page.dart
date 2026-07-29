import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/main.dart';

class PendingApprovalPage extends StatefulWidget {
  final String tenantId;
  final VoidCallback onApproved;
  final VoidCallback onLogout;

  const PendingApprovalPage({
    super.key,
    required this.tenantId,
    required this.onApproved,
    required this.onLogout,
  });

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage>
    with SingleTickerProviderStateMixin {
  Timer? _pollingTimer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _startPolling();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final status = await client.onboarding.status();
        if (status == 'ativo') {
          timer.cancel();
          widget.onApproved();
        }
      } catch (e) {
        debugPrint('Erro no polling: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Stack(
        children: [
          // 1. Esfera de Luz 1 (Fundo)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FincoreColors.primary.withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // 2. Esfera de Luz 2 (Fundo)
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FincoreColors.accent.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 3. Conteúdo Centralizado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                decoration: BoxDecoration(
                  color: FincoreColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: FincoreColors.border.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animação de Órbita e Pulso
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Anel Rotativo com Gradiente
                        RotationTransition(
                          turns: _rotateAnimation,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: FincoreColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: FincoreColors.primary,
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: FincoreColors.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: FincoreColors.accent,
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Icone Pulsante Central
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: FincoreColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FincoreColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              size: 40,
                              color: FincoreColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Bem-vindo ao FINCORE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Seu negócio. Mais simples.',
                      style: TextStyle(
                        color: FincoreColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Estamos preparando tudo para você. Em breve, sua operação, gestão e resultados estarão conectados em um único lugar — simples, inteligente e feito para o seu negócio crescer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⏳ ', style: TextStyle(fontSize: 16)),
                        Text(
                          'Aprovação em andamento',
                          style: TextStyle(
                            color: FincoreColors.warning,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    FincoreShimmerLine(width: double.infinity, height: 2),
                    const SizedBox(height: 32),
                    
                    // Botão Verificar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final status = await client.onboarding.status();
                          if (status == 'ativo') {
                            widget.onApproved();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sua conta ainda está aguardando ativação.'),
                                backgroundColor: FincoreColors.surface,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FincoreColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: FincoreColors.primary.withOpacity(0.3),
                        ),
                        child: const Text(
                          'VERIFICAR STATUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Link de suporte por email/contato
                    Column(
                      children: [
                        const Text(
                          'Precisa de liberação rápida?',
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Suporte notificado! Entraremos em contato.'),
                                backgroundColor: FincoreColors.success,
                              ),
                            );
                          },
                          child: const Text(
                            'Entrar em contato com o suporte',
                            style: TextStyle(
                              color: FincoreColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
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
}
