import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';

class BlocoProximasEntregas extends StatelessWidget {
  final DashboardController controller;

  const BlocoProximasEntregas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final entregas = controller.metrics.proximasEntregas;

    final hoje = entregas.where((e) => !e.isAmanha).toList();
    final amanha = entregas.where((e) => e.isAmanha).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximas Entregas',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => FincoreShell.selectTab(context, 'pedidos'),
              icon: const Icon(Icons.calendar_month_outlined, size: 14),
              label: const Text('Abrir Agenda', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: FincoreColors.textSecondary,
                side: const BorderSide(color: FincoreColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final painelHoje = Container(
              padding: const EdgeInsets.all(16),
              height: 220,
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hoje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${hoje.length} agendamento(s)',
                          style: TextStyle(color: FincoreColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: FincoreColors.border),
                  Expanded(
                    child: hoje.isEmpty
                        ? const Center(
                            child: Text('Nenhum agendamento para hoje.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                          )
                        : ListView.separated(
                            itemCount: hoje.length,
                            separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                            itemBuilder: (context, index) {
                              final e = hoje[index];
                              final hora = DateFormat('HH:mm').format(e.dataHora.toLocal());
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hora,
                                      style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.clienteNome,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            e.itensResumo.join(', '),
                                            style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );

            final painelAmanha = Container(
              padding: const EdgeInsets.all(16),
              height: 220,
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amanhã', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${amanha.length} agendamento(s)',
                          style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: FincoreColors.border),
                  Expanded(
                    child: amanha.isEmpty
                        ? const Center(
                            child: Text('Nenhum agendamento para amanhã.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                          )
                        : ListView.separated(
                            itemCount: amanha.length,
                            separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                            itemBuilder: (context, index) {
                              final e = amanha[index];
                              final hora = DateFormat('HH:mm').format(e.dataHora.toLocal());
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Amanhã',
                                      style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      hora,
                                      style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.clienteNome,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            e.itensResumo.join(', '),
                                            style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );

            if (isMobile) {
              return Column(
                children: [
                  painelHoje,
                  const SizedBox(height: 14),
                  painelAmanha,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: painelHoje),
                const SizedBox(width: 14),
                Expanded(child: painelAmanha),
              ],
            );
          },
        ),
      ],
    );
  }
}
