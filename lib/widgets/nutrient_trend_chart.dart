import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Phase 4: weekly nutrient % vs DRI line chart. Drop into the tracker
/// screen with a list of (day, percent) points. Uses fl_chart so the same
/// widget renders on iOS, Android, and the upcoming watch surface.
class NutrientTrendChart extends StatelessWidget {
  const NutrientTrendChart({
    super.key,
    required this.points,
    this.targetPercent = 100,
    this.height = 180,
  });

  final List<NutrientTrendPoint> points;
  final double targetPercent;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('No data')));
    }
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].percent),
    ];
    final maxY = (spots.map((s) => s.y).fold<double>(targetPercent, (a, b) => a > b ? a : b)) + 10;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: targetPercent,
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
              dashArray: const [4, 4],
            ),
          ]),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2,
              color: Theme.of(context).colorScheme.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NutrientTrendPoint {
  const NutrientTrendPoint({required this.label, required this.percent});
  final String label;
  final double percent;
}
