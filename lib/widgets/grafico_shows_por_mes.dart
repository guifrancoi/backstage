import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/painel_numeros.dart';

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// Barras de shows realizados por mês (Plano 20, `fl_chart`). Uma série só:
/// sem legenda (o título da seção a nomeia), cor do tema, eixo e grade
/// discretos e tooltip ao tocar na barra. Sem nenhum show no período, mostra
/// uma frase no lugar do gráfico vazio.
class GraficoShowsPorMes extends StatelessWidget {
  const GraficoShowsPorMes({super.key, required this.porMes});

  final List<ShowsDoMes> porMes;

  static String rotuloMes(DateTime mes) => _meses[mes.month - 1];

  @override
  Widget build(BuildContext context) {
    final maior = porMes.fold(0, (m, s) => math.max(m, s.quantidade));
    if (maior == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Nenhum show realizado nesses meses.',
          style: TextStyle(color: AppColors.textoSecundario),
        ),
      );
    }

    final cor = Theme.of(context).colorScheme.primary;
    final intervalo = math.max(1, (maior / 4).ceil()).toDouble();
    final texto = Theme.of(context).textTheme.bodySmall;

    return Semantics(
      label:
          'Shows realizados por mês: '
          '${porMes.map((s) => '${rotuloMes(s.mes)} ${s.quantidade}').join(', ')}',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maior + intervalo,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: intervalo,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: AppColors.borda, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: intervalo,
                  getTitlesWidget: (valor, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(valor.toInt().toString(), style: texto),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (valor, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      rotuloMes(porMes[valor.toInt()].mes),
                      style: texto,
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.superficieAlta,
                getTooltipItem: (grupo, _, barra, _) {
                  final s = porMes[grupo.x];
                  final n = barra.toY.toInt();
                  return BarTooltipItem(
                    '$n show${n == 1 ? '' : 's'} em '
                    '${rotuloMes(s.mes)}/${s.mes.year}',
                    const TextStyle(color: AppColors.texto),
                  );
                },
              ),
            ),
            barGroups: [
              for (var i = 0; i < porMes.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: porMes[i].quantidade.toDouble(),
                      color: cor,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto do resumo da Home: "3 shows em 2026 · R$ 4.500 · ★ 4,6 (8)".
String resumoNumeros(NumerosDoLado n, int ano, {String? avaliacao}) {
  return [
    '${n.realizadosNoAno} show${n.realizadosNoAno == 1 ? '' : 's'} em $ano',
    formatarReais(n.valorNoAno),
    ?avaliacao,
  ].join(' · ');
}
