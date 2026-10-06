import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/painel_numeros.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../widgets/bloco_info.dart';
import '../../widgets/grafico_shows_por_mes.dart';
import '../../widgets/titulo_secao.dart';

/// "Meus números" (Plano 20): indicadores por papel e o gráfico de shows
/// realizados por mês. O músico vê o que tocou e recebeu; o dono, o que
/// contratou e pagou; o admin vê os dois.
class MeusNumerosScreen extends StatelessWidget {
  const MeusNumerosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.userId;
    final contratacoes = context.watch<ContratacaoProvider>().todas;
    final avaliacao = uid == null
        ? null
        : context.watch<AvaliacaoProvider>().resumoDe(uid);
    final agora = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Meus números')),
      body: uid == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                if (avaliacao != null && avaliacao.temAvaliacao)
                  BlocoInfo(
                    rotulo: 'Sua avaliação',
                    valor: avaliacao.rotulo.replaceFirst('★ ', ''),
                    icone: Icons.star_rounded,
                    cor: AppColors.estrela,
                  ),
                if (auth.atuaComoMusico)
                  _Secao(
                    titulo: 'Como músico',
                    numeros: calcularNumeros(
                      contratacoes,
                      uid: uid,
                      comoMusico: true,
                      agora: agora,
                    ),
                    ano: agora.year,
                    extras: [
                      _taxaAceite(
                        taxaDeAceite(
                          context.watch<InteresseProvider>().enviados,
                        ),
                      ),
                    ],
                    rotuloValor: 'Recebido em ${agora.year}',
                  ),
                if (auth.atuaComoDono)
                  _Secao(
                    titulo: 'Como contratante',
                    numeros: calcularNumeros(
                      contratacoes,
                      uid: uid,
                      comoMusico: false,
                      agora: agora,
                    ),
                    ano: agora.year,
                    extras: [
                      BlocoInfo(
                        rotulo: 'Oportunidades abertas',
                        valor:
                            '${context.watch<OportunidadeProvider>().minhasOportunidades(uid).where((o) => !o.vencida).length}',
                      ),
                    ],
                    rotuloValor: 'Pago em ${agora.year}',
                  ),
              ],
            ),
    );
  }

  static Widget _taxaAceite(double? taxa) => BlocoInfo(
    rotulo: taxa == null
        ? 'Aceite das candidaturas (nenhuma respondida)'
        : 'Aceite das candidaturas',
    valor: taxa == null ? '—' : '${(taxa * 100).round()}%',
  );
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.numeros,
    required this.ano,
    required this.extras,
    required this.rotuloValor,
  });

  final String titulo;
  final NumerosDoLado numeros;
  final int ano;
  final List<Widget> extras;
  final String rotuloValor;

  @override
  Widget build(BuildContext context) {
    final n = numeros;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloSecao(titulo),
          GradeBlocos(
            blocos: [
              // O dinheiro abre a grade, como nos protótipos.
              BlocoInfo(
                rotulo: rotuloValor,
                valor: formatarReais(n.valorNoAno),
                cor: context.cores.dinheiro,
              ),
              BlocoInfo(
                rotulo: 'Próximos confirmados',
                valor: '${n.proximos}',
                icone: Icons.event_available_outlined,
              ),
              BlocoInfo(rotulo: 'Shows no mês', valor: '${n.realizadosNoMes}'),
              BlocoInfo(rotulo: 'Shows em $ano', valor: '${n.realizadosNoAno}'),
              BlocoInfo(
                rotulo: 'Em negociação',
                valor: '${n.propostasPendentes}',
                cor: n.propostasPendentes > 0 ? AppColors.aviso : null,
              ),
              ...extras,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CardSecao(
            titulo: 'Shows realizados por mês',
            child: GraficoShowsPorMes(porMes: n.porMes),
          ),
        ],
      ),
    );
  }
}
