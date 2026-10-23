import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/screens/add_edit_appliance_screen.dart';

/// Appliance management screen for adding, editing, viewing, and deleting appliances.
///
/// Displays a list of registered appliances with options to add new, edit, and delete.
/// Each appliance card shows name, category icon, and wattage. Uses a floating action
/// button to add new appliances and context menu actions for edit and delete operations.
class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({super.key});

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  /// Gets the icon for an appliance category.
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'fan':
        return Icons.air;
      case 'light':
        return Icons.light_mode;
      case 'television':
        return Icons.tv;
      case 'refrigerator':
        return Icons.kitchen;
      case 'riceCooker':
        return Icons.rice_bowl;
      case 'airConditioner':
        return Icons.ac_unit;
      default:
        return Icons.devices;
    }
  }

  /// Gets the display label for an appliance category.
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'fan':
        return 'Fan';
      case 'light':
        return 'Light';
      case 'television':
        return 'Television';
      case 'refrigerator':
        return 'Refrigerator';
      case 'riceCooker':
        return 'Rice Cooker';
      case 'airConditioner':
        return 'Air Conditioner';
      default:
        return category;
    }
  }

  /// Shows a confirmation dialog before deleting an appliance.
  void _showDeleteConfirmation(BuildContext context, Appliance appliance) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appliance'),
          content: Text('Are you sure you want to delete "${appliance.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAppliance(context, appliance.id);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Deletes an appliance and updates the UI.
  Future<void> _deleteAppliance(BuildContext context, String id) async {
    try {
      await context.read<AppState>().deleteAppliance(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appliance deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appliance: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Opens the add appliance screen.
  void _openAddScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditApplianceScreen(),
      ),
    );
  }

  /// Opens the edit appliance screen.
  void _openEditScreen(BuildContext context, Appliance appliance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditApplianceScreen(appliance: appliance),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appliances'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.appliances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appliances registered yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAddScreen(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Appliance'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: appState.appliances.length,
            itemBuilder: (context, index) {
              final appliance = appState.appliances[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getCategoryIcon(appliance.category.name),
                    color: Colors.green[700],
                  ),
                  title: Text(appliance.name),
                  subtitle: Text(
                    '${_getCategoryLabel(appliance.category.name)} • ${appliance.wattage.toStringAsFixed(0)} W',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openEditScreen(context, appliance);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, appliance);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _openEditScreen(context, appliance);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddScreen(context),
        tooltip: 'Add Appliance',
        child: const Icon(Icons.add),
      ),
    );
  }
}
