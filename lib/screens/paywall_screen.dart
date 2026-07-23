import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

/// Écran affiché à la place de l'Historique tant que l'utilisateur n'est
/// pas Premium — CLAUDE.md §10.1 : le calcul ponctuel (écran Course) ne
/// passe jamais derrière ce mur, seuls historique/stats/export/comparateur
/// en dépendent.
class PaywallScreen extends StatelessWidget {
  final List<ProductDetails> products;
  final bool isSupported;
  final ValueChanged<ProductDetails> onSubscribe;
  final VoidCallback onRestore;

  const PaywallScreen({
    super.key,
    required this.products,
    required this.isSupported,
    required this.onSubscribe,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const AppTopBar(title: 'Renta VTC Premium'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF14161B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_outlined, color: AppColors.amber, size: 28),
                const SizedBox(height: 12),
                const Text(
                  'Pilote ton activité dans la durée',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Historique des courses, statistiques (net/km, net/h), comparateur de '
                  'plateformes, export CSV et multi-véhicules. Le calcul ponctuel d\'une '
                  'course reste gratuit, sans compte, comme aujourd\'hui.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        if (!isSupported)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                kDebugMode
                    ? 'Les achats in-app ne sont pas disponibles sur cet aperçu web — '
                        'uniquement sur l\'app Android/iOS publiée. Un mode test est disponible '
                        'dans Réglages en attendant.'
                    : 'Les achats in-app ne sont pas disponibles sur cet aperçu — '
                        'uniquement sur l\'app Android/iOS publiée.',
                style: const TextStyle(fontSize: 12, color: AppColors.amber),
              ),
            ),
          )
        else if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              'Offres indisponibles pour le moment.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                for (final product in products) _PlanTile(product: product, onTap: () => onSubscribe(product)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: TextButton(
            onPressed: onRestore,
            child: const Text('Restaurer mes achats', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  final ProductDetails product;
  final VoidCallback onTap;

  const _PlanTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    Text(
                      product.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(product.description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text(
                product.price,
                style: const TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
