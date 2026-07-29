import 'dart:async';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/shared/presentation/router/fincore_root_router.dart';
import 'src/shared/database_initializer.dart';
import 'package:fincore_core/fincore_core.dart';

late final Client client;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Captura erros de framework Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        try {
          LogService.instance.error(
            LogModule.crash,
            'Erro de framework Flutter: ${details.exceptionAsString()}',
            stackTrace: details.stack?.toString(),
          );
        } catch (_) {
          debugPrint('═══ FLUTTER ERROR (FALLBACK) ═══');
          debugPrint(details.exceptionAsString());
        }
      };

      const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
      final serverUrl =
          serverUrlFromEnv.isEmpty ? 'http://localhost:8080/' : serverUrlFromEnv;

      debugPrint('Conectando ao servidor: $serverUrl');

      client = Client(
        serverUrl,
        authenticationKeyManager: FlutterAuthenticationKeyManager(),
      )..connectivityMonitor = FlutterConnectivityMonitor();

      debugPrint('Client criado. Iniciando DatabaseInitializer...');

      // Inicializa o banco local Drift e registra no DI
      await DatabaseInitializer.init(client);

      debugPrint('DatabaseInitializer concluído. Iniciando app...');

      runApp(const MyApp());
    },
    (error, stackTrace) {
      try {
        LogService.instance.error(
          LogModule.crash,
          'Erro crítico não tratado (ZonedGuarded): $error',
          stackTrace: stackTrace.toString(),
        );
      } catch (_) {
        debugPrint('═══ ERRO NÃO TRATADO (FALLBACK) ═══');
        debugPrint('Erro: $error');
        debugPrint('Stack: $stackTrace');
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINCORE Food Platform',
      debugShowCheckedModeBanner: false,
      theme: FincoreTheme.darkTheme,
      home: const FincoreRootRouter(),
    );
  }
}

/// Custom key manager using SharedPreferences for offline-first token persistence.
class FlutterAuthenticationKeyManager extends AuthenticationKeyManager {
  static const _key = 'fincore_auth_key';
  String? _cachedKey;

  @override
  Future<String?> get() async {
    if (_cachedKey != null) return _cachedKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedKey = prefs.getString(_key);
    } catch (_) {}
    return _cachedKey;
  }

  @override
  Future<void> put(String key) async {
    _cachedKey = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, key);
    } catch (_) {}
  }

  @override
  Future<void> remove() async {
    _cachedKey = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
