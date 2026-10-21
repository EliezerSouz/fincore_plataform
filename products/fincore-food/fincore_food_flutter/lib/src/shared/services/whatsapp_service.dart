import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/fincore_core.dart';
import '../data/whatsapp_message_log_repository.dart';
import 'evolution_api_client.dart';
export 'evolution_api_client.dart';
export '../data/whatsapp_message_log_repository.dart';

/// Modelo de Template de Mensagem Rápida do WhatsApp (Configuração Dinâmica — Fase D2)
class WhatsAppTemplate {
  final String id;
  final String titulo;
  final String emoji;
  final String descricao;
  final String conteudo;
  final String categoria; // 'atendimento', 'pedido', 'entrega', 'financeiro', 'marketing', 'custom'
  final bool ativo;
  final bool isPadrao;
  final List<String> variaveisSugeridas;
  final String evento; // 'geral', 'pedido_criado', 'pedido_aprovado', 'pedido_pronto', 'saiu_entrega', 'pedido_cancelado'
  final String condicaoFormaPagamento; // 'QUALQUER', 'PIX', 'DINHEIRO', 'CARTAO'
  final String condicaoStatusPagamento; // 'QUALQUER', 'PENDENTE', 'PAGO'
  final int ordem;

  const WhatsAppTemplate({
    required this.id,
    required this.titulo,
    required this.emoji,
    required this.descricao,
    required this.conteudo,
    this.categoria = 'custom',
    this.ativo = true,
    this.isPadrao = false,
    this.evento = 'geral',
    this.condicaoFormaPagamento = 'QUALQUER',
    this.condicaoStatusPagamento = 'QUALQUER',
    this.ordem = 0,
    this.variaveisSugeridas = const [
      '{cliente}',
      '{loja}',
      '{pedido}',
      '{total}',
      '{forma_pagamento}',
      '{endereco}',
      '{chave_pix}',
      '{link_cardapio}',
    ],
  });

