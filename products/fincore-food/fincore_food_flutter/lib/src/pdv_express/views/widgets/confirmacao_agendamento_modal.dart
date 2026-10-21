import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../../controllers/pdv_express_controller.dart';
import '../../../shared/services/whatsapp_service.dart';

enum ConfirmAction {
  finalizar,
  finalizarEImprimir,
  cancelar,
}

/// Resultado da ação de confirmação no PDV
class ConfirmResult {
  final ConfirmAction action;
  final bool enviarWhatsApp;

  const ConfirmResult({
    required this.action,
    this.enviarWhatsApp = false,
  });
}

/// Modal de Confirmação Visual de Agendamento & Entrega
/// Exibido antes de finalizar a venda para garantir que a data, hora,
/// tipo de atendimento e valores estejam corretos.
class ConfirmacaoAgendamentoModal extends StatefulWidget {
  final PdvExpressController controller;

  const ConfirmacaoAgendamentoModal({
    super.key,
    required this.controller,
  });

  /// Método estático utilitário para exibir o modal
  static Future<ConfirmResult?> show(BuildContext context, PdvExpressController controller) {
    return showDialog<ConfirmResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmacaoAgendamentoModal(controller: controller),
    );
  }

  @override
  State<ConfirmacaoAgendamentoModal> createState() => _ConfirmacaoAgendamentoModalState();
}

class _ConfirmacaoAgendamentoModalState extends State<ConfirmacaoAgendamentoModal> {
  late bool _enviarWhatsApp;
  bool _politicaDesativada = false;
  WhatsAppEventPolicy _politicaEvento = WhatsAppEventPolicy.desativado;

  @override
  void initState() {
    super.initState();
    final tel = widget.controller.cliente.telefone;
    final temTelefone = tel != null && tel.isNotEmpty && tel != '00000000000';
    _enviarWhatsApp = false; // Inicia false por padrão até carregar hierarquia
    _carregarPreferenciaEnvio(temTelefone);
  }

  Future<void> _carregarPreferenciaEnvio(bool temTelefone) async {
    try {
      final String? tenantId = widget.controller.tenantContext.hasContext
          ? widget.controller.tenantContext.tenantId
          : null;

      final hierarquia = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tenantId: tenantId,
        empresaUsarWhatsApp: widget.controller.empresaConfig?.usarWhatsApp,
      );

      final cfg = await WhatsAppService.getPdvConfig(tenantId: tenantId);

      if (mounted) {
        setState(() {
          _politicaEvento = hierarquia.politica;
          _politicaDesativada = hierarquia.eventoDesativado;

          // HIERARQUIA ESTRITA:
          // Se o evento estiver desativado nas políticas ou sem telefone, NUNCA marca por padrão!
          if (_politicaDesativada || !temTelefone) {
            _enviarWhatsApp = false;
          } else if (hierarquia.politica == WhatsAppEventPolicy.automatico) {
            _enviarWhatsApp = cfg.enviarWhatsAppPadrao;
          } else {
            // Manual: inicia false, aguardando clique explícito do operador
            _enviarWhatsApp = false;
          }
        });
      }
    } catch (_) {}
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
    final controller = widget.controller;
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
    final taxaServicoFormatada = (entrega.taxaServicoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    
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
        constraints: const BoxConstraints(maxWidth: 580),
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

            // ── Lista Discriminada de Itens do Pedido ─────────────────
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ITENS DO PEDIDO',
                        style: TextStyle(
                          color: FincoreColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final totalQtd = controller.cart.fold<double>(0, (sum, i) => sum + i.quantity);
                          final totalQtdStr = totalQtd % 1 == 0 ? totalQtd.toStringAsFixed(0) : totalQtd.toStringAsFixed(1);
                          return Text(
                            'TOTAL: $totalQtdStr un',
                            style: TextStyle(
                              color: FincoreColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: Color(0xFF2E2E38), height: 1),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: controller.cart.length,
                      separatorBuilder: (c, i) => const Divider(color: Color(0xFF2E2E38), height: 8),
                      itemBuilder: (context, idx) {
                        final item = controller.cart[idx];
                        final qtyStr = item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1);
                        final itemTotalStr = (item.totalInCents / 100).toStringAsFixed(2).replaceAll('.', ',');

                        return Row(
                          children: [
                            Text(
                              '${qtyStr}x',
                              style: TextStyle(
                                color: FincoreColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            Text(
                              'R\$ $itemTotalStr',
                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
                  if (entrega.taxaServicoCentavos > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taxa de Serviço / Mão de Obra:',
                          style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                        ),
                        Text(
                          'R\$ $taxaServicoFormatada',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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

            const SizedBox(height: 16),

            // ── Switch de Envio de Comprovante via WhatsApp ─────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _enviarWhatsApp
                    ? const Color(0xFF25D366).withValues(alpha: 0.12)
                    : const Color(0xFF1E1E28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _enviarWhatsApp
                      ? const Color(0xFF25D366).withValues(alpha: 0.6)
                      : FincoreColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 20,
                    color: _enviarWhatsApp ? const Color(0xFF25D366) : FincoreColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _politicaDesativada
                              ? 'Comprovante via WhatsApp (OFF nas políticas)'
                              : (_politicaEvento == WhatsAppEventPolicy.manual
                                  ? 'Enviar Comprovante via WhatsApp [Manual]'
                                  : 'Enviar Comprovante via WhatsApp [Automático]'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _enviarWhatsApp ? Colors.white : FincoreColors.textSecondary,
                          ),
                        ),
                        if (_politicaDesativada)
                          const Text(
                            'Evento desativado nas configurações de mensageria',
                            style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                          )
                        else if (cliente.telefone != null && cliente.telefone!.isNotEmpty && cliente.telefone != '00000000000')
                          Text(
                            'Para: ${cliente.nome ?? "Cliente"} (${cliente.telefone})',
                            style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                          )
                        else
                          const Text(
                            'Cliente sem telefone cadastrado',
                            style: TextStyle(fontSize: 11, color: Colors.amber),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enviarWhatsApp,
                    onChanged: (cliente.telefone == null ||
                            cliente.telefone!.isEmpty ||
                            cliente.telefone == '00000000000' ||
                            _politicaDesativada)
                        ? null
                        : (val) => setState(() => _enviarWhatsApp = val),
                    activeColor: const Color(0xFF25D366),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Botões de Ação ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: FincoreColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(
                      const ConfirmResult(action: ConfirmAction.cancelar),
                    ),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                    label: const Text(
                      'ALTERAR DADOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E2E3A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: FincoreColors.border),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(
                      ConfirmResult(action: ConfirmAction.finalizar, enviarWhatsApp: _enviarWhatsApp),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.amber),
                    label: const Text(
                      'FINALIZAR PEDIDO',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(
                      ConfirmResult(action: ConfirmAction.finalizarEImprimir, enviarWhatsApp: _enviarWhatsApp),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'FINALIZAR &\nIMPRIMIR',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, height: 1.1),
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
