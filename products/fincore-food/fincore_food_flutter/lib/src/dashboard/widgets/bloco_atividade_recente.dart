import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/estoque/views/producao_page.dart';
import '../controllers/dashboard_controller.dart';

class BlocoAtividadeRecente extends StatelessWidget {
  final DashboardController controller;

  const BlocoAtividadeRecente({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.metrics;
    final concluidas = m.producoesConcluidasHoje;
    final criados = m.planejamentosCriadosHoje;
    final parciais = m.producoesParciaisHoje;

    // Se não houver nenhuma atividade, não mostrar a seção.
    if (concluidas == 0 && criados == 0 && parciais == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Recente',
          style: TextStyle(
            color: FincoreColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (concluidas > 0)
                _buildActivityRow(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: FincoreColors.success,
                  text: '$concluidas produç${concluidas > 1 ? 'ões concluídas' : 'ão concluída'} hoje',
                ),
              if (criados > 0) ...[
                if (concluidas > 0) const SizedBox(height: 10),
                _buildActivityRow(
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: FincoreColors.primary,
                  text: '$criados planejamento${criados > 1 ? 's criados' : ' criado'} hoje',
                ),
              ],
              if (parciais > 0) ...[
                if (concluidas > 0 || criados > 0) const SizedBox(height: 10),
                _buildActivityRow(
                  icon: Icons.pending_actions_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  text: '$parciais produç${parciais > 1 ? 'ões parciais' : 'ão parcial'}',
                ),
              ],
              const Divider(height: 24, color: FincoreColors.border),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ProducaoPage.initialTab = 0; // Primeira aba com as campanhas
                    FincoreShell.selectTab(context, 'producao');
                  },
                  icon: const Icon(Icons.history_rounded, size: 14),
                  label: const Text('Ver Histórico', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FincoreColors.textSecondary,
                    side: const BorderSide(color: FincoreColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: FincoreColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
