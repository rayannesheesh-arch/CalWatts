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

  static Future<List<Appliance>> loadAppliances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_appliancesKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => Appliance.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAppliances(List<Appliance> appliances) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(appliances.map((a) => a.toJson()).toList());
      await prefs.setString(_appliancesKey, jsonString);
    } catch (_) {}
  }

  static Future<double> getElectricityRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_electricityRateKey) ?? _defaultElectricityRate;
    } catch (_) {
      return _defaultElectricityRate;
    }
  }

  static Future<void> setElectricityRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_electricityRateKey, rate);
    } catch (_) {}
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_simulationKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => SimDay.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSimulationDays(List<SimDay> days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(days.map((d) => d.toJson()).toList());
      await prefs.setString(_simulationKey, jsonString);
    } catch (_) {}
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
