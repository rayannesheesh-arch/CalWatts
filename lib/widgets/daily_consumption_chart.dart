import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';

/// Bar chart showing estimated daily kWh consumption for each day of the week.
///
/// Each bar represents the estimated energy consumption for that day, calculated
/// based on appliance wattage, operating hours, and operating schedule.
/// Only ON appliances contribute to the calculation.
class DailyConsumptionChart extends StatelessWidget {
  /// List of appliances to calculate consumption for.
  final List<Appliance> appliances;

  /// Electricity rate in PHP per kWh (used for validation).
  final double electricityRate;

  const DailyConsumptionChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  /// Calculates daily consumption for a specific day of the week (0=Mon, 6=Sun).
  ///
  /// Sums up consumption from all ON appliances that operate on that day.
  double _calculateDayConsumption(int dayOfWeek) {
    double total = 0.0;
    for (final appliance in appliances) {
      if (!appliance.isOn) continue;

      // Check if this appliance operates on this day
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
    final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<double> dailyData =
        List.generate(7, (index) => _calculateDayConsumption(index));

    // Find max for Y-axis scaling
    final maxValue = dailyData.isEmpty || dailyData.every((v) => v == 0)
        ? 10.0
        : dailyData.reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Daily Consumption',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Per Day of Week (kWh)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    7,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dailyData[index],
                          color: Colors.green.shade400,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dayLabels.length) {
                            return Text(
                              dayLabels[index],
                              style: const TextStyle(fontSize: 10),
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
