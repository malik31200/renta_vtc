import 'package:flutter_test/flutter_test.dart';
import 'package:renta_vtc/models/driver_profile.dart';
import 'package:renta_vtc/models/ride_entry.dart';
import 'package:renta_vtc/models/ride_result.dart';
import 'package:renta_vtc/services/backup_service.dart';

void main() {
  const backup = BackupService();

  const profile = DriverProfile(
    id: 'p1',
    vehicleName: 'Clio V',
    consumptionL100km: 6.0,
    fuelPricePerLiter: 1.8,
    urssafRate: 0.212,
  );

  final entry = RideEntry(
    id: 'e1',
    date: DateTime(2026, 3, 1, 10, 30),
    platformName: 'Uber',
    durationMinutes: 25,
    result: const RideResult(
      rideKm: 10,
      clientPrice: 20,
      platformPayout: 16,
      fuelCost: 1,
      urssafCost: 4.24,
      net: 10.76,
    ),
  );

  test('round-trip : ce qui est exporté est ce qui est réimporté', () {
    final json = backup.buildBackupJson(profiles: [profile], history: [entry]);
    final restored = backup.parseBackupJson(json);

    expect(restored.profiles.single.id, profile.id);
    expect(restored.profiles.single.vehicleName, profile.vehicleName);
    expect(restored.profiles.single.consumptionL100km, profile.consumptionL100km);
    expect(restored.history.single.id, entry.id);
    expect(restored.history.single.platformName, entry.platformName);
    expect(restored.history.single.result.net, entry.result.net);
  });

  test('JSON invalide (pas un objet) lève une FormatException', () {
    expect(() => backup.parseBackupJson('[1,2,3]'), throwsFormatException);
  });

  test('JSON sans les clés attendues lève une FormatException', () {
    expect(() => backup.parseBackupJson('{"foo":"bar"}'), throwsFormatException);
  });

  test('sauvegarde sans aucun véhicule lève une FormatException', () {
    final json = backup.buildBackupJson(profiles: const [], history: const []);
    expect(() => backup.parseBackupJson(json), throwsFormatException);
  });
}
