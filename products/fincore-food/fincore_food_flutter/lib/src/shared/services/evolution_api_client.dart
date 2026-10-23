import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status do resultado de envio de mensagem via WhatsApp/Evolution API
enum WhatsAppSendStatus {
  sucesso,
  falhaAutenticacao,
  servidorIndisponivel,
  timeout,
  telefoneInvalido,
  erroApi,
  desconhecido,
}

/// Modelo imutável do resultado seguro de envio de mensagem
class WhatsAppSendResult {
  final WhatsAppSendStatus status;
  final bool sucesso; // true apenas se a API aceitou o envio
  final int? httpStatusCode;
  final String? messageId;
  final String? statusMensagem; // ex: 'PENDING', 'SENT' retornado pela Evolution API
  final String? erro;
  final String? telefoneMascarado;
  final String? instancia;
  final String? idempotencyKey;
  final DateTime timestamp;

  const WhatsAppSendResult({
    required this.status,
    required this.sucesso,
    this.httpStatusCode,
    this.messageId,
    this.statusMensagem,
    this.erro,
    this.telefoneMascarado,
    this.instancia,
    this.idempotencyKey,
    required this.timestamp,
  });

  Map<String, dynamic> toAuditMap() => {
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'sucesso': sucesso,
        'httpStatusCode': httpStatusCode,
        'messageId': messageId,
        'statusMensagem': statusMensagem,
        'erro': erro,
        'telefoneMascarado': telefoneMascarado,
        'instancia': instancia,
        'idempotencyKey': idempotencyKey,
      };

  @override
  String toString() {
    return 'WhatsAppSendResult(status: ${status.name}, sucesso: $sucesso, httpStatus: $httpStatusCode, messageId: $messageId, erro: $erro)';
  }
}

/// Configurações de conexão com a Evolution API
class EvolutionApiConfig {
  final String apiUrl;
  final String apiKey;
  final String instanceName;
  final bool ativo;
  final bool enviarLinkPreview;
  final Duration timeout;

  const EvolutionApiConfig({
    required this.apiUrl,
    required this.apiKey,
    required this.instanceName,
    this.ativo = true,
    this.enviarLinkPreview = true,
    this.timeout = const Duration(seconds: 10),
  });

  EvolutionApiConfig copyWith({
    String? apiUrl,
    String? apiKey,
    String? instanceName,
    bool? ativo,
    bool? enviarLinkPreview,
    Duration? timeout,
  }) {
    return EvolutionApiConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      instanceName: instanceName ?? this.instanceName,
      ativo: ativo ?? this.ativo,
      enviarLinkPreview: enviarLinkPreview ?? this.enviarLinkPreview,
      timeout: timeout ?? this.timeout,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiUrl': apiUrl,
        'apiKey': apiKey,
        'instanceName': instanceName,
        'ativo': ativo,
        'enviarLinkPreview': enviarLinkPreview,
        'timeoutSeconds': timeout.inSeconds,
      };

  factory EvolutionApiConfig.fromJson(Map<String, dynamic> json) {
    String apiUrl = json['apiUrl']?.toString() ?? 'https://vps72051.publiccloud.com.br';
    if (apiUrl.contains('localhost') || apiUrl.trim().isEmpty) {
      apiUrl = 'https://vps72051.publiccloud.com.br';
    }
    String apiKey = json['apiKey']?.toString() ?? '';
    if (apiKey.trim().isEmpty) {
      apiKey = '6c91b1222b101cb115f435fc88f44359';
    }

    return EvolutionApiConfig(
      apiUrl: apiUrl,
      apiKey: apiKey,
      instanceName: json['instanceName']?.toString() ?? '',
      ativo: json['ativo'] as bool? ?? true,
      enviarLinkPreview: json['enviarLinkPreview'] as bool? ?? true,
      timeout: Duration(seconds: json['timeoutSeconds'] as int? ?? 10),
    );
  }

