class RideResult {
  final double rideKm;
  final double clientPrice;
  final double platformPayout;
  final double fuelCost;
  final double urssafCost;
  final double net;

  const RideResult({
    required this.rideKm,
    required this.clientPrice,
    required this.platformPayout,
    required this.fuelCost,
    required this.urssafCost,
    required this.net,
  });

  double get commissionAmount => clientPrice - platformPayout;

  /// Ratio (0.18 = 18 %), 0 si `clientPrice` est nul pour éviter une division
  /// par zéro.
  double get commissionRate =>
      clientPrice == 0 ? 0 : commissionAmount / clientPrice;
}
