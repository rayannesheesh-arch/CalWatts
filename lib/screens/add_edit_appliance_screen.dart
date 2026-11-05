import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/services/appliance_service.dart';
import 'package:calwatt/theme/app_theme.dart';

class AddEditApplianceScreen extends StatefulWidget {
  final Appliance? appliance;
  const AddEditApplianceScreen({super.key, this.appliance});

  @override
  State<AddEditApplianceScreen> createState() => _AddEditApplianceScreenState();
}

class _AddEditApplianceScreenState extends State<AddEditApplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _wattageCtrl;
  late TextEditingController _voltageCtrl;
  late TextEditingController _currentCtrl;
  late TextEditingController _hoursCtrl;

  late ApplianceCategory _selectedCategory;
  late List<bool> _operatingDays;
  late bool _isOn;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Group categories for the dropdown
  static final Map<String, List<ApplianceCategory>> _groups = {
    'Household': ApplianceCategory.values.where((c) => c.groupLabel == 'Household').toList(),
    'Computers & IT': ApplianceCategory.values.where((c) => c.groupLabel == 'Computers & IT').toList(),
    'Warehouse & Industrial': ApplianceCategory.values.where((c) => c.groupLabel == 'Warehouse & Industrial').toList(),
    'Commercial & Business': ApplianceCategory.values.where((c) => c.groupLabel == 'Commercial & Business').toList(),
  };

  @override
  void initState() {
    super.initState();
    final a = widget.appliance;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _wattageCtrl = TextEditingController(text: a?.wattage.toStringAsFixed(0) ?? '');
    _voltageCtrl = TextEditingController(text: a?.voltage?.toStringAsFixed(0) ?? '');
    _currentCtrl = TextEditingController(text: a?.current?.toStringAsFixed(2) ?? '');
    _hoursCtrl = TextEditingController(text: a?.dailyOperatingHours.toStringAsFixed(1) ?? '');
    _selectedCategory = a?.category ?? ApplianceCategory.fan;
    _operatingDays = a?.operatingDays ?? List.filled(7, true);
    _isOn = a?.isOn ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wattageCtrl.dispose();
    _voltageCtrl.dispose();
    _currentCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  void _calculateWattage() {
    final v = double.tryParse(_voltageCtrl.text);
    final i = double.tryParse(_currentCtrl.text);
    if (v != null && v > 0 && i != null && i > 0) {
      _wattageCtrl.text = (v * i).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wattage: ${(v * i).toStringAsFixed(2)} W')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid voltage and current values')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final name = _nameCtrl.text.trim();
      final wattage = double.parse(_wattageCtrl.text);
      final voltage = _voltageCtrl.text.trim().isEmpty ? null : double.tryParse(_voltageCtrl.text);
      final current = _currentCtrl.text.trim().isEmpty ? null : double.tryParse(_currentCtrl.text);
      final hours = double.parse(_hoursCtrl.text);
      final isEditing = widget.appliance != null;

      final appState = context.read<AppState>();
      if (isEditing) {
        final updated = widget.appliance!.copyWith(
          name: name,
          category: _selectedCategory,
          wattage: wattage,
          voltage: voltage,
          current: current,
          dailyOperatingHours: hours,
          operatingDays: _operatingDays,
          isOn: _isOn,
        );
        await ApplianceService.updateAppliance(updated);
        if (!mounted) return;
        appState.updateAppliance(updated);
      } else {
        await ApplianceService.addAppliance(
          name: name,
          category: _selectedCategory,
          wattage: wattage,
          voltage: voltage,
          current: current,
          dailyOperatingHours: hours,
          operatingDays: _operatingDays,
          isOn: _isOn,
        );
        if (!mounted) return;
        await appState.refreshAppliances();
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Appliance updated' : 'Appliance added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appliance != null;
    final primary = AppTheme.primaryColor(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Appliance' : 'Add Appliance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g., Living Room Fan'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

              // Category selector with groups
              _buildCategorySelector(context, primary),
              const SizedBox(height: 14),

              TextFormField(
                controller: _wattageCtrl,
                decoration: const InputDecoration(labelText: 'Wattage (W)', hintText: 'e.g., 70', suffixText: 'W'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wattage is required';
                  final w = double.tryParse(v);
                  if (w == null || w <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _voltageCtrl,
                      decoration: const InputDecoration(labelText: 'Voltage (V)', hintText: 'Optional'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _currentCtrl,
                      decoration: const InputDecoration(labelText: 'Current (A)', hintText: 'Optional'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _calculateWattage,
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Calculate Wattage from V × A'),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Daily Operating Hours',
                  hintText: 'e.g., 6',
                  suffixText: 'hrs',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final h = double.tryParse(v);
                  if (h == null || h < 0 || h > 24) return 'Must be 0–24';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Text('Operating Days', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (i) => FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: _operatingDays[i],
                  onSelected: (v) => setState(() => _operatingDays[i] = v),
                )),
              ),
              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Text('Status', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        _isOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _isOn ? primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isOn,
                        onChanged: (v) => setState(() => _isOn = v),
                        activeThumbColor: primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(isEditing ? 'Update Appliance' : 'Add Appliance'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, Color primary) {
    return InkWell(
      onTap: () => _showCategoryPicker(context, primary),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(_selectedCategory.icon, color: primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    _selectedCategory.label,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, Color primary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Category', style: Theme.of(context).textTheme.headlineSmall),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _groups.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: primary,
                              ),
                        ),
                      ),
                      ...entry.value.map((cat) => ListTile(
                            dense: true,
                            leading: Icon(cat.icon, color: primary, size: 20),
                            title: Text(cat.label, style: Theme.of(context).textTheme.bodyLarge),
                            trailing: _selectedCategory == cat
                                ? Icon(Icons.check_circle, color: primary, size: 20)
                                : null,
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              Navigator.pop(ctx);
                            },
                          )),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
