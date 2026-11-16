import 'dart:convert';

import 'package:calwatt/models/appliance_category.dart';

/// Immutable model representing an electrical appliance.
class Appliance {
  final String id;
  final String name;
  final ApplianceCategory category;
  final double wattage;
  final double? voltage;
  final double? current;
  final double dailyOperatingHours;
  final List<bool> operatingDays;
  final bool isOn;
  final DateTime createdAt;

  /// Number of identical units currently running (for dashboard quantity management).
  final int quantity;

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
    this.quantity = 1,
  });

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
    int? quantity,
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
      quantity: quantity ?? this.quantity,
    );
  }

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
      'quantity': quantity,
    };
  }

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
      quantity: (json['quantity'] as int?) ?? 1,
    );
  }

  static Appliance fromServerJson(Map<String, dynamic> json) {
    final daysValue = json['operatingDays'];
    final days = daysValue is String
        ? List<bool>.from(jsonDecode(daysValue) as List)
        : List<bool>.from(daysValue as List);
    final createdAtValue = json['createdAt'];
    return Appliance(
      id: json['id'].toString(),
      name: json['name'] as String,
      category: ApplianceCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => ApplianceCategory.fan,
      ),
      wattage: (json['wattage'] as num).toDouble(),
      dailyOperatingHours: (json['dailyOperatingHours'] as num).toDouble(),
      operatingDays: days,
      isOn: json['isOn'] == true || json['isOn'] == 1,
      createdAt: createdAtValue == null
          ? DateTime.now()
          : DateTime.tryParse(createdAtValue.toString()) ?? DateTime.now(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  String toString() =>
      'Appliance(id: $id, name: $name, category: $category, wattage: $wattage, isOn: $isOn, qty: $quantity)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appliance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
