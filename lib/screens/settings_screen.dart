import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';

/// Settings screen for configuring app preferences and viewing information.
///
/// Allows users to:
/// - Configure the electricity rate in PHP per kWh
/// - View information about CalWatt's SDG 7 alignment
/// - View limitations and disclaimers about the app's estimates
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateController;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final appState = context.read<AppState>();
    _rateController = TextEditingController(
      text: appState.electricityRate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  /// Validates and saves the electricity rate.
  Future<void> _saveElectricityRate() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSaving = true;
    });

    try {
      final rateText = _rateController.text.trim();
      if (rateText.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter an electricity rate';
          _isSaving = false;
        });
        return;
      }

      final rate = double.parse(rateText);
      if (rate <= 0) {
        setState(() {
          _errorMessage = 'Electricity rate must be greater than 0';
          _isSaving = false;
        });
        return;
      }

      await context.read<AppState>().setElectricityRate(rate);

      setState(() {
        _successMessage = 'Electricity rate saved successfully';
        _isSaving = false;
      });

      // Clear success message after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } on FormatException {
      setState(() {
        _errorMessage = 'Please enter a valid number';
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving rate: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Electricity Rate Section
            _buildSectionHeader('Electricity Rate'),
            const SizedBox(height: 12),
            _buildElectricityRateCard(),
            const SizedBox(height: 32),

            // About CalWatt Section
            _buildSectionHeader('About CalWatt'),
            const SizedBox(height: 12),
            _buildAboutCard(),
            const SizedBox(height: 32),

            // Estimation Limitations Section
            _buildSectionHeader('Estimation Limitations'),
            const SizedBox(height: 12),
            _buildLimitationsCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the section header widget.
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  /// Builds the electricity rate configuration card.
  Widget _buildElectricityRateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure the electricity rate for your area. This rate is used to calculate estimated costs.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Electricity Rate (PHP/kWh)',
                hintText: '12.0',
                suffixText: '₱/kWh',
                enabled: !_isSaving,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveElectricityRate,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the About CalWatt information card.
  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CalWatt is a household energy consumption calculator app designed to support SDG 7: Affordable and Clean Energy.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'CalWatt helps households in the Philippines estimate and optimize their electricity consumption to promote affordable and clean energy usage. By understanding appliance energy consumption, users can make informed decisions to reduce costs and environmental impact.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 12),
            Chip(
              label: const Text('SDG 7 Alignment'),
              backgroundColor: Colors.green.shade100,
              labelStyle: TextStyle(color: Colors.green.shade900),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Estimation Limitations disclaimer card.
  Widget _buildLimitationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please note the following about CalWatt estimates:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'All calculations are estimates based on nameplate wattage and configured operating hours. Actual electricity consumption depends on device efficiency, usage patterns, and environmental factors. Your actual electricity bill may differ from these estimates. This app does not interface with physical meters or provide real-time monitoring.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estimates are for planning purposes only. Consult your actual electricity bill for accurate consumption data.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
