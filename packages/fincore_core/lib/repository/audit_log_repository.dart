import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import '../common/app_constants.dart';
import '../context/tenant_context.dart';
import '../src/logging/log_service.dart';
import 'usuario_repository.dart';

class AuditLogRepository {
  final FincoreDatabase _db;
  final OutboxService _outboxRepo;

  AuditLogRepository({
    FincoreDatabase? db,
    OutboxService? outboxRepo,
  })  : _db = db ?? DependencyInjection().get<FincoreDatabase>(),
        _outboxRepo = outboxRepo ?? DependencyInjection().get<OutboxService>();

  /// Registra uma nova entrada de auditoria imutável com contexto forense rico e enfileira no Outbox.
  Future<void> log({
    required String entityName,
    required String entityId,
    required String userId,
    required String action, // CREATE, UPDATE, DELETE, LOGIN, SYNC...
    Map<String, dynamic>? diff,
    int? syncVersion,
    String? deviceInfo,
    String? origin,
    String? reason,
    // Contexto histórico forense desnormalizado
    String? userName,
    String? userRole,
    String? machineName,
    String? hostName,
    String? ipAddress,
    String? macAddress,
    String? platform,
    String? osVersion,
    String? appVersion,
    String? sessionId,
    String? browser,
    String? deviceDescription,
    String? entityDisplayName,
    String? entityModule,
  }) async {
    final auditId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc();
    final diffJson = diff != null ? jsonEncode(diff) : null;

    String activeTenantId = 'system';
    String defaultUserName = 'Usuário do Sistema';
    String defaultUserRole = 'Operador';

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      if (tenantCtx.hasContext) {
        activeTenantId = tenantCtx.tenantId;
        if (tenantCtx.usuario.nome.isNotEmpty && !_isUuid(tenantCtx.usuario.nome)) {
          defaultUserName = tenantCtx.usuario.nome;
        }
        defaultUserRole = tenantCtx.usuario.role ?? 'Operador';
      }
    } catch (_) {}

    String resolvedUserName = userName ?? defaultUserName;
    if (_isUuid(resolvedUserName)) {
      if (defaultUserName != 'Usuário do Sistema' && !_isUuid(defaultUserName)) {
        resolvedUserName = defaultUserName;
      } else {
        try {
          final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
          final u = await usuarioRepo.findById(userId);
          if (u != null && u.nome.isNotEmpty && !_isUuid(u.nome)) {
            resolvedUserName = u.nome;
          }
        } catch (_) {}
      }
    }

    final resolvedUserRole = userRole ?? defaultUserRole;
    final resolvedHostName = hostName ?? (Platform.isWindows || Platform.isLinux || Platform.isMacOS ? Platform.localHostname : 'Terminal-Local');
    final resolvedMachineName = machineName ?? resolvedHostName;
    final resolvedPlatform = platform ?? (Platform.isWindows ? 'Desktop' : (Platform.isAndroid ? 'Android' : 'Web'));
    final resolvedOsVersion = osVersion ?? _resolveOsVersion();
    final resolvedAppVersion = appVersion ?? AppConstants.version;
    final resolvedIpAddress = ipAddress ?? await _resolveLocalIp();

    final companion = AuditLogsTableCompanion.insert(
      id: auditId,
      targetEntity: entityName,
      entityId: entityId,
      tenantId: activeTenantId,
      userId: userId,
      action: action,
      timestamp: timestamp,
      diff: Value(diffJson),
      syncVersion: Value(syncVersion),
      deviceInfo: Value(deviceInfo),
      origin: Value(origin ?? resolvedPlatform),
      reason: Value(reason),
      userName: Value(resolvedUserName),
      userRole: Value(resolvedUserRole),
      machineName: Value(resolvedMachineName),
      hostName: Value(resolvedHostName),
      ipAddress: Value(resolvedIpAddress),
      macAddress: Value(macAddress),
      platform: Value(resolvedPlatform),
      osVersion: Value(resolvedOsVersion),
      appVersion: Value(resolvedAppVersion),
      sessionId: Value(sessionId),
      browser: Value(browser),
      deviceDescription: Value(deviceDescription ?? '$resolvedMachineName ($resolvedPlatform)'),
      entityDisplayName: Value(entityDisplayName ?? entityName),
      entityModule: Value(entityModule ?? _inferModule(entityName)),
    );

    await _db.into(_db.auditLogsTable).insert(companion);

    // Enfileira para o Supabase (Push) com compatibilidade dual (camelCase + snake_case)
    final payload = {
      'id': auditId,
      'tenantId': activeTenantId,
      'entityName': entityName,
      'entityId': entityId,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'diff': diffJson,
      'syncVersion': syncVersion ?? 1,
      'deviceInfo': deviceInfo,
      'origin': origin ?? resolvedPlatform,
      'reason': reason,
      'user_name': resolvedUserName,
      'user_role': resolvedUserRole,
      'machine_name': resolvedMachineName,
      'host_name': resolvedHostName,
      'ip_address': resolvedIpAddress,
      'mac_address': macAddress,
      'platform': resolvedPlatform,
      'os_version': resolvedOsVersion,
      'app_version': resolvedAppVersion,
      'session_id': sessionId,
      'browser': browser,
      'device_description': deviceDescription ?? '$resolvedMachineName ($resolvedPlatform)',
      'entity_display_name': entityDisplayName ?? entityName,
      'entity_module': entityModule ?? _inferModule(entityName),
    };

    await _outboxRepo.enqueue(
      entity: 'audit_log',
      entityId: auditId,
      action: 'UPSERT',
      payload: payload,
      version: 1,
    );

