import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/location_service.dart';
import 'acoes_interesse.dart';

class DetalheOportunidadeScreen extends StatefulWidget {
  final String oportunidadeId;

  const DetalheOportunidadeScreen({super.key, required this.oportunidadeId});

  @override
  State<DetalheOportunidadeScreen> createState() =>
      _DetalheOportunidadeScreenState();
}

class _DetalheOportunidadeScreenState extends State<DetalheOportunidadeScreen> {
  bool _carregandoMapa = false;

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> _abrirMapa({
    required String logradouro,
    required String numero,
    required String cidade,
    required String estado,
    String? cep,
  }) async {
    final locationService = context.read<LocationService>();
    setState(() => _carregandoMapa = true);

    try {
      final coordenadas = await locationService.geocodeEndereco(
        logradouro: logradouro,
        numero: numero,
        cidade: cidade,
        estado: estado,
        cep: cep,
      );

      Uri uri;
      if (coordenadas != null) {
        final (lat, lon) = coordenadas;
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
        );
      } else {
        final query = Uri.encodeComponent(
          '$logradouro $numero, $cidade - $estado',
        );
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$query',
        );
      }

      if (!mounted) return;

      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa.')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregandoMapa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final oportunidade =
        provider.buscarOportunidadePorId(widget.oportunidadeId);

    if (oportunidade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da oportunidade')),
        body: const Center(child: Text('Oportunidade não encontrada.')),
      );
    }

    final pode = podeCandidatar(auth, oportunidade);
    final candidatura = interesses.candidaturaPara(oportunidade.id);

    final temEndereco = oportunidade.logradouro.isNotEmpty &&
        oportunidade.numero.isNotEmpty &&
        oportunidade.estado.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da oportunidade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (oportunidade.vencida) ...[
                    const Chip(
                      avatar: Icon(Icons.event_busy, size: 18),
                      label: Text('Evento encerrado'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    oportunidade.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Contratante: ${oportunidade.contratante}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Localização',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (temEndereco) ...[
                    Text(
                      '${oportunidade.logradouro}, ${oportunidade.numero}',
                    ),
                    Text(
                      '${oportunidade.cidade} — ${oportunidade.estado}'
                      '${oportunidade.cep != null ? '  CEP: ${oportunidade.cep}' : ''}',
                    ),
                  ] else
                    Text(oportunidade.cidade),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _carregandoMapa
                          ? null
                          : () => _abrirMapa(
                                logradouro: oportunidade.logradouro,
                                numero: oportunidade.numero,
                                cidade: oportunidade.cidade,
                                estado: oportunidade.estado,
                                cep: oportunidade.cep,
                              ),
                      icon: _carregandoMapa
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.map_outlined),
                      label: const Text('Ver no mapa'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Gênero musical: ${oportunidade.generoMusical}'),
                  const SizedBox(height: 8),
                  Text(
                    'Data do evento: ${_formatarData(oportunidade.dataEvento)}',
                  ),
                  if (oportunidade.horario.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Horário: ${oportunidade.horario}'),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Cachê oferecido: R\$ ${oportunidade.cacheOferecido.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descrição',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(oportunidade.descricao),
                ],
              ),
            ),
          ),
          if (pode) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: candidatura == null
                    ? () => confirmarCandidatura(context, oportunidade)
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: Text(candidatura?.rotuloStatus ?? 'Candidatar-se'),
              ),
            ),
          ],
          if (podeGerenciar(auth, oportunidade)) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final removeu = await confirmarRemocao(
                        context,
                        oportunidade,
                      );
                      if (removeu && context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.editarOportunidade,
                      arguments: oportunidade.id,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
