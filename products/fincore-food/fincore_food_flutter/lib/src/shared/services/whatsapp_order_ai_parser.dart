import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:fincore_core/common/master_data_models.dart';

/// Item de pedido interpretado pela Inteligência Artificial / Parser
class ItemPedidoIaParsed {
  final String id;
  final String textoOriginal;
  String nomeIdentificado;
  double quantidade;
  String? observacoes;
  Produto? produtoMatched;
  double confianca;
  int precoSugeridoCentavos;

  ItemPedidoIaParsed({
    String? id,
    required this.textoOriginal,
    required this.nomeIdentificado,
    required this.quantidade,
    this.observacoes,
    this.produtoMatched,
    this.confianca = 0.0,
    this.precoSugeridoCentavos = 0,
  }) : id = id ?? const Uuid().v4();

  ItemPedidoIaParsed copyWith({
    String? id,
    String? textoOriginal,
    String? nomeIdentificado,
    double? quantidade,
    String? observacoes,
    Produto? produtoMatched,
    double? confianca,
    int? precoSugeridoCentavos,
  }) {
    return ItemPedidoIaParsed(
      id: id ?? this.id,
      textoOriginal: textoOriginal ?? this.textoOriginal,
      nomeIdentificado: nomeIdentificado ?? this.nomeIdentificado,
      quantidade: quantidade ?? this.quantidade,
      observacoes: observacoes ?? this.observacoes,
      produtoMatched: produtoMatched ?? this.produtoMatched,
      confianca: confianca ?? this.confianca,
      precoSugeridoCentavos: precoSugeridoCentavos ?? this.precoSugeridoCentavos,
    );
  }
}

/// Resultado completo da interpretação de uma mensagem de WhatsApp
class PedidoIaParsedResult {
  String? clienteNome;
  String? clienteTelefone;
  String tipoLogistica; // 'Entrega' ou 'Retirada'
  String? logradouro;
  String? numero;
  String? bairro;
  String? complemento;
  String? referencia;
  String? cidade;
  String? formaPagamento; // 'PIX', 'Dinheiro', 'Cartão'
  int? trocoParaCentavos;
  String? observacoesGerais;
  List<ItemPedidoIaParsed> itens;
  String textoBruto;
  double confiancaGeral;
  String metodoProcessamento; // 'local_nlp' ou 'llm_cloud'
  String? erroMensagem;

  PedidoIaParsedResult({
    this.clienteNome,
    this.clienteTelefone,
    this.tipoLogistica = 'Entrega',
    this.logradouro,
    this.numero,
    this.bairro,
    this.complemento,
    this.referencia,
    this.cidade,
    this.formaPagamento,
    this.trocoParaCentavos,
    this.observacoesGerais,
    required this.itens,
    required this.textoBruto,
    this.confiancaGeral = 1.0,
    this.metodoProcessamento = 'local_nlp',
    this.erroMensagem,
  });

  bool get temItens => itens.isNotEmpty;
  int get totalItensReconhecidos => itens.where((i) => i.produtoMatched != null).length;
}

/// Configuração do motor de IA
class AiProviderConfig {
  final String provider; // 'local', 'gemini', 'openai'
  final String apiKey;
  final String model;

  const AiProviderConfig({
    this.provider = 'local',
    this.apiKey = '',
    this.model = '',
  });

  bool get isCloud => (provider == 'gemini' || provider == 'openai') && apiKey.trim().isNotEmpty;
}

/// Motor Inteligente de Captura e Interpretação de Pedidos via WhatsApp
class WhatsAppOrderAiParser {
  static const String _kPrefProvider = 'fincore_whatsapp_ai_provider';
  static const String _kPrefApiKey = 'fincore_whatsapp_ai_apikey';
  static const String _kPrefModel = 'fincore_whatsapp_ai_model';