  WhatsAppTemplate copyWith({
    String? id,
    String? titulo,
    String? emoji,
    String? descricao,
    String? conteudo,
    String? categoria,
    bool? ativo,
    bool? isPadrao,
    List<String>? variaveisSugeridas,
    String? evento,
    String? condicaoFormaPagamento,
    String? condicaoStatusPagamento,
    int? ordem,
  }) {
    return WhatsAppTemplate(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      emoji: emoji ?? this.emoji,
      descricao: descricao ?? this.descricao,
      conteudo: conteudo ?? this.conteudo,
      categoria: categoria ?? this.categoria,
      ativo: ativo ?? this.ativo,
      isPadrao: isPadrao ?? this.isPadrao,
      variaveisSugeridas: variaveisSugeridas ?? this.variaveisSugeridas,
      evento: evento ?? this.evento,
      condicaoFormaPagamento: condicaoFormaPagamento ?? this.condicaoFormaPagamento,
      condicaoStatusPagamento: condicaoStatusPagamento ?? this.condicaoStatusPagamento,
      ordem: ordem ?? this.ordem,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'emoji': emoji,
        'descricao': descricao,
        'conteudo': conteudo,
        'categoria': categoria,
        'ativo': ativo,
        'isPadrao': isPadrao,
        'variaveisSugeridas': variaveisSugeridas,
        'evento': evento,
        'condicaoFormaPagamento': condicaoFormaPagamento,
        'condicaoStatusPagamento': condicaoStatusPagamento,
        'ordem': ordem,
      };

  factory WhatsAppTemplate.fromJson(Map<String, dynamic> map) {
    return WhatsAppTemplate(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '💬',
      descricao: map['descricao']?.toString() ?? '',
      conteudo: map['conteudo']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? 'custom',
      ativo: map['ativo'] == true,
      isPadrao: map['isPadrao'] == true,
      evento: map['evento']?.toString() ?? 'geral',
      condicaoFormaPagamento: map['condicaoFormaPagamento']?.toString() ?? 'QUALQUER',
      condicaoStatusPagamento: map['condicaoStatusPagamento']?.toString() ?? 'QUALQUER',
      ordem: map['ordem'] as int? ?? 0,
      variaveisSugeridas: (map['variaveisSugeridas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            '{cliente}',
            '{loja}',
            '{pedido}',
            '{total}',
            '{forma_pagamento}',
            '{endereco}',
            '{chave_pix}',
            '{link_cardapio}',
          ],
    );
  }
}

/// Modo de envio do WhatsApp
enum WhatsAppApiMode {
  manualWaMe, // wa.me / whatsapp:// (gratuito e sem servidor)
  evolutionApi, // Evolution API (Self-hosted REST API)
  genericWebhook, // Webhook Genérico HTTP POST
}

/// Configuração de Disparo e Comportamento do WhatsApp no Frente de Caixa (PDV)
class WhatsAppPdvConfig {
  final String templateId; // ID do template a ser utilizado ao finalizar no PDV (default: 'comprovante')
  final bool enviarPix2MsgPadrao; // Se true, o checkbox de 2ª msg com PIX vem marcado (default: false por enquanto)
  final String formatoPixPadrao; // 'bloco_completo', 'chave', 'copia_cola'
  final bool enviarWhatsAppPadrao; // Se true, o switch de envio vem ativado ao finalizar venda (default: true)

  const WhatsAppPdvConfig({
    this.templateId = 'comprovante',
    this.enviarPix2MsgPadrao = false,
    this.formatoPixPadrao = 'bloco_completo',
    this.enviarWhatsAppPadrao = true,
  });

  WhatsAppPdvConfig copyWith({
    String? templateId,
    bool? enviarPix2MsgPadrao,
    String? formatoPixPadrao,
    bool? enviarWhatsAppPadrao,
  }) {
    return WhatsAppPdvConfig(
      templateId: templateId ?? this.templateId,
      enviarPix2MsgPadrao: enviarPix2MsgPadrao ?? this.enviarPix2MsgPadrao,
      formatoPixPadrao: formatoPixPadrao ?? this.formatoPixPadrao,
      enviarWhatsAppPadrao: enviarWhatsAppPadrao ?? this.enviarWhatsAppPadrao,
    );
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'enviarPix2MsgPadrao': enviarPix2MsgPadrao,
        'formatoPixPadrao': formatoPixPadrao,
        'enviarWhatsAppPadrao': enviarWhatsAppPadrao,
      };

  factory WhatsAppPdvConfig.fromJson(Map<String, dynamic> map) {
    return WhatsAppPdvConfig(
      templateId: map['templateId']?.toString() ?? 'comprovante',
      enviarPix2MsgPadrao: map['enviarPix2MsgPadrao'] == true,
      formatoPixPadrao: map['formatoPixPadrao']?.toString() ?? 'bloco_completo',
      enviarWhatsAppPadrao: map['enviarWhatsAppPadrao'] != false,
    );
  }
}

/// Serviço utilitário de WhatsApp da FINCORE
class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// Limpa e extrai apenas os dígitos de uma string de telefone
  static String sanitizarTelefone(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  /// Verifica se o número informado parece ser um telefone fixo brasileiro (8 dígitos após o DDD e início de 2 a 5)
  static bool isTelefoneFixo(String raw) {
    final digitos = sanitizarTelefone(raw);
    // Remove DDI 55 se houver
    final local = digitos.startsWith('55') && digitos.length > 10 ? digitos.substring(2) : digitos;
    if (local.length == 10) {
      final primeiroDigitoNumero = local.substring(2, 3);
      return ['2', '3', '4', '5'].contains(primeiroDigitoNumero);
    }
    return false;
  }

  /// Formata o número para padrão internacional wa.me (55 + DDD + NUMERO)
  /// [comNonoDigito]: se true, força a presença do 9º dígito para celulares. Se false, remove o 9º se presente (fixo/contas antigas).
  static String formatarParaEnvio({
    required String rawPhone,
    required bool comNonoDigito,
  }) {
    String digitos = sanitizarTelefone(rawPhone);

    // Se vier com o 55 no início, remove temporariamente para tratar DDD e número
    if (digitos.startsWith('55') && (digitos.length == 12 || digitos.length == 13)) {
      digitos = digitos.substring(2);
    }

    if (digitos.length < 10) {
      // Número inválido ou muito curto, retorna como está com 55
      return '55$digitos';
    }

    final ddd = digitos.substring(0, 2);
    String numero = digitos.substring(2);

    if (comNonoDigito) {
      // Se não tem 9 dígitos, adiciona o '9' na frente
      if (numero.length == 8) {
        numero = '9$numero';
      }
    } else {
      // Se tem 9 dígitos e começa com '9', remove o nono dígito (para fixos ou contas antigas de 8 dígitos)
      if (numero.length == 9 && numero.startsWith('9')) {
        numero = numero.substring(1);
      }
    }

    return '55$ddd$numero';
  }

  /// Formata visualmente para exibição na UI
  static String formatarExibicao({
    required String rawPhone,
    required bool comNonoDigito,
  }) {
    String digitos = sanitizarTelefone(rawPhone);
    if (digitos.startsWith('55') && (digitos.length == 12 || digitos.length == 13)) {
      digitos = digitos.substring(2);
    }
    if (digitos.length < 10) return rawPhone;

    final ddd = digitos.substring(0, 2);
    String numero = digitos.substring(2);

    if (comNonoDigito && numero.length == 8) {
      numero = '9$numero';
    } else if (!comNonoDigito && numero.length == 9 && numero.startsWith('9')) {
      numero = numero.substring(1);
    }

    if (numero.length == 9) {
      return '($ddd) ${numero.substring(0, 5)}-${numero.substring(5)}';
    } else if (numero.length == 8) {
      return '($ddd) ${numero.substring(0, 4)}-${numero.substring(4)}';
    }
    return '($ddd) $numero';
  }

  /// Abre a conversa no WhatsApp Web ou App Desktop com texto pré-carregado
  static Future<bool> abrirConversa({
    required String rawPhone,
    required bool comNonoDigito,
    String? mensagem,
  }) async {
    final phoneFormatado = formatarParaEnvio(
      rawPhone: rawPhone,
      comNonoDigito: comNonoDigito,
    );

    final encodedMessage = mensagem != null && mensagem.isNotEmpty ? Uri.encodeComponent(mensagem) : '';

    // 1. Tenta abrir diretamente no aplicativo WhatsApp Desktop / Mobile via protocolo nativo
    try {
      final appUri = Uri.parse('whatsapp://send?phone=$phoneFormatado${encodedMessage.isNotEmpty ? '&text=$encodedMessage' : ''}');
      if (await canLaunchUrl(appUri)) {
        final launched = await launchUrl(appUri, mode: LaunchMode.externalNonBrowserApplication);
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('[WhatsAppService] App nativo não disponível, tentando WhatsApp Web: $e');
    }

    // 2. Se não abrir app nativo, abre direto o WhatsApp Web (sem passar pela tela intermediária de redirect api.whatsapp.com/send)
    try {
      final webUri = Uri.parse('https://web.whatsapp.com/send?phone=$phoneFormatado${encodedMessage.isNotEmpty ? '&text=$encodedMessage' : ''}');
      if (await canLaunchUrl(webUri)) {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('[WhatsAppService] WhatsApp Web falhou: $e');
    }

    // 3. Fallback wa.me
    try {
      final waUri = Uri.parse('https://wa.me/$phoneFormatado${encodedMessage.isNotEmpty ? '?text=$encodedMessage' : ''}');
      if (await canLaunchUrl(waUri)) {
        return await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[WhatsAppService] Fallback wa.me falhou: $e');
    }

    return false;
  }

  /// Dispara mensagem em background via Evolution API ou Webhook se configurado
  static Future<bool> dispararViaApi({
    required String apiUrl,
    required String apiKey,
    required String instanceName,
    required String phoneFormatado,
    required String mensagem,
    WhatsAppApiMode mode = WhatsAppApiMode.evolutionApi,
  }) async {
    if (apiUrl.trim().isEmpty) return false;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      Uri targetUri;
      Map<String, dynamic> body;

      if (mode == WhatsAppApiMode.evolutionApi) {
        // Padrão Evolution API v2: POST {apiUrl}/message/sendText/{instance}
        final cleanUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
        targetUri = Uri.parse('$cleanUrl/message/sendText/$instanceName');
        body = {
          'number': phoneFormatado,
          'options': {
            'delay': 1200,
            'presence': 'composing',
            'linkPreview': false,
          },
          'textMessage': {
            'text': mensagem,
          },
        };
      } else {
        // Webhook Genérico: envia payload completo do evento
        targetUri = Uri.parse(apiUrl);
        body = {
          'event': 'whatsapp.send_message',
          'phone': phoneFormatado,
          'message': mensagem,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final request = await client.postUrl(targetUri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      if (apiKey.isNotEmpty) {
        request.headers.set('apikey', apiKey);
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      }

      request.write(jsonEncode(body));
      final response = await request.close();

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao disparar API/Webhook: $e');
      return false;
    }
  }

  /// Gera a mensagem padronizada e profissional do resumo do pedido.
  ///
  /// NOTA sobre emojis: usamos sequências \u{XXXXX} explícitas do Dart para
  /// garantir codificação UTF-16 correta ao passar via Uri.encodeComponent
  /// para o wa.me/whatsapp://send. Emojis literais acima do BMP podem ser
  /// corrompidos em duplo-encode em alguns navegadores/shells do Windows.
  static String gerarTextoResumoPedido({
    required String nomeCliente,
    required String numeroPedidoOuId,
    required String tipoAtendimento,
    required String dataHoraPrevista,
    required List<Map<String, dynamic>> itens,
    required double subtotal,
    required double taxaEntrega,
    required double taxaServico,
    required double total,
    required String formaPagamento,
    String? enderecoEntrega,
    String? observacoes,
    String? nomeEmpresa,
    // Se PIX, a chave/payload é enviada como card separado — não embutida aqui.
  }) {
    final buffer = StringBuffer();
    final empresaStr = (nomeEmpresa != null && nomeEmpresa.isNotEmpty) ? nomeEmpresa : 'FINCORE Food';

    // \u{1F44B} = 👋  \u{1F9FE} = 🧾  \u{1F4CD} = 📍  \u{23F0} = ⏰
    buffer.writeln('\u{1F44B} *Ol\u00E1, $nomeCliente!*');
    buffer.writeln('Agradecemos a sua prefer\u00EAncia na *$empresaStr*!');
    buffer.writeln('');
    buffer.writeln('\u{1F9FE} *PEDIDO #$numeroPedidoOuId*');
    buffer.writeln('\u{1F4CD} *Tipo de Pedido:* $tipoAtendimento');
    buffer.writeln('\u{23F0} *Agendado para:* $dataHoraPrevista');
    buffer.writeln('\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500');
    buffer.writeln('*ITENS DO PEDIDO:*');

    for (final item in itens) {
      final qtd = item['qtd'] ?? 1;
      final nome = item['nome'] ?? 'Item';
      final totalItem = (item['total'] as num?)?.toDouble() ?? 0.0;
      final obs = item['obs'] as String?;

      // \u25AA = ▪
      buffer.writeln('\u25AA ${qtd}x *$nome* - R\$ ${totalItem.toStringAsFixed(2)}');
      if (obs != null && obs.isNotEmpty) {
        buffer.writeln('   _(Obs: $obs)_');
      }
    }

    buffer.writeln('\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500');
    buffer.writeln('Subtotal: R\$ ${subtotal.toStringAsFixed(2)}');
    if (taxaEntrega > 0) {
      buffer.writeln('Taxa de Entrega: R\$ ${taxaEntrega.toStringAsFixed(2)}');
    }
    if (taxaServico > 0) {
      buffer.writeln('Taxa de Servi\u00E7o / M\u00E3o de Obra: R\$ ${taxaServico.toStringAsFixed(2)}');
    }
    // \u{1F4B0} = 💰  \u{1F4B3} = 💳
    buffer.writeln('\u{1F4B0} *TOTAL:* *R\$ ${total.toStringAsFixed(2)}*');
    buffer.writeln('\u{1F4B3} *Forma de Pagamento:* $formaPagamento');

    if (enderecoEntrega != null && enderecoEntrega.isNotEmpty) {
      buffer.writeln('');
      // \u{1F6F5} = 🛵
      buffer.writeln('\u{1F6F5} *Endere\u00E7o de Entrega:*');
      buffer.writeln(enderecoEntrega);
    }

    if (observacoes != null && observacoes.isNotEmpty) {
      buffer.writeln('');
      // \u{1F4DD} = 📝
      buffer.writeln('\u{1F4DD} *Observa\u00E7\u00F5es Gerais:*');
      buffer.writeln(observacoes);
    }

    buffer.writeln('');
    // \u{1F680} = 🚀
    buffer.writeln('Qualquer d\u00FAvida, estamos \u00E0 disposi\u00E7\u00E3o! \u{1F680}');

    return buffer.toString();
  }

  /// Gera mensagem template para notificação de saída para entrega
  static String gerarTextoSaiuParaEntrega({
    required String nomeCliente,
    required String numeroPedidoOuId,
    String? nomeEmpresa,
  }) {
    final emp = (nomeEmpresa != null && nomeEmpresa.isNotEmpty) ? nomeEmpresa : 'Nossa Loja';
    // \u{1F6F5}=🛵 \u{1F389}=🎉 \u{1F44B}=👋 \u{1F60D}=😍 \u{1F4AC}=💬 \u{2728}=✨
    return '\u{1F6F5} *SEU PEDIDO SAIU PARA ENTREGA!* \u{1F389}\n\n'
        '\u{1F44B} Ol\u00E1, *$nomeCliente*!\n\n'
        'Boas not\u00EDcias: o seu pedido *#$numeroPedidoOuId* acabou de sair fresquinho e est\u00E1 a caminho com o nosso entregador! \u{1F60D}\u{2728}\n\n'
        'Por favor, fique atento(a) \u00E0 campainha ou interfone.\n'
        'Qualquer d\u00FAvida ou orienta\u00E7\u00E3o de entrega, basta responder aqui! \u{1F4AC}\n\n'
        'Agradecemos a sua prefer\u00EAncia na *$emp*! Tenha um excelente momento! \u{1F60A}\u{2764}\u{FE0F}';
  }

  /// Gera mensagem padrão para contato via WhatsApp no kanban
  static String gerarTextoContatoKanban({
    required String nomeCliente,
    required String numeroPedidoOuId,
    String? nomeEmpresa,
  }) {
    final emp = (nomeEmpresa != null && nomeEmpresa.isNotEmpty) ? nomeEmpresa : 'Nossa Loja';
    // \u{1F44B}=👋 \u{1F60A}=😊 \u{1F4C4}=📄 \u{1F4AC}=💬 \u{2728}=✨
    return '\u{1F44B} *Ol\u00E1, $nomeCliente!* Tudo bem com voc\u00EA?\n\n'
        'Aqui \u00E9 da equipe da *$emp*! \u{1F60A}\u{2728}\n\n'
        'Estamos entrando em contato referente ao seu pedido *#$numeroPedidoOuId*.\n'
        'Podemos te ajudar com alguma informa\u00E7\u00E3o ou atualiza\u00E7\u00E3o do seu atendimento? \u{1F4AC}\n\n'
        'Estamos \u00E0 total disposi\u00E7\u00E3o!';
  }

  /// Gera mensagem profissional e educada de lembrete/cobrança de pagamento (Contas a Receber)
  static String gerarTextoLembretePagamento({
    required String nomeCliente,
    required String numeroPedidoOuId,
    required double valor,
    String? dataVencimento,
    String? nomeEmpresa,
  }) {
    final emp = (nomeEmpresa != null && nomeEmpresa.isNotEmpty) ? nomeEmpresa : 'Nossa Loja';
    final buffer = StringBuffer();
    // \u{1F44B}=👋 \u{1F4C4}=📄 \u{1F4B0}=💰 \u{1F4C5}=📅 \u{1F447}=👇 \u{1F60A}=😊 \u{2728}=✨
    buffer.writeln('\u{1F44B} *Ol\u00E1, $nomeCliente!* Tudo bem? \u{1F60A}');
    buffer.writeln('Aqui \u00E9 da equipe de atendimento da *$emp*.');
    buffer.writeln('');
    buffer.writeln('\u{1F4C4} *Informa\u00E7\u00F5es de Pagamento - Pedido #$numeroPedidoOuId*');
    buffer.writeln('\u{1F4B0} *Valor Total:* R\$ ${valor.toStringAsFixed(2)}');
    if (dataVencimento != null && dataVencimento.isNotEmpty) {
      buffer.writeln('\u{1F4C5} *Data:* $dataVencimento');
    }
    buffer.writeln('');
    buffer.writeln('Para sua maior comodidade, disponibilizamos o pagamento r\u00E1pido via PIX! \u{1F447}');
    buffer.writeln('Basta utilizar a chave ou c\u00F3digo copia e cola enviado.');
    buffer.writeln('');
    buffer.writeln('Assim que realizar a transfer\u00EAncia, por gentileza nos envie o comprovante por aqui.');
    buffer.writeln('Agradecemos imensamente pela prefer\u00EAncia! \u{2728}');
    return buffer.toString();
  }

  // ── GERENCIAMENTO DE TEMPLATES DINÂMICOS & CONFIGURÁVEIS ──────────────────

  static const String _storageKeyPrefix = 'fincore_whatsapp_templates_';

  /// Retorna os templates padrão do sistema com textos ricos, emojis e variáveis dinâmicas
  static List<WhatsAppTemplate> getTemplatesPadrao({
    String? nomeEmpresa,
    String? linkCardapio,
  }) {
    final emp = (nomeEmpresa != null && nomeEmpresa.isNotEmpty) ? nomeEmpresa : '{loja}';
    final cardapio = (linkCardapio != null && linkCardapio.isNotEmpty) ? linkCardapio : '{link_cardapio}';

    return [
      WhatsAppTemplate(
        id: 'comprovante',
        titulo: 'Comprovante do Pedido (PDV / Balcão)',
        emoji: '🧾',
        descricao: 'Comprovante discriminado com itens, valores, dados de pagamento e entrega emitido no Frente de Caixa da loja.',
        categoria: 'pedido',
        isPadrao: true,
        evento: 'pedido_criado',
        ordem: 0,
        conteudo: '🧾 *COMPROVANTE DE VENDA #{pedido}*\n'
            '🏢 *{loja}*\n'
            '📍 *Canal:* Atendimento Balcão / Frente de Caixa\n\n'
            '👋 *Olá, {cliente}!* Agradecemos a sua preferência em nossa loja física! Segue o seu comprovante detalhado:\n\n'
            '🛒 *Itens Registrados:*\n'
            '{itens}\n\n'
            '💰 *Subtotal:* R\$ {subtotal}\n'
            '{se taxa_entrega > 0}🛵 *Taxa de Entrega:* R\$ {taxa_entrega}\n{/se}'
            '{se taxa_servico > 0}🛎️ *Taxa de Serviço:* R\$ {taxa_servico}\n{/se}'
            '{se desconto > 0}🏷️ *Desconto:* R\$ {desconto}\n{/se}'
            '💵 *TOTAL:* R\$ {total}\n\n'
            '💳 *Forma de Pagamento:* {forma_pagamento}\n'
            '📊 *Status:* {status_pagamento}\n\n'
            '{bloco_pix}\n\n'
            '{bloco_endereco}\n\n'
            '📱 *Acompanhe seu pedido em tempo real pelo link:*\n'
            '{link_rastreio}\n\n'
            'Obrigado pela preferência e volte sempre! ✨',
      ),
      WhatsAppTemplate(
        id: 'pedido_aprovado',
        titulo: 'Pedido Online Aprovado (Cardápio Web)',
        emoji: '🌐',
        descricao: 'Notifica o cliente que seu pedido feito pelo Cardápio Digital Web foi aceito e encaminhado para a cozinha.',
        categoria: 'pedido',
        isPadrao: true,
        evento: 'pedido_aprovado',
        ordem: 1,
        conteudo: '🌐 *PEDIDO ONLINE #{pedido} APROVADO!* 🎉\n'
            '🏢 *{loja}*\n'
            '📱 *Canal:* Cardápio Digital Online\n\n'
            '👋 *Olá, {cliente}!* Recebemos o seu pedido realizado pelo nosso Cardápio Online!\n'
            'Ele foi *aprovado com sucesso* e já está sendo preparado com todo carinho pela nossa equipe! 😋🔥\n\n'
            '🛒 *Itens do Pedido:*\n'
            '{itens}\n\n'
            '💰 *Subtotal:* R\$ {subtotal}\n'
            '{se taxa_entrega > 0}🛵 *Taxa de Entrega:* R\$ {taxa_entrega}\n{/se}'
            '{se taxa_servico > 0}🛎️ *Taxa de Serviço:* R\$ {taxa_servico}\n{/se}'
            '{se desconto > 0}🏷️ *Desconto:* R\$ {desconto}\n{/se}'
            '💵 *TOTAL:* R\$ {total}\n\n'
            '💳 *Forma de Pagamento:* {forma_pagamento}\n\n'
            '{bloco_pix}\n\n'
            '{bloco_endereco}\n\n'
            '📱 *Acompanhe o preparo e a entrega em tempo real:*\n'
            '{link_rastreio}\n\n'
            'Qualquer dúvida ou alteração, basta nos responder por aqui! ✨',
      ),
      WhatsAppTemplate(
        id: 'saudacao',
        titulo: 'Saudação & Atendimento',
        emoji: '👋',
        descricao: 'Mensagem calorosa de boas-vindas e atendimento geral ao cliente.',
        categoria: 'atendimento',
        isPadrao: true,
        evento: 'geral',
        ordem: 0,
        conteudo: '👋 *Olá, {cliente}!* Tudo bem com você? 😊✨\n\n'
            'Aqui é da equipe da *$emp*!\n'
            'Passando para saber como podemos te atender hoje ou se gostaria de ver nossas delícias fresquinhas! 🍕🍔\n\n'
            'Estamos à sua total disposição! 🚀',
      ),
      WhatsAppTemplate(
        id: 'contato_pedido',
        titulo: 'Acompanhamento do Pedido',
        emoji: '🛎️',
        descricao: 'Informações sobre status e acompanhamento de pedido em andamento.',
        categoria: 'pedido',
        isPadrao: true,
        evento: 'pedido_criado',
        ordem: 1,
        conteudo: '👋 *Olá, {cliente}!* Tudo bem? 😊\n\n'
            'Aqui é da equipe da *$emp* referente ao seu pedido *#{pedido}*. ✨\n\n'
            '💰 *Total:* R\$ {total}\n'
            '💳 *Pagamento:* {forma_pagamento}\n\n'
            '{se forma_pagamento == PIX}\n'
            '🔑 *Chave PIX:* {chave_pix}\n\n'
            '{/se}'
            '{se tipo_pedido == Entrega}\n'
            '📍 *Endereço de Entrega:* {endereco}\n\n'
            '{senao}\n'
            '🏢 *Retirada na Loja:* {endereco_empresa}\n\n'
            '{/se}'
            '📱 *Acompanhe seu pedido em tempo real pelo link:*\n'
            '{link_rastreio}\n\n'
            'Se precisar de alguma informação, alteração ou suporte, basta nos responder por aqui! 💬',
      ),
      WhatsAppTemplate(
        id: 'pedido_pronto',
        titulo: 'Pedido Pronto (Retirada Balcão)',
        emoji: '🛍️',
        descricao: 'Avisa o cliente que o pedido está pronto para ser retirado na loja.',
        categoria: 'pedido',
        isPadrao: true,
        evento: 'pedido_pronto',
        ordem: 2,
        conteudo: '🛍️ *SEU PEDIDO ESTÁ PRONTO!* 🎉✨\n\n'
            '👋 Olá, *{cliente}*!\n'
            'O seu pedido *#{pedido}* já foi preparado e está prontinho esperando por você na *$emp*! 😋🔥\n\n'
            '🏢 *Local de Retirada:* {endereco_empresa}\n\n'
            'Pode vir retirar quando quiser. Estamos te esperando com tudo fresquinho! 🚀',
      ),
      WhatsAppTemplate(
        id: 'saiu_entrega',
        titulo: 'Saiu para Entrega (Delivery)',
        emoji: '🛵',
        descricao: 'Notifica que o entregador saiu com o pedido.',
        categoria: 'entrega',
        isPadrao: true,
        evento: 'saiu_entrega',
        ordem: 3,
        conteudo: '🛵 *SEU PEDIDO SAIU PARA ENTREGA!* 🎉🚀\n\n'
            '👋 Olá, *{cliente}*!\n'
            'Boas notícias: o seu pedido *#{pedido}* acabou de sair e está a caminho com o nosso entregador! 😍✨\n\n'
            '📍 *Endereço de Entrega:* {endereco}\n\n'
            '{se entregador != "A definir"}\n'
            '🛵 *Entregador:* {entregador}\n\n'
            '{/se}'
            '📱 *Acompanhe o status pelo link:*\n'
            '{link_rastreio}\n\n'
            'Por favor, fique atento(a) à campainha, interfone ou portaria.\n'
            'Qualquer orientação para o entregador, pode nos avisar aqui! 💬\n\n'
            'Agradecemos a preferência na *$emp*! Tenha um excelente momento! ❤️',
      ),
      WhatsAppTemplate(
        id: 'cobranca_pix',
        titulo: 'Lembrete de Pagamento & PIX',
        emoji: '💳',
        descricao: 'Envio de detalhes de pagamento e chave PIX com cordialidade.',
        categoria: 'financeiro',
        isPadrao: true,
        evento: 'pedido_criado',
        condicaoFormaPagamento: 'PIX',
        condicaoStatusPagamento: 'PENDENTE',
        ordem: 4,
        conteudo: '👋 *Olá, {cliente}!* Tudo bem? 😊\n\n'
            'Aqui é da equipe de atendimento da *$emp*.\n\n'
            '📄 *Informações de Pagamento — Pedido #{pedido}*\n'
            '💰 *Valor Total:* R\$ {total}\n'
            '💳 *Forma:* {forma_pagamento}\n\n'
            '{se forma_pagamento == PIX}\n'
            'Para sua maior comodidade, disponibilizamos pagamento rápido via PIX! 👇\n'
            '🔑 *Chave PIX:* {chave_pix}\n\n'
            '{/se}'
            'Assim que efetuar o pagamento, por gentileza nos envie o comprovante por aqui. Muito obrigado! ✨',
      ),
      WhatsAppTemplate(
        id: 'cardapio_digital',
        titulo: 'Cardápio Digital & Novidades',
        emoji: '✨',
        descricao: 'Divulga o link do cardápio digital oficial para o cliente.',
        categoria: 'marketing',
        isPadrao: true,
        evento: 'geral',
        ordem: 5,
        conteudo: '✨ *Olá, {cliente}!* Bateu aquela fome? 😋🔥\n\n'
            'Confira o nosso cardápio digital completo com fotos, promoções e novidades fresquinhas da *$emp*:\n\n'
            '🌐 *Acesse o link e faça seu pedido direto por aqui:*\n'
            '$cardapio\n\n'
            'É super rápido, fácil e você acompanha o preparo em tempo real! 🚀🍔',
      ),
      WhatsAppTemplate(
        id: 'confirmar_endereco',
        titulo: 'Confirmação de Endereço',
        emoji: '📍',
        descricao: 'Confirma o local de entrega antes do envio.',
        categoria: 'entrega',
        isPadrao: true,
        evento: 'pedido_criado',
        ordem: 6,
        conteudo: '📍 *Olá, {cliente}!* Tudo bem? 😊\n\n'
            'Por favor, confirme se o endereço de entrega do seu pedido *#{pedido}* está correto:\n\n'
            '🏠 *{endereco}*\n\n'
            'Podemos despachar para este endereço? Agradecemos a confirmação rápida! 🛵✨',
      ),
      WhatsAppTemplate(
        id: 'avaliacao_pos_venda',
        titulo: 'Avaliação & Pós-Venda',
        emoji: '⭐',
        descricao: 'Agradecimento pós-entrega com link para avaliação rápida da experiência do cliente.',
        categoria: 'marketing',
        isPadrao: true,
        evento: 'pedido_entregue',
        ordem: 7,
        conteudo: '❤️ *Olá, {primeiro_nome}!* Esperamos que sua experiência tenha sido maravilhosa! ✨\n\n'
            'Seu pedido *#{pedido}* foi entregue com muito carinho pela *$emp*! 🍲😋\n\n'
            'Poderia nos avaliar em 15 segundos? Sua opinião é essencial para mantermos a qualidade do nosso atendimento:\n'
            '⭐ *Avalie seu pedido aqui:* {link_avaliacao}\n\n'
            'Muito obrigado pela confiança e até o próximo pedido! 🚀🍕',
      ),
      WhatsAppTemplate(
        id: 'pedido_cancelado',
        titulo: 'Pedido Cancelado',
        emoji: '❌',
        descricao: 'Notifica o cliente com cordialidade e transparência quando um pedido é cancelado.',
        categoria: 'pedido',
        isPadrao: true,
        evento: 'pedido_cancelado',
        ordem: 8,
        conteudo: '❌ *AVISO — PEDIDO #{pedido} CANCELADO*\n\n'
            '👋 Olá, *{cliente}*!\n\n'
            'Informamos que o seu pedido *#{pedido}* na *$emp* foi cancelado.\n\n'
            '{se observacoes != ""}\n'
            '📝 *Motivo / Observações:* {observacoes}\n\n'
            '{/se}'
            'Caso você já tenha efetuado qualquer pagamento via PIX, nosso time providenciará o estorno de forma imediata.\n\n'
            'Pedimos sinceras desculpas pelo ocorrido. Se tiver qualquer dúvida ou desejar refazer o pedido, basta responder a esta mensagem! 💬🙏',
      ),
    ];
  }

  static const String _eventTemplatesStorageKeyPrefix = 'fincore_whatsapp_event_templates_';

  /// Retorna o mapa de qual template está vinculado a cada evento operacional
  static Future<Map<String, String>> getTemplatesEventosConfigurados({String? tenantId}) async {
    final Map<String, String> padroes = {
      kEventoPedidoCriadoPdv: 'comprovante',
      kEventoPedidoAprovadoWeb: 'pedido_aprovado',
      kEventoPedidoPronto: 'pedido_pronto',
      kEventoPedidoSaiuEntrega: 'saiu_entrega',
      kEventoPedidoEntregue: 'avaliacao_pos_venda',
      kEventoPedidoCancelado: 'pedido_cancelado',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_eventTemplatesStorageKeyPrefix${tenantId ?? 'default'}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v != null && v.toString().isNotEmpty) {
            padroes[k] = v.toString();
          }
        });
      }
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao carregar templates vinculados a eventos: $e');
    }

    return padroes;
  }

  /// Salva o vínculo de templates por evento operacional
  static Future<bool> salvarTemplatesEventosConfigurados(
    Map<String, String> mapping, {
    String? tenantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_eventTemplatesStorageKeyPrefix${tenantId ?? 'default'}';
      await prefs.setString(key, jsonEncode(mapping));
      return true;
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao salvar templates vinculados a eventos: $e');
      return false;
    }
  }

  /// Carrega a lista de templates salvos pelo usuário para a empresa ativa (ou os padrões se não houver)
  static Future<List<WhatsAppTemplate>> getTemplates({
    String? tenantId,
    String? nomeEmpresa,
    String? linkCardapio,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_storageKeyPrefix${tenantId ?? 'default'}';
      final rawJson = prefs.getString(key);

      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        final templates = decoded
            .map((item) => WhatsAppTemplate.fromJson(item as Map<String, dynamic>))
            .toList();

        if (templates.isNotEmpty) {
          // Garante que o template oficial de pedido cancelado esteja disponível mesmo em bases já salvas
          if (!templates.any((t) => t.id == 'pedido_cancelado' || t.evento == 'pedido_cancelado')) {
            final padroes = getTemplatesPadrao(nomeEmpresa: nomeEmpresa, linkCardapio: linkCardapio);
            final canceladoT = padroes.firstWhere(
              (t) => t.id == 'pedido_cancelado',
              orElse: () => padroes.last,
            );
            templates.add(canceladoT);
          }
          // Garante que o template oficial de pedido aprovado esteja disponível mesmo em bases já salvas
          if (!templates.any((t) => t.id == 'pedido_aprovado' || t.evento == 'pedido_aprovado' || t.evento == 'pedido_aprovado_web')) {
            final padroes = getTemplatesPadrao(nomeEmpresa: nomeEmpresa, linkCardapio: linkCardapio);
            final aprovadoT = padroes.firstWhere(
              (t) => t.id == 'pedido_aprovado',
              orElse: () => padroes.first,
            );
            templates.add(aprovadoT);
          }
          return templates;
        }
      }
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao carregar templates salvos: $e');
    }

    return getTemplatesPadrao(nomeEmpresa: nomeEmpresa, linkCardapio: linkCardapio);
  }

  /// Salva a lista de templates customizados do usuário
  static Future<bool> salvarTemplates(
    List<WhatsAppTemplate> templates, {
    String? tenantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_storageKeyPrefix${tenantId ?? 'default'}';
      final jsonList = templates.map((t) => t.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
      return true;
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao salvar templates: $e');
      return false;
    }
  }

  /// Redefine todos os templates para a configuração padrão recomendada
  static Future<void> resetarTemplatesPadrao({
    String? tenantId,
    String? nomeEmpresa,
    String? linkCardapio,
  }) async {
    final padroes = getTemplatesPadrao(nomeEmpresa: nomeEmpresa, linkCardapio: linkCardapio);
    await salvarTemplates(padroes, tenantId: tenantId);
  }

  static const String _pdvConfigStorageKeyPrefix = 'fincore_whatsapp_pdv_config_';

  /// Carrega as preferências operacionais de WhatsApp do Frente de Caixa
  static Future<WhatsAppPdvConfig> getPdvConfig({String? tenantId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pdvConfigStorageKeyPrefix${tenantId ?? 'default'}';
      final rawJson = prefs.getString(key);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        return WhatsAppPdvConfig.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao carregar config PDV: $e');
    }
    return const WhatsAppPdvConfig();
  }

  /// Salva as preferências operacionais de WhatsApp do Frente de Caixa
  static Future<bool> salvarPdvConfig(
    WhatsAppPdvConfig config, {
    String? tenantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pdvConfigStorageKeyPrefix${tenantId ?? 'default'}';
      await prefs.setString(key, jsonEncode(config.toJson()));
      return true;
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao salvar config PDV: $e');
      return false;
    }
  }

  /// Formata o endereço completo da empresa a partir do TenantContext ou modelo CoreEmpresa
  static String formatarEnderecoEmpresa([CoreEmpresa? empresa]) {
    try {
      final e = empresa ?? (TenantContext().hasContext ? TenantContext().empresa : null);
      if (e != null) {
        final partes = <String>[];
        if (e.logradouro != null && e.logradouro!.trim().isNotEmpty) {
          var rua = e.logradouro!.trim();
          if (e.numero != null && e.numero!.trim().isNotEmpty) {
            rua += ', ${e.numero!.trim()}';
          }
          if (e.complemento != null && e.complemento!.trim().isNotEmpty) {
            rua += ' (${e.complemento!.trim()})';
          }
          partes.add(rua);
        }
        if (e.bairro != null && e.bairro!.trim().isNotEmpty) partes.add(e.bairro!.trim());
        if (e.cidade != null && e.cidade!.trim().isNotEmpty) {
          var cid = e.cidade!.trim();
          if (e.estado != null && e.estado!.trim().isNotEmpty) cid += '/${e.estado!.trim()}';
          partes.add(cid);
        }
        if (partes.isNotEmpty) return partes.join(' - ');
      }
    } catch (_) {}
    return 'Endereço da nossa loja';
  }

  /// Expressão regular para blocos condicionais:
  /// `{se expressao}...{/se}`
  /// ou
  /// `{se expressao}...{senao}...{/se}`
  static final RegExp _regexCondicional = RegExp(
    r'\{se\s+([^}]+)\}([\s\S]*?)(?:\{senao\}([\s\S]*?))?\{/se\}',
    caseSensitive: false,
  );

  /// Processa e resolve todos os blocos condicionais do template.
  /// Suporta recursão/aninhamento de até 5 níveis.
  static String processarCondicionais(String template, Map<String, String> variaveis) {
    String resultado = template;
    int iteracoes = 0;
    while (_regexCondicional.hasMatch(resultado) && iteracoes < 6) {
      iteracoes++;
      resultado = resultado.replaceAllMapped(_regexCondicional, (match) {
        final condicao = match.group(1)?.trim() ?? '';
        final blocoVerdadeiro = match.group(2) ?? '';
        final blocoFalso = match.group(3) ?? '';

        final atendida = avaliarExpressaoCondicional(condicao, variaveis);
        var selecionado = atendida ? blocoVerdadeiro : blocoFalso;
        if (selecionado.startsWith('\n')) {
          selecionado = selecionado.substring(1);
        }
        if (selecionado.endsWith('\n')) {
          selecionado = selecionado.substring(0, selecionado.length - 1);
        }
        return selecionado;
      });
    }
    return resultado;
  }

  /// Avalia expressões com operadores relacionais (==, !=, contem, nao_contem),
  /// operadores lógicos (&&, ||) e truthiness booleano sobre as variáveis contextuais.
  static bool avaliarExpressaoCondicional(String expressaoRaw, Map<String, String> variaveis) {
    final exp = expressaoRaw.trim();
    if (exp.isEmpty) return true;

    // Disjunções (OR - '||')
    final orPartes = exp.split('||');
    for (final orParte in orPartes) {
      if (_avaliarClausulaAnd(orParte, variaveis)) {
        return true;
      }
    }
    return false;
  }

  static bool _avaliarClausulaAnd(String clausulaAndRaw, Map<String, String> variaveis) {
    final andPartes = clausulaAndRaw.split('&&');
    for (final termo in andPartes) {
      if (!_avaliarTermoAtomico(termo, variaveis)) {
        return false;
      }
    }
    return true;
  }

  static bool _avaliarTermoAtomico(String termoRaw, Map<String, String> variaveis) {
    final t = termoRaw.trim();
    if (t.isEmpty) return true;

    String? operador;
    int opIndex = -1;
    int opLength = 0;

    final operadores = ['!=', '==', '=', ' nao_contem ', ' não_contém ', ' contem ', ' contém '];
    for (final op in operadores) {
      final idx = t.toLowerCase().indexOf(op);
      if (idx != -1) {
        operador = op.trim();
        opIndex = idx;
        opLength = op.length;
        break;
      }
    }

    if (operador != null && opIndex != -1) {
      final leftRaw = t.substring(0, opIndex).trim();
      final rightRaw = t.substring(opIndex + opLength).trim();

      final valAtual = _obterValorVariavel(leftRaw, variaveis);
      final valEsperado = _limparValorLiteral(rightRaw);

      final valAtualNorm = valAtual.toLowerCase().trim();
      final valEspNorm = valEsperado.toLowerCase().trim();
      final leftKeyNorm = leftRaw.replaceAll(RegExp(r'[{}]'), '').trim().toLowerCase();

      switch (operador) {
        case '==':
        case '=':
          return _compararIgualdadeInteligente(leftKeyNorm, valAtualNorm, valEspNorm);
        case '!=':
          return !_compararIgualdadeInteligente(leftKeyNorm, valAtualNorm, valEspNorm);
        case 'contem':
        case 'contém':
          return valAtualNorm.contains(valEspNorm);
        case 'nao_contem':
        case 'não_contém':
          return !valAtualNorm.contains(valEspNorm);
      }
    }

    // Termo unário (Truthiness direto)
    final keyNorm = t.replaceAll(RegExp(r'[{}]'), '').trim().toLowerCase();
    final val = _obterValorVariavel(keyNorm, variaveis);
    final valNorm = val.toLowerCase().trim();

    if (keyNorm == 'pagamento_pendente') {
      return valNorm == 'true' || valNorm.contains('pend') || valNorm == 'sim';
    }
    if (keyNorm == 'is_pix') {
      return valNorm == 'true' || valNorm.contains('pix');
    }
    if (keyNorm == 'is_entrega') {
      return valNorm == 'true' || valNorm.contains('entrega');
    }
    if (keyNorm == 'is_retirada') {
      return valNorm == 'true' || valNorm.contains('retirada') || valNorm.contains('balcao');
    }

    return valNorm.isNotEmpty &&
        valNorm != '0' &&
        valNorm != '0,00' &&
        valNorm != 'false' &&
        valNorm != 'sem observações' &&
        valNorm != 'não necessário' &&
        valNorm != 'a definir' &&
        valNorm != 'a confirmar';
  }

  static String _obterValorVariavel(String keyRaw, Map<String, String> variaveis) {
    final clean = keyRaw.replaceAll(RegExp(r'[{}]'), '').trim().toLowerCase();

    if (variaveis.containsKey('{$clean}')) return variaveis['{$clean}']!;
    if (variaveis.containsKey(clean)) return variaveis[clean]!;

    if (clean == 'is_pix') {
      final fp = variaveis['{forma_pagamento}'] ?? variaveis['forma_pagamento'] ?? '';
      return fp.toLowerCase().contains('pix') ? 'true' : 'false';
    }
    if (clean == 'is_entrega') {
      final tp = variaveis['{tipo_pedido}'] ?? variaveis['tipo_pedido'] ?? '';
      return tp.toLowerCase().contains('entrega') ? 'true' : 'false';
    }
    if (clean == 'is_retirada') {
      final tp = variaveis['{tipo_pedido}'] ?? variaveis['tipo_pedido'] ?? '';
      return (tp.toLowerCase().contains('retirada') ||
              tp.toLowerCase().contains('balcao') ||
              tp.toLowerCase().contains('balcão'))
          ? 'true'
          : 'false';
    }
    if (clean == 'pagamento_pendente') {
      final st = variaveis['{status_pagamento}'] ?? variaveis['status_pagamento'] ?? '';
      return (st.toLowerCase().contains('pend') || variaveis['{pagamento_pendente}'] == 'true')
          ? 'true'
          : 'false';
    }
    return '';
  }

  static String _limparValorLiteral(String literal) {
    var s = literal.trim();
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  static bool _compararIgualdadeInteligente(String keyNorm, String valAtualNorm, String valEspNorm) {
    if (keyNorm == 'forma_pagamento') {
      if (valEspNorm == 'pix') return valAtualNorm.contains('pix');
      if (valEspNorm == 'cartao' || valEspNorm == 'cartão') return valAtualNorm.contains('cart');
      if (valEspNorm == 'dinheiro') return valAtualNorm.contains('dinh');
    }
    if (keyNorm == 'tipo_pedido') {
      if (valEspNorm == 'entrega') return valAtualNorm.contains('entrega');
      if (valEspNorm == 'retirada' || valEspNorm == 'balcao' || valEspNorm == 'balcão') {
        return valAtualNorm.contains('retirada') || valAtualNorm.contains('balcao') || valAtualNorm.contains('balcão');
      }
    }
    if (keyNorm == 'status_pagamento' || keyNorm == 'pagamento') {
      if (valEspNorm == 'pendente') return valAtualNorm.contains('pend');
      if (valEspNorm == 'confirmado' || valEspNorm == 'pago') {
        return valAtualNorm.contains('conf') || valAtualNorm.contains('pago');
      }
    }
    return valAtualNorm == valEspNorm;
  }

  /// Substitui as tags dinâmicas e processa blocos condicionais {se ...} ... {/se}.
  static String interpolarTemplate(
    String template,
    Map<String, String> variaveis,
  ) {
    // 1. Processa blocos condicionais {se ...} ... {senao} ... {/se}
    String resultado = processarCondicionais(template, variaveis);

    // 2. Substitui variáveis dinâmicas
    variaveis.forEach((tag, valor) {
      if (tag == '{pedido}') {
        final numLimpo = valor.startsWith('#') ? valor.substring(1) : valor;
        resultado = resultado.replaceAll('#{pedido}', '#$numLimpo');
        resultado = resultado.replaceAll('{pedido}', valor);
      } else {
        resultado = resultado.replaceAll(tag, valor);
      }
    });

    // 3. Remove duplicidades acidentais
    resultado = resultado.replaceAll('##', '#');

    // 4. Limpeza de quebras de linha excessivas (mais de 2 consecutivas)
    resultado = resultado.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    return resultado;
  }

  /// Formata quantidades numéricas para exibição amigável (ex: 50.0 -> 50, 1.5 -> 1,5)
  static String formatarQuantidadeDisplay(dynamic rawQtd) {
    if (rawQtd == null) return '1';
    if (rawQtd is num) {
      if (rawQtd % 1 == 0) return rawQtd.toInt().toString();
      return rawQtd.toString().replaceAll('.', ',');
    }
    final parsed = double.tryParse(rawQtd.toString());
    if (parsed != null) {
      if (parsed % 1 == 0) return parsed.toInt().toString();
      return parsed.toString().replaceAll('.', ',');
    }
    return rawQtd.toString();
  }

  /// Formata um endereço bruto (string comum ou JSON serializado vindo do Cardápio Web)
  /// para uma apresentação amigável e limpa para envio via WhatsApp.
  static String formatarEnderecoCliente(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final fmtStr = decoded['formatado']?.toString().trim();
          final ref = decoded['referencia']?.toString().trim();
          if (fmtStr != null && fmtStr.isNotEmpty) {
            if (ref != null && ref.isNotEmpty && !fmtStr.contains('(Ref:')) {
              return '$fmtStr (Ref: $ref)';
            }
            return fmtStr;
          }
          final logradouro = decoded['logradouro']?.toString().trim() ?? '';
          final numero = decoded['numero']?.toString().trim() ?? '';
          final bairro = decoded['bairro']?.toString().trim() ?? '';
          final cidade = decoded['cidade']?.toString().trim() ?? '';
          final uf = decoded['uf']?.toString().trim() ?? '';
          final complemento = decoded['complemento']?.toString().trim() ?? '';
          final cep = decoded['cep']?.toString().trim() ?? '';

          final partes = <String>[];
          if (logradouro.isNotEmpty) {
            partes.add(numero.isNotEmpty ? '$logradouro, $numero' : logradouro);
          }
          if (complemento.isNotEmpty) partes.add(complemento);
          if (bairro.isNotEmpty) partes.add(bairro);
          if (cidade.isNotEmpty) partes.add(uf.isNotEmpty ? '$cidade - $uf' : cidade);
          if (cep.isNotEmpty) partes.add('CEP: $cep');
          if (ref != null && ref.isNotEmpty) partes.add('(Ref: $ref)');

          if (partes.isNotEmpty) return partes.join(' - ');
        }
      } catch (_) {}
    }
    return trimmed;
  }

  /// Formata uma lista de itens para texto WhatsApp com marcadores:
  /// ▪ 2x X-Salada - R$ 40,00
  static String formatarItensParaWhatsApp(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) return 'Nenhum item informado';
    final lines = <String>[];
    for (final it in itens) {
      final qtd = formatarQuantidadeDisplay(it['qtd']);
      final nome = it['nome'] ?? 'Item';
      final totalItem = (it['total'] as num?)?.toDouble();
      final obs = it['obs'] as String?;
      final valorStr = totalItem != null
          ? ' - R\$ ${totalItem.toStringAsFixed(2).replaceAll('.', ',')}'
          : '';
      var line = '▪ ${qtd}x *$nome*$valorStr';
      if (obs != null && obs.isNotEmpty) {
        line += '\n   _(Obs: $obs)_';
      }
      lines.add(line);
    }
    return lines.join('\n');
  }

