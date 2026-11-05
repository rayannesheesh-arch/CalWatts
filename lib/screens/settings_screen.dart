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
  late TextEditingController _rateCtrl;
  bool _isSaving = false;
  String? _errorMsg;
  String? _successMsg;

  @override
  void initState() {
    super.initState();
    final rate = context.read<AppState>().electricityRate;
    _rateCtrl = TextEditingController(text: rate.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _errorMsg = null; _successMsg = null; _isSaving = true; });
    try {
      final text = _rateCtrl.text.trim();
      if (text.isEmpty) throw FormatException('empty');
      final rate = double.parse(text);
      if (rate <= 0) {
        setState(() { _errorMsg = 'Rate must be greater than 0'; _isSaving = false; });
        return;
      }
      await context.read<AppState>().setElectricityRate(rate);
      setState(() { _successMsg = 'Rate saved successfully'; _isSaving = false; });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _successMsg = null);
      });
    } on FormatException {
      setState(() { _errorMsg = 'Please enter a valid number'; _isSaving = false; });
    } catch (e) {
      setState(() { _errorMsg = 'Error: $e'; _isSaving = false; });
    }
  }

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

            // Electricity Rate
            Text('Electricity Rate', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set the electricity rate for your area. Used for all cost calculations.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Electricity Rate',
                        hintText: '12.0',
                        suffixText: '₱/kWh',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_errorMsg != null)
                      _MessageBox(message: _errorMsg!, isError: true),
                    if (_successMsg != null)
                      _MessageBox(message: _successMsg!, isError: false),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Rate'),
                      ),
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

class _MessageBox extends StatelessWidget {
  final String message;
  final bool isError;
  const _MessageBox({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: TextStyle(color: color.shade700, fontSize: 13)),
    );
  }
}
