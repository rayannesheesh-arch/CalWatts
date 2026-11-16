import 'dart:convert';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/simulation_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _appliancesKey = 'appliances';
  static const String _electricityRateKey = 'electricity_rate';
  static const String _darkModeKey = 'dark_mode';
  static const String _simulationKey = 'simulation_days';
  static const double _defaultElectricityRate = 12.0;
  static String? _activeAccountId;

  static String _key(String key) =>
      _activeAccountId == null ? key : 'calwatt.${_activeAccountId!}.$key';

  static Future<void> useAccount(String userId) async {
    _activeAccountId = userId;
  }

  static Future<({List<Appliance> appliances, List<SimDay> simulationDays})?>
      migrateLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesJson = prefs.getString(_appliancesKey);
    final simulationJson = prefs.getString(_simulationKey);
    if ((appliancesJson == null || appliancesJson.isEmpty)
        && (simulationJson == null || simulationJson.isEmpty)) {
      return null;
    }
    final appliances = appliancesJson == null || appliancesJson.isEmpty
        ? <Appliance>[]
        : (jsonDecode(appliancesJson) as List)
            .map((item) => Appliance.fromJson(item as Map<String, dynamic>))
            .toList();
    final days = simulationJson == null || simulationJson.isEmpty
        ? <SimDay>[]
        : (jsonDecode(simulationJson) as List)
            .map((item) => SimDay.fromJson(item as Map<String, dynamic>))
            .toList();
    await saveAppliances(appliances);
    await saveSimulationDays(days);
    await prefs.remove(_appliancesKey);
    await prefs.remove(_simulationKey);
    await prefs.remove(_electricityRateKey);
    return (appliances: appliances, simulationDays: days);
  }

  static Future<List<Appliance>> loadAppliances() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key(_appliancesKey));
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((item) => Appliance.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAppliances(List<Appliance> appliances) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(appliances.map((a) => a.toJson()).toList());
    await prefs.setString(_key(_appliancesKey), jsonString);
  }

  static Future<double> getElectricityRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key(_electricityRateKey)) ?? _defaultElectricityRate;
  }

  static Future<void> setElectricityRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key(_electricityRateKey), rate);
  }

  static Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_darkModeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
    } catch (_) {}
  }

  static Future<List<SimDay>> loadSimulationDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key(_simulationKey));
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((item) => SimDay.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveSimulationDays(List<SimDay> days) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(days.map((d) => d.toJson()).toList());
    await prefs.setString(_key(_simulationKey), jsonString);
  }

  static Future<String?> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key('pending_changes'));
  }

  static Future<void> saveQueue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('pending_changes'), value);
  }

  static Future<void> saveConsumptionHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('consumption_history'), value);
  }

  static Future<String?> loadConsumptionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key('consumption_history'));
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appliancesKey);
      await prefs.remove(_electricityRateKey);
      await prefs.remove(_darkModeKey);
      await prefs.remove(_simulationKey);
    } catch (_) {}
  }
}
