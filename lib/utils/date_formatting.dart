/// Formatage de date simple, sans dépendance aux données de locale d'`intl`
/// (évite d'avoir à initialiser `initializeDateFormatting` juste pour un
/// format jj/mm/aaaa · hh:mm).
class DateFormatting {
  DateFormatting._();

  static String formatShort(DateTime date) =>
      '${formatDateOnly(date)} · ${formatTimeOnly(date)}';

  static String formatDateOnly(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String formatTimeOnly(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}
