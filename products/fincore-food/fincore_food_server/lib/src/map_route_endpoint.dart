import 'dart:io';
import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';

class MapRouteEndpoint extends Endpoint {
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
      final cleanOrigCep = origin.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanDestCep = destination.replaceAll(RegExp(r'[^0-9]'), '');
      
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
            // Se as coordenadas geocodificadas forem idênticas mas os endereços originais
            // forem textualmente diferentes, significa que o Nominatim falhou em discriminar as ruas
            // e retornou o mesmo centro da cidade. Usamos o fallback de 5 km para evitar retornar 0 km.
            session.log('Nominatim: Ambos os endereços geocodificados são idênticos. Usando fallback de 5 km.');
            distance = 5000;
            duration = 900;
            status = 'fallback';
            msg = 'Coordenadas idênticas no centróide da cidade. Usando fallback de 5 km.';
          } else {
            session.log('Calculando rota OSRM entre: ${locOrig.lat},${locOrig.lon} e ${locDest.lat},${locDest.lon}');
            final route = await _calculateOsrmRoute(session, locOrig.lat, locOrig.lon, locDest.lat, locDest.lon);
            if (route != null) {
              distance = route.distanceMeters;
              duration = route.durationSeconds;
              status = 'success';
              msg = 'Calculado com sucesso via OSRM';
            }
          }
        }
      } catch (apiError) {
        session.log('Erro na API de mapas: $apiError', level: LogLevel.warning);
      }

      // Salvar no cache persistente para evitar novas consultas
      await _saveToCache(session, origKey, destKey, distance, duration);

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
    // 1. Tentar extrair CEP para busca direta (limpando e formatando como #####-###, Brasil)
    final cepMatch = RegExp(r'\b\d{2}\.?\d{3}-?\d{3}\b').firstMatch(address);
    if (cepMatch != null) {
      final digits = cepMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 8) {
        final cepFormatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
        session.log('Nominatim: tentando por CEP "$cepFormatted, Brasil"');
        final resultCep = await _geocodeQuery(session, '$cepFormatted, Brasil', requirePostcode: true);
        if (resultCep != null) return resultCep;
      }
    }

    // 2. Tentar por componentes estruturados (Rua, Número, Cidade)
    final parts = address.split(',').map((s) => s.trim()).toList();
    String city = '';
    String numStr = '';
    if (parts.isNotEmpty) {
      final street = parts[0];

      // Tenta achar o número do imóvel (segundo elemento se contiver dígitos ou for curto)
      if (parts.length > 1) {
        final second = parts[1];
        if (RegExp(r'\d').hasMatch(second) || second.length < 6) {
          numStr = second.split('-').first.trim();
        }
      }

      // Varre de trás para frente para identificar a cidade (ignorando CEP e UF)
      for (int i = parts.length - 1; i >= 0; i--) {
        final p = parts[i];
        if (RegExp(r'^\d{2}\.?\d{3}-?\d{3}$').hasMatch(p) || RegExp(r'^\d{8}$').hasMatch(p)) {
          continue; // Pula CEPs
        }
        if (RegExp(r'^[A-Z]{2}$').hasMatch(p)) {
          continue; // Pula UFs
        }
        if (i > 1 || (i == 1 && numStr.isEmpty)) {
          city = p;
          break;
        }
      }

      if (street.isNotEmpty && city.isNotEmpty) {
        final queryStr = numStr.isNotEmpty
            ? '$street, $numStr, $city, Brasil'
            : '$street, $city, Brasil';
        session.log('Nominatim: tentando por componentes "$queryStr"');
        final resultAddr = await _geocodeQuery(session, queryStr);
        if (resultAddr != null) return resultAddr;
      }
    }

    // 3. Fallback final: string cheia
    session.log('Nominatim: fallback para endereço completo "$address"');
    final resultFull = await _geocodeQuery(session, address);
    if (resultFull != null) return resultFull;

    // 4. Fallback de desespero: tentar apenas Cidade e Estado
    if (city.isNotEmpty) {
      final stateMatch = RegExp(r'\b[A-Z]{2}\b').firstMatch(address);
      final stateStr = stateMatch != null ? stateMatch.group(0) : '';
      final queryCity = stateStr != null && stateStr.isNotEmpty ? '$city, $stateStr, Brasil' : '$city, Brasil';
      session.log('Nominatim: fallback de desespero para cidade "$queryCity"');
      final resultCity = await _geocodeQuery(session, queryCity);
      if (resultCity != null) return resultCity;
    }

    session.log('Nominatim: falha ao geocodificar "$address"', level: LogLevel.warning);
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
