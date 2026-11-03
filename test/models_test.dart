import 'package:bengkel_digital/models/component_interval.dart';
import 'package:bengkel_digital/models/service_record.dart';
import 'package:bengkel_digital/models/tax_reminder.dart';
import 'package:bengkel_digital/models/vehicle.dart';
import 'package:bengkel_digital/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vehicle', () {
    test('toInsertJson & fromJson konsisten (round trip)', () {
      final DateTime dibuat = DateTime(2026, 1, 15, 10, 30);
      final DateTime pajak = DateTime(2026, 6, 1);
      final DateTime stnk = DateTime(2029, 6, 1);

      // Simulasi baris yang dikirim Supabase (snake_case).
      final Map<String, dynamic> baris = <String, dynamic>{
        'id': 1,
        'user_id': '11111111-1111-4111-8111-111111111111',
        'brand': 'Honda',
        'model': 'Vario 160',
        'year': 2021,
        'plate': 'B 1234 XYZ',
        'current_km': 12500,
        'tax_due_date': '2026-06-01',
        'stnk_due_date': '2029-06-01',
        'created_at': dibuat.toIso8601String(),
      };

      final Vehicle hasil = Vehicle.fromJson(baris);

      expect(hasil.id, 1);
      expect(hasil.userId, '11111111-1111-4111-8111-111111111111');
      expect(hasil.brand, 'Honda');
      expect(hasil.model, 'Vario 160');
      expect(hasil.year, 2021);
      expect(hasil.plateNumber, 'B 1234 XYZ');
      expect(hasil.currentKm, 12500);
      expect(hasil.taxDueDate, pajak);
      expect(hasil.stnkDueDate, stnk);
      expect(hasil.createdAt, dibuat);
      expect(hasil.displayName, 'Honda Vario 160');
    });

    test('toInsertJson memakai nama kolom database', () {
      final Vehicle baru = Vehicle(
        userId: 'demo',
        brand: 'Yamaha',
        model: 'NMAX',
        year: 2023,
        plateNumber: 'D 5678 AB',
        currentKm: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      final Map<String, Object?> json = baru.toInsertJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json['plate'], 'D 5678 AB');
      expect(json['current_km'], 0);
      expect(json['tax_due_date'], isNull);
    });

    test('copyWith bisa mengosongkan tanggal jatuh tempo', () {
      final Vehicle asli = Vehicle(
        userId: 'demo',
        brand: 'Honda',
        model: 'Beat',
        year: 2020,
        plateNumber: 'B 1 A',
        currentKm: 1000,
        taxDueDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 1, 1),
      );

      final Vehicle kosong = asli.copyWith(hapusTaxDueDate: true);

      expect(kosong.taxDueDate, isNull);
    });
  });

  group('ServiceRecord', () {
    test('fromJson memetakan kolom service_records', () {
      final ServiceRecord catatan = ServiceRecord.fromJson(<String, dynamic>{
        'id': 7,
        'vehicle_id': 2,
        'component': 'oli_mesin',
        'service_km': 9000,
        'cost': 55000,
        'workshop': 'Bengkel Pak Budi',
        'note': null,
        'service_date': '2026-02-10',
        'created_at': '2026-02-10T08:00:00+00:00',
      });

      expect(catatan.id, 7);
      expect(catatan.vehicleId, 2);
      expect(catatan.componentKey, 'oli_mesin');
      expect(catatan.kmAtService, 9000);
      expect(catatan.cost, 55000);
      expect(catatan.workshopName, 'Bengkel Pak Budi');
      expect(catatan.note, isNull);
      expect(catatan.serviceDate, DateTime(2026, 2, 10));
    });

    test('toInsertJson memakai nama kolom database', () {
      final ServiceRecord catatan = ServiceRecord(
        vehicleId: 3,
        componentKey: 'kampas_rem',
        serviceDate: DateTime(2026, 3, 5),
        kmAtService: 15000,
        cost: 120000,
        createdAt: DateTime(2026, 3, 5),
      );

      final Map<String, Object?> json = catatan.toInsertJson();

      expect(json['vehicle_id'], 3);
      expect(json['component'], 'kampas_rem');
      expect(json['service_km'], 15000);
      expect(json['service_date'], '2026-03-05');
      expect(json.containsKey('id'), isFalse);
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
