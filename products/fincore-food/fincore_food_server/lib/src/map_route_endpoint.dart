import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';

class MapRouteEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// Calcula a distância (metros) e duração (segundos) de deslocamento
  /// entre a origem (empresa) e o destino (entrega do cliente).
  ///
  /// Utiliza cache persistente no banco PostgreSQL (Supabase) via queries diretas.
  Future<MapRouteResult> calculateRoute(Session session, String origin, String destination) async {
    final origKey = origin.trim().toLowerCase();
    final destKey = destination.trim().toLowerCase();

    if (origKey.isEmpty || destKey.isEmpty) {
      return MapRouteResult(
        distanciaMetros: 0,
        tempoDeslocamentoSegundos: 0,
        status: 'error',
        mensagem: 'Origem ou destino não informados.',
      );
    }

    try {
      // 1. Garantir que a tabela de cache exista no banco Postgres
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS route_cache (
          origin TEXT,
          destination TEXT,
          distance_meters INTEGER,
          duration_seconds INTEGER,
          updated_at TIMESTAMP,
          PRIMARY KEY (origin, destination)
        )
      ''');

      // 2. Tentar ler do cache
      final cachedRows = await session.db.unsafeQuery(
        'SELECT distance_meters, duration_seconds FROM route_cache WHERE origin = \$1 AND destination = \$2',
        parameters: QueryParametersPositional([origKey, destKey]),
      );

      if (cachedRows.isNotEmpty) {
        final row = cachedRows.first.toColumnMap();
        final distance = row['distance_meters'] as int? ?? 5000;
        final duration = row['duration_seconds'] as int? ?? 900;
        
        session.log('Route Cache Hit: "$origKey" -> "$destKey" | Distance: ${distance}m, Duration: ${duration}s');
        
        return MapRouteResult(
          distanciaMetros: distance,
          tempoDeslocamentoSegundos: duration,
          status: 'success',
          mensagem: 'Recuperado do cache',
        );
      }

      // Fast path: CEPs e endereços idênticos ou no mesmo CEP
      final cleanOrigCep = _extractCep(origin);
      final cleanDestCep = _extractCep(destination);
      
      if (cleanOrigCep == cleanDestCep && cleanOrigCep.isNotEmpty) {
        final origNum = _extractNumber(origin);
        final destNum = _extractNumber(destination);
        final origStreet = _extractStreet(origin);
        final destStreet = _extractStreet(destination);
        
        if (origStreet == destStreet) {
          if (origNum == destNum) {
            session.log('Fast path: Endereço idêntico');
            return MapRouteResult(
              distanciaMetros: 0,
              tempoDeslocamentoSegundos: 0,
              status: 'success',
              mensagem: 'Mesmo endereço',
            );
          } else {
            final diff = (origNum - destNum).abs();
            final distance = diff * 5; // Aprox 5 metros por número
            final duration = (distance / 8.3).round(); // Aprox 30km/h (8.3 m/s)
            session.log('Fast path: Mesma rua, números diferentes ($diff)');
            
            // Salvar no cache
            await _saveToCache(session, origKey, destKey, distance, duration);
            
            return MapRouteResult(
              distanciaMetros: distance < 50 ? 50 : distance,
              tempoDeslocamentoSegundos: duration < 10 ? 10 : duration,
              status: 'success',
              mensagem: 'Mesma rua',
            );
          }
        } else {
          session.log('Fast path: Ruas diferentes no mesmo CEP');
          final distance = 400;
          final duration = 90;
          
          await _saveToCache(session, origKey, destKey, distance, duration);
          
          return MapRouteResult(
            distanciaMetros: distance,
            tempoDeslocamentoSegundos: duration,
            status: 'success',
            mensagem: 'Mesmo CEP, ruas diferentes',
          );
        }
      }

      // 3. Cache Miss: Calcular via geolocalização e OSRM
      int distance = 5000; // 5 km padrão
      int duration = 900;  // 15 min padrão
      String status = 'fallback';
      String? msg = 'API de rotas indisponível, usando estimativa padrão.';

      try {
        session.log('Geocodificando origem e destino...');
        final locOrig = await _geocode(session, origin);
        final locDest = await _geocode(session, destination);

        if (locOrig != null && locDest != null) {
          if (locOrig.lat == locDest.lat && locOrig.lon == locDest.lon) {
            final origNum = _extractNumber(origin);
            final destNum = _extractNumber(destination);
            if (origNum > 0 && destNum > 0 && origNum != destNum) {
              final diff = (origNum - destNum).abs();
              distance = (diff * 8).clamp(50, 1500);
              duration = (distance / 8.33).round();
              status = 'success';
              msg = 'Mesma rua/CEP, números diferentes ($diff números de diferença).';
            } else {
              distance = 100;
              duration = 30;
              status = 'success';
              msg = 'Endereço/CEP idêntico.';
            }
          } else {
            session.log('Calculando rota OSRM entre: ${locOrig.lat},${locOrig.lon} e ${locDest.lat},${locDest.lon}');
            final route = await _calculateOsrmRoute(session, locOrig.lat, locOrig.lon, locDest.lat, locDest.lon);
            if (route != null && route.distanceMeters > 0) {
              distance = route.distanceMeters;
              duration = route.durationSeconds;
              status = 'success';
              msg = 'Calculado com sucesso via OSRM';
            } else {
              final havMeters = _calculateHaversineMeters(locOrig.lat, locOrig.lon, locDest.lat, locDest.lon);
              distance = havMeters < 50 ? 50 : havMeters;
              duration = (distance / 8.33).round();
              status = 'success';
              msg = 'Calculado via Haversine urbano.';
            }
          }
        }
      } catch (apiError) {
        session.log('Erro na API de mapas: $apiError', level: LogLevel.warning);
      }

      // Salvar no cache persistente apenas se o cálculo foi bem-sucedido
      if (status == 'success') {
        await _saveToCache(session, origKey, destKey, distance, duration);
      }

      return MapRouteResult(
        distanciaMetros: distance,
        tempoDeslocamentoSegundos: duration,
        status: status,
        mensagem: msg,
      );

    } catch (e) {
      session.log('Erro crítico na rota: $e', level: LogLevel.error);
      return MapRouteResult(
        distanciaMetros: 5000,
        tempoDeslocamentoSegundos: 900,
        status: 'error',
        mensagem: 'Erro ao calcular rota: $e. Usando fallback de 15 min.',
      );
    }
  }

  int _extractNumber(String address) {
    final reg = RegExp(r'\b\d+\b');
    final match = reg.firstMatch(address);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  String _extractStreet(String address) {
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim().toLowerCase();
    }
    return address.trim().toLowerCase();
  }

  String _extractCep(String address) {
    final cepMatch = RegExp(r'\b\d{2}\.?\d{3}-?\d{3}\b').firstMatch(address);
    if (cepMatch != null) {
      return cepMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
    }
    final digitsMatch = RegExp(r'\b\d{8}\b').firstMatch(address);
    if (digitsMatch != null) {
      return digitsMatch.group(0)!;
    }
    return '';
  }

  int _calculateHaversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final straightMeters = (R * c).round();
    return (straightMeters * 1.35).round();
  }

  Future<void> _saveToCache(Session session, String origin, String destination, int distance, int duration) async {
    try {
      await session.db.unsafeExecute('''
        INSERT INTO route_cache (origin, destination, distance_meters, duration_seconds, updated_at)
        VALUES (\$1, \$2, \$3, \$4, NOW())
        ON CONFLICT (origin, destination) 
        DO UPDATE SET distance_meters = EXCLUDED.distance_meters, 
                      duration_seconds = EXCLUDED.duration_seconds, 
                      updated_at = EXCLUDED.updated_at
      ''', parameters: QueryParametersPositional([origin, destination, distance, duration]));
    } catch (e) {
      session.log('Erro ao salvar cache de rota: $e', level: LogLevel.warning);
    }
  }

  Future<({double lat, double lon})?> _geocodeQuery(Session session, String query, {bool requirePostcode = false}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1';
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'FincoreFoodApp/1.0 (contact: eliezerssouz@gmail.com)');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as List<dynamic>;
        if (json.isNotEmpty) {
          final first = json.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          
          if (requirePostcode) {
            final addresstype = first['addresstype']?.toString() ?? '';
            final type = first['type']?.toString() ?? '';
            if (addresstype != 'postcode' && type != 'postcode') {
              session.log('Nominatim: query "$query" retornou tipo $type/$addresstype, esperado postcode. Ignorando.');
              return null;
            }
          }
          
          if (lat != null && lon != null) {
            return (lat: lat, lon: lon);
          }
        }
      }
    } catch (e) {
      session.log('Erro ao consultar Nominatim para "$query": $e', level: LogLevel.warning);
    } finally {
      client.close();
    }
    return null;
  }

  Future<({double lat, double lon})?> _geocode(Session session, String address) async {
    final cep = _extractCep(address);

    // 1. Tentar BrasilAPI v2 (Retorna lat/lon oficiais do CEP)
    if (cep.length == 8) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      try {
        final req = await client.getUrl(Uri.parse('https://brasilapi.com.br/api/cep/v2/$cep'));
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
                session.log('Geocode BrasilAPI SUCESSO: $cep -> ($lat, $lon)');
                return (lat: lat, lon: lon);
              }
            }
          }
        }
      } catch (e) {
        session.log('BrasilAPI erro: $e', level: LogLevel.debug);
      } finally {
        client.close();
      }

      // 2. Tentar AwesomeAPI CEP
      final clientAwesome = HttpClient();
      clientAwesome.connectionTimeout = const Duration(seconds: 3);
      try {
        final req = await clientAwesome.getUrl(Uri.parse('https://cep.awesomeapi.com.br/json/$cep'));
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          final lat = double.tryParse(json['lat']?.toString() ?? '');
          final lon = double.tryParse(json['lng']?.toString() ?? '');
          if (lat != null && lon != null && (lat != 0 || lon != 0)) {
            session.log('Geocode AwesomeAPI SUCESSO: $cep -> ($lat, $lon)');
            return (lat: lat, lon: lon);
          }
        }
      } catch (e) {
        session.log('AwesomeAPI erro: $e', level: LogLevel.debug);
      } finally {
        clientAwesome.close();
      }
    }

    // 3. Tentar ViaCEP para obter logradouro e cidade
    String logradouro = '';
    String cidade = '';
    String uf = '';

    if (cep.length == 8) {
      final clientVia = HttpClient();
      clientVia.connectionTimeout = const Duration(seconds: 3);
      try {
        final req = await clientVia.getUrl(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          if (json['erro'] != 'true') {
            logradouro = json['logradouro']?.toString() ?? '';
            cidade = json['localidade']?.toString() ?? '';
            uf = json['uf']?.toString() ?? '';
          }
        }
      } catch (_) {
      } finally {
        clientVia.close();
      }
    }

    final numStr = _extractNumber(address);
    final numParam = numStr > 0 ? '$numStr' : '';

    if (logradouro.isNotEmpty && cidade.isNotEmpty) {
      final queryStr = numParam.isNotEmpty
          ? '$logradouro, $numParam, $cidade, $uf, Brasil'
          : '$logradouro, $cidade, $uf, Brasil';
      session.log('Nominatim via ViaCEP: "$queryStr"');
      final resultVia = await _geocodeQuery(session, queryStr);
      if (resultVia != null) return resultVia;
    }

    // 4. Se não conseguiu ViaCEP + Nominatim, tentar componentes originais
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.isNotEmpty) {
      final street = parts[0];
      if (street.isNotEmpty) {
        final queryStr = numParam.isNotEmpty
            ? '$street, $numParam, Brasil'
            : '$street, Brasil';
        session.log('Nominatim componentes: "$queryStr"');
        final resultAddr = await _geocodeQuery(session, queryStr);
        if (resultAddr != null) return resultAddr;
      }
    }

    // 5. Fallback final: string cheia
    session.log('Nominatim fallback endereço completo "$address"');
    final resultFull = await _geocodeQuery(session, address);
    if (resultFull != null) return resultFull;

    session.log('Geocodificação falhou completamente para "$address"', level: LogLevel.warning);
    return null;
  }

  Future<({int distanceMeters, int durationSeconds})?> _calculateOsrmRoute(
      Session session, double lat1, double lon1, double lat2, double lon2) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/$lon1,$lat1;$lon2,$lat2?overview=false';
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'FincoreFoodApp/1.0 (contact: support@fincore.com)');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final routes = json['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final distance = (firstRoute['distance'] as num?)?.round();
          final duration = (firstRoute['duration'] as num?)?.round();
          if (distance != null && duration != null) {
            return (distanceMeters: distance, durationSeconds: duration);
          }
        }
      }
    } catch (e) {
      session.log('Erro ao calcular rota OSRM: $e', level: LogLevel.warning);
    } finally {
      client.close();
    }
    return null;
  }
}
