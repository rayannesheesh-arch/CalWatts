import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/services/calculation_service.dart';
import 'package:calwatt/widgets/stat_card.dart';
import 'package:calwatt/widgets/appliance_card.dart';
import 'package:calwatt/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final rate = appState.electricityRate;
        double dailyKwh = 0, monthlyCost = 0, dailyCost = 0, monthlyKwh = 0;
        if (rate > 0) {
          dailyKwh = _householdDailyKwh(appState);
          dailyCost = dailyKwh * rate;
          monthlyKwh = dailyKwh * 30;
          monthlyCost = dailyCost * 30;
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.bolt, color: AppTheme.primaryColor(context), size: 22),
                const SizedBox(width: 6),
                const Text('CalWatt'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                ),
                tooltip: appState.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: () => context.read<AppState>().toggleDarkMode(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rate <= 0)
                  _RateWarning(context: context),

                // Stats grid
                Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.flash_on,
                              label: 'Est. Daily Consumption',
                              value: dailyKwh.toStringAsFixed(2),
                              unit: 'kWh',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              icon: Icons.receipt_long,
                              label: 'Est. Daily Cost',
                              value: dailyCost.toStringAsFixed(2),
                              unit: '₱',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.calendar_month,
                              label: 'Est. Monthly Consumption',
                              value: monthlyKwh.toStringAsFixed(2),
                              unit: 'kWh',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              icon: Icons.trending_up,
                              label: 'Est. Monthly Cost',
                              value: monthlyCost.toStringAsFixed(2),
                              unit: '₱',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      'Appliances',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${appState.appliances.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (appState.appliances.isEmpty)
                  _EmptyAppliances()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appState.appliances.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final appliance = appState.appliances[index];
                      return ApplianceCard(
                        appliance: appliance,
                        electricityRate: rate,
                        onToggle: () =>
                            context.read<AppState>().toggleAppliance(appliance.id),
                        onIncreaseQty: () =>
                            context.read<AppState>().increaseQuantity(appliance.id),
                        onDecreaseQty: () =>
                            context.read<AppState>().decreaseQuantity(appliance.id),
                        onClone: () =>
                            context.read<AppState>().cloneAppliance(appliance.id),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _householdDailyKwh(AppState appState) {
    if (appState.electricityRate <= 0) return 0;
    double total = 0;
    for (final a in appState.appliances) {
      if (!a.isOn) continue;
      try {
        final calc = CalculationService.calculateDailyConsumptionKwh(
          a,
          appState.electricityRate,
        );
        total += calc.dailyConsumptionKwh * a.quantity;
      } catch (_) {}
    }
    return total;
  }
}

class _RateWarning extends StatelessWidget {
  final BuildContext context;
  const _RateWarning({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Electricity rate not set. Go to Settings to configure it.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAppliances extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.devices_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No appliances registered yet.\nGo to Appliances to add some.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
