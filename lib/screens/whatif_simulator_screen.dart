import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/energy_calculation.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/services/calculation_service.dart';

/// What-If Savings Simulator screen.
///
/// Allows users to simulate turning an appliance off or changing its operating hours
/// without modifying the original appliance settings. Displays a side-by-side comparison
/// of original vs proposed scenarios with estimated savings.
class WhatIfSimulatorScreen extends StatefulWidget {
  const WhatIfSimulatorScreen({super.key});

  @override
  State<WhatIfSimulatorScreen> createState() => _WhatIfSimulatorScreenState();
}

class _WhatIfSimulatorScreenState extends State<WhatIfSimulatorScreen> {
  Appliance? _selectedAppliance;
  SimulationMode _simulationMode = SimulationMode.turnOff;
  final TextEditingController _hoursController = TextEditingController();
  EnergyCalculation? _originalCalculation;
  EnergyCalculation? _proposedCalculation;
  bool _hasSimulated = false;

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  /// Enum to track simulation mode.
  void _updateSimulation() {
    final appState = context.read<AppState>();
    if (_selectedAppliance == null || appState.electricityRate <= 0) {
      return;
    }

    try {
      // Calculate original scenario
      _originalCalculation = CalculationService.calculateDailyConsumptionKwh(
        _selectedAppliance!,
        appState.electricityRate,
      );

      // Create proposed appliance based on simulation mode
      Appliance proposedAppliance;
      if (_simulationMode == SimulationMode.turnOff) {
        proposedAppliance = _selectedAppliance!.copyWith(isOn: false);
      } else {
        // Change hours mode
        final newHours =
            double.tryParse(_hoursController.text) ?? _selectedAppliance!.dailyOperatingHours;
        proposedAppliance = _selectedAppliance!.copyWith(dailyOperatingHours: newHours);
      }

      // Calculate proposed scenario
      _proposedCalculation = CalculationService.calculateDailyConsumptionKwh(
        proposedAppliance,
        appState.electricityRate,
      );

      setState(() {
        _hasSimulated = true;
      });
    } catch (e) {
      _showErrorSnackBar('Error calculating simulation: $e');
    }
  }

