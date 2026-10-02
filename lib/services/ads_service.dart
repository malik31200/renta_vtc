import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Init du SDK AdMob + consentement RGPD via Google UMP — CLAUDE.md §10.5.
/// Non disponible sur le web (le plugin ne le supporte pas) : dégradation
/// silencieuse sur cette plateforme, comme pour `in_app_purchase`.
class AdsService {
  /// IDs de bloc d'annonces bannière du vrai compte AdMob (CLAUDE.md
  /// §10.5.a).
  static const String androidBannerAdUnitId = 'ca-app-pub-3858509501102713/2364813577';
  static const String iosBannerAdUnitId = 'ca-app-pub-3858509501102713/8838988518';

  static String get bannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? iosBannerAdUnitId : androidBannerAdUnitId;

  bool get isSupportedOnThisPlatform => !kIsWeb;

  Future<void> init() async {
    if (!isSupportedOnThisPlatform) return;
    try {
      await _requestConsent();
      await _requestTrackingAuthorization();
      await MobileAds.instance.initialize();
    } catch (_) {
      // Échec silencieux (pas de réseau, SDK indisponible…) : la bannière
      // ne se chargera simplement pas, pas d'impact sur le reste de l'app.
    }
  }

  Future<void> _requestConsent() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        final formAvailable = await ConsentInformation.instance.isConsentFormAvailable();
        if (formAvailable) {
          await _loadAndShowConsentFormIfRequired();
        }
        if (!completer.isCompleted) completer.complete();
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  /// Demande ATT (iOS uniquement), après le formulaire UMP et avant
  /// l'init AdMob, pour qu'aucune donnée de tracking ne soit collectée
  /// avant la réponse de l'utilisateur. Le léger délai laisse l'app passer
  /// à l'état actif : sinon iOS ignore la demande sans rien afficher.
  Future<void> _requestTrackingAuthorization() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  Future<void> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadConsentForm(
      (consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((_) {
            if (!completer.isCompleted) completer.complete();
          });
        } else if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}
