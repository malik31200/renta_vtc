import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'models/driver_profile.dart';
import 'models/fixed_expense.dart';
import 'models/fuel_entry.dart';
import 'models/ride_entry.dart';
import 'models/subscription_status.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ads_service.dart';
import 'services/notification_service.dart';
import 'services/stats_service.dart';
import 'services/storage_service.dart';
import 'services/subscription_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_tab_bar.dart';

void main() {
  runApp(const RentaVtcApp());
}

class RentaVtcApp extends StatelessWidget {
  const RentaVtcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Renta VTC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootShell(),
    );
  }
}

/// Coquille racine : charge les profils véhicule (multi-véhicules, §10.2.d),
/// l'historique, le statut d'abonnement (§10.3) et le plafond
/// auto-entrepreneur (§10.2.f) au démarrage ; redirige automatiquement vers
/// les réglages tant que le profil actif n'est pas configuré — CLAUDE.md §7.1.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _storage = StorageService();
  static const _stats = StatsService();
  final _subscriptionService = SubscriptionService();
  final _notificationService = NotificationService();
  final _adsService = AdsService();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  List<DriverProfile>? _profiles;
  String _activeProfileId = '';
  List<RideEntry> _history = [];
  List<FixedExpense> _fixedExpenses = [];
  List<FuelEntry> _fuelEntries = [];
  double _annualThreshold = kDefaultAnnualCapThreshold;
  SubscriptionStatus _subscriptionStatus = const SubscriptionStatus.free();
  List<ProductDetails> _products = [];
  int _tabIndex = 0;

  /// Créé une seule fois, avec la bonne page initiale, dès que les profils
  /// sont résolus (voir build()) — permet le swipe entre onglets en plus des
  /// taps sur la barre du bas.
  PageController? _pageController;

  DriverProfile get _activeProfile =>
      _profiles!.firstWhere((p) => p.id == _activeProfileId, orElse: () => _profiles!.first);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _purchaseSubscription = _subscriptionService.purchaseStream.listen(_onPurchaseUpdates);
    _notificationService.init();
    _adsService.init();
    _subscriptionService.queryProducts().then((products) {
      if (mounted) setState(() => _products = products);
    });
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final profiles = await _storage.loadDriverProfiles();
    final activeId = await _storage.loadActiveProfileId();
    final history = await _storage.loadRideHistory();
    final fixedExpenses = await _storage.loadFixedExpenses();
    final fuelEntries = await _storage.loadFuelEntries();
    final threshold = await _storage.loadAnnualThreshold();
    final subscriptionStatus = await _storage.loadSubscriptionStatus();
    if (!mounted) return;

    final resolvedProfiles = profiles.isEmpty ? [const DriverProfile.empty()] : profiles;
    final resolvedActiveId = resolvedProfiles.any((p) => p.id == activeId)
        ? activeId!
        : resolvedProfiles.first.id;
    final resolvedActiveProfile =
        resolvedProfiles.firstWhere((p) => p.id == resolvedActiveId);

    setState(() {
      _profiles = resolvedProfiles;
      _activeProfileId = resolvedActiveId;
      _history = history;
      _fixedExpenses = fixedExpenses;
      _fuelEntries = fuelEntries;
      _annualThreshold = threshold;
      _subscriptionStatus = subscriptionStatus;
      _tabIndex = resolvedActiveProfile.isConfigured ? 0 : 1;
    });

    _subscriptionService.restorePurchases();
    _maybeAlertThreshold();
  }

  Future<void> _maybeAlertThreshold() async {
    final currentAmount = _stats.totalClientPriceInYear(_history, DateTime.now().year);
    if (_annualThreshold <= 0 || currentAmount / _annualThreshold < 0.8) return;

    final lastAlertDate = await _storage.loadLastThresholdAlertDate();
    final today = DateTime.now();
    if (lastAlertDate != null &&
        lastAlertDate.year == today.year &&
        lastAlertDate.month == today.month &&
        lastAlertDate.day == today.day) {
      return;
    }

    await _notificationService.showThresholdAlert(
      currentAmount: currentAmount,
      threshold: _annualThreshold,
    );
    await _storage.saveLastThresholdAlertDate(today);
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        final status = _subscriptionService.statusFromPurchase(purchase);
        setState(() => _subscriptionStatus = status);
        _storage.saveSubscriptionStatus(status);
      }
      if (purchase.pendingCompletePurchase) {
        _subscriptionService.completePurchase(purchase);
      }
    }
  }

  void _onSubscribe(ProductDetails product) {
    _subscriptionService.buy(product);
  }

  void _onRestorePurchases() {
    _subscriptionService.restorePurchases();
  }

  void _onTogglePremiumDevMode(bool value) {
    final status = SubscriptionStatus(isPremium: value);
    setState(() => _subscriptionStatus = status);
    _storage.saveSubscriptionStatus(status);
  }

  void _onThresholdChanged(double value) {
    setState(() => _annualThreshold = value);
    _storage.saveAnnualThreshold(value);
  }

  void _onProfileSaved(DriverProfile profile) {
    final saved = profile.id.isEmpty
        ? DriverProfile(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            vehicleName: profile.vehicleName,
            consumptionL100km: profile.consumptionL100km,
            fuelPricePerLiter: profile.fuelPricePerLiter,
            urssafRate: profile.urssafRate,
            isElectric: profile.isElectric,
          )
        : profile;

    setState(() {
      final profiles = [..._profiles!];
      final index = profiles.indexWhere((p) => p.id == saved.id);
      if (index == -1) {
        profiles.add(saved);
      } else {
        profiles[index] = saved;
      }
      _profiles = profiles;
      _activeProfileId = saved.id;
      _tabIndex = 0;
    });
    _pageController?.animateToPage(0, duration: _tabAnimDuration, curve: _tabAnimCurve);
    _storage.saveDriverProfiles(_profiles!);
    _storage.saveActiveProfileId(_activeProfileId);
  }

  void _onSelectProfile(String id) {
    setState(() => _activeProfileId = id);
    _storage.saveActiveProfileId(id);
  }

  void _onAddProfile() {
    final blank = DriverProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      vehicleName: '',
      consumptionL100km: 0,
      fuelPricePerLiter: 0,
      urssafRate: kDefaultUrssafRate,
    );
    setState(() {
      _profiles = [..._profiles!, blank];
      _activeProfileId = blank.id;
    });
    _storage.saveDriverProfiles(_profiles!);
    _storage.saveActiveProfileId(_activeProfileId);
  }

  void _onDeleteProfile(String id) {
    if (_profiles!.length <= 1) return;
    setState(() {
      final profiles = _profiles!.where((p) => p.id != id).toList();
      _profiles = profiles;
      if (_activeProfileId == id) {
        _activeProfileId = profiles.first.id;
      }
    });
    _storage.saveDriverProfiles(_profiles!);
    _storage.saveActiveProfileId(_activeProfileId);
  }

  void _onRideCalculated(RideEntry entry) {
    setState(() => _history = [..._history, entry]);
    _storage.saveRideHistory(_history);
    _maybeAlertThreshold();
  }

  void _onDeleteRideEntry(RideEntry entry) {
    setState(() => _history = _history.where((e) => e.id != entry.id).toList());
    _storage.saveRideHistory(_history);
  }

  void _onAddFixedExpense(FixedExpense expense) {
    setState(() => _fixedExpenses = [..._fixedExpenses, expense]);
    _storage.saveFixedExpenses(_fixedExpenses);
  }

  void _onDeleteFixedExpense(FixedExpense expense) {
    setState(() => _fixedExpenses = _fixedExpenses.where((e) => e.id != expense.id).toList());
    _storage.saveFixedExpenses(_fixedExpenses);
  }

  void _onAddFuelEntry(FuelEntry entry) {
    setState(() => _fuelEntries = [..._fuelEntries, entry]);
    _storage.saveFuelEntries(_fuelEntries);
  }

  void _onDeleteFuelEntry(FuelEntry entry) {
    setState(() => _fuelEntries = _fuelEntries.where((e) => e.id != entry.id).toList());
    _storage.saveFuelEntries(_fuelEntries);
  }

  void _onRestoreBackup(List<DriverProfile> profiles, List<RideEntry> history) {
    setState(() {
      _profiles = profiles;
      _activeProfileId = profiles.first.id;
      _history = history;
      _tabIndex = _activeProfile.isConfigured ? 0 : 1;
    });
    _pageController?.animateToPage(_tabIndex, duration: _tabAnimDuration, curve: _tabAnimCurve);
    _storage.saveDriverProfiles(profiles);
    _storage.saveActiveProfileId(_activeProfileId);
    _storage.saveRideHistory(history);
  }

  static const _tabAnimDuration = Duration(milliseconds: 250);
  static const _tabAnimCurve = Curves.easeOut;

  /// Tap sur la barre du bas — anime le PageView vers l'onglet choisi.
  void _onTabTap(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == 0 && !_activeProfile.isConfigured) {
      _goToTab(1);
      return;
    }
    _goToTab(index);
  }

  void _goToTab(int index) {
    setState(() => _tabIndex = index);
    _pageController?.animateToPage(index, duration: _tabAnimDuration, curve: _tabAnimCurve);
  }

  /// Swipe horizontal sur le PageView — CLAUDE.md n'impose pas ce geste,
  /// ajouté en confort d'usage en plus des taps sur la barre du bas.
  ///
  /// Ferme systématiquement le clavier au changement d'onglet : un champ
  /// resté focus après un swipe garde le clavier ouvert indéfiniment (le
  /// framework ne le referme jamais tout seul quand le champ n'est plus
  /// visible, seulement quand il perd explicitement le focus) — retour
  /// testeur, remonté aussi par la review Apple.
  void _onPageChanged(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == 0 && !_activeProfile.isConfigured) {
      // Le profil doit être configuré avant d'accéder au calcul : on ne
      // laisse pas le swipe atterrir sur Course, on renvoie vers Réglages.
      _goToTab(1);
      return;
    }
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _profiles;
    if (profiles == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }

    _pageController ??= PageController(initialPage: _tabIndex);

    // Contrainte de largeur type smartphone : sans effet sur un vrai appareil
    // mobile (toujours plus étroit que 480), mais évite que l'app s'étire sur
    // toute la largeur d'un écran de bureau (aperçu web uniquement).
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      // Taper en dehors d'un champ de saisie ferme le clavier — les champs
      // eux-mêmes gèrent leur propre tap (LabeledField), qui prend le
      // dessus sur celui-ci dans l'arène de gestes Flutter.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ColoredBox(
            color: AppColors.bg,
            child: Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    // PageView plutôt qu'IndexedStack : permet de glisser
                    // d'un onglet à l'autre en plus de taper sur la barre du
                    // bas (qui reste, elle, toujours cliquable).
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [
                        HomeScreen(
                          profile: _activeProfile,
                          onOpenSettings: () => _onTabTap(1),
                          onRideCalculated: _onRideCalculated,
                          isPremium: _subscriptionStatus.isActive,
                        ),
                        SettingsScreen(
                          profiles: profiles,
                          activeProfileId: _activeProfileId,
                          onSaved: _onProfileSaved,
                          onSelectProfile: _onSelectProfile,
                          onAddProfile: _onAddProfile,
                          onDeleteProfile: _onDeleteProfile,
                          annualThreshold: _annualThreshold,
                          onThresholdChanged: _onThresholdChanged,
                          isPremium: _subscriptionStatus.isActive,
                          onTogglePremiumDevMode: _onTogglePremiumDevMode,
                          rideHistory: _history,
                          onRestoreBackup: _onRestoreBackup,
                        ),
                        _subscriptionStatus.isActive
                            ? HistoryScreen(
                                entries: _history,
                                onDelete: _onDeleteRideEntry,
                                annualThreshold: _annualThreshold,
                                fixedExpenses: _fixedExpenses,
                                fuelEntries: _fuelEntries,
                                isElectric: _activeProfile.isElectric,
                                onAddFixedExpense: _onAddFixedExpense,
                                onDeleteFixedExpense: _onDeleteFixedExpense,
                                onAddFuelEntry: _onAddFuelEntry,
                                onDeleteFuelEntry: _onDeleteFuelEntry,
                              )
                            : PaywallScreen(
                                products: _products,
                                isSupported: _subscriptionService.isSupportedOnThisPlatform,
                                onSubscribe: _onSubscribe,
                                onRestore: _onRestorePurchases,
                              ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: AppTabBar(currentIndex: _tabIndex, onTap: _onTabTap),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