  /// Carrega as configurações de IA salvas
  static Future<AiProviderConfig> carregarConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return AiProviderConfig(
      provider: prefs.getString(_kPrefProvider) ?? 'local',
      apiKey: prefs.getString(_kPrefApiKey) ?? '',
      model: prefs.getString(_kPrefModel) ?? '',
    );
  }

  /// Salva as configurações de IA
  static Future<void> salvarConfig(AiProviderConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefProvider, config.provider);
    await prefs.setString(_kPrefApiKey, config.apiKey);
    await prefs.setString(_kPrefModel, config.model);
  }

  /// Ponto de entrada principal para processar o texto
  Future<PedidoIaParsedResult> parseOrder(
    String rawText, {
    List<Produto>? catalogoProdutos,
    AiProviderConfig? customConfig,
  }) async {
    final cleanText = rawText.trim();
    if (cleanText.isEmpty) {
      return PedidoIaParsedResult(
        itens: [],
        textoBruto: rawText,
        erroMensagem: 'Mensagem vazia informada para processamento.',
      );
    }

    final config = customConfig ?? await carregarConfig();

    // Se configurado para IA na nuvem (Gemini / OpenAI), tenta processar via LLM
    if (config.isCloud) {
      try {
        final result = await _parseWithLlm(cleanText, config, catalogoProdutos);
        if (result != null && result.temItens) {
          return result;
        }
      } catch (e) {
        debugPrint('[WhatsAppOrderAiParser] Falha no LLM Cloud ($e). Fallback para parser local.');
      }
    }

    // Processamento nativo local (Offline NLP / Heurísticas de Delivery)
    return parseLocal(cleanText, catalogoProdutos: catalogoProdutos);
  }

  /// Motor Local Autônomo e Instantâneo (Offline)
  PedidoIaParsedResult parseLocal(String rawText, {List<Produto>? catalogoProdutos}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? clienteNome;
    String? clienteTelefone;
    String tipoLogistica = 'Entrega';
    String? logradouro;
    String? numero;
    String? bairro;
    String? complemento;
    String? referencia;
    String? formaPagamento;
    int? trocoParaCentavos;
    final List<String> obsGerais = [];
    final List<ItemPedidoIaParsed> itensIdentificados = [];

    // 1. Extração de Telefone no texto global
    final phoneRegex = RegExp(
      r'(?:(?:\+?55\s?)?(?:\(?\d{2}\)?\s?)?(?:9\s?\d{4}[-\s]?\d{4}|\d{4}[-\s]?\d{4}))',
    );
    final phoneMatch = phoneRegex.firstMatch(rawText);
    if (phoneMatch != null) {
      final rawDigits = phoneMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (rawDigits.length >= 8) {
        clienteTelefone = _formatarTelefone(rawDigits);
      }
    }

    // 2. Extração de Troco no texto global
    final trocoRegex = RegExp(
      r'(?:troco\s*(?:para|pra|de)?\s*(?:r\$)?\s*(\d+(?:[.,]\d{1,2})?))',
      caseSensitive: false,
    );
    final trocoMatch = trocoRegex.firstMatch(rawText);
    if (trocoMatch != null) {
      final trocoStr = trocoMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(trocoStr);
      if (val != null && val > 0) {
        trocoParaCentavos = (val * 100).round();
      }
    }

    // 3. Extração de Forma de Pagamento no texto global
    final lowerRaw = rawText.toLowerCase();
    if (lowerRaw.contains('pix')) {
      formaPagamento = 'PIX';
    } else if (lowerRaw.contains('dinheiro') || trocoParaCentavos != null) {
      formaPagamento = 'Dinheiro';
    } else if (lowerRaw.contains('cartão') ||
        lowerRaw.contains('cartao') ||
        lowerRaw.contains('crédito') ||
        lowerRaw.contains('credito') ||
        lowerRaw.contains('débito') ||
        lowerRaw.contains('debito')) {
      formaPagamento = 'Cartão';
    }

    // 4. Verificação de Tipo de Logística (Retirada vs Entrega)
    if (lowerRaw.contains('retirada') ||
        lowerRaw.contains('vou retirar') ||
        lowerRaw.contains('vou buscar') ||
        lowerRaw.contains('pego aí') ||
        lowerRaw.contains('passo aí pra pegar') ||
        lowerRaw.contains('balcão') ||
        lowerRaw.contains('balcao')) {
      tipoLogistica = 'Retirada';
    }

    // 5. Varredura Linha a Linha para Campos Estruturados e Itens
    for (final line in lines) {
      final cleanLine = _limparFormatacaoWhatsApp(line);
      final lowerLine = cleanLine.toLowerCase();

      // Linhas puramente de cabeçalho ou separadores
      if (lowerLine.contains('novo pedido') ||
          lowerLine == 'itens:' ||
          lowerLine == 'pedido:' ||
          lowerLine == 'itens' ||
          lowerLine == 'pedido') {
        continue;
      }

      // Cliente / Nome
      if (lowerLine.startsWith('nome:') ||
          lowerLine.startsWith('cliente:') ||
          lowerLine.startsWith('para:') ||
          lowerLine.startsWith('pra:')) {
        final val = cleanLine.split(':').sublist(1).join(':').trim();
        if (val.isNotEmpty) {
          clienteNome = val;
          continue;
        }
      } else if (lowerLine.startsWith('meu nome é') || lowerLine.startsWith('meu nome e')) {
        clienteNome = cleanLine.replaceAll(RegExp(r'^meu nome [ée]\s*', caseSensitive: false), '').trim();
        continue;
      }

      // Telefone com rótulo (com ou sem dois pontos, ex: "Whats 19999887766")
      if (lowerLine.startsWith('telefone') ||
          lowerLine.startsWith('tel') ||
          lowerLine.startsWith('fone') ||
          lowerLine.startsWith('cel') ||
          lowerLine.startsWith('whatsapp') ||
          lowerLine.startsWith('whats')) {
        final digits = cleanLine.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 8) {
          clienteTelefone = _formatarTelefone(digits);
          continue;
        }
      }

      // Endereço explícito
      if (lowerLine.startsWith('endereço:') ||
          lowerLine.startsWith('endereco:') ||
          lowerLine.startsWith('rua:') ||
          lowerLine.startsWith('local:') ||
          lowerLine.startsWith('entrega:')) {
        final val = cleanLine.split(':').sublist(1).join(':').trim();
        if (val.isNotEmpty && !val.toLowerCase().contains('retirada')) {
          _extrairEnderecoComplexo(val, (l, n, b, c, r) {
            logradouro = l;
            numero = n;
            bairro = b;
            complemento = c;
            referencia = r;
          });
          continue;
        }
      }

      // Bairro explícito
      if (lowerLine.startsWith('bairro:')) {
        bairro = cleanLine.split(':').sublist(1).join(':').trim();
        continue;
      }

      // Ponto de Referência explícito
      if (lowerLine.startsWith('ref:') ||
          lowerLine.startsWith('referência:') ||
          lowerLine.startsWith('referencia:')) {
        referencia = cleanLine.split(':').sublist(1).join(':').trim();
        continue;
      }

      // Retirada explícita
      if (lowerLine.contains('retirar') ||
          lowerLine.contains('retirada') ||
          lowerLine.contains('balcão') ||
          lowerLine.contains('balcao') ||
          lowerLine.contains('vou buscar') ||
          lowerLine.contains('pego aí')) {
        tipoLogistica = 'Retirada';
        continue;
      }

      // Pagamento explícito ou informal (ex: "Vou pagar no PIX", "Forma de Pagamento: Dinheiro")
      if (lowerLine.startsWith('pagamento') ||
          lowerLine.startsWith('forma de pagamento') ||
          lowerLine.startsWith('pgto') ||
          lowerLine.contains('vou pagar') ||
          lowerLine.contains('pago no') ||
          lowerLine.contains('pago na')) {
        if (lowerLine.contains('pix')) formaPagamento = 'PIX';
        if (lowerLine.contains('dinheiro')) formaPagamento = 'Dinheiro';
        if (lowerLine.contains('cart')) formaPagamento = 'Cartão';
        continue;
      }

      // Troco explícito
      if (lowerLine.contains('troco')) {
        continue; // Já extraído no regex global
      }

      // Observações explícitas
      if (lowerLine.startsWith('obs:') ||
          lowerLine.startsWith('observação:') ||
          lowerLine.startsWith('observacoes:')) {
        final val = cleanLine.split(':').sublist(1).join(':').trim();
        if (val.isNotEmpty) obsGerais.add(val);
        continue;
      }

      // Detecção de endereço em linha solta (ex: "Rua das Flores, 123 - Centro" ou "Rua Brasil 50")
      if (tipoLogistica == 'Entrega' &&
          (lowerLine.startsWith('rua ') ||
              lowerLine.startsWith('r. ') ||
              lowerLine.startsWith('av ') ||
              lowerLine.startsWith('av. ') ||
              lowerLine.startsWith('avenida ') ||
              lowerLine.startsWith('alameda ') ||
              lowerLine.startsWith('travessa ') ||
              lowerLine.startsWith('estrada '))) {
        _extrairEnderecoComplexo(cleanLine, (l, n, b, c, r) {
          logradouro = l;
          numero = n;
          bairro = b;
          complemento = c;
          referencia = r;
        });
        continue;
      }

      // Tentativa de Extração de Item de Pedido
      final parsedItem = _tentarExtrairItem(cleanLine, catalogoProdutos);
      if (parsedItem != null) {
        itensIdentificados.add(parsedItem);
      }
    }

    // Se ainda não encontrou clienteNome, tenta identificar frases como "meu nome é X" ou saudações
    if (clienteNome == null) {
      final saudacaoRegex = RegExp(
        r'(?:meu nome é|aqui é (?:o|a)?|sou (?:o|a)?)\s+([A-Za-zÀ-ÿ]+(?:\s+[A-Za-zÀ-ÿ]+)?)',
        caseSensitive: false,
      );
      final m = saudacaoRegex.firstMatch(rawText);
      if (m != null) {
        clienteNome = m.group(1)?.trim();
      }
    }

    return PedidoIaParsedResult(
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      tipoLogistica: tipoLogistica,
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      complemento: complemento,
      referencia: referencia,
      formaPagamento: formaPagamento,
      trocoParaCentavos: trocoParaCentavos,
      observacoesGerais: obsGerais.isNotEmpty ? obsGerais.join(' | ') : null,
      itens: itensIdentificados,
      textoBruto: rawText,
      confiancaGeral: itensIdentificados.isNotEmpty
          ? (itensIdentificados.map((i) => i.confianca).reduce((a, b) => a + b) / itensIdentificados.length)
          : 0.5,
      metodoProcessamento: 'local_nlp',
    );
  }

  /// Limpa formatação Markdown do WhatsApp (*negrito*, _itálico_, ~tachado~)
  static String _limparFormatacaoWhatsApp(String str) {
    return str
        .replaceAll(RegExp(r'^\s*[-•*]\s*'), '') // remove marcadores de lista
        .replaceAll('*', '')
        .replaceAll('_', '')
        .replaceAll('~', '')
        .trim();
  }

  /// Formata número de telefone brasileiro para padrão (XX) 9XXXX-XXXX ou XX 9XXXXXXXX
  static String _formatarTelefone(String digits) {
    if (digits.startsWith('55') && digits.length > 10) {
      digits = digits.substring(2);
    }
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return digits;
  }

  /// Extrai componentes de um endereço brasileiro informal
  static void _extrairEnderecoComplexo(
    String enderecoTexto,
    void Function(String? logradouro, String? numero, String? bairro, String? complemento, String? referencia) callback,
  ) {
    String? logradouro;
    String? numero;
    String? bairro;
    String? complemento;
    String? referencia;

    // Remove tags de prefixo
    var text = enderecoTexto
        .replaceFirst(RegExp(r'^(?:endereço|endereco|rua|entrega):\s*', caseSensitive: false), '')
        .trim();

    // Ponto de Referência
    if (text.toLowerCase().contains('ref:') || text.toLowerCase().contains('próximo') || text.toLowerCase().contains('proximo')) {
      final partesRef = text.split(RegExp(r'(?:ref:|\bpróximo\b|\bproximo\b)', caseSensitive: false));
      if (partesRef.length > 1) {
        referencia = partesRef.sublist(1).join(' ').trim();
        text = partesRef[0].trim();
      }
    }

    // Bairro
    if (text.toLowerCase().contains('bairro:')) {
      final partesBairro = text.split(RegExp(r'bairro:\s*', caseSensitive: false));
      if (partesBairro.length > 1) {
        bairro = partesBairro[1].trim();
        text = partesBairro[0].trim();
      }
    } else if (text.contains(' - ')) {
      final partesDash = text.split(' - ');
      if (partesDash.length > 1) {
        bairro = partesDash.last.trim();
        text = partesDash.sublist(0, partesDash.length - 1).join(' - ').trim();
      }
    }

    // Número
    final numRegex = RegExp(r'(?:nº|n°|num|número|numero|,|\s+)\s*(\d+[a-zA-Z]?)', caseSensitive: false);
    final numMatch = numRegex.firstMatch(text);
    if (numMatch != null) {
      numero = numMatch.group(1);
      final idx = numMatch.start;
      logradouro = text.substring(0, idx).replaceAll(RegExp(r'[, -]+$'), '').trim();
      final resto = text.substring(numMatch.end).trim();
      if (resto.isNotEmpty) {
        complemento = resto.replaceAll(RegExp(r'^[, -]+'), '').trim();
      }
    } else {
      logradouro = text;
      numero = 'S/N';
    }

    callback(logradouro, numero, bairro, complemento, referencia);
  }

  /// Tenta extrair item de pedido, quantidade e modificadores de uma linha
  static ItemPedidoIaParsed? _tentarExtrairItem(String line, List<Produto>? catalogoProdutos) {
    if (line.isEmpty) return null;

    // Ignora linhas que são claramente cabeçalhos, totais ou saudações
    final lower = line.toLowerCase().trim();
    if (lower.startsWith('oi') ||
        lower.startsWith('olá') ||
        lower.startsWith('ola') ||
        lower.startsWith('bom dia') ||
        lower.startsWith('boa tarde') ||
        lower.startsWith('boa noite') ||
        lower.startsWith('manda aí') ||
        lower.startsWith('manda ai') ||
        lower.startsWith('quero fazer um pedido') ||
        lower.startsWith('itens:') ||
        lower.startsWith('pedido:') ||
        lower.startsWith('total:') ||
        lower.startsWith('obrigado') ||
        lower.startsWith('valeu') ||
        lower.contains('novo pedido')) {
      return null;
    }

    double quantidade = 1.0;
    String nomeItem = line;
    String? observacoes;

    // 1. Extração de observações entre parênteses, colchetes ou após hífen/com/sem
    final obsParentesesRegex = RegExp(r'\((.*?)\)|\[(.*?)\]');
    final obsMatch = obsParentesesRegex.firstMatch(line);
    if (obsMatch != null) {
      observacoes = obsMatch.group(1) ?? obsMatch.group(2);
      nomeItem = line.replaceRange(obsMatch.start, obsMatch.end, '').trim();
    }

    // 2. Extração de Quantidade
    // Padrão 1: "2x", "1X", "3 x", "2un", "1 un"
    final qtyPrefixoRegex = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(?:x|un|unidades?|pct|porção|prato)?\s*[-–:]?\s*', caseSensitive: false);
    final qtyMatch = qtyPrefixoRegex.firstMatch(nomeItem);
    bool temQuantidadeIdentificada = false;

    if (qtyMatch != null) {
      final qStr = qtyMatch.group(1)!.replaceAll(',', '.');
      final q = double.tryParse(qStr);
      if (q != null && q > 0) {
        quantidade = q;
        temQuantidadeIdentificada = true;
        nomeItem = nomeItem.substring(qtyMatch.end).trim();
      }
    } else {
      // Padrão 2: Palavras no início ("um", "uma", "dois", "duas", "meia", "meio")
      if (nomeItem.toLowerCase().startsWith('uma ') || nomeItem.toLowerCase().startsWith('um ')) {
        quantidade = 1.0;
        temQuantidadeIdentificada = true;
        nomeItem = nomeItem.substring(nomeItem.indexOf(' ') + 1).trim();
      } else if (nomeItem.toLowerCase().startsWith('duas ') || nomeItem.toLowerCase().startsWith('dois ')) {
        quantidade = 2.0;
        temQuantidadeIdentificada = true;
        nomeItem = nomeItem.substring(nomeItem.indexOf(' ') + 1).trim();
      } else if (nomeItem.toLowerCase().startsWith('três ') || nomeItem.toLowerCase().startsWith('tres ')) {
        quantidade = 3.0;
        temQuantidadeIdentificada = true;
        nomeItem = nomeItem.substring(nomeItem.indexOf(' ') + 1).trim();
      } else if (nomeItem.toLowerCase().startsWith('meia ') || nomeItem.toLowerCase().startsWith('meio ')) {
        quantidade = 0.5;
        temQuantidadeIdentificada = true;
        nomeItem = nomeItem.substring(nomeItem.indexOf(' ') + 1).trim();
      }
    }

    // Limpa pontuação residual
    nomeItem = nomeItem.replaceAll(RegExp(r'^[-–:\s]+|[-–:\s]+$'), '').trim();
    if (nomeItem.length < 2) return null;

    // 3. Cruzamento com o Catálogo de Produtos (Fuzzy Matching)
    Produto? matchedProduct;
    double bestScore = 0.0;

    if (catalogoProdutos != null && catalogoProdutos.isNotEmpty) {
      for (final prod in catalogoProdutos) {
        if (!prod.ativo) continue;
        final score = calcularSimilaridade(nomeItem, prod.nome);
        if (score > bestScore) {
          bestScore = score;
          matchedProduct = prod;
        }
      }
    }

    // Descarta linhas sem quantidade identificada que não derem match satisfatório com o catálogo
    if (!temQuantidadeIdentificada && bestScore < 0.50) {
      return null;
    }

    return ItemPedidoIaParsed(
      textoOriginal: line,
      nomeIdentificado: matchedProduct?.nome ?? nomeItem,
      quantidade: quantidade,
      observacoes: observacoes?.trim(),
      produtoMatched: bestScore >= 0.50 ? matchedProduct : null,
      confianca: bestScore,
      precoSugeridoCentavos: 0,
    );
  }

  /// Algoritmo de Similaridade de Textos (Normalização + Token Overlap + Jaccard)
  static double calcularSimilaridade(String input, String target) {
    final s1 = _normalizarTextoParaComparacao(input);
    final s2 = _normalizarTextoParaComparacao(target);

    // Match exato após normalização
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Se uma string contém a outra completamente
    if (s1.contains(s2) || s2.contains(s1)) {
      final ratio = min(s1.length, s2.length) / max(s1.length, s2.length);
      return 0.80 + (ratio * 0.18);
    }

    // Comparação de tokens (Jaccard similarity de palavras)
    final tokens1 = s1.split(' ').where((t) => t.length > 1).toSet();
    final tokens2 = s2.split(' ').where((t) => t.length > 1).toSet();

    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final intersection = tokens1.intersection(tokens2);
    final union = tokens1.union(tokens2);

    final jaccard = intersection.length / union.length;

    // Distância de Levenshtein aproximada para pequenos erros de digitação
    final lev = 1.0 - (_levenshteinDistance(s1, s2) / max(s1.length, s2.length));

    return (jaccard * 0.70) + (max(0.0, lev) * 0.30);
  }

  /// Normaliza string removendo acentos, pontuações e stopwords culinárias comuns
  static String _normalizarTextoParaComparacao(String text) {
    var s = text.toLowerCase().trim();

    // Remove acentos
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
    for (var i = 0; i < comAcento.length; i++) {
      s = s.replaceAll(comAcento[i], semAcento[i]);
    }

    // Remove pontuação
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Remove stopwords para melhor correspondência
    final words = s.split(RegExp(r'\s+')).where((w) {
      return w != 'de' &&
          w != 'do' &&
          w != 'da' &&
          w != 'dos' &&
          w != 'das' &&
          w != 'e' &&
          w != 'com' &&
          w != 'sem' &&
          w != 'em' &&
          w != 'para' &&
          w != 'pra' &&
          w != 'porcao' &&
          w != 'refrigerante';
    });

    return words.join(' ').trim();
  }

  /// Cálculo da Distância de Levenshtein entre duas cadeias de caracteres
  static int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[b.length];
  }

  /// Processamento via Provedor LLM em Nuvem (Google Gemini ou OpenAI)
  Future<PedidoIaParsedResult?> _parseWithLlm(
    String rawText,
    AiProviderConfig config,
    List<Produto>? catalogoProdutos,
  ) async {
    final catalogSummary = (catalogoProdutos != null && catalogoProdutos.isNotEmpty)
        ? catalogoProdutos.where((p) => p.ativo).take(150).map((p) => '- ${p.nome} (ID: ${p.id})').join('\n')
        : 'Nenhum catálogo fornecido';

    const systemPrompt = '''
Você é um especialista em extração e estruturação de pedidos de delivery e restaurantes a partir de conversas informais e transcrições de áudio do WhatsApp.
Sua missão é extrair rigorosamente os dados do cliente, itens, entrega e pagamento, retornando APENAS um JSON válido.

Regras:
1. Responda ESTRITAMENTE em formato JSON puro, sem crases de código markdown.
2. Identifique os itens solicitados com quantidade e observações (ex: "sem cebola", "bem passado").
3. Mapeie os itens com o catálogo fornecido caso haja correspondência óbvia.
4. Extraia nome, telefone (com DDD se houver), tipo de logística ("Entrega" ou "Retirada"), endereço completo e forma de pagamento.

Estrutura JSON obrigatória:
{
  "cliente_nome": "Nome do cliente ou null",
  "cliente_telefone": "Telefone sanitizado ou null",
  "tipo_logistica": "Entrega" ou "Retirada",
  "logradouro": "Rua/Av ou null",
  "numero": "Número ou null",
  "bairro": "Bairro ou null",
  "complemento": "Apto/Casa ou null",
  "referencia": "Ponto de referência ou null",
  "forma_pagamento": "PIX", "Dinheiro" ou "Cartão",
  "troco_para": 50.0 ou null,
  "observacoes_gerais": "Observações gerais ou null",
  "itens": [
    {
      "nome": "Nome do item",
      "quantidade": 1.0,
      "observacoes": "modificadores ou null",
      "produto_id": "UUID do produto no catálogo ou null"
    }
  ]
}
''';

    final userPrompt = '''
CATÁLOGO DE PRODUTOS DISPONÍVEIS:
$catalogSummary

MENSAGEM DO WHATSAPP:
$rawText
''';

    Map<String, dynamic>? jsonResult;

    if (config.provider == 'gemini') {
      final model = config.model.isNotEmpty ? config.model : 'gemini-1.5-flash';
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${config.apiKey}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$systemPrompt\n\n$userPrompt'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.1,
          }
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final candidates = body['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content']['parts'][0]['text'] as String;
          jsonResult = jsonDecode(_limparJsonString(content));
        }
      }
    } else if (config.provider == 'openai') {
      final model = config.model.isNotEmpty ? config.model : 'gpt-4o-mini';
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['choices'][0]['message']['content'] as String;
        jsonResult = jsonDecode(_limparJsonString(content));
      }
    }

    if (jsonResult == null) return null;

    // Mapeamento do JSON da LLM para os objetos de domínio
    final List<ItemPedidoIaParsed> itens = [];
    final rawItens = jsonResult['itens'] as List? ?? [];

    for (final it in rawItens) {
      final nome = it['nome']?.toString() ?? 'Item';
      final qty = (it['quantidade'] as num?)?.toDouble() ?? 1.0;
      final obs = it['observacoes']?.toString();
      final prodId = it['produto_id']?.toString();

      Produto? matched;
      if (prodId != null && catalogoProdutos != null) {
        matched = catalogoProdutos.cast<Produto?>().firstWhere((p) => p?.id == prodId, orElse: () => null);
      }
      if (matched == null && catalogoProdutos != null) {
        // Fallback fuzzy
        double best = 0.0;
        for (final p in catalogoProdutos) {
          final s = calcularSimilaridade(nome, p.nome);
          if (s > best) {
            best = s;
            matched = p;
          }
        }
        if (best < 0.50) matched = null;
      }

      itens.add(ItemPedidoIaParsed(
        textoOriginal: nome,
        nomeIdentificado: matched?.nome ?? nome,
        quantidade: qty,
        observacoes: obs,
        produtoMatched: matched,
        confianca: matched != null ? 0.95 : 0.70,
      ));
    }

    int? trocoCentavos;
    if (jsonResult['troco_para'] != null) {
      final val = (jsonResult['troco_para'] as num).toDouble();
      if (val > 0) trocoCentavos = (val * 100).round();
    }

    return PedidoIaParsedResult(
      clienteNome: jsonResult['cliente_nome']?.toString(),
      clienteTelefone: jsonResult['cliente_telefone'] != null
          ? _formatarTelefone(jsonResult['cliente_telefone'].toString().replaceAll(RegExp(r'\D'), ''))
          : null,
      tipoLogistica: jsonResult['tipo_logistica']?.toString() ?? 'Entrega',
      logradouro: jsonResult['logradouro']?.toString(),
      numero: jsonResult['numero']?.toString(),
      bairro: jsonResult['bairro']?.toString(),
      complemento: jsonResult['complemento']?.toString(),
      referencia: jsonResult['referencia']?.toString(),
      formaPagamento: jsonResult['forma_pagamento']?.toString(),
      trocoParaCentavos: trocoCentavos,
      observacoesGerais: jsonResult['observacoes_gerais']?.toString(),
      itens: itens,
      textoBruto: rawText,
      confiancaGeral: 0.95,
      metodoProcessamento: 'llm_cloud',
    );
  }

  static String _limparJsonString(String str) {
    var clean = str.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }
}
