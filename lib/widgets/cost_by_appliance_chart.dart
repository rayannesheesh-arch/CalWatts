import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';
import 'package:calwatt/theme/app_theme.dart';

class CostByApplianceChart extends StatelessWidget {
  final List<Appliance> appliances;
  final double electricityRate;

  const CostByApplianceChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  double _calcCost(Appliance a) {
    if (!a.isOn || electricityRate <= 0) return 0;
    try {
      return CalculationService.calculateDailyConsumptionKwh(a, electricityRate).dailyCostPhp *
          a.quantity;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final onAppliances = appliances.where((a) => a.isOn).toList();

    if (onAppliances.isEmpty) {
      return _emptyCard(context);
    }

    final costData = onAppliances.map((a) => (appliance: a, cost: _calcCost(a))).toList()
      ..sort((a, b) => b.cost.compareTo(a.cost));

    final maxY = costData.every((d) => d.cost == 0)
        ? 10.0
        : costData.map((d) => d.cost).reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cost by Appliance', style: Theme.of(context).textTheme.titleMedium),
            Text('Daily cost (₱)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: List.generate(costData.length, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: costData[i].cost,
                        color: primary,
                        width: costData.length > 6 ? 8 : 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  )),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text('₱${v.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= 0 && i < costData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: SizedBox(
                                width: 50,
                                child: Text(
                                  costData[i].appliance.name,
                                  style: const TextStyle(fontSize: 8),
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

  Widget _emptyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cost by Appliance', style: Theme.of(context).textTheme.titleMedium),
            Text('Daily cost (₱)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            Center(child: Text('No appliances are currently ON', style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
