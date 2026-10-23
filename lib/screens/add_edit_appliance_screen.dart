import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/services/appliance_service.dart';

/// Modal or page for adding/editing an appliance.
///
/// Provides a form for entering appliance details including name, category,
/// wattage, voltage, current, daily operating hours, operating days schedule,
/// and ON/OFF status. Includes validation and a "Calculate Wattage" button
/// for estimating watts from voltage and current.
class AddEditApplianceScreen extends StatefulWidget {
  /// The appliance to edit, or null to add a new appliance.
  final Appliance? appliance;

  const AddEditApplianceScreen({
    super.key,
    this.appliance,
  });

  @override
  State<AddEditApplianceScreen> createState() => _AddEditApplianceScreenState();
}

class _AddEditApplianceScreenState extends State<AddEditApplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _wattageController;
  late TextEditingController _voltageController;
  late TextEditingController _currentController;
  late TextEditingController _dailyHoursController;

  late ApplianceCategory _selectedCategory;
  late List<bool> _operatingDays;
  late bool _isOn;

  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final appliance = widget.appliance;

    _nameController = TextEditingController(text: appliance?.name ?? '');
    _wattageController = TextEditingController(
      text: appliance?.wattage.toStringAsFixed(0) ?? '',
    );
    _voltageController = TextEditingController(
      text: appliance?.voltage?.toStringAsFixed(0) ?? '',
    );
    _currentController = TextEditingController(
      text: appliance?.current?.toStringAsFixed(2) ?? '',
    );
    _dailyHoursController = TextEditingController(
      text: appliance?.dailyOperatingHours.toStringAsFixed(1) ?? '',
    );

    _selectedCategory = appliance?.category ?? ApplianceCategory.fan;
    _operatingDays = appliance?.operatingDays ?? [true, true, true, true, true, true, true];
    _isOn = appliance?.isOn ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    _voltageController.dispose();
    _currentController.dispose();
    _dailyHoursController.dispose();
    super.dispose();
  }

  /// Calculates wattage from voltage and current if both are provided.
  void _calculateWattage() {
    final voltage = double.tryParse(_voltageController.text);
    final current = double.tryParse(_currentController.text);

    if (voltage != null && voltage > 0 && current != null && current > 0) {
      final watts = voltage * current;
      _wattageController.text = watts.toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wattage calculated: ${watts.toStringAsFixed(2)} W'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide valid voltage and current values'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Saves the appliance (add or update).
  Future<void> _saveAppliance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final name = _nameController.text.trim();
      final wattage = double.parse(_wattageController.text);
      final voltage = _voltageController.text.trim().isEmpty
          ? null
          : double.tryParse(_voltageController.text);
      final current = _currentController.text.trim().isEmpty
          ? null
          : double.tryParse(_currentController.text);
      final dailyHours = double.parse(_dailyHoursController.text);

      final isEditing = widget.appliance != null;

      if (isEditing) {
        // Update existing appliance
        final updated = widget.appliance!.copyWith(
          name: name,
          category: _selectedCategory,
          wattage: wattage,
          voltage: voltage,
          current: current,
          dailyOperatingHours: dailyHours,
          operatingDays: _operatingDays,
          isOn: _isOn,
        );
        await ApplianceService.updateAppliance(updated);
        if (mounted) {
          context.read<AppState>().updateAppliance(updated);
        }
      } else {
        // Add new appliance
        await ApplianceService.addAppliance(
          name: name,
          category: _selectedCategory,
          wattage: wattage,
          voltage: voltage,
          current: current,
          dailyOperatingHours: dailyHours,
          operatingDays: _operatingDays,
          isOn: _isOn,
        );
        if (mounted) {
          await context.read<AppState>().refreshAppliances();
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Appliance updated successfully'
                  : 'Appliance added successfully',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving appliance: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appliance != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Appliance' : 'Add Appliance'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Living Room Fan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<ApplianceCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ApplianceCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryLabel(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Wattage field
                TextFormField(
                  controller: _wattageController,
                  decoration: const InputDecoration(
                    labelText: 'Wattage (W)',
                    hintText: 'e.g., 70',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wattage is required';
                    }
                    final wattage = double.tryParse(value);
                    if (wattage == null || wattage <= 0) {
                      return 'Wattage must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Voltage and Current row with Calculate button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _voltageController,
                        decoration: const InputDecoration(
                          labelText: 'Voltage (V)',
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _currentController,
                        decoration: const InputDecoration(
                          labelText: 'Current (A)',
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Calculate Wattage button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _calculateWattage,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculate Wattage'),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily operating hours field
                TextFormField(
                  controller: _dailyHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Operating Hours',
                    hintText: 'e.g., 6 (0-24)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Daily hours is required';
                    }
                    final hours = double.tryParse(value);
                    if (hours == null || hours < 0 || hours > 24) {
                      return 'Daily hours must be between 0 and 24';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Operating days checkboxes
                Text(
                  'Operating Days',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    return FilterChip(
                      label: Text(_dayLabels[index]),
                      selected: _operatingDays[index],
                      onSelected: (selected) {
                        setState(() {
                          _operatingDays[index] = selected;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // ON/OFF status toggle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Switch(
                          value: _isOn,
                          onChanged: (value) {
                            setState(() {
                              _isOn = value;
                            });
                          },
                        ),
                        Text(
                          _isOn ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isOn ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAppliance,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        isEditing ? 'Update Appliance' : 'Add Appliance',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to get display label for appliance category.
  String _getCategoryLabel(ApplianceCategory category) {
    switch (category) {
      case ApplianceCategory.fan:
        return 'Fan';
      case ApplianceCategory.light:
        return 'Light';
      case ApplianceCategory.television:
        return 'Television';
      case ApplianceCategory.refrigerator:
        return 'Refrigerator';
      case ApplianceCategory.riceCooker:
        return 'Rice Cooker';
      case ApplianceCategory.airConditioner:
        return 'Air Conditioner';
    }
  }
}
