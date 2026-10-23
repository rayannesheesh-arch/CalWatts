import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing appliance CRUD operations and initialization.
///
/// ApplianceService provides a high-level interface for creating, reading,
/// updating, and deleting appliances. It uses StorageService for persistence
/// and initializes sample appliances on first run.
class ApplianceService {
  static const uuid = Uuid();
  static List<Appliance>? _cachedAppliances;

  /// Adds a new appliance to the collection.
  ///
  /// Generates a unique ID and saves the appliance to storage.
  static Future<Appliance> addAppliance({
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
      id: uuid.v4(),
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

    final appliances = await getAll();
    appliances.add(appliance);
    await StorageService.saveAppliances(appliances);
    _cachedAppliances = appliances;

    return appliance;
  }

  /// Updates an existing appliance.
  ///
  /// Replaces the appliance with the given ID and saves to storage.
  static Future<void> updateAppliance(Appliance appliance) async {
    final appliances = await getAll();
    final index = appliances.indexWhere((a) => a.id == appliance.id);

    if (index != -1) {
      appliances[index] = appliance;
      await StorageService.saveAppliances(appliances);
      _cachedAppliances = appliances;
    }
  }

  /// Deletes an appliance by ID.
  ///
  /// Removes the appliance and saves the updated list to storage.
  static Future<void> deleteAppliance(String id) async {
    final appliances = await getAll();
    appliances.removeWhere((a) => a.id == id);
    await StorageService.saveAppliances(appliances);
    _cachedAppliances = appliances;
  }

  /// Retrieves all appliances.
  ///
  /// Returns the cached list or loads from storage if not cached.
  static Future<List<Appliance>> getAll() async {
    if (_cachedAppliances != null) {
      return _cachedAppliances!;
    }

    final appliances = await StorageService.loadAppliances();
    _cachedAppliances = appliances;
    return appliances;
  }

  /// Retrieves a single appliance by ID.
  ///
  /// Returns null if not found.
  static Future<Appliance?> getById(String id) async {
    final appliances = await getAll();
    try {
      return appliances.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Initializes sample appliances on first run.
  ///
  /// Creates 6 sample appliances with realistic wattages and operating schedules.
  /// Only initializes if no appliances exist.
  static Future<void> initializeSampleAppliances() async {
    final existingAppliances = await StorageService.loadAppliances();

    if (existingAppliances.isNotEmpty) {
      _cachedAppliances = existingAppliances;
      return;
    }

    // All days of the week enabled
    final allDays = [true, true, true, true, true, true, true];

    final sampleAppliances = [
      Appliance(
        id: uuid.v4(),
        name: 'Living Room Fan',
        category: ApplianceCategory.fan,
        wattage: 70,
        dailyOperatingHours: 6,
        operatingDays: allDays,
        isOn: false,
        createdAt: DateTime.now(),
      ),
      Appliance(
        id: uuid.v4(),
        name: 'Bedroom Light',
        category: ApplianceCategory.light,
        wattage: 15,
        dailyOperatingHours: 4,
        operatingDays: allDays,
        isOn: false,
        createdAt: DateTime.now(),
      ),
      Appliance(
        id: uuid.v4(),
        name: 'Living Room TV',
        category: ApplianceCategory.television,
        wattage: 100,
        dailyOperatingHours: 5,
        operatingDays: allDays,
        isOn: false,
        createdAt: DateTime.now(),
      ),
      Appliance(
        id: uuid.v4(),
        name: 'Kitchen Refrigerator',
        category: ApplianceCategory.refrigerator,
        wattage: 150,
        dailyOperatingHours: 24,
        operatingDays: allDays,
        isOn: true,
        createdAt: DateTime.now(),
      ),
      Appliance(
        id: uuid.v4(),
        name: 'Kitchen Rice Cooker',
        category: ApplianceCategory.riceCooker,
        wattage: 1000,
        dailyOperatingHours: 1,
        operatingDays: allDays,
        isOn: false,
        createdAt: DateTime.now(),
      ),
      Appliance(
        id: uuid.v4(),
        name: 'Bedroom Air Conditioner',
        category: ApplianceCategory.airConditioner,
        wattage: 2500,
        dailyOperatingHours: 8,
        operatingDays: allDays,
        isOn: false,
        createdAt: DateTime.now(),
      ),
    ];

    await StorageService.saveAppliances(sampleAppliances);
    _cachedAppliances = sampleAppliances;
  }

  /// Clears the cache (useful for testing).
  static void clearCache() {
    _cachedAppliances = null;
  }
}
