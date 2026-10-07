import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/core_models.dart';

class CalculoTaxaResult {
  final int taxaCentavos;
  final String descricaoRegra;
  final double? distanciaKm;
  final bool isGratis;

  const CalculoTaxaResult({
    required this.taxaCentavos,
    required this.descricaoRegra,
    this.distanciaKm,
    this.isGratis = false,
  });
}

class DeliveryFeeService {
  static final Map<String, ({double lat, double lon})> _geoCache = {};

  /// Estima a distância em KM entre a empresa e o cliente utilizando geocodificação e malha viária real
  static Future<double?> estimarDistanciaKm({
    required CoreEmpresa empresa,
    String? clienteCep,
    String? clienteLogradouro,
    String? clienteNumero,
    String? clienteBairro,
    String? clienteCidade,
  }) async {
    try {
      // 1. Coordenadas da Loja (Origem)
      final origemCoords = await _obterCoordenadasLoja(empresa);
      if (origemCoords == null) {
        debugPrint('[DeliveryFeeService] Não foi possível obter coordenadas da loja.');
        return null;
      }

      // 2. Coordenadas do Cliente (Destino) - Prioriza Nominatim estruturado idêntico ao Web
      final destinoCoords = await _obterCoordenadasCliente(
        cep: clienteCep,
        logradouro: clienteLogradouro,
        numero: clienteNumero,
        bairro: clienteBairro,
        cidadePadrao: clienteCidade ?? empresa.cidade ?? 'Pouso Alegre',
        estadoPadrao: empresa.estado ?? 'MG',
      );

      if (destinoCoords == null) {
        debugPrint('[DeliveryFeeService] Não foi possível geocodificar o destino do cliente.');
        return null;
      }

      // Se mesma coordenada (loja e cliente idênticos)
      if (origemCoords.lat == destinoCoords.lat && origemCoords.lon == destinoCoords.lon) {
        return 0.1;
      }

      // 3. Tentar rota viária real via OSRM (com HTTPS e User-Agent)
      final osrmKm = await _calcularDistanciaOsrm(
        origemCoords.lat,
        origemCoords.lon,
        destinoCoords.lat,
        destinoCoords.lon,
      );

      if (osrmKm != null && osrmKm > 0) {
        return double.parse(osrmKm.toStringAsFixed(1));
      }

      // 4. Fallback imediato: Haversine viário (fator 1.30 de malha urbana brasileira)
      final havKm = calcularDistanciaHaversineKm(
        origemCoords.lat,
        origemCoords.lon,
        destinoCoords.lat,
        destinoCoords.lon,
      );

      return double.parse(havKm.toStringAsFixed(1));
    } catch (e) {
      debugPrint('[DeliveryFeeService] Erro ao estimar distância: $e');
      return null;
    }
  }

  static Future<({double lat, double lon})?> _obterCoordenadasLoja(CoreEmpresa empresa) async {
    const key = '__loja__';
    if (_geoCache.containsKey(key)) return _geoCache[key];

    final rua = empresa.logradouro ?? '';
    final bairro = empresa.bairro ?? '';
    final cidade = empresa.cidade ?? 'Pouso Alegre';
    final estado = empresa.estado ?? 'MG';

    // Matriz conhecida em Pouso Alegre (Francisca Augusta Rios / Nadia Prancic)
    if (bairro.toLowerCase().contains('francisca augusta') || rua.toLowerCase().contains('nadia prancic')) {
      const coords = (lat: -22.2592283, lon: -45.9260035);
      _geoCache[key] = coords;
      return coords;
    }

    // Cascata idêntica ao Web
    final attempts = [
      if (rua.isNotEmpty && (empresa.numero ?? '').isNotEmpty)
        '$rua, ${empresa.numero} - $bairro, $cidade - $estado, Brasil',
      if (rua.isNotEmpty && bairro.isNotEmpty)
        '$rua, $bairro, $cidade - $estado, Brasil',
      if (bairro.isNotEmpty)
        '$bairro, $cidade - $estado, Brasil',
      '$cidade - $estado, Brasil',
    ];

    for (final query in attempts) {
      final coords = await _geocodeNominatim(query);
      if (coords != null) {
        _geoCache[key] = coords;
        return coords;
      }
    }

    // Fallback padrão se nada responder
    const fallbackCoords = (lat: -22.2592283, lon: -45.9260035);
    _geoCache[key] = fallbackCoords;
    return fallbackCoords;
  }

