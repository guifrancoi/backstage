import 'dart:async';
import 'dart:convert';

import 'package:backstage/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<(double, double)?> _geocode(LocationService service, {String? cep}) {
  return service.geocodeEndereco(
    logradouro: 'Rua Barão do Amazonas',
    numero: '520',
    cidade: 'Ribeirão Preto',
    estado: 'SP',
    cep: cep,
  );
}

void main() {
  group('LocationService.geocodeEndereco', () {
    test('retorna (lat, lon) do primeiro resultado', () async {
      final service = LocationService(
        client: MockClient((_) async => http.Response(
          jsonEncode([
            {'lat': '-21.1775', 'lon': '-47.8103'},
            {'lat': '0', 'lon': '0'},
          ]),
          200,
        )),
      );

      expect(await _geocode(service), (-21.1775, -47.8103));
    });

    test('monta a consulta estruturada do Nominatim com User-Agent', () async {
      late http.Request requisicao;
      final service = LocationService(
        client: MockClient((request) async {
          requisicao = request;
          return http.Response('[]', 200);
        }),
      );

      await _geocode(service, cep: '14010-120');

      final uri = requisicao.url;
      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.path, '/search');
      expect(uri.queryParameters, {
        'street': '520 Rua Barão do Amazonas',
        'city': 'Ribeirão Preto',
        'state': 'SP',
        'country': 'Brasil',
        'format': 'json',
        'limit': '1',
        'addressdetails': '0',
        'postalcode': '14010-120',
      });
      expect(requisicao.headers['User-Agent'], 'BackstageApp/0.1.0');
    });

    test('omite postalcode quando o cep é nulo ou vazio', () async {
      final consultas = <Map<String, String>>[];
      final service = LocationService(
        client: MockClient((request) async {
          consultas.add(request.url.queryParameters);
          return http.Response('[]', 200);
        }),
      );

      await _geocode(service);
      await _geocode(service, cep: '');

      for (final consulta in consultas) {
        expect(consulta.containsKey('postalcode'), isFalse);
      }
    });

    test('retorna null quando não há resultados', () async {
      final service = LocationService(
        client: MockClient((_) async => http.Response('[]', 200)),
      );

      expect(await _geocode(service), isNull);
    });

    test('retorna null para status diferente de 200', () async {
      final service = LocationService(
        client: MockClient((_) async => http.Response('erro', 503)),
      );

      expect(await _geocode(service), isNull);
    });

    test('retorna null quando lat/lon não são numéricos', () async {
      final service = LocationService(
        client: MockClient((_) async => http.Response(
          jsonEncode([
            {'lat': 'abc', 'lon': null},
          ]),
          200,
        )),
      );

      expect(await _geocode(service), isNull);
    });

    test('retorna null para JSON inválido', () async {
      final service = LocationService(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );

      expect(await _geocode(service), isNull);
    });

    test('retorna null em falha de rede', () async {
      final service = LocationService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(await _geocode(service), isNull);
    });

    test('retorna null em timeout', () async {
      final service = LocationService(
        client: MockClient((_) async => throw TimeoutException('lento')),
      );

      expect(await _geocode(service), isNull);
    });
  });
}
