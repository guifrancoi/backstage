import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../models/casa_show.dart';

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
    TextInputType? teclado,
    int maxLines = 1,
    String? dica,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: teclado,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: rotulo,
          hintText: dica,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String? Function(String?) _obrigatorio(String campo) =>
      (value) => Validators.validarCampoObrigatorio(value, campo);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            _nomeController,
            'Nome do estabelecimento',
            validator: _obrigatorio('o nome'),
          ),
          _campo(
            _logradouroController,
            'Logradouro',
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
              const SizedBox(width: 12),
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
              const SizedBox(width: 12),
              Expanded(
                child: _campo(
                  _estadoController,
                  'UF',
                  validator: _validarEstado,
                ),
              ),
            ],
          ),
          _campo(
            _contatoController,
            'Contato',
            dica: 'Telefone, WhatsApp ou e-mail',
            validator: _obrigatorio('o contato'),
          ),
          _campo(_cnpjController, 'CNPJ (opcional)'),
          _campo(
            _capacidadeController,
            'Capacidade de público (opcional)',
            teclado: TextInputType.number,
            validator: _validarCapacidade,
          ),
          _campo(_descricaoController, 'Descrição (opcional)', maxLines: 4),
          const Text(
            'Estilos desejados (opcional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
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