  static Future<({double lat, double lon})?> _obterCoordenadasCliente({
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    required String cidadePadrao,
    String estadoPadrao = 'MG',
  }) async {
    final cleanCep = cep?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final logr = logradouro?.trim() ?? '';
    final num = numero?.trim() ?? '';
    final bair = bairro?.trim() ?? '';
    final cid = cidadePadrao.trim().isNotEmpty ? cidadePadrao.trim() : 'Pouso Alegre';
    final uf = estadoPadrao.trim().isNotEmpty ? estadoPadrao.trim() : 'MG';

    // 1. Tentar por Endereço Estruturado via Nominatim (prioridade idêntica ao Cardápio Web em app.js)
    final queries = <String>[];
    if (logr.isNotEmpty && num.isNotEmpty) {
      queries.add('$logr, $num - $bair, $cid - $uf, Brasil');
    }
    if (logr.isNotEmpty && bair.isNotEmpty) {
      queries.add('$logr, $bair, $cid - $uf, Brasil');
    }
    if (logr.isNotEmpty) {
      queries.add('$logr, $cid - $uf, Brasil');
    }
    if (bair.isNotEmpty && cid.isNotEmpty) {
      queries.add('$bair, $cid - $uf, Brasil');
    }
    if (cleanCep.length == 8) {
      queries.add('$cleanCep, Brasil');
    }
    if (cid.isNotEmpty && uf.isNotEmpty) {
      queries.add('$cid - $uf, Brasil');
    }

    for (final q in queries) {
      final coords = await _geocodeNominatim(q);
      if (coords != null) return coords;
    }

    // 2. Fallbacks secundários de CEP caso o Nominatim não retorne coordenadas
    if (cleanCep.length == 8) {
      if (_geoCache.containsKey(cleanCep)) return _geoCache[cleanCep];

      // AwesomeAPI
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final req = await client.getUrl(Uri.parse('https://cep.awesomeapi.com.br/json/$cleanCep'));
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          final lat = double.tryParse(json['lat']?.toString() ?? '');
          final lon = double.tryParse(json['lng']?.toString() ?? '');
          if (lat != null && lon != null && (lat != 0 || lon != 0)) {
            final result = (lat: lat, lon: lon);
            _geoCache[cleanCep] = result;
            return result;
          }
        }
      } catch (_) {}

