import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';

/// Line chart showing estimated monthly consumption trend over 30 days.
///
/// Displays a 30-day projection based on the current appliance configuration
/// and operating schedules. Each point represents estimated daily consumption
/// for that day, with the line showing the trend.
class MonthlyProjectionChart extends StatelessWidget {
  /// List of appliances to calculate consumption for.
  final List<Appliance> appliances;

  /// Electricity rate in PHP per kWh (used for validation).
  final double electricityRate;

  const MonthlyProjectionChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  /// Calculates daily consumption for a specific day of the month.
  ///
  /// Uses the day-of-week (0=Monday) to determine which appliances operate.
  double _calculateDayConsumption(int dayOfMonth) {
    // Determine day of week from day of month (starting with a Monday on day 1)
    final dayOfWeek = dayOfMonth % 7;

    double total = 0.0;
    for (final appliance in appliances) {
      if (!appliance.isOn) continue;

      // Check if this appliance operates on this day of week
      if (appliance.operatingDays[dayOfWeek]) {
        try {
          final kw = CalculationService.kWFromWatts(appliance.wattage);
          final dailyKwh =
              CalculationService.kWhFromKwAndHours(kw, appliance.dailyOperatingHours);
          total += dailyKwh;
        } catch (e) {
          // Skip appliances with calculation errors
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Generate 30-day projection
    final List<FlSpot> spots = List.generate(
      30,
      (index) => FlSpot(
        index.toDouble(),
        _calculateDayConsumption(index),
      ),
    );

    // Find max for Y-axis scaling
    final maxValue = spots.isEmpty || spots.every((s) => s.y == 0)
        ? 10.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Monthly Projection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '30-Day Trend (kWh)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  spots: spots,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt() + 1;
                          if (day % 5 == 0 || day == 1) {
                            return Text(
                              'D$day',
                              style: const TextStyle(fontSize: 9),
                            );
                          }
                          return const Text('');
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green.shade600,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