    final diffStr = diffJson != null ? ' | Alterações: $diffJson' : '';
    await LogService.instance.info(
      LogModule.database,
      'AUDIT LOG ID: $auditId | Usuário: $resolvedUserName ($resolvedUserRole) | Máquina: $resolvedMachineName | Entidade: [$entityName] ID: $entityId | Ação: $action$diffStr',
      tenantId: activeTenantId,
    );
  }

  /// Retorna o histórico de auditoria para uma entidade específica.
  Future<List<AuditLogEntry>> findByEntity(String entityName, String entityId) async {
    return (_db.select(_db.auditLogsTable)
          ..where((t) => t.targetEntity.equals(entityName) & t.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  /// Retorna todo o histórico de auditoria do tenant ativo.
  Future<List<AuditLogEntry>> findAllGlobal() async {
    String activeTenantId = 'system';
    try {
      activeTenantId = DependencyInjection().get<TenantContext>().tenantId;
    } catch (_) {}

    return (_db.select(_db.auditLogsTable)
          ..where((t) => t.tenantId.equals(activeTenantId))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  /// Busca avançada de auditoria forense com múltiplos filtros.
  Future<List<AuditLogEntry>> query({
    String? entityModule,
    String? userId,
    String? action,
    String? search,
    String? machineName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String activeTenantId = 'system';
    try {
      activeTenantId = DependencyInjection().get<TenantContext>().tenantId;
    } catch (_) {}

    final q = _db.select(_db.auditLogsTable)
      ..where((t) => t.tenantId.equals(activeTenantId));

    if (entityModule != null && entityModule != 'Todos') {
      q.where((t) => t.entityModule.equals(entityModule));
    }
    if (userId != null && userId != 'Todos') {
      q.where((t) => t.userId.equals(userId));
    }
    if (action != null && action != 'Todos') {
      q.where((t) => t.action.equals(action));
    }
    if (machineName != null && machineName != 'Todas') {
      q.where((t) => t.machineName.equals(machineName));
    }
    if (startDate != null) {
      q.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      q.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
    }

    // P3-03: Busca livre via SQL LIKE — empurra o filtro para o SQLite em vez de
    // carregar todos os registros em memória e filtrar em Dart.
    // SQLite usa índice de prefixo quando o padrão começa sem '%', portanto
    // '%term%' é menos seletivo mas correto para busca parcial genérica.
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q.where((t) =>
          t.userName.like(term) |
          t.userRole.like(term) |
          t.machineName.like(term) |
          t.ipAddress.like(term) |
          t.targetEntity.like(term) |
          t.entityDisplayName.like(term) |
          t.diff.like(term) |
          t.action.like(term));
    }

    q.orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]);
    return q.get();
  }

  String _inferModule(String entityName) {
    switch (entityName.toLowerCase()) {
      case 'empresa':
      case 'empresa_configuracao':
        return 'Empresa';
      case 'produto':
      case 'produtos':
      case 'categoria':
      case 'categorias':
        return 'Produtos';
      case 'cliente':
      case 'clientes':
      case 'local_entrega':
      case 'locais_entrega':
        return 'Clientes';
      case 'pedido':
      case 'pedidos':
      case 'itens_pedido':
      case 'itempedido':
      case 'ordempreparo':
        return 'Pedidos';
      // P3-02: Entidades de precificação faltantes
      case 'tabela_precificacao':
      case 'tabelas_precificacao':
      case 'item_tabela_precificacao':
      case 'itens_tabela_precificacao':
      case 'produto_tabela_precificacao':
      case 'produtos_tabelas_precificacao':
      case 'categoria_tabela_precificacao':
      case 'categorias_tabelas_precificacao':
        return 'Políticas de Preço';
      // P3-02: Entidades de taxa/entrega faltantes
      case 'taxa_entrega':
      case 'taxas_entrega':
        return 'Taxas de Entrega';
      case 'forma_pagamento':
      case 'formas_pagamento':
        return 'Formas de Pagamento';
      case 'membros_empresa':
      case 'membro_empresa':
      case 'usuario':
      case 'usuarios':
        return 'Usuários';
      case 'syncengine':
      case 'sync_engine':
        return 'Sincronização';
      default:
        return 'Configurações';
    }
  }

  static String? _cachedIp;
  static DateTime? _cachedIpAt;
  // P3-06: TTL de 30min para o cache de IP (lida com DHCP)
  static const _ipCacheTtl = Duration(minutes: 30);

  static Future<String> _resolveLocalIp() async {
    final now = DateTime.now();
    if (_cachedIp != null &&
        _cachedIpAt != null &&
        now.difference(_cachedIpAt!) < _ipCacheTtl) {
      return _cachedIp!;
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            _cachedIp = addr.address;
            _cachedIpAt = now;
            return _cachedIp!;
          }
        }
      }
    } catch (_) {}
    _cachedIp = '127.0.0.1';
    _cachedIpAt = now;
    return _cachedIp!;
  }

  static String _resolveOsVersion() {
    if (Platform.isWindows) {
      final raw = Platform.operatingSystemVersion;
      // Exemplo de retorno bruto: "Windows 10 Pro" 10.0 (Build 26200)
      final buildMatch = RegExp(r'Build\s+(\d+)').firstMatch(raw);
      if (buildMatch != null) {
        final buildNum = int.tryParse(buildMatch.group(1) ?? '0') ?? 0;
        if (buildNum >= 22000) {
          // É Windows 11 (Build >= 22000)!
          return raw.replaceFirst('Windows 10', 'Windows 11');
        }
      }
      return raw;
    }
    return Platform.operatingSystemVersion;
  }

  static bool _isUuid(String input) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(input.trim());
  }
}
