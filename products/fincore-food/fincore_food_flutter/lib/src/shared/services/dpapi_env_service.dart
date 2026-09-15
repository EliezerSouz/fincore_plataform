// ignore_for_file: camel_case_types

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fincore_core/fincore_core.dart';

// ─── Estruturas Win32 para o DPAPI ──────────────────────────────────────────

base class DATA_BLOB extends Struct {
  @Int32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

// ─── Tipagens das funções Win32 ─────────────────────────────────────────────

typedef CryptProtectDataNative = Int32 Function(
  Pointer<DATA_BLOB> pDataIn,
  Pointer<Utf16> szDataDescr,
  Pointer<DATA_BLOB> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  Int32 dwFlags,
  Pointer<DATA_BLOB> pDataOut,
);

typedef CryptProtectDataDart = int Function(
  Pointer<DATA_BLOB> pDataIn,
  Pointer<Utf16> szDataDescr,
  Pointer<DATA_BLOB> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  int dwFlags,
  Pointer<DATA_BLOB> pDataOut,
);

typedef CryptUnprotectDataNative = Int32 Function(
  Pointer<DATA_BLOB> pDataIn,
  Pointer<Pointer<Utf16>> ppszDataDescr,
  Pointer<DATA_BLOB> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  Int32 dwFlags,
  Pointer<DATA_BLOB> pDataOut,
);

typedef CryptUnprotectDataDart = int Function(
  Pointer<DATA_BLOB> pDataIn,
  Pointer<Pointer<Utf16>> ppszDataDescr,
  Pointer<DATA_BLOB> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  int dwFlags,
  Pointer<DATA_BLOB> pDataOut,
);

typedef LocalFreeNative = Pointer<Void> Function(Pointer<Void> hMem);
typedef LocalFreeDart = Pointer<Void> Function(Pointer<Void> hMem);

/// Serviço de proteção do arquivo .env usando Windows DPAPI.
///
/// Comportamento:
/// - Se `.env.dpapi` existe → decriptografa com DPAPI e carrega as variáveis.
/// - Se `.env` existe em texto puro → lê, criptografa com DPAPI, salva como
///   `.env.dpapi` e apaga o `.env` original.
///
/// A chave DPAPI é gerada pelo Windows e vinculada à conta do usuário + máquina.
/// O arquivo `.env.dpapi` é ilegível em qualquer outro computador ou conta.
class DpapiEnvService {
  static const _encryptedFileName = '.env.dpapi';
  static const _plainFileName = '.env';
  static const _logTag = 'DpapiEnvService';

  /// Carrega o .env com proteção DPAPI.
  ///
  /// Retorna `true` se as variáveis foram carregadas com sucesso.
  static Future<bool> loadSecure() async {
    // Em ambiente de teste, apenas carrega o .env diretamente sem DPAPI.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _loadPlain();
    }

    // Só suporta DPAPI no Windows
    if (!Platform.isWindows) {
      return _loadPlain();
    }

    final exeDir = _executableDirectory();
    final encryptedFile = File('$exeDir/$_encryptedFileName');
    final plainFile = File('$exeDir/$_plainFileName');

    // ── Caminho 1: arquivo criptografado já existe ────────────────────────
    if (await encryptedFile.exists()) {
      return await _decryptAndLoad(encryptedFile);
    }

    // ── Caminho 2: arquivo em texto puro — criptografar e proteger ────────
    if (await plainFile.exists()) {
      return await _encryptAndLoad(plainFile, encryptedFile);
    }

    LogService.instance.warning(
      LogModule.app,
      '$_logTag | Nenhum arquivo .env ou .env.dpapi encontrado. '
      'Coloque o arquivo .env na pasta do executável.',
    );
    return false;
  }

  // ─── Criptografar o .env em texto puro e salvar como .env.dpapi ─────────

  static Future<bool> _encryptAndLoad(
    File plainFile,
    File encryptedFile,
  ) async {
    try {
      final content = await plainFile.readAsBytes();
      final encrypted = _dpApiEncrypt(content);

      if (encrypted == null) {
        LogService.instance.warning(
          LogModule.app,
          '$_logTag | Falha ao criptografar o .env com DPAPI. '
          'Carregando em texto puro como fallback.',
        );
        return _loadPlain();
      }

      await encryptedFile.writeAsBytes(encrypted);
      await plainFile.delete();

      LogService.instance.info(
        LogModule.app,
        '$_logTag | .env criptografado com DPAPI e arquivo original apagado. '
        'A partir de agora apenas .env.dpapi é usado nesta máquina.',
      );

      return _parseAndLoad(String.fromCharCodes(content));
    } catch (e) {
      LogService.instance.warning(
        LogModule.app,
        '$_logTag | Erro ao processar criptografia: $e',
      );
      return _loadPlain();
    }
  }

  // ─── Decriptografar o .env.dpapi e carregar em memória ──────────────────

  static Future<bool> _decryptAndLoad(File encryptedFile) async {
    try {
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decrypted = _dpApiDecrypt(encryptedBytes);

      if (decrypted == null) {
        LogService.instance.warning(
          LogModule.app,
          '$_logTag | Falha ao decriptografar .env.dpapi. '
          'O arquivo pode ter sido corrompido ou transferido de outra máquina.',
        );
        return false;
      }

      LogService.instance.info(
        LogModule.app,
        '$_logTag | Variáveis de ambiente carregadas via DPAPI com sucesso.',
      );

      return _parseAndLoad(String.fromCharCodes(decrypted));
    } catch (e) {
      LogService.instance.warning(
        LogModule.app,
        '$_logTag | Erro ao decriptografar .env.dpapi: $e',
      );
      return false;
    }
  }

  // ─── Fallback: carregar .env em texto puro (dev/teste) ──────────────────

  static Future<bool> _loadPlain() async {
    try {
      await dotenv.load(fileName: _plainFileName);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Parse manual do conteúdo do .env e injeção no dotenv ───────────────

  static bool _parseAndLoad(String content) {
    try {
      final Map<String, String> envMap = {};
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx < 0) continue;
        final key = trimmed.substring(0, eqIdx).trim();
        final value = trimmed.substring(eqIdx + 1).trim();
        if (key.isNotEmpty) envMap[key] = value;
      }
      dotenv.testLoad(mergeWith: envMap);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Diretório do executável ─────────────────────────────────────────────

  static String _executableDirectory() {
    try {
      return File(Platform.resolvedExecutable).parent.path;
    } catch (_) {
      return Directory.current.path;
    }
  }

  // ─── Win32 DPAPI: CryptProtectData ──────────────────────────────────────

  static Uint8List? _dpApiEncrypt(Uint8List plainData) {
    final crypt32 = DynamicLibrary.open('Crypt32.dll');
    final kernel32 = DynamicLibrary.open('Kernel32.dll');

    final cryptProtectData = crypt32.lookupFunction<
        CryptProtectDataNative, CryptProtectDataDart>('CryptProtectData');
    final localFree = kernel32
        .lookupFunction<LocalFreeNative, LocalFreeDart>('LocalFree');

    final pInput = calloc<DATA_BLOB>();
    final pOutput = calloc<DATA_BLOB>();

    try {
      final inputData = calloc<Uint8>(plainData.length);
      for (var i = 0; i < plainData.length; i++) {
        inputData[i] = plainData[i];
      }

      pInput.ref.cbData = plainData.length;
      pInput.ref.pbData = inputData;

      final result = cryptProtectData(
        pInput,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        0,
        pOutput,
      );

      if (result == 0) return null;

      final outData = pOutput.ref;
      final bytes =
          Uint8List.fromList(outData.pbData.asTypedList(outData.cbData));

      localFree(outData.pbData.cast());
      calloc.free(inputData);

      return bytes;
    } finally {
      calloc.free(pInput);
      calloc.free(pOutput);
    }
  }

  // ─── Win32 DPAPI: CryptUnprotectData ────────────────────────────────────

  static Uint8List? _dpApiDecrypt(Uint8List encryptedData) {
    final crypt32 = DynamicLibrary.open('Crypt32.dll');
    final kernel32 = DynamicLibrary.open('Kernel32.dll');

    final cryptUnprotectData = crypt32.lookupFunction<
        CryptUnprotectDataNative,
        CryptUnprotectDataDart>('CryptUnprotectData');
    final localFree = kernel32
        .lookupFunction<LocalFreeNative, LocalFreeDart>('LocalFree');

    final pInput = calloc<DATA_BLOB>();
    final pOutput = calloc<DATA_BLOB>();

    try {
      final inputData = calloc<Uint8>(encryptedData.length);
      for (var i = 0; i < encryptedData.length; i++) {
        inputData[i] = encryptedData[i];
      }

      pInput.ref.cbData = encryptedData.length;
      pInput.ref.pbData = inputData;

      final result = cryptUnprotectData(
        pInput,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        0,
        pOutput,
      );

      if (result == 0) return null;

      final outData = pOutput.ref;
      final bytes =
          Uint8List.fromList(outData.pbData.asTypedList(outData.cbData));

      localFree(outData.pbData.cast());
      calloc.free(inputData);

      return bytes;
    } finally {
      calloc.free(pInput);
      calloc.free(pOutput);
    }
  }
}
