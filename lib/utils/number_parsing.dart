import 'package:intl/intl.dart';

/// Fonction centralisée de parsing/formatage des nombres saisis par
/// l'utilisateur (virgule ou point français) — CLAUDE.md §12 : les montants
/// restent des `double`, jamais des `String` parsés à la volée dans l'UI.
class NumberParsing {
  NumberParsing._();

  static final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'fr_FR');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.#', 'fr_FR');

  /// Parse une saisie utilisateur en double. Accepte virgule ou point comme
  /// séparateur décimal. Retourne 0 si la saisie est vide ou invalide.
  static double parse(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized) ?? 0;
  }

  /// Formate un montant avec deux décimales à la française, ex: "12,24".
  static String formatAmount(double value) => _amountFormat.format(value);

  /// Formate une valeur décimale simple (ex: distance, consommation) sans
  /// décimales superflues, ex: "4,7".
  static String formatDecimal(double value) => _decimalFormat.format(value);
}
