/// Statut d'abonnement Premium — CLAUDE.md §10.3. Stocké en local après
/// validation du reçu d'achat via `in_app_purchase`, jamais vérifié côté
/// serveur (l'app reste sans backend).
class SubscriptionStatus {
  final bool isPremium;

  /// null = abonnement à vie / achat unique (pas d'expiration).
  final DateTime? expiresAt;

  const SubscriptionStatus({required this.isPremium, this.expiresAt});

  const SubscriptionStatus.free()
      : isPremium = false,
        expiresAt = null;

  /// Premium et pas expiré (ou sans date d'expiration).
  bool get isActive =>
      isPremium && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  Map<String, dynamic> toJson() => {
        'isPremium': isPremium,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isPremium: json['isPremium'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}
