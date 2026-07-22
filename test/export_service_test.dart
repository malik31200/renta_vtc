import 'package:flutter_test/flutter_test.dart';
import 'package:renta_vtc/models/ride_entry.dart';
import 'package:renta_vtc/models/ride_result.dart';
import 'package:renta_vtc/services/export_service.dart';

RideEntry _entry({
  required String id,
  required DateTime date,
  String? platformName,
}) {
  return RideEntry(
    id: id,
    date: date,
    platformName: platformName,
    result: const RideResult(
      rideKm: 10,
      clientPrice: 20,
      platformPayout: 16,
      fuelCost: 1,
      urssafCost: 4.24,
      net: 10.76,
    ),
  );
}

void main() {
  const export = ExportService();

  group('buildCsv', () {
    test('une ligne d\'en-tête + une ligne par course, triées par date', () {
      final csv = export.buildCsv([
        _entry(id: '2', date: DateTime(2026, 3, 2)),
        _entry(id: '1', date: DateTime(2026, 3, 1)),
      ]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 3);
      expect(lines[0], startsWith('Date;Heure;Plateforme'));
      // triée par date croissante malgré l'ordre d'entrée inverse
      expect(lines[1], startsWith('01/03/2026'));
      expect(lines[2], startsWith('02/03/2026'));
    });

    test('liste vide -> seulement l\'en-tête', () {
      final csv = export.buildCsv([]);
      expect(csv.trim().split('\n').length, 1);
    });

    test('échappe les champs contenant le séparateur point-virgule', () {
      final csv = export.buildCsv([_entry(id: '1', date: DateTime(2026, 1, 1), platformName: 'Uber;Bolt')]);
      expect(csv, contains('"Uber;Bolt"'));
    });

    test('les montants utilisent la virgule décimale française', () {
      final csv = export.buildCsv([_entry(id: '1', date: DateTime(2026, 1, 1))]);
      expect(csv, contains('10,76'));
      expect(csv, isNot(contains('10.76')));
    });
  });

  group('startOfQuarter / quarterOf', () {
    test('janvier-mars -> T1, débute le 1er janvier', () {
      expect(ExportService.quarterOf(DateTime(2026, 2, 15)), 1);
      expect(ExportService.startOfQuarter(DateTime(2026, 2, 15)), DateTime(2026, 1, 1));
    });

    test('avril-juin -> T2, débute le 1er avril', () {
      expect(ExportService.quarterOf(DateTime(2026, 5, 1)), 2);
      expect(ExportService.startOfQuarter(DateTime(2026, 5, 1)), DateTime(2026, 4, 1));
    });

    test('octobre-décembre -> T4, débute le 1er octobre', () {
      expect(ExportService.quarterOf(DateTime(2026, 12, 31)), 4);
      expect(ExportService.startOfQuarter(DateTime(2026, 12, 31)), DateTime(2026, 10, 1));
    });
  });

  test('entriesInQuarter exclut les courses hors trimestre', () {
    final entries = [
      _entry(id: '1', date: DateTime(2026, 3, 31)), // T1
      _entry(id: '2', date: DateTime(2026, 4, 1)), // T2
      _entry(id: '3', date: DateTime(2026, 5, 15)), // T2
    ];
    final result = export.entriesInQuarter(entries, DateTime(2026, 4, 20));
    expect(result.map((e) => e.id), ['2', '3']);
  });
}
