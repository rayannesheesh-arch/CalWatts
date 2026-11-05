import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';

class ConsumptionByApplianceChart extends StatelessWidget {
  final List<Appliance> appliances;
  final double electricityRate;

  const ConsumptionByApplianceChart({
    super.key,
    required this.appliances,
    required this.electricityRate,
  });

  double _calcKwh(Appliance a) {
    if (!a.isOn || electricityRate <= 0) return 0;
    try {
      return CalculationService.calculateDailyConsumptionKwh(a, electricityRate)
              .dailyConsumptionKwh *
          a.quantity;
    } catch (_) {
      return 0;
    }
  }

  Color _color(int i) {
    const colors = [
      Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFF59E0B),
      Color(0xFF8B5CF6), Color(0xFFEF4444), Color(0xFF14B8A6),
      Color(0xFFF97316), Color(0xFFEC4899),
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final onAppliances = appliances.where((a) => a.isOn).toList();

    if (onAppliances.isEmpty) {
      return _emptyCard(context, 'No appliances are currently ON');
    }

    final data = onAppliances.map(_calcKwh).toList();
    final total = data.fold<double>(0, (s, v) => s + v);

    if (total == 0) return _emptyCard(context, 'No consumption data');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumption by Appliance', style: Theme.of(context).textTheme.titleMedium),
            Text('Daily kWh share', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: List.generate(onAppliances.length, (i) {
                    final pct = data[i] / total * 100;
                    return PieChartSectionData(
                      value: data[i],
                      title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                      radius: 70,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      color: _color(i),
                    );
                  }),
                  centerSpaceRadius: 36,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: List.generate(onAppliances.length, (i) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _color(i), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      onAppliances[i].name,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumption by Appliance', style: Theme.of(context).textTheme.titleMedium),
            Text('Daily kWh share', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            Center(child: Text(msg, style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
