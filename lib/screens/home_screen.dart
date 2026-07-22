import 'package:flutter/material.dart';

import '../models/driver_profile.dart';
import '../models/ride_entry.dart';
import '../models/ride_result.dart';
import '../services/calculator_service.dart';
import '../utils/number_parsing.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/form_card.dart';
import '../widgets/labeled_field.dart';
import '../widgets/platform_selector.dart';
import '../widgets/readout_card.dart';
import '../widgets/section_title.dart';

/// Écran principal : saisie course + résultat — CLAUDE.md §7.1.
class HomeScreen extends StatefulWidget {
  final DriverProfile profile;
  final VoidCallback onOpenSettings;
  final ValueChanged<RideEntry> onRideCalculated;
  final bool isPremium;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.onOpenSettings,
    required this.onRideCalculated,
    required this.isPremium,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _calculator = CalculatorService();

  final _rideKmController = TextEditingController();
  final _clientPriceController = TextEditingController();
  final _platformPayoutController = TextEditingController();
  final _durationController = TextEditingController();
  final _scrollController = ScrollController();

  RideResult? _result;
  String? _selectedPlatform;

  @override
  void dispose() {
    _rideKmController.dispose();
    _clientPriceController.dispose();
    _platformPayoutController.dispose();
    _durationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    final result = _calculator.computeRide(
      profile: widget.profile,
      rideKm: NumberParsing.parse(_rideKmController.text),
      clientPrice: NumberParsing.parse(_clientPriceController.text),
      platformPayout: NumberParsing.parse(_platformPayoutController.text),
    );
    setState(() => _result = result);

    final duration = NumberParsing.parse(_durationController.text);

    widget.onRideCalculated(RideEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      result: result,
      date: DateTime.now(),
      platformName: _selectedPlatform,
      durationMinutes: duration > 0 ? duration.round() : null,
    ));

    _rideKmController.clear();
    _clientPriceController.clear();
    _platformPayoutController.clear();
    _durationController.clear();
    setState(() => _selectedPlatform = null);

    // Remonte vers le Readout pour que le résultat soit visible
    // immédiatement, même si l'utilisateur avait scrollé en bas pour saisir
    // les champs — sinon rien ne semble s'être passé.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildForm(context)),
        // En dehors du contenu défilant : la pub ne recouvre ni ne repousse
        // jamais le formulaire ou le bouton "Calculer le net" (CLAUDE.md
        // §10.5.b), elle s'ajoute simplement sous la zone scrollable.
        if (!widget.isPremium) const AdBanner(),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        AppTopBar(
          vehicleLabel: widget.profile.vehicleName,
          onVehicleTap: widget.onOpenSettings,
        ),
        ReadoutCard(
          result: _result,
          urssafRatePercent: widget.profile.urssafRate * 100,
          fuelLabel: widget.profile.isElectric ? 'Électricité' : 'Carburant',
        ),
        const SectionTitle('Détails de la course'),
        FormCard(children: [
          LabeledField(
            icon: Icons.route_outlined,
            label: 'Course',
            controller: _rideKmController,
            suffix: 'km',
          ),
          LabeledField(
            icon: Icons.receipt_long_outlined,
            label: 'Prix client',
            controller: _clientPriceController,
            suffix: '€',
          ),
          LabeledField(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Versé plateforme',
            controller: _platformPayoutController,
            suffix: '€',
          ),
          LabeledField(
            icon: Icons.schedule_outlined,
            label: 'Durée',
            sublabel: 'Optionnel, pour le net/heure',
            controller: _durationController,
            suffix: 'min',
          ),
        ]),
        const SectionTitle('Plateforme'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PlatformSelector(
            selected: _selectedPlatform,
            onChanged: (value) => setState(() => _selectedPlatform = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculer le net'),
            ),
          ),
        ),
      ],
    );
  }
}
