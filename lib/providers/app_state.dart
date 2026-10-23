import 'package:flutter/material.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/services/appliance_service.dart';
import 'package:calwatt/services/storage_service.dart';

/// Application state managed via provider pattern.
///
/// Holds and manages the app-wide state including appliances list,
/// electricity rate, and current tab selection. Notifies listeners when
/// state changes.
class AppState extends ChangeNotifier {
  List<Appliance> _appliances = [];
  double _electricityRate = 0.0; // PHP per kWh
  int _currentTab = 0;
  bool _isInitialized = false;

  /// List of all registered appliances.
  List<Appliance> get appliances => _appliances;

  /// Electricity rate in PHP per kWh.
  double get electricityRate => _electricityRate;

  /// Currently selected tab index (0: Dashboard, 1: Appliances, 2: Analytics, 3: Settings).
  int get currentTab => _currentTab;

  /// Whether the app state has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the app state by loading appliances and electricity rate.
  ///
  /// Should be called once when the app starts. Loads sample appliances on first run
  /// and retrieves stored electricity rate.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize sample appliances on first run
    await ApplianceService.initializeSampleAppliances();

    // Load appliances from storage
    _appliances = await ApplianceService.getAll();

    // Load electricity rate from storage (default to 12.0 if not set)
    _electricityRate = await StorageService.getElectricityRate();

    _isInitialized = true;
    notifyListeners();
  }

  /// Sets the current tab index.
  void setCurrentTab(int tabIndex) {
    if (_currentTab != tabIndex) {
      _currentTab = tabIndex;
      notifyListeners();
    }
  }

  /// Adds a new appliance to the collection.
  Future<void> addAppliance({
    required String name,
    required String category,
    required double wattage,
    double? voltage,
    double? current,
    required double dailyOperatingHours,
    required List<bool> operatingDays,
    bool isOn = false,
  }) async {
    // Implementation will depend on ApplianceCategory enum
    // For now, this is a placeholder for integration in later features
    notifyListeners();
  }

  /// Updates an appliance in the collection.
  Future<void> updateAppliance(Appliance appliance) async {
    await ApplianceService.updateAppliance(appliance);
    final index = _appliances.indexWhere((a) => a.id == appliance.id);
    if (index != -1) {
      _appliances[index] = appliance;
      notifyListeners();
    }
  }

  /// Deletes an appliance by ID.
  Future<void> deleteAppliance(String id) async {
    await ApplianceService.deleteAppliance(id);
    _appliances.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// Toggles the ON/OFF status of an appliance.
  Future<void> toggleAppliance(String id) async {
    final index = _appliances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final appliance = _appliances[index];
      final updated = appliance.copyWith(isOn: !appliance.isOn);
      await updateAppliance(updated);
    }
  }

  /// Sets the electricity rate in PHP per kWh.
  Future<void> setElectricityRate(double rate) async {
    if (_electricityRate != rate) {
      _electricityRate = rate;
      await StorageService.setElectricityRate(rate);
      notifyListeners();
    }
  }

  /// Refreshes the appliances list from storage.
  Future<void> refreshAppliances() async {
    _appliances = await ApplianceService.getAll();
    notifyListeners();
  }
}