  /// Formata uma lista de itens em texto resumido em linha única:
  /// 2x X-Salada, 1x Coca-Cola 2L
  static String formatarItensResumo(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) return 'Nenhum item';
    return itens.map((it) {
      final qtd = formatarQuantidadeDisplay(it['qtd']);
      final nome = it['nome'] ?? 'Item';
      return '${qtd}x $nome';
    }).join(', ');
  }

  /// Cache em memória da URL base do Cardápio Digital Web (configurada nas preferências da empresa)
  static String _cachedBaseUrlCardapio = 'https://fincore-cardapio-web.vercel.app';

  /// Atualiza o cache local da URL base do Cardápio Digital a partir das preferências do usuário/tenant.
  static Future<void> atualizarCacheUrlCardapio({String? tenantId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : '');
      final saved = (tId.isNotEmpty ? prefs.getString('cardapio_base_url_$tId') : null) ??
          prefs.getString('cardapio_base_url');
      if (saved != null && saved.trim().isNotEmpty) {
        _cachedBaseUrlCardapio = saved.trim();
      }
    } catch (_) {}
  }

  /// Retorna a URL base do Cardápio Digital Web (do cache ou padrão).
  static String get baseUrlCardapioPadrao => _cachedBaseUrlCardapio;

  /// Monta a URL oficial completa do Cardápio Digital da loja com o parâmetro tenant_id se aplicável.
  static String montarUrlCardapioDigital({
    required String baseUrl,
    String? tenantId,
  }) {
    final cleanBase = baseUrl.trim().isNotEmpty
        ? baseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://fincore-cardapio-web.vercel.app';
    final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : '');
    if (tId.isEmpty || cleanBase.contains('tenant_id=')) return cleanBase;

    final sep = cleanBase.contains('?') ? '&' : '/?';
    return '$cleanBase${sep}tenant_id=$tId';
  }

  /// Monta a URL oficial de rastreio/acompanhamento em tempo real do pedido no Cardápio Digital Web.
  /// Formato: {cardapio_url}/?pedido={num_pedido}&tenant_id={tenant_id}
  static String montarUrlRastreioPedido({
    required String baseUrl,
    required String numeroOuIdPedido,
    String? tenantId,
  }) {
    final cleanBase = baseUrl.trim().isNotEmpty
        ? baseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://fincore-cardapio-web.vercel.app';
    final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : '');
    final numClean = numeroOuIdPedido.replaceAll('#', '').trim();

    final sep = cleanBase.contains('?') ? '&' : '/?';
    final tenantParam = (tId.isNotEmpty && !cleanBase.contains('tenant_id=')) ? '&tenant_id=$tId' : '';
    return '$cleanBase${sep}pedido=$numClean$tenantParam';
  }

  /// Monta a URL oficial de avaliação/pós-venda do pedido no Cardápio Digital Web.
  /// Formato: {cardapio_url}/avaliacao.html?pedido={id_ou_num}&num={num_pedido}&tenant_id={tenant_id}
  static String montarUrlAvaliacaoPedido({
    required String baseUrl,
    required String numeroOuIdPedido,
    String? numeroExibicao,
    String? tenantId,
  }) {
    final cleanBase = baseUrl.trim().isNotEmpty
        ? baseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://fincore-cardapio-web.vercel.app';
    final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : '');
    final numClean = numeroOuIdPedido.replaceAll('#', '').trim();
    final numExibClean = (numeroExibicao != null && numeroExibicao.trim().isNotEmpty && numeroExibicao.trim() != numClean)
        ? numeroExibicao.replaceAll('#', '').trim()
        : '';

    final sep = cleanBase.contains('?') ? '&' : '?';
    final numParam = numExibClean.isNotEmpty ? '&num=$numExibClean' : '';
    final tenantParam = (tId.isNotEmpty && !cleanBase.contains('tenant_id=')) ? '&tenant_id=$tId' : '';
    return '$cleanBase/avaliacao.html${sep}pedido=$numClean$numParam$tenantParam';
  }

  /// Monta o mapa completo de interpolação com as tags operacionais do Food Service,
  /// tags contextuais e tags inteligentes ({bloco_pix}, {bloco_endereco}).
  static Map<String, String> gerarVariaveisInterpolacao({
    required String clienteNome,
    required String nomeEmpresa,
    String? numeroPedido,
    String? pedidoId,
    String? tenantId,
    String? linkCardapioBase,
    String? canalOrigem,
    List<Map<String, dynamic>>? itens,
    double? subtotal,
    double? desconto,
    double? taxaEntrega,
    double? taxaServico,
    double? total,
    String? formaPagamento,
    String? trocoPara,
    String? tipoPedido,
    String? endereco,
    String? enderecoEmpresa,
    String? statusPagamento,
    bool? pagamentoPendente,
    bool? isPix,
    String? observacoes,
    String? previsaoEntrega,
    String? entregador,
    String? mesa,
    String? linkCardapio,
    String? linkRastreio,
    String? linkAvaliacao,
    String? chavePix,
    String? chavePixCopiaCola,
    String? formatoPix,
  }) {
    final nomeLimpo = clienteNome.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    final nomeCompleto = nomeLimpo.isNotEmpty ? nomeLimpo : 'Cliente';
    final primeiroNome = nomeCompleto.split(RegExp(r'\s+')).first;

    final numPedidoFormatado = (numeroPedido != null && numeroPedido.isNotEmpty)
        ? (numeroPedido.startsWith('#') ? numeroPedido : '#$numeroPedido')
        : '#000000';

    final listaItens = itens ?? [];
    final itensTexto = listaItens.isNotEmpty
        ? formatarItensParaWhatsApp(listaItens)
        : 'Nenhum item informado';
    final itensResumoTexto = listaItens.isNotEmpty
        ? formatarItensResumo(listaItens)
        : 'Nenhum item informado';
    final qtdTotalItens = listaItens.isNotEmpty
        ? listaItens.fold<int>(0, (acc, it) => acc + ((it['qtd'] as num?)?.toInt() ?? 1)).toString()
        : '0';

    final totalVal = total ?? 0.0;
    final subtotalVal = subtotal ?? totalVal;
    final descontoVal = desconto ?? 0.0;
    final taxaEntregaVal = taxaEntrega ?? 0.0;
    final taxaServicoVal = taxaServico ?? 0.0;

    String formatarMoeda(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

    final numPedidoId = numPedidoFormatado.replaceAll('#', '').trim();
    final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : '');
    final baseCardapio = (linkCardapioBase != null && linkCardapioBase.trim().isNotEmpty)
        ? linkCardapioBase.trim()
        : _cachedBaseUrlCardapio;

    final linkCardapioResolvido = (linkCardapio != null && linkCardapio.isNotEmpty)
        ? linkCardapio
        : montarUrlCardapioDigital(baseUrl: baseCardapio, tenantId: tId);

    // Se tiver o UUID do pedido (pedidoId), usa-o para compatibilidade total com o Supabase/Vercel
    final idParaRastreio = (pedidoId != null && pedidoId.trim().isNotEmpty)
        ? pedidoId.trim()
        : numPedidoId;

    final linkRastreioResolvido = (linkRastreio != null && linkRastreio.isNotEmpty)
        ? linkRastreio
        : montarUrlRastreioPedido(baseUrl: baseCardapio, numeroOuIdPedido: idParaRastreio, tenantId: tId);

    final linkAvaliacaoResolvido = (linkAvaliacao != null && linkAvaliacao.isNotEmpty)
        ? linkAvaliacao
        : montarUrlAvaliacaoPedido(
            baseUrl: baseCardapio,
            numeroOuIdPedido: idParaRastreio,
            numeroExibicao: numPedidoId.isNotEmpty ? numPedidoId : null,
            tenantId: tId,
          );

    // Resoluções contextuais inteligentes
    final formaPagamentoResolvida = (formaPagamento != null && formaPagamento.trim().isNotEmpty)
        ? formaPagamento.trim()
        : 'Não informada';

    final isPixResolved = isPix ?? formaPagamentoResolvida.toLowerCase().contains('pix');
    final isEntregaResolved = tipoPedido != null && tipoPedido.toLowerCase().contains('entrega');
    final isRetiradaResolved = tipoPedido != null &&
        (tipoPedido.toLowerCase().contains('retirada') ||
            tipoPedido.toLowerCase().contains('balcao') ||
            tipoPedido.toLowerCase().contains('balcão'));

    final statusPagamentoResolvido = (statusPagamento != null && statusPagamento.trim().isNotEmpty)
        ? statusPagamento.trim()
        : (pagamentoPendente == true ? 'Pendente' : (pagamentoPendente == false ? 'Confirmado' : 'Pendente'));

    final isPendente = pagamentoPendente ?? statusPagamentoResolvido.toLowerCase().contains('pend');

    final enderecoEmpresaResolved = (enderecoEmpresa != null && enderecoEmpresa.trim().isNotEmpty)
        ? enderecoEmpresa.trim()
        : formatarEnderecoEmpresa();

    // Bloco inteligente {bloco_pix}
    String blocoPixTexto = '';
    if (isPixResolved &&
        ((chavePix != null && chavePix.trim().isNotEmpty) ||
            (chavePixCopiaCola != null && chavePixCopiaCola.trim().isNotEmpty))) {
      final ch = chavePix?.trim() ?? '';
      final cp = (chavePixCopiaCola != null && chavePixCopiaCola.trim().isNotEmpty) ? chavePixCopiaCola.trim() : '';
      final fmt = (formatoPix ?? 'bloco_completo').trim().toLowerCase();

      if (fmt == 'chave') {
        blocoPixTexto = ch.isNotEmpty ? '🔑 *Chave PIX:* $ch' : (cp.isNotEmpty ? '📋 *PIX Copia e Cola:*\n$cp' : '');
      } else if (fmt == 'copia_cola') {
        blocoPixTexto = cp.isNotEmpty ? '📋 *PIX Copia e Cola:*\n$cp' : (ch.isNotEmpty ? '🔑 *Chave PIX:* $ch' : '');
      } else {
        // bloco_completo
        if (ch.isNotEmpty && cp.isNotEmpty && cp != ch) {
          blocoPixTexto = '🔑 *Chave PIX:* $ch\n\n📋 *Copia e Cola:*\n$cp';
        } else if (ch.isNotEmpty) {
          blocoPixTexto = '🔑 *Chave PIX:* $ch';
        } else if (cp.isNotEmpty) {
          blocoPixTexto = '📋 *PIX Copia e Cola:*\n$cp';
        }
      }
    }

    final enderecoLimpo = formatarEnderecoCliente(endereco);

    // Bloco inteligente {bloco_endereco}
    String blocoEnderecoTexto = '';
    if (isEntregaResolved) {
      blocoEnderecoTexto = '📍 *Endereço de Entrega:* ${(enderecoLimpo.isNotEmpty) ? enderecoLimpo : "Conforme cadastro"}';
    } else if (isRetiradaResolved) {
      blocoEnderecoTexto = '🏢 *Retirada na Loja:* $enderecoEmpresaResolved';
    }

    return {
      '{cliente}': nomeCompleto,
      '{primeiro_nome}': primeiroNome,
      '{loja}': nomeEmpresa.isNotEmpty ? nomeEmpresa : 'Nossa Loja',
      '{pedido}': numPedidoFormatado,
      '{itens}': itensTexto,
      '{itens_resumo}': itensResumoTexto,
      '{quantidade_itens}': qtdTotalItens,
      '{observacoes}': (observacoes != null && observacoes.trim().isNotEmpty)
          ? observacoes.trim()
          : 'Sem observações',
      '{total}': formatarMoeda(totalVal),
      '{subtotal}': formatarMoeda(subtotalVal),
      '{desconto}': formatarMoeda(descontoVal),
      '{taxa_entrega}': formatarMoeda(taxaEntregaVal),
      '{taxa_servico}': formatarMoeda(taxaServicoVal),
      '{forma_pagamento}': formaPagamentoResolvida,
      '{status_pagamento}': statusPagamentoResolvido,
      '{pagamento_pendente}': isPendente ? 'true' : 'false',
      '{is_pix}': isPixResolved ? 'true' : 'false',
      '{is_entrega}': isEntregaResolved ? 'true' : 'false',
      '{is_retirada}': isRetiradaResolved ? 'true' : 'false',
      '{troco_para}': (trocoPara != null && trocoPara.trim().isNotEmpty)
          ? trocoPara.trim()
          : 'Não necessário',
      '{tipo_pedido}': (tipoPedido != null && tipoPedido.trim().isNotEmpty)
          ? tipoPedido.trim()
          : 'Entrega / Retirada',
      '{endereco}': enderecoLimpo.isNotEmpty
          ? enderecoLimpo
          : 'Conforme cadastro / Retirada no balcão',
      '{endereco_empresa}': enderecoEmpresaResolved,
      '{endereco_loja}': enderecoEmpresaResolved,
      '{bloco_pix}': blocoPixTexto,
      '{bloco_endereco}': blocoEnderecoTexto,
      '{previsao_entrega}': (previsaoEntrega != null && previsaoEntrega.trim().isNotEmpty)
          ? previsaoEntrega.trim()
          : 'A confirmar',
      '{entregador}': (entregador != null && entregador.trim().isNotEmpty)
          ? entregador.trim()
          : 'A definir',
      '{mesa}': (mesa != null && mesa.trim().isNotEmpty)
          ? mesa.trim()
          : 'Balcão / Delivery',
      '{link_cardapio}': linkCardapioResolvido,
      '{link_rastreio}': linkRastreioResolvido,
      '{chave_pix}': (chavePix != null && chavePix.trim().isNotEmpty)
          ? chavePix.trim()
          : '',
      '{chave_pix_copia_cola}': (chavePixCopiaCola != null && chavePixCopiaCola.trim().isNotEmpty)
          ? chavePixCopiaCola.trim()
          : (chavePix != null ? chavePix.trim() : ''),
      '{link_avaliacao}': linkAvaliacaoResolvido,
      '{origem}': (() {
        final c = (canalOrigem ?? '').toLowerCase().trim();
        final t = (tipoPedido ?? '').toLowerCase().trim();
        if (c.contains('web') || c.contains('cardapio') || c.contains('online') || t.contains('web') || t.contains('online')) {
          return 'Cardápio Digital Online';
        }
        if (c.contains('whatsapp') || c.contains('ia') || t.contains('whatsapp') || t.contains('ia')) {
          return 'WhatsApp (IA / Atendimento)';
        }
        if (c.contains('mesa') || c.contains('comanda') || t.contains('mesa') || t.contains('comanda')) {
          return 'Mesa / Comanda';
        }
        return 'Atendimento Balcão / Frente de Caixa';
      })(),
      '{canal}': (() {
        final c = (canalOrigem ?? '').toLowerCase().trim();
        final t = (tipoPedido ?? '').toLowerCase().trim();
        if (c.contains('web') || c.contains('cardapio') || c.contains('online') || t.contains('web') || t.contains('online')) {
          return 'Cardápio Web';
        }
        if (c.contains('whatsapp') || c.contains('ia') || t.contains('whatsapp') || t.contains('ia')) {
          return 'WhatsApp Chat';
        }
        if (c.contains('mesa') || c.contains('comanda') || t.contains('mesa') || t.contains('comanda')) {
          return 'Salão / Mesa';
        }
        return 'PDV Balcão';
      })(),
    };
  }

  // ── MODO SIMULAÇÃO / MOCK: POLÍTICAS E DECISÃO DE ENVIO (FASE C) ──────────

  static const String _policiesStorageKeyPrefix = 'fincore_whatsapp_policies_';

  // Identificadores canônicos dos eventos operacionais do FINCORE
  static const String kEventoPedidoCriadoPdv = 'pedido_criado_pdv';
  static const String kEventoPedidoAprovadoWeb = 'pedido_aprovado_web';
  static const String kEventoPedidoPronto = 'pedido_pronto';
  static const String kEventoPedidoSaiuEntrega = 'saiu_entrega';
  static const String kEventoPedidoEntregue = 'pedido_entregue';
  static const String kEventoPedidoCancelado = 'pedido_cancelado';

  // Chaves de idempotência processadas nesta sessão local
  static final Set<String> _simulatedIdempotencyKeys = <String>{};
  static final List<WhatsAppSimulatedDecision> _simulatedHistory = <WhatsAppSimulatedDecision>[];
  static final WhatsAppMessageLogRepository _logRepo = WhatsAppMessageLogRepository();

  /// Repositório de logs e idempotência persistente
  static WhatsAppMessageLogRepository get logRepository => _logRepo;

  /// Notificador reativo para atualizações em tempo real do histórico de simulações
  static final ValueNotifier<int> simulacoesRevision = ValueNotifier<int>(0);

  /// Notificador reativo para solicitações de confirmação manual do operador (Human-in-the-Loop — Fase D2)
  static final ValueNotifier<WhatsAppManualPrompt?> manualPromptNotifier =
      ValueNotifier<WhatsAppManualPrompt?>(null);

  /// Retorna o histórico de decisões simuladas para auditoria visual e testes
  static List<WhatsAppSimulatedDecision> getHistoricoSimulacoes() {
    return List.unmodifiable(_simulatedHistory);
  }

  /// Limpa o histórico de simulações (utilizado em testes unitários)
  static void limparHistoricoSimulacoes() {
    _simulatedIdempotencyKeys.clear();
    _simulatedHistory.clear();
    manualPromptNotifier.value = null;
    _logRepo.limparLogsParaTestes();
    simulacoesRevision.value++;
  }

  /// Retorna as políticas configuradas por evento para o tenant.
  /// Padrão de fábrica estrito: TODOS iniciam como [WhatsAppEventPolicy.desativado].
  static Future<Map<String, WhatsAppEventPolicy>> getPoliticasEventos({String? tenantId}) async {
    final Map<String, WhatsAppEventPolicy> resultado = {
      kEventoPedidoCriadoPdv: WhatsAppEventPolicy.desativado,
      kEventoPedidoAprovadoWeb: WhatsAppEventPolicy.desativado,
      kEventoPedidoPronto: WhatsAppEventPolicy.desativado,
      kEventoPedidoSaiuEntrega: WhatsAppEventPolicy.desativado,
      kEventoPedidoEntregue: WhatsAppEventPolicy.desativado,
      kEventoPedidoCancelado: WhatsAppEventPolicy.desativado,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_policiesStorageKeyPrefix${tenantId ?? 'default'}';
      final rawJson = prefs.getString(key);

      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        decoded.forEach((evento, polStr) {
          if (resultado.containsKey(evento)) {
            resultado[evento] = WhatsAppEventPolicy.values.firstWhere(
              (p) => p.name == polStr,
              orElse: () => WhatsAppEventPolicy.desativado,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao carregar políticas de eventos: $e');
    }

    return resultado;
  }

  /// Salva as políticas configuradas no SharedPreferences local do dispositivo
  static Future<bool> salvarPoliticasEventos(
    Map<String, WhatsAppEventPolicy> politicas, {
    String? tenantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_policiesStorageKeyPrefix${tenantId ?? 'default'}';
      final mapToSave = politicas.map((k, v) => MapEntry(k, v.name));
      await prefs.setString(key, jsonEncode(mapToSave));
      return true;
    } catch (e) {
      debugPrint('[WhatsAppService] Erro ao salvar políticas de eventos: $e');
      return false;
    }
  }

  /// Avalia a HIERARQUIA COMPLETA DE MENSAGERIA para determinar se um evento pode ser disparado.
  /// 
  /// Hierarquia estrita:
  /// 1. [Global / Empresa]: Mensageria habilitada nas configurações da empresa (usarWhatsApp)?
  /// 2. [Política por Evento]:
  ///    - [desativado / OFF]: BLOQUEIO TOTAL. Nenhum disparo automático ou sugestão padrão.
  ///    - [manual]: Exige intenção/confirmação explícita do operador.
  ///    - [automatico]: Autorizado para disparo automático em segundo plano.
  /// 3. [Conectividade]: Instância da Evolution API conectada e operacional.
  static Future<({bool podeDispararAutomatico, bool eventoDesativado, WhatsAppEventPolicy politica, bool isApiConectada})> avaliarHierarquiaEvento({
    required String eventoId,
    String? tenantId,
    bool? empresaUsarWhatsApp,
  }) async {
    // 1. Validação Global da Empresa
    bool empresaAtiva = empresaUsarWhatsApp ?? true;
    try {
      final repo = DependencyInjection().tryGet<EmpresaConfiguracaoRepository>();
      if (repo != null) {
        final configs = await repo.findAll();
        if (configs.isNotEmpty) {
          empresaAtiva = configs.first.usarWhatsApp;
        }
      }
    } catch (_) {}

    if (!empresaAtiva) {
      return (
        podeDispararAutomatico: false,
        eventoDesativado: true,
        politica: WhatsAppEventPolicy.desativado,
        isApiConectada: false,
      );
    }

    // 2. Política do Evento
    final politicas = await getPoliticasEventos(tenantId: tenantId);
    final politica = politicas[eventoId] ?? WhatsAppEventPolicy.desativado;

    if (politica == WhatsAppEventPolicy.desativado) {
      return (
        podeDispararAutomatico: false,
        eventoDesativado: true,
        politica: WhatsAppEventPolicy.desativado,
        isApiConectada: false,
      );
    }

    // 3. Conexão com a Evolution API
    final isApiConectada = await EvolutionApiClient.isInstanciaConectada(tenantId: tenantId);

    return (
      podeDispararAutomatico: isApiConectada && politica == WhatsAppEventPolicy.automatico,
      eventoDesativado: false,
      politica: politica,
      isApiConectada: isApiConectada,
    );
  }

  static void _adicionarDecisao(WhatsAppSimulatedDecision dec) {
    _simulatedHistory.insert(0, dec);
    simulacoesRevision.value++;
  }

  /// Avalia a decisão de mensageria em MODO SIMULAÇÃO / MOCK.
  ///
  /// IMPORTANTE: Este método executa 100% em memória/local e NUNCA faz chamadas HTTP
  /// reais nem envia mensagens a clientes. Ele audita toda a hierarquia de regras,
  /// consentimento, modalidade e idempotência, retornando um [WhatsAppSimulatedDecision].
  static Future<WhatsAppSimulatedDecision> avaliarDecisaoSimulada({
    required String tenantId,
    required String pedidoId,
    required String numeroPedido,
    required String eventoId,
    required String tipoLogistica, // 'Entrega', 'Retirada', 'Balcão', 'Local'
    required bool empresaUsarWhatsApp,
    required bool clienteAceitaWhatsapp,
    required String? rawPhone,
    required String clienteNome,
    Map<String, String>? variaveisTemplate,
    String? templateCustomizado,
  }) async {
    final now = DateTime.now();
    final sanitizado = rawPhone != null ? sanitizarTelefone(rawPhone) : '';
    final formattedPhone = sanitizado.isNotEmpty
        ? formatarExibicao(rawPhone: sanitizado, comNonoDigito: true)
        : 'Não informado';

    final idempotencyKey = '$tenantId:$pedidoId:$eventoId';

    // 1. Verificação da trava global da empresa (Kill Switch)
    if (!empresaUsarWhatsApp) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: WhatsAppEventPolicy.desativado,
        codigoDecisao: 'BLOCKED_GLOBAL_DISABLED',
        motivo: 'Mensageria global desabilitada nas configurações da empresa.',
        telefoneFormatado: formattedPhone,
        timestamp: now,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    // 2. Leitura da política local configurada para o evento
    final politicas = await getPoliticasEventos(tenantId: tenantId);
    final politica = politicas[eventoId] ?? WhatsAppEventPolicy.desativado;

    if (politica == WhatsAppEventPolicy.desativado) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: WhatsAppEventPolicy.desativado,
        codigoDecisao: 'BLOCKED_EVENT_DISABLED',
        motivo: 'A política para o evento "$eventoId" está configurada como Desativada.',
        telefoneFormatado: formattedPhone,
        timestamp: now,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    // 3. Verificação de Consentimento do Cliente (LGPD / Preferência)
    if (!clienteAceitaWhatsapp) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: politica,
        codigoDecisao: 'BLOCKED_NO_CONSENT',
        motivo: 'O cliente "$clienteNome" está com aceitação de WhatsApp desmarcada.',
        telefoneFormatado: formattedPhone,
        timestamp: now,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    // 4. Verificação de Telefone Válido
    if (sanitizado.length < 10) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: politica,
        codigoDecisao: 'BLOCKED_INVALID_PHONE',
        motivo: 'Telefone do cliente ausente ou inválido ($sanitizado).',
        telefoneFormatado: formattedPhone,
        timestamp: now,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    // 5. Verificação de Compatibilidade Logística (Modalidade do Pedido)
    final isEntrega = tipoLogistica.trim().toLowerCase().contains('entrega');

    if (eventoId == kEventoPedidoSaiuEntrega && !isEntrega) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: politica,
        codigoDecisao: 'BLOCKED_INVALID_LOGISTICS',
        motivo: 'Notificação "Saiu para Entrega" bloqueada: pedido é da modalidade "$tipoLogistica".',
        telefoneFormatado: formattedPhone,
        timestamp: now,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    if (eventoId == kEventoPedidoPronto && isEntrega) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: politica,
        codigoDecisao: 'BLOCKED_INVALID_LOGISTICS',
        motivo: 'Notificação "Pedido Pronto no Balcão" bloqueada: pedido é de Entrega (aguarda despacho de motoboy).',
        telefoneFormatado: formattedPhone,
        timestamp: now,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    // 6. Verificação de Idempotência Persistente (Prevenção de duplicidade por re-render, clique duplo ou reinício)
    final jaProcessadoNoBanco = await _logRepo.existeIdempotencia(idempotencyKey);
    if (_simulatedIdempotencyKeys.contains(idempotencyKey) || jaProcessadoNoBanco) {
      final dec = WhatsAppSimulatedDecision(
        eventoId: eventoId,
        pedidoId: pedidoId,
        numeroPedido: numeroPedido,
        autorizado: false,
        politica: politica,
        codigoDecisao: 'BLOCKED_DUPLICATE',
        motivo: 'Evento já processado anteriormente para este pedido nesta sessão/banco (chave: $idempotencyKey).',
        telefoneFormatado: formattedPhone,
        timestamp: now,
        isDuplicado: true,
      );
      _adicionarDecisao(dec);
      return dec;
    }

    // 7. Autorizado para Simulação (Manual ou Automático)
    _simulatedIdempotencyKeys.add(idempotencyKey);

    // Gera preview do texto utilizando template padrão ou customizado
    String preview = templateCustomizado ?? '';
    if (preview.isEmpty) {
      final templates = getTemplatesPadrao();
      if (eventoId == kEventoPedidoSaiuEntrega) {
        preview = gerarTextoSaiuParaEntrega(nomeCliente: clienteNome, numeroPedidoOuId: numeroPedido);
      } else if (eventoId == kEventoPedidoPronto) {
        final t = templates.firstWhere((item) => item.id == 'pedido_pronto', orElse: () => templates.first);
        preview = t.conteudo;
      } else if (eventoId == kEventoPedidoEntregue) {
        final t = templates.firstWhere((item) => item.id == 'avaliacao_pos_venda', orElse: () => templates.first);
        preview = t.conteudo;
      } else {
        final t = templates.firstWhere((item) => item.id == 'contato_pedido', orElse: () => templates.first);
        preview = t.conteudo;
      }
    }

    if (variaveisTemplate != null && variaveisTemplate.isNotEmpty) {
      preview = interpolarTemplate(preview, variaveisTemplate);
    }

    final isManual = politica == WhatsAppEventPolicy.manual;
    final dec = WhatsAppSimulatedDecision(
      eventoId: eventoId,
      pedidoId: pedidoId,
      numeroPedido: numeroPedido,
      autorizado: true,
      politica: politica,
      codigoDecisao: isManual ? 'AUTHORIZED_MANUAL' : 'AUTHORIZED_AUTO_SIMULATED',
      motivo: isManual
          ? 'Autorizado para envio manual com confirmação do operador (Human-in-the-Loop).'
          : 'Autorizado para envio automático simulado (Simulação - sem chamada HTTP externa).' ,
      telefoneFormatado: formattedPhone,
      previewTexto: preview,
      timestamp: now,
    );

    _adicionarDecisao(dec);
    debugPrint('[WhatsApp SIMULAÇÃO] Decisão: ${dec.codigoDecisao} | Pedido: #$numeroPedido | Evento: $eventoId | Destino: $formattedPhone');

    // Human-in-the-Loop: notifica ouvintes ativos na interface para confirmação do operador
    if (dec.requerConfirmacaoManual && sanitizado.isNotEmpty) {
      manualPromptNotifier.value = WhatsAppManualPrompt(
        decisao: dec,
        rawPhone: sanitizado,
        tenantId: tenantId,
      );
    }

    return dec;
  }

  /// Envia mensagem real via Evolution API (Fase D1/D2: Canal Técnico e Idempotência Segregada)
  ///
  /// Conecta o FINCORE à Evolution API de forma desacoplada e segura.
  ///
  /// ## Diretriz Fundamental de Idempotência:
  /// - [isManualIntent]: Quando `true` (ação explícita do operador na interface),
  ///   representa uma NOVA INTENÇÃO DE ENVIO. Nunca é bloqueada por histórico ou
  ///   mensagens anteriores do pedido, permitindo reenvios intencionais mesmo com o mesmo texto.
  /// - [idempotencyKey]: Quando fornecida para eventos automáticos, protege exclusivamente
  ///   contra repetição do MESMO evento automático (ex: retry, loop ou redelivery de E123).
  /// - Novos eventos no mesmo pedido (ex: pedido alterado E456 ou nova versão) geram chaves
  ///   distintas e são processados normalmente.
  /// - [isTechnicalRetry]: Quando `true`, preserva a chave da tentativa original para
  ///   evitar duplicidade silenciosa em caso de timeout de rede com a Evolution API.
  static Future<WhatsAppSendResult> enviarMensagem({
    required String rawPhone,
    required String mensagem,
    EvolutionApiConfig? config,
    String? tenantId,
    String? pedidoId,
    String? eventoId,
    String? idempotencyKey,
    bool isManualIntent = false,
    bool isTechnicalRetry = false,
  }) async {
    final String resolvedKey;

    if (isManualIntent) {
      // Envio manual intencional do operador:
      // Cada clique no botão é uma nova intenção humana de envio.
      // NÃO consulta trava de histórico/idempotência automática.
      // Gera uma chave de auditoria única para registro forense no banco local.
      resolvedKey = idempotencyKey ??
          'manual:${tenantId ?? "default"}:${pedidoId ?? "avulso"}:${const Uuid().v4()}';
    } else {
      // Processamento automático de evento:
      // A proteção existe para impedir que o MESMO evento/processamento seja reprocessado.
      resolvedKey = idempotencyKey ??
          (tenantId != null && pedidoId != null && eventoId != null
              ? '$tenantId:$pedidoId:$eventoId'
              : 'auto:${tenantId ?? "default"}:${pedidoId ?? "avulso"}:${const Uuid().v4()}');

      // Validação de Idempotência Persistida no SQLite para eventos automáticos
      if (await _logRepo.existeIdempotencia(resolvedKey)) {
        return WhatsAppSendResult(
          status: WhatsAppSendStatus.erroApi,
          sucesso: false,
          erro: 'Disparo bloqueado por idempotência (BLOCKED_DUPLICATE: O evento automático ($resolvedKey) já foi processado com sucesso anteriormente.)',
          telefoneMascarado: EvolutionApiClient.mascararTelefone(rawPhone),
          idempotencyKey: resolvedKey,
          timestamp: DateTime.now(),
        );
      }
    }

    final cfg = config ?? await EvolutionApiClient.carregarConfig(tenantId: tenantId);
    final resultado = await EvolutionApiClient.enviarMensagemTexto(
      config: cfg,
      numeroDestino: rawPhone,
      textoMensagem: mensagem,
      tenantId: tenantId,
      pedidoId: pedidoId,
      eventoId: eventoId,
      idempotencyKey: resolvedKey,
    );

    // Grava registro de auditoria forense persistente no banco de dados local
    if (resultado.sucesso) {
      final record = WhatsAppMessageLogRecord(
        id: const Uuid().v4(),
        tenantId: tenantId ?? 'default',
        pedidoId: pedidoId ?? '',
        eventoId: eventoId ?? (isManualIntent ? 'manual' : 'direto'),
        idempotencyKey: resolvedKey,
        destinatarioMascarado: resultado.telefoneMascarado ?? EvolutionApiClient.mascararTelefone(rawPhone),
        instancia: resultado.instancia ?? cfg.instanceName,
        mensagemPreview: mensagem.length > 120 ? '${mensagem.substring(0, 120)}...' : mensagem,
        status: resultado.status.name,
        messageId: resultado.messageId,
        httpStatusCode: resultado.httpStatusCode,
        erro: resultado.erro,
        criadoEm: resultado.timestamp,
      );
      await _logRepo.registrarLog(record);
    }

    return resultado;
  }

  /// Obtém a chave PIX oficial configurada na empresa/tenant (sem duplicidade de fontes)
  static Future<String> obterChavePixOficial({String? tenantId}) async {
    try {
      final repo = DependencyInjection().tryGet<EmpresaConfiguracaoRepository>();
      if (repo != null) {
        final configs = await repo.findAll();
        if (configs.isNotEmpty) {
          final tId = tenantId ?? (TenantContext().hasContext ? TenantContext().tenantId : '');
          final cfg = configs.firstWhere(
            (c) => c.tenantId == tId,
            orElse: () => configs.first,
          );
          final rawPix = cfg.pixKey ?? '';
          if (rawPix.isNotEmpty) {
            try {
              final decoded = jsonDecode(rawPix);
              if (decoded is List && decoded.isNotEmpty) {
                final first = decoded.first as Map<String, dynamic>;
                final chave = first['chave']?.toString();
                if (chave != null && chave.isNotEmpty) return chave;
              }
            } catch (_) {
              return rawPix;
            }
          }
        }
      }
    } catch (_) {}
    return 'Chave PIX cadastrada na loja';
  }

  /// Processa eventos de negócio de forma segura e não bloqueante (Fase D2).
  ///
  /// Respeita estritamente:
  /// 1. Se a política estiver [WhatsAppEventPolicy.desativado] ou [WhatsAppEventPolicy.manual], NUNCA envia automaticamente.
  /// 2. Se [WhatsAppEventPolicy.automatico], avalia regras de negócio e idempotência do evento específico.
  /// 3. Se o mesmo evento [eventInstanceId] for reprocessado, é bloqueado como duplicata.
  /// 4. Se o pedido for alterado (nova versão/evento [eventInstanceId]), o envio é permitido.
  /// 5. Condição especial PIX: se formaPagamento == 'PIX' e statusPagamento == 'PENDENTE',
  ///    dispara a confirmação e mensagem de PIX com chaves vinculadas à instância do evento.
  static Future<void> processarEventoPedidoAutomatico({
    required String tenantId,
    required String pedidoId,
    required String numeroPedido,
    required String eventoId, // 'pedido_criado', 'pedido_pronto', 'saiu_entrega', etc.
    required String tipoLogistica,
    required String formaPagamento, // 'PIX', 'Dinheiro', 'Cartao', etc.
    required String statusPagamento, // 'PENDENTE', 'PAGO'
    required String? rawPhone,
    required String clienteNome,
    required bool clienteAceitaWhatsapp,
    String? canalOrigem,
    String? eventInstanceId, // Identificador estável da instância do evento (ex: 'E123', ID do Outbox, ID do Histórico)
    int? versaoPedido,       // Versão/Revision do pedido no banco de dados local
    DateTime? dataAlteracao, // Data/hora da última alteração do pedido
    String? chavePix,
    String? chavePixCopiaCola,
    String? enderecoCliente,
    int? valorTotalCentavos,
    int? valorSubtotalCentavos,
    int? valorDescontoCentavos,
    int? valorTaxaEntregaCentavos,
    int? valorTaxaServicoCentavos,
    int? trocoParaCentavos,
    List<Map<String, dynamic>>? itens,
    String? observacoes,
    String? previsaoEntrega,
    String? entregador,
    String? mesa,
    String? linkCardapio,
    String? linkRastreio,
    String? nomeEmpresa,
    bool isTechnicalRetry = false,
  }) async {
    try {
      // 1. Checa a HIERARQUIA COMPLETA DE MENSAGERIA para o evento
      final hierarquia = await avaliarHierarquiaEvento(
        eventoId: eventoId,
        tenantId: tenantId,
      );

      // Se o evento estiver DESATIVADO (OFF), bloqueio total e absoluto!
      if (hierarquia.eventoDesativado || hierarquia.politica == WhatsAppEventPolicy.desativado) {
        debugPrint('[WhatsAppService] Evento "$eventoId" está DESATIVADO (OFF) nas configurações de política. Disparo automático cancelado.');
        return;
      }

      // Se a política for MANUAL, automação em background não pode disparar silenciosa
      if (hierarquia.politica == WhatsAppEventPolicy.manual) {
        debugPrint('[WhatsAppService] Evento "$eventoId" configurado como MANUAL. Disparo automático em background ignorado.');
        return;
      }

      // Se a política for AUTOMÁTICA, exige conexão ativa com a Evolution API
      if (!hierarquia.podeDispararAutomatico || !hierarquia.isApiConectada) {
        debugPrint('[WhatsAppService] Evento "$eventoId" automático, porém Evolution API desconectada. Disparo cancelado.');
        return;
      }

      // 2. Validações preliminares
      if (!clienteAceitaWhatsapp) return;
      if (rawPhone == null || sanitizarTelefone(rawPhone).length < 10) return;

      final empNome = nomeEmpresa ?? (TenantContext().hasContext ? TenantContext().empresa.nomeFantasia : 'Nossa Loja');
      final pixKeyResolvida = (chavePix != null && chavePix.isNotEmpty)
          ? chavePix
          : await obterChavePixOficial(tenantId: tenantId);

      final vars = gerarVariaveisInterpolacao(
        clienteNome: clienteNome,
        nomeEmpresa: empNome,
        numeroPedido: numeroPedido,
        pedidoId: pedidoId,
        tenantId: tenantId,
        canalOrigem: canalOrigem,
        itens: itens,
        subtotal: valorSubtotalCentavos != null
            ? valorSubtotalCentavos / 100.0
            : (valorTotalCentavos != null ? valorTotalCentavos / 100.0 : 0.0),
        desconto: valorDescontoCentavos != null ? valorDescontoCentavos / 100.0 : 0.0,
        taxaEntrega: valorTaxaEntregaCentavos != null ? valorTaxaEntregaCentavos / 100.0 : 0.0,
        taxaServico: valorTaxaServicoCentavos != null ? valorTaxaServicoCentavos / 100.0 : 0.0,
        total: valorTotalCentavos != null ? valorTotalCentavos / 100.0 : 0.0,
        formaPagamento: formaPagamento,
        trocoPara: trocoParaCentavos != null && trocoParaCentavos > 0
            ? 'R\$ ${(trocoParaCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',')}'
            : null,
        tipoPedido: tipoLogistica,
        endereco: formatarEnderecoCliente(enderecoCliente),
        observacoes: observacoes,
        previsaoEntrega: previsaoEntrega,
        entregador: entregador,
        mesa: mesa,
        linkCardapio: linkCardapio,
        linkRastreio: linkRastreio,
        chavePix: pixKeyResolvida,
        chavePixCopiaCola: chavePixCopiaCola,
      );

      final templates = await getTemplates(tenantId: tenantId, nomeEmpresa: empNome);
      final mappingEventos = await getTemplatesEventosConfigurados(tenantId: tenantId);
      final templateIdVinculado = mappingEventos[eventoId] ??
          (eventoId == kEventoPedidoAprovadoWeb ? (mappingEventos['pedido_aprovado'] ?? mappingEventos['pedido_aprovado_web']) : null) ??
          (eventoId == kEventoPedidoCriadoPdv ? mappingEventos['pedido_criado'] : null) ??
          (eventoId == kEventoPedidoEntregue ? mappingEventos['pedido_entregue'] : null);

      // 3. Localiza template aplicável ao evento:
      WhatsAppTemplate? templateConfirmacao;

      // A. Se houver um template explicitamente vinculado a este evento pelo operador:
      if (templateIdVinculado != null) {
        templateConfirmacao = templates.where((t) => t.ativo && t.id == templateIdVinculado).firstOrNull;
      }

      // B. Busca template ativo com o evento correspondente:
      templateConfirmacao ??= templates
          .where((t) =>
              t.ativo &&
              (t.evento == eventoId ||
                  (eventoId == kEventoPedidoCriadoPdv && (t.evento == 'pedido_criado' || t.id == 'comprovante')) ||
                  (eventoId == kEventoPedidoAprovadoWeb && (t.evento == 'pedido_aprovado' || t.evento == 'pedido_aprovado_web' || t.id == 'pedido_aprovado')) ||
                  (eventoId == kEventoPedidoEntregue && (t.evento == 'pedido_entregue' || t.id == 'avaliacao_pos_venda'))))
          .firstOrNull;

      // C. Se for pedido cancelado e ainda não achou, busca o template de cancelamento
      if (templateConfirmacao == null && eventoId == kEventoPedidoCancelado) {
        templateConfirmacao = templates.where((t) => t.id == 'pedido_cancelado').firstOrNull;
      }

      // D. Se for pedido entregue e ainda não achou, busca o template de avaliação pós-venda
      if (templateConfirmacao == null && eventoId == kEventoPedidoEntregue) {
        templateConfirmacao = templates.where((t) => t.id == 'avaliacao_pos_venda').firstOrNull;
      }

      // D. Fallback seguro: se NÃO for cancelamento, busca contato_pedido ou o primeiro
      templateConfirmacao ??= (eventoId == kEventoPedidoCancelado)
          ? null
          : templates.firstWhere(
              (t) => t.id == 'contato_pedido',
              orElse: () => templates.first,
            );

      if (templateConfirmacao == null) {
        debugPrint('[WhatsAppService] Nenhum template ativo configurado para o evento $eventoId. Disparo cancelado com segurança.');
        return;
      }

      // Identificador único da instância do evento para proteger contra repetição do MESMO evento,
      // mas permitir novos envios se o pedido for alterado (nova versão / novo evento legítimo).
      final eventRef = eventInstanceId ??
          (versaoPedido != null
              ? 'v$versaoPedido'
              : (dataAlteracao != null
                  ? 'ts_${dataAlteracao.millisecondsSinceEpoch}'
                  : 'evt_${DateTime.now().millisecondsSinceEpoch}'));

      final keyConfirmacao = '$tenantId:$pedidoId:$eventoId:$eventRef:confirmacao';
      final textoConfirmacao = interpolarTemplate(templateConfirmacao.conteudo, vars);

      await enviarMensagem(
        rawPhone: rawPhone,
        mensagem: textoConfirmacao,
        tenantId: tenantId,
        pedidoId: pedidoId,
        eventoId: eventoId,
        idempotencyKey: keyConfirmacao,
        isManualIntent: false,
        isTechnicalRetry: isTechnicalRetry,
      );

      // 4. CONDIÇÃO ESPECIAL PIX (Regra 5 e 6 da Fase D2)
      // SE forma de pagamento == PIX E pagamento == PENDENTE
      final isPix = formaPagamento.trim().toUpperCase() == 'PIX';
      final isPendente = statusPagamento.trim().toUpperCase() != 'PAGO';

      if (isPix && isPendente) {
        final templatePix = templates.firstWhere(
          (t) => t.id == 'cobranca_pix' || t.condicaoFormaPagamento == 'PIX',
          orElse: () => getTemplatesPadrao(nomeEmpresa: empNome).firstWhere((t) => t.id == 'cobranca_pix'),
        );

        final keyPix = '$tenantId:$pedidoId:$eventoId:$eventRef:pix';
        final textoPix = interpolarTemplate(templatePix.conteudo, vars);

        await enviarMensagem(
          rawPhone: rawPhone,
          mensagem: textoPix,
          tenantId: tenantId,
          pedidoId: pedidoId,
          eventoId: eventoId,
          idempotencyKey: keyPix,
          isManualIntent: false,
          isTechnicalRetry: isTechnicalRetry,
        );
      }
    } catch (e) {
      debugPrint('[WhatsAppService] Falha isolada no envio automático (fluxo não-bloqueante): $e');
    }
  }
}

/// Políticas de disparo por evento no FINCORE (Fase C)
enum WhatsAppEventPolicy {
  desativado, // Nenhuma mensagem é processada para o evento
  manual,     // Operador pode confirmar ou dispensar o envio (não-bloqueante)
  automatico, // Processamento automático simulado (sem chamadas externas)
}

/// Representa o resultado auditável da avaliação de uma regra de mensageria
class WhatsAppSimulatedDecision {
  final String eventoId;
  final String pedidoId;
  final String numeroPedido;
  final bool autorizado;
  final WhatsAppEventPolicy politica;
  final String codigoDecisao;
  final String motivo;
  final String telefoneFormatado;
  final String? previewTexto;
  final DateTime timestamp;
  final bool isDuplicado;
  final bool isSimulacao;

  const WhatsAppSimulatedDecision({
    required this.eventoId,
    required this.pedidoId,
    required this.numeroPedido,
    required this.autorizado,
    required this.politica,
    required this.codigoDecisao,
    required this.motivo,
    required this.telefoneFormatado,
    this.previewTexto,
    required this.timestamp,
    this.isDuplicado = false,
    this.isSimulacao = true,
  });

  bool get requerConfirmacaoManual => autorizado && politica == WhatsAppEventPolicy.manual;
}

/// Representa uma solicitação pendente de confirmação manual do operador (Human-in-the-Loop — Fase D2)
class WhatsAppManualPrompt {
  final WhatsAppSimulatedDecision decisao;
  final String rawPhone;
  final String? tenantId;

  const WhatsAppManualPrompt({
    required this.decisao,
    required this.rawPhone,
    this.tenantId,
  });
}


