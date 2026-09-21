import 'dart:convert';

import 'package:http/http.dart' as http;

class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() => _client.close();

  static const String _host = 'nominatim.openstreetmap.org';
  static const String _userAgent = 'BackstageApp/0.1.0';

  /// Geocodifica um endereço estruturado e retorna (latitude, longitude), ou null em falha.
  Future<(double, double)?> geocodeEndereco({
    required String logradouro,
    required String numero,
    required String cidade,
    required String estado,
    String? cep,
    String pais = 'Brasil',
  }) async {
    final params = <String, String>{
      'street': '$numero $logradouro',
      'city': cidade,
      'state': estado,
      'country': pais,
      'format': 'json',
      'limit': '1',
      'addressdetails': '0',
    };

    if (cep != null && cep.isNotEmpty) {
      params['postalcode'] = cep;
    }

    final uri = Uri.https(_host, '/search', params);

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');

      if (lat == null || lon == null) return null;
      return (lat, lon);
    } catch (_) {
      return null;
    }
  }
}
