import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/app_database.dart';
import '../../../design_system/colors.dart';

class AlertaNotificacao {
  final String id;
  final String titulo;
  final String mensagem;
  final String tipo; // 'PIX', 'Estoque', 'Atraso', 'Producao', 'Cancelado', 'VIP'
  final String urgencia; // 'Alta' (Crítico), 'Media' (Atenção), 'Baixa' (Informativo)
  final DateTime data;
  final VoidCallback? onAction;
  final String? actionText;

  AlertaNotificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.urgencia,
    required this.data,
    this.onAction,
    this.actionText,
  });
}

class CentralNotificacoesWidget extends StatefulWidget {
  final List<AlertaNotificacao> alertas;
  final VoidCallback? onRefresh;

  const CentralNotificacoesWidget({
    super.key,
    required this.alertas,
    this.onRefresh,
  });

  @override
  State<CentralNotificacoesWidget> createState() => _CentralNotificacoesWidgetState();
}

class _CentralNotificacoesWidgetState extends State<CentralNotificacoesWidget> {
  String _filtroCategoria = 'Todos'; // 'Todos', 'Criticos', 'Atencao', 'Informativo'

  Color _getUrgenciaColor(String urgencia) {
    switch (urgencia) {
      case 'Alta':
        return Colors.red.shade700;
      case 'Media':
        return Colors.orange.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'PIX':
        return Icons.pix;
      case 'Estoque':
        return Icons.inventory_2_outlined;
      case 'Atraso':
        return Icons.alarm;
      case 'Producao':
        return Icons.restaurant;
      case 'VIP':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticos = widget.alertas.where((a) => a.urgencia == 'Alta').toList();
    final atencao = widget.alertas.where((a) => a.urgencia == 'Media').toList();
    final informativo = widget.alertas.where((a) => a.urgencia == 'Baixa').toList();

    List<AlertaNotificacao> filtrados = widget.alertas;
    if (_filtroCategoria == 'Criticos') {
      filtrados = criticos;
    } else if (_filtroCategoria == 'Atencao') {
      filtrados = atencao;
    } else if (_filtroCategoria == 'Informativo') {
      filtrados = informativo;
    }

    if (widget.alertas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operação Redonda!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 14),
                  ),
                  Text(
                    'Nenhum alerta crítico ou atraso pendente de atenção no momento.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Centro de Alertas Operacionais',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.alertas.length}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (widget.onRefresh != null)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                        onPressed: widget.onRefresh,
                        tooltip: 'Atualizar Alertas',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Categorias Filtro Chips: Crítico, Atenção, Informativo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _filtroCategoria == 'Todos',
                        label: Text('Todos (${widget.alertas.length})'),
                        onSelected: (_) => setState(() => _filtroCategoria = 'Todos'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filtroCategoria == 'Criticos',
                        avatar: CircleAvatar(backgroundColor: Colors.red.shade700, radius: 4),
                        label: Text('🔴 Críticos (${criticos.length})'),
                        onSelected: (_) => setState(() => _filtroCategoria = 'Criticos'),
                        selectedColor: Colors.red.shade50,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filtroCategoria == 'Atencao',
                        avatar: CircleAvatar(backgroundColor: Colors.orange.shade700, radius: 4),
                        label: Text('🟠 Atenção (${atencao.length})'),
                        onSelected: (_) => setState(() => _filtroCategoria = 'Atencao'),
                        selectedColor: Colors.orange.shade50,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filtroCategoria == 'Informativo',
                        avatar: CircleAvatar(backgroundColor: Colors.blue.shade700, radius: 4),
                        label: Text('🔵 Informativos (${informativo.length})'),
                        onSelected: (_) => setState(() => _filtroCategoria = 'Informativo'),
                        selectedColor: Colors.blue.shade50,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Nenhum alerta nesta categoria.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtrados.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final a = filtrados[idx];
                final uColor = _getUrgenciaColor(a.urgencia);

                return Container(
                  padding: const EdgeInsets.all(14),
                  color: a.urgencia == 'Alta' ? Colors.red.shade50.withOpacity(0.3) : Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de Horário estilo Timeline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: uColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: uColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(a.data),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: uColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: uColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getTipoIcon(a.tipo), color: uColor, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  a.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.mensagem,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (a.actionText != null && a.onAction != null) ...[
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: a.onAction,
                                child: Text(
                                  a.actionText!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: uColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
