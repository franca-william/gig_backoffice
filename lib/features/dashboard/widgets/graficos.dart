import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import 'blocos.dart';

/// Uma linha (ou um grupo de barras) do gráfico.
class Serie {
  const Serie(this.nome, this.cor, this.valores);

  final String nome;
  final Color cor;
  final List<double> valores;
}

double _teto(Iterable<Serie> series) {
  final maior = series.expand((s) => s.valores).fold<double>(0, math.max);
  if (maior <= 0) return 4;
  // Folga de 15% e número "redondo" no topo.
  final bruto = maior * 1.15;
  final passo = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
  return (bruto / passo).ceil() * passo;
}

Widget _rotuloEixo(String texto) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(texto, style: GigTypography.caption),
    );

FlTitlesData _titulos({required List<String> rotulosX, required double teto}) => FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: teto / 4,
          getTitlesWidget: (valor, meta) => Text(valor.toStringAsFixed(0), style: GigTypography.caption),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (valor, meta) {
            final i = valor.round();
            if (i < 0 || i >= rotulosX.length || valor != i.toDouble()) return const SizedBox.shrink();
            return _rotuloEixo(rotulosX[i]);
          },
        ),
      ),
    );

FlGridData _grade(double teto) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: teto / 4,
      getDrawingHorizontalLine: (_) => const FlLine(color: CoresGrafico.grade, strokeWidth: 1),
    );

/// Linhas por semana (ex.: novos cadastros por perfil nas últimas 12 semanas).
class GraficoDeLinhas extends StatelessWidget {
  const GraficoDeLinhas({super.key, required this.series, required this.rotulosX, this.altura = 240});

  final List<Serie> series;
  final List<String> rotulosX;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final teto = _teto(series);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (series.length > 1) ...[
        Legenda(itens: {for (final s in series) s.nome: s.cor}),
        const SizedBox(height: GigSpacing.md),
      ],
      SizedBox(
        height: altura,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(rotulosX.length - 1, 1).toDouble(),
            minY: 0,
            maxY: teto,
            gridData: _grade(teto),
            borderData: FlBorderData(show: false),
            titlesData: _titulos(rotulosX: rotulosX, teto: teto),
            lineBarsData: [
              for (final s in series)
                LineChartBarData(
                  spots: [for (var i = 0; i < s.valores.length; i++) FlSpot(i.toDouble(), s.valores[i])],
                  color: s.cor,
                  barWidth: 2.5,
                  isCurved: false,
                  dotData: const FlDotData(show: true),
                ),
            ],
          ),
        ),
      ),
    ]);
  }
}

/// Barras verticais agrupadas: um grupo por rótulo do eixo X, uma barra por série.
class GraficoDeBarras extends StatelessWidget {
  const GraficoDeBarras({super.key, required this.series, required this.rotulosX, this.altura = 240});

  final List<Serie> series;
  final List<String> rotulosX;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final teto = _teto(series);
    final largura = series.length <= 1 ? 18.0 : (series.length == 2 ? 12.0 : 9.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (series.length > 1) ...[
        Legenda(itens: {for (final s in series) s.nome: s.cor}),
        const SizedBox(height: GigSpacing.md),
      ],
      SizedBox(
        height: altura,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: teto,
            alignment: BarChartAlignment.spaceAround,
            gridData: _grade(teto),
            borderData: FlBorderData(show: false),
            titlesData: _titulos(rotulosX: rotulosX, teto: teto),
            barGroups: [
              for (var i = 0; i < rotulosX.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    for (final s in series)
                      BarChartRodData(
                        toY: i < s.valores.length ? s.valores[i] : 0,
                        color: s.cor,
                        width: largura,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ]);
  }
}
