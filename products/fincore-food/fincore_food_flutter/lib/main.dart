import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/shared/presentation/router/fincore_root_router.dart';
import 'src/shared/database_initializer.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:intl/date_symbol_data_local.dart';

class FincoreHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..findProxy = (uri) => 'DIRECT';
  }
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting('pt_BR', null);
      if (!kIsWeb) {
        HttpOverrides.global = FincoreHttpOverrides();
      }

      // Captura erros de framework Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        final errorString = details.exceptionAsString();

        // Ignora bug interno de asserts do RawKeyboard no Windows Desktop
        if (errorString.contains('Attempted to send a key down event') ||
            errorString.contains('keysPressed') ||
            errorString.contains('raw_keyboard.dart')) {
          debugPrint(
              '⚠️ Ignorando crash conhecido de RawKeyboard no Windows: $errorString');
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

      // Inicializa banco local Drift + Supabase + DI
      await DatabaseInitializer.init();

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

/// Gerencia a chave de autenticação local para persistência offline.
///
/// Mantida por compatibilidade com SharedPreferences — usada para
/// armazenar o ID do usuário offline entre sessões.
class LocalAuthKeyManager {
  static const _key = 'fincore_auth_key';
  String? _cachedKey;

  Future<String?> get() async {
    if (_cachedKey != null) return _cachedKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedKey = prefs.getString(_key);
    } catch (_) {}
    return _cachedKey;
  }

  Future<void> put(String key) async {
    _cachedKey = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, key);
    } catch (_) {}
  }

  Future<void> remove() async {
    _cachedKey = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
