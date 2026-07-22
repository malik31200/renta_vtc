/// Taux URSSAF par défaut pour un auto-entrepreneur VTC (prestations de
/// services, BIC), taux 2026 — voir CLAUDE.md §5.4. Modifiable par
/// l'utilisateur dans les réglages, ce n'est qu'une valeur de pré-remplissage.
const double kDefaultUrssafRate = 0.212;

class DriverProfile {
  /// Vide ('') pour le profil placeholder avant toute sauvegarde — un id
  /// définitif est attribué à la première sauvegarde (CLAUDE.md §10.2.d,
  /// multi-véhicules).
  final String id;

  final String vehicleName;

  /// Consommation aux 100km. Interprétée en L/100km pour un véhicule
  /// thermique, ou en kWh/100km si [isElectric] — même formule de calcul
  /// dans les deux cas (CLAUDE.md §5.2), seule l'unité affichée change.
  final double consumptionL100km;

  /// Prix de l'énergie : €/L (thermique) ou €/kWh (électrique).
  final double fuelPricePerLiter;

  final double urssafRate;

  /// Véhicule 100% électrique : change uniquement les unités affichées
  /// (kWh/100km, €/kWh) — le calcul du coût d'énergie reste identique.
  final bool isElectric;

  const DriverProfile({
    required this.id,
    required this.vehicleName,
    required this.consumptionL100km,
    required this.fuelPricePerLiter,
    required this.urssafRate,
    this.isElectric = false,
  });

  const DriverProfile.empty()
      : id = '',
        vehicleName = '',
        consumptionL100km = 0,
        fuelPricePerLiter = 0,
        urssafRate = kDefaultUrssafRate,
        isElectric = false;

  /// Un profil est considéré configuré une fois que les champs nécessaires
  /// au calcul (véhicule, conso, prix carburant) ont été renseignés par
  /// l'utilisateur. Le taux URSSAF a toujours une valeur par défaut.
  bool get isConfigured =>
      vehicleName.isNotEmpty && consumptionL100km > 0 && fuelPricePerLiter > 0;

  DriverProfile copyWith({
    String? vehicleName,
    double? consumptionL100km,
    double? fuelPricePerLiter,
    double? urssafRate,
    bool? isElectric,
  }) {
    return DriverProfile(
      id: id,
      vehicleName: vehicleName ?? this.vehicleName,
      consumptionL100km: consumptionL100km ?? this.consumptionL100km,
      fuelPricePerLiter: fuelPricePerLiter ?? this.fuelPricePerLiter,
      urssafRate: urssafRate ?? this.urssafRate,
      isElectric: isElectric ?? this.isElectric,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleName': vehicleName,
        'consumptionL100km': consumptionL100km,
        'fuelPricePerLiter': fuelPricePerLiter,
        'urssafRate': urssafRate,
        'isElectric': isElectric,
      };

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String? ?? '',
      vehicleName: json['vehicleName'] as String? ?? '',
      consumptionL100km: (json['consumptionL100km'] as num?)?.toDouble() ?? 0,
      fuelPricePerLiter: (json['fuelPricePerLiter'] as num?)?.toDouble() ?? 0,
      urssafRate:
          (json['urssafRate'] as num?)?.toDouble() ?? kDefaultUrssafRate,
      isElectric: json['isElectric'] as bool? ?? false,
    );
  }
}
