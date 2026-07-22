import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/number_parsing.dart';

/// Bandeau d'alerte affiché quand le CA annuel approche le plafond
/// auto-entrepreneur — CLAUDE.md §10.2.f. Ne s'affiche qu'à partir de 70 %
/// du seuil pour rester un signal d'alerte, pas un widget de tableau de bord
/// permanent.
class ThresholdBanner extends StatelessWidget {
  final double currentAmount;
  final double threshold;

  const ThresholdBanner({super.key, required this.currentAmount, required this.threshold});

  @override
  Widget build(BuildContext context) {
    if (threshold <= 0) return const SizedBox.shrink();
    final ratio = (currentAmount / threshold).clamp(0.0, 1.0);
    if (ratio < 0.7) return const SizedBox.shrink();

    final color = ratio >= 0.9 ? AppColors.red : AppColors.amber;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plafond auto-entrepreneur : ${(ratio * 100).round()} %',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${NumberParsing.formatAmount(currentAmount)} € encaissés cette année sur ${NumberParsing.formatAmount(threshold)} € de plafond.',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
