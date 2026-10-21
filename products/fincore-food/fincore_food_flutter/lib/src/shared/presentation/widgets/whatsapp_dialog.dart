import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:fincore_core/context/tenant_context.dart';
import '../../services/whatsapp_service.dart';

/// Informações de PIX para exibição contextual no WhatsAppDialog.
/// Gerado pelo PixGenerator e passado pelo caller (PDV Express ou Kanban).
class PixWhatsAppInfo {
  /// Chave legível para exibição (ex: "(11) 99999-8888", "email@...", CPF mascarado)
  final String chaveDisplay;

  /// Tipo da chave (ex: "Telefone", "CPF", "CNPJ", "E-mail", "Aleatória")
  final String tipoChave;

  /// Payload EMV completo (Copia e Cola) — gerado pelo PixGenerator
  final String copiaECola;

  /// Indica se o pagamento PIX já foi confirmado
  final bool confirmado;

  const PixWhatsAppInfo({
    required this.chaveDisplay,
    required this.tipoChave,
    required this.copiaECola,
    this.confirmado = false,
  });
}

/// Modal Oficial e Inteligente de Disparo de Mensagens via WhatsApp.
/// Redesign UX/UI: compacto, profissional e centrado no conteúdo da mensagem.
class WhatsAppDialog extends StatefulWidget {
  final String rawPhone;
  final String clienteNome;
  final String? initialMessage;
  final String? enderecoCliente;
  final String? nomeEmpresa;

  /// Informações PIX para exibição contextual (opcional).
  final PixWhatsAppInfo? pixInfo;

  /// ID amigável do pedido (ex: "#000142") — exibido no cabeçalho e usado nos templates.
  final String? numeroPedido;

  /// Dados avançados de Food Service para interpolação de todas as tags do sistema
  final List<Map<String, dynamic>>? itens;
  final double? subtotal;
  final double? desconto;
  final double? taxaEntrega;
  final double? taxaServico;
  final double? total;
  final String? formaPagamento;
  final String? trocoPara;
  final String? tipoPedido;
  final String? observacoes;
  final String? previsaoEntrega;
  final String? entregador;
  final String? mesa;
  final String? linkCardapio;
  final String? linkRastreio;
  final String? pedidoId;
  final String? enderecoEmpresa;
  final String? statusPagamento;
  final bool? pagamentoPendente;
  final bool? isPix;
  final String? initialTemplateId;

  const WhatsAppDialog({
    super.key,
    required this.rawPhone,
    required this.clienteNome,
    this.initialMessage,
    this.initialTemplateId,
    this.enderecoCliente,
    this.enderecoEmpresa,
    this.nomeEmpresa,
    this.pixInfo,
    this.numeroPedido,
    this.pedidoId,
    this.itens,
    this.subtotal,
    this.desconto,
    this.taxaEntrega,
    this.taxaServico,
    this.total,
    this.formaPagamento,
    this.statusPagamento,
    this.pagamentoPendente,
    this.isPix,
    this.trocoPara,
    this.tipoPedido,
    this.observacoes,
    this.previsaoEntrega,
    this.entregador,
    this.mesa,
    this.linkCardapio,
    this.linkRastreio,
  });

