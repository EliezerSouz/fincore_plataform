import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef NativeBeep = Int32 Function(Uint32 dwFreq, Uint32 dwDuration);
typedef DartBeep = int Function(int dwFreq, int dwDuration);

/// Estilos de alerta sonoro disponíveis para a cozinha
enum SoundStyle {
  kitchenAlarm(
    'Alarme de Cozinha (Bip Triplo Agudo)',
    'Tons de alta frequência (1800Hz - 3000Hz) ideais para cortar barulhos de exaustor e fritadeira.',
  ),
  urgentSiren(
    'Sirene de Urgência (Bip Repetitivo)',
    'Pulsos rápidos e intensos para chamadas prioritárias de atraso/entrega.',
  ),
  dingDong(
    'Campainha de Restaurante (Ding-Dong)',
    'Melodia suave de duas notas (C6 - G5) agradável para balcões e salão.',
  ),
  systemDefault(
    'Som Padrão do Windows',
    'Som de alerta nativo do sistema operacional.',
  );

  final String label;
  final String description;
  const SoundStyle(this.label, this.description);
}

/// Serviço utilitário de alertas sonoros para a Central de Pedidos e Cozinha (KDS).
/// Utiliza Win32 FFI Beep no Windows para gerar tons agudos de alta visibilidade e volume.
class SoundService {
  static const String _prefEnabledKey = 'sound_service_enabled';
  static const String _prefStyleKey = 'sound_service_style_index';

  static bool _enabled = true;
  static bool get enabled => _enabled;
  static set enabled(bool value) {
    _enabled = value;
    savePreferences();
  }

  static SoundStyle currentStyle = SoundStyle.kitchenAlarm;

  static DartBeep? _winBeep;
  static bool _initialized = false;