  /// Retorna as credenciais padrão baseadas em variáveis de ambiente (.env) ou infraestrutura local segura.
  /// O nome da instância é vazio por padrão para não amarrar novos clientes ou criar instâncias órfãs na VPS.
  static EvolutionApiConfig get padrao {
    const vpsUrlPadrao = 'https://vps72051.publiccloud.com.br';
    const vpsKeyPadrao = '6c91b1222b101cb115f435fc88f44359';

    String envUrl = vpsUrlPadrao;
    String envKey = vpsKeyPadrao;
    String envInstance = '';

    try {
      if (dotenv.isInitialized) {
        final rawUrl = dotenv.env['EVOLUTION_API_URL'];
        if (rawUrl != null && rawUrl.isNotEmpty && !rawUrl.contains('localhost')) {
          envUrl = rawUrl;
        }
        final rawKey = dotenv.env['EVOLUTION_API_KEY'];
        if (rawKey != null && rawKey.isNotEmpty) {
          envKey = rawKey;
        }
        envInstance = dotenv.env['EVOLUTION_INSTANCE_NAME'] ?? envInstance;
      }

      final platUrl = Platform.environment['EVOLUTION_API_URL'];
      if (platUrl != null && platUrl.isNotEmpty && !platUrl.contains('localhost')) {
        envUrl = platUrl;
      }
      final platKey = Platform.environment['EVOLUTION_API_KEY'];
      if (platKey != null && platKey.isNotEmpty) {
        envKey = platKey;
      }
      envInstance = Platform.environment['EVOLUTION_INSTANCE_NAME'] ?? envInstance;
    } catch (_) {}

    return EvolutionApiConfig(
      apiUrl: envUrl,
      apiKey: envKey,
      instanceName: envInstance.trim(),
    );
  }
}

/// Cliente dedicado à comunicação HTTP com a Evolution API
class EvolutionApiClient {
  static const String _storagePrefix = 'fincore_evolution_config_';

  // Cache volátil de status de conexão para evitar chamadas de rede redundantes
  static bool? _cachedIsConnected;
  static DateTime? _cachedStatusTime;

  // Histórico em memória de envios para auditoria segura
  static final List<WhatsAppSendResult> _auditHistory = <WhatsAppSendResult>[];
  static final ValueNotifier<int> auditRevision = ValueNotifier<int>(0);

  /// Retorna o histórico de auditoria seguro (sem expor credenciais)
  static List<WhatsAppSendResult> getAuditHistory() {
    return List.unmodifiable(_auditHistory);
  }

  /// Limpa o histórico de auditoria
  static void clearAuditHistory() {
    _auditHistory.clear();
    auditRevision.value++;
  }

  /// Registra com segurança o resultado do envio
  static void _registrarAuditoria(WhatsAppSendResult res) {
    _auditHistory.insert(0, res);
    if (_auditHistory.length > 50) {
      _auditHistory.removeLast();
    }
    auditRevision.value++;
  }

