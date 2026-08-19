import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

// ─── Script de teste local para verificar algoritmo de assinatura JWT ────────
// ⚠️  SEGURANÇA: Nunca commitar secrets neste arquivo.
// Configure a variável de ambiente SUPABASE_JWT_SECRET antes de executar.
// Uso: SUPABASE_JWT_SECRET=seu_secret dart run bin/test_jwt.dart
// ─────────────────────────────────────────────────────────────────────────────

void main(List<String> args) {
  // Token JWT de exemplo para teste (já expirado — apenas para validar o algoritmo)
  final token = args.isNotEmpty
      ? args[0]
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.<payload>.<signature>';

  // ⚠️  SEGURANÇA: Secret lido exclusivamente de variável de ambiente
  final secretB64 = Platform.environment['SUPABASE_JWT_SECRET'];
  if (secretB64 == null || secretB64.isEmpty) {
    print('[ERRO] Configure a variável de ambiente SUPABASE_JWT_SECRET antes de executar este script.');
    print('PowerShell: \$env:SUPABASE_JWT_SECRET = "seu_secret_aqui"');
    exit(1);
  }
  
  final parts = token.split('.');
  if (parts.length != 3) {
    print('[ERRO] Token JWT inválido. Forneça um token completo com 3 partes.');
    exit(1);
  }

  final headerAndPayload = parts[0] + '.' + parts[1];
  final signature = parts[2];

  print('Signature length: ${signature.length}');

  // Testa decodificação do secret como utf8 e base64, com algoritmos HS256/384/512
  final secretBytesOptions = {
    'utf8(secret)': utf8.encode(secretB64),
    'base64Decode(secret)': base64Decode(secretB64),
  };

  final hashOptions = {
    'HS256': sha256,
    'HS384': sha384,
    'HS512': sha512,
  };

  for (final sName in secretBytesOptions.keys) {
    final sBytes = secretBytesOptions[sName]!;
    for (final hName in hashOptions.keys) {
      final hAlgo = hashOptions[hName]!;
      
      final hmac = Hmac(hAlgo, sBytes);
      final digest = hmac.convert(utf8.encode(headerAndPayload));
      final calc = base64UrlEncode(digest.bytes).replaceAll('=', '');
      
      if (calc == signature) {
        print('MATCH ENCONTRADO!');
        print('Algoritmo: $hName');
        print('Tipo de secret: $sName');
        return;
      }
    }
  }

  print('Nenhuma combinação de algoritmo/secret produziu a assinatura esperada.');
}