  static Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefEnabledKey) ?? true;
      final styleIdx = prefs.getInt(_prefStyleKey) ?? 0;
      if (styleIdx >= 0 && styleIdx < SoundStyle.values.length) {
        currentStyle = SoundStyle.values[styleIdx];
      }
    } catch (e) {
      debugPrint('[SoundService] Erro ao carregar preferências de som: $e');
    }
  }

  static Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefEnabledKey, _enabled);
      await prefs.setInt(_prefStyleKey, currentStyle.index);
    } catch (e) {
      debugPrint('[SoundService] Erro ao salvar preferências de som: $e');
    }
  }

  static void _initNative() {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) return;
    if (Platform.isWindows) {
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        _winBeep = kernel32.lookupFunction<NativeBeep, DartBeep>('Beep');
      } catch (e) {
        debugPrint('[SoundService] Falha ao carregar kernel32.dll: $e');
      }
    }
  }

  static Future<void> _playBeep(int freqHz, int durationMs) async {
    _initNative();
    if (!kIsWeb && Platform.isWindows && _winBeep != null) {
      try {
        _winBeep!(freqHz, durationMs);
      } catch (e) {
        debugPrint('[SoundService] Beep FFI error: $e');
      }
    }
  }

  /// Toca um sinal sonoro de atenção (pedidos com entregas próximas ≤ 30 min)
  static Future<void> playAttentionSound() async {
    if (!_enabled) return;
    _initNative();

    switch (currentStyle) {
      case SoundStyle.kitchenAlarm:
        await Future.microtask(() async {
          await _playBeep(1800, 140);
          await Future.delayed(const Duration(milliseconds: 50));
          await _playBeep(2400, 200);
        });
        break;

      case SoundStyle.dingDong:
        await Future.microtask(() async {
          await _playBeep(1046, 220); // C6
          await Future.delayed(const Duration(milliseconds: 40));
          await _playBeep(784, 450);  // G5
        });
        break;

      case SoundStyle.urgentSiren:
        await Future.microtask(() async {
          await _playBeep(2200, 100);
          await Future.delayed(const Duration(milliseconds: 40));
          await _playBeep(2200, 100);
        });
        break;

      case SoundStyle.systemDefault:
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (e) {
          debugPrint('[SoundService] Erro som sistema: $e');
        }
        break;
    }
  }

  /// Toca um sinal sonoro de urgência crítica (pedidos ≤ 15 min ou atrasados) - MUITO CHAMATIVO!
  static Future<void> playUrgentSound() async {
    if (!_enabled) return;
    _initNative();

    switch (currentStyle) {
      case SoundStyle.kitchenAlarm:
        await Future.microtask(() async {
          await _playBeep(1800, 120);
          await Future.delayed(const Duration(milliseconds: 30));
          await _playBeep(2400, 120);
          await Future.delayed(const Duration(milliseconds: 30));
          await _playBeep(3000, 250);
          await Future.delayed(const Duration(milliseconds: 120));
          await _playBeep(3000, 280);
        });
        break;

      case SoundStyle.dingDong:
        await Future.microtask(() async {
          await _playBeep(1046, 180);
          await Future.delayed(const Duration(milliseconds: 30));
          await _playBeep(784, 300);
          await Future.delayed(const Duration(milliseconds: 100));
          await _playBeep(1046, 180);
          await Future.delayed(const Duration(milliseconds: 30));
          await _playBeep(784, 400);
        });
        break;

      case SoundStyle.urgentSiren:
        await Future.microtask(() async {
          for (int i = 0; i < 4; i++) {
            await _playBeep(2400, 70);
            await Future.delayed(const Duration(milliseconds: 30));
            await _playBeep(2800, 70);
            await Future.delayed(const Duration(milliseconds: 30));
          }
        });
        break;

      case SoundStyle.systemDefault:
        try {
          await SystemSound.play(SystemSoundType.alert);
          await Future.delayed(const Duration(milliseconds: 350));
          await SystemSound.play(SystemSoundType.alert);
        } catch (e) {
          debugPrint('[SoundService] Erro som sistema: $e');
        }
        break;
    }
  }

  /// Toca um sinal sonoro de NOVO PEDIDO CHEGANDO na cozinha / balcão
  static Future<void> playNewOrderSound() async {
    if (!_enabled) return;
    _initNative();

    switch (currentStyle) {
      case SoundStyle.kitchenAlarm:
        await Future.microtask(() async {
          await _playBeep(1046, 120);
          await Future.delayed(const Duration(milliseconds: 30));
          await _playBeep(1318, 120);
          await Future.delayed(const Duration(milliseconds: 30));
          await _playBeep(1568, 250);
          await Future.delayed(const Duration(milliseconds: 100));
          await _playBeep(2093, 300);
        });
        break;

      case SoundStyle.dingDong:
        await Future.microtask(() async {
          await _playBeep(784, 180);
          await Future.delayed(const Duration(milliseconds: 40));
          await _playBeep(1046, 300);
          await Future.delayed(const Duration(milliseconds: 60));
          await _playBeep(1318, 350);
        });
        break;

      case SoundStyle.urgentSiren:
        await Future.microtask(() async {
          for (int i = 0; i < 3; i++) {
            await _playBeep(2600, 90);
            await Future.delayed(const Duration(milliseconds: 40));
            await _playBeep(3200, 90);
            await Future.delayed(const Duration(milliseconds: 40));
          }
        });
        break;

      case SoundStyle.systemDefault:
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (e) {
          debugPrint('[SoundService] Erro som novo pedido: $e');
        }
        break;
    }
  }

  /// Toca um sinal suave de confirmação de ação
  static Future<void> playSuccessSound() async {
    if (!_enabled) return;
    _initNative();
    if (!kIsWeb && Platform.isWindows && _winBeep != null) {
      await Future.microtask(() async {
        await _playBeep(1500, 80);
      });
    } else {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (e) {
        debugPrint('[SoundService] Erro som clique: $e');
      }
    }
  }
}
