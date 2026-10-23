import 'package:calwatt/models/appliance_category.dart';

/// Immutable model representing a household appliance.
///
/// This class stores all information about an appliance including its power
/// specifications, operating schedule, and current status. All fields are final
/// to ensure immutability.
class Appliance {
  /// Unique identifier for the appliance.
  final String id;

  /// User-friendly name of the appliance (e.g., "Living Room Fan").
  final String name;

  /// Category/type of appliance.
  final ApplianceCategory category;

  /// Power consumption in watts.
  final double wattage;

  /// Optional voltage in volts (for voltage/current-based wattage estimation).
  final double? voltage;

  /// Optional current in amperes (for voltage/current-based wattage estimation).
  final double? current;

  /// Expected daily operating hours for this appliance.
  final double dailyOperatingHours;

  /// Operating schedule: whether the appliance operates on each day of the week.
  /// Index 0 = Monday, Index 6 = Sunday
  final List<bool> operatingDays;

  /// Simulated ON/OFF status of the appliance.
  final bool isOn;

  /// Timestamp when the appliance record was created.
  final DateTime createdAt;

  /// Creates an immutable Appliance instance.
  const Appliance({
    required this.id,
    required this.name,
    required this.category,
    required this.wattage,
    this.voltage,
    this.current,
    required this.dailyOperatingHours,
    required this.operatingDays,
    required this.isOn,
    required this.createdAt,
  });

  /// Creates a copy of this appliance with optional field overrides.
  Appliance copyWith({
    String? id,
    String? name,
    ApplianceCategory? category,
    double? wattage,
    double? voltage,
    double? current,
    double? dailyOperatingHours,
    List<bool>? operatingDays,
    bool? isOn,
    DateTime? createdAt,
  }) {
    return Appliance(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      wattage: wattage ?? this.wattage,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      dailyOperatingHours: dailyOperatingHours ?? this.dailyOperatingHours,
      operatingDays: operatingDays ?? this.operatingDays,
      isOn: isOn ?? this.isOn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this appliance to a JSON-compatible map for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toJson(),
      'wattage': wattage,
      'voltage': voltage,
      'current': current,
      'dailyOperatingHours': dailyOperatingHours,
      'operatingDays': operatingDays,
      'isOn': isOn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates an appliance from a JSON map (e.g., from storage).
  static Appliance fromJson(Map<String, dynamic> json) {
    return Appliance(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ApplianceCategory.fromJson(json['category'] as String),
      wattage: (json['wattage'] as num).toDouble(),
      voltage: json['voltage'] != null ? (json['voltage'] as num).toDouble() : null,
      current: json['current'] != null ? (json['current'] as num).toDouble() : null,
      dailyOperatingHours: (json['dailyOperatingHours'] as num).toDouble(),
      operatingDays: List<bool>.from(json['operatingDays'] as List),
      isOn: json['isOn'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Appliance(id: $id, name: $name, category: $category, wattage: $wattage, isOn: $isOn)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Appliance &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.wattage == wattage &&
        other.voltage == voltage &&
        other.current == current &&
        other.dailyOperatingHours == dailyOperatingHours &&
        other.operatingDays == operatingDays &&
        other.isOn == isOn &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      category,
      wattage,
      voltage,
      current,
      dailyOperatingHours,
      Object.hashAll(operatingDays),
      isOn,
      createdAt,
    );
  }
}
