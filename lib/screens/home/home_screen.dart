import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/lembrete_show.dart';
import '../../core/utils/painel_numeros.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/notificacao_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/grafico_shows_por_mes.dart' show resumoNumeros;
import '../../widgets/titulo_secao.dart';
import 'abas.dart';
import 'destaques_dono.dart';
import 'oportunidades_para_voce.dart';

/// "Bom dia" (5h–11h), "Boa tarde" (12h–17h) ou "Boa noite".
String saudacaoPara(DateTime agora) {
  if (agora.hour >= 5 && agora.hour < 12) return 'Bom dia';
  if (agora.hour >= 12 && agora.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// Início (Plano 8, Fase 1), no layout do protótipo: saudação, busca,
/// avisos do dia, acesso rápido e destaques pelo papel — sugestões para o
/// músico, próxima oportunidade e músicos para o dono (admin vê os dois).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contratacoes = context.watch<ContratacaoProvider>();
    final avaliacoes = context.watch<AvaliacaoProvider>();
    final uid = auth.userId;
    final agora = DateTime.now();

    // Plano 19: shows confirmados de hoje e amanhã (nada é gravado).
    final lembretes = uid == null
        ? const <LembreteShow>[]
        : lembretesDeShow(contratacoes.todas, uid: uid, agora: agora);
    // Plano 17: shows realizados ainda sem a avaliação do usuário.
    final paraAvaliar = avaliacoes.paraAvaliar(contratacoes.todas);
    // Plano 20: resumo do lado principal (músico, se atua como músico).
    final avaliacao = uid == null ? null : avaliacoes.resumoDe(uid);
    final resumo = uid == null
        ? null
        : resumoNumeros(
            calcularNumeros(
              contratacoes.todas,
              uid: uid,
              comoMusico: auth.atuaComoMusico,
              agora: agora,
            ),
            agora.year,
            avaliacao: avaliacao != null && avaliacao.temAvaliacao
                ? avaliacao.rotuloCurto
                : null,
          );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            _Cabecalho(saudacao: saudacaoPara(agora), nome: auth.nomeExibicao),
            const SizedBox(height: AppSpacing.md),
            const _CampoBusca(),
            const SizedBox(height: AppSpacing.lg),
            for (final lembrete in lembretes) _CardLembrete(lembrete),
            if (paraAvaliar.isNotEmpty)
              _CardAviso(
                icone: Icons.star_rounded,
                titulo: paraAvaliar.length == 1
                    ? 'Você tem 1 show para avaliar'
                    : 'Você tem ${paraAvaliar.length} shows para avaliar',
                detalhe: 'Até 30 dias depois do show.',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.contratacoes),
              ),
            if (lembretes.isNotEmpty || paraAvaliar.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            const TituloSecao('Acesso rápido'),
            const _AcessoRapido(),
            const SizedBox(height: AppSpacing.sm),
            _CardNumeros(resumo: resumo),
            const SizedBox(height: AppSpacing.lg),
            if (auth.atuaComoMusico) const OportunidadesParaVoce(),
            if (auth.atuaComoDono) const DestaquesDono(),
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.saudacao, required this.nome});

  final String saudacao;
  final String nome;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final naoLidas = context.watch<NotificacaoProvider>().naoLidas;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(saudacao, style: texto.bodySmall),
              Text(
                nome,
                style: texto.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notificações',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.notificacoes),
          icon: Badge(
            isLabelVisible: naoLidas > 0,
            label: Text('$naoLidas'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Tooltip(
          message: 'Meu perfil',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => irParaAba(context, AbaPrincipal.perfil),
            child: AvatarIniciais(nome: nome, tamanho: 44, circular: true),
          ),
        ),
      ],
    );
  }
}

