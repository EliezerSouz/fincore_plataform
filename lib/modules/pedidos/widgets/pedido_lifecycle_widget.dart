import 'package:flutter/material.dart';
import '../../../design_system/colors.dart';

class PedidoLifecycleWidget extends StatelessWidget {
  final String status;
  final String statusFinanceiro;
  final String tipoEntrega; // 'Balcão', 'Entrega', 'Retirada'

  const PedidoLifecycleWidget({
    super.key,
    required this.status,
    this.statusFinanceiro = 'Pendente',
    this.tipoEntrega = 'Entrega',
  });

  int _getStepIndex() {
    if (status == 'Cancelado') return -1;
    if (status == 'Finalizado') return 5;
    if (status == 'Em Rota') return 4;
    if (status == 'Pronto') return 3;
    if (status == 'Em Preparo') return 2;
    if (statusFinanceiro == 'Pago' || statusFinanceiro == 'Confirmado') return 1;
    return 0; // Criado / Pendente
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'Cancelado') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido Cancelado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'A linha de vida foi interrompida.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final activeStep = _getStepIndex();

    final steps = [
      _LifecycleStep(
        title: 'Criado',
        subtitle: 'Registrado',
        icon: Icons.receipt_long,
      ),
      _LifecycleStep(
        title: 'Pagamento',
        subtitle: statusFinanceiro == 'Pago' ? 'PIX Confirmado' : 'Aguardando PIX',
        icon: Icons.pix,
        isWarning: statusFinanceiro != 'Pago',
      ),
      _LifecycleStep(
        title: 'Produção',
        subtitle: 'Cozinha',
        icon: Icons.restaurant_menu,
      ),
      _LifecycleStep(
        title: 'Pronto',
        subtitle: 'Embalado',
        icon: Icons.check_circle_outline,
      ),
      _LifecycleStep(
        title: tipoEntrega.contains('Retirada') ? 'Aguardando' : 'Em Rota',
        subtitle: tipoEntrega.contains('Retirada') ? 'Cliente Retira' : 'Saiu Entrega',
        icon: tipoEntrega.contains('Retirada') ? Icons.storefront : Icons.local_shipping,
      ),
      _LifecycleStep(
        title: 'Entregue',
        subtitle: 'Finalizado',
        icon: Icons.task_alt,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Linha de Vida do Pedido (Lifecycle)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Etapa ${activeStep + 1} de ${steps.length}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 520,
              child: Row(
                children: List.generate(steps.length, (i) {
              final step = steps[i];
              final isPassed = i < activeStep;
              final isCurrent = i == activeStep;

              Color circleColor = Colors.grey.shade300;
              Color iconColor = Colors.grey.shade600;
              if (isPassed) {
                circleColor = Colors.green.shade600;
                iconColor = Colors.white;
              } else if (isCurrent) {
                circleColor = step.isWarning ? Colors.amber.shade700 : AppColors.primary;
                iconColor = Colors.white;
              }

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: circleColor.withAlpha(100),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isPassed ? Icons.check : step.icon,
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent || isPassed ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 20),
                          color: i < activeStep ? Colors.green.shade600 : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ],
  ),
);
  }
}

class _LifecycleStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isWarning;

  _LifecycleStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isWarning = false,
  });
}
