import 'package:flutter/material.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/calculation_service.dart';
import 'package:calwatt/theme/app_theme.dart';

class ApplianceCard extends StatelessWidget {
  final Appliance appliance;
  final double electricityRate;
  final VoidCallback? onToggle;
  final VoidCallback? onIncreaseQty;
  final VoidCallback? onDecreaseQty;
  final VoidCallback? onClone;

  const ApplianceCard({
    super.key,
    required this.appliance,
    required this.electricityRate,
    this.onToggle,
    this.onIncreaseQty,
    this.onDecreaseQty,
    this.onClone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);
    final isDark = theme.brightness == Brightness.dark;

    double dailyKwh = 0.0;
    double dailyCost = 0.0;
    if (electricityRate > 0) {
      final calc = CalculationService.calculateDailyConsumptionKwh(
        appliance,
        electricityRate,
      );
      dailyKwh = calc.dailyConsumptionKwh * appliance.quantity;
      dailyCost = calc.dailyCostPhp * appliance.quantity;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    appliance.category.icon,
                    color: primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appliance.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        appliance.category.label,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ON/OFF toggle
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: appliance.isOn,
                    onChanged: (_) => onToggle?.call(),
                    activeThumbColor: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _StatChip(
                  label: 'Wattage',
                  value:
                      '${(appliance.wattage * appliance.quantity).toStringAsFixed(0)} W',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Daily',
                  value: '${dailyKwh.toStringAsFixed(3)} kWh',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Cost',
                  value: '₱${dailyCost.toStringAsFixed(2)}',
                  valueColor: primary,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quantity + Clone row
            Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE5E7EB),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: appliance.quantity > 1 ? onDecreaseQty : null,
                        primary: primary,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${appliance.quantity}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: onIncreaseQty,
                        primary: primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  appliance.quantity == 1 ? 'unit' : 'units',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                // Clone button
                TextButton.icon(
                  onPressed: onClone,
                  icon: const Icon(Icons.copy_all, size: 16),
                  label: const Text('Clone'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(color: valueColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color primary;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? primary : Colors.grey,
        ),
      ),
    );
  }
}
