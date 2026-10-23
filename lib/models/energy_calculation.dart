import 'package:calwatt/models/appliance.dart';

/// Immutable model storing energy consumption and cost calculations for an appliance.
///
/// This class holds the results of energy and cost calculations, with references
/// to the appliance being calculated. All fields are final to ensure immutability.
class EnergyCalculation {
  /// Daily energy consumption in kilowatt-hours (kWh).
  final double dailyConsumptionKwh;

  /// Estimated daily electricity cost in Philippine pesos (₱).
  final double dailyCostPhp;

  /// Projected monthly energy consumption in kilowatt-hours (kWh).
  final double monthlyConsumptionKwh;

  /// Projected monthly electricity cost in Philippine pesos (₱).
  final double monthlyCostPhp;

  /// Reference to the appliance this calculation is for.
  final Appliance appliance;

  /// Creates an immutable EnergyCalculation instance.
  const EnergyCalculation({
    required this.dailyConsumptionKwh,
    required this.dailyCostPhp,
    required this.monthlyConsumptionKwh,
    required this.monthlyCostPhp,
    required this.appliance,
  });

  /// Creates a copy of this calculation with optional field overrides.
  EnergyCalculation copyWith({
    double? dailyConsumptionKwh,
    double? dailyCostPhp,
    double? monthlyConsumptionKwh,
    double? monthlyCostPhp,
    Appliance? appliance,
  }) {
    return EnergyCalculation(
      dailyConsumptionKwh: dailyConsumptionKwh ?? this.dailyConsumptionKwh,
      dailyCostPhp: dailyCostPhp ?? this.dailyCostPhp,
      monthlyConsumptionKwh: monthlyConsumptionKwh ?? this.monthlyConsumptionKwh,
      monthlyCostPhp: monthlyCostPhp ?? this.monthlyCostPhp,
      appliance: appliance ?? this.appliance,
    );
  }

  /// Converts this calculation to a JSON-compatible map for storage.
  Map<String, dynamic> toJson() {
    return {
      'dailyConsumptionKwh': dailyConsumptionKwh,
      'dailyCostPhp': dailyCostPhp,
      'monthlyConsumptionKwh': monthlyConsumptionKwh,
      'monthlyCostPhp': monthlyCostPhp,
      'appliance': appliance.toJson(),
    };
  }

  /// Creates a calculation from a JSON map (e.g., from storage).
  static EnergyCalculation fromJson(Map<String, dynamic> json) {
    return EnergyCalculation(
      dailyConsumptionKwh: (json['dailyConsumptionKwh'] as num).toDouble(),
      dailyCostPhp: (json['dailyCostPhp'] as num).toDouble(),
      monthlyConsumptionKwh: (json['monthlyConsumptionKwh'] as num).toDouble(),
      monthlyCostPhp: (json['monthlyCostPhp'] as num).toDouble(),
      appliance: Appliance.fromJson(json['appliance'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() {
    return 'EnergyCalculation('
        'daily: ${dailyConsumptionKwh.toStringAsFixed(3)} kWh / ₱${dailyCostPhp.toStringAsFixed(2)}, '
        'monthly: ${monthlyConsumptionKwh.toStringAsFixed(3)} kWh / ₱${monthlyCostPhp.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EnergyCalculation &&
        other.dailyConsumptionKwh == dailyConsumptionKwh &&
        other.dailyCostPhp == dailyCostPhp &&
        other.monthlyConsumptionKwh == monthlyConsumptionKwh &&
        other.monthlyCostPhp == monthlyCostPhp &&
        other.appliance == appliance;
  }

  @override
  int get hashCode {
    return Object.hash(
      dailyConsumptionKwh,
      dailyCostPhp,
      monthlyConsumptionKwh,
      monthlyCostPhp,
      appliance,
    );
  }
}
