import 'package:flutter_test/flutter_test.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/appliance_category.dart';
import 'package:calwatt/services/calculation_service.dart';

void main() {
  group('CalculationService', () {
    // Helper to create a test appliance
    Appliance createTestAppliance({
      String id = 'test-1',
      String name = 'Test Appliance',
      ApplianceCategory category = ApplianceCategory.fan,
      double wattage = 100.0,
      double? voltage,
      double? current,
      double dailyOperatingHours = 8.0,
      List<bool>? operatingDays,
      bool isOn = true,
    }) {
      return Appliance(
        id: id,
        name: name,
        category: category,
        wattage: wattage,
        voltage: voltage,
        current: current,
        dailyOperatingHours: dailyOperatingHours,
        operatingDays:
            operatingDays ?? [true, true, true, true, true, true, true],
        isOn: isOn,
        createdAt: DateTime.now(),
      );
    }

    group('kWFromWatts', () {
      test('converts 100 watts to 0.1 kW', () {
        expect(CalculationService.kWFromWatts(100), equals(0.1));
      });

      test('converts 1000 watts to 1.0 kW', () {
        expect(CalculationService.kWFromWatts(1000), equals(1.0));
      });

      test('converts 500 watts to 0.5 kW', () {
        expect(CalculationService.kWFromWatts(500), equals(0.5));
      });

      test('throws ArgumentError for zero watts', () {
        expect(
          () => CalculationService.kWFromWatts(0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative watts', () {
        expect(
          () => CalculationService.kWFromWatts(-100),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('kWhFromKwAndHours', () {
      test('calculates 0.1 kW × 8 hours = 0.8 kWh', () {
        expect(
          CalculationService.kWhFromKwAndHours(0.1, 8),
          closeTo(0.8, 0.0001),
        );
      });

      test('calculates 1.0 kW × 24 hours = 24.0 kWh', () {
        expect(
          CalculationService.kWhFromKwAndHours(1.0, 24),
          closeTo(24.0, 0.0001),
        );
      });

      test('calculates 0.5 kW × 0 hours = 0.0 kWh', () {
        expect(CalculationService.kWhFromKwAndHours(0.5, 0), equals(0.0));
      });

      test('throws ArgumentError for zero kW', () {
        expect(
          () => CalculationService.kWhFromKwAndHours(0, 8),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative kW', () {
        expect(
          () => CalculationService.kWhFromKwAndHours(-0.1, 8),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative hours', () {
        expect(
          () => CalculationService.kWhFromKwAndHours(0.1, -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for hours > 24', () {
        expect(
          () => CalculationService.kWhFromKwAndHours(0.1, 25),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('costFromKwhAndRate', () {
      test('calculates 1.0 kWh × ₱8.00/kWh = ₱8.00', () {
        expect(
          CalculationService.costFromKwhAndRate(1.0, 8.0),
          closeTo(8.0, 0.0001),
        );
      });

      test('calculates 0.8 kWh × ₱10.00/kWh = ₱8.00', () {
        expect(
          CalculationService.costFromKwhAndRate(0.8, 10.0),
          closeTo(8.0, 0.0001),
        );
      });

      test('calculates 0.0 kWh × ₱10.00/kWh = ₱0.00', () {
        expect(CalculationService.costFromKwhAndRate(0.0, 10.0), equals(0.0));
      });

      test('throws ArgumentError for negative kWh', () {
        expect(
          () => CalculationService.costFromKwhAndRate(-0.5, 10.0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for zero rate', () {
        expect(
          () => CalculationService.costFromKwhAndRate(1.0, 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative rate', () {
        expect(
          () => CalculationService.costFromKwhAndRate(1.0, -5.0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('calculateWattageFromVoltageAndCurrent', () {
      test('calculates 220V × 0.5A = 110W', () {
        expect(
          CalculationService.calculateWattageFromVoltageAndCurrent(220, 0.5),
          closeTo(110, 0.0001),
        );
      });

      test('calculates 120V × 1.0A = 120W', () {
        expect(
          CalculationService.calculateWattageFromVoltageAndCurrent(120, 1.0),
          closeTo(120, 0.0001),
        );
      });

      test('calculates 230V × 2.0A = 460W', () {
        expect(
          CalculationService.calculateWattageFromVoltageAndCurrent(230, 2.0),
          closeTo(460, 0.0001),
        );
      });

      test('throws ArgumentError for zero voltage', () {
        expect(
          () =>
              CalculationService.calculateWattageFromVoltageAndCurrent(0, 1.0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative voltage', () {
        expect(
          () => CalculationService.calculateWattageFromVoltageAndCurrent(
            -220,
            1.0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for zero current', () {
        expect(
          () =>
              CalculationService.calculateWattageFromVoltageAndCurrent(220, 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative current', () {
        expect(
          () => CalculationService.calculateWattageFromVoltageAndCurrent(
            220,
            -1.0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('calculateDailyConsumptionKwh', () {
      test('calculates daily consumption for 100W appliance with 8 operating hours', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 8.0,
        );
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        expect(result.dailyConsumptionKwh, closeTo(0.8, 0.0001));
        expect(result.dailyCostPhp, closeTo(8.0, 0.0001));
        expect(result.monthlyConsumptionKwh, closeTo(24.0, 0.0001));
        expect(result.monthlyCostPhp, closeTo(240.0, 0.0001));
        expect(result.appliance, equals(appliance));
      });

      test('calculates zero consumption when appliance is OFF', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 8.0,
          isOn: false,
        );
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        expect(result.dailyConsumptionKwh, equals(0.0));
        expect(result.dailyCostPhp, equals(0.0));
        expect(result.monthlyConsumptionKwh, equals(0.0));
        expect(result.monthlyCostPhp, equals(0.0));
      });

      test('calculates daily consumption for high-wattage appliance', () {
        final appliance = createTestAppliance(
          wattage: 2000.0,
          dailyOperatingHours: 2.0,
        );
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          8.0,
        );

        expect(result.dailyConsumptionKwh, closeTo(4.0, 0.0001));
        expect(result.dailyCostPhp, closeTo(32.0, 0.0001));
        expect(result.monthlyConsumptionKwh, closeTo(120.0, 0.0001));
        expect(result.monthlyCostPhp, closeTo(960.0, 0.0001));
      });

      test('calculates zero consumption with zero operating hours', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 0.0,
        );
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        expect(result.dailyConsumptionKwh, equals(0.0));
        expect(result.dailyCostPhp, equals(0.0));
        expect(result.monthlyConsumptionKwh, equals(0.0));
        expect(result.monthlyCostPhp, equals(0.0));
      });

      test('throws ArgumentError for zero rate', () {
        final appliance = createTestAppliance();
        expect(
          () => CalculationService.calculateDailyConsumptionKwh(appliance, 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative rate', () {
        final appliance = createTestAppliance();
        expect(
          () =>
              CalculationService.calculateDailyConsumptionKwh(appliance, -5.0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('monthly consumption is exactly daily consumption × 30', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 8.0,
        );
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        expect(
          result.monthlyConsumptionKwh,
          closeTo(result.dailyConsumptionKwh * 30, 0.0001),
        );
        expect(
          result.monthlyCostPhp,
          closeTo(result.dailyCostPhp * 30, 0.0001),
        );
      });

      test('handles fractional electricity rates', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 8.0,
        );
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          9.75,
        );

        expect(result.dailyConsumptionKwh, closeTo(0.8, 0.0001));
        expect(result.dailyCostPhp, closeTo(7.8, 0.0001));
      });

      test('averages scheduled use across the week and includes quantity in household totals', () {
        final appliance = createTestAppliance(
          wattage: 70,
          dailyOperatingHours: 6,
          operatingDays: [true, true, true, true, true, false, false],
        ).copyWith(quantity: 3);
        final result = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          12,
        );

        expect(result.dailyConsumptionKwh, closeTo(0.3, 0.0001));
        expect(result.dailyCostPhp, closeTo(3.6, 0.0001));
        expect(result.monthlyConsumptionKwh, closeTo(9, 0.0001));
        expect(result.monthlyCostPhp, closeTo(108, 0.0001));
        expect(
          CalculationService.getHouseholdDaily([appliance], 12),
          closeTo(0.9, 0.0001),
        );
        expect(
          CalculationService.getHouseholdDailyCost([appliance], 12),
          closeTo(10.8, 0.0001),
        );
        expect(
          CalculationService.getHouseholdMonthly([appliance], 12),
          closeTo(27, 0.0001),
        );
        expect(
          CalculationService.getHouseholdMonthlyCost([appliance], 12),
          closeTo(324, 0.0001),
        );
      });

      test('calculates schedule-aware weekday use with the real Monday-based index', () {
        final appliance = createTestAppliance(
          wattage: 70,
          dailyOperatingHours: 6,
          operatingDays: [true, true, true, true, true, false, false],
        ).copyWith(quantity: 3);

        expect(
          CalculationService.calculateHouseholdConsumptionForDay([
            appliance,
          ], 0),
          closeTo(1.26, 0.0001),
        );
        expect(
          CalculationService.calculateHouseholdConsumptionForDay([
            appliance,
          ], 6),
          0,
        );
      });
    });

    group('getHouseholdDaily', () {
      test('sums consumption from multiple appliances', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
            isOn: true,
          ),
          createTestAppliance(
            id: '2',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
            isOn: true,
          ),
        ];

        final result = CalculationService.getHouseholdDaily(appliances, 10.0);
        expect(result, closeTo(1.6, 0.0001)); // 0.8 + 0.8
      });

      test('ignores OFF appliances in total', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
            isOn: true,
          ),
          createTestAppliance(
            id: '2',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
            isOn: false,
          ),
        ];

        final result = CalculationService.getHouseholdDaily(appliances, 10.0);
        expect(result, closeTo(0.8, 0.0001)); // Only ON appliance
      });

      test('returns 0 for empty appliance list', () {
        final result = CalculationService.getHouseholdDaily([], 10.0);
        expect(result, equals(0.0));
      });

      test('returns 0 when all appliances are OFF', () {
        final appliances = [
          createTestAppliance(id: '1', isOn: false),
          createTestAppliance(id: '2', isOn: false),
        ];

        final result = CalculationService.getHouseholdDaily(appliances, 10.0);
        expect(result, equals(0.0));
      });

      test('throws ArgumentError for zero rate', () {
        final appliances = [createTestAppliance()];
        expect(
          () => CalculationService.getHouseholdDaily(appliances, 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles mixed appliance wattages and operating hours', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
          ),
          createTestAppliance(
            id: '2',
            wattage: 2000.0,
            dailyOperatingHours: 2.0,
          ),
        ];

        final result = CalculationService.getHouseholdDaily(appliances, 10.0);
        // First: 100W / 1000 × 8 = 0.8 kWh
        // Second: 2000W / 1000 × 2 = 4.0 kWh
        // Total: 4.8 kWh
        expect(result, closeTo(4.8, 0.0001));
      });
    });

    group('getHouseholdMonthly', () {
      test('monthly is exactly daily × 30', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
          ),
          createTestAppliance(
            id: '2',
            wattage: 2000.0,
            dailyOperatingHours: 2.0,
          ),
        ];

        final daily = CalculationService.getHouseholdDaily(appliances, 10.0);
        final monthly = CalculationService.getHouseholdMonthly(
          appliances,
          10.0,
        );

        expect(monthly, closeTo(daily * 30, 0.0001));
      });

      test('returns 0 for empty appliance list', () {
        final result = CalculationService.getHouseholdMonthly([], 10.0);
        expect(result, equals(0.0));
      });

      test('throws ArgumentError for invalid rate', () {
        final appliances = [createTestAppliance()];
        expect(
          () => CalculationService.getHouseholdMonthly(appliances, -1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getHouseholdDailyCost', () {
      test('sums cost from multiple appliances', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
          ),
          createTestAppliance(
            id: '2',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
          ),
        ];

        final result = CalculationService.getHouseholdDailyCost(
          appliances,
          10.0,
        );
        expect(result, closeTo(16.0, 0.0001)); // (0.8 + 0.8) × 10
      });

      test('returns 0 for empty appliance list', () {
        final result = CalculationService.getHouseholdDailyCost([], 10.0);
        expect(result, equals(0.0));
      });

      test('ignores OFF appliances', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
            isOn: true,
          ),
          createTestAppliance(
            id: '2',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
            isOn: false,
          ),
        ];

        final result = CalculationService.getHouseholdDailyCost(
          appliances,
          10.0,
        );
        expect(result, closeTo(8.0, 0.0001));
      });
    });

    group('getHouseholdMonthlyCost', () {
      test('monthly cost is exactly daily cost × 30', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            wattage: 100.0,
            dailyOperatingHours: 8.0,
          ),
        ];

        final daily = CalculationService.getHouseholdDailyCost(
          appliances,
          10.0,
        );
        final monthly = CalculationService.getHouseholdMonthlyCost(
          appliances,
          10.0,
        );

        expect(monthly, closeTo(daily * 30, 0.0001));
      });

      test('returns 0 for empty list', () {
        final result = CalculationService.getHouseholdMonthlyCost([], 10.0);
        expect(result, equals(0.0));
      });
    });

    group('calculateMonthlySavings', () {
      test('calculates positive savings when original > proposed', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 8.0,
        );
        final original = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        // Simulate turning off the appliance (proposed scenario)
        final applianceOff = appliance.copyWith(isOn: false);
        final proposed = CalculationService.calculateDailyConsumptionKwh(
          applianceOff,
          10.0,
        );

        final savings = CalculationService.calculateMonthlySavings(
          original,
          proposed,
        );

        expect(savings['originalDailyKwh'], closeTo(0.8, 0.0001));
        expect(savings['proposedDailyKwh'], equals(0.0));
        expect(savings['dailySavingsKwh'], closeTo(0.8, 0.0001));
        expect(savings['originalMonthlyCost'], closeTo(240.0, 0.0001));
        expect(savings['proposedMonthlyCost'], equals(0.0));
        expect(savings['monthlySavingsPhp'], closeTo(240.0, 0.0001));
      });

      test('calculates negative savings when original < proposed', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 4.0,
        );
        final original = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        // Simulate increasing operating hours
        final applianceMore = appliance.copyWith(dailyOperatingHours: 8.0);
        final proposed = CalculationService.calculateDailyConsumptionKwh(
          applianceMore,
          10.0,
        );

        final savings = CalculationService.calculateMonthlySavings(
          original,
          proposed,
        );

        expect(
          savings['dailySavingsKwh'],
          closeTo(-0.4, 0.0001),
        ); // Negative savings (additional cost)
        expect(savings['monthlySavingsPhp'], closeTo(-120.0, 0.0001));
      });

      test('calculates zero savings when original == proposed', () {
        final appliance = createTestAppliance(
          wattage: 100.0,
          dailyOperatingHours: 8.0,
        );
        final original = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );
        final proposed = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );

        final savings = CalculationService.calculateMonthlySavings(
          original,
          proposed,
        );

        expect(savings['dailySavingsKwh'], closeTo(0.0, 0.0001));
        expect(savings['monthlySavingsPhp'], closeTo(0.0, 0.0001));
      });

      test('returns all six expected keys', () {
        final appliance = createTestAppliance();
        final original = CalculationService.calculateDailyConsumptionKwh(
          appliance,
          10.0,
        );
        final proposed = CalculationService.calculateDailyConsumptionKwh(
          appliance.copyWith(isOn: false),
          10.0,
        );

        final savings = CalculationService.calculateMonthlySavings(
          original,
          proposed,
        );

        expect(savings.length, equals(6));
        expect(savings.containsKey('originalDailyKwh'), isTrue);
        expect(savings.containsKey('proposedDailyKwh'), isTrue);
        expect(savings.containsKey('dailySavingsKwh'), isTrue);
        expect(savings.containsKey('originalMonthlyCost'), isTrue);
        expect(savings.containsKey('proposedMonthlyCost'), isTrue);
        expect(savings.containsKey('monthlySavingsPhp'), isTrue);
      });
    });

    group('Integration tests', () {
      test('realistic household scenario', () {
        final appliances = [
          createTestAppliance(
            id: '1',
            name: 'Living Room Fan',
            category: ApplianceCategory.fan,
            wattage: 50.0,
            dailyOperatingHours: 8.0,
          ),
          createTestAppliance(
            id: '2',
            name: 'Refrigerator',
            category: ApplianceCategory.refrigerator,
            wattage: 150.0,
            dailyOperatingHours: 24.0,
          ),
          createTestAppliance(
            id: '3',
            name: 'Air Conditioner',
            category: ApplianceCategory.airConditioner,
            wattage: 1500.0,
            dailyOperatingHours: 6.0,
            isOn: false, // OFF
          ),
        ];

        final electricityRate = 10.0; // PHP per kWh

        // Calculate household totals
        final dailyConsumption = CalculationService.getHouseholdDaily(
          appliances,
          electricityRate,
        );
        final monthlyCost = CalculationService.getHouseholdMonthlyCost(
          appliances,
          electricityRate,
        );

        // Expected: (50W × 8h + 150W × 24h) / 1000 = (0.4 + 3.6) = 4.0 kWh daily
        expect(dailyConsumption, closeTo(4.0, 0.0001));
        expect(monthlyCost, closeTo(1200.0, 0.0001)); // 4.0 × 10 × 30
      });

      test('what-if scenario: turning on AC reduces savings potential', () {
        final fan = createTestAppliance(
          id: '1',
          wattage: 50.0,
          dailyOperatingHours: 8.0,
        );
        final ac = createTestAppliance(
          id: '2',
          wattage: 1500.0,
          dailyOperatingHours: 6.0,
          isOn: false,
        );

        final originalList = [fan, ac];
        final originalCost = CalculationService.getHouseholdDailyCost(
          originalList,
          10.0,
        );

        // Simulate turning on AC
        final acOn = ac.copyWith(isOn: true);
        final proposedList = [fan, acOn];
        final proposedCost = CalculationService.getHouseholdDailyCost(
          proposedList,
          10.0,
        );

        expect(
          proposedCost - originalCost,
          closeTo(90.0, 0.0001),
        ); // 9 kWh × 10
      });
    });
  });
}
