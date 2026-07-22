import 'package:flutter/material.dart';

import '../models/ride_entry.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/number_parsing.dart';

/// Ligne de tuiles statistiques calculées à la volée depuis l'historique —
/// CLAUDE.md §10.2.b. Une "tuile stat" par indicateur (valeur + label), pas
/// de graphique : ce sont des chiffres uniques, pas une série.
class StatsSummary extends StatelessWidget {
  final List<RideEntry> entries;
  final double annualThreshold;

  const StatsSummary({super.key, required this.entries, required this.annualThreshold});

  @override
  Widget build(BuildContext context) {
    const stats = StatsService();
    final now = DateTime.now();

    final perKm = stats.averageNetPerKm(entries);
    final perHour = stats.averageNetPerHour(entries);
    final today = stats.totalNetOnDay(entries, now);
    final thisWeek = stats.totalNetSince(entries, StatsService.startOfWeek(now));
    final thisMonth = stats.totalNetInMonth(entries, now);
    final yearToDate = stats.totalClientPriceInYear(entries, now.year);
    final thresholdRatio = annualThreshold <= 0 ? 0.0 : yearToDate / annualThreshold;
    final thresholdColor = thresholdRatio >= 0.9
        ? AppColors.red
        : (thresholdRatio >= 0.7 ? AppColors.amber : AppColors.green);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatTile(
            label: 'Net moyen / km',
            value: perKm,
            tooltip: 'Somme des net ÷ somme des km parcourus sur toutes les courses enregistrées. Une moyenne, pas un montant perçu.',
          ),
          _StatTile(
            label: 'Net / h',
            value: perHour,
            tooltip: 'Somme des net ÷ somme des durées (courses avec durée renseignée uniquement). Une moyenne indicative, pas un montant réellement perçu sur 1 heure.',
          ),
          _StatTile(label: 'Aujourd\'hui', value: today),
          _StatTile(label: 'Cette semaine', value: thisWeek),
          _StatTile(label: 'Ce mois', value: thisMonth),
          _StatTile(
            label: 'CA annuel',
            displayText:
                '${NumberParsing.formatAmount(yearToDate)} / ${NumberParsing.formatAmount(annualThreshold)} €',
            colorOverride: thresholdColor,
            tooltip: 'Chiffre d\'affaires brut (prix client) encaissé cette année civile, sur le plafond auto-entrepreneur réglé dans Réglages.',
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double? value;
  final String? displayText;
  final Color? colorOverride;
  final String? tooltip;

  const _StatTile({
    required this.label,
    this.value,
    this.displayText,
    this.colorOverride,
    this.tooltip,
  }) : assert(value != null || displayText != null);

  @override
  Widget build(BuildContext context) {
    final color = colorOverride ?? ((value ?? 0) >= 0 ? AppColors.green : AppColors.red);
    final text = displayText ?? '${NumberParsing.formatAmount(value!)} €';

    return Container(
      width: 138,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 3),
                Tooltip(
                  message: tooltip!,
                  triggerMode: TooltipTriggerMode.tap,
                  textStyle: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
