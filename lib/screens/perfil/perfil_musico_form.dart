import '../../core/theme/app_colors.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/foto_perfil.dart';
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
    this.escolherFoto = escolherMiniatura,
  });

  /// Abre a galeria e devolve a miniatura em base64 (`null` = desistiu).
  /// Injetável para os testes, que não têm galeria.
  final Future<String?> Function() escolherFoto;

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
  final _integrantesController = TextEditingController();
  final _duracaoController = TextEditingController();
  final _repertorioController = TextEditingController();

  String? _generoSelecionado;
  String? _foto;
  Formacao? _formacao;
  bool _equipamentoProprio = false;
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
    _foto = perfil?.foto;
    _formacao = perfil?.formacao;
    _equipamentoProprio = perfil?.equipamentoProprio ?? false;
    _integrantesController.text = perfil?.integrantes?.toString() ?? '';
    _duracaoController.text = perfil?.duracaoShowMin?.toString() ?? '';
    _repertorioController.text = perfil?.repertorio ?? '';
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
    _integrantesController.dispose();
    _duracaoController.dispose();
    _repertorioController.dispose();
    super.dispose();
  }

  /// Número inteiro opcional entre [min] e [max].
  String? Function(String?) _validarInteiro(int min, int max, String campo) {
    return (value) {
      final texto = value?.trim() ?? '';
      if (texto.isEmpty) return null;
      final n = int.tryParse(texto);
      if (n == null || n < min || n > max) {
        return 'Informe $campo entre $min e $max.';
      }
      return null;
    };
  }

  int? _inteiro(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  String? _validarCache(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o cachê.';
    final valor = double.tryParse(value.replaceAll(',', '.'));
    if (valor == null) return 'Informe um valor numérico válido.';
    if (valor < 0) return 'O cachê não pode ser negativo.';
    return null;
  }

  Future<void> _selecionarImagem() async {
    final foto = await widget.escolherFoto();
    if (foto == null || !mounted) return;
    if (foto.length > Musico.tamanhoMaximoFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto muito grande. Escolha uma imagem JPG ou PNG.'),
        ),
      );
      return;
    }
    setState(() => _foto = foto);
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
      foto: _foto,
      formacao: _formacao,
      // Solo/duo/trio já dizem quantos são.
      integrantes: _formacao == Formacao.banda
          ? _inteiro(_integrantesController)
          : null,
      equipamentoProprio: _equipamentoProprio,
      duracaoShowMin: _inteiro(_duracaoController),
      repertorio: _repertorioController.text.trim().isEmpty
          ? null
          : _repertorioController.text.trim(),
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
    final imagem = imagemDaFoto(_foto);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.primariaContainer,
              backgroundImage: imagem,
              child: imagem == null
                  ? const Icon(Icons.person, size: 55, color: AppColors.primariaTexto)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _selecionarImagem,
                icon: const Icon(Icons.photo),
                label: Text(_foto == null ? 'Escolher foto' : 'Alterar foto'),
              ),
              if (_foto != null)
                TextButton.icon(
                  onPressed: () => setState(() => _foto = null),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover foto'),
                ),
            ],
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
          Text(
            'Sobre o show (opcional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Formacao?>(
            initialValue: _formacao,
            decoration: const InputDecoration(
              labelText: 'Formação',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<Formacao?>(
                value: null,
                child: Text('Não informar'),
              ),
              for (final f in Formacao.values)
                DropdownMenuItem<Formacao?>(value: f, child: Text(f.rotulo)),
            ],
            onChanged: (value) => setState(() => _formacao = value),
          ),
          if (_formacao == Formacao.banda) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _integrantesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de integrantes',
                border: OutlineInputBorder(),
              ),
              validator: _validarInteiro(2, 50, 'um número'),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tenho equipamento próprio'),
            subtitle: const Text('Som e/ou luz para o show'),
            value: _equipamentoProprio,
            onChanged: (value) => setState(() => _equipamentoProprio = value),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _duracaoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duração do show (minutos)',
              hintText: 'Ex: 120',
              border: OutlineInputBorder(),
            ),
            validator: _validarInteiro(10, 600, 'uma duração'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _repertorioController,
            maxLines: 2,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Repertório',
              hintText: 'Ex: autoral + covers de rock nacional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
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

/// Escolhe uma foto na galeria já reduzida (até 256 px, JPEG 70%) e devolve
/// em base64 para gravar no perfil (Plano 14). Funciona também no Web
/// (`readAsBytes`); só GIF não é reduzido lá.
Future<String?> escolherMiniatura() async {
  final imagem = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 256,
    maxHeight: 256,
    imageQuality: 70,
  );
  if (imagem == null) return null;
  return base64Encode(await imagem.readAsBytes());
}
