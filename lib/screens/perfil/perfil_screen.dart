import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/local_image_provider.dart';
import '../../models/musico.dart';
import '../../providers/perfil_provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeArtisticoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _cacheController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _portfolioController = TextEditingController();

  bool _dadosCarregados = false;
  bool _modoEdicao = false;
  String? _fotoSelecionadaPath;
  String? _generoSelecionado;

  @override
  void initState() {
    super.initState();

    final provider = context.read<PerfilProvider>();

    Future.microtask(() {
      if (provider.perfilMusico == null) {
        provider.carregarPerfilMock();
      }

      final perfil = provider.perfilMusico;
      if (perfil != null && mounted) {
        _preencherCampos(perfil);
      }
    });
  }

  void _preencherCampos(Musico perfil) {
    _nomeArtisticoController.text = perfil.nomeArtistico;
    _cidadeController.text = perfil.cidade;
    _cacheController.text = perfil.cacheMedio.toStringAsFixed(2);
    _descricaoController.text = perfil.descricao;
    _portfolioController.text = perfil.portfolioLinks.join('\n');
    _fotoSelecionadaPath = perfil.fotoPath;
    _generoSelecionado = perfil.generoMusical;
    _dadosCarregados = true;
  }

  Future<void> _cancelarEdicaoComConfirmacao(Musico perfil) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar edição'),
        content: const Text(
          'Deseja realmente cancelar? As alterações não salvas serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    _preencherCampos(perfil);

    setState(() {
      _modoEdicao = false;
    });
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();

    final imagem = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagem == null) return;

    setState(() {
      _fotoSelecionadaPath = imagem.path;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagem selecionada com sucesso!')),
    );
  }

  Future<void> _abrirLink(String link) async {
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

    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  String? _validarCampoObrigatorio(String? value, String nomeCampo) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $nomeCampo.';
    }
    return null;
  }

  String? _validarCache(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o cachê.';
    }

    final valor = double.tryParse(value.replaceAll(',', '.'));
    if (valor == null) {
      return 'Informe um valor numérico válido.';
    }

    if (valor < 0) {
      return 'O cachê não pode ser negativo.';
    }

    return null;
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    if (_generoSelecionado == null || _generoSelecionado!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um gênero musical.')),
      );
      return;
    }

    final provider = context.read<PerfilProvider>();

    final portfolioLinks = _portfolioController.text
        .split('\n')
        .map((link) => link.trim())
        .where((link) => link.isNotEmpty)
        .toList();

    final cache = double.parse(
      _cacheController.text.trim().replaceAll(',', '.'),
    );

    await provider.atualizarPerfil(
      nomeArtistico: _nomeArtisticoController.text.trim(),
      generoMusical: _generoSelecionado!,
      cidade: _cidadeController.text.trim(),
      cacheMedio: cache,
      descricao: _descricaoController.text.trim(),
      portfolioLinks: portfolioLinks,
      fotoPath: _fotoSelecionadaPath,
    );

    if (!mounted) return;

    setState(() {
      _modoEdicao = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso!')),
    );
  }

  @override
  void dispose() {
    _nomeArtisticoController.dispose();
    _cidadeController.dispose();
    _cacheController.dispose();
    _descricaoController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Widget _buildFotoPerfil() {
    final imageProvider = localImageProvider(_fotoSelecionadaPath);
    final hasImage = imageProvider != null;

    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: Colors.deepPurple.shade100,
          backgroundImage: imageProvider,
          child: !hasImage
              ? const Icon(Icons.person, size: 55, color: Colors.deepPurple)
              : null,
        ),
        const SizedBox(height: 12),
        if (_modoEdicao)
          OutlinedButton.icon(
            onPressed: _selecionarImagem,
            icon: const Icon(Icons.photo),
            label: const Text('Alterar foto'),
          ),
      ],
    );
  }

  Widget _buildVisualizacao(Musico perfil) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFotoPerfil(),
        const SizedBox(height: 20),
        Center(
          child: Text(
            perfil.nomeArtistico,
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
                Text('Gênero: ${perfil.generoMusical}'),
                const SizedBox(height: 8),
                Text('Cidade: ${perfil.cidade}'),
                const SizedBox(height: 8),
                Text(
                  'Cachê médio: R\$ ${perfil.cacheMedio.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
                Text('Descrição: ${perfil.descricao}'),
                const SizedBox(height: 16),
                const Text(
                  'Portfólio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (perfil.portfolioLinks.isEmpty)
                  const Text('Nenhum link cadastrado.')
                else
                  ...perfil.portfolioLinks.map(
                    (link) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _abrirLink(link),
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
            onPressed: () {
              setState(() {
                _modoEdicao = true;
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar perfil'),
          ),
        ),
      ],
    );
  }

  Widget _buildEdicao(Musico perfil) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFotoPerfil(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nomeArtisticoController,
              decoration: const InputDecoration(
                labelText: 'Nome artístico',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  _validarCampoObrigatorio(value, 'o nome artístico'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _generoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Gênero musical',
                border: OutlineInputBorder(),
              ),
              items: AppStrings.generosMusicais
                  .map(
                    (genero) =>
                        DropdownMenuItem(value: genero, child: Text(genero)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _generoSelecionado = value;
                });
              },
              validator: (value) => value == null || value.isEmpty
                  ? 'Selecione um gênero musical.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cidadeController,
              decoration: const InputDecoration(
                labelText: 'Cidade',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _validarCampoObrigatorio(value, 'a cidade'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cacheController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cachê médio',
                hintText: 'Ex: 1500.00',
                border: OutlineInputBorder(),
              ),
              validator: _validarCache,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  _validarCampoObrigatorio(value, 'a descrição'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portfolioController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Portfólio',
                hintText:
                    'Informe um link por linha\nhttps://instagram.com/...\nhttps://youtube.com/...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dica: informe um link por linha.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelarEdicaoComConfirmacao(perfil),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvarPerfil,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    final perfil = provider.perfilMusico;

    if (perfil != null && !_dadosCarregados) {
      _preencherCampos(perfil);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do artista')),
      body: perfil == null
          ? const Center(child: CircularProgressIndicator())
          : _modoEdicao
          ? _buildEdicao(perfil)
          : _buildVisualizacao(perfil),
    );
  }
}
