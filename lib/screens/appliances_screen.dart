import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/screens/add_edit_appliance_screen.dart';
import 'package:calwatt/theme/app_theme.dart';

class AppliancesScreen extends StatelessWidget {
  const AppliancesScreen({super.key});

  void _showDeleteConfirmation(BuildContext context, Appliance appliance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appliance'),
        content: Text('Delete "${appliance.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().deleteAppliance(appliance.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditApplianceScreen()),
    );
  }

  void _openEdit(BuildContext context, Appliance appliance) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditApplianceScreen(appliance: appliance)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appliances'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, _) => IconButton(
              icon: Icon(
                appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              ),
              onPressed: () => context.read<AppState>().toggleDarkMode(),
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.appliances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No appliances registered yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAdd(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Appliance'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: appState.appliances.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final appliance = appState.appliances[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(appliance.category.icon, color: primary, size: 20),
                  ),
                  title: Text(
                    appliance.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    '${appliance.category.label} • ${appliance.wattage.toStringAsFixed(0)} W',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _openEdit(context, appliance);
                      if (value == 'delete') _showDeleteConfirmation(context, appliance);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ]),
                      ),
                    ],
                  ),
                  onTap: () => _openEdit(context, appliance),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
