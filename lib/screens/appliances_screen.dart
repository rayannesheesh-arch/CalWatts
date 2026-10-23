import 'package:flutter/material.dart';

/// Appliance management screen for adding, editing, viewing, and deleting appliances.
///
/// Placeholder for FEAT-006 implementation. Will display list of registered appliances
/// with options to add, edit, delete, and view details.
class AppliancesScreen extends StatelessWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appliances'),
      ),
      body: const Center(
        child: Text('Appliances'),
      ),
    );
  }
}
