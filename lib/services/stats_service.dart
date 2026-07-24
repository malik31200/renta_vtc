import '../models/fixed_expense.dart';
import '../models/fuel_entry.dart';
import '../models/ride_entry.dart';

/// Statistiques calculées à la volée à partir de l'historique — CLAUDE.md
/// §10.2.b. Pas de pré-agrégation ni de persistance : tout se recalcule à
/// chaque appel depuis la liste de `RideEntry`.
class StatsService {
  const StatsService();

  double averageNetPerKm(List<RideEntry> entries) {
    final withDistance = entries.where((e) => e.result.rideKm > 0);
    if (withDistance.isEmpty) return 0;
    final totalNet = withDistance.fold<double>(0, (sum, e) => sum + e.result.net);
    final totalKm = withDistance.fold<double>(0, (sum, e) => sum + e.result.rideKm);
    return totalNet / totalKm;
  }

  /// Ne considère que les courses dont la durée a été renseignée.
  double averageNetPerHour(List<RideEntry> entries) {
    final withDuration =
        entries.where((e) => (e.durationMinutes ?? 0) > 0);
    if (withDuration.isEmpty) return 0;
    final totalNet = withDuration.fold<double>(0, (sum, e) => sum + e.result.net);
    final totalMinutes =
        withDuration.fold<int>(0, (sum, e) => sum + e.durationMinutes!);
    return totalNet / (totalMinutes / 60);
  }

  double totalNetOnDay(List<RideEntry> entries, DateTime day) {
    return entries
        .where((e) => _isSameDay(e.date, day))
        .fold<double>(0, (sum, e) => sum + e.result.net);
  }

  double totalNetSince(List<RideEntry> entries, DateTime start) {
    return entries
        .where((e) => !e.date.isBefore(start))
        .fold<double>(0, (sum, e) => sum + e.result.net);
  }

  double totalNetInMonth(List<RideEntry> entries, DateTime reference) {
    return entries
        .where((e) => e.date.year == reference.year && e.date.month == reference.month)
        .fold<double>(0, (sum, e) => sum + e.result.net);
  }

  /// CA brut (prix client) cumulé sur l'année civile — utilisé pour l'alerte
  /// de seuil auto-entrepreneur (CLAUDE.md §10.2.f), qui se base sur le CA
  /// encaissé et non le net, à l'image du calcul des cotisations URSSAF.
  double totalClientPriceInYear(List<RideEntry> entries, int year) {
    return entries
        .where((e) => e.date.year == year)
        .fold<double>(0, (sum, e) => sum + e.result.clientPrice);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfWeek(DateTime reference) {
    final startOfDay = DateTime(reference.year, reference.month, reference.day);
    return startOfDay.subtract(Duration(days: reference.weekday - 1));
  }

  /// Regroupe les courses par plateforme avec net moyen et cumulé —
  /// CLAUDE.md §10.2.e. Triées par net moyen décroissant.
  List<PlatformStats> byPlatform(List<RideEntry> entries) {
    final groups = <String, List<RideEntry>>{};
    for (final entry in entries) {
      final key = entry.platformName ?? 'Sans plateforme';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final stats = groups.entries.map((group) {
      final totalNet = group.value.fold<double>(0, (sum, e) => sum + e.result.net);
      return PlatformStats(
        label: group.key,
        rideCount: group.value.length,
        totalNet: totalNet,
        averageNet: totalNet / group.value.length,
      );
    }).toList();

    stats.sort((a, b) => b.averageNet.compareTo(a.averageNet));
    return stats;
  }

  /// Net réel du mois : remplace le carburant théorique par course (basé
  /// uniquement sur la distance course, cf. §5.1) par la dépense carburant
  /// réellement saisie, et déduit les charges fixes — fonctionnalité
  /// Premium demandée par un chauffeur testeur.
  ///
  /// Garde-fou : tant qu'aucun plein n'est saisi pour le mois, le carburant
  /// théorique reste utilisé tel quel (comme dans le net par course actuel)
  /// plutôt que d'être traité comme 0€ — sinon un oubli de saisie gonflerait
  /// artificiellement le "net réel" affiché.
  RealMonthlyNet realNetForMonth(
    List<RideEntry> entries,
    List<FixedExpense> fixedExpenses,
    List<FuelEntry> fuelEntries,
    DateTime reference,
  ) {
    final monthEntries = entries.where(
      (e) => e.date.year == reference.year && e.date.month == reference.month,
    );
    final theoreticalNet = monthEntries.fold<double>(0, (sum, e) => sum + e.result.net);
    final fuelTheoretical = monthEntries.fold<double>(0, (sum, e) => sum + e.result.fuelCost);

    final monthFuelEntries = fuelEntries.where(
      (e) => e.date.year == reference.year && e.date.month == reference.month,
    );
    final hasFuelEntries = monthFuelEntries.isNotEmpty;
    final realFuel = monthFuelEntries.fold<double>(0, (sum, e) => sum + e.amount);

    final fixedCharges = fixedExpenses.fold<double>(0, (sum, e) => sum + e.amountPerMonth);

    final realNet = hasFuelEntries
        ? (theoreticalNet + fuelTheoretical) - realFuel - fixedCharges
        : theoreticalNet - fixedCharges;

    return RealMonthlyNet(
      theoreticalNet: theoreticalNet,
      fuelTheoretical: fuelTheoretical,
      realFuel: realFuel,
      hasFuelEntries: hasFuelEntries,
      fixedCharges: fixedCharges,
      realNet: realNet,
    );
  }
}

/// Détail du calcul du net réel d'un mois — voir
/// [StatsService.realNetForMonth].
class RealMonthlyNet {
  final double theoreticalNet;
  final double fuelTheoretical;
  final double realFuel;
  final bool hasFuelEntries;
  final double fixedCharges;
  final double realNet;

  const RealMonthlyNet({
    required this.theoreticalNet,
    required this.fuelTheoretical,
    required this.realFuel,
    required this.hasFuelEntries,
    required this.fixedCharges,
    required this.realNet,
  });
}

/// Net moyen et cumulé d'une plateforme sur l'historique disponible —
/// CLAUDE.md §10.2.e.
class PlatformStats {
  final String label;
  final int rideCount;
  final double totalNet;
  final double averageNet;

  const PlatformStats({
    required this.label,
    required this.rideCount,
    required this.totalNet,
    required this.averageNet,
  });
}
