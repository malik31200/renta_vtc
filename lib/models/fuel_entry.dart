/// Un plein réel (carburant ou électricité selon le véhicule actif) —
/// saisi à chaque recharge, plusieurs entrées possibles par mois. Réservé
/// Premium, utilisé pour remplacer le coût carburant théorique (basé sur la
/// seule distance course) par la dépense réelle dans le net mensuel — voir
/// StatsService.
class FuelEntry {
  final String id;
  final DateTime date;
  final double amount;

  const FuelEntry({
    required this.id,
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
      };

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
