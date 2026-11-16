import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';
import 'package:calwatt/theme/app_theme.dart';

class MonthlyProjectionChart extends StatelessWidget {
  final List<Appliance> appliances;
  final double electricityRate;

  const MonthlyProjectionChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final today = DateTime.now();
    final spots = List.generate(30, (i) {
      final date = today.add(Duration(days: i));
      final kwh = CalculationService.calculateHouseholdConsumptionForDay(
        appliances,
        date.weekday - 1,
      );
      return FlSpot(i.toDouble(), kwh);
    });
    final maxY = spots.every((s) => s.y == 0)
        ? 10.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Projection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '30-day trend (kWh)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          final d = v.toInt() + 1;
                          return (d == 1 || d % 5 == 0)
                              ? Text('D$d', style: const TextStyle(fontSize: 9))
                              : const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
