import '../models/ride_entry.dart';
import '../utils/date_formatting.dart';
import '../utils/number_parsing.dart';

/// Export CSV du chiffre d'affaires brut cumulé sur une période — CLAUDE.md
/// §10.2.c. Ne remplace pas le relevé officiel de la plateforme, sert à
/// comparer/consolider les propres saisies du chauffeur.
class ExportService {
  const ExportService();

  static const List<String> _header = [
    'Date',
    'Heure',
    'Plateforme',
    'Distance (km)',
    'Prix client (€)',
    'Versé plateforme (€)',
    'Carburant (€)',
    'URSSAF (€)',
    'Net (€)',
  ];

  String buildCsv(List<RideEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final buffer = StringBuffer()..writeln(_row(_header));

    for (final entry in sorted) {
      final r = entry.result;
      buffer.writeln(_row([
        DateFormatting.formatDateOnly(entry.date),
        DateFormatting.formatTimeOnly(entry.date),
        entry.platformName ?? '',
        NumberParsing.formatDecimal(r.rideKm),
        NumberParsing.formatAmount(r.clientPrice),
        NumberParsing.formatAmount(r.platformPayout),
        NumberParsing.formatAmount(r.fuelCost),
        NumberParsing.formatAmount(r.urssafCost),
        NumberParsing.formatAmount(r.net),
      ]));
    }

    return buffer.toString();
  }

  /// Entrées dont la date tombe dans le même trimestre calendaire que
  /// [reference] — la période par défaut, alignée sur la fréquence de
  /// déclaration URSSAF.
  List<RideEntry> entriesInQuarter(List<RideEntry> entries, DateTime reference) {
    final start = startOfQuarter(reference);
    final end = DateTime(start.year, start.month + 3, 1);
    return entries.where((e) => !e.date.isBefore(start) && e.date.isBefore(end)).toList();
  }

  static DateTime startOfQuarter(DateTime reference) {
    final quarterStartMonth = ((reference.month - 1) ~/ 3) * 3 + 1;
    return DateTime(reference.year, quarterStartMonth, 1);
  }

  static int quarterOf(DateTime reference) => ((reference.month - 1) ~/ 3) + 1;

  String _row(List<String> fields) => fields.map(_escape).join(';');

  String _escape(String field) {
    if (field.contains(';') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
