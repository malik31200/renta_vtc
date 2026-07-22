import 'package:flutter/material.dart';

import '../models/driver_profile.dart';
import '../models/ride_entry.dart';
import '../theme/app_theme.dart';
import '../utils/number_parsing.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/backup_section.dart';
import '../widgets/form_card.dart';
import '../widgets/labeled_field.dart';
import '../widgets/section_title.dart';
import '../widgets/toggle_field.dart';
import '../widgets/vehicle_switcher.dart';

/// Réglages, saisis une fois par véhicule : profil véhicule + statut fiscal
/// — CLAUDE.md §7.2, multi-véhicules §10.2.d.
class SettingsScreen extends StatefulWidget {
  final List<DriverProfile> profiles;
  final String activeProfileId;
  final ValueChanged<DriverProfile> onSaved;
  final ValueChanged<String> onSelectProfile;
  final VoidCallback onAddProfile;
  final ValueChanged<String> onDeleteProfile;

  final double annualThreshold;
  final ValueChanged<double> onThresholdChanged;

  final bool isPremium;
  final ValueChanged<bool> onTogglePremiumDevMode;

  final List<RideEntry> rideHistory;
  final void Function(List<DriverProfile> profiles, List<RideEntry> history) onRestoreBackup;

  const SettingsScreen({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    required this.onSaved,
    required this.onSelectProfile,
    required this.onAddProfile,
    required this.onDeleteProfile,
    required this.annualThreshold,
    required this.onThresholdChanged,
    required this.isPremium,
    required this.onTogglePremiumDevMode,
    required this.rideHistory,
    required this.onRestoreBackup,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  late TextEditingController _vehicleNameController;
  late TextEditingController _consumptionController;
  late TextEditingController _fuelPriceController;
  late TextEditingController _urssafRateController;
  late bool _isElectric;
  late String _editingProfileId;
  late final TextEditingController _thresholdController;

  // Voir HomeScreen : évite que PageView reconstruise cet écran (et perde
  // les champs en cours d'édition) à chaque glissement d'onglet.
  @override
  bool get wantKeepAlive => true;

  DriverProfile get _activeProfile =>
      widget.profiles.firstWhere((p) => p.id == widget.activeProfileId);

  @override
  void initState() {
    super.initState();
    _editingProfileId = widget.activeProfileId;
    _initControllers(_activeProfile);
    _thresholdController =
        TextEditingController(text: NumberParsing.formatDecimal(widget.annualThreshold));
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le profil actif a changé depuis l'extérieur (ex: sélection dans le
    // switcher) : on recharge les champs pour refléter le bon véhicule.
    if (widget.activeProfileId != _editingProfileId) {
      _editingProfileId = widget.activeProfileId;
      _disposeControllers();
      _initControllers(_activeProfile);
    }
  }

  void _disposeControllers() {
    _vehicleNameController.dispose();
    _consumptionController.dispose();
    _fuelPriceController.dispose();
    _urssafRateController.dispose();
  }

  void _initControllers(DriverProfile p) {
    _vehicleNameController = TextEditingController(text: p.vehicleName);
    _consumptionController = TextEditingController(
      text: p.consumptionL100km == 0 ? '' : NumberParsing.formatDecimal(p.consumptionL100km),
    );
    _fuelPriceController = TextEditingController(
      text: p.fuelPricePerLiter == 0 ? '' : NumberParsing.formatDecimal(p.fuelPricePerLiter),
    );
    _urssafRateController = TextEditingController(
      text: NumberParsing.formatDecimal(p.urssafRate * 100),
    );
    _isElectric = p.isElectric;
  }

  @override
  void dispose() {
    _disposeControllers();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = DriverProfile(
      id: _activeProfile.id,
      vehicleName: _vehicleNameController.text.trim(),
      consumptionL100km: NumberParsing.parse(_consumptionController.text),
      fuelPricePerLiter: NumberParsing.parse(_fuelPriceController.text),
      urssafRate: NumberParsing.parse(_urssafRateController.text) / 100,
      isElectric: _isElectric,
    );
    widget.onSaved(profile);

    final threshold = NumberParsing.parse(_thresholdController.text);
    if (threshold > 0) widget.onThresholdChanged(threshold);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const AppTopBar(title: 'Mon profil'),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(),
              SizedBox(width: 6),
              Text(
                'Enregistré localement, sur cet appareil',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green),
              ),
            ],
          ),
        ),
        const SectionTitle('Véhicules'),
        VehicleSwitcher(
          profiles: widget.profiles,
          activeProfileId: widget.activeProfileId,
          onSelect: widget.onSelectProfile,
          onAdd: widget.onAddProfile,
        ),
        const SizedBox(height: 14),
        FormCard(children: [
          LabeledField(
            icon: Icons.directions_car_outlined,
            label: 'Modèle',
            sublabel: 'Nom libre, informatif',
            controller: _vehicleNameController,
            valueColor: AppColors.textPrimary,
            numeric: false,
            expandInput: true,
          ),
          ToggleField(
            icon: Icons.ev_station_outlined,
            label: '100% électrique',
            sublabel: 'Change les unités ci-dessous',
            value: _isElectric,
            onChanged: (value) => setState(() => _isElectric = value),
          ),
          LabeledField(
            icon: _isElectric ? Icons.ev_station_outlined : Icons.local_gas_station_outlined,
            label: 'Consommation',
            controller: _consumptionController,
            suffix: _isElectric ? 'kWh/100km' : 'L/100km',
          ),
          LabeledField(
            icon: _isElectric ? Icons.bolt : Icons.attach_money,
            label: _isElectric ? 'Prix électricité' : 'Prix carburant',
            controller: _fuelPriceController,
            suffix: _isElectric ? '€/kWh' : '€/L',
          ),
        ]),
        const SectionTitle('Statut fiscal'),
        FormCard(children: [
          LabeledField(
            icon: Icons.description_outlined,
            label: 'Auto-entrepreneur',
            sublabel: 'Cotisations URSSAF VTC',
            controller: _urssafRateController,
            suffix: '%',
            inputWidth: 50,
          ),
          LabeledField(
            icon: Icons.speed_outlined,
            label: 'Plafond annuel',
            sublabel: 'Seuil auto-entrepreneur, alerte à l\'approche',
            controller: _thresholdController,
            suffix: '€',
            inputWidth: 90,
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Enregistrer le profil'),
            ),
          ),
        ),
        if (widget.profiles.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => widget.onDeleteProfile(_activeProfile.id),
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                label: const Text(
                  'Supprimer ce véhicule',
                  style: TextStyle(color: AppColors.red),
                ),
              ),
            ),
          ),
        const SectionTitle('Sauvegarde'),
        BackupSection(
          profiles: widget.profiles,
          history: widget.rideHistory,
          onRestore: widget.onRestoreBackup,
        ),
        const SectionTitle('Abonnement'),
        FormCard(children: [
          ToggleField(
            icon: Icons.workspace_premium_outlined,
            label: 'Premium (mode test)',
            sublabel: 'Bascule locale — remplace le vrai achat in-app, indisponible sur cet aperçu web',
            value: widget.isPremium,
            onChanged: widget.onTogglePremiumDevMode,
          ),
        ]),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
    );
  }
}
