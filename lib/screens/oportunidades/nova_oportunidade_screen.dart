import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../core/utils/validators.dart';
import '../../models/oportunidade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../widgets/campo_horario.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/estados.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/titulo_secao.dart';

/// Cria uma oportunidade ou, com [oportunidadeId], edita uma existente (dono
/// ou admin). Na criação o endereço vem do perfil do estabelecimento e o
/// contratante é o nome dele.
class NovaOportunidadeScreen extends StatefulWidget {
  const NovaOportunidadeScreen({super.key, this.oportunidadeId});

  final String? oportunidadeId;

  @override
  State<NovaOportunidadeScreen> createState() => _NovaOportunidadeScreenState();
}

class _NovaOportunidadeScreenState extends State<NovaOportunidadeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _cacheController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cepController = TextEditingController();

  String? _genero;
  DateTime? _dataEvento;
  String? _horaInicio;
  String? _horaFim;
  bool _salvando = false;

  /// Oportunidade em edição (null = criando).
  Oportunidade? _original;

  bool get _editando => widget.oportunidadeId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.oportunidadeId;
    if (id != null) {
      final o = context.read<OportunidadeProvider>().buscarOportunidadePorId(
        id,
      );
      _original = o;
      if (o != null) {
        _tituloController.text = o.titulo;
        _descricaoController.text = o.descricao;
        _cacheController.text = o.cacheOferecido.toStringAsFixed(2);
        _cidadeController.text = o.cidade;
        _estadoController.text = o.estado;
        _logradouroController.text = o.logradouro;
        _numeroController.text = o.numero;
        _cepController.text = o.cep ?? '';
        _genero = AppStrings.generosMusicais.contains(o.generoMusical)
            ? o.generoMusical
            : null;
        _dataEvento = o.dataEvento;
        _horaInicio = o.horaInicio;
        _horaFim = o.horaFim;
      }
      return;
    }

    final estabelecimento = context
        .read<PerfilProvider>()
        .perfilEstabelecimento;
    if (estabelecimento != null) {
      _cidadeController.text = estabelecimento.cidade;
      _estadoController.text = estabelecimento.estado;
      _logradouroController.text = estabelecimento.logradouro;
      _numeroController.text = estabelecimento.numero;
      _cepController.text = estabelecimento.cep ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _tituloController,
      _descricaoController,
      _cacheController,
      _cidadeController,
      _estadoController,
      _logradouroController,
      _numeroController,
      _cepController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validarCache(String? value) {
    final valor = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (valor == null || valor <= 0) return 'Informe um cachê válido.';
    return null;
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = _dataEvento;
    // Ao editar um evento que já passou, a data antiga precisa ser válida.
    final primeira = atual != null && atual.isBefore(hoje) ? atual : hoje;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: primeira,
      lastDate: DateTime(hoje.year + 2),
    );
    if (escolhida != null) setState(() => _dataEvento = escolhida);
  }

  Future<void> _salvar() async {
    final formOk = _formKey.currentState!.validate();
    final faltando = _dataEvento == null
        ? 'Escolha a data do evento.'
        : (_horaInicio == null || _horaFim == null)
        ? 'Escolha o horário de início e de fim.'
        : null;
    if (!formOk || faltando != null) {
      if (faltando != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(faltando)));
      }
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<OportunidadeProvider>();
    final estabelecimento = context
        .read<PerfilProvider>()
        .perfilEstabelecimento;
    final cep = _cepController.text.trim();
    final original = _original;

    final oportunidade = Oportunidade(
      id: original?.id ?? '',
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      cidade: _cidadeController.text.trim(),
      generoMusical: _genero!,
      dataEvento: _dataEvento!,
      horaInicio: _horaInicio,
      horaFim: _horaFim,
      cacheOferecido: double.parse(
        _cacheController.text.trim().replaceAll(',', '.'),
      ),
      // Admin pode editar a oportunidade de outro dono: mantém o contratante.
      contratante:
          original?.contratante ?? estabelecimento?.nome ?? auth.nomeExibicao,
      donoId: original?.donoId ?? auth.userId!,
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      estado: _estadoController.text.trim().toUpperCase(),
      cep: cep.isEmpty ? null : cep,
    );

    setState(() => _salvando = true);
    final ok = original != null
        ? await provider.atualizarOportunidade(oportunidade)
        : await provider.criarOportunidade(oportunidade, auth.userId!);
    if (!mounted) return;
    setState(() => _salvando = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Não foi possível salvar.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editando ? 'Oportunidade atualizada!' : 'Oportunidade publicada!',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = _dataEvento;
    final texto = Theme.of(context).textTheme;
    const espaco = SizedBox(height: AppSpacing.sm);
    const entreSecoes = SizedBox(height: AppSpacing.lg);

    if (_editando && _original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar oportunidade')),
        body: const EstadoVazio(
          icone: Icons.search_off,
          titulo: 'Oportunidade não encontrada.',
          mensagem: 'Ela pode ter sido removida.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar oportunidade' : 'Nova oportunidade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RotuloSecao('O evento', destaque: true),
              espaco,
              CustomTextField(
                controller: _tituloController,
                label: 'Título',
                icone: Icons.campaign_outlined,
                dica: 'Ex: Noite de MPB ao vivo',
                validator: (v) =>
                    Validators.validarCampoObrigatorio(v, 'o título'),
              ),
              espaco,
              DropdownButtonFormField<String>(
                initialValue: _genero,
                decoration: const InputDecoration(
                  labelText: 'Gênero musical',
                  prefixIcon: Icon(Icons.music_note_outlined),
                ),
                items: [
                  for (final genero in AppStrings.generosMusicais)
                    DropdownMenuItem(value: genero, child: Text(genero)),
                ],
                validator: (v) => v == null ? 'Escolha o gênero.' : null,
                onChanged: (v) => setState(() => _genero = v),
              ),
              espaco,
              CustomTextField(
                controller: _descricaoController,
                label: 'Descrição',
                dica: 'Estrutura do palco, público esperado, repertório...',
                linhas: 3,
                validator: (v) =>
                    Validators.validarCampoObrigatorio(v, 'a descrição'),
              ),
              entreSecoes,
              const RotuloSecao('Quando', destaque: true),
              espaco,
              OutlinedButton.icon(
                onPressed: _escolherData,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  data == null
                      ? 'Escolher data do evento'
                      : 'Data: ${formatarData(data)}',
                ),
              ),
              espaco,
              Row(
                children: [
                  Expanded(
                    child: CampoHorario(
                      rotulo: 'Início',
                      valor: _horaInicio,
                      onChanged: (v) => setState(() => _horaInicio = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CampoHorario(
                      rotulo: 'Fim',
                      valor: _horaFim,
                      onChanged: (v) => setState(() => _horaFim = v),
                    ),
                  ),
                ],
              ),
              entreSecoes,
              const RotuloSecao('Cachê', destaque: true),
              espaco,
              CustomTextField(
                controller: _cacheController,
                label: 'Cachê oferecido (R\$)',
                icone: Icons.payments_outlined,
                dica: 'Ex: 1500',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validarCache,
              ),
              entreSecoes,
              const RotuloSecao('Local', destaque: true),
              if (!_editando) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Preenchido com o endereço do seu estabelecimento; mude se '
                  'o show for em outro lugar.',
                  style: texto.bodySmall,
                ),
              ],
              espaco,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2:1 para o rótulo "Número" caber inteiro.
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _logradouroController,
                      label: 'Logradouro',
                      validator: (v) =>
                          Validators.validarCampoObrigatorio(v, 'o logradouro'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomTextField(
                      controller: _numeroController,
                      label: 'Número',
                      validator: (v) =>
                          Validators.validarCampoObrigatorio(v, 'o número'),
                    ),
                  ),
                ],
              ),
              espaco,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: _cidadeController,
                      label: 'Cidade',
                      validator: (v) =>
                          Validators.validarCampoObrigatorio(v, 'a cidade'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomTextField(
                      controller: _estadoController,
                      label: 'UF',
                      validator: (v) =>
                          Validators.validarCampoObrigatorio(v, 'o estado'),
                    ),
                  ),
                ],
              ),
              espaco,
              CustomTextField(
                controller: _cepController,
                label: 'CEP (opcional)',
                keyboardType: TextInputType.number,
              ),
              entreSecoes,
              PrimaryButton(
                text: _editando ? 'Salvar alterações' : 'Publicar oportunidade',
                icone: _editando ? Icons.check : Icons.campaign_outlined,
                carregando: _salvando,
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
