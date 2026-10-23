import 'dart:convert';
import 'package:calwatt/models/appliance.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing persistent storage of appliances and settings.
///
/// StorageService uses SharedPreferences to persist appliance data and
/// electricity rate configuration locally on the device.
class StorageService {
  static const String _appliancesKey = 'appliances';
  static const String _electricityRateKey = 'electricity_rate';
  static const double _defaultElectricityRate = 12.0; // PHP per kWh

  /// Loads all appliances from storage.
  ///
  /// Returns a list of Appliance objects parsed from stored JSON.
  /// If no appliances are stored, returns an empty list.
  static Future<List<Appliance>> loadAppliances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_appliancesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => Appliance.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading appliances: $e');
      return [];
    }
  }

  /// Saves all appliances to storage.
  ///
  /// Converts appliances to JSON and stores them in SharedPreferences.
  static Future<void> saveAppliances(List<Appliance> appliances) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = appliances.map((a) => a.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_appliancesKey, jsonString);
    } catch (e) {
      print('Error saving appliances: $e');
    }
  }

  /// Retrieves the configured electricity rate in PHP per kWh.
  ///
  /// Returns the stored rate or the default 12.0 PHP/kWh if not configured.
  static Future<double> getElectricityRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_electricityRateKey) ?? _defaultElectricityRate;
    } catch (e) {
      print('Error loading electricity rate: $e');
      return _defaultElectricityRate;
    }
  }

  /// Sets the electricity rate in PHP per kWh.
  static Future<void> setElectricityRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_electricityRateKey, rate);
    } catch (e) {
      print('Error saving electricity rate: $e');
    }
  }

  /// Clears all stored data.
  ///
  /// Useful for testing or resetting the application.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appliancesKey);
      await prefs.remove(_electricityRateKey);
    } catch (e) {
      print('Error clearing storage: $e');
    }
  }
}
