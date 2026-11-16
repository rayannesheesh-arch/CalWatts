import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/models/simulation_day.dart';
import 'package:calwatt/services/api_client.dart';
import 'package:calwatt/services/appliance_service.dart';
import 'package:calwatt/services/mobile_sync_service.dart';
import 'package:calwatt/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  final CalWattApiClient _api = CalWattApiClient.instance;
  late final MobileSyncService _sync = MobileSyncService(_api);

  List<Appliance> _appliances = [];
  double _electricityRate = 12.0;
  int _currentTab = 0;
  bool _isInitialized = false;
  bool _isDarkMode = false;
  bool _isSyncing = false;
  Map<String, dynamic>? _currentUser;
  List<SimDay> _simulationDays = [];
  String? _initializationError;

  static const _uuid = Uuid();

  List<Appliance> get appliances => _appliances;
  double get electricityRate => _electricityRate;
  int get currentTab => _currentTab;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  List<SimDay> get simulationDays => _simulationDays;
  bool get isAuthenticated => _currentUser != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isOnline => _sync.isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingChangesCount => _sync.pendingChangesCount;
  String? get syncError => _sync.lastError;
  String? get initializationError => _initializationError;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isDarkMode = await StorageService.getDarkMode();
    try {
      final savedUser = await _api.readSavedUser();
      final hasCachedSession = savedUser != null;
      if (hasCachedSession || await _api.hasSession()) {
        _currentUser = savedUser ?? await _api.restoreSession();
        await StorageService.useAccount(_currentUser!['id'].toString());
        await _importLegacyDataIfPresent();
        await _loadLocalData();
        if (hasCachedSession) {
          try {
            _currentUser = await _api.restoreSession();
            await _syncNow();
          } on ApiConnectionException catch (error) {
            _sync.isOnline = false;
            _sync.lastError = error.message;
          } on ApiException catch (error) {
            if (error.statusCode == 401) {
              await _api.clearCredentials();
              _currentUser = null;
            } else {
              _initializationError = error.message;
            }
          }
        } else {
          await _syncNow();
        }
      }
    } catch (error) {
      _initializationError = error.toString();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final user = await _api.login(email: email.trim(), password: password);
    await _activateUser(user);
  }

  Future<void> register(String fullName, String email, String password) async {
    final user = await _api.register(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
    );
    await _activateUser(user);
  }

  Future<void> _activateUser(Map<String, dynamic> user) async {
    _currentUser = user;
    await StorageService.useAccount(user['id'].toString());
    ApplianceService.clearCache();
    await _importLegacyDataIfPresent();
    await _loadLocalData();
    notifyListeners();
    await syncNow();
  }

  Future<void> _importLegacyDataIfPresent() async {
    final legacy = await StorageService.migrateLegacyData();
    if (legacy == null) return;
    await _sync.importLegacyData(
      appliances: legacy.appliances,
      days: legacy.simulationDays,
    );
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } on ApiConnectionException {
      await _api.clearCredentials();
    } on ApiException {
      await _api.clearCredentials();
    }
    _currentUser = null;
    _appliances = [];
    _simulationDays = [];
    _sync.isOnline = false;
    _sync.pendingChangesCount = 0;
    ApplianceService.clearCache();
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    ApplianceService.clearCache();
    _appliances = await StorageService.loadAppliances();
    _simulationDays = await StorageService.loadSimulationDays();
    _electricityRate = await StorageService.getElectricityRate();
    final queue = await StorageService.loadQueue();
    if (queue != null && queue.isNotEmpty) {
      _sync.pendingChangesCount = (jsonDecode(queue) as List).length;
    } else {
      _sync.pendingChangesCount = 0;
    }
  }

  Future<bool> syncNow() async {
    if (!isAuthenticated || _isSyncing) return false;
    return _syncNow();
  }

  Future<bool> _syncNow() async {
    _isSyncing = true;
    notifyListeners();
    try {
      final success = await _sync.synchronize();
      await _loadLocalData();
      if (_sync.sessionExpired) _currentUser = null;
      return success;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
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
    final index = _appliances.indexWhere((item) => item.id == appliance.id);
    if (index == -1) return;
    _appliances[index] = appliance;
    await StorageService.saveAppliances(_appliances);
    ApplianceService.clearCache();
    await _sync.queueAppliance(appliance);
    notifyListeners();
    await syncNow();
  }

  Future<void> deleteAppliance(String id) async {
    _appliances.removeWhere((item) => item.id == id);
    _simulationDays = _simulationDays.map((day) {
      final usages = day.usages
          .where((usage) => usage.applianceId != id)
          .toList();
      return day.copyWith(usages: usages);
    }).toList();
    await StorageService.saveAppliances(_appliances);
    await StorageService.saveSimulationDays(_simulationDays);
    ApplianceService.clearCache();
    await _sync.queueApplianceDelete(id);
    for (final day in _simulationDays) {
      await _sync.queueSimulationDay(day);
    }
    notifyListeners();
    await syncNow();
  }

  Future<void> toggleAppliance(String id) async {
    final index = _appliances.indexWhere((item) => item.id == id);
    if (index != -1) {
      final appliance = _appliances[index];
      await updateAppliance(appliance.copyWith(isOn: !appliance.isOn));
    }
  }

  Future<void> increaseQuantity(String id) async {
    final index = _appliances.indexWhere((item) => item.id == id);
    if (index != -1) {
      final appliance = _appliances[index];
      await updateAppliance(
        appliance.copyWith(quantity: appliance.quantity + 1),
      );
    }
  }

  Future<void> decreaseQuantity(String id) async {
    final index = _appliances.indexWhere((item) => item.id == id);
    if (index != -1 && _appliances[index].quantity > 1) {
      final appliance = _appliances[index];
      await updateAppliance(
        appliance.copyWith(quantity: appliance.quantity - 1),
      );
    }
  }

  Future<void> cloneAppliance(String id) async {
    final index = _appliances.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final original = _appliances[index];
    final cloned = original.copyWith(
      id: _uuid.v4(),
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
      quantity: 1,
    );
    _appliances.add(cloned);
    await StorageService.saveAppliances(_appliances);
    await _sync.queueAppliance(cloned);
    ApplianceService.clearCache();
    notifyListeners();
    await syncNow();
  }

  Future<void> refreshAppliances() async {
    await _loadLocalData();
    notifyListeners();
  }

  Future<void> setSimDay(SimDay day) async {
    assert(day.day >= 1 && day.day <= 31);
    final index = _simulationDays.indexWhere((item) => item.day == day.day);
    if (index == -1) {
      _simulationDays.add(day);
      _simulationDays.sort((a, b) => a.day.compareTo(b.day));
    } else {
      _simulationDays[index] = day;
    }
    await StorageService.saveSimulationDays(_simulationDays);
    await _sync.queueSimulationDay(day);
    notifyListeners();
    await syncNow();
  }

  Future<void> deleteSimDay(int dayNumber) async {
    _simulationDays.removeWhere((day) => day.day == dayNumber);
    await StorageService.saveSimulationDays(_simulationDays);
    await _sync.queueSimulationDelete(dayNumber);
    notifyListeners();
    await syncNow();
  }

  SimDay? getSimDay(int dayNumber) {
    for (final day in _simulationDays) {
      if (day.day == dayNumber) return day;
    }
    return null;
  }

  Future<void> clearSimulation() async {
    final days = _simulationDays.map((day) => day.day).toList();
    _simulationDays = [];
    await StorageService.saveSimulationDays(_simulationDays);
    for (final day in days) {
      await _sync.queueSimulationDelete(day);
    }
    notifyListeners();
    await syncNow();
  }

  Future<List<Map<String, dynamic>>> loadConsumptionHistory() =>
      _sync.loadHistory();

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
    final appliance = Appliance(
      id: _uuid.v4(),
      name: name,
      category: category,
      wattage: wattage,
      voltage: voltage,
      current: current,
      dailyOperatingHours: dailyOperatingHours,
      operatingDays: operatingDays,
      isOn: isOn,
      createdAt: DateTime.now(),
    );
    _appliances.add(appliance);
    await StorageService.saveAppliances(_appliances);
    await _sync.queueAppliance(appliance);
    ApplianceService.clearCache();
    notifyListeners();
    await syncNow();
  }
}
