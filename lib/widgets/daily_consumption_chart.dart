import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';
import 'package:calwatt/theme/app_theme.dart';

class DailyConsumptionChart extends StatelessWidget {
  final List<Appliance> appliances;
  final double electricityRate;

  const DailyConsumptionChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  double _calcDay(int dayOfWeek) {
    double total = 0;
    for (final a in appliances) {
      if (!a.isOn) continue;
      if (!a.operatingDays[dayOfWeek]) continue;
      try {
        final kw = CalculationService.kWFromWatts(a.wattage);
        total += CalculationService.kWhFromKwAndHours(kw, a.dailyOperatingHours) * a.quantity;
      } catch (_) {}
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data = List.generate(7, _calcDay);
    final maxY = data.every((v) => v == 0) ? 10.0 : data.reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Consumption', style: Theme.of(context).textTheme.titleMedium),
            Text('Per day of week (kWh)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        color: primary,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  )),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          return i >= 0 && i < 7
                              ? Text(days[i], style: const TextStyle(fontSize: 10))
                              : const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