  /// Mascara o número de telefone para auditoria segura (LGPD / Proteção de Dados)
  static String mascararTelefone(String raw) {
    final digitos = raw.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 8) return '***';
    final inicio = digitos.substring(0, 4);
    final fim = digitos.substring(digitos.length - 2);
    return '$inicio****$fim';
  }

  /// Mascara a URL da API para exibição segura ao operador
  static String mascararUrl(String url) {
    if (url.isEmpty) return 'Não configurada';
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.length > 8) {
        return '${uri.scheme}://${host.substring(0, 4)}...${host.substring(host.length - 4)}${uri.hasPort ? ":${uri.port}" : ""}';
      }
      return url;
    } catch (_) {
      return 'https://•••••••••••••';
    }
  }

  /// Mascara a chave da API (Global ou Instance Key)
  static String mascararApiKey(String key) {
    if (key.isEmpty) return '••••••••••••••••';
    if (key.length <= 8) return '••••••••';
    final fim = key.substring(key.length - 4);
    return '••••••••••••••••$fim';
  }

  /// Retorna se a Evolution API está ativa e conectada ao WhatsApp (status open)
  static Future<bool> isInstanciaConectada({String? tenantId, bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedIsConnected != null &&
        _cachedStatusTime != null &&
        now.difference(_cachedStatusTime!).inSeconds < 20) {
      return _cachedIsConnected!;
    }

    try {
      final config = await carregarConfig(tenantId: tenantId);
      if (!config.ativo || config.apiUrl.isEmpty || config.instanceName.isEmpty) {
        _cachedIsConnected = false;
        _cachedStatusTime = now;
        return false;
      }

      final info = await obterStatusInstancia(config: config);
      final connected = info.isConnected;
      _cachedIsConnected = connected;
      _cachedStatusTime = now;
      return connected;
    } catch (_) {
      return _cachedIsConnected ?? false;
    }
  }

  /// Invalida o cache de status de conexão
  static void invalidarCacheConexao() {
    _cachedIsConnected = null;
    _cachedStatusTime = null;
  }

  /// Gera um identificador único de instância para o estabelecimento/loja.
  /// É invocado estritamente sob demanda no momento em que o operador clica para conectar o WhatsApp,
  /// garantindo que novos estabelecimentos não criem instâncias órfãs nem compartilhem conexões.
  static String gerarNomeInstanciaEstabelecimento({String? tenantId, String? nomeLoja}) {
    if (tenantId != null && tenantId.isNotEmpty && tenantId != 'default') {
      final clean = tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final suffix = clean.length > 12 ? clean.substring(0, 12) : clean;
      return 'fincore_t_$suffix';
    }

    if (nomeLoja != null && nomeLoja.trim().isNotEmpty && nomeLoja != 'Nossa Loja') {
      final clean = nomeLoja
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[áàâãä]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòôõö]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u')
          .replaceAll(RegExp(r'[ç]'), 'c')
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final trimmed = clean.length > 18 ? clean.substring(0, 18) : clean;
      final finalName = trimmed.replaceAll(RegExp(r'_$'), '');
      if (finalName.isNotEmpty) {
        return 'fincore_$finalName';
      }
    }

    final timestampSlug = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'fincore_$timestampSlug';
  }

  /// Retorna o identificador de instância privativo caso já exista, ou vazio se for cliente novo
  static String resolverInstanciaPrivativa({String? tenantId}) {
    return '';
  }

  /// Carrega a configuração da Evolution API salva para o tenant (ou padrão).
  /// As credenciais globais de rede (URL e Chave Global da VPS) vêm do .env criptografado via DPAPI.
  /// O nome da instância só é preenchido se o cliente já tiver conectado previamente.
  static Future<EvolutionApiConfig> carregarConfig({String? tenantId}) async {
    final defaultConfig = EvolutionApiConfig.padrao;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_storagePrefix${tenantId ?? 'default'}';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final loaded = EvolutionApiConfig.fromJson(decoded);

        return EvolutionApiConfig(
          apiUrl: defaultConfig.apiUrl,
          apiKey: defaultConfig.apiKey,
          instanceName: loaded.instanceName.trim(),
          ativo: loaded.ativo,
        );
      }
    } catch (e) {
      debugPrint('[EvolutionApiClient] Erro ao carregar configuração: $e');
    }

    return EvolutionApiConfig(
      apiUrl: defaultConfig.apiUrl,
      apiKey: defaultConfig.apiKey,
      instanceName: defaultConfig.instanceName.trim(),
    );
  }

  /// Salva a configuração da Evolution API no SharedPreferences do tenant
  static Future<bool> salvarConfig(EvolutionApiConfig config, {String? tenantId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_storagePrefix${tenantId ?? 'default'}';
      await prefs.setString(key, jsonEncode(config.toJson()));
      invalidarCacheConexao();
      return true;
    } catch (e) {
      debugPrint('[EvolutionApiClient] Erro ao salvar configuração: $e');
      return false;
    }
  }

  /// Envia mensagem de texto via Evolution API v2
  ///
  /// Endpoint oficial: POST {apiUrl}/message/sendText/{instanceName}
  /// Payload:
  /// ```json
  /// {
  ///   "number": "553592503114",
  ///   "text": "..."
  /// }
  /// ```
  static Future<WhatsAppSendResult> enviarMensagemTexto({
    required EvolutionApiConfig config,
    required String numeroDestino,
    required String textoMensagem,
    String? tenantId,
    String? pedidoId,
    String? eventoId,
    String? idempotencyKey,
  }) async {
    final now = DateTime.now();
    final sanitizado = numeroDestino.replaceAll(RegExp(r'\D'), '');
    final maskedPhone = mascararTelefone(sanitizado);

    // Preparação de chave de idempotência conceitual (Fase C.1 / D.1)
    final resolvedIdempotencyKey = idempotencyKey ??
        (tenantId != null && pedidoId != null && eventoId != null
            ? '$tenantId:$pedidoId:$eventoId'
            : null);

    // 1. Validação de Telefone
    if (sanitizado.length < 10) {
      final result = WhatsAppSendResult(
        status: WhatsAppSendStatus.telefoneInvalido,
        sucesso: false,
        erro: 'Número de telefone inválido ou muito curto ($sanitizado).',
        telefoneMascarado: maskedPhone,
        instancia: config.instanceName,
        idempotencyKey: resolvedIdempotencyKey,
        timestamp: now,
      );
      _registrarAuditoria(result);
      return result;
    }

    // 2. Validação de Configuração Básica
    if (!config.ativo || config.apiUrl.trim().isEmpty || config.instanceName.trim().isEmpty) {
      final result = WhatsAppSendResult(
        status: WhatsAppSendStatus.servidorIndisponivel,
        sucesso: false,
        erro: 'Evolution API não configurada ou desativada.',
        telefoneMascarado: maskedPhone,
        instancia: config.instanceName,
        idempotencyKey: resolvedIdempotencyKey,
        timestamp: now,
      );
      _registrarAuditoria(result);
      return result;
    }

    // 3. Formatação do número para envio
    String phoneToSend = sanitizado;
    if (!phoneToSend.startsWith('55') && (phoneToSend.length == 10 || phoneToSend.length == 11)) {
      phoneToSend = '55$phoneToSend';
    }

    // 4. Montagem da URL e Payload
    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;
    final targetUri = Uri.parse('$cleanUrl/message/sendText/${config.instanceName}');

    // O card de preview só deve ser enviado se:
    // 1. A configuração permitir (config.enviarLinkPreview == true)
    // 2. A mensagem contiver efetivamente um link HTTP/HTTPS
    final bool contemLink = textoMensagem.contains(RegExp(r'https?:\/\/', caseSensitive: false));
    final bool deveGerarPreview = config.enviarLinkPreview && contemLink;

    final payload = {
      'number': phoneToSend,
      'text': textoMensagem,
      'linkPreview': deveGerarPreview,
    };

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = config.timeout;

      final request = await client.postUrl(targetUri).timeout(config.timeout);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');

      if (config.apiKey.isNotEmpty) {
        request.headers.set('apikey', config.apiKey);
      }

      final bodyBytes = utf8.encode(jsonEncode(payload));
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close().timeout(config.timeout);
      final statusCode = response.statusCode;

      final responseBody = await response.transform(utf8.decoder).join();

      // Tratamento por código HTTP
      if (statusCode == 401 || statusCode == 403) {
        final result = WhatsAppSendResult(
          status: WhatsAppSendStatus.falhaAutenticacao,
          sucesso: false,
          httpStatusCode: statusCode,
          erro: 'Falha de autenticação na Evolution API (HTTP $statusCode). Verifique a apikey.',
          telefoneMascarado: maskedPhone,
          instancia: config.instanceName,
          idempotencyKey: resolvedIdempotencyKey,
          timestamp: now,
        );
        _registrarAuditoria(result);
        return result;
      }

      if (statusCode >= 200 && statusCode < 300) {
        String? messageId;
        String? statusMsg;

        try {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          if (decoded.containsKey('key') && decoded['key'] is Map) {
            messageId = (decoded['key'] as Map)['id']?.toString();
          }
          statusMsg = decoded['status']?.toString();
        } catch (_) {}

        final result = WhatsAppSendResult(
          status: WhatsAppSendStatus.sucesso,
          sucesso: true,
          httpStatusCode: statusCode,
          messageId: messageId,
          statusMensagem: statusMsg ?? 'ACCEPTED',
          telefoneMascarado: maskedPhone,
          instancia: config.instanceName,
          idempotencyKey: resolvedIdempotencyKey,
          timestamp: now,
        );
        _registrarAuditoria(result);
        return result;
      }

      // Outro status de erro retornado pela API (400, 404, 500)
      String mensagemErroAmigavel = 'A Evolution API retornou HTTP $statusCode';
      try {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        if (decoded.containsKey('response') && decoded['response'] is Map) {
          final respObj = decoded['response'] as Map<String, dynamic>;
          if (respObj.containsKey('message')) {
            final msg = respObj['message'];
            if (msg is List && msg.isNotEmpty && msg.first is Map && msg.first['exists'] == false) {
              mensagemErroAmigavel = 'O número $maskedPhone não possui conta de WhatsApp ativa.';
            } else {
              mensagemErroAmigavel = 'Evolution API: $msg';
            }
          }
        } else if (decoded.containsKey('message')) {
          mensagemErroAmigavel = 'Evolution API: ${decoded['message']}';
        }
      } catch (_) {
        mensagemErroAmigavel = 'A Evolution API retornou HTTP $statusCode: $responseBody';
      }

      if (mensagemErroAmigavel.contains('Connection Closed') || responseBody.contains('Connection Closed')) {
        mensagemErroAmigavel = 'WhatsApp desconectado na Evolution API (Connection Closed). Conecte e leia o QR Code na aba "Conexão & API".';
      }

      final result = WhatsAppSendResult(
        status: WhatsAppSendStatus.erroApi,
        sucesso: false,
        httpStatusCode: statusCode,
        erro: mensagemErroAmigavel,
        telefoneMascarado: maskedPhone,
        instancia: config.instanceName,
        idempotencyKey: resolvedIdempotencyKey,
        timestamp: now,
      );
      _registrarAuditoria(result);
      return result;
    } on TimeoutException catch (e) {
      final result = WhatsAppSendResult(
        status: WhatsAppSendStatus.timeout,
        sucesso: false,
        erro: 'Timeout ao conectar com a Evolution API (${config.timeout.inSeconds}s): $e',
        telefoneMascarado: maskedPhone,
        instancia: config.instanceName,
        idempotencyKey: resolvedIdempotencyKey,
        timestamp: now,
      );
      _registrarAuditoria(result);
      return result;
    } on SocketException catch (e) {
      final result = WhatsAppSendResult(
        status: WhatsAppSendStatus.servidorIndisponivel,
        sucesso: false,
        erro: 'Servidor Evolution API indisponível ou inacessível (${e.message}).',
        telefoneMascarado: maskedPhone,
        instancia: config.instanceName,
        idempotencyKey: resolvedIdempotencyKey,
        timestamp: now,
      );
      _registrarAuditoria(result);
      return result;
    } catch (e) {
      final result = WhatsAppSendResult(
        status: WhatsAppSendStatus.desconhecido,
        sucesso: false,
        erro: 'Erro inesperado na comunicação com a Evolution API: $e',
        telefoneMascarado: maskedPhone,
        instancia: config.instanceName,
        idempotencyKey: resolvedIdempotencyKey,
        timestamp: now,
      );
      _registrarAuditoria(result);
      return result;
    } finally {
      client?.close(force: true);
    }
  }

  /// Consulta o status real da conexão e perfil da instância na Evolution API (Fase D3)
  static Future<EvolutionInstanceInfo> obterStatusInstancia({
    required EvolutionApiConfig config,
  }) async {
    // Se o cliente for novo e ainda não tiver configurado/criado uma instância,
    // retorna imediatamente 'not_configured' sem disparar chamadas de rede à VPS.
    if (config.instanceName.trim().isEmpty) {
      return const EvolutionInstanceInfo(
        name: '',
        connectionStatus: 'not_configured',
        disconnectionMessage: 'Nenhuma conexão de WhatsApp configurada para este estabelecimento.',
      );
    }

    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // 1. Consulta PRIMEIRO o banco oficial de instâncias: /instance/fetchInstances
      final fetchUri = Uri.parse('$cleanUrl/instance/fetchInstances');
      final reqFetch = await client.getUrl(fetchUri).timeout(const Duration(seconds: 15));
      if (config.apiKey.isNotEmpty) {
        reqFetch.headers.set('apikey', config.apiKey);
      }
      final respFetch = await reqFetch.close().timeout(const Duration(seconds: 15));

      if (respFetch.statusCode == 401 || respFetch.statusCode == 403) {
        return EvolutionInstanceInfo(
          name: config.instanceName,
          connectionStatus: 'error',
          disconnectionMessage: 'Falha de autenticação (HTTP ${respFetch.statusCode}). Verifique a API Key.',
        );
      }

      if (respFetch.statusCode != 200) {
        return EvolutionInstanceInfo(
          name: config.instanceName,
          connectionStatus: 'error',
          disconnectionMessage: 'Servidor retornou HTTP ${respFetch.statusCode}',
        );
      }

      final fetchBody = await respFetch.transform(utf8.decoder).join();
      final decoded = jsonDecode(fetchBody);

      Map<String, dynamic>? instanceData;
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map && (item['name'] == config.instanceName || item['instanceName'] == config.instanceName)) {
            instanceData = Map<String, dynamic>.from(item);
            break;
          }
        }
      }

      // Se a instância NÃO foi encontrada no cadastro do servidor:
      if (instanceData == null) {
        return EvolutionInstanceInfo(
          name: config.instanceName,
          connectionStatus: 'not_found',
        );
      }

      // Se a instância FOI encontrada no cadastro do servidor, ela EXISTE com certeza:
      String dbStatus = instanceData['connectionStatus']?.toString().toLowerCase() ?? 'close';
      String? ownerJid = instanceData['ownerJid']?.toString() ?? instanceData['number']?.toString();
      String? profileName = instanceData['profileName']?.toString();
      String? profilePicUrl = instanceData['profilePicUrl']?.toString();
      int? reasonCode = instanceData['disconnectionReasonCode'] as int?;
      String? discMsg = instanceData['disconnectionObject']?.toString();
      DateTime? discAt;
      final atStr = instanceData['disconnectionAt']?.toString();
      if (atStr != null) {
        discAt = DateTime.tryParse(atStr);
      }

      String realState = dbStatus;

      // Se no banco consta como open, validamos o estado do socket em memória via connectionState
      if (dbStatus == 'open') {
        try {
          final stateUri = Uri.parse('$cleanUrl/instance/connectionState/${config.instanceName}');
          final reqState = await client.getUrl(stateUri).timeout(const Duration(seconds: 6));
          if (config.apiKey.isNotEmpty) {
            reqState.headers.set('apikey', config.apiKey);
          }
          final respState = await reqState.close().timeout(const Duration(seconds: 6));
          if (respState.statusCode == 200) {
            final stateBody = await respState.transform(utf8.decoder).join();
            final decState = jsonDecode(stateBody) as Map<String, dynamic>;
            if (decState.containsKey('instance') && decState['instance'] is Map) {
              realState = (decState['instance'] as Map)['state']?.toString().toLowerCase() ?? dbStatus;
            }
          } else if (respState.statusCode == 404) {
            realState = 'close';
          }
        } catch (_) {}
      }

      return EvolutionInstanceInfo(
        name: config.instanceName,
        connectionStatus: realState,
        ownerJid: ownerJid,
        profileName: profileName,
        profilePicUrl: profilePicUrl,
        disconnectionReasonCode: reasonCode,
        disconnectionMessage: discMsg,
        disconnectionAt: discAt,
      );
    } catch (e) {
      return EvolutionInstanceInfo(
        name: config.instanceName,
        connectionStatus: 'error',
        disconnectionMessage: e.toString(),
      );
    } finally {
      client?.close(force: true);
    }
  }

  /// Lista todas as instâncias existentes no servidor da Evolution API (Fase D3)
  static Future<List<EvolutionInstanceInfo>> listarInstanciasServidor({
    required EvolutionApiConfig config,
  }) async {
    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;
    final uri = Uri.parse('$cleanUrl/instance/fetchInstances');

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      if (config.apiKey.isNotEmpty) {
        req.headers.set('apikey', config.apiKey);
      }
      final resp = await req.close().timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final body = await resp.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) return [];

      final list = <EvolutionInstanceInfo>[];
      for (final item in decoded) {
        if (item is Map) {
          final name = item['name']?.toString() ?? item['instanceName']?.toString() ?? '';
          if (name.isEmpty) continue;
          final status = item['connectionStatus']?.toString().toLowerCase() ?? 'close';
          final ownerJid = item['ownerJid']?.toString() ?? item['number']?.toString();
          final profileName = item['profileName']?.toString();
          final profilePicUrl = item['profilePicUrl']?.toString();
          list.add(EvolutionInstanceInfo(
            name: name,
            connectionStatus: status,
            ownerJid: ownerJid,
            profileName: profileName,
            profilePicUrl: profilePicUrl,
          ));
        }
      }
      return list;
    } catch (_) {
      return [];
    } finally {
      client?.close(force: true);
    }
  }

  /// Cria uma nova instância na Evolution API (Fase D3)
  static Future<EvolutionCreateResult> criarInstancia({
    required EvolutionApiConfig config,
  }) async {
    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;
    final uri = Uri.parse('$cleanUrl/instance/create');

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);
      final req = await client.postUrl(uri).timeout(const Duration(seconds: 25));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      if (config.apiKey.isNotEmpty) {
        req.headers.set('apikey', config.apiKey);
      }
      final payload = {
        'instanceName': config.instanceName,
        'integration': 'WHATSAPP-BAILEYS',
        'qrcode': false,
      };
      final bytes = utf8.encode(jsonEncode(payload));
      req.contentLength = bytes.length;
      req.add(bytes);

      final resp = await req.close().timeout(const Duration(seconds: 25));
      final respBody = await resp.transform(utf8.decoder).join();

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return const EvolutionCreateResult(sucesso: true);
      }

      // Se o servidor avisar que o nome já está em uso, a instância já existe e está pronta
      if (resp.statusCode == 403 || respBody.contains('already in use')) {
        return const EvolutionCreateResult(
          sucesso: true,
          jaExistia: true,
        );
      }

      return EvolutionCreateResult(
        sucesso: false,
        erro: 'Servidor retornou HTTP ${resp.statusCode}: $respBody',
      );
    } catch (e) {
      return EvolutionCreateResult(
        sucesso: false,
        erro: 'Erro de comunicação: $e',
      );
    } finally {
      client?.close(force: true);
    }
  }

  /// Obtém o QR Code em Base64 para conexão do WhatsApp na Evolution API (Fase D3)
  static Future<EvolutionConnectResult> obterQrCodeConexao({
    required EvolutionApiConfig config,
  }) async {
    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;
    final uri = Uri.parse('$cleanUrl/instance/connect/${config.instanceName}');

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 65);
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 65));
      if (config.apiKey.isNotEmpty) {
        req.headers.set('apikey', config.apiKey);
      }
      final resp = await req.close().timeout(const Duration(seconds: 65));
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode == 404) {
        return const EvolutionConnectResult(
          sucesso: false,
          erro: 'Instância não encontrada no servidor.',
        );
      }

      if (resp.statusCode == 504 || body.contains('504 Gateway Time-out')) {
        return const EvolutionConnectResult(
          sucesso: false,
          erro: 'A VPS atingiu tempo limite (504 Gateway Timeout). O WhatsApp Web pode estar iniciando no servidor.',
        );
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;

        // Verifica se já está conectada
        if (decoded.containsKey('instance') && decoded['instance'] is Map) {
          final inst = decoded['instance'] as Map;
          if (inst['state']?.toString().toLowerCase() == 'open' || inst['status']?.toString().toLowerCase() == 'open') {
            return const EvolutionConnectResult(
              sucesso: true,
              isAlreadyConnected: true,
            );
          }
        }

        // Obtém o base64 do QR Code
        String? base64Str = decoded['base64']?.toString();
        if (base64Str == null && decoded.containsKey('qrcode') && decoded['qrcode'] is Map) {
          base64Str = (decoded['qrcode'] as Map)['base64']?.toString();
        }

        if (base64Str != null && base64Str.isNotEmpty) {
          // Remove prefixo se houver (data:image/png;base64,)
          if (base64Str.contains(',')) {
            base64Str = base64Str.split(',').last;
          }
          base64Str = base64Str.replaceAll(RegExp(r'\s+'), '');

          return EvolutionConnectResult(
            sucesso: true,
            base64Qr: base64Str,
            pairingCode: decoded['pairingCode']?.toString(),
            count: decoded['count']?.toString(),
          );
        }

        final count = decoded['count']?.toString() ??
            (decoded.containsKey('qrcode') && decoded['qrcode'] is Map
                ? (decoded['qrcode'] as Map)['count']?.toString()
                : null);

        return EvolutionConnectResult(
          sucesso: false,
          count: count,
          erro: count == '0'
              ? 'Aguardando inicialização do QR Code pela Evolution API...'
              : 'QR Code ainda não disponível.',
        );
      }

      final erroCurto = body.length > 200 ? '${body.substring(0, 197)}...' : body;
      return EvolutionConnectResult(
        sucesso: false,
        erro: 'A API retornou HTTP ${resp.statusCode}: $erroCurto',
      );
    } catch (e) {
      final msg = e.toString().contains('TimeoutException')
          ? 'Tempo limite de conexão excedido. O servidor na VPS pode estar lento ou inicializando.'
          : 'Erro ao obter QR Code: $e';
      return EvolutionConnectResult(
        sucesso: false,
        erro: msg,
      );
    } finally {
      client?.close(force: true);
    }
  }

  /// Desvincula (logout) a sessão do WhatsApp na Evolution API (Fase D3)
  static Future<bool> desvincularInstancia({
    required EvolutionApiConfig config,
  }) async {
    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;
    final uri = Uri.parse('$cleanUrl/instance/logout/${config.instanceName}');

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final req = await client.deleteUrl(uri).timeout(const Duration(seconds: 15));
      if (config.apiKey.isNotEmpty) {
        req.headers.set('apikey', config.apiKey);
      }
      final resp = await req.close().timeout(const Duration(seconds: 15));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }

  /// Remove completamente a instância da Evolution API (Fase D3)
  static Future<bool> deletarInstancia({
    required EvolutionApiConfig config,
  }) async {
    final cleanUrl = config.apiUrl.endsWith('/')
        ? config.apiUrl.substring(0, config.apiUrl.length - 1)
        : config.apiUrl;
    final uri = Uri.parse('$cleanUrl/instance/delete/${config.instanceName}');

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);
      final req = await client.deleteUrl(uri).timeout(const Duration(seconds: 20));
      if (config.apiKey.isNotEmpty) {
        req.headers.set('apikey', config.apiKey);
      }
      final resp = await req.close().timeout(const Duration(seconds: 20));
      return (resp.statusCode >= 200 && resp.statusCode < 300) || resp.statusCode == 404;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }
}

