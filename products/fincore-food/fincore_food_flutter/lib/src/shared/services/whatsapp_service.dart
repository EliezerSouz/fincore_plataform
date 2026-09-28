import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
}
