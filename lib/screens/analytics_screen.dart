import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/widgets/daily_consumption_chart.dart';
import 'package:calwatt/widgets/monthly_projection_chart.dart';
import 'package:calwatt/widgets/consumption_by_appliance_chart.dart';
import 'package:calwatt/widgets/cost_by_appliance_chart.dart';
import 'package:calwatt/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = context.read<AppState>().loadConsumptionHistory();
  }

  void _reloadHistory() {
    setState(() {
      _historyFuture = context.read<AppState>().loadConsumptionHistory();
    });
  }

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
                _ConsumptionHistory(
                  historyFuture: _historyFuture!,
                  onRefresh: _reloadHistory,
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

class _ConsumptionHistory extends StatelessWidget {
  const _ConsumptionHistory({
    required this.historyFuture,
    required this.onRefresh,
  });

  final Future<List<Map<String, dynamic>>> historyFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Consumption History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh history',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Could not load history: ${snapshot.error}');
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No recorded estimates yet. Saved calculations from your account will appear here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return Column(
                  children: records.take(20).map((record) {
                    final date = DateTime.tryParse(
                      record['recordedFor']?.toString() ??
                          record['createdAt']?.toString() ??
                          '',
                    );
                    final dateLabel = date == null
                        ? 'Date unavailable'
                        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final kwh = (record['kwh'] as num?)?.toDouble() ?? 0;
                    final cost = (record['cost'] as num?)?.toDouble() ?? 0;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_outlined),
                      title: Text(record['applianceName']?.toString() ?? 'Consumption estimate'),
                      subtitle: Text('$dateLabel · ${kwh.toStringAsFixed(3)} kWh'),
                      trailing: Text('₱${cost.toStringAsFixed(2)}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
