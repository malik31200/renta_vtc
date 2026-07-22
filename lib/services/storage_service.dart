import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver_profile.dart';
import '../models/ride_entry.dart';
import '../models/subscription_status.dart';

/// Plafond auto-entrepreneur par défaut (2026) — CLAUDE.md §10.2.f, valeur
/// modifiable par l'utilisateur car ce seuil évolue chaque année.
const double kDefaultAnnualCapThreshold = 83600.0;

/// Persistance locale des profils véhicule et de l'historique des courses,
/// en JSON dans SharedPreferences. Pas de compte, pas de backend : tout
/// reste sur l'appareil (CLAUDE.md §2).
class StorageService {
  const StorageService();

  /// Clé historique, avant le passage au multi-véhicules (§10.2.d) — encore
  /// lue pour migrer les profils déjà sauvegardés par des versions
  /// antérieures de l'app, jamais réécrite.
  static const _legacyDriverProfileKey = 'driver_profile';

  static const _driverProfilesKey = 'driver_profiles';
  static const _activeProfileIdKey = 'active_profile_id';
  static const _rideHistoryKey = 'ride_history';
  static const _annualThresholdKey = 'annual_cap_threshold';
  static const _lastThresholdAlertDateKey = 'last_threshold_alert_date';
  static const _subscriptionStatusKey = 'subscription_status';

  Future<List<DriverProfile>> loadDriverProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_driverProfilesKey);
    if (raw != null) {
      return raw
          .map((e) => DriverProfile.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    }

    final legacyRaw = prefs.getString(_legacyDriverProfileKey);
    if (legacyRaw == null) return [];

    final legacy = DriverProfile.fromJson(jsonDecode(legacyRaw) as Map<String, dynamic>);
    final migrated = legacy.id.isEmpty
        ? DriverProfile(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            vehicleName: legacy.vehicleName,
            consumptionL100km: legacy.consumptionL100km,
            fuelPricePerLiter: legacy.fuelPricePerLiter,
            urssafRate: legacy.urssafRate,
            isElectric: legacy.isElectric,
          )
        : legacy;
    await saveDriverProfiles([migrated]);
    await saveActiveProfileId(migrated.id);
    return [migrated];
  }

  Future<String?> loadActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileIdKey);
  }

  Future<void> saveDriverProfiles(List<DriverProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _driverProfilesKey,
      profiles.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  Future<void> saveActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileIdKey, id);
  }

  Future<List<RideEntry>> loadRideHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_rideHistoryKey) ?? const [];
    return raw
        .map((e) => RideEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRideHistory(List<RideEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _rideHistoryKey,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<double> loadAnnualThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_annualThresholdKey) ?? kDefaultAnnualCapThreshold;
  }

  Future<void> saveAnnualThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_annualThresholdKey, value);
  }

  /// Empêche de renvoyer la notification de seuil plusieurs fois le même
  /// jour à chaque reprise de l'app.
  Future<DateTime?> loadLastThresholdAlertDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastThresholdAlertDateKey);
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> saveLastThresholdAlertDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastThresholdAlertDateKey, date.toIso8601String());
  }

  Future<SubscriptionStatus> loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subscriptionStatusKey);
    if (raw == null) return const SubscriptionStatus.free();
    return SubscriptionStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSubscriptionStatus(SubscriptionStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionStatusKey, jsonEncode(status.toJson()));
  }
}
