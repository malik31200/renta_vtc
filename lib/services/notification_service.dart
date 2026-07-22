import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification locale (pas de push serveur) déclenchée par l'app elle-même
/// à la reprise, quand le CA cumulé de l'année approche le plafond
/// auto-entrepreneur — CLAUDE.md §10.2.f.
class NotificationService {
  static const _channelId = 'renta_vtc_alerts';
  static const _channelName = 'Alertes Renta VTC';
  static const _thresholdNotificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    try {
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Plateforme sans support notifications (ex: certains navigateurs) —
      // l'alerte visuelle en app (ThresholdBanner) reste disponible.
    }
  }

  Future<void> showThresholdAlert({
    required double currentAmount,
    required double threshold,
  }) async {
    final percent = (currentAmount / threshold * 100).round();
    try {
      await _plugin.show(
        id: _thresholdNotificationId,
        title: 'Plafond auto-entrepreneur',
        body: 'Tu as atteint $percent % du plafond annuel ($currentAmount € / $threshold €).',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Idem : échec silencieux, le bandeau in-app reste la source de vérité.
    }
  }
}
