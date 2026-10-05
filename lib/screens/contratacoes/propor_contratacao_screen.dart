import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/data_hora.dart';
import '../../core/utils/validators.dart';
import '../../models/agenda_publica.dart';
import '../../models/contratacao.dart';
import '../../models/interesse.dart';
import '../../models/oportunidade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../widgets/campo_horario.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../busca/acoes_interesse.dart';

/// O dono propõe a contratação a partir de um interesse aceito. Data,
/// horário, cachê e local vêm pré-preenchidos da oportunidade (ou, sem
/// oportunidade, o local do estabelecimento). O músico confirma depois.
class ProporContratacaoScreen extends StatefulWidget {
  const ProporContratacaoScreen({super.key, required this.interesseId});

  final String interesseId;

  @override
  State<ProporContratacaoScreen> createState() =>
      _ProporContratacaoScreenState();
}

class _ProporContratacaoScreenState extends State<ProporContratacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cacheController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _preenchido = false;
  DateTime? _data;
  String? _horaInicio;
  String? _horaFim;
  AgendaPublica? _agenda;
  /// Enviando ou já enviada por esta tela. Nesse estado a proposta que o
  /// stream traz de volta é a nossa — não pode virar "já existe" (o Firestore
  /// atualiza o stream local antes de o servidor confirmar o `add`).
  bool _salvando = false;
  bool _enviada = false;

  /// Pré-preenche uma vez, quando os dados estiverem disponíveis: o
  /// interesse e a oportunidade podem chegar pelos streams depois que a tela
  /// abriu (providers são criados sob demanda).
  void _preencher(Interesse interesse, Oportunidade? oportunidade) {
    _preenchido = true;
    if (oportunidade != null) {
      _data = oportunidade.dataEvento;
      _horaInicio = oportunidade.horaInicio;
      _horaFim = oportunidade.horaFim;
      _cacheController.text = oportunidade.cacheOferecido.toStringAsFixed(2);
      _logradouroController.text = oportunidade.logradouro;
      _numeroController.text = oportunidade.numero;
      _cidadeController.text = oportunidade.cidade;
      _estadoController.text = oportunidade.estado;
    } else {
      final estabelecimento = context
          .read<PerfilProvider>()
          .perfilEstabelecimento;
      _logradouroController.text = estabelecimento?.logradouro ?? '';
      _numeroController.text = estabelecimento?.numero ?? '';
      _cidadeController.text = estabelecimento?.cidade ?? '';
      _estadoController.text = estabelecimento?.estado ?? '';
    }

    carregarAgendaPublica(context, interesse.musicoId).then((agenda) {
      if (mounted) setState(() => _agenda = agenda);
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _cacheController,
      _logradouroController,
      _numeroController,
      _cidadeController,
      _estadoController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = _data != null && !_data!.isBefore(hoje) ? _data! : hoje;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  String? _validarCache(String? value) {
    final valor = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (valor == null || valor <= 0) return 'Informe um cachê válido.';
    return null;
  }

  Future<void> _propor(Interesse interesse) async {
    final formOk = _formKey.currentState!.validate();
    final agora = DateTime.now();
    final data = _data;
    final faltando = data == null
        ? 'Escolha a data do show.'
        : data.isBefore(DateTime(agora.year, agora.month, agora.day))
        ? 'Escolha uma data a partir de hoje.'
        : (_horaInicio == null || _horaFim == null)
        ? 'Escolha o horário de início e de fim.'
        : null;
    if (!formOk || faltando != null) {
      if (faltando != null) _avisar(faltando);
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<ContratacaoProvider>();
    final estabelecimento = context
        .read<PerfilProvider>()
        .perfilEstabelecimento;
    final nomeDono = estabelecimento?.nome ?? auth.nomeExibicao;

    final contratacao = Contratacao(
      id: '',
      interesseId: interesse.id,
      musicoId: interesse.musicoId,
      musicoNome: interesse.musicoNome,
      donoId: auth.userId!,
      donoNome: nomeDono,
      oportunidadeId: interesse.oportunidadeId,
      titulo:
          interesse.oportunidadeTitulo ?? 'Show de ${interesse.musicoNome}',
      dia: Contratacao.diaDe(data!),
      horaInicio: _horaInicio!,
      horaFim: _horaFim!,
      cacheAcordado: double.parse(
        _cacheController.text.trim().replaceAll(',', '.'),
      ),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim().toUpperCase(),
      criadoEm: DateTime.now(),
    );

    setState(() => _salvando = true);
    final ok = await provider.propor(contratacao);
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _enviada = ok;
    });

    if (!ok) {
      _avisar(provider.errorMessage ?? 'Não foi possível enviar a proposta.');
      return;
    }
    _avisar('Proposta enviada! Aguarde a confirmação do músico.');
    Navigator.pop(context);
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final interesse = context.watch<InteresseProvider>().buscarPorId(
      widget.interesseId,
    );
    final oportunidadeId = interesse?.oportunidadeId;
    final oportunidades = context.watch<OportunidadeProvider>();
    final oportunidade = oportunidadeId == null
        ? null
        : oportunidades.buscarOportunidadePorId(oportunidadeId);
    // Com oportunidade vinculada, espera o catálogo trazê-la (a menos que ela
    // tenha sido removida: catálogo carregado e ela não está lá).
    final esperandoOportunidade =
        oportunidadeId != null &&
        oportunidade == null &&
        (oportunidades.carregandoOportunidades ||
            oportunidades.oportunidades.isEmpty);
    if (interesse != null && !_preenchido && !esperandoOportunidade) {
      _preencher(interesse, oportunidade);
    }
    final auth = context.watch<AuthProvider>();
    final ativaNoStream = context
        .watch<ContratacaoProvider>()
        .ativaParaInteresse(widget.interesseId);
    final ativa = _salvando || _enviada ? null : ativaNoStream;

    final motivoIndisponivel = interesse == null
        ? 'Interesse não encontrado.'
        : interesse.status != StatusInteresse.aceito
        ? 'Só é possível propor depois que o interesse for aceito.'
        : interesse.donoId != auth.userId
        ? 'Só o dono do estabelecimento propõe a contratação.'
        : ativa != null
        ? 'Já existe uma contratação ${ativa.rotuloStatus.toLowerCase()} para este interesse.'
        : null;

    if (motivoIndisponivel != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Propor contratação')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(motivoIndisponivel, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final data = _data;
    final aviso = data == null ? null : avisoAgenda(_agenda, data);

    return Scaffold(
      appBar: AppBar(title: const Text('Propor contratação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Show com ${interesse!.musicoNome}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (interesse.oportunidadeTitulo != null) ...[
                const SizedBox(height: 4),
                Text('Oportunidade: ${interesse.oportunidadeTitulo}'),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _escolherData,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  data == null
                      ? 'Escolher data do show'
                      : 'Data: ${formatarData(data)}',
                ),
              ),
              if (aviso != null) ...[
                const SizedBox(height: 8),
                Text(aviso, style: const TextStyle(color: AppColors.aviso)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CampoHorario(
                      rotulo: 'Início',
                      valor: _horaInicio,
                      onChanged: (v) => setState(() => _horaInicio = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoHorario(
                      rotulo: 'Fim',
                      valor: _horaFim,
                      onChanged: (v) => setState(() => _horaFim = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cacheController,
                label: 'Cachê acordado (R\$)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validarCache,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _logradouroController,
                label: 'Logradouro',
                validator: (v) =>
                    Validators.validarCampoObrigatorio(v, 'o logradouro'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _numeroController,
                label: 'Número',
                validator: (v) =>
                    Validators.validarCampoObrigatorio(v, 'o número'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cidadeController,
                label: 'Cidade',
                validator: (v) =>
                    Validators.validarCampoObrigatorio(v, 'a cidade'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _estadoController,
                label: 'Estado (UF)',
                validator: (v) =>
                    Validators.validarCampoObrigatorio(v, 'o estado'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _salvando ? 'Enviando...' : 'Enviar proposta',
                onPressed: _salvando ? null : () => _propor(interesse),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
