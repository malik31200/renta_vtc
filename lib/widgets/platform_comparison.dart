import 'package:flutter/material.dart';

import '../models/ride_entry.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/number_parsing.dart';

/// Comparateur de plateformes — CLAUDE.md §10.2.e. N'a de sens qu'avec au
/// moins 2 plateformes distinctes dans l'historique ; sinon rien à comparer.
class PlatformComparison extends StatelessWidget {
  final List<RideEntry> entries;

  const PlatformComparison({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    const stats = StatsService();
    final byPlatform = stats.byPlatform(entries);
    if (byPlatform.length < 2) return const SizedBox.shrink();

    final maxAverageNet =
        byPlatform.map((s) => s.averageNet).fold<double>(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stat in byPlatform)
          _PlatformRow(stat: stat, maxAverageNet: maxAverageNet),
      ],
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final PlatformStats stat;
  final double maxAverageNet;

  const _PlatformRow({required this.stat, required this.maxAverageNet});

  @override
  Widget build(BuildContext context) {
    final color = stat.averageNet >= 0 ? AppColors.green : AppColors.red;
    final ratio = maxAverageNet <= 0 ? 0.0 : (stat.averageNet / maxAverageNet).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        stat.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stat.rideCount} course${stat.rideCount > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberParsing.formatAmount(stat.averageNet)} € / course',
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
