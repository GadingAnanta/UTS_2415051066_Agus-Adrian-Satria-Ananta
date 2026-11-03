import 'package:bengkel_digital/models/component_interval.dart';
import 'package:bengkel_digital/models/tax_reminder.dart';
import 'package:bengkel_digital/models/vehicle.dart';
import 'package:bengkel_digital/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vehicle', () {
    test('toMap & fromMap konsisten (round trip)', () {
      final DateTime dibuat = DateTime(2026, 1, 15, 10, 30);
      final Vehicle asli = Vehicle(
        id: 1,
        brand: 'Honda',
        model: 'Vario 160',
        year: 2021,
        plateNumber: 'B 1234 XYZ',
        currentKm: 12500,
        createdAt: dibuat,
      );

      final Vehicle hasil = Vehicle.fromMap(asli.toMap());

      expect(hasil.id, 1);
      expect(hasil.brand, 'Honda');
      expect(hasil.model, 'Vario 160');
      expect(hasil.year, 2021);
      expect(hasil.plateNumber, 'B 1234 XYZ');
      expect(hasil.currentKm, 12500);
      expect(hasil.createdAt, dibuat);
      expect(hasil.displayName, 'Honda Vario 160');
    });

    test('toMap tidak menyertakan id jika null', () {
      final Vehicle baru = Vehicle(
        brand: 'Yamaha',
        model: 'NMAX',
        year: 2023,
        plateNumber: 'D 5678 AB',
        currentKm: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(baru.toMap().containsKey('id'), isFalse);
    });
  });

  group('ComponentInterval', () {
    test('data seed berisi 8 komponen sesuai spesifikasi', () {
      expect(defaultComponentIntervals.length, 8);
      final ComponentInterval oliMesin = defaultComponentIntervals.firstWhere(
        (ComponentInterval k) => k.key == 'oli_mesin',
      );
      expect(oliMesin.kmInterval, 2000);
      expect(oliMesin.monthInterval, 2);
    });

    test('aki hanya punya interval bulan', () {
      final ComponentInterval aki = defaultComponentIntervals.firstWhere(
        (ComponentInterval k) => k.key == 'aki',
      );
      expect(aki.hasKmInterval, isFalse);
      expect(aki.hasMonthInterval, isTrue);
      expect(aki.monthInterval, 24);
    });

    test('intervalLabel terbaca manusia', () {
      final ComponentInterval oliMesin = defaultComponentIntervals.firstWhere(
        (ComponentInterval k) => k.key == 'oli_mesin',
      );
      expect(oliMesin.intervalLabel, '2.000 km / 2 bulan');
    });

    test('toMap & fromMap konsisten', () {
      final ComponentInterval asli = defaultComponentIntervals.first;
      final ComponentInterval hasil = ComponentInterval.fromMap(asli.toMap());
      expect(hasil.key, asli.key);
      expect(hasil.kmInterval, asli.kmInterval);
      expect(hasil.monthInterval, asli.monthInterval);
      expect(hasil.isActive, isTrue);
    });
  });

  group('TaxReminder', () {
    test('menghitung sisa hari dan status lewat batas', () {
      final DateTime besok = DateTime.now().add(const Duration(days: 1));
      final TaxReminder reminder = TaxReminder(
        vehicleId: 1,
        type: TaxType.pajakTahunan,
        dueDate: besok,
      );

      expect(reminder.daysRemaining, 1);
      expect(reminder.isOverdue, isFalse);

      final TaxReminder lewat = TaxReminder(
        vehicleId: 1,
        type: TaxType.stnkLimaTahunan,
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(lewat.isOverdue, isTrue);
    });

    test('TaxType.fromValue mengembalikan enum yang tepat', () {
      expect(TaxType.fromValue('pajak_tahunan'), TaxType.pajakTahunan);
      expect(TaxType.fromValue('stnk_lima_tahunan'), TaxType.stnkLimaTahunan);
      expect(TaxType.fromValue('tidak_dikenal'), TaxType.pajakTahunan);
    });
  });
}