/// Parece um campo, mas só leva à aba Buscar (onde ficam os filtros).
class _CampoBusca extends StatelessWidget {
  const _CampoBusca();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Semantics(
      button: true,
      label: 'Buscar músicos e oportunidades',
      excludeSemantics: true,
      child: Material(
        color: cores.superficieAlta,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
          side: BorderSide(color: cores.borda),
        ),
        child: InkWell(
          borderRadius: AppRadius.circular(AppRadius.md),
          onTap: () => irParaAba(context, AbaPrincipal.buscar),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: cores.textoSecundario),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Buscar músicos, oportunidades...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cores.textoTerciario,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plano 19: show de hoje (roxo) ou de amanhã.
class _CardLembrete extends StatelessWidget {
  const _CardLembrete(this.lembrete);

  final LembreteShow lembrete;

  @override
  Widget build(BuildContext context) {
    return _CardAviso(
      icone: lembrete.hoje ? Icons.music_note_rounded : Icons.event_rounded,
      titulo: lembrete.titulo,
      detalhe: lembrete.detalhe,
      corIcone: AppColors.primariaTexto,
      fundoIcone: AppColors.primariaContainer,
      destacado: lembrete.hoje,
      onTap: () => Navigator.pushNamed(context, AppRoutes.contratacoes),
    );
  }
}

class _CardAviso extends StatelessWidget {
  const _CardAviso({
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.onTap,
    this.corIcone = AppColors.estrela,
    this.fundoIcone = AppColors.avisoFundo,
    this.destacado = false,
  });

  final IconData icone;
  final String titulo;
  final String detalhe;
  final VoidCallback onTap;
  final Color corIcone;
  final Color fundoIcone;

  /// Borda roxa (show de hoje).
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: destacado
          ? RoundedRectangleBorder(
              borderRadius: AppRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.primaria),
            )
          : null,
      child: InkWell(
        borderRadius: AppRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fundoIcone,
                  borderRadius: AppRadius.circular(AppRadius.md),
                ),
                child: Icon(icone, color: corIcone),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleSmall),
                    const SizedBox(height: 2),
                    Text(detalhe, style: texto.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.cores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atalhos quadrados (protótipo): o que não está na barra inferior, com
/// selo de pendentes.
class _AcessoRapido extends StatelessWidget {
  const _AcessoRapido();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pendentes = context.watch<InteresseProvider>().pendentesRecebidos;
    final propostas = context.watch<ContratacaoProvider>().propostasPendentes;
    final denuncias = auth.isAdmin
        ? context.watch<DenunciaProvider>().pendentes
        : 0;

    final atalhos = [
      _Atalho(
        'Interesses',
        Icons.favorite_border_rounded,
        AppRoutes.interesses,
        pendentes,
      ),
      _Atalho(
        'Contratações',
        Icons.handshake_outlined,
        AppRoutes.contratacoes,
        propostas,
      ),
      if (auth.atuaComoDono)
        const _Atalho(
          'Minhas vagas',
          Icons.storefront_outlined,
          AppRoutes.minhasOportunidades,
          0,
          semantica: 'Minhas oportunidades',
        ),
      // Atalho para a aba Buscar, no que o papel procura.
      _Atalho(
        auth.atuaComoDono ? 'Músicos' : 'Oportunidades',
        auth.atuaComoDono ? Icons.mic_none_rounded : Icons.event_outlined,
        null,
        0,
        aba: AbaPrincipal.buscar,
      ),
      if (auth.isAdmin)
        _Atalho(
          'Denúncias',
          Icons.flag_outlined,
          AppRoutes.denuncias,
          denuncias,
        ),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        // 4 por linha em telas comuns; 3 nas bem estreitas.
        final porLinha = restricoes.maxWidth < 300 ? 3 : 4;
        final largura =
            (restricoes.maxWidth - AppSpacing.xs * (porLinha - 1)) / porLinha;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final atalho in atalhos.take(porLinha * 2))
              SizedBox(width: largura, child: _TileAtalho(atalho)),
          ],
        );
      },
    );
  }
}

class _Atalho {
  const _Atalho(
    this.rotulo,
    this.icone,
    this.rota,
    this.contador, {
    this.semantica,
    this.aba,
  });

  final String rotulo;
  final IconData icone;

  /// Rota aberta por cima; sem rota, troca para [aba].
  final String? rota;
  final AbaPrincipal? aba;
  final int contador;

  /// Nome completo para leitor de tela, quando o rótulo é abreviado.
  final String? semantica;
}

class _TileAtalho extends StatelessWidget {
  const _TileAtalho(this.atalho);

  final _Atalho atalho;

  @override
  Widget build(BuildContext context) {
    final contador = atalho.contador;
    return Semantics(
      button: true,
      label: [
        atalho.semantica ?? atalho.rotulo,
        if (contador > 0) '$contador pendentes',
      ].join(', '),
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: AppRadius.circular(AppRadius.lg),
          onTap: () {
            final rota = atalho.rota;
            if (rota != null) {
              Navigator.pushNamed(context, rota);
            } else if (atalho.aba != null) {
              irParaAba(context, atalho.aba!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm + 2,
              horizontal: AppSpacing.xxs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: contador > 0,
                  label: Text('$contador'),
                  child: Icon(atalho.icone, color: AppColors.primariaTexto),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Diminui um pouco em vez de cortar ("Oportunidades").
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    atalho.rotulo,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 0,
                      color: AppColors.texto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plano 20: atalho para "Meus números" com o resumo do ano.
class _CardNumeros extends StatelessWidget {
  const _CardNumeros({required this.resumo});

  final String? resumo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: const Icon(Icons.bar_chart_rounded, color: AppColors.sucesso),
        title: const Text('Meus números'),
        subtitle: resumo == null ? null : Text(resumo!),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, AppRoutes.meusNumeros),
      ),
    );
  }
}
