import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/widgets/daily_consumption_chart.dart';
import 'package:calwatt/widgets/monthly_projection_chart.dart';
import 'package:calwatt/widgets/consumption_by_appliance_chart.dart';
import 'package:calwatt/widgets/cost_by_appliance_chart.dart';

/// Analytics screen displaying charts and consumption analysis.
///
/// Shows four interactive charts with real calculated data:
/// - Daily consumption by day of week (BarChart)
/// - Monthly projection over 30 days (LineChart)
/// - Consumption share by appliance (PieChart)
/// - Cost contribution by appliance (BarChart)
///
/// All charts update automatically when appliances, schedules, or electricity
/// rates change. Uses Consumer<AppState> to listen for state changes.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _lastUpdated;

  @override
  void initState() {
    super.initState();
    _lastUpdated = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          // Update timestamp when state changes
          _lastUpdated = DateTime.now();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Consumption Chart
                  DailyConsumptionChart(
                    appliances: appState.appliances,
                    electricityRate: appState.electricityRate,
                  ),
                  const SizedBox(height: 16),

                  // Monthly Projection Chart
                  MonthlyProjectionChart(
                    appliances: appState.appliances,
                    electricityRate: appState.electricityRate,
                  ),
                  const SizedBox(height: 16),

                  // Consumption by Appliance Chart
                  ConsumptionByApplianceChart(
                    appliances: appState.appliances,
                    electricityRate: appState.electricityRate,
                  ),
                  const SizedBox(height: 16),

                  // Cost by Appliance Chart
                  CostByApplianceChart(
                    appliances: appState.appliances,
                    electricityRate: appState.electricityRate,
                  ),
                  const SizedBox(height: 24),

                  // Last Updated and Disclaimer
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimation Notice',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All values displayed on this screen are estimates based on appliance specifications, '
                            'operating schedules, and the configured electricity rate. Actual electricity consumption '
                            'may vary significantly based on real usage patterns, device efficiency, weather conditions, '
                            'and other environmental factors. This application does not measure actual electricity usage.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Last Updated: ${_lastUpdated.hour.toString().padLeft(2, '0')}:'
                            '${_lastUpdated.minute.toString().padLeft(2, '0')}:'
                            '${_lastUpdated.second.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
