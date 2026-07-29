import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInN1YiI6ImJkN2YyYzcwLTVmMTAtNDg1OS1hZTc5LTc1M2I1OGVhM2E3OSIsImF1ZCI6ImF1dGhlbnRpY2F0ZWQiLCJleHAiOjE3ODUwNzQ4MzQsImlhdCI6MTc4NTA3MTIzNCwiZW1haWwiOiJkZXZAZmluY29yZS5jb20iLCJwaG9uZSI6IiIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIiwicHJvdmlkZXJzIjpbImVtYWlsIl19LCJ1c2VyX21ldGFkYXRhIjp7ImVtYWlsIjoiZGV2QGZpbmNvcmUuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWwiOiJlbGkiLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInN1YiI6ImJkN2YyYzcwLTVmMTAtNDg1OS1hZTc5LTc1M2I1OGVhM2E3OSJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzg1MDcxMjM0fV0sInNlc3Npb25faWQiOiIzMDM1MGNmMi05Njc4LTRkMjItYmZmZS0wMGRiNzllNWFiNDciLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.FP-fGrQrVzH0MknOyKWs3gWoTmqVitmNEyf1HUrW32KSAhJwOY9TR9GqCHgZ2dZpfhoE1PiYr6ygH8CTNnODZw';
  final secretB64 = '7y9IvWpX04q7xcVGpYPW+2l0SDhnN37AZdb9Axz3rQz4YF/gaPwU3E0GNYmAwGzvjMZkg2xCZOkBnkAqMVh92Q==';
  
  final parts = token.split('.');
  final headerAndPayload = parts[0] + '.' + parts[1];
  final signature = parts[2];

  print('Signature length: ${signature.length}');

  // Try decoding secret as base64, then utf8, then try HS256, HS384, HS512
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
        print('MATCH FOUND!');
        print('Algorithm used: $hName');
        print('Secret type: $sName');
        return;
      }
    }
  }

  print('No match found.');
}
