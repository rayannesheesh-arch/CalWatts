import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/energy_calculation.dart';

/// Service providing all energy consumption and cost calculations for CalWatt.
///
/// This service encapsulates business logic for converting watts to kilowatts,
/// calculating energy consumption in kWh, estimating costs, and aggregating
/// household-level calculations. All methods are static to allow easy access
/// throughout the application without instantiation.
///
/// Formulas implemented:
/// - kW = Watts / 1000
/// - kWh = kW × Operating Hours
/// - Estimated Cost = kWh × Electricity Rate (in PHP per kWh)
/// - Scheduled daily average = weekly scheduled use / 7
/// - Monthly projection = scheduled daily average × 30
class CalculationService {
  /// Prevents instantiation of this utility class.
  CalculationService._();

  /// Converts watts to kilowatts.
  ///
  /// Formula: kW = Watts / 1000
  ///
  /// Throws [ArgumentError] if watts is negative or zero.
  static double kWFromWatts(double watts) {
    if (watts <= 0) {
      throw ArgumentError('Watts must be greater than 0');
    }
    return watts / 1000;
  }

  /// Calculates kilowatt-hours from kilowatts and operating hours.
  ///
  /// Formula: kWh = kW × Operating Hours
  ///
  /// Throws [ArgumentError] if kw is negative or zero, or if hours is negative or greater than 24.
  static double kWhFromKwAndHours(double kw, double hours) {
    if (kw <= 0) {
      throw ArgumentError('kW must be greater than 0');
    }
    if (hours < 0 || hours > 24) {
      throw ArgumentError('Operating hours must be between 0 and 24');
    }
    return kw * hours;
  }

  /// Calculates electricity cost from kilowatt-hours and electricity rate.
  ///
  /// Formula: Cost = kWh × Electricity Rate (PHP per kWh)
  ///
  /// Throws [ArgumentError] if kwh is negative or if rate is negative or zero.
  static double costFromKwhAndRate(double kwh, double rate) {
    if (kwh < 0) {
      throw ArgumentError('kWh must be non-negative');
    }
    if (rate <= 0) {
      throw ArgumentError('Electricity rate must be greater than 0');
    }
    return kwh * rate;
  }

  /// Calculates wattage from voltage and current.
  ///
  /// Formula: Watts = Voltage × Current
  ///
  /// Throws [ArgumentError] if voltage or current is negative or zero.
  static double calculateWattageFromVoltageAndCurrent(
    double voltage,
    double current,
  ) {
    if (voltage <= 0) {
      throw ArgumentError('Voltage must be greater than 0');
    }
    if (current <= 0) {
      throw ArgumentError('Current must be greater than 0');
    }
    return voltage * current;
  }

  /// Calculates the average daily energy consumption and cost for one appliance.
  ///
  /// Returns an [EnergyCalculation] containing:
  /// - Daily consumption in kWh
  /// - Daily cost in PHP
  /// - Monthly projection (daily × 30)
  /// - Monthly cost projection
  ///
  /// Operating days are averaged across the week to match web dashboard estimates.
  /// The returned values are per unit; household aggregations apply quantity.
  ///
  /// Throws [ArgumentError] if rate is negative or zero, or if appliance properties are invalid.
  static EnergyCalculation calculateDailyConsumptionKwh(
    Appliance appliance,
    double rate,
  ) {
    if (rate <= 0) {
      throw ArgumentError('Electricity rate must be greater than 0');
    }

    final dailyKwh = calculateAverageDailyKwh(appliance);
    final dailyCost = costFromKwhAndRate(dailyKwh, rate);

    final monthlyKwh = dailyKwh * 30;
    final monthlyCost = dailyCost * 30;

    return EnergyCalculation(
      dailyConsumptionKwh: dailyKwh,
      dailyCostPhp: dailyCost,
      monthlyConsumptionKwh: monthlyKwh,
      monthlyCostPhp: monthlyCost,
      appliance: appliance,
    );
  }

