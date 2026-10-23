import 'package:flutter/material.dart';

/// Dashboard screen showing energy consumption and cost overview.
///
/// Placeholder for FEAT-005 implementation. Will display estimated daily and
/// monthly consumption, costs, appliance counts, and quick status toggles.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Text('Dashboard'),
      ),
    );
  }
}
