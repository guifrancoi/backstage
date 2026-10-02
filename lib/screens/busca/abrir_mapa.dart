import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/location_service.dart';

/// Abre o endereço no Google Maps: geocodifica pelo `LocationService` e, se
/// não achar, cai na busca por texto. Mostra SnackBar se não abrir. Usado no
/// detalhe da oportunidade e no perfil do estabelecimento (Plano 16).
Future<void> abrirMapa(
  BuildContext context, {
  required String logradouro,
  required String numero,
  required String cidade,
  required String estado,
  String? cep,
}) async {
  final coordenadas = await context.read<LocationService>().geocodeEndereco(
    logradouro: logradouro,
    numero: numero,
    cidade: cidade,
    estado: estado,
    cep: cep,
  );

  final Uri uri;
  if (coordenadas != null) {
    final (lat, lon) = coordenadas;
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
  } else {
    final query = Uri.encodeComponent('$logradouro $numero, $cidade - $estado');
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
  }

  if (!context.mounted) return;
  final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!abriu && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o mapa.')),
    );
  }
}
