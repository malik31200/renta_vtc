/// Une charge fixe mensuelle (assurance, RC pro, entretien...) — intitulé
/// libre saisi par l'utilisateur, montant. Réservé Premium, utilisé
/// uniquement pour le calcul du net réel du mois (voir StatsService).
class FixedExpense {
  final String id;
  final String label;
  final double amountPerMonth;

  const FixedExpense({
    required this.id,
    required this.label,
    required this.amountPerMonth,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amountPerMonth': amountPerMonth,
      };

  factory FixedExpense.fromJson(Map<String, dynamic> json) {
    return FixedExpense(
      id: json['id'] as String,
      label: json['label'] as String,
      amountPerMonth: (json['amountPerMonth'] as num).toDouble(),
    );
  }
}
