import 'package:flutter/material.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/models/simulation_day.dart';
import 'package:calwatt/services/appliance_service.dart';
import 'package:calwatt/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  List<Appliance> _appliances = [];
  double _electricityRate = 0.0;
  int _currentTab = 0;
  bool _isInitialized = false;
  bool _isDarkMode = false;
  List<SimDay> _simulationDays = [];

  static const _uuid = Uuid();

  List<Appliance> get appliances => _appliances;
  double get electricityRate => _electricityRate;
  int get currentTab => _currentTab;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  List<SimDay> get simulationDays => _simulationDays;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await ApplianceService.initializeSampleAppliances();
    _appliances = await ApplianceService.getAll();
    _electricityRate = await StorageService.getElectricityRate();
    _isDarkMode = await StorageService.getDarkMode();
    _simulationDays = await StorageService.loadSimulationDays();
    _isInitialized = true;
    notifyListeners();
  }

  void setCurrentTab(int tabIndex) {
    if (_currentTab != tabIndex) {
      _currentTab = tabIndex;
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> updateAppliance(Appliance appliance) async {
    await ApplianceService.updateAppliance(appliance);
    final index = _appliances.indexWhere((a) => a.id == appliance.id);
    if (index != -1) {
      _appliances[index] = appliance;
      notifyListeners();
    }
  }

  Future<void> deleteAppliance(String id) async {
    await ApplianceService.deleteAppliance(id);
    _appliances.removeWhere((a) => a.id == id);
    // Clean up simulation references to deleted appliance
    _simulationDays = _simulationDays.map((day) {
      final filtered = day.usages.where((u) => u.applianceId != id).toList();
      return day.copyWith(usages: filtered);
    }).toList();
    await StorageService.saveSimulationDays(_simulationDays);
    notifyListeners();
  }

  Future<void> toggleAppliance(String id) async {
    final index = _appliances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final appliance = _appliances[index];
      final updated = appliance.copyWith(isOn: !appliance.isOn);
      await updateAppliance(updated);
    }
  }

  /// Increases the running quantity of an appliance by 1.
  Future<void> increaseQuantity(String id) async {
    final index = _appliances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final appliance = _appliances[index];
      final updated = appliance.copyWith(quantity: appliance.quantity + 1);
      await updateAppliance(updated);
    }
  }

  /// Decreases the running quantity of an appliance by 1 (minimum 1).
  Future<void> decreaseQuantity(String id) async {
    final index = _appliances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final appliance = _appliances[index];
      if (appliance.quantity > 1) {
        final updated = appliance.copyWith(quantity: appliance.quantity - 1);
        await updateAppliance(updated);
      }
    }
  }

  /// Clones an appliance as a new independent entry.
  Future<void> cloneAppliance(String id) async {
    final index = _appliances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final original = _appliances[index];
      final cloned = original.copyWith(
        id: _uuid.v4(),
        name: '${original.name} (Copy)',
        createdAt: DateTime.now(),
        quantity: 1,
      );
      final allAppliances = await ApplianceService.getAll();
      allAppliances.add(cloned);
      await StorageService.saveAppliances(allAppliances);
      ApplianceService.clearCache();
      _appliances = await ApplianceService.getAll();
      notifyListeners();
    }
  }

  Future<void> setElectricityRate(double rate) async {
    if (_electricityRate != rate) {
      _electricityRate = rate;
      await StorageService.setElectricityRate(rate);
      notifyListeners();
    }
  }

  Future<void> refreshAppliances() async {
    _appliances = await ApplianceService.getAll();
    notifyListeners();
  }

  // ── Simulation ──────────────────────────────────────────────────────────────

  /// Adds or replaces a simulation day configuration.
  Future<void> setSimDay(SimDay day) async {
    assert(day.day >= 1 && day.day <= 31);
    final idx = _simulationDays.indexWhere((d) => d.day == day.day);
    if (idx != -1) {
      _simulationDays[idx] = day;
    } else {
      _simulationDays.add(day);
      _simulationDays.sort((a, b) => a.day.compareTo(b.day));
    }
    await StorageService.saveSimulationDays(_simulationDays);
    notifyListeners();
  }

  /// Removes a simulation day configuration (resets to zero consumption).
  Future<void> deleteSimDay(int dayNumber) async {
    _simulationDays.removeWhere((d) => d.day == dayNumber);
    await StorageService.saveSimulationDays(_simulationDays);
    notifyListeners();
  }

  /// Returns the SimDay for a given day number, or null if not configured.
  SimDay? getSimDay(int dayNumber) {
    try {
      return _simulationDays.firstWhere((d) => d.day == dayNumber);
    } catch (_) {
      return null;
    }
  }

  /// Clears all simulation days.
  Future<void> clearSimulation() async {
    _simulationDays = [];
    await StorageService.saveSimulationDays(_simulationDays);
    notifyListeners();
  }

  // ── Legacy addAppliance (used by AddEditApplianceScreen) ────────────────────
  Future<void> addAppliance({
    required String name,
    required ApplianceCategory category,
    required double wattage,
    double? voltage,
    double? current,
    required double dailyOperatingHours,
    required List<bool> operatingDays,
    bool isOn = false,
  }) async {
    await ApplianceService.addAppliance(
      name: name,
      category: category,
      wattage: wattage,
      voltage: voltage,
      current: current,
      dailyOperatingHours: dailyOperatingHours,
      operatingDays: operatingDays,
      isOn: isOn,
    );
    await refreshAppliances();
  }
}
