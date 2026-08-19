import 'dart:async';
import 'dart:io';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/shared/presentation/router/fincore_root_router.dart';
import 'src/shared/database_initializer.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:intl/date_symbol_data_local.dart';

class FincoreHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) => 'DIRECT';
  }
}

late final Client client;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting('pt_BR', null);
      HttpOverrides.global = FincoreHttpOverrides();

      // Captura erros de framework Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        final errorString = details.exceptionAsString();
        
        // Ignora bug interno de asserts do RawKeyboard no Windows Desktop
        if (errorString.contains('Attempted to send a key down event') ||
            errorString.contains('keysPressed') ||
            errorString.contains('raw_keyboard.dart')) {
          debugPrint('⚠️ Ignorando crash conhecido de RawKeyboard no Windows: $errorString');
          return;
        }

        try {
          LogService.instance.error(
            LogModule.crash,
            'Erro de framework Flutter: $errorString',
            stackTrace: details.stack?.toString(),
          );
        } catch (_) {
          debugPrint('═══ FLUTTER ERROR (FALLBACK) ═══');
          debugPrint(errorString);
        }

        // Repassa erros reais para apresentação
        FlutterError.presentError(details);
      };

      const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
      final serverUrl =
          serverUrlFromEnv.isEmpty ? 'http://127.0.0.1:18080/' : serverUrlFromEnv;

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final controller = ThemeController.instance;
        return MaterialApp(
          title: 'FINCORE Food Platform',
          debugShowCheckedModeBanner: false,
          themeMode: controller.themeMode,
          theme: controller.lightTheme,
          darkTheme: controller.darkTheme,
          home: const FincoreRootRouter(),
        );
      },
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
