import 'package:flutter_test/flutter_test.dart';
import 'package:renta_vtc/models/driver_profile.dart';
import 'package:renta_vtc/services/calculator_service.dart';

void main() {
  const calculator = CalculatorService();

  group('CalculatorService.computeRide', () {
    test('cas nominal : course rentable', () {
      const profile = DriverProfile(
        id: 'test',
        vehicleName: 'Clio V',
        consumptionL100km: 6.0,
        fuelPricePerLiter: 1.80,
        urssafRate: 0.212,
      );

      final result = calculator.computeRide(
        profile: profile,
        rideKm: 10,
        clientPrice: 25.00,
        platformPayout: 20.00,
      );

      expect(result.fuelCost, closeTo(1.08, 0.001));
      expect(result.urssafCost, closeTo(5.30, 0.001));
      expect(result.net, closeTo(13.62, 0.001));
      expect(result.commissionAmount, closeTo(5.00, 0.001));
      expect(result.commissionRate, closeTo(0.20, 0.001));
    });

    test('cas net négatif : course non rentable après charges', () {
      const profile = DriverProfile(
        id: 'test',
        vehicleName: 'SUV',
        consumptionL100km: 8.0,
        fuelPricePerLiter: 2.00,
        urssafRate: 0.212,
      );

      final result = calculator.computeRide(
        profile: profile,
        rideKm: 100,
        clientPrice: 15.00,
        platformPayout: 12.00,
      );

      expect(result.fuelCost, closeTo(16.00, 0.001));
      expect(result.urssafCost, closeTo(3.18, 0.001));
      expect(result.net, closeTo(-7.18, 0.001));
      expect(result.net, lessThan(0));
    });

    test('cas valeurs à zéro : champs non remplis', () {
      const profile = DriverProfile(
        id: 'test',
        vehicleName: 'Clio V',
        consumptionL100km: 6.0,
        fuelPricePerLiter: 1.80,
        urssafRate: 0.212,
      );

      final result = calculator.computeRide(
        profile: profile,
        rideKm: 0,
        clientPrice: 0,
        platformPayout: 0,
      );

      expect(result.fuelCost, 0);
      expect(result.urssafCost, 0);
      expect(result.net, 0);
      expect(result.commissionAmount, 0);
      expect(result.commissionRate, 0);
    });

    test(
      'règle métier critique : urssafCost se base sur clientPrice, jamais sur platformPayout',
      () {
        const profile = DriverProfile(
        id: 'test',
          vehicleName: 'Clio V',
          consumptionL100km: 0,
          fuelPricePerLiter: 0,
          urssafRate: 0.212,
        );

        final result = calculator.computeRide(
          profile: profile,
          rideKm: 0,
          clientPrice: 100,
          platformPayout: 50,
        );

        // 21,2 % de 100 € (prix client), et non de 50 € (versé plateforme).
        expect(result.urssafCost, closeTo(21.2, 0.001));
        expect(result.urssafCost, isNot(closeTo(50 * 0.212, 0.001)));
      },
    );
  });
}
