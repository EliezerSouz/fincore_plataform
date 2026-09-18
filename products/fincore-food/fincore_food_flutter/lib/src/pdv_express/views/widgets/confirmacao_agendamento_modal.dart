import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../controllers/pdv_express_controller.dart';

/// Modal de Confirmação Visual de Agendamento & Entrega
/// Exibido antes de finalizar a venda para garantir que a data, hora,
/// tipo de atendimento e valores estejam corretos.
class ConfirmacaoAgendamentoModal extends StatelessWidget {
  final PdvExpressController controller;

  const ConfirmacaoAgendamentoModal({
    super.key,
    required this.controller,
  });

  /// Método estático utilitário para exibir o modal
  static Future<bool?> show(BuildContext context, PdvExpressController controller) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmacaoAgendamentoModal(controller: controller),
    );
  }

  String _getDiaDaSemanaFormatado(DateTime dt) {
    const dias = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return dias[(dt.weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final entrega = controller.entrega;
    final cliente = controller.cliente;
    final dataHora = entrega.dataHora;

    final dataStr =
        '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}';
    final horaStr =
        '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
    final diaSemana = _getDiaDaSemanaFormatado(dataHora);

    final isEntrega = entrega.tipo == 'Entrega';
    final isMesa = entrega.tipo == 'Mesa';

    final totalCentavos = controller.totalInCents;
    final totalFormatado = (totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    final taxaFormatada = (entrega.taxaEntregaCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    
    final int? trocoCentavos = (entrega.trocoParaCentavos != null && entrega.trocoParaCentavos! > totalCentavos)
        ? (entrega.trocoParaCentavos! - totalCentavos)
        : null;
    final trocoFormatado = trocoCentavos != null ? (trocoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',') : null;

    return Dialog(
      backgroundColor: const Color(0xFF16161A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: FincoreColors.primary, width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho do Modal ──────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FincoreColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: FincoreColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONFIRMAÇÃO DE AGENDAMENTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Revise a data, horário e dados antes de enviar para a produção',
                        style: TextStyle(
                          color: FincoreColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFF2E2E38), height: 1),
            const SizedBox(height: 20),

            // ── Card de Destaque da Data e Hora ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FincoreColors.primary.withValues(alpha: 0.2),
                    const Color(0xFF1E1E28),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_filled_rounded, color: FincoreColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'PREVISTO PARA: $dataStr AS $horaStr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diaSemana.toUpperCase(),
                    style: TextStyle(
                      color: FincoreColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badge do Tipo de Atendimento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isEntrega
                              ? Colors.orange.withValues(alpha: 0.2)
                              : isMesa
                                  ? Colors.purple.withValues(alpha: 0.2)
                                  : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEntrega
                                ? Colors.orange
                                : isMesa
                                    ? Colors.purpleAccent
                                    : Colors.blueAccent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEntrega
                                  ? Icons.two_wheeler_outlined
                                  : isMesa
                                      ? Icons.table_restaurant_outlined
                                      : Icons.storefront_outlined,
                              size: 14,
                              color: isEntrega
                                  ? Colors.orange
                                  : isMesa
                                      ? Colors.purpleAccent
                                      : Colors.blueAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entrega.tipo.toUpperCase(),
                              style: TextStyle(
                                color: isEntrega
                                    ? Colors.orange
                                    : isMesa
                                        ? Colors.purpleAccent
                                        : Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entrega.prioridade.isNotEmpty && entrega.prioridade != 'Normal') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Text(
                            entrega.prioridade.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Detalhes do Cliente e Endereço ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: FincoreColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        cliente.nome?.isNotEmpty == true ? cliente.nome! : 'Cliente Consumidor Final',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (cliente.telefone?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${cliente.telefone})',
                          style: const TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isEntrega) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.orangeAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (entrega.logradouro.isNotEmpty) entrega.logradouro,
                              if (entrega.numero.isNotEmpty) 'Nº ${entrega.numero}',
                              if (entrega.bairro.isNotEmpty) 'Bairro ${entrega.bairro}',
                              if (entrega.cidade.isNotEmpty) entrega.cidade,
                            ].join(', '),
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (entrega.referencia.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 22),
                        child: Text(
                          'Ref: ${entrega.referencia}',
                          style: const TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ] else if (isMesa) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mesa/Comanda: ${entrega.mesa.isNotEmpty ? entrega.mesa : "Não informada"}'
                      '${entrega.garcom.isNotEmpty ? " | Garçom: ${entrega.garcom}" : ""}',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Resumo Financeiro e Forma de Pagamento ─────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Forma de Pagamento:',
                        style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                      ),
                      Text(
                        controller.paymentMethod,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (isEntrega && entrega.taxaEntregaCentavos > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taxa de Entrega:',
                          style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                        ),
                        Text(
                          'R\$ $taxaFormatada',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  if (trocoFormatado != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Troco para o Cliente:',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$ $trocoFormatado',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFF2E2E38), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL DO PEDIDO:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'R\$ $totalFormatado',
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botões de Ação ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: FincoreColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: const Text(
                      'ALTERAR DADOS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'CONFIRMAR & FINALIZAR ⚡',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
