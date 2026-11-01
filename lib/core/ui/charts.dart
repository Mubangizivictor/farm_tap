// Charts use fl_chart; all colours and sizes come from the theme.
import 'package:farm_tap/core/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Line + soft area chart ("Milk this week"). [labels] is one per value.
/// The last point (or [highlightIndex]) gets a dot and a value tooltip.
class MilkLineChart extends StatelessWidget {
  const new({required this.values, required this.labels, super.key, this.highlightIndex, this.unit = 'L', this.height});

  final List<double> values;
  final List<String> labels;
  final int? highlightIndex;
  final String unit;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final line = context.colors.primary;
    final grid = context.colors.outlineVariant;
    final label = context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant);
    final maxY = _niceMax(values);
    final hi = highlightIndex ?? values.length - 1;
    return Padding(
      padding: EdgeInsets.only(right: context.space.xl),
      child: SizedBox(
        height: height ?? context.sizes.chartHeight,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            minX: 0,
            maxX: (values.length - 1).toDouble(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 3,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: grid, strokeWidth: context.sizes.borderThin, dashArray: [4, 4]),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: context.sizes.avatarMd,
                  interval: maxY / 3,
                  getTitlesWidget: (v, meta) => Text(v.round().toString(), style: label),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: context.sizes.iconLg,
                  interval: 1,
                  getTitlesWidget: (v, meta) {
                    final i = v.round();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: context.space.xs),
                      child: Text(labels[i], style: label),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => context.colors.inverseSurface,
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${s.y.round()} $unit',
                      context.text.labelLarge!.copyWith(
                        color: context.colors.onInverseSurface,
                        fontWeight: FarmTapWeights.bold,
                      ),
                    ),
                ],
              ),
            ),
            showingTooltipIndicators: [
              ShowingTooltipIndicators([
                LineBarSpot(
                  LineChartBarData(spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])]),
                  0,
                  FlSpot(hi.toDouble(), values[hi]),
                ),
              ]),
            ],
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                color: line,
                barWidth: context.sizes.borderThick * 1.5,
                isCurved: true,
                curveSmoothness: 0.2,
                dotData: FlDotData(
                  checkToShowDot: (spot, _) => spot.x.round() == hi,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: context.sizes.iconXs / 2,
                    color: context.colors.surface,
                    strokeColor: line,
                    strokeWidth: context.sizes.borderThick,
                  ),
                ),
                belowBarData: BarAreaData(show: true, color: line.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bars for sales / expenses / litres per day. [highlightIndex] bar is
/// drawn in the primary colour, the rest softer.
class FarmTapBarChart extends StatelessWidget {
  const new({required this.values, required this.labels, super.key, this.highlightIndex, this.height});

  final List<double> values;
  final List<String> labels;
  final int? highlightIndex;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final label = context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant);
    final maxY = _niceMax(values);
    final hi = highlightIndex ?? values.length - 1;
    return Padding(
      padding: EdgeInsets.only(right: context.space.sm),
      child: SizedBox(
        height: height ?? context.sizes.chartHeight,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            barTouchData: const BarTouchData(enabled: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 3,
              getDrawingHorizontalLine: (_) => FlLine(
                color: context.colors.outlineVariant,
                strokeWidth: context.sizes.borderThin,
                dashArray: [4, 4],
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: context.sizes.avatarMd,
                  interval: maxY / 3,
                  getTitlesWidget: (v, meta) => Text(v.round().toString(), style: label),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: context.sizes.iconLg,
                  getTitlesWidget: (v, meta) {
                    final i = v.round();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: context.space.xs),
                      child: Text(labels[i], style: label),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      width: context.space.xl,
                      color: i == hi ? context.colors.primary : context.colors.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(context.radii.xs)),
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

/// Top of the y axis: three equal steps, rounded up to whole litres.
double _niceMax(List<double> values) {
  final top = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
  final step = (top / 3).ceilToDouble().clamp(1, double.infinity);
  return step * 3;
}
