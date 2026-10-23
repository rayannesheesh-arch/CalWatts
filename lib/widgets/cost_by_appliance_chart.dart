import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';

/// Bar chart showing estimated daily cost contribution by each ON appliance.
///
/// Displays bars for each ON appliance, sorted in descending order by cost.
/// Bars are green and represent the daily cost contribution of each appliance
/// at the configured electricity rate.
class CostByApplianceChart extends StatelessWidget {
  /// List of appliances to calculate costs for.
  final List<Appliance> appliances;

  /// Electricity rate in PHP per kWh.
  final double electricityRate;

  const CostByApplianceChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  /// Calculates daily cost for a single ON appliance.
  double _calculateApplianceCost(Appliance appliance) {
    if (!appliance.isOn) return 0.0;

    try {
      final calculation = CalculationService.calculateDailyConsumptionKwh(
        appliance,
        electricityRate,
      );
      return calculation.dailyCostPhp;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter for ON appliances only
    final onAppliances = appliances.where((a) => a.isOn).toList();

    if (onAppliances.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost by Appliance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily Cost (₱)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No appliances are currently ON'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate cost for each ON appliance and create list of (appliance, cost) pairs
    final costData = onAppliances.map((a) {
      return (appliance: a, cost: _calculateApplianceCost(a));
    }).toList();

    // Sort descending by cost
    costData.sort((a, b) => b.cost.compareTo(a.cost));

    // Find max for Y-axis scaling
    final maxCost = costData.isEmpty || costData.every((d) => d.cost == 0)
        ? 10.0
        : costData.map((d) => d.cost).reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost by Appliance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily Cost (₱)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    costData.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: costData[index].cost,
                          color: Colors.green.shade500,
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
                            '₱${value.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < costData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                width: 60,
                                child: Text(
                                  costData[index].appliance.name,
                                  style: const TextStyle(fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
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