  /// Abre o modal de WhatsApp
  static Future<bool?> show(
    BuildContext context, {
    required String rawPhone,
    required String clienteNome,
    String? initialMessage,
    String? initialTemplateId,
    String? enderecoCliente,
    String? enderecoEmpresa,
    String? nomeEmpresa,
    PixWhatsAppInfo? pixInfo,
    String? numeroPedido,
    String? pedidoId,
    List<Map<String, dynamic>>? itens,
    double? subtotal,
    double? desconto,
    double? taxaEntrega,
    double? taxaServico,
    double? total,
    String? formaPagamento,
    String? statusPagamento,
    bool? pagamentoPendente,
    bool? isPix,
    String? trocoPara,
    String? tipoPedido,
    String? observacoes,
    String? previsaoEntrega,
    String? entregador,
    String? mesa,
    String? linkCardapio,
    String? linkRastreio,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsAppDialog(
        rawPhone: rawPhone,
        clienteNome: clienteNome,
        initialMessage: initialMessage,
        initialTemplateId: initialTemplateId,
        enderecoCliente: enderecoCliente,
        enderecoEmpresa: enderecoEmpresa,
        nomeEmpresa: nomeEmpresa,
        pixInfo: pixInfo,
        numeroPedido: numeroPedido,
        pedidoId: pedidoId,
        itens: itens,
        subtotal: subtotal,
        desconto: desconto,
        taxaEntrega: taxaEntrega,
        taxaServico: taxaServico,
        total: total,
        formaPagamento: formaPagamento,
        statusPagamento: statusPagamento,
        pagamentoPendente: pagamentoPendente,
        isPix: isPix,
        trocoPara: trocoPara,
        tipoPedido: tipoPedido,
        observacoes: observacoes,
        previsaoEntrega: previsaoEntrega,
        entregador: entregador,
        mesa: mesa,
        linkCardapio: linkCardapio,
        linkRastreio: linkRastreio,
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
  String? _ultimoEnvioHora;
  bool _algumEnvioRealizado = false;

  String get _clienteNomeLimpo {
    return widget.clienteNome.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  String get _subtituloCabecalho {
    final nome = widget.clienteNome.isNotEmpty ? _clienteNomeLimpo : 'Cliente';
    if (widget.numeroPedido != null && widget.numeroPedido!.isNotEmpty) {
      final ped = widget.numeroPedido!.startsWith('#')
          ? widget.numeroPedido!
          : '#${widget.numeroPedido}';
      return '$nome · Pedido $ped';
    }
    return nome;
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

  bool _enviarPixSegundaMensagem = false;

  String _interpolarTexto(String texto) {
    String? tenantId;
    try {
      if (TenantContext().hasContext) {
        tenantId = TenantContext().tenantId;
      }
    } catch (_) {}

    final mapa = WhatsAppService.gerarVariaveisInterpolacao(
      clienteNome: widget.clienteNome,
      nomeEmpresa: _resolvedNomeEmpresa,
      tenantId: tenantId,
      numeroPedido: widget.numeroPedido,
      pedidoId: widget.pedidoId,
      itens: widget.itens,
      subtotal: widget.subtotal,
      desconto: widget.desconto,
      taxaEntrega: widget.taxaEntrega,
      taxaServico: widget.taxaServico,
      total: widget.total,
      formaPagamento: widget.formaPagamento,
      statusPagamento: widget.statusPagamento,
      pagamentoPendente: widget.pagamentoPendente,
      isPix: widget.isPix,
      trocoPara: widget.trocoPara,
      tipoPedido: widget.tipoPedido,
      endereco: widget.enderecoCliente,
      enderecoEmpresa: widget.enderecoEmpresa,
      observacoes: widget.observacoes,
      previsaoEntrega: widget.previsaoEntrega,
      entregador: widget.entregador,
      mesa: widget.mesa,
      linkCardapio: widget.linkCardapio,
      linkRastreio: widget.linkRastreio,
      chavePix: widget.pixInfo?.chaveDisplay,
      chavePixCopiaCola: widget.pixInfo?.copiaECola,
    );
    return WhatsAppService.interpolarTemplate(texto, mapa);
  }

  List<WhatsAppTemplate> _customTemplates = [];
  String? _selectedTemplateOption;

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
    _selectedTemplateOption = widget.initialTemplateId;

    // Usa initialMessage interpolado se fornecido, senão saudação padrão calorosa
    final rawMessage = widget.initialMessage ??
        '\u{1F44B} *Ol\u00E1, {primeiro_nome}!* Tudo bem? \u{1F60A}\n\n'
        'Aqui \u00E9 da equipe da *{loja}*! \u{2728}\n'
        'Passando para saber se voc\u00EA gostaria de fazer um novo pedido ou se precisa de alguma ajuda hoje?\n\n'
        'Estamos \u00E0 sua total disposi\u00E7\u00E3o! \u{1F680}';

    _messageController = TextEditingController(text: _interpolarTexto(rawMessage));
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    String? tenantId;
    try {
      if (TenantContext().hasContext) {
        tenantId = TenantContext().tenantId;
      }
    } catch (_) {}

    await WhatsAppService.atualizarCacheUrlCardapio(tenantId: tenantId);

    // Carrega preferência de PIX 2ª mensagem definida nas configurações do PDV
    try {
      final pdvCfg = await WhatsAppService.getPdvConfig(tenantId: tenantId);
      if (mounted) {
        setState(() {
          _enviarPixSegundaMensagem = pdvCfg.enviarPix2MsgPadrao;
        });
      }
    } catch (_) {}

    // Se a mensagem original tiver tags dinâmicas de link ou pedido, re-interpola com a URL base carregada
    if (widget.initialMessage != null &&
        (widget.initialMessage!.contains('{link_cardapio}') ||
            widget.initialMessage!.contains('{link_rastreio}'))) {
      if (mounted) {
        _messageController.text = _interpolarTexto(widget.initialMessage!);
      }
    }

    await _carregarTemplatesConfigurados(tenantId);
  }

  Future<void> _carregarTemplatesConfigurados([String? tenantId]) async {
    final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : null);

    final list = await WhatsAppService.getTemplates(
      tenantId: tId,
      nomeEmpresa: _resolvedNomeEmpresa,
    );

    if (mounted) {
      final ativos = list.where((t) => t.ativo).toList();
      setState(() {
        _customTemplates = ativos;

        // Se foi solicitado um template inicial específico (ex: 'cobranca_pix', 'saiu_entrega', 'comprovante')
        if (widget.initialTemplateId != null) {
          final match = ativos.firstWhere(
            (t) => t.id == widget.initialTemplateId,
            orElse: () => list.firstWhere(
              (t) => t.id == widget.initialTemplateId,
              orElse: () => ativos.isNotEmpty ? ativos.first : WhatsAppService.getTemplatesPadrao().first,
            ),
          );
          _selectedTemplateOption = match.id;
          // Se o caller não passou um texto já formatado manualmente, ou se passou para usar o template, carrega o conteúdo salvo
          if (widget.initialMessage == null || widget.initialMessage!.isEmpty) {
            _messageController.text = _interpolarTexto(match.conteudo);
          }
        } else if (_selectedTemplateOption != null) {
          final existe = ativos.any((t) => t.id == _selectedTemplateOption);
          if (!existe && ativos.isNotEmpty) {
            _selectedTemplateOption = ativos.first.id;
          }
        }
      });
    }
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
        const SnackBar(
          backgroundColor: FincoreColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: FincoreColors.success, size: 18),
              SizedBox(width: 8),
              Text('Mensagem copiada para a área de transferência!',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _copiarChavePix() async {
    if (widget.pixInfo == null) return;
    await Clipboard.setData(ClipboardData(text: widget.pixInfo!.chaveDisplay));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF32BCAD),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.pix, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Chave PIX copiada!', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _copiarPixCopiaECola() async {
    if (widget.pixInfo == null) return;
    await Clipboard.setData(ClipboardData(text: widget.pixInfo!.copiaECola));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.pix, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Código PIX Copia e Cola copiado!',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
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
          behavior: SnackBarBehavior.floating,
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
          final now = DateTime.now();
          final horaStr =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          setState(() {
            _ultimoEnvioHora = horaStr;
            _algumEnvioRealizado = true;
          });

          // Se configurado para enviar Copia e Cola em 2ª mensagem, copia para o Clipboard
          final pix = widget.pixInfo;
          if (_enviarPixSegundaMensagem && pix != null && pix.copiaECola.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: pix.copiaECola));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  content: Text('WhatsApp aberto! O código PIX Copia e Cola já foi copiado para sua área de transferência para colar em seguida. 📋'),
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: FincoreColors.danger,
              behavior: SnackBarBehavior.floating,
              content: Text(
                  'Não foi possível abrir o WhatsApp. Verifique se o navegador ou aplicativo está disponível.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            behavior: SnackBarBehavior.floating,
            content: Text('Erro ao acionar WhatsApp: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _enviarViaEvolutionApi() async {
    final rawPhone = _phoneController.text.trim();
    final digitos = WhatsAppService.sanitizarTelefone(rawPhone);

    if (digitos.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FincoreColors.danger,
          behavior: SnackBarBehavior.floating,
          content: Text('Por favor, informe um número de telefone com DDD válido.'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      String? tenantId;
      try {
        if (TenantContext().hasContext) {
          tenantId = TenantContext().tenantId;
        }
      } catch (_) {}

      final res = await WhatsAppService.enviarMensagem(
        rawPhone: rawPhone,
        mensagem: _messageController.text,
        tenantId: tenantId,
        pedidoId: widget.numeroPedido,
        eventoId: 'direto_dialog',
        isManualIntent: true,
      );

      if (mounted) {
        if (res.sucesso) {
          final now = DateTime.now();
          final horaStr =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          setState(() {
            _ultimoEnvioHora = horaStr;
            _algumEnvioRealizado = true;
          });

          // Disparo da 2ª mensagem com PIX Copia e Cola se selecionado
          final pix = widget.pixInfo;
          if (_enviarPixSegundaMensagem && pix != null && pix.copiaECola.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 1200));
            await WhatsAppService.enviarMensagem(
              rawPhone: rawPhone,
              mensagem: pix.copiaECola,
              tenantId: tenantId,
              pedidoId: widget.numeroPedido,
              eventoId: 'pix_copia_cola_2msg',
              isManualIntent: true,
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (_enviarPixSegundaMensagem && pix != null && pix.copiaECola.isNotEmpty)
                            ? 'Mensagem e código PIX Copia e Cola enviados às $horaStr para ${res.telefoneMascarado}! 🚀'
                            : 'Mensagem enviada com sucesso às $horaStr para ${res.telefoneMascarado}! 🚀',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: FincoreColors.danger,
              behavior: SnackBarBehavior.floating,
              content: Text(
                  'Não foi possível enviar via Evolution API: ${res.erro ?? res.status.name}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            behavior: SnackBarBehavior.floating,
            content: Text('Erro ao disparar Evolution API: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }


  String _injetarAposPagamento(String textoAtual, String blocoPix) {
    if (textoAtual.contains(blocoPix.trim())) {
      return textoAtual;
    }

    // 1. Tenta localizar a linha onde a forma de pagamento é descrita
    // Ex: "💳 *Pagamento: Pix Mercado Pago*", "Forma de Pagamento: Pix"
    final regexPagamento = RegExp(
      r'((?:💳\s*\*?(?:Forma de\s+)?Pagamento\*?:?[^\n]*|(?:Forma de\s+)?Pagamento\*?:?[^\n]*))',
      caseSensitive: false,
    );

    final matchPagto = regexPagamento.firstMatch(textoAtual);
    if (matchPagto != null) {
      final fimPagto = matchPagto.end;
      final antes = textoAtual.substring(0, fimPagto).trimRight();
      final depois = textoAtual.substring(fimPagto).trimLeft();
      return '$antes\n\n$blocoPix\n\n$depois'.trim();
    }

    // 2. Fallback: antes de link de rastreio, dúvidas ou encerramento
    final regexFinal = RegExp(
      r'(\n\s*(?:(?:📱|🔗)?\s*\*?Acompanhe|Qualquer dúvida|Dúvidas|Se tiver dúvidas|Se precisar|Agradecemos|Muito obrigado|Obrigado pela preferência|\*Equipe|Atenciosamente))',
      caseSensitive: false,
    );

    final matchFinal = regexFinal.firstMatch(textoAtual);
    if (matchFinal != null && matchFinal.start > 0) {
      final antes = textoAtual.substring(0, matchFinal.start).trimRight();
      final depois = textoAtual.substring(matchFinal.start).trimLeft();
      return '$antes\n\n$blocoPix\n\n$depois'.trim();
    }

    return '$textoAtual\n\n$blocoPix'.trim();
  }

  void _inserirChavePixNoTexto() {
    final pix = widget.pixInfo;
    if (pix == null || pix.chaveDisplay.isEmpty) return;
    final blocoChave = '🔑 *Chave PIX (${pix.tipoChave}):* ${pix.chaveDisplay}';
    _messageController.text = _injetarAposPagamento(_messageController.text, blocoChave);
  }

  void _inserirCopiaEColaNoTexto() {
    final pix = widget.pixInfo;
    if (pix == null || pix.copiaECola.isEmpty) return;
    final blocoCopiaCola = '📋 *PIX Copia e Cola:*\n${pix.copiaECola}';
    _messageController.text = _injetarAposPagamento(_messageController.text, blocoCopiaCola);
  }

  @override
  Widget build(BuildContext context) {
    const whatsappGreen = Color(0xFF25D366);
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogMaxHeight = (screenHeight * 0.90).clamp(520.0, 750.0);

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FincoreColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: dialogMaxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Top Header ──────────────────────────────────────────
            _buildHeader(whatsappGreen),

            // ── 2. Body com Scroll Suave ──────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── DESTINATÁRIO ─────────────────────────────────
                    _buildDestinatarioSection(whatsappGreen),
                    const SizedBox(height: 16),

                    const Divider(height: 1, color: FincoreColors.border),
                    const SizedBox(height: 16),

                    // ── MENSAGEM (Elemento Principal) ─────────────────
                    _buildMensagemSection(),

                    // ── PIX (Contextual — apenas quando aplicável) ─────
                    _buildPixSection(),
                  ],
                ),
              ),
            ),

            // ── 3. Rodapé Fixo ─────────────────────────────────────────
            _buildFooter(whatsappGreen),
          ],
        ),
      ),
    );
  }

  // ── 1. Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(Color whatsappGreen) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: const Border(bottom: BorderSide(color: FincoreColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: whatsappGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: whatsappGreen.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.chat_rounded, color: whatsappGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conversa no WhatsApp',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtituloCabecalho,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: FincoreColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: FincoreColors.textMuted),
            onPressed: () => Navigator.of(context).pop(_algumEnvioRealizado),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  // ── 2. Destinatário ───────────────────────────────────────────────────────

  Widget _buildDestinatarioSection(Color whatsappGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DESTINATÁRIO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: FincoreColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            // Toggle compacto do 9º dígito
            InkWell(
              onTap: () => _onToggleNonoDigito(!_comNonoDigito),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _comNonoDigito
                      ? whatsappGreen.withValues(alpha: 0.12)
                      : FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _comNonoDigito
                        ? whatsappGreen.withValues(alpha: 0.5)
                        : FincoreColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _comNonoDigito ? Icons.phone_android_rounded : Icons.phone_rounded,
                      size: 13,
                      color: _comNonoDigito ? whatsappGreen : FincoreColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _comNonoDigito ? 'Celular (com 9)' : 'Fixo / Antigo (sem 9)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _comNonoDigito ? whatsappGreen : FincoreColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Campo de Telefone Compacto com Indicador de Validade
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _phoneController,
          builder: (context, value, _) {
            final digitos = WhatsAppService.sanitizarTelefone(value.text);
            final isValido = digitos.length >= 10 && digitos.length <= 11;

            return Container(
              decoration: BoxDecoration(
                color: FincoreColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValido
                      ? whatsappGreen.withValues(alpha: 0.4)
                      : (digitos.isNotEmpty
                          ? FincoreColors.warning.withValues(alpha: 0.5)
                          : FincoreColors.border),
                ),
              ),
              child: TextFormField(
                controller: _phoneController,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FincoreColors.textPrimary,
                  letterSpacing: 0.4,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF25D366)),
                        SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('|', style: TextStyle(color: FincoreColors.border)),
                      ],
                    ),
                  ),
                  suffixIcon: Tooltip(
                    message: isValido
                        ? 'Número com DDD válido para envio'
                        : 'Informe DDD + número (mínimo 10 dígitos)',
                    child: Icon(
                      isValido ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 18,
                      color: isValido
                          ? const Color(0xFF22C55E)
                          : (digitos.isNotEmpty ? FincoreColors.warning : FincoreColors.textMuted),
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── 3. Mensagem ───────────────────────────────────────────────────────────

  Widget _buildMensagemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MENSAGEM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: FincoreColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        // ⚡ Modelo de mensagem
        Row(
          children: const [
            Icon(Icons.bolt_rounded, size: 15, color: Color(0xFFF59E0B)),
            SizedBox(width: 4),
            Text(
              'Modelo de mensagem',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: FincoreColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Container(
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: () {
                final templates = (_customTemplates.isNotEmpty
                        ? _customTemplates
                        : WhatsAppService.getTemplatesPadrao(nomeEmpresa: _resolvedNomeEmpresa))
                    .where((t) => t.ativo)
                    .toList();
                if (_selectedTemplateOption != null && templates.any((t) => t.id == _selectedTemplateOption)) {
                  return _selectedTemplateOption;
                }
                return null;
              }(),
              hint: const Text(
                'Selecione um modelo de mensagem...',
                style: TextStyle(fontSize: 12.5, color: FincoreColors.textMuted),
              ),
              isExpanded: true,
              dropdownColor: FincoreColors.surfaceElevated,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: FincoreColors.textMuted, size: 20),
              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
              onChanged: (novoId) {
                if (novoId == null) return;
                setState(() => _selectedTemplateOption = novoId);

                final templatesLista = (_customTemplates.isNotEmpty
                    ? _customTemplates
                    : WhatsAppService.getTemplatesPadrao(nomeEmpresa: _resolvedNomeEmpresa));
                final match = templatesLista.firstWhere(
                  (t) => t.id == novoId,
                  orElse: () => templatesLista.first,
                );

                final textoInterpolado = _interpolarTexto(match.conteudo);
                _setTemplate(textoInterpolado);
              },
              items: (_customTemplates.isNotEmpty
                      ? _customTemplates
                      : WhatsAppService.getTemplatesPadrao(nomeEmpresa: _resolvedNomeEmpresa))
                  .where((t) => t.ativo)
                  .map((t) {
                final isSelected = t.id == _selectedTemplateOption;
                return DropdownMenuItem<String>(
                  value: t.id,
                  child: Row(
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.titulo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF25D366) : FincoreColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Área de Conteúdo da Mensagem Editável com Contador
        Container(
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(
                  fontSize: 13,
                  color: FincoreColors.textPrimary,
                  height: 1.45,
                ),
                decoration: const InputDecoration(
                  hintText: 'Digite o conteúdo da mensagem...',
                  hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _messageController,
                      builder: (context, value, _) {
                        return Text(
                          '${value.text.length} caracteres',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FincoreColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 4. PIX (Contextual) ───────────────────────────────────────────────────

  Widget _buildPixSection() {
    final pix = widget.pixInfo;
    if (pix == null) return const SizedBox.shrink();

    const pixTeal = Color(0xFF32BCAD);

    // Quando o pagamento já estiver confirmado
    if (pix.confirmado) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.pix, color: Color(0xFF16A34A), size: 18),
            SizedBox(width: 8),
            Text(
              'PIX',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '✓ Pagamento confirmado',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF22C55E),
              ),
            ),
          ],
        ),
      );
    }

    // Quando o pagamento estiver pendente
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pixTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pixTeal.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pix, color: pixTeal, size: 16),
              const SizedBox(width: 6),
              const Text(
                'PIX',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: pixTeal,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pagamento pendente',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chave: ',
                    style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                  ),
                  SelectableText(
                    pix.chaveDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: FincoreColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: _inserirChavePixNoTexto,
                    icon: const Icon(Icons.add_circle_outline, size: 12, color: Colors.amber),
                    label: const Text('+ Chave no Texto', style: TextStyle(color: Colors.amber, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (pix.copiaECola.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _inserirCopiaEColaNoTexto,
                      icon: const Icon(Icons.add_circle_outline, size: 12, color: Colors.cyanAccent),
                      label: const Text('+ Copia e Cola no Texto', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (pix.copiaECola.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _enviarPixSegundaMensagem,
                      activeColor: pixTeal,
                      onChanged: (val) {
                        setState(() => _enviarPixSegundaMensagem = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _enviarPixSegundaMensagem = !_enviarPixSegundaMensagem),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enviar PIX Copia e Cola em 2ª mensagem',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: FincoreColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Opcional: envia o código copia e cola avulso para o cliente copiar com 1 toque.',
                            style: TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                          ),
                        ],
                      ),
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

  // ── 5. Rodapé ─────────────────────────────────────────────────────────────

  Widget _buildFooter(Color whatsappGreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: const Border(top: BorderSide(color: FincoreColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feedback de Envio Bem-Sucedido (Não bloqueia novos envios manuais)
          if (_ultimoEnvioHora != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '✓ Mensagem enviada às $_ultimoEnvioHora. Você pode reenviar ou enviar uma nova mensagem a qualquer momento.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              // [Cancelar] ou [Fechar]
              TextButton(
                onPressed: () => Navigator.of(context).pop(_algumEnvioRealizado),
                style: TextButton.styleFrom(
                  foregroundColor: FincoreColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _algumEnvioRealizado ? 'Fechar' : 'Cancelar',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(width: 8),

              // [Copiar]
              OutlinedButton.icon(
                onPressed: _copiarTexto,
                icon: const Icon(Icons.copy_rounded, size: 14, color: FincoreColors.textSecondary),
                label: const Text(
                  'Copiar',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: FincoreColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 4),

              // Menu secundário ⋮
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                icon: const Icon(Icons.more_vert_rounded,
                    color: FincoreColors.textSecondary, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: FincoreColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: FincoreColors.border),
                ),
                onSelected: (val) {
                  if (val == 'copiar_texto') _copiarTexto();
                  if (val == 'copiar_pix') _copiarChavePix();
                  if (val == 'copiar_copia_cola') _copiarPixCopiaECola();
                  if (val == 'abrir_web') _enviar();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'copiar_texto',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 15, color: FincoreColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Copiar texto da mensagem', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (widget.pixInfo != null) ...[
                    const PopupMenuItem(
                      value: 'copiar_pix',
                      child: Row(
                        children: [
                          Icon(Icons.pix, size: 15, color: Color(0xFF32BCAD)),
                          SizedBox(width: 8),
                          Text('Copiar chave PIX', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copiar_copia_cola',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_rounded, size: 15, color: Color(0xFF32BCAD)),
                          SizedBox(width: 8),
                          Text('Copiar Pix Copia e Cola', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'abrir_web',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_browser_rounded,
                            size: 15, color: FincoreColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Abrir no WhatsApp Web/App', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // [🚀 Enviar pelo WhatsApp]
              ElevatedButton.icon(
                onPressed: _enviando ? null : _enviarViaEvolutionApi,
                icon: _enviando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('🚀', style: TextStyle(fontSize: 13)),
                label: Text(
                  _enviando ? 'Enviando...' : 'Enviar pelo WhatsApp',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: whatsappGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
