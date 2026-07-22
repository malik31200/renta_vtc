import '../models/driver_profile.dart';
import '../models/ride_result.dart';

/// Logique métier pure de calcul du net réel d'une course. Voir CLAUDE.md §5
/// pour les règles de calcul et §5.3 pour la règle URSSAF (calculée sur le
/// prix client, jamais sur le montant versé par la plateforme).
class CalculatorService {
  const CalculatorService();

  RideResult computeRide({
    required DriverProfile profile,
    required double rideKm,
    required double clientPrice,
    required double platformPayout,
  }) {
    final fuelCost =
        rideKm * (profile.consumptionL100km / 100) * profile.fuelPricePerLiter;
    final urssafCost = clientPrice * profile.urssafRate;
    final net = platformPayout - fuelCost - urssafCost;

    return RideResult(
      rideKm: rideKm,
      clientPrice: clientPrice,
      platformPayout: platformPayout,
      fuelCost: fuelCost,
      urssafCost: urssafCost,
      net: net,
    );
  }
}
