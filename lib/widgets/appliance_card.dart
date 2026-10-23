import 'package:flutter/material.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/services/calculation_service.dart';

/// Card widget displaying an appliance with its consumption data and ON/OFF toggle.
///
/// Shows appliance name, category icon, wattage, calculated daily kWh and cost,
/// and a toggle switch to turn the appliance ON/OFF. The card uses Material 3 styling.
class ApplianceCard extends StatelessWidget {
  /// The appliance to display.
  final Appliance appliance;

  /// Electricity rate in PHP per kWh (used for cost calculation).
  final double electricityRate;

  /// Callback when the ON/OFF toggle is pressed.
  final VoidCallback? onToggle;

  const ApplianceCard({
    super.key,
    required this.appliance,
    required this.electricityRate,
    this.onToggle,
  });

  /// Gets the icon for the appliance category.
  IconData _getCategoryIcon(ApplianceCategory category) {
    switch (category) {
      case ApplianceCategory.fan:
        return Icons.air;
      case ApplianceCategory.light:
        return Icons.lightbulb;
      case ApplianceCategory.television:
        return Icons.tv;
      case ApplianceCategory.refrigerator:
        return Icons.kitchen;
      case ApplianceCategory.riceCooker:
        return Icons.rice_bowl;
      case ApplianceCategory.airConditioner:
        return Icons.ac_unit;
    }
  }

  /// Gets the label for the appliance category.
  String _getCategoryLabel(ApplianceCategory category) {
    switch (category) {
      case ApplianceCategory.fan:
        return 'Fan';
      case ApplianceCategory.light:
        return 'Light';
      case ApplianceCategory.television:
        return 'TV';
      case ApplianceCategory.refrigerator:
        return 'Refrigerator';
      case ApplianceCategory.riceCooker:
        return 'Rice Cooker';
      case ApplianceCategory.airConditioner:
        return 'AC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate daily consumption and cost
    double dailyKwh = 0.0;
    double dailyCost = 0.0;

    try {
      final calculation = CalculationService.calculateDailyConsumptionKwh(
        appliance,
        electricityRate,
      );
      dailyKwh = calculation.dailyConsumptionKwh;
      dailyCost = calculation.dailyCostPhp;
    } catch (e) {
      // If calculation fails, display zero values
      dailyKwh = 0.0;
      dailyCost = 0.0;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Category, and Toggle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _getCategoryIcon(appliance.category),
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appliance.name,
                        style: textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getCategoryLabel(appliance.category),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ON/OFF Toggle
                Switch(
                  value: appliance.isOn,
                  onChanged: (_) {
                    onToggle?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Wattage and consumption info
            Row(
              children: [
                // Wattage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wattage',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appliance.wattage.toStringAsFixed(0)} W',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),

                // Daily consumption
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Est.',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dailyKwh.toStringAsFixed(3)} kWh',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),

                // Daily cost
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Est. Cost',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱${dailyCost.toStringAsFixed(2)}',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
