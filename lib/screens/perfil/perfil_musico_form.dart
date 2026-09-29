import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/local_image_provider.dart';
import '../../core/utils/validators.dart';
import '../../models/musico.dart';

/// Formulário do perfil de artista, usado no onboarding e na tela de Perfil.
/// Não grava nada: devolve o [Musico] montado em [onSalvar] (o id é
/// definido pelo `PerfilProvider`).
class PerfilMusicoForm extends StatefulWidget {
  const PerfilMusicoForm({
    super.key,
    this.inicial,
    this.nomePadrao = '',
    required this.onSalvar,
    this.onCancelar,
    this.textoSalvar = 'Salvar',
  });

  final Musico? inicial;

  /// Nome artístico sugerido quando ainda não há perfil (nome da conta).
  final String nomePadrao;
  final Future<void> Function(Musico perfil) onSalvar;
  final VoidCallback? onCancelar;
  final String textoSalvar;

  @override
  State<PerfilMusicoForm> createState() => _PerfilMusicoFormState();
}

class _PerfilMusicoFormState extends State<PerfilMusicoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeArtisticoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _cacheController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _portfolioController = TextEditingController();

  String? _generoSelecionado;
  String? _fotoPath;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final perfil = widget.inicial;
    _nomeArtisticoController.text = perfil?.nomeArtistico.isNotEmpty == true
        ? perfil!.nomeArtistico
        : widget.nomePadrao;
    _cidadeController.text = perfil?.cidade ?? '';
    // Perfil antigo em branco tinha cachê 0: melhor campo vazio que "0.00".
    _cacheController.text = perfil != null && perfil.completo
        ? perfil.cacheMedio.toStringAsFixed(2)
        : '';
    _descricaoController.text = perfil?.descricao ?? '';
    _portfolioController.text = perfil?.portfolioLinks.join('\n') ?? '';
    _fotoPath = perfil?.fotoPath;
    // O dropdown exige um valor da lista ou null.
    _generoSelecionado =
        AppStrings.generosMusicais.contains(perfil?.generoMusical)
        ? perfil!.generoMusical
        : null;
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

  String? _validarCache(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o cachê.';
    final valor = double.tryParse(value.replaceAll(',', '.'));
    if (valor == null) return 'Informe um valor numérico válido.';
    if (valor < 0) return 'O cachê não pode ser negativo.';
    return null;
  }

  Future<void> _selecionarImagem() async {
    final imagem = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imagem == null) return;
    setState(() => _fotoPath = imagem.path);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final perfil = Musico(
      id: widget.inicial?.id ?? '',
      nomeArtistico: _nomeArtisticoController.text.trim(),
      generoMusical: _generoSelecionado!,
      cidade: _cidadeController.text.trim(),
      cacheMedio: double.parse(
        _cacheController.text.trim().replaceAll(',', '.'),
      ),
      descricao: _descricaoController.text.trim(),
      portfolioLinks: _portfolioController.text
          .split('\n')
          .map((link) => link.trim())
          .where((link) => link.isNotEmpty)
          .toList(),
      fotoPath: _fotoPath,
    );

    setState(() => _salvando = true);
    try {
      await widget.onSalvar(perfil);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagem = localImageProvider(_fotoPath);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.deepPurple.shade100,
              backgroundImage: imagem,
              child: imagem == null
                  ? const Icon(Icons.person, size: 55, color: Colors.deepPurple)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _selecionarImagem,
              icon: const Icon(Icons.photo),
              label: const Text('Alterar foto'),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nomeArtisticoController,
            decoration: const InputDecoration(
              labelText: 'Nome artístico',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                Validators.validarCampoObrigatorio(value, 'o nome artístico'),
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
            onChanged: (value) => setState(() => _generoSelecionado = value),
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
            validator: (value) =>
                Validators.validarCampoObrigatorio(value, 'a cidade'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cacheController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                Validators.validarCampoObrigatorio(value, 'a descrição'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _portfolioController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Portfólio (opcional)',
              hintText:
                  'Informe um link por linha\nhttps://instagram.com/...\nhttps://youtube.com/...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.onCancelar != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _salvando ? null : widget.onCancelar,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: Text(_salvando ? 'Salvando...' : widget.textoSalvar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
