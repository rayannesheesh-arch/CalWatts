import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/widgets/daily_consumption_chart.dart';
import 'package:calwatt/widgets/monthly_projection_chart.dart';
import 'package:calwatt/widgets/consumption_by_appliance_chart.dart';
import 'package:calwatt/widgets/cost_by_appliance_chart.dart';
import 'package:calwatt/theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, _) => IconButton(
              icon: Icon(appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
              onPressed: () => context.read<AppState>().toggleDarkMode(),
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DailyConsumptionChart(
                  appliances: appState.appliances,
                  electricityRate: appState.electricityRate,
                ),
                const SizedBox(height: 12),
                MonthlyProjectionChart(
                  appliances: appState.appliances,
                  electricityRate: appState.electricityRate,
                ),
                const SizedBox(height: 12),
                ConsumptionByApplianceChart(
                  appliances: appState.appliances,
                  electricityRate: appState.electricityRate,
                ),
                const SizedBox(height: 12),
                CostByApplianceChart(
                  appliances: appState.appliances,
                  electricityRate: appState.electricityRate,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.primaryColor(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All values are estimates based on appliance specifications and configured operating hours. Actual consumption may vary.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
