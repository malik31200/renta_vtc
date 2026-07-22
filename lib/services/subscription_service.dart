import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription_status.dart';

/// Achat in-app Premium — CLAUDE.md §10.1/10.3. `in_app_purchase` gère
/// Google Play Billing / StoreKit avec une seule API, pas de backend de
/// paiement custom. Non disponible sur le web (le plugin ne le supporte
/// pas) : chaque méthode se dégrade sans plantage sur cette plateforme.
///
/// `InAppPurchase.instance` ne doit JAMAIS être touché sur le web — le
/// champ statique `late` de la plateforme sous-jacente n'y est jamais
/// initialisé (aucune implémentation web n'existe pour ce plugin), donc y
/// accéder lève une `LateInitializationError` immédiate. D'où l'accès
/// paresseux via un getter plutôt qu'un champ final construit d'entrée.
class SubscriptionService {
  static const String monthlyProductId = 'renta_vtc_premium_monthly';
  static const String annualProductId = 'renta_vtc_premium_annual';
  static const Set<String> productIds = {monthlyProductId, annualProductId};

  InAppPurchase get _iap => InAppPurchase.instance;

  bool get isSupportedOnThisPlatform => !kIsWeb;

  Future<bool> isAvailable() async {
    if (!isSupportedOnThisPlatform) return false;
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<List<ProductDetails>> queryProducts() async {
    if (!isSupportedOnThisPlatform) return const [];
    try {
      final response = await _iap.queryProductDetails(productIds);
      return response.productDetails;
    } catch (_) {
      return const [];
    }
  }

  /// Stream des mises à jour d'achat — à écouter dès le démarrage de l'app
  /// pour capter les achats déjà en cours (ex: reçu validé après relance).
  /// Flux vide sur le web, plutôt que de toucher `InAppPurchase.instance`.
  Stream<List<PurchaseDetails>> get purchaseStream =>
      isSupportedOnThisPlatform ? _iap.purchaseStream : const Stream.empty();

  Future<void> buy(ProductDetails product) {
    if (!isSupportedOnThisPlatform) return Future.value();
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Vérification périodique du statut d'abonnement à la reprise de l'app
  /// (CLAUDE.md §10.3), plutôt qu'une vérification serveur puisque l'app
  /// reste sans backend.
  Future<void> restorePurchases() async {
    if (!isSupportedOnThisPlatform) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {
      // Pas de connexion store, ou plateforme non configurée : le statut
      // local précédemment enregistré reste la meilleure estimation connue.
    }
  }

  Future<void> completePurchase(PurchaseDetails purchase) {
    if (!isSupportedOnThisPlatform) return Future.value();
    if (purchase.pendingCompletePurchase) {
      return _iap.completePurchase(purchase);
    }
    return Future.value();
  }

  /// Dérive un statut local à partir d'un achat validé. Simplification
  /// assumée pour une app 100% locale sans backend : la date d'expiration
  /// est calculée depuis la période du produit plutôt que revalidée par un
  /// reçu serveur — `restorePurchases()` à chaque reprise reste la garde-fou
  /// contre un statut local périmé.
  SubscriptionStatus statusFromPurchase(PurchaseDetails purchase) {
    final isMonthly = purchase.productID == monthlyProductId;
    final period = isMonthly ? const Duration(days: 31) : const Duration(days: 366);
    return SubscriptionStatus(isPremium: true, expiresAt: DateTime.now().add(period));
  }
}
