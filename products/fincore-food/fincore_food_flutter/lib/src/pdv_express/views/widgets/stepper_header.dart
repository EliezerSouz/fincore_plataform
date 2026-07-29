import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../controllers/pdv_express_controller.dart';

/// StepperHeader do PDV Express.
///
/// Exibe as 3 etapas do fluxo de venda com:
/// - Indicador numérico circular com cor ativa/inativa
/// - Texto da etapa com peso de fonte dinâmico
/// - Linha divisória colorida conforme progresso
/// - Borda de foco Laranja Forno 2px na etapa corrente (PRD-006)
/// - Feedback de atalho de teclado [F1], [F2], [F3] visível abaixo do rótulo
class StepperHeader extends StatelessWidget {
  final PdvExpressController controller;

  const StepperHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final etapas = [
      _StepInfo(label: 'Cliente & Entrega', shortcut: 'F2'),
      _StepInfo(label: 'Seleção de Produtos', shortcut: 'F1'),
      _StepInfo(label: 'Forma de Pagamento', shortcut: 'F3'),
    ];
    final passoAtual = controller.passoAtual;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        children: List.generate(etapas.length, (index) {
          final ativo    = index <= passoAtual;
          final corrente = index == passoAtual;
          final etapa    = etapas[index];

          return Expanded(
            child: Row(
              children: [
                // ── Indicador Circular da Etapa ─────────────────────
                GestureDetector(
                  onTap: () => controller.setPassoAtual(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: corrente
                          ? FincoreColors.primary
                          : (ativo
                              ? FincoreColors.primary.withValues(alpha: 0.2)
                              : FincoreColors.border),
                      // Borda Laranja Forno 2px na etapa corrente (PRD-006)
                      border: Border.all(
                        color: corrente
                            ? FincoreColors.primary
                            : (ativo ? FincoreColors.primary : Colors.transparent),
                        width: corrente ? 2.0 : 1.5,
                      ),
                      // Glow sutil na etapa ativa
                      boxShadow: corrente
                          ? [
                              BoxShadow(
                                color: FincoreColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: (corrente || ativo) ? Colors.white : FincoreColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ── Rótulo da Etapa com atalho de teclado ────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setPassoAtual(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          etapa.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: corrente ? FontWeight.bold : FontWeight.normal,
                            color: corrente
                                ? FincoreColors.textPrimary
                                : (ativo
                                    ? FincoreColors.textSecondary
                                    : FincoreColors.textMuted),
                            fontSize: 12.5,
                          ),
                        ),
                        // Atalho de teclado visível abaixo do rótulo
                        Text(
                          '[${etapa.shortcut}]',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: corrente
                                ? FincoreColors.primary
                                : FincoreColors.textMuted,
                            fontWeight: corrente ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Linha de Progresso entre etapas ──────────────────
                if (index < etapas.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        decoration: BoxDecoration(
                          color: ativo
                              ? FincoreColors.primary.withValues(alpha: 0.6)
                              : FincoreColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepInfo {
  final String label;
  final String shortcut;
  const _StepInfo({required this.label, required this.shortcut});
}
