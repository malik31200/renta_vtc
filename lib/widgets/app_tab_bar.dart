import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _TabDef {
  final IconData icon;
  final String label;

  const _TabDef(this.icon, this.label);
}

/// Barre d'onglets du bas — CLAUDE.md §6-7.
class AppTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppTabBar({super.key, required this.currentIndex, required this.onTap});

  static const _tabs = [
    _TabDef(Icons.calculate_outlined, 'Course'),
    _TabDef(Icons.settings_outlined, 'Réglages'),
    _TabDef(Icons.history, 'Historique'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabs[i].icon,
                    size: 20,
                    color: i == currentIndex ? AppColors.amber : AppColors.textMuted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _tabs[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: i == currentIndex ? AppColors.amber : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
