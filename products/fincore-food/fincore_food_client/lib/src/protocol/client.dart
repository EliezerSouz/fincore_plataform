/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:fincore_food_client/src/protocol/auth_user_info.dart' as _i3;
import 'package:fincore_food_client/src/protocol/bootstrap_payload.dart' as _i4;
import 'package:fincore_food_client/src/protocol/greeting.dart' as _i5;
import 'package:fincore_food_client/src/protocol/map_route_result.dart' as _i6;
import 'package:fincore_food_client/src/protocol/empresa.dart' as _i7;
import 'package:fincore_food_client/src/protocol/workspace_setup_progress_info.dart'
    as _i8;
import 'package:fincore_food_client/src/protocol/sync_push_entry.dart' as _i9;
import 'package:fincore_food_client/src/protocol/sync_pull_payload.dart'
    as _i10;
import 'protocol.dart' as _i11;

/// {@category Endpoint}
class EndpointAdmin extends _i1.EndpointRef {
  EndpointAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'admin';

  /// Ativa uma empresa pendente de aprovação.
  _i2.Future<bool> ativarEmpresa(String tenantId) =>
      caller.callServerEndpoint<bool>(
        'admin',
        'ativarEmpresa',
        {'tenantId': tenantId},
      );

  /// Retorna lista de empresas aguardando ativação
  _i2.Future<List<String>> empresasPendentes() =>
      caller.callServerEndpoint<List<String>>(
        'admin',
        'empresasPendentes',
        {},
      );
}

/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Faz a validação da sessão autenticada por JWT e retorna as informações do usuário logado.
  _i2.Future<_i3.AuthUserInfo?> login() =>
      caller.callServerEndpoint<_i3.AuthUserInfo?>(
        'auth',
        'login',
        {},
      );

  _i2.Future<void> logout() => caller.callServerEndpoint<void>(
        'auth',
        'logout',
        {},
      );
}

/// {@category Endpoint}
class EndpointBootstrap extends _i1.EndpointRef {
  EndpointBootstrap(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'bootstrap';

  /// Retorna todos os dados necessários para inicializar o aplicativo no dispositivo do cliente.
  _i2.Future<_i4.BootstrapPayload> bootstrapTenant() =>
      caller.callServerEndpoint<_i4.BootstrapPayload>(
        'bootstrap',
        'bootstrapTenant',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i5.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i5.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// {@category Endpoint}
class EndpointMapRoute extends _i1.EndpointRef {
  EndpointMapRoute(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapRoute';

  /// Calcula a distância (metros) e duração (segundos) de deslocamento
  /// entre a origem (empresa) e o destino (entrega do cliente).
  ///
  /// Utiliza cache persistente no banco PostgreSQL (Supabase) via queries diretas.
  _i2.Future<_i6.MapRouteResult> calculateRoute(
    String origin,
    String destination,
  ) =>
      caller.callServerEndpoint<_i6.MapRouteResult>(
        'mapRoute',
        'calculateRoute',
        {
          'origin': origin,
          'destination': destination,
        },
      );
}

/// {@category Endpoint}
class EndpointOnboarding extends _i1.EndpointRef {
  EndpointOnboarding(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'onboarding';

  /// Cria uma nova empresa (tenant) e vincula o usuário autenticado como ADMIN.
  _i2.Future<bool> criarEmpresa({
    required String tenantId,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String emailEmpresa,
    required String telefoneEmpresa,
    required String usuarioNome,
    required String segmento,
    String? plano,
  }) =>
      caller.callServerEndpoint<bool>(
        'onboarding',
        'criarEmpresa',
        {
          'tenantId': tenantId,
          'razaoSocial': razaoSocial,
          'nomeFantasia': nomeFantasia,
          'documentoFiscal': documentoFiscal,
          'emailEmpresa': emailEmpresa,
          'telefoneEmpresa': telefoneEmpresa,
          'usuarioNome': usuarioNome,
          'segmento': segmento,
          'plano': plano,
        },
      );

  /// Consulta os dados da empresa vinculada ao usuário autenticado
  _i2.Future<_i7.Empresa?> minhaEmpresa() =>
      caller.callServerEndpoint<_i7.Empresa?>(
        'onboarding',
        'minhaEmpresa',
        {},
      );

  /// Consulta o status de ativação da empresa vinculada ao usuário
  _i2.Future<String?> status() => caller.callServerEndpoint<String?>(
        'onboarding',
        'status',
        {},
      );

  /// Calcula o progresso do setup do workspace (categorias, produtos, etc.)
  _i2.Future<_i8.WorkspaceSetupProgressInfo> progressoSetup(String tenantId) =>
      caller.callServerEndpoint<_i8.WorkspaceSetupProgressInfo>(
        'onboarding',
        'progressoSetup',
        {'tenantId': tenantId},
      );
}

/// {@category Endpoint}
class EndpointSync extends _i1.EndpointRef {
  EndpointSync(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sync';

  /// Recebe uma lista de alterações geradas no FincoreCore (Outbox)
  /// e as aplica no banco Postgres usando Last-Write-Wins.
  ///
  /// ⚠️  INCOMPLETO: Apenas 'empresa_configuracao' é tratado.
  /// Os demais casos caem no `default` com log de warning.
  /// O sync real acontece via SupabaseSyncService no Flutter.
  _i2.Future<bool> push(List<_i9.SyncPushEntry> changes) =>
      caller.callServerEndpoint<bool>(
        'sync',
        'push',
        {'changes': changes},
      );

  /// Retorna as modificações que ocorreram no servidor desde a última sincronização local
  _i2.Future<_i10.SyncPullPayload> pull(DateTime lastSyncAt) =>
      caller.callServerEndpoint<_i10.SyncPullPayload>(
        'sync',
        'pull',
        {'lastSyncAt': lastSyncAt},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i11.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    admin = EndpointAdmin(this);
    auth = EndpointAuth(this);
    bootstrap = EndpointBootstrap(this);
    greeting = EndpointGreeting(this);
    mapRoute = EndpointMapRoute(this);
    onboarding = EndpointOnboarding(this);
    sync = EndpointSync(this);
  }

  late final EndpointAdmin admin;

  late final EndpointAuth auth;

  late final EndpointBootstrap bootstrap;

  late final EndpointGreeting greeting;

  late final EndpointMapRoute mapRoute;

  late final EndpointOnboarding onboarding;

  late final EndpointSync sync;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'admin': admin,
        'auth': auth,
        'bootstrap': bootstrap,
        'greeting': greeting,
        'mapRoute': mapRoute,
        'onboarding': onboarding,
        'sync': sync,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