      // BrasilAPI v2 (como último recurso)
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final req = await client.getUrl(Uri.parse('https://brasilapi.com.br/api/cep/v2/$cleanCep'));
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          final location = json['location'] as Map<String, dynamic>?;
          if (location != null) {
            final coords = location['coordinates'] as Map<String, dynamic>?;
            if (coords != null) {
              final lat = double.tryParse(coords['latitude']?.toString() ?? '');
              final lon = double.tryParse(coords['longitude']?.toString() ?? '');
              if (lat != null && lon != null && (lat != 0 || lon != 0)) {
                final result = (lat: lat, lon: lon);
                _geoCache[cleanCep] = result;
                return result;
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<({double lat, double lon})?> _geocodeNominatim(String query) async {
    final cacheKey = query.toLowerCase().trim();
    if (_geoCache.containsKey(cacheKey)) return _geoCache[cacheKey];

    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 3500);
      final encoded = Uri.encodeComponent(query);
      final req = await client.getUrl(Uri.parse('https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1&countrycodes=br'));
      req.followRedirects = true;
      req.headers.set(HttpHeaders.userAgentHeader, 'FinCoreFoodCardapio/2.0');
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'pt-BR');
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            final coords = (lat: lat, lon: lon);
            _geoCache[cacheKey] = coords;
            return coords;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<double?> _calcularDistanciaOsrm(double lat1, double lon1, double lat2, double lon2) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 3000);
      final url = 'https://router.project-osrm.org/route/v1/driving/$lon1,$lat1;$lon2,$lat2?overview=false';
      final req = await client.getUrl(Uri.parse(url));
      req.followRedirects = true;
      req.headers.set(HttpHeaders.userAgentHeader, 'FinCoreFoodCardapio/2.0');
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final routes = json['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final first = routes.first as Map<String, dynamic>;
          final distanceMeters = (first['distance'] as num?)?.toDouble();
          if (distanceMeters != null && distanceMeters > 0) {
            return distanceMeters / 1000.0;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Calcula a taxa de entrega aplicando as regras com hierarquia comercial precisa:
  /// 1. Bairro cadastrado (Região específica de entrega)
  /// 2. CEP cadastrado (faixa de CEP inicial e final)
  /// 3. Faixas de KM (se distanciaKm informada)
  /// 4. Taxa Fixa / Fallback configurado
  static CalculoTaxaResult calcular({
    required List<TaxaEntrega> taxas,
    double? distanciaKm,
    String? bairro,
    String? cep,
    int? fallbackCentavos,
    int? subtotalCentavos,
  }) {
    // 1. Regra por Bairro (Específica da Região cadastrada)
    if (bairro != null && bairro.trim().isNotEmpty) {
      final cleanBairro = bairro.trim().toLowerCase();
      final regrasBairro = taxas.where((t) => t.ativo && t.tipoRegra == TipoRegraTaxaEntrega.bairro && t.bairro != null).toList();

      TaxaEntrega? matched = regrasBairro.where((t) => t.bairro!.trim().toLowerCase() == cleanBairro).firstOrNull;
      matched ??= regrasBairro.where((t) {
        final b = t.bairro!.trim().toLowerCase();
        return b.contains(cleanBairro) || cleanBairro.contains(b);
      }).firstOrNull;

      if (matched != null) {
        final minGratis = matched.pedidoMinimoCentavos;
        final isFreeByOrder = (minGratis > 0 && subtotalCentavos != null && subtotalCentavos >= minGratis);
        final valorFinal = isFreeByOrder ? 0 : matched.valorCentavos;

        return CalculoTaxaResult(
          taxaCentavos: valorFinal,
          descricaoRegra: isFreeByOrder
              ? 'Grátis (Pedido acima de R\$ ${(minGratis / 100).toStringAsFixed(2)})'
              : 'Bairro: ${matched.bairro ?? bairro}',
          distanciaKm: distanciaKm,
          isGratis: valorFinal == 0,
        );
      }
    }

    // 2. Regra por CEP
    if (cep != null && cep.trim().isNotEmpty) {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanCep.length == 8) {
        for (final r in taxas.where((t) => t.ativo && t.tipoRegra == TipoRegraTaxaEntrega.cep && t.cepInicial != null && t.cepFinal != null)) {
          final ini = r.cepInicial!.replaceAll(RegExp(r'[^0-9]'), '');
          final fim = r.cepFinal!.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanCep.compareTo(ini) >= 0 && cleanCep.compareTo(fim) <= 0) {
            final minGratis = r.pedidoMinimoCentavos;
            final isFreeByOrder = (minGratis > 0 && subtotalCentavos != null && subtotalCentavos >= minGratis);
            final valorFinal = isFreeByOrder ? 0 : r.valorCentavos;

            return CalculoTaxaResult(
              taxaCentavos: valorFinal,
              descricaoRegra: isFreeByOrder
                  ? 'Grátis (Pedido acima de R\$ ${(minGratis / 100).toStringAsFixed(2)})'
                  : 'Faixa CEP: ${r.cepInicial} a ${r.cepFinal}',
              distanciaKm: distanciaKm,
              isGratis: valorFinal == 0,
            );
          }
        }
      }
    }

    // 3. Regras por KM (quando não há taxa específica de Bairro ou CEP)
    final regrasKm = taxas
        .where((t) => t.ativo && t.tipoRegra == TipoRegraTaxaEntrega.km && t.distanciaMaxKm != null)
        .toList();

    if (distanciaKm != null && regrasKm.isNotEmpty) {
      regrasKm.sort((a, b) => (a.distanciaMinKm ?? 0.0).compareTo(b.distanciaMinKm ?? 0.0));

      // Busca na faixa exata
      for (final r in regrasKm) {
        final min = r.distanciaMinKm ?? 0.0;
        final max = r.distanciaMaxKm!;
        if (distanciaKm >= min && distanciaKm <= max) {
          final minGratis = r.pedidoMinimoCentavos;
          final isFreeByOrder = (minGratis > 0 && subtotalCentavos != null && subtotalCentavos >= minGratis);
          final valorFinal = isFreeByOrder ? 0 : r.valorCentavos;

          return CalculoTaxaResult(
            taxaCentavos: valorFinal,
            descricaoRegra: isFreeByOrder
                ? 'Grátis (Pedido acima de R\$ ${(minGratis / 100).toStringAsFixed(2)})'
                : 'Faixa KM: ${min.toStringAsFixed(1)} a ${max.toStringAsFixed(1)} km',
            distanciaKm: distanciaKm,
            isGratis: valorFinal == 0,
          );
        }
      }

      // Se a distância for menor que o início da primeira faixa cadastrada
      final primeiraFaixa = regrasKm.first;
      final minPrimeira = primeiraFaixa.distanciaMinKm ?? 0.0;
      if (distanciaKm < minPrimeira) {
        return CalculoTaxaResult(
          taxaCentavos: 0,
          descricaoRegra: 'Raio de cortesia (< ${minPrimeira.toStringAsFixed(1)} km)',
          distanciaKm: distanciaKm,
          isGratis: true,
        );
      }

      // Se a distância for maior que a última faixa cadastrada
      final ultimaFaixa = regrasKm.last;
      final maxUltima = ultimaFaixa.distanciaMaxKm!;
      if (distanciaKm > maxUltima) {
        final minGratis = ultimaFaixa.pedidoMinimoCentavos;
        final isFreeByOrder = (minGratis > 0 && subtotalCentavos != null && subtotalCentavos >= minGratis);
        final valorFinal = isFreeByOrder ? 0 : ultimaFaixa.valorCentavos;

        return CalculoTaxaResult(
          taxaCentavos: valorFinal,
          descricaoRegra: isFreeByOrder
              ? 'Grátis (Pedido acima de R\$ ${(minGratis / 100).toStringAsFixed(2)})'
              : 'Acima de ${maxUltima.toStringAsFixed(1)} km',
          distanciaKm: distanciaKm,
          isGratis: valorFinal == 0,
        );
      }
    }

    // 4. Taxa Fixa ou Fallback
    final regraFixa = taxas.where((t) => t.ativo && t.tipoRegra == TipoRegraTaxaEntrega.fixo).firstOrNull;
    if (regraFixa != null && regraFixa.valorCentavos > 0) {
      return CalculoTaxaResult(
        taxaCentavos: regraFixa.valorCentavos,
        descricaoRegra: 'Taxa Fixa Padrão',
        distanciaKm: distanciaKm,
        isGratis: false,
      );
    }

    final fallback = fallbackCentavos ?? 0;
    return CalculoTaxaResult(
      taxaCentavos: fallback,
      descricaoRegra: fallback > 0 ? 'Taxa Base Padrão' : 'Sem taxa configurada',
      distanciaKm: distanciaKm,
      isGratis: fallback == 0,
    );
  }

  /// Distância Haversine urbana em Km (com fator 1.30 de malha viária)
  static double calcularDistanciaHaversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c) * 1.30;
  }
}
