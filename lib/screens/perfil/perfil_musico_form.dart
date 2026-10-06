import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../models/musico.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/titulo_secao.dart';
import 'botoes_formulario.dart';

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
        // "1100" em vez de "1100.00"; centavos só quando houver.
        ? perfil.cacheMedio.toStringAsFixed(
            perfil.cacheMedio == perfil.cacheMedio.roundToDouble() ? 0 : 2,
          )
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
    const espaco = SizedBox(height: AppSpacing.sm);
    const entreSecoes = SizedBox(height: AppSpacing.lg);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            // O nome digitado já vira as iniciais enquanto não há foto.
            child: ListenableBuilder(
              listenable: _nomeArtisticoController,
              builder: (_, _) => AvatarIniciais(
                nome: _nomeArtisticoController.text,
                foto: _foto,
                tamanho: 96,
                circular: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              TextButton.icon(
                onPressed: _selecionarImagem,
                icon: const Icon(Icons.photo_camera_outlined),
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
          const SizedBox(height: AppSpacing.md),
          const RotuloSecao('Identidade', destaque: true),
          espaco,
          CustomTextField(
            controller: _nomeArtisticoController,
            label: 'Nome artístico',
            icone: Icons.person_outline,
            validator: (value) =>
                Validators.validarCampoObrigatorio(value, 'o nome artístico'),
          ),
          espaco,
          DropdownButtonFormField<String>(
            initialValue: _generoSelecionado,
            decoration: const InputDecoration(
              labelText: 'Gênero musical',
              prefixIcon: Icon(Icons.music_note_outlined),
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
          espaco,
          CustomTextField(
            controller: _cidadeController,
            label: 'Cidade',
            icone: Icons.place_outlined,
            validator: (value) =>
                Validators.validarCampoObrigatorio(value, 'a cidade'),
          ),
          espaco,
          CustomTextField(
            controller: _cacheController,
            label: 'Cachê médio',
            icone: Icons.payments_outlined,
            dica: 'Ex: 1500',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validarCache,
          ),
          espaco,
          CustomTextField(
            controller: _descricaoController,
            label: 'Descrição',
            dica: 'Conte sua trajetória e o estilo do seu show',
            linhas: 4,
            validator: (value) =>
                Validators.validarCampoObrigatorio(value, 'a descrição'),
          ),
          entreSecoes,
          const RotuloSecao('Sobre o show (opcional)', destaque: true),
          espaco,
          Text('Formação', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          // Tocar de novo na escolhida desmarca (= não informar).
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final f in Formacao.values)
                ChoiceChip(
                  label: Text(f.rotulo),
                  selected: _formacao == f,
                  onSelected: (sim) =>
                      setState(() => _formacao = sim ? f : null),
                ),
            ],
          ),
          if (_formacao == Formacao.banda) ...[
            espaco,
            CustomTextField(
              controller: _integrantesController,
              label: 'Número de integrantes',
              icone: Icons.groups_outlined,
              keyboardType: TextInputType.number,
              validator: _validarInteiro(2, 50, 'um número'),
            ),
          ],
          espaco,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tenho equipamento próprio'),
            subtitle: const Text('Som e/ou luz para o show'),
            value: _equipamentoProprio,
            onChanged: (value) => setState(() => _equipamentoProprio = value),
          ),
          espaco,
          CustomTextField(
            controller: _duracaoController,
            label: 'Duração do show (minutos)',
            icone: Icons.timer_outlined,
            dica: 'Ex: 120',
            keyboardType: TextInputType.number,
            validator: _validarInteiro(10, 600, 'uma duração'),
          ),
          espaco,
          CustomTextField(
            controller: _repertorioController,
            label: 'Repertório',
            dica: 'Ex: autoral + covers de rock nacional',
            linhas: 2,
            maxLength: 200,
          ),
          entreSecoes,
          const RotuloSecao('Portfólio (opcional)', destaque: true),
          espaco,
          CustomTextField(
            controller: _portfolioController,
            label: 'Links',
            dica: 'https://instagram.com/...\nhttps://youtube.com/...',
            ajuda: 'Um link por linha: Instagram, YouTube, Spotify...',
            linhas: 4,
          ),
          entreSecoes,
          BotoesFormulario(
            textoSalvar: widget.textoSalvar,
            salvando: _salvando,
            onSalvar: _salvar,
            onCancelar: widget.onCancelar,
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
