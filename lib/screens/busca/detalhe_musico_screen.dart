import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/local_image_provider.dart';
import '../../providers/oportunidade_provider.dart';

class DetalheMusicoScreen extends StatelessWidget {
  final String musicoId;

  const DetalheMusicoScreen({super.key, required this.musicoId});

  Future<void> _abrirLink(BuildContext context, String link) async {
    String url = link.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link inválido.')));
      return;
    }

    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Future<void> _confirmarInteresse(BuildContext context) async {
    final provider = context.read<OportunidadeProvider>();
    final musico = provider.buscarMusicoPorId(musicoId);

    if (musico == null) return;

    if (musico.interesseEnviado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já demonstrou interesse neste artista.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Demonstrar interesse'),
        content: Text(
          'Deseja demonstrar interesse no artista "${musico.nomeArtistico}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    await provider.demonstrarInteresseEmMusico(
      musicoId: musicoId,
      usuarioId: 'casa_show_logada_1',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interesse no artista enviado com sucesso!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final musico = provider.buscarMusicoPorId(musicoId);

    if (musico == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do músico')),
        body: const Center(child: Text('Músico não encontrado.')),
      );
    }

    final imageProvider = localImageProvider(musico.fotoPath);
    final temFoto = imageProvider != null;
    final interesseEnviado = musico.interesseEnviado == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do músico')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.deepPurple.shade100,
              backgroundImage: imageProvider,
              child: !temFoto
                  ? const Icon(
                      Icons.music_note,
                      size: 50,
                      color: Colors.deepPurple,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              musico.nomeArtistico,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gênero: ${musico.generoMusical}'),
                  const SizedBox(height: 8),
                  Text('Cidade: ${musico.cidade}'),
                  const SizedBox(height: 8),
                  Text(
                    'Cachê médio: R\$ ${musico.cacheMedio.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descrição',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(musico.descricao),
                  const SizedBox(height: 16),
                  const Text(
                    'Datas disponíveis',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (musico.datasDisponiveis.isEmpty)
                    const Text('Nenhuma data informada.')
                  else
                    ...musico.datasDisponiveis.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $data'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Portfólio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (musico.portfolioLinks.isEmpty)
                    const Text('Nenhum link cadastrado.')
                  else
                    ...musico.portfolioLinks.map(
                      (link) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _abrirLink(context, link),
                          child: Text(
                            link,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: interesseEnviado
                  ? null
                  : () => _confirmarInteresse(context),
              icon: const Icon(Icons.favorite_border),
              label: Text(
                interesseEnviado
                    ? 'Interesse já enviado'
                    : 'Demonstrar interesse',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
