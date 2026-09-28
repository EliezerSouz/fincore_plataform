import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:fincore_core/context/tenant_context.dart';
import '../../services/whatsapp_service.dart';

/// Informações de PIX para exibição no card separado do WhatsAppDialog.
/// Gerado pelo PixGenerator e passado pelo caller (PDV Express ou Kanban).
class PixWhatsAppInfo {
  /// Chave legível para exibição (ex: "(11) 99999-8888", "email@...", CPF mascarado)
  final String chaveDisplay;

  /// Tipo da chave (ex: "Telefone", "CPF", "CNPJ", "E-mail", "Aleatória")
  final String tipoChave;

  /// Payload EMV completo (Copia e Cola) — gerado pelo PixGenerator
  final String copiaECola;

  const PixWhatsAppInfo({
    required this.chaveDisplay,
    required this.tipoChave,
    required this.copiaECola,
  });
}

/// Modal Oficial e Inteligente de Disparo de Mensagens via WhatsApp
/// Suporta card de PIX com QR Code inline e chave copiável em seção separada.
class WhatsAppDialog extends StatefulWidget {
  final String rawPhone;
  final String clienteNome;
  final String? initialMessage;
  final String? enderecoCliente;
  final String? nomeEmpresa;

  /// Informações PIX para exibição no card copiável (opcional).
  /// Quando fornecido, exibe seção de PIX com QR Code e botão de cópia.
  final PixWhatsAppInfo? pixInfo;

  /// ID amigável do pedido (ex: "#000142") — usado nos templates rápidos.
  final String? numeroPedido;

  const WhatsAppDialog({
    super.key,
    required this.rawPhone,
    required this.clienteNome,
    this.initialMessage,
    this.enderecoCliente,
    this.nomeEmpresa,
    this.pixInfo,
    this.numeroPedido,
  });

  /// Abre o modal de WhatsApp
  static Future<bool?> show(
    BuildContext context, {
    required String rawPhone,
    required String clienteNome,
    String? initialMessage,
    String? enderecoCliente,
    String? nomeEmpresa,
    PixWhatsAppInfo? pixInfo,
    String? numeroPedido,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsAppDialog(
        rawPhone: rawPhone,
        clienteNome: clienteNome,
        initialMessage: initialMessage,
        enderecoCliente: enderecoCliente,
        nomeEmpresa: nomeEmpresa,
        pixInfo: pixInfo,
        numeroPedido: numeroPedido,
      ),
    );
  }

  @override
  State<WhatsAppDialog> createState() => _WhatsAppDialogState();
}

class _WhatsAppDialogState extends State<WhatsAppDialog> {
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  late bool _comNonoDigito;
  bool _enviando = false;
  bool _pixCardExpanded = true;

