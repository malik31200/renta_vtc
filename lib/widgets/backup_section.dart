import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/driver_profile.dart';
import '../models/ride_entry.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

/// Export/import JSON complet (profils + historique) — CLAUDE.md §10.4.b.
/// Filet de sécurité en plus de la sauvegarde cloud native de l'OS,
/// fonctionne même en changeant d'OS (Android ↔ iOS).
class BackupSection extends StatefulWidget {
  final List<DriverProfile> profiles;
  final List<RideEntry> history;
  final void Function(List<DriverProfile> profiles, List<RideEntry> history) onRestore;

  const BackupSection({
    super.key,
    required this.profiles,
    required this.history,
    required this.onRestore,
  });

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  static const _backup = BackupService();
  String? _error;
  bool _busy = false;

  Future<void> _export() async {
    final json = _backup.buildBackupJson(profiles: widget.profiles, history: widget.history);
    final fileName = 'renta-vtc-sauvegarde-${DateTime.now().toIso8601String().split('T').first}.json';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(json), name: fileName, mimeType: 'application/json')],
        subject: fileName,
      ),
    );
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) {
        setState(() => _busy = false);
        return;
      }

      final bytes = await result.files.single.readAsBytes();
      final raw = utf8.decode(bytes);
      final data = _backup.parseBackupJson(raw);
      widget.onRestore(data.profiles, data.history);
    } catch (_) {
      setState(() => _error = 'Fichier de sauvegarde illisible ou invalide.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sans sauvegarde cloud OS activée ni export manuel avant un changement '
            'd\'appareil, les données sont définitivement perdues à la désinstallation.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Exporter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    side: const BorderSide(color: AppColors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Importer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 11, color: AppColors.red)),
          ],
        ],
      ),
    );
  }
}
