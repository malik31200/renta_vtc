import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ride_entry.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/number_parsing.dart';

/// Export CSV du CA du trimestre en cours — CLAUDE.md §10.2.c. Ne remplace
/// pas le relevé officiel de la plateforme, précisé explicitement dans l'UI
/// pour éviter toute confusion sur la source de vérité fiscale.
class ExportSection extends StatelessWidget {
  final List<RideEntry> entries;

  const ExportSection({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    const export = ExportService();
    final now = DateTime.now();
    final quarterEntries = export.entriesInQuarter(entries, now);
    final totalClientPrice = quarterEntries.fold<double>(0, (sum, e) => sum + e.result.clientPrice);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'T${ExportService.quarterOf(now)} ${now.year} · ${quarterEntries.length} course${quarterEntries.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'CA brut : ${NumberParsing.formatAmount(totalClientPrice)} €',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sert à comparer/consolider tes propres saisies — ne remplace pas le relevé officiel de la plateforme.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: quarterEntries.isEmpty ? null : () => _export(quarterEntries, now),
              icon: const Icon(Icons.ios_share, size: 16),
              label: const Text('Exporter le trimestre (CSV)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: const BorderSide(color: AppColors.amber),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(List<RideEntry> quarterEntries, DateTime now) async {
    const export = ExportService();
    final csv = export.buildCsv(quarterEntries);
    final fileName =
        'renta-vtc-T${ExportService.quarterOf(now)}-${now.year}.csv';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(csv), name: fileName, mimeType: 'text/csv')],
        subject: fileName,
      ),
    );
  }
}
