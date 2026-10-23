import 'package:flutter/material.dart';

/// Settings screen for configuration and app information.
///
/// Placeholder for FEAT-008 implementation. Will allow users to configure electricity rate,
/// view about section, and manage app preferences.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('Settings'),
      ),
    );
  }
}
