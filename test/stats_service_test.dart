import 'package:flutter_test/flutter_test.dart';
import 'package:renta_vtc/models/ride_entry.dart';
import 'package:renta_vtc/models/ride_result.dart';
import 'package:renta_vtc/services/stats_service.dart';

RideEntry _entry({
  required String id,
  required DateTime date,
  double rideKm = 10,
  double clientPrice = 20,
  double net = 12,
  String? platformName,
  int? durationMinutes,
}) {
  return RideEntry(
    id: id,
    date: date,
    platformName: platformName,
    durationMinutes: durationMinutes,
    result: RideResult(
      rideKm: rideKm,
      clientPrice: clientPrice,
      platformPayout: clientPrice * 0.8,
      fuelCost: 1,
      urssafCost: clientPrice * 0.212,
      net: net,
    ),
  );
}

void main() {
  const stats = StatsService();

  group('averageNetPerKm', () {
    test('moyenne pondérée par la distance, pas une moyenne simple', () {
      final entries = [
        _entry(id: '1', date: DateTime(2026, 1, 1), rideKm: 10, net: 10),
        _entry(id: '2', date: DateTime(2026, 1, 2), rideKm: 30, net: 30),
      ];
      // (10+30) / (10+30) = 1.0 €/km
      expect(stats.averageNetPerKm(entries), closeTo(1.0, 0.001));
    });

    test('liste vide -> 0', () {
      expect(stats.averageNetPerKm([]), 0);
    });

    test('ignore les courses à 0 km', () {
      final entries = [
        _entry(id: '1', date: DateTime(2026, 1, 1), rideKm: 0, net: 5),
        _entry(id: '2', date: DateTime(2026, 1, 2), rideKm: 10, net: 10),
      ];
      expect(stats.averageNetPerKm(entries), closeTo(1.0, 0.001));
    });
  });

  group('averageNetPerHour', () {
    test('moyenne globale (net total / heures totales), pas par course', () {
      final entries = [
        _entry(id: '1', date: DateTime(2026, 1, 1), net: 10, durationMinutes: 30),
        _entry(id: '2', date: DateTime(2026, 1, 2), net: 20, durationMinutes: 90),
      ];
      // total net 30 / total heures 2 = 15 €/h (pas 20+13.33 en moyenne simple)
      expect(stats.averageNetPerHour(entries), closeTo(15.0, 0.001));
    });

    test('exclut les courses sans durée renseignée', () {
      final entries = [
        _entry(id: '1', date: DateTime(2026, 1, 1), net: 10, durationMinutes: 30),
        _entry(id: '2', date: DateTime(2026, 1, 2), net: 999, durationMinutes: null),
      ];
      expect(stats.averageNetPerHour(entries), closeTo(20.0, 0.001));
    });

    test('aucune course avec durée -> 0', () {
      final entries = [_entry(id: '1', date: DateTime(2026, 1, 1), durationMinutes: null)];
      expect(stats.averageNetPerHour(entries), 0);
    });
  });

  group('totalNetOnDay / totalNetSince / totalNetInMonth', () {
    final entries = [
      _entry(id: '1', date: DateTime(2026, 3, 15, 9), net: 10),
      _entry(id: '2', date: DateTime(2026, 3, 15, 18), net: 5),
      _entry(id: '3', date: DateTime(2026, 3, 16), net: 100),
      _entry(id: '4', date: DateTime(2026, 4, 1), net: 1000),
    ];

    test('totalNetOnDay ne compte que le jour exact', () {
      expect(stats.totalNetOnDay(entries, DateTime(2026, 3, 15, 23)), closeTo(15, 0.001));
    });

    test('totalNetSince inclut la date de départ et tout ce qui suit', () {
      expect(stats.totalNetSince(entries, DateTime(2026, 3, 16)), closeTo(1100, 0.001));
    });

    test('totalNetInMonth filtre par année+mois', () {
      expect(stats.totalNetInMonth(entries, DateTime(2026, 3, 1)), closeTo(115, 0.001));
    });
  });

  test('totalClientPriceInYear filtre par année civile', () {
    final entries = [
      _entry(id: '1', date: DateTime(2025, 12, 31), clientPrice: 500),
      _entry(id: '2', date: DateTime(2026, 1, 1), clientPrice: 100),
      _entry(id: '3', date: DateTime(2026, 6, 1), clientPrice: 50),
    ];
    expect(stats.totalClientPriceInYear(entries, 2026), closeTo(150, 0.001));
  });

  test('startOfWeek renvoie le lundi de la semaine', () {
    // Jeudi 19 mars 2026 -> lundi 16 mars 2026
    final monday = StatsService.startOfWeek(DateTime(2026, 3, 19));
    expect(monday, DateTime(2026, 3, 16));
  });

  group('byPlatform', () {
    test('regroupe et trie par net moyen décroissant', () {
      final entries = [
        _entry(id: '1', date: DateTime(2026, 1, 1), net: 10, platformName: 'Uber'),
        _entry(id: '2', date: DateTime(2026, 1, 2), net: 20, platformName: 'Uber'),
        _entry(id: '3', date: DateTime(2026, 1, 3), net: 50, platformName: 'Bolt'),
      ];
      final result = stats.byPlatform(entries);

      expect(result.map((s) => s.label), ['Bolt', 'Uber']);
      expect(result[0].averageNet, closeTo(50, 0.001));
      expect(result[1].averageNet, closeTo(15, 0.001));
      expect(result[1].rideCount, 2);
    });

    test('plateforme non renseignée regroupée sous "Sans plateforme"', () {
      final entries = [_entry(id: '1', date: DateTime(2026, 1, 1), platformName: null)];
      final result = stats.byPlatform(entries);
      expect(result.single.label, 'Sans plateforme');
    });
  });
}