  /// Shows a confirmation dialog before applying changes.
  void _showApplyConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Changes?'),
        content: Text('This will update the ${_selectedAppliance!.name} settings. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyChanges();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Applies the simulated changes to the appliance.
  Future<void> _applyChanges() async {
    if (_selectedAppliance == null) return;

    try {
      final appState = context.read<AppState>();
      Appliance updatedAppliance;

      if (_simulationMode == SimulationMode.turnOff) {
        updatedAppliance = _selectedAppliance!.copyWith(isOn: false);
      } else {
        final newHours =
            double.tryParse(_hoursController.text) ?? _selectedAppliance!.dailyOperatingHours;
        updatedAppliance = _selectedAppliance!.copyWith(dailyOperatingHours: newHours);
      }

      await appState.updateAppliance(updatedAppliance);
      _selectedAppliance = updatedAppliance;

      if (mounted) {
        _showSuccessSnackBar('Changes applied successfully!');
        _resetSimulation();
      }
    } catch (e) {
      _showErrorSnackBar('Error applying changes: $e');
    }
  }

  /// Cancels the simulation and resets state.
  void _cancelSimulation() {
    _resetSimulation();
    _showInfoSnackBar('Simulation cancelled.');
  }

  /// Resets simulation state without saving changes.
  void _resetSimulation() {
    setState(() {
      _hasSimulated = false;
      _hoursController.clear();
      _simulationMode = SimulationMode.turnOff;
      _originalCalculation = null;
      _proposedCalculation = null;
    });
  }

  /// Shows error snack bar.
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows success snack bar.
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows info snack bar.
  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What-If Simulator'), centerTitle: true, elevation: 0),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Simulate changes to see potential energy and cost savings without modifying your appliances.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Appliance selection dropdown
                Text('Select Appliance', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                DropdownButton<Appliance>(
                  value: _selectedAppliance,
                  isExpanded: true,
                  hint: const Text('Choose an appliance'),
                  items: appState.appliances
                      .map(
                        (appliance) =>
                            DropdownMenuItem(value: appliance, child: Text(appliance.name)),
                      )
                      .toList(),
                  onChanged: (appliance) {
                    setState(() {
                      _selectedAppliance = appliance;
                      _resetSimulation();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Simulation mode selection
                if (_selectedAppliance != null) ...[
                  Text('Simulation Mode', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<SimulationMode>(
                          title: const Text('Turn Off'),
                          subtitle: Text(
                            'Simulate turning off ${_selectedAppliance!.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: SimulationMode.turnOff,
                          groupValue: _simulationMode,
                          onChanged: (value) {
                            setState(() {
                              _simulationMode = value!;
                              _resetSimulation();
                              _hoursController.clear();
                            });
                          },
                        ),
                        RadioListTile<SimulationMode>(
                          title: const Text('Change Operating Hours'),
                          subtitle: Text(
                            'Simulate different daily operating hours',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: SimulationMode.changeHours,
                          groupValue: _simulationMode,
                          onChanged: (value) {
                            setState(() {
                              _simulationMode = value!;
                              _resetSimulation();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hours input field (shown only when "Change Hours" is selected)
                  if (_simulationMode == SimulationMode.changeHours) ...[
                    Text(
                      'New Daily Operating Hours',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter hours (0-24)',
                        helperText: 'Current: ${_selectedAppliance!.dailyOperatingHours} hours',
                        suffixText: 'hours',
                      ),
                      onChanged: (_) => _updateSimulation(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Simulation button
                  if (_simulationMode == SimulationMode.turnOff && !_hasSimulated)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _updateSimulation,
                        icon: const Icon(Icons.calculate),
                        label: const Text('Calculate Savings'),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Comparison display
                  if (_hasSimulated &&
                      _originalCalculation != null &&
                      _proposedCalculation != null) ...[
                    _buildComparisonSection(context),
                    const SizedBox(height: 24),
                    _buildActionsSection(),
                  ],
                ],

                if (_selectedAppliance == null && appState.appliances.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No appliances available.',
                        style: Theme.of(context).textTheme.bodyMedium,
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

  /// Builds the comparison section showing original vs proposed scenarios.
  Widget _buildComparisonSection(BuildContext context) {
    final originalDaily = _originalCalculation!.dailyConsumptionKwh;
    final proposedDaily = _proposedCalculation!.dailyConsumptionKwh;
    final dailySavingsKwh = originalDaily - proposedDaily;
    final dailySavingsPercent = originalDaily > 0 ? (dailySavingsKwh / originalDaily * 100) : 0;

    final originalCost = _originalCalculation!.dailyCostPhp;
    final proposedCost = _proposedCalculation!.dailyCostPhp;
    final costSavingsPhp = originalCost - proposedCost;
    final costSavingsPercent = originalCost > 0 ? (costSavingsPhp / originalCost * 100) : 0;

    final originalMonthlyCost = _originalCalculation!.monthlyCostPhp;
    final proposedMonthlyCost = _proposedCalculation!.monthlyCostPhp;
    final monthlySavingsPhp = originalMonthlyCost - proposedMonthlyCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comparison: Original vs Proposed', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Daily Energy Consumption
        _buildComparisonCard(
          context,
          title: 'Daily Energy Consumption (kWh)',
          original: originalDaily.toStringAsFixed(3),
          proposed: proposedDaily.toStringAsFixed(3),
          savings: dailySavingsKwh.toStringAsFixed(3),
          savingsPercent: dailySavingsPercent,
        ),
        const SizedBox(height: 12),

        // Daily Cost
        _buildComparisonCard(
          context,
          title: 'Daily Electricity Cost (₱)',
          original: originalCost.toStringAsFixed(2),
          proposed: proposedCost.toStringAsFixed(2),
          savings: costSavingsPhp.toStringAsFixed(2),
          savingsPercent: costSavingsPercent,
        ),
        const SizedBox(height: 12),

        // Monthly Energy Consumption
        _buildComparisonCard(
          context,
          title: 'Monthly Energy Consumption (kWh)',
          original: _originalCalculation!.monthlyConsumptionKwh.toStringAsFixed(3),
          proposed: _proposedCalculation!.monthlyConsumptionKwh.toStringAsFixed(3),
          savings: (dailySavingsKwh * 30).toStringAsFixed(3),
          savingsPercent: dailySavingsPercent,
        ),
        const SizedBox(height: 12),

        // Monthly Cost
        _buildComparisonCard(
          context,
          title: 'Monthly Electricity Cost (₱)',
          original: originalMonthlyCost.toStringAsFixed(2),
          proposed: proposedMonthlyCost.toStringAsFixed(2),
          savings: monthlySavingsPhp.toStringAsFixed(2),
          savingsPercent: costSavingsPercent,
        ),
      ],
    );
  }

  /// Builds a single comparison card.
  Widget _buildComparisonCard(
    BuildContext context, {
    required String title,
    required String original,
    required String proposed,
    required String savings,
    required double savingsPercent,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildValueBox(
                    context,
                    label: 'Original',
                    value: original,
                    backgroundColor: const Color(0xFFF3F4F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueBox(
                    context,
                    label: 'Proposed',
                    value: proposed,
                    backgroundColor: const Color(0xFFF3F4F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border.all(color: const Color(0x2610B981)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Potential Savings',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: const Color(0xFF059669)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          savings,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: const Color(0xFF059669)),
                        ),
                      ),
                      Text(
                        '${savingsPercent.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: const Color(0xFF059669), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a value display box.
  Widget _buildValueBox(
    BuildContext context, {
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Builds the action buttons section.
  Widget _buildActionsSection() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _cancelSimulation,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showApplyConfirmationDialog,
            icon: const Icon(Icons.check),
            label: const Text('Apply Changes'),
          ),
        ),
      ],
    );
  }
}

/// Enum for simulation modes.
enum SimulationMode { turnOff, changeHours }