  /// Returns an appliance's per-unit consumption for one Monday-based weekday.
  static double calculateScheduledDailyKwh(Appliance appliance, int dayOfWeek) {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw ArgumentError(
        'Day of week must be between 0 (Monday) and 6 (Sunday)',
      );
    }
    if (appliance.operatingDays.length != 7) {
      throw ArgumentError('Operating days must contain seven values');
    }
    if (!appliance.isOn || !appliance.operatingDays[dayOfWeek]) return 0;
    final kw = kWFromWatts(appliance.wattage);
    return kWhFromKwAndHours(kw, appliance.dailyOperatingHours);
  }

  /// Returns weekly scheduled consumption averaged across seven days, per unit.
  static double calculateAverageDailyKwh(Appliance appliance) {
    if (appliance.operatingDays.length != 7) {
      throw ArgumentError('Operating days must contain seven values');
    }
    if (!appliance.isOn) return 0;
    final scheduledDays = appliance.operatingDays.where((day) => day).length;
    final dailyKwh = kWhFromKwAndHours(
      kWFromWatts(appliance.wattage),
      appliance.dailyOperatingHours,
    );
    return dailyKwh * scheduledDays / 7;
  }

  /// Calculates household use for a Monday-based weekday, including quantities.
  static double calculateHouseholdConsumptionForDay(
    List<Appliance> appliances,
    int dayOfWeek,
  ) {
    return appliances.fold<double>(
      0,
      (total, appliance) =>
          total +
          calculateScheduledDailyKwh(appliance, dayOfWeek) * appliance.quantity,
    );
  }

  /// Aggregates daily energy consumption across all appliances in the household.
  ///
  /// Returns the total daily consumption in kWh considering all appliances
  /// and their ON/OFF states. Only appliances that are ON contribute to consumption.
  ///
  /// Throws [ArgumentError] if rate is invalid or appliance data is malformed.
  static double getHouseholdDaily(List<Appliance> appliances, double rate) {
    if (rate <= 0) {
      throw ArgumentError('Electricity rate must be greater than 0');
    }

    return appliances.fold<double>(
      0,
      (total, appliance) =>
          total + calculateAverageDailyKwh(appliance) * appliance.quantity,
    );
  }

  /// Aggregates monthly energy consumption projection across all appliances.
  ///
  /// Returns the total monthly consumption in kWh by multiplying the total
  /// daily consumption by 30.
  ///
  /// Throws [ArgumentError] if rate is invalid.
  static double getHouseholdMonthly(List<Appliance> appliances, double rate) {
    final dailyTotal = getHouseholdDaily(appliances, rate);
    return dailyTotal * 30;
  }

  /// Calculates household daily electricity cost.
  ///
  /// Returns the total estimated daily cost in Philippine pesos (₱).
  static double getHouseholdDailyCost(List<Appliance> appliances, double rate) {
    if (rate <= 0) {
      throw ArgumentError('Electricity rate must be greater than 0');
    }

    return getHouseholdDaily(appliances, rate) * rate;
  }

  /// Calculates household monthly electricity cost projection.
  ///
  /// Returns the total estimated monthly cost in Philippine pesos (₱).
  static double getHouseholdMonthlyCost(
    List<Appliance> appliances,
    double rate,
  ) {
    final dailyCost = getHouseholdDailyCost(appliances, rate);
    return dailyCost * 30;
  }

  /// Calculates the difference between two scenarios for what-if analysis.
  ///
  /// Compares an original [EnergyCalculation] against a proposed scenario and
  /// returns a map containing:
  /// - 'originalDailyKwh': Original daily consumption
  /// - 'proposedDailyKwh': Proposed daily consumption
  /// - 'dailySavingsKwh': Difference (positive = savings)
  /// - 'originalMonthlyCost': Original monthly cost
  /// - 'proposedMonthlyCost': Proposed monthly cost
  /// - 'monthlySavingsPhp': Difference (positive = savings)
  ///
  /// This method does not modify the original appliance data.
  static Map<String, double> calculateMonthlySavings(
    EnergyCalculation original,
    EnergyCalculation proposed,
  ) {
    final dailySavingsKwh =
        original.dailyConsumptionKwh - proposed.dailyConsumptionKwh;
    final monthlySavingsPhp = original.monthlyCostPhp - proposed.monthlyCostPhp;

    return {
      'originalDailyKwh': original.dailyConsumptionKwh,
      'proposedDailyKwh': proposed.dailyConsumptionKwh,
      'dailySavingsKwh': dailySavingsKwh,
      'originalMonthlyCost': original.monthlyCostPhp,
      'proposedMonthlyCost': proposed.monthlyCostPhp,
      'monthlySavingsPhp': monthlySavingsPhp,
    };
  }
}
