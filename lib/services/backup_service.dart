import 'dart:convert';

import '../models/driver_profile.dart';
import '../models/ride_entry.dart';

/// Export/import JSON complet (profils + historique) — CLAUDE.md §10.4.b.
/// Filet de sécurité cross-plateforme en plus de la sauvegarde native OS :
/// aucune donnée ne transite par un serveur, uniquement un fichier partagé
/// via le système natif (`share_plus`) au choix de l'utilisateur.
class BackupService {
  const BackupService();

  static const _formatVersion = 1;

  String buildBackupJson({
    required List<DriverProfile> profiles,
    required List<RideEntry> history,
  }) {
    final backup = {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Lève une [FormatException] si le fichier n'est pas une sauvegarde
  /// Renta VTC valide.
  BackupData parseBackupJson(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic> || json['profiles'] is! List || json['history'] is! List) {
      throw const FormatException('Fichier de sauvegarde invalide.');
    }

    final profiles = (json['profiles'] as List)
        .cast<Map<String, dynamic>>()
        .map(DriverProfile.fromJson)
        .toList();
    final history = (json['history'] as List)
        .cast<Map<String, dynamic>>()
        .map(RideEntry.fromJson)
        .toList();

    if (profiles.isEmpty) {
      throw const FormatException('La sauvegarde ne contient aucun véhicule.');
    }

    return BackupData(profiles: profiles, history: history);
  }
}

class BackupData {
  final List<DriverProfile> profiles;
  final List<RideEntry> history;

  const BackupData({required this.profiles, required this.history});
}
