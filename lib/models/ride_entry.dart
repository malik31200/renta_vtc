import 'ride_result.dart';

/// Plateformes proposées pour le tag manuel d'une course — CLAUDE.md §10.2.a.
const List<String> kRidePlatforms = ['Uber', 'Bolt', 'Heetch', 'Autre'];

/// Une course calculée et horodatée, conservée dans l'historique (Premium) —
/// CLAUDE.md §10.2.a.
class RideEntry {
  final String id;
  final RideResult result;
  final DateTime date;
  final String? platformName;

  /// Durée de la course en minutes — saisie optionnelle, utilisée uniquement
  /// pour calculer le net moyen par heure (CLAUDE.md §10.2.b).
  final int? durationMinutes;

  const RideEntry({
    required this.id,
    required this.result,
    required this.date,
    this.platformName,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'platformName': platformName,
        'durationMinutes': durationMinutes,
        'rideKm': result.rideKm,
        'clientPrice': result.clientPrice,
        'platformPayout': result.platformPayout,
        'fuelCost': result.fuelCost,
        'urssafCost': result.urssafCost,
        'net': result.net,
      };

  factory RideEntry.fromJson(Map<String, dynamic> json) {
    return RideEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      platformName: json['platformName'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      result: RideResult(
        rideKm: (json['rideKm'] as num).toDouble(),
        clientPrice: (json['clientPrice'] as num).toDouble(),
        platformPayout: (json['platformPayout'] as num).toDouble(),
        fuelCost: (json['fuelCost'] as num).toDouble(),
        urssafCost: (json['urssafCost'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
      ),
    );
  }
}
