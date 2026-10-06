import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/interesse.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';

/// Interesses recebidos (aceitar/recusar) e enviados (cancelar).
class InteressesScreen extends StatelessWidget {
  const InteressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InteresseProvider>();
    final pendentes = provider.pendentesRecebidos;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interesses'),
          bottom: TabBar(
            tabs: [
              Tab(text: pendentes > 0 ? 'Recebidos ($pendentes)' : 'Recebidos'),
              const Tab(text: 'Enviados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaInteresses(
              interesses: provider.recebidos,
              recebidos: true,
              vazio: 'Ninguém demonstrou interesse em você ainda.',
            ),
            _ListaInteresses(
              interesses: provider.enviados,
              recebidos: false,
              vazio: 'Você ainda não enviou candidaturas ou convites.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaInteresses extends StatelessWidget {
  final List<Interesse> interesses;
  final bool recebidos;
  final String vazio;

  const _ListaInteresses({
    required this.interesses,
    required this.recebidos,
    required this.vazio,
  });

  @override
  Widget build(BuildContext context) {
    if (interesses.isEmpty) {
      return EstadoVazio(
        icone: recebidos ? Icons.inbox_outlined : Icons.outbox_outlined,
        titulo: recebidos ? 'Nada recebido ainda' : 'Nada enviado ainda',
        mensagem: vazio,
      );
    }

    return ListView.builder(
      padding: AppSpacing.tela,
      itemCount: interesses.length,
      itemBuilder: (context, index) =>
          _InteresseCard(interesse: interesses[index], recebido: recebidos),
    );
  }
}

class _InteresseCard extends StatelessWidget {
  final Interesse interesse;
  final bool recebido;

  const _InteresseCard({required this.interesse, required this.recebido});

  String get _titulo {
    final titulo = interesse.oportunidadeTitulo;
    final paraOportunidade = titulo == null ? '' : ' para "$titulo"';

    if (recebido) {
      if (interesse.tipo == TipoInteresse.convite) {
        return '${interesse.remetenteNome} convidou você$paraOportunidade';
      }
      // Nome artístico pode repetir entre contas; mostra também quem enviou.
      final artista = interesse.musicoNome;
      final conta = interesse.remetenteNome;
      final quem = conta.isNotEmpty && conta != artista
          ? '$artista ($conta)'
          : artista;
      return '$quem quer tocar$paraOportunidade';
    }
    return interesse.tipo == TipoInteresse.candidatura
        ? 'Candidatura$paraOportunidade'
        : 'Convite a ${interesse.musicoNome}$paraOportunidade';
  }

  /// "Candidatura · 05/10/2026" (e o motivo, quando cancelado).
  String get _detalhe {
    final tipo = interesse.tipo == TipoInteresse.candidatura
        ? 'Candidatura'
        : 'Convite';
    final partes = [
      tipo,
      formatarData(interesse.criadoEm),
      if (interesse.status == StatusInteresse.cancelado)
        'oportunidade removida',
      if (interesse.pendente && recebido) 'aguardando sua resposta',
    ];
    return partes.join(' · ');
  }

  (String, TipoEtiqueta) get _etiqueta => switch (interesse.status) {
    StatusInteresse.pendente => ('Pendente', TipoEtiqueta.aviso),
    StatusInteresse.aceito => ('Aceito', TipoEtiqueta.sucesso),
    StatusInteresse.recusado => ('Recusado', TipoEtiqueta.erro),
    StatusInteresse.cancelado => ('Cancelado', TipoEtiqueta.neutra),
  };

  /// Quem está do outro lado (recebidos) ou o ícone do tipo (enviados: o
  /// nome do destinatário não fica no interesse).
  Widget _avatar() {
    if (recebido) {
      final nome = interesse.tipo == TipoInteresse.candidatura
          ? interesse.musicoNome
          : interesse.remetenteNome;
      return AvatarIniciais(nome: nome, tamanho: 44);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.superficieAlta,
        borderRadius: AppRadius.circular(AppRadius.md),
      ),
      child: Icon(
        interesse.tipo == TipoInteresse.candidatura
            ? Icons.send_outlined
            : Icons.mail_outline,
        color: AppColors.primariaTexto,
      ),
    );
  }

  Future<void> _aceitar(BuildContext context) async {
    final provider = context.read<InteresseProvider>();
    final conversaId = await provider.aceitar(
      interesse,
      nomeDestinatario: context.read<AuthProvider>().nomeExibicao,
    );
    if (!context.mounted) return;

    if (conversaId == null) {
      _avisar(context, provider.errorMessage ?? 'Não foi possível aceitar.');
      return;
    }
    _avisar(context, 'Interesse aceito! A conversa foi aberta.');
    Navigator.pushNamed(context, AppRoutes.chat, arguments: conversaId);
  }

  Future<void> _recusar(BuildContext context) async {
    final provider = context.read<InteresseProvider>();
    final ok = await provider.recusar(
      interesse,
      nomeDestinatario: context.read<AuthProvider>().nomeExibicao,
    );
    if (!context.mounted) return;
    _avisar(
      context,
      ok
          ? 'Interesse recusado.'
          : provider.errorMessage ?? 'Não foi possível recusar.',
    );
  }

  Future<void> _cancelar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar envio'),
        content: const Text('Deseja cancelar este interesse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar envio'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final provider = context.read<InteresseProvider>();
    final ok = await provider.cancelar(interesse);
    if (!context.mounted) return;
    _avisar(
      context,
      ok
          ? 'Interesse cancelado.'
          : provider.errorMessage ?? 'Não foi possível cancelar.',
    );
  }

  /// Conversa do par (uma por par de usuários); recria se tiver sumido.
  Future<void> _abrirConversa(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<InteresseProvider>();
    final conversaId = await provider.abrirConversa(
      interesse,
      meuUid: auth.userId!,
      meuNome: auth.nomeExibicao,
    );
    if (!context.mounted) return;
    if (conversaId == null) {
      _avisar(
        context,
        provider.errorMessage ?? 'Não foi possível abrir a conversa.',
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.chat, arguments: conversaId);
  }

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final aceito = interesse.status == StatusInteresse.aceito;
    final uid = context.watch<AuthProvider>().userId;
    final podePropor =
        interesse.status == StatusInteresse.aceito &&
        interesse.donoId == uid &&
        context.watch<ContratacaoProvider>().ativaParaInteresse(interesse.id) ==
            null;
    final verPerfil = recebido && interesse.tipo == TipoInteresse.candidatura;
    final oportunidadeId = interesse.oportunidadeId;

    final (rotuloStatus, tipoStatus) = _etiqueta;
    final texto = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titulo, style: texto.titleSmall),
                      const SizedBox(height: 2),
                      Text(_detalhe, style: texto.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Etiqueta(rotuloStatus, tipo: tipoStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                if (verPerfil)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detalheMusico,
                      arguments: interesse.musicoId,
                    ),
                    child: const Text('Ver perfil'),
                  ),
                // Plano 16: o músico vê o perfil de quem o convidou ou de
                // quem recebeu a candidatura.
                if (interesse.donoId != uid)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detalheEstabelecimento,
                      arguments: interesse.donoId,
                    ),
                    child: const Text('Ver estabelecimento'),
                  ),
                if (!verPerfil && oportunidadeId != null)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detalheOportunidade,
                      arguments: oportunidadeId,
                    ),
                    child: const Text('Ver oportunidade'),
                  ),
                if (recebido && interesse.pendente) ...[
                  OutlinedButton(
                    onPressed: () => _recusar(context),
                    child: const Text('Recusar'),
                  ),
                  ElevatedButton(
                    onPressed: () => _aceitar(context),
                    child: const Text('Aceitar'),
                  ),
                ],
                if (!recebido && interesse.pendente)
                  OutlinedButton(
                    onPressed: () => _cancelar(context),
                    child: const Text('Cancelar'),
                  ),
                if (aceito)
                  ElevatedButton.icon(
                    onPressed: () => _abrirConversa(context),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Abrir conversa'),
                  ),
                if (podePropor)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.proporContratacao,
                      arguments: interesse.id,
                    ),
                    icon: const Icon(Icons.handshake_outlined),
                    label: const Text('Propor show'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