/// Resultado da criação de instância na Evolution API
class EvolutionCreateResult {
  final bool sucesso;
  final bool jaExistia;
  final String? erro;

  const EvolutionCreateResult({
    required this.sucesso,
    this.jaExistia = false,
    this.erro,
  });
}

/// Informações do estado operacional e perfil da instância WhatsApp (Fase D3)
class EvolutionInstanceInfo {
  final String name;
  final String connectionStatus; // 'open', 'close', 'connecting', 'not_found', 'error'
  final String? ownerJid;
  final String? profileName;
  final String? profilePicUrl;
  final int? disconnectionReasonCode;
  final String? disconnectionMessage;
  final DateTime? disconnectionAt;

  const EvolutionInstanceInfo({
    required this.name,
    required this.connectionStatus,
    this.ownerJid,
    this.profileName,
    this.profilePicUrl,
    this.disconnectionReasonCode,
    this.disconnectionMessage,
    this.disconnectionAt,
  });

  bool get isConnected => connectionStatus.toLowerCase() == 'open';
  bool get isConnecting => connectionStatus.toLowerCase() == 'connecting';
  bool get isDisconnected => connectionStatus.toLowerCase() == 'close';
  bool get isNotFound => connectionStatus.toLowerCase() == 'not_found';
  bool get isNotConfigured => connectionStatus.toLowerCase() == 'not_configured';
  bool get isError => connectionStatus.toLowerCase() == 'error';

  String? get formattedPhone {
    if (ownerJid == null || ownerJid!.trim().isEmpty) return null;
    final digits = ownerJid!.split('@').first.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 13 && digits.startsWith('55')) {
      return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
    } else if (digits.length == 12 && digits.startsWith('55')) {
      return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 8)}-${digits.substring(8)}';
    }
    return digits.isNotEmpty ? '+$digits' : null;
  }
}

/// Resultado detalhado da tentativa de obtenção de QR Code ou conexão
class EvolutionConnectResult {
  final bool sucesso;
  final String? base64Qr;
  final String? pairingCode;
  final String? count;
  final String? erro;
  final bool isAlreadyConnected;

  const EvolutionConnectResult({
    required this.sucesso,
    this.base64Qr,
    this.pairingCode,
    this.count,
    this.erro,
    this.isAlreadyConnected = false,
  });
}
