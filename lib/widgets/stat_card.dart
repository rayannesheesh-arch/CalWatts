import 'package:flutter/material.dart';

/// Reusable card widget for displaying a single metric.
///
/// Shows a metric with an icon, label, and large value with unit.
/// Uses Material 3 styling with white background, subtle shadow, and green accent.
class StatCard extends StatelessWidget {
  /// Icon to display at the top of the card.
  final IconData icon;

  /// Label describing the metric (e.g., "Est. Daily Consumption").
  final String label;

  /// The main value to display (large font).
  final String value;

  /// Unit of measurement (e.g., "kWh", "₱").
  final String unit;

  /// Background color for the icon (defaults to light green).
  final Color? iconBackgroundColor;

  /// Icon color (defaults to primary green).
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with circular background
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor ?? colorScheme.primary.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: iconColor ?? colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // Label
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),

            // Value and unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF1F2937),
                    fontSize: 28,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
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
