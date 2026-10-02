import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/painel_numeros.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../widgets/grafico_shows_por_mes.dart';

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
              padding: const EdgeInsets.all(16),
              children: [
                if (avaliacao != null && avaliacao.temAvaliacao)
                  _Indicador(
                    valor: avaliacao.rotulo,
                    rotulo: 'Sua avaliação',
                    largo: true,
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
                        taxaDeAceite(context.watch<InteresseProvider>().enviados),
                      ),
                    ],
                    rotuloValor: 'Cachê recebido em ${agora.year}',
                    rotuloPropostas: 'Propostas em negociação',
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
                      _Indicador(
                        valor:
                            '${context.watch<OportunidadeProvider>().minhasOportunidades(uid).where((o) => !o.vencida).length}',
                        rotulo: 'Oportunidades abertas',
                      ),
                    ],
                    rotuloValor: 'Total pago em ${agora.year}',
                    rotuloPropostas: 'Propostas em negociação',
                  ),
              ],
            ),
    );
  }

  static Widget _taxaAceite(double? taxa) => _Indicador(
    valor: taxa == null ? '—' : '${(taxa * 100).round()}%',
    rotulo: taxa == null
        ? 'Aceite das candidaturas (nenhuma respondida)'
        : 'Aceite das candidaturas',
  );
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.numeros,
    required this.ano,
    required this.extras,
    required this.rotuloValor,
    required this.rotuloPropostas,
  });

  final String titulo;
  final NumerosDoLado numeros;
  final int ano;
  final List<Widget> extras;
  final String rotuloValor;
  final String rotuloPropostas;

  @override
  Widget build(BuildContext context) {
    final n = numeros;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.9,
            children: [
              _Indicador(
                valor: '${n.realizadosNoMes}',
                rotulo: 'Shows realizados no mês',
              ),
              _Indicador(
                valor: '${n.realizadosNoAno}',
                rotulo: 'Shows realizados em $ano',
              ),
              _Indicador(valor: formatarReais(n.valorNoAno), rotulo: rotuloValor),
              _Indicador(valor: '${n.proximos}', rotulo: 'Próximos confirmados'),
              _Indicador(
                valor: '${n.propostasPendentes}',
                rotulo: rotuloPropostas,
              ),
              ...extras,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Shows realizados por mês',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          GraficoShowsPorMes(porMes: n.porMes),
        ],
      ),
    );
  }
}

/// Um número grande com o rótulo embaixo.
class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.valor,
    required this.rotulo,
    this.largo = false,
  });

  final String valor;
  final String rotulo;

  /// Ocupa a linha toda (fora da grade).
  final bool largo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: largo ? const EdgeInsets.only(bottom: 4) : EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              rotulo,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
