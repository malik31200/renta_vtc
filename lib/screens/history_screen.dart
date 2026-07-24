import 'package:flutter/material.dart';

import '../models/fixed_expense.dart';
import '../models/fuel_entry.dart';
import '../models/ride_entry.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatting.dart';
import '../utils/number_parsing.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/charges_section.dart';
import '../widgets/export_section.dart';
import '../widgets/platform_comparison.dart';
import '../widgets/section_title.dart';
import '../widgets/stats_summary.dart';
import '../widgets/threshold_banner.dart';

/// Historique des courses (Premium) — CLAUDE.md §10.2.a.
class HistoryScreen extends StatelessWidget {
  final List<RideEntry> entries;
  final ValueChanged<RideEntry> onDelete;
  final double annualThreshold;
  final List<FixedExpense> fixedExpenses;
  final List<FuelEntry> fuelEntries;
  final bool isElectric;
  final ValueChanged<FixedExpense> onAddFixedExpense;
  final ValueChanged<FixedExpense> onDeleteFixedExpense;
  final ValueChanged<FuelEntry> onAddFuelEntry;
  final ValueChanged<FuelEntry> onDeleteFuelEntry;

  const HistoryScreen({
    super.key,
    required this.entries,
    required this.onDelete,
    required this.annualThreshold,
    required this.fixedExpenses,
    required this.fuelEntries,
    required this.isElectric,
    required this.onAddFixedExpense,
    required this.onDeleteFixedExpense,
    required this.onAddFuelEntry,
    required this.onDeleteFuelEntry,
  });

  @override
  Widget build(BuildContext context) {
    const stats = StatsService();
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    final showComparison = stats.byPlatform(entries).length >= 2;
    final yearToDateAmount = stats.totalClientPriceInYear(entries, DateTime.now().year);

    return Column(
      children: [
        const AppTopBar(title: 'Historique'),
        Expanded(
          child: entries.isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    ThresholdBanner(currentAmount: yearToDateAmount, threshold: annualThreshold),
                    StatsSummary(entries: entries, annualThreshold: annualThreshold),
                    if (showComparison) ...[
                      const SectionTitle('Par plateforme'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: PlatformComparison(entries: entries),
                      ),
                    ],
                    const SectionTitle('Charges du mois'),
                    ChargesSection(
                      entries: entries,
                      fixedExpenses: fixedExpenses,
                      fuelEntries: fuelEntries,
                      isElectric: isElectric,
                      onAddFixedExpense: onAddFixedExpense,
                      onDeleteFixedExpense: onDeleteFixedExpense,
                      onAddFuelEntry: onAddFuelEntry,
                      onDeleteFuelEntry: onDeleteFuelEntry,
                    ),
                    const SectionTitle('Export'),
                    ExportSection(entries: entries),
                    const SectionTitle('Courses'),
                    for (final entry in sorted)
                      _HistoryTile(entry: entry, onDelete: () => onDelete(entry)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final RideEntry entry;
  final VoidCallback onDelete;

  const _HistoryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final result = entry.result;
    final netColor = result.net >= 0 ? AppColors.green : AppColors.red;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (entry.platformName != null) ...[
                      _PlatformBadge(entry.platformName!),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      DateFormatting.formatShort(entry.date),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${NumberParsing.formatDecimal(result.rideKm)} km · Prix client ${NumberParsing.formatAmount(result.clientPrice)} €'
                  '${entry.durationMinutes != null ? ' · ${entry.durationMinutes} min' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Text(
            '${NumberParsing.formatAmount(result.net)} €',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: netColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
            onPressed: onDelete,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String platformName;

  const _PlatformBadge(this.platformName);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        platformName,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Aucune course enregistrée pour l\'instant',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chaque calcul est ajouté ici automatiquement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
