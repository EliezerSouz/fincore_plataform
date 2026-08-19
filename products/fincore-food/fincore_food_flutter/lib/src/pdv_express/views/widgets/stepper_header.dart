import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../controllers/pdv_express_controller.dart';

/// StepperHeader do PDV Express conforme Mockup Original (1-Cliente --- 2-Produtos --- 3-Pagamento)
class StepperHeader extends StatelessWidget {
  final PdvExpressController controller;

  const StepperHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final etapas = [
      _StepInfo(number: 1, label: '1  Cliente & Entrega'),
      _StepInfo(number: 2, label: '2  Produtos'),
      _StepInfo(number: 3, label: '3  Pagamento & Confirmação'),
    ];
    final passoAtual = controller.passoAtual;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(etapas.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Linha Conectora entre Etapas
            final stepBeforeIndex = i ~/ 2;
            final isCompleted = stepBeforeIndex < passoAtual;
            return Container(
              width: 24,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? FincoreColors.primary
                    : FincoreColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final isCurrent = stepIndex == passoAtual;
          final isPast = stepIndex < passoAtual;
          final step = etapas[stepIndex];

          return GestureDetector(
            onTap: () => controller.setPassoAtual(stepIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? FincoreColors.primary
                    : (isPast
                        ? FincoreColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCurrent
                      ? FincoreColors.primary
                      : (isPast ? FincoreColors.primary : Colors.transparent),
                  width: 1.5,
                ),
              ),
              child: Text(
                step.label,
                style: TextStyle(
                  color: isCurrent
                      ? Colors.white
                      : (isPast
                          ? FincoreColors.primary
                          : FincoreColors.textSecondary),
                  fontWeight: isCurrent || isPast
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
  }
}

class _StepInfo {
  final int number;
  final String label;
  const _StepInfo({required this.number, required this.label});
}