  String get _clienteNomeLimpo {
    return widget.clienteNome.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  String get _resolvedNomeEmpresa {
    if (widget.nomeEmpresa != null && widget.nomeEmpresa!.isNotEmpty) {
      return widget.nomeEmpresa!;
    }
    try {
      if (TenantContext().hasContext) {
        final fant = TenantContext().empresa.nomeFantasia;
        if (fant.isNotEmpty) return fant;
        final raz = TenantContext().empresa.razaoSocial;
        if (raz.isNotEmpty) return raz;
      }
    } catch (_) {}
    return 'Nossa Loja';
  }

  @override
  void initState() {
    super.initState();

    final ehFixo = WhatsAppService.isTelefoneFixo(widget.rawPhone);
    _comNonoDigito = !ehFixo;

    final initialPhoneFormatted = WhatsAppService.formatarExibicao(
      rawPhone: widget.rawPhone,
      comNonoDigito: _comNonoDigito,
    );

    _phoneController = TextEditingController(text: initialPhoneFormatted);

    final empresa = _resolvedNomeEmpresa;
    final nome = _clienteNomeLimpo;

    // Usa initialMessage se fornecido (comprovante PDV), senão saudação padrão calorosa
    final defaultMessage = widget.initialMessage ??
        // \u{1F44B}=👋 \u{1F60A}=😊 \u{2728}=✨ \u{1F680}=🚀
        '\u{1F44B} *Ol\u00E1, $nome!* Tudo bem? \u{1F60A}\n\n'
        'Aqui \u00E9 da equipe da *$empresa*! \u{2728}\n'
        'Passando para saber se voc\u00EA gostaria de fazer um novo pedido ou se precisa de alguma ajuda hoje?\n\n'
        'Estamos \u00E0 sua total disposi\u00E7\u00E3o! \u{1F680}';

    _messageController = TextEditingController(text: defaultMessage);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onToggleNonoDigito(bool com9) {
    setState(() {
      _comNonoDigito = com9;
      final currentRaw = _phoneController.text;
      _phoneController.text = WhatsAppService.formatarExibicao(
        rawPhone: currentRaw,
        comNonoDigito: _comNonoDigito,
      );
    });
  }

  void _setTemplate(String template) {
    setState(() {
      _messageController.text = template;
    });
  }

  Future<void> _copiarTexto() async {
    final texto = _messageController.text;
    if (texto.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FincoreColors.surfaceElevated,
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: FincoreColors.success, size: 18),
              SizedBox(width: 8),
              Text('Mensagem copiada!',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copiarPixCopiaECola() async {
    if (widget.pixInfo == null) return;
    await Clipboard.setData(ClipboardData(text: widget.pixInfo!.copiaECola));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Row(
            children: const [
              Icon(Icons.pix, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Chave PIX (Copia e Cola) copiada!',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _enviar() async {
    final rawPhone = _phoneController.text;
    final digitos = WhatsAppService.sanitizarTelefone(rawPhone);

    if (digitos.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          content: Text('Por favor, informe um número de telefone com DDD válido.'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final ok = await WhatsAppService.abrirConversa(
        rawPhone: rawPhone,
        comNonoDigito: _comNonoDigito,
        mensagem: _messageController.text,
      );

      if (mounted) {
        if (ok) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: FincoreColors.danger,
              content: Text(
                  'Não foi possível abrir o WhatsApp. Verifique se o navegador ou app está disponível.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Erro ao acionar WhatsApp: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ── PIX Card com QR Code ─────────────────────────────────────────────────

  Widget _buildPixCard() {
    final pix = widget.pixInfo!;
    const pixGreen = Color(0xFF32BCAD); // Cor oficial do PIX (Bacen)

    return Container(
      decoration: BoxDecoration(
        color: pixGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pixGreen.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header expansível do card PIX
          InkWell(
            onTap: () => setState(() => _pixCardExpanded = !_pixCardExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.pix, color: Color(0xFF32BCAD), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHAVE PIX',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF32BCAD),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${pix.tipoChave}: ${pix.chaveDisplay}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: FincoreColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _pixCardExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: FincoreColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expansível
          if (_pixCardExpanded) ...[
            const Divider(height: 1, color: Color(0xFF32BCAD), indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QR Code visual (usando CustomPaint para compatibilidade sem qr_flutter)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _PixQrCodePainter(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Coluna direita: chave + botão copiar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip do tipo de chave
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF32BCAD).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF32BCAD).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            pix.tipoChave.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF32BCAD),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Chave exibida
                        Text(
                          pix.chaveDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Payload completo gerado (Copia e Cola)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FincoreColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Botão copiar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _copiarPixCopiaECola,
                            icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                            label: const Text(
                              'Copiar Copia e Cola',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF32BCAD),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Dica
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF38BDF8)),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Copie a chave e envie como 2ª mensagem no WhatsApp, ou o cliente pode escanear o QR Code diretamente.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF94A3B8),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const whatsappGreen = Color(0xFF25D366);
    final temPix = widget.pixInfo != null;
    final numPedido = widget.numeroPedido ?? '---';

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FincoreColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 620,
        constraints: BoxConstraints(maxHeight: temPix ? 820 : 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: FincoreColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(bottom: BorderSide(color: FincoreColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: whatsappGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: whatsappGreen.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.chat_rounded, color: whatsappGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversa no WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.clienteNome.isNotEmpty ? widget.clienteNome : 'Cliente',
                          style: const TextStyle(
                            fontSize: 13,
                            color: FincoreColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (temPix)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF32BCAD).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF32BCAD).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pix, size: 12, color: Color(0xFF32BCAD)),
                          SizedBox(width: 4),
                          Text(
                            'PIX',
                            style: TextStyle(
                              color: Color(0xFF32BCAD),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: FincoreColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(false),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Card PIX (se houver) ──────────────────────
                    if (temPix) ...[
                      _buildPixCard(),
                      const SizedBox(height: 16),
                    ],

                    // Seletor de Formato do Número (Com 9 vs Sem 9)
                    const Text(
                      'TIPO DO NÚMERO / 9º DÍGITO:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _onToggleNonoDigito(true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _comNonoDigito
                                    ? whatsappGreen.withValues(alpha: 0.12)
                                    : FincoreColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _comNonoDigito ? whatsappGreen : FincoreColors.border,
                                  width: _comNonoDigito ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_android_rounded,
                                    size: 18,
                                    color: _comNonoDigito ? whatsappGreen : FincoreColors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Celular (com 9)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: _comNonoDigito ? FontWeight.bold : FontWeight.w500,
                                      color: _comNonoDigito ? Colors.white : FincoreColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _onToggleNonoDigito(false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: !_comNonoDigito
                                    ? whatsappGreen.withValues(alpha: 0.12)
                                    : FincoreColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_comNonoDigito ? whatsappGreen : FincoreColors.border,
                                  width: !_comNonoDigito ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 18,
                                    color: !_comNonoDigito ? whatsappGreen : FincoreColors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fixo / Antigo (sem 9)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: !_comNonoDigito ? FontWeight.bold : FontWeight.w500,
                                      color: !_comNonoDigito ? Colors.white : FincoreColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Campo de Telefone Editável
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TelefoneInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Número do WhatsApp',
                        labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.dialpad_rounded, size: 18, color: FincoreColors.textMuted),
                        filled: true,
                        fillColor: FincoreColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: whatsappGreen, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Banner Informativo
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF38BDF8)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dica: Se o WhatsApp informar que o número não existe, altere para "Sem 9" (números fixos comerciais ou contas antigas não possuem o nono dígito).',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mensagens Rápidas (Templates)
                    const Text(
                      'MENSAGENS RÁPIDAS:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Saudação padrão (com número de pedido quando disponível)
                        ActionChip(
                          avatar: const Icon(Icons.waving_hand_rounded, size: 14, color: Colors.amber),
                          label: const Text('Saudação Padrão', style: TextStyle(fontSize: 11.5)),
                          backgroundColor: FincoreColors.surfaceElevated,
                          side: const BorderSide(color: FincoreColors.border),
                          onPressed: () {
                            final pedidoStr = widget.numeroPedido != null
                                ? ' referente ao seu pedido *$numPedido*'
                                : '';
                            _setTemplate(
                              // \u{1F44B}=👋 \u{1F60A}=😊 \u{2728}=✨ \u{1F680}=🚀
                              '\u{1F44B} *Ol\u00E1, $_clienteNomeLimpo!* Tudo bem? \u{1F60A}\n\n'
                              'Aqui \u00E9 da equipe da *$_resolvedNomeEmpresa*! \u{2728}\n'
                              'Passando para falar com voc\u00EA$pedidoStr e ver como posso te ajudar.\n\n'
                              'Estamos \u00E0 sua total disposi\u00E7\u00E3o! \u{1F680}',
                            );
                          },
                        ),
                        // Contato sobre Pedido específico (usa gerarTextoContatoKanban)
                        if (widget.numeroPedido != null)
                          ActionChip(
                            avatar: const Icon(Icons.support_agent_rounded, size: 14, color: Color(0xFF818CF8)),
                            label: const Text('Contato sobre Pedido', style: TextStyle(fontSize: 11.5)),
                            backgroundColor: FincoreColors.surfaceElevated,
                            side: const BorderSide(color: FincoreColors.border),
                            onPressed: () => _setTemplate(
                              WhatsAppService.gerarTextoContatoKanban(
                                nomeCliente: _clienteNomeLimpo,
                                numeroPedidoOuId: numPedido,
                                nomeEmpresa: _resolvedNomeEmpresa,
                              ),
                            ),
                          ),
                        // Cardápio / Novidades
                        ActionChip(
                          avatar: const Icon(Icons.restaurant_menu_rounded, size: 14, color: Color(0xFFF97316)),
                          label: const Text('Card\u00E1pio / Novidades', style: TextStyle(fontSize: 11.5)),
                          backgroundColor: FincoreColors.surfaceElevated,
                          side: const BorderSide(color: FincoreColors.border),
                          onPressed: () => _setTemplate(
                            // \u{2728}=✨ \u{1F360}=🍠 \u{1F525}=🔥 \u{1F60D}=😍
                            '\u{2728} *Ol\u00E1, $_clienteNomeLimpo!*\n\n'
                            'Temos novidades incr\u00EDveis e del\u00EDcias fresquinhas saindo hoje na *$_resolvedNomeEmpresa*! \u{1F360}\u{1F525}\n\n'
                            'Quer conferir o nosso card\u00E1pio completo e fazer o seu pedido? \u{1F60D}\n'
                            'Aqui voc\u00EA escolhe, n\u00F3s cuidamos do resto! \u{1F680}',
                          ),
                        ),
                        // Saiu para entrega (se tiver número de pedido)
                        if (widget.numeroPedido != null)
                          ActionChip(
                            avatar: const Icon(Icons.delivery_dining_rounded, size: 14, color: Color(0xFF06B6D4)),
                            label: const Text('Saiu p/ Entrega', style: TextStyle(fontSize: 11.5)),
                            backgroundColor: FincoreColors.surfaceElevated,
                            side: const BorderSide(color: FincoreColors.border),
                            onPressed: () => _setTemplate(
                              WhatsAppService.gerarTextoSaiuParaEntrega(
                                nomeCliente: _clienteNomeLimpo,
                                numeroPedidoOuId: numPedido,
                                nomeEmpresa: _resolvedNomeEmpresa,
                              ),
                            ),
                          ),
                        // Lembrete de Pagamento / Cobrança PIX
                        if (widget.numeroPedido != null || widget.pixInfo != null)
                          ActionChip(
                            avatar: const Icon(Icons.pix, size: 14, color: Color(0xFF32BCAD)),
                            label: const Text('Lembrete de Pagamento', style: TextStyle(fontSize: 11.5)),
                            backgroundColor: FincoreColors.surfaceElevated,
                            side: const BorderSide(color: FincoreColors.border),
                            onPressed: () => _setTemplate(
                              WhatsAppService.gerarTextoLembretePagamento(
                                nomeCliente: _clienteNomeLimpo,
                                numeroPedidoOuId: numPedido,
                                valor: 0.0, // Preenchido no resumo ou editável
                                nomeEmpresa: _resolvedNomeEmpresa,
                              ),
                            ),
                          ),
                        // Confirmar Endereço
                        if (widget.enderecoCliente != null && widget.enderecoCliente!.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF38BDF8)),
                            label: const Text('Confirmar Endere\u00E7o', style: TextStyle(fontSize: 11.5)),
                            backgroundColor: FincoreColors.surfaceElevated,
                            side: const BorderSide(color: FincoreColors.border),
                            // \u{1F4CD}=📍 \u{1F3E0}=🏠 \u{1F60A}=😊
                            onPressed: () => _setTemplate(
                              '\u{1F4CD} *Olá, $_clienteNomeLimpo!*\n\n'
                              'Confirmando o endereço de entrega do seu pedido *$numPedido*:\n'
                              '\u{1F3E0} *${widget.enderecoCliente}*\n\n'
                              'Está correto? Confirmando, seguimos com a entrega! \u{1F60A}',
                            ),
                          ),
                        // Comprovante do Pedido (se initialMessage fornecido)
                        if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.receipt_long_rounded, size: 14, color: whatsappGreen),
                            label: const Text('Comprovante do Pedido', style: TextStyle(fontSize: 11.5)),
                            backgroundColor: FincoreColors.surfaceElevated,
                            side: const BorderSide(color: FincoreColors.border),
                            onPressed: () => _setTemplate(widget.initialMessage!),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Campo da Mensagem
                    const Text(
                      'CONTE\u00DADO DA MENSAGEM:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    TextFormField(
                      controller: _messageController,
                      maxLines: 7,
                      minLines: 4,
                      style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary, height: 1.4),
                      decoration: InputDecoration(
                        hintText: 'Digite a mensagem para enviar...',
                        hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: FincoreColors.surfaceElevated,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: FincoreColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: whatsappGreen, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FincoreColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: const Border(top: BorderSide(color: FincoreColors.border)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _copiarTexto,
                    icon: const Icon(Icons.copy_rounded, size: 16, color: FincoreColors.textSecondary),
                    label: const Text('Copiar Texto',
                        style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: FincoreColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (temPix) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _copiarPixCopiaECola,
                      icon: const Icon(Icons.pix, size: 16, color: Color(0xFF32BCAD)),
                      label: const Text('Copiar PIX',
                          style: TextStyle(color: Color(0xFF32BCAD), fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF32BCAD)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar',
                        style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    label: Text(
                      _enviando ? 'Abrindo...' : 'Abrir WhatsApp',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whatsappGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR Code Visual (CustomPainter) ──────────────────────────────────────────
//
// Renderiza um QR Code estilizado visualmente (não é um QR escan\u00e1vel real).
// Para o QR real, o operador deve abrir o PixPaymentModal do PDV Express.
// Aqui serve apenas para representação visual da chave no card WhatsApp.
//
class _PixQrCodePainter extends CustomPainter {
  const _PixQrCodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Cantos principais do QR Code (finder patterns)
    canvas.drawRect(const Rect.fromLTWH(0, 0, 42, 42), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 42, 0, 42, 42), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 42, 42, 42), paint);

    // Interior branco dos cantos
    paint.color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(7, 7, 28, 28), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 35, 7, 28, 28), paint);
    canvas.drawRect(Rect.fromLTWH(7, size.height - 35, 28, 28), paint);

    // Centro dos cantos (teal para identidade PIX)
    paint.color = const Color(0xFF32BCAD);
    canvas.drawRect(const Rect.fromLTWH(14, 14, 14, 14), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 28, 14, 14, 14), paint);
    canvas.drawRect(Rect.fromLTWH(14, size.height - 28, 14, 14), paint);

    // Pixels de dados simulados
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(52, 4, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(66, 4, 14, 10), paint);
    canvas.drawRect(Rect.fromLTWH(52, 18, 10, 6), paint);
    canvas.drawRect(Rect.fromLTWH(70, 18, 10, 14), paint);
    canvas.drawRect(Rect.fromLTWH(4, 52, 14, 10), paint);
    canvas.drawRect(Rect.fromLTWH(22, 52, 6, 18), paint);
    canvas.drawRect(Rect.fromLTWH(4, 66, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(50, 50, 18, 8), paint);
    canvas.drawRect(Rect.fromLTWH(72, 52, 12, 12), paint);
    canvas.drawRect(Rect.fromLTWH(50, 64, 8, 14), paint);
    canvas.drawRect(Rect.fromLTWH(64, 68, 14, 8), paint);
    canvas.drawRect(Rect.fromLTWH(82, 64, 8, 18), paint);
    canvas.drawRect(Rect.fromLTWH(56, 82, 18, 8), paint);
    canvas.drawRect(Rect.fromLTWH(78, 82, 12, 14), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
