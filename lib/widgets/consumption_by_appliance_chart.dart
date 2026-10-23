import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';

/// Pie chart showing each ON appliance's share of daily kWh consumption.
///
/// Only appliances with isOn=true are included in the chart. Each slice
/// represents the percentage of total household consumption for that appliance.
class ConsumptionByApplianceChart extends StatelessWidget {
  /// List of appliances to calculate consumption for.
  final List<Appliance> appliances;

  /// Electricity rate in PHP per kWh (used for validation).
  final double electricityRate;

  const ConsumptionByApplianceChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  /// Calculates daily consumption for a single ON appliance.
  double _calculateApplianceConsumption(Appliance appliance) {
    if (!appliance.isOn) return 0.0;

    try {
      final calculation = CalculationService.calculateDailyConsumptionKwh(
        appliance,
        electricityRate,
      );
      return calculation.dailyConsumptionKwh;
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
                'Consumption by Appliance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily kWh Share',
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

    // Calculate consumption for each ON appliance
    final consumptionData = onAppliances
        .map((a) => _calculateApplianceConsumption(a))
        .toList();

    final totalConsumption = consumptionData.fold<double>(0, (sum, val) => sum + val);

    if (totalConsumption == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consumption by Appliance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily kWh Share',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No consumption data available'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Create pie chart sections
    final pieSections = List.generate(onAppliances.length, (index) {
      final consumption = consumptionData[index];
      final percentage = (consumption / totalConsumption * 100).toStringAsFixed(1);
      final color = _getColorForIndex(index);

      return PieChartSectionData(
        value: consumption,
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: color,
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consumption by Appliance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily kWh Share',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(onAppliances.length, (index) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getColorForIndex(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      onAppliances[index].name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets a distinct color for each appliance index.
  Color _getColorForIndex(int index) {
    final colors = [
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.amber.shade400,
      Colors.pink.shade400,
    ];
    return colors[index % colors.length];
  }
}
