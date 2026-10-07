import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

typedef _FindWindowNative = IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef _FindWindowDart = int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

typedef _ShowWindowNative = Int32 Function(IntPtr hWnd, Int32 nCmdShow);
typedef _ShowWindowDart = int Function(int hWnd, int nCmdShow);

typedef _SetForegroundWindowNative = Int32 Function(IntPtr hWnd);
typedef _SetForegroundWindowDart = int Function(int hWnd);

typedef _IsIconicNative = Int32 Function(IntPtr hWnd);
typedef _IsIconicDart = int Function(int hWnd);

typedef _FlashWindowNative = Int32 Function(IntPtr hWnd, Int32 bInvert);
typedef _FlashWindowDart = int Function(int hWnd, int bInvert);

/// Serviço nativo para controle da janela do Flutter no Windows via Win32 FFI.
///
/// Permite restaurar e focar a janela do aplicativo quando um novo pedido
/// chega do Cardápio Digital ou canal remoto, garantindo que o operador
/// não perca nenhum pedido mesmo estando com outro aplicativo aberto no Windows.
class WindowsFocusService {
  static _FindWindowDart? _findWindow;
  static _ShowWindowDart? _showWindow;
  static _SetForegroundWindowDart? _setForegroundWindow;
  static _IsIconicDart? _isIconic;
  static _FlashWindowDart? _flashWindow;
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final user32 = DynamicLibrary.open('user32.dll');
      _findWindow = user32.lookupFunction<_FindWindowNative, _FindWindowDart>('FindWindowW');
      _showWindow = user32.lookupFunction<_ShowWindowNative, _ShowWindowDart>('ShowWindow');
      _setForegroundWindow = user32.lookupFunction<_SetForegroundWindowNative, _SetForegroundWindowDart>('SetForegroundWindow');
      _isIconic = user32.lookupFunction<_IsIconicNative, _IsIconicDart>('IsIconic');
      _flashWindow = user32.lookupFunction<_FlashWindowNative, _FlashWindowDart>('FlashWindow');
    } catch (e) {
      debugPrint('[WindowsFocusService] Falha ao carregar user32.dll: $e');
    }
  }

  /// Traz a janela do FINCORE FOOD para primeiro plano no Windows,
  /// restaurando se estiver minimizada e fazendo a barra de tarefas piscar.
  static void bringWindowToFront() {
    if (kIsWeb || !Platform.isWindows) return;
    _init();

    if (_findWindow == null) return;

    try {
      final classNamePtr = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
      final hwnd = _findWindow!(classNamePtr, nullptr);
      calloc.free(classNamePtr);

      if (hwnd != 0) {
        // Constantes Win32:
        // SW_RESTORE = 9 (Restaura e ativa se minimizada)
        // SW_SHOW = 5 (Exibe e ativa)
        const swRestore = 9;
        const swShow = 5;

        if (_isIconic != null && _isIconic!(hwnd) != 0) {
          _showWindow?.call(hwnd, swRestore);
        } else {
          _showWindow?.call(hwnd, swShow);
        }

        // Traz para a frente na pilha de janelas
        _setForegroundWindow?.call(hwnd);

        // Faz piscar na barra de tarefas (alerta do Windows)
        _flashWindow?.call(hwnd, 1);
      }
    } catch (e) {
      debugPrint('[WindowsFocusService] Erro ao trazer janela para a frente: $e');
    }
  }
}
