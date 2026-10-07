import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EnderecoCep {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;
  final String? ibge;
  final bool valido;

  const EnderecoCep({
    required this.cep,
    required this.logradouro,
    this.complemento = '',
    required this.bairro,
    required this.localidade,
    required this.uf,
    this.ibge,
    this.valido = true,
  });

  String get cidade => localidade;

  factory EnderecoCep.vazio() => const EnderecoCep(
        cep: '',
        logradouro: '',
        bairro: '',
        localidade: '',
        uf: '',
        valido: false,
      );
}

class CepService {
  /// Consulta endereço no ViaCEP com fallback BrasilAPI e sanitização de caracteres
  static Future<EnderecoCep?> consultarCep(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return null;

    // 1. Tenta ViaCEP
    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['erro'] != true && data['erro'] != 'true') {
          return EnderecoCep(
            cep: cleanCep,
            logradouro: (data['logradouro'] as String?)?.trim() ?? '',
            complemento: (data['complemento'] as String?)?.trim() ?? '',
            bairro: (data['bairro'] as String?)?.trim() ?? '',
            localidade: (data['localidade'] as String?)?.trim() ?? '',
            uf: (data['uf'] as String?)?.trim().toUpperCase() ?? '',
            ibge: data['ibge'] as String?,
            valido: true,
          );
        }
      }
    } catch (e) {
      debugPrint('[CepService] ViaCEP falhou ($e), tentando BrasilAPI...');
    }

    // 2. Fallback BrasilAPI
    try {
      final uriBrasil = Uri.parse('https://brasilapi.com.br/api/cep/v2/$cleanCep');
      final respBrasil = await http.get(uriBrasil).timeout(const Duration(seconds: 4));

      if (respBrasil.statusCode == 200) {
        final data = jsonDecode(utf8.decode(respBrasil.bodyBytes));
        return EnderecoCep(
          cep: cleanCep,
          logradouro: (data['street'] as String?)?.trim() ?? '',
          complemento: '',
          bairro: (data['neighborhood'] as String?)?.trim() ?? '',
          localidade: (data['city'] as String?)?.trim() ?? '',
          uf: (data['state'] as String?)?.trim().toUpperCase() ?? '',
          valido: true,
        );
      }
    } catch (e) {
      debugPrint('[CepService] BrasilAPI falhou ($e)');
    }

    return null;
  }
}
