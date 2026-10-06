import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../models/casa_show.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/titulo_secao.dart';
import 'botoes_formulario.dart';

/// Formulário do perfil de estabelecimento, usado no onboarding e na tela de
/// Perfil. Obrigatórios: nome, cidade, endereço (logradouro, número, estado)
/// e contato. Não grava nada: devolve o [CasaShow] montado em [onSalvar].
class PerfilEstabelecimentoForm extends StatefulWidget {
  const PerfilEstabelecimentoForm({
    super.key,
    this.inicial,
    required this.onSalvar,
    this.onCancelar,
    this.textoSalvar = 'Salvar',
  });

  final CasaShow? inicial;
  final Future<void> Function(CasaShow perfil) onSalvar;
  final VoidCallback? onCancelar;
  final String textoSalvar;

  @override
  State<PerfilEstabelecimentoForm> createState() =>
      _PerfilEstabelecimentoFormState();
}

class _PerfilEstabelecimentoFormState extends State<PerfilEstabelecimentoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cepController = TextEditingController();
  final _contatoController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _capacidadeController = TextEditingController();
  final _descricaoController = TextEditingController();

  late final Set<String> _estilos;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final perfil = widget.inicial;
    _nomeController.text = perfil?.nome ?? '';
    _logradouroController.text = perfil?.logradouro ?? '';
    _numeroController.text = perfil?.numero ?? '';
    _cidadeController.text = perfil?.cidade ?? '';
    _estadoController.text = perfil?.estado ?? '';
    _cepController.text = perfil?.cep ?? '';
    _contatoController.text = perfil?.contato ?? '';
    _cnpjController.text = perfil?.cnpj ?? '';
    _capacidadeController.text = (perfil?.capacidade ?? 0) > 0
        ? '${perfil!.capacidade}'
        : '';
    _descricaoController.text = perfil?.descricao ?? '';
    _estilos = {...?perfil?.estilosDesejados};
  }

  @override
  void dispose() {
    for (final controller in [
      _nomeController,
      _logradouroController,
      _numeroController,
      _cidadeController,
      _estadoController,
      _cepController,
      _contatoController,
      _cnpjController,
      _capacidadeController,
      _descricaoController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validarEstado(String? value) {
    final uf = value?.trim() ?? '';
    if (uf.isEmpty) return 'Informe o estado.';
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(uf)) return 'Use a sigla (ex: SP).';
    return null;
  }

  String? _validarCapacidade(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) return null;
    final valor = int.tryParse(texto);
    if (valor == null || valor < 0) return 'Informe um número válido.';
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final cep = _cepController.text.trim();
    final perfil = CasaShow(
      id: widget.inicial?.id ?? '',
      nome: _nomeController.text.trim(),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim().toUpperCase(),
      cep: cep.isEmpty ? null : cep,
      contato: _contatoController.text.trim(),
      cnpj: _cnpjController.text.trim(),
      capacidade: int.tryParse(_capacidadeController.text.trim()) ?? 0,
      descricao: _descricaoController.text.trim(),
      estilosDesejados: AppStrings.generosMusicais
          .where(_estilos.contains)
          .toList(),
    );

    setState(() => _salvando = true);
    try {
      await widget.onSalvar(perfil);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(
    TextEditingController controller,
    String rotulo, {
    String? Function(String?)? validator,
    TextInputType teclado = TextInputType.text,
    int linhas = 1,
    String? dica,
    IconData? icone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomTextField(
        controller: controller,
        label: rotulo,
        keyboardType: teclado,
        linhas: linhas,
        dica: dica,
        icone: icone,
        validator: validator,
      ),
    );
  }

  String? Function(String?) _obrigatorio(String campo) =>
      (value) => Validators.validarCampoObrigatorio(value, campo);

  @override
  Widget build(BuildContext context) {
    // Espaço para o rótulo flutuante do 1º campo não colar no título.
    const espaco = SizedBox(height: AppSpacing.sm);
    const entreSecoes = SizedBox(height: AppSpacing.lg);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RotuloSecao('Estabelecimento', destaque: true),
          espaco,
          _campo(
            _nomeController,
            'Nome do estabelecimento',
            icone: Icons.storefront_outlined,
            validator: _obrigatorio('o nome'),
          ),
          _campo(
            _capacidadeController,
            'Capacidade de público (opcional)',
            icone: Icons.groups_outlined,
            teclado: TextInputType.number,
            validator: _validarCapacidade,
          ),
          _campo(
            _descricaoController,
            'Descrição (opcional)',
            dica: 'Ambiente, público, estrutura de som...',
            linhas: 4,
          ),
          entreSecoes,
          const RotuloSecao('Endereço', destaque: true),
          espaco,
          _campo(
            _logradouroController,
            'Logradouro',
            icone: Icons.place_outlined,
            dica: 'Ex: Rua das Flores',
            validator: _obrigatorio('o logradouro'),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _campo(
                  _numeroController,
                  'Número',
                  validator: _obrigatorio('o número'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _campo(
                  _cepController,
                  'CEP (opcional)',
                  teclado: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _campo(
                  _cidadeController,
                  'Cidade',
                  validator: _obrigatorio('a cidade'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _campo(
                  _estadoController,
                  'UF',
                  validator: _validarEstado,
                ),
              ),
            ],
          ),
          entreSecoes,
          const RotuloSecao('Contato', destaque: true),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Só aparece para quem tiver um interesse aceito com você.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _campo(
            _contatoController,
            'Contato',
            icone: Icons.phone_outlined,
            dica: 'Telefone, WhatsApp ou e-mail',
            validator: _obrigatorio('o contato'),
          ),
          _campo(
            _cnpjController,
            'CNPJ (opcional)',
            icone: Icons.badge_outlined,
            teclado: TextInputType.number,
          ),
          entreSecoes,
          const RotuloSecao('Estilos que procura (opcional)', destaque: true),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: AppStrings.generosMusicais
                .map(
                  (genero) => FilterChip(
                    label: Text(genero),
                    selected: _estilos.contains(genero),
                    onSelected: (selecionado) => setState(() {
                      selecionado
                          ? _estilos.add(genero)
                          : _estilos.remove(genero);
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
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
