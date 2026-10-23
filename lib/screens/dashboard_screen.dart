import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/services/calculation_service.dart';
import 'package:calwatt/widgets/stat_card.dart';
import 'package:calwatt/widgets/appliance_card.dart';

/// Dashboard screen showing energy consumption and cost overview.
///
/// Displays estimated daily and monthly consumption and costs for the household,
/// total appliance count, and a scrollable list of appliance cards with quick
/// status toggles. All values update automatically when appliances, schedules,
/// statuses, or electricity rates change.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AppState appState;

  @override
  void initState() {
    super.initState();
    // Listen to AppState changes to trigger rebuilds
    appState = context.read<AppState>();
    appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    // Rebuild when app state changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Calculate household metrics
        final householdDailyKwh = CalculationService.getHouseholdDaily(
          appState.appliances,
          appState.electricityRate,
        );
        final householdMonthlyKwh = CalculationService.getHouseholdMonthly(
          appState.appliances,
          appState.electricityRate,
        );
        final householdDailyCost = CalculationService.getHouseholdDailyCost(
          appState.appliances,
          appState.electricityRate,
        );
        final householdMonthlyCost = CalculationService.getHouseholdMonthlyCost(
          appState.appliances,
          appState.electricityRate,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metric Cards (2x2 grid)
                  GridView(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        icon: Icons.flash_on,
                        label: 'Est. Daily Consumption',
                        value: householdDailyKwh.toStringAsFixed(2),
                        unit: 'kWh',
                      ),
                      StatCard(
                        icon: Icons.receipt,
                        label: 'Est. Daily Cost',
                        value: householdDailyCost.toStringAsFixed(2),
                        unit: '₱',
                      ),
                      StatCard(
                        icon: Icons.calendar_month,
                        label: 'Est. Monthly Consumption',
                        value: householdMonthlyKwh.toStringAsFixed(2),
                        unit: 'kWh',
                      ),
                      StatCard(
                        icon: Icons.trending_up,
                        label: 'Est. Monthly Cost',
                        value: householdMonthlyCost.toStringAsFixed(2),
                        unit: '₱',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Total Appliances section
                  Text(
                    'Appliances (${appState.appliances.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  // Appliance cards list
                  if (appState.appliances.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No appliances registered yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appState.appliances.length,
                      itemBuilder: (context, index) {
                        final appliance = appState.appliances[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ApplianceCard(
                            appliance: appliance,
                            electricityRate: appState.electricityRate,
                            onToggle: () {
                              context.read<AppState>().toggleAppliance(appliance.id);
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
