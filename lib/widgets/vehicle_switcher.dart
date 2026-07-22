import 'package:flutter/material.dart';

import '../models/driver_profile.dart';
import '../theme/app_theme.dart';

/// Sélecteur de véhicule actif — multi-véhicules, CLAUDE.md §10.2.d. Un chip
/// par profil enregistré + un chip "+" pour en ajouter un nouveau.
class VehicleSwitcher extends StatelessWidget {
  final List<DriverProfile> profiles;
  final String activeProfileId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  const VehicleSwitcher({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final profile in profiles) ...[
            _VehicleChip(
              label: profile.vehicleName.isEmpty ? 'Nouveau véhicule' : profile.vehicleName,
              selected: profile.id == activeProfileId,
              onTap: () => onSelect(profile.id),
            ),
            const SizedBox(width: 8),
          ],
          _VehicleChip(
            label: '+ Ajouter',
            selected: false,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleChip({required this.label, required this.selected, required this.onTap});

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
