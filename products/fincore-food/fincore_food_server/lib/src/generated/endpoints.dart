/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../admin_endpoint.dart' as _i2;
import '../auth_endpoint.dart' as _i3;
import '../bootstrap_endpoint.dart' as _i4;
import '../greeting_endpoint.dart' as _i5;
import '../onboarding_endpoint.dart' as _i6;
import '../sync_endpoint.dart' as _i7;
import 'package:fincore_food_server/src/generated/sync_push_entry.dart' as _i8;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'admin': _i2.AdminEndpoint()
        ..initialize(
          server,
          'admin',
          null,
        ),
      'auth': _i3.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'bootstrap': _i4.BootstrapEndpoint()
        ..initialize(
          server,
          'bootstrap',
          null,
        ),
      'greeting': _i5.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'onboarding': _i6.OnboardingEndpoint()
        ..initialize(
          server,
          'onboarding',
          null,
        ),
      'sync': _i7.SyncEndpoint()
        ..initialize(
          server,
          'sync',
          null,
        ),
    };
    connectors['admin'] = _i1.EndpointConnector(
      name: 'admin',
      endpoint: endpoints['admin']!,
      methodConnectors: {
        'ativarEmpresa': _i1.MethodConnector(
          name: 'ativarEmpresa',
          params: {
            'tenantId': _i1.ParameterDescription(
              name: 'tenantId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['admin'] as _i2.AdminEndpoint).ativarEmpresa(
            session,
            params['tenantId'],
          ),
        ),
        'empresasPendentes': _i1.MethodConnector(
          name: 'empresasPendentes',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['admin'] as _i2.AdminEndpoint)
                  .empresasPendentes(session),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i3.AuthEndpoint).login(session),
        ),
        'logout': _i1.MethodConnector(
          name: 'logout',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i3.AuthEndpoint).logout(session),
        ),
      },
    );
    connectors['bootstrap'] = _i1.EndpointConnector(
      name: 'bootstrap',
      endpoint: endpoints['bootstrap']!,
      methodConnectors: {
        'bootstrapTenant': _i1.MethodConnector(
          name: 'bootstrapTenant',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['bootstrap'] as _i4.BootstrapEndpoint)
                  .bootstrapTenant(session),
        )
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['greeting'] as _i5.GreetingEndpoint).hello(
            session,
            params['name'],
          ),
        )
      },
    );
    connectors['onboarding'] = _i1.EndpointConnector(
      name: 'onboarding',
      endpoint: endpoints['onboarding']!,
      methodConnectors: {
        'criarEmpresa': _i1.MethodConnector(
          name: 'criarEmpresa',
          params: {
            'tenantId': _i1.ParameterDescription(
              name: 'tenantId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'razaoSocial': _i1.ParameterDescription(
              name: 'razaoSocial',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'nomeFantasia': _i1.ParameterDescription(
              name: 'nomeFantasia',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'documentoFiscal': _i1.ParameterDescription(
              name: 'documentoFiscal',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'emailEmpresa': _i1.ParameterDescription(
              name: 'emailEmpresa',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'telefoneEmpresa': _i1.ParameterDescription(
              name: 'telefoneEmpresa',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'usuarioNome': _i1.ParameterDescription(
              name: 'usuarioNome',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'segmento': _i1.ParameterDescription(
              name: 'segmento',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['onboarding'] as _i6.OnboardingEndpoint).criarEmpresa(
            session,
            tenantId: params['tenantId'],
            razaoSocial: params['razaoSocial'],
            nomeFantasia: params['nomeFantasia'],
            documentoFiscal: params['documentoFiscal'],
            emailEmpresa: params['emailEmpresa'],
            telefoneEmpresa: params['telefoneEmpresa'],
            usuarioNome: params['usuarioNome'],
            segmento: params['segmento'],
          ),
        ),
        'status': _i1.MethodConnector(
          name: 'status',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['onboarding'] as _i6.OnboardingEndpoint)
                  .status(session),
        ),
        'progressoSetup': _i1.MethodConnector(
          name: 'progressoSetup',
          params: {
            'tenantId': _i1.ParameterDescription(
              name: 'tenantId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['onboarding'] as _i6.OnboardingEndpoint)
                  .progressoSetup(
            session,
            params['tenantId'],
          ),
        ),
      },
    );
    connectors['sync'] = _i1.EndpointConnector(
      name: 'sync',
      endpoint: endpoints['sync']!,
      methodConnectors: {
        'push': _i1.MethodConnector(
          name: 'push',
          params: {
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i8.SyncPushEntry>>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['sync'] as _i7.SyncEndpoint).push(
            session,
            params['changes'],
          ),
        ),
        'pull': _i1.MethodConnector(
          name: 'pull',
          params: {
            'lastSyncAt': _i1.ParameterDescription(
              name: 'lastSyncAt',
              type: _i1.getType<DateTime>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['sync'] as _i7.SyncEndpoint).pull(
            session,
            params['lastSyncAt'],
          ),
        ),
      },
    );
  }
}
