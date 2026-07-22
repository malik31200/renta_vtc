import 'package:flutter/material.dart';

import '../models/ride_entry.dart';
import '../theme/app_theme.dart';

/// Sélecteur de plateforme (Uber/Bolt/Heetch/Autre) pour tagger une course —
/// saisie manuelle, CLAUDE.md §10.2.a.
class PlatformSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const PlatformSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final platform in kRidePlatforms)
          _PlatformChip(
            label: platform,
            selected: selected == platform,
            onTap: () => onChanged(selected == platform ? null : platform),
          ),
      ],
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PlatformChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber.withValues(alpha: 0.15) : AppColors.surface,
          border: Border.all(color: selected ? AppColors.amber : AppColors.divider),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.amber : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
