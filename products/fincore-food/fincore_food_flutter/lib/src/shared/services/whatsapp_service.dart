import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de Template de Mensagem Rápida do WhatsApp
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

  const WhatsAppTemplate({
    required this.id,
    required this.titulo,
    required this.emoji,
    required this.descricao,
    required this.conteudo,
    this.categoria = 'custom',
    this.ativo = true,
    this.isPadrao = false,
    this.variaveisSugeridas = const [
      '{cliente}',
      '{loja}',
      '{pedido}',
      '{total}',
      '{endereco}',
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
      variaveisSugeridas: (map['variaveisSugeridas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['{cliente}', '{loja}', '{pedido}', '{total}', '{endereco}', '{link_cardapio}'],
    );
  }
}

/// Modo de envio do WhatsApp
enum WhatsAppApiMode {
  manualWaMe, // wa.me / whatsapp:// (gratuito e sem servidor)
  evolutionApi, // Evolution API (Self-hosted REST API)
  genericWebhook, // Webhook Genérico HTTP POST
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
        id: 'saudacao',
        titulo: 'Saudação & Atendimento',
        emoji: '👋',
        descricao: 'Mensagem calorosa de boas-vindas e atendimento geral ao cliente.',
        categoria: 'atendimento',
        isPadrao: true,
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
        conteudo: '👋 *Olá, {cliente}!* Tudo bem? 😊\n\n'
            'Aqui é da equipe da *$emp* referente ao seu pedido *#{pedido}*. ✨\n'
            'Estamos acompanhando a sua solicitação com todo o carinho e dedicação!\n\n'
            'Se precisar de alguma informação, alteração ou suporte, basta nos responder por aqui! 💬',
      ),
      WhatsAppTemplate(
        id: 'pedido_pronto',
        titulo: 'Pedido Pronto (Retirada Balcão)',
        emoji: '🛍️',
        descricao: 'Avisa o cliente que o pedido está pronto para ser retirado na loja.',
        categoria: 'pedido',
        isPadrao: true,
        conteudo: '🛍️ *SEU PEDIDO ESTÁ PRONTO!* 🎉✨\n\n'
            '👋 Olá, *{cliente}*!\n'
            'O seu pedido *#{pedido}* já foi preparado e está prontinho esperando por você no balcão da *$emp*! 😋🔥\n\n'
            'Pode vir retirar quando quiser. Estamos te esperando com tudo fresquinho! 🚀',
      ),
      WhatsAppTemplate(
        id: 'saiu_entrega',
        titulo: 'Saiu para Entrega (Delivery)',
        emoji: '🛵',
        descricao: 'Notifica que o entregador saiu com o pedido.',
        categoria: 'entrega',
        isPadrao: true,
        conteudo: '🛵 *SEU PEDIDO SAIU PARA ENTREGA!* 🎉🚀\n\n'
            '👋 Olá, *{cliente}*!\n'
            'Boas notícias: o seu pedido *#{pedido}* acabou de sair e está a caminho com o nosso entregador! 😍✨\n\n'
            '📍 *Endereço de Entrega:* {endereco}\n\n'
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
        conteudo: '👋 *Olá, {cliente}!* Tudo bem? 😊\n\n'
            'Aqui é da equipe de atendimento da *$emp*.\n\n'
            '📄 *Informações de Pagamento — Pedido #{pedido}*\n'
            '💰 *Valor Total:* R\$ {total}\n'
            '💳 *Forma:* {forma_pagamento}\n\n'
            'Para sua maior comodidade, disponibilizamos pagamento rápido via PIX! 👇\n'
            'Basta utilizar a chave ou código copia e cola enviado.\n\n'
            'Assim que efetuar o pagamento, por gentileza nos envie o comprovante por aqui. Muito obrigado! ✨',
      ),
      WhatsAppTemplate(
        id: 'cardapio_digital',
        titulo: 'Cardápio Digital & Novidades',
        emoji: '✨',
        descricao: 'Divulga o link do cardápio digital oficial para o cliente.',
        categoria: 'marketing',
        isPadrao: true,
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
        conteudo: '📍 *Olá, {cliente}!* Tudo bem? 😊\n\n'
            'Por favor, confirme se o endereço de entrega do seu pedido *#{pedido}* está correto:\n\n'
            '🏠 *{endereco}*\n\n'
            'Podemos despachar para este endereço? Agradecemos a confirmação rápida! 🛵✨',
      ),
      WhatsAppTemplate(
        id: 'avaliacao_pos_venda',
        titulo: 'Avaliação & Pós-Venda',
        emoji: '⭐',
        descricao: 'Agradecimento pós-entrega solicitando feedback do cliente.',
        categoria: 'marketing',
        isPadrao: true,
        conteudo: '❤️ *Olá, {cliente}!* Esperamos que sua experiência tenha sido incrível! ✨\n\n'
            'Como estava o seu pedido da *$emp*? A sua opinião é muito valiosa para continuarmos melhorando cada vez mais! ⭐⭐⭐⭐⭐\n\n'
            'Se puder nos contar o que achou, ficaremos muito felizes. Até o próximo pedido! 🚀😊',
      ),
    ];
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

        if (templates.isNotEmpty) return templates;
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

  /// Substitui as tags dinâmicas `{cliente}`, `{loja}`, `{pedido}`, `{total}`, `{endereco}`, `{link_cardapio}`, etc.
  static String interpolarTemplate(
    String template,
    Map<String, String> variaveis,
  ) {
    String resultado = template;
    variaveis.forEach((tag, valor) {
      if (tag == '{pedido}') {
        final numLimpo = valor.startsWith('#') ? valor.substring(1) : valor;
        resultado = resultado.replaceAll('#{pedido}', '#$numLimpo');
        resultado = resultado.replaceAll('{pedido}', valor);
      } else {
        resultado = resultado.replaceAll(tag, valor);
      }
    });
    // Remove qualquer duplicidade acidental de ##
    resultado = resultado.replaceAll('##', '#');
    return resultado;
  }
}

