import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, _) => IconButton(
              icon: Icon(appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
              tooltip: appState.isDarkMode ? 'Light Mode' : 'Dark Mode',
              onPressed: () => context.read<AppState>().toggleDarkMode(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance
            Text('Appearance', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Card(
              child: Consumer<AppState>(
                builder: (context, appState, _) => SwitchListTile(
                  secondary: Icon(
                    appState.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                    color: primary,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(appState.isDarkMode ? 'Night theme active' : 'Day theme active'),
                  value: appState.isDarkMode,
                  activeThumbColor: primary,
                  onChanged: (_) => context.read<AppState>().toggleDarkMode(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Account & Sync', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Card(
              child: Consumer<AppState>(
                builder: (context, appState, _) => Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person_outline, color: primary),
                      title: Text(appState.currentUser?['fullName']?.toString() ?? 'CalWatt account'),
                      subtitle: Text(appState.currentUser?['email']?.toString() ?? ''),
                    ),
                    ListTile(
                      leading: Icon(
                        appState.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                        color: appState.isOnline ? primary : theme.colorScheme.error,
                      ),
                      title: Text(appState.isOnline ? 'Connected' : 'Offline'),
                      subtitle: Text(
                        appState.pendingChangesCount == 0
                            ? 'All changes are synced'
                            : '${appState.pendingChangesCount} change(s) waiting to sync',
                      ),
                      trailing: IconButton(
                        tooltip: 'Sync now',
                        onPressed: appState.isSyncing ? null : appState.syncNow,
                        icon: appState.isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                      ),
                    ),
                    if (appState.syncError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            appState.syncError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.bolt_outlined, color: primary),
                      title: const Text('Electricity rate'),
                      subtitle: const Text('Managed by your CalWatt administrator'),
                      trailing: Text('₱${appState.electricityRate.toStringAsFixed(2)}/kWh'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: primary),
                      title: const Text('Sign out'),
                      onTap: appState.logout,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // About
            Text('About CalWatt', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt, color: primary, size: 24),
                        const SizedBox(width: 8),
                        Text('CalWatt', style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'CalWatt is an electricity consumption calculator and monitoring application for homes, offices, warehouses, and commercial buildings. It supports SDG 7: Affordable and Clean Energy.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: const Text('SDG 7'),
                          backgroundColor: primary.withValues(alpha: 0.12),
                          labelStyle: TextStyle(color: primary, fontSize: 12),
                        ),
                        Chip(
                          label: const Text('Philippines ₱'),
                          backgroundColor: primary.withValues(alpha: 0.12),
                          labelStyle: TextStyle(color: primary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Limitations
            Text('Estimation Limitations', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All calculations are estimates based on nameplate wattage and configured operating hours. Actual consumption may vary. This app does not interface with physical meters.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade900),
                            ),
                          ),
                        ],
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
  }
}
