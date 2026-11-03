import 'package:bengkel_digital/models/service_record.dart';
import 'package:bengkel_digital/utils/expense_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membuat catatan servis cepat untuk pengujian.
ServiceRecord _catatan({
  required DateTime tanggal,
  required int biaya,
  String komponen = 'oli_mesin',
}) {
  return ServiceRecord(
    vehicleId: 1,
    componentKey: komponen,
    serviceDate: tanggal,
    kmAtService: 1000,
    cost: biaya,
    createdAt: tanggal,
  );
}

void main() {
  // Tanggal patokan tetap supaya hasil tes tidak bergantung pada hari ini.
  final DateTime acuan = DateTime(2026, 11, 15);

  group('ExpenseAggregator.perBulan', () {
    test('selalu mengembalikan jumlah bulan yang diminta', () {
      final List<MonthlyExpense> hasil =
          ExpenseAggregator.perBulan(<ServiceRecord>[], jumlahBulan: 6, acuan: acuan);

      expect(hasil.length, 6);
      expect(hasil.every((MonthlyExpense item) => item.total == 0), isTrue);
    });

    test('urutan bulan dari paling lama ke terbaru, berakhir di bulan acuan', () {
      final List<MonthlyExpense> hasil =
          ExpenseAggregator.perBulan(<ServiceRecord>[], jumlahBulan: 3, acuan: acuan);

      expect(hasil[0].bulan, DateTime(2026, 9));
      expect(hasil[1].bulan, DateTime(2026, 10));
      expect(hasil[2].bulan, DateTime(2026, 11));
    });

    test('menjumlahkan biaya beberapa catatan pada bulan yang sama', () {
      final List<ServiceRecord> data = <ServiceRecord>[
        _catatan(tanggal: DateTime(2026, 11, 2), biaya: 50000),
        _catatan(tanggal: DateTime(2026, 11, 20), biaya: 75000, komponen: 'busi'),
      ];

      final List<MonthlyExpense> hasil =
          ExpenseAggregator.perBulan(data, jumlahBulan: 6, acuan: acuan);
      final MonthlyExpense november = hasil.last;

      expect(november.total, 125000);
      expect(november.jumlahServis, 2);
    });

    test('catatan di luar rentang bulan diabaikan', () {
      final List<ServiceRecord> data = <ServiceRecord>[
        // 7 bulan sebelum acuan → di luar 6 bulan terakhir.
        _catatan(tanggal: DateTime(2026, 4, 10), biaya: 999000),
        _catatan(tanggal: DateTime(2026, 10, 10), biaya: 40000),
      ];

      final List<MonthlyExpense> hasil =
          ExpenseAggregator.perBulan(data, jumlahBulan: 6, acuan: acuan);

      final int totalTampil = hasil.fold<int>(
        0,
        (int jumlah, MonthlyExpense item) => jumlah + item.total,
      );
      expect(totalTampil, 40000);
    });

    test('menangani pergantian tahun dengan benar', () {
      final List<MonthlyExpense> hasil = ExpenseAggregator.perBulan(
        <ServiceRecord>[_catatan(tanggal: DateTime(2025, 12, 31), biaya: 100000)],
        jumlahBulan: 3,
        acuan: DateTime(2026, 1, 10),
      );

      expect(hasil[0].bulan, DateTime(2025, 11));
      expect(hasil[1].bulan, DateTime(2025, 12));
      expect(hasil[2].bulan, DateTime(2026, 1));
      expect(hasil[1].total, 100000);
    });
  });

  group('ExpenseAggregator.perKomponen', () {
    test('mengelompokkan biaya per komponen dan mengurutkan dari terbesar', () {
      final List<ServiceRecord> data = <ServiceRecord>[
        _catatan(tanggal: DateTime(2026, 10, 1), biaya: 60000, komponen: 'oli_mesin'),
        _catatan(tanggal: DateTime(2026, 11, 1), biaya: 40000, komponen: 'oli_mesin'),
        _catatan(tanggal: DateTime(2026, 11, 5), biaya: 150000, komponen: 'ban'),
      ];

      final List<ComponentExpense> hasil = ExpenseAggregator.perKomponen(data);

      expect(hasil.length, 2);
      expect(hasil.first.componentKey, 'ban');
      expect(hasil.first.total, 150000);
      expect(hasil.last.componentKey, 'oli_mesin');
      expect(hasil.last.total, 100000);
      expect(hasil.last.jumlahServis, 2);
    });

    test('daftar kosong menghasilkan daftar kosong', () {
      expect(ExpenseAggregator.perKomponen(<ServiceRecord>[]), isEmpty);
    });
  });

  group('ExpenseAggregator total & rata-rata', () {
    test('total menjumlahkan seluruh biaya', () {
      final List<ServiceRecord> data = <ServiceRecord>[
        _catatan(tanggal: DateTime(2026, 10, 1), biaya: 25000),
        _catatan(tanggal: DateTime(2026, 11, 1), biaya: 75000),
      ];

      expect(ExpenseAggregator.total(data), 100000);
      expect(ExpenseAggregator.total(<ServiceRecord>[]), 0);
    });

    test('rata-rata per bulan membagi total dengan jumlah bulan', () {
      final List<MonthlyExpense> data = <MonthlyExpense>[
        MonthlyExpense(bulan: DateTime(2026, 11), total: 60000, jumlahServis: 1),
        MonthlyExpense(bulan: DateTime(2026, 12), total: 0, jumlahServis: 0),
        MonthlyExpense(bulan: DateTime(2027, 1), total: 30000, jumlahServis: 1),
      ];

      // (60000 + 0 + 30000) / 3 = 30000
      expect(ExpenseAggregator.rataRataPerBulan(data), 30000);
    });

    test('rata-rata daftar kosong adalah 0', () {
      expect(ExpenseAggregator.rataRataPerBulan(<MonthlyExpense>[]), 0);
    });
  });
}
