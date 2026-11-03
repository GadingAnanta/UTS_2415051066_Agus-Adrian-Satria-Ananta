import 'package:flutter_test/flutter_test.dart';

import 'package:bengkel_digital/models/component_interval.dart';
import 'package:bengkel_digital/models/service_record.dart';
import 'package:bengkel_digital/utils/service_calculator.dart';

/// Helper membuat catatan servis cepat.
ServiceRecord _catatan({
  int? id,
  String componentKey = 'oli_mesin',
  DateTime? tanggal,
  int km = 10000,
  int biaya = 50000,
}) {
  final DateTime waktu = tanggal ?? DateTime(2026, 1, 1);
  return ServiceRecord(
    id: id,
    vehicleId: 1,
    componentKey: componentKey,
    serviceDate: waktu,
    kmAtService: km,
    cost: biaya,
    createdAt: waktu,
  );
}

/// Komponen uji dengan interval KM + bulan.
const ComponentInterval _oliMesin = ComponentInterval(
  key: 'oli_mesin',
  name: 'Oli Mesin',
  kmInterval: 2000,
  monthInterval: 2,
  sortOrder: 1,
);

/// Komponen uji yang hanya punya patokan waktu (mirip Aki).
const ComponentInterval _aki = ComponentInterval(
  key: 'aki',
  name: 'Aki',
  monthInterval: 24,
  sortOrder: 2,
);

void main() {
  group('ServiceCalculator.hitungSisaKm', () {
    test('menghitung sisa KM dari servis terakhir', () {
      final int sisa = ServiceCalculator.hitungSisaKm(
        currentKm: 11500,
        kmAtService: 10000,
        kmInterval: 2000,
      );
      expect(sisa, 500);
    });

    test('menghasilkan angka negatif bila servis sudah terlambat', () {
      final int sisa = ServiceCalculator.hitungSisaKm(
        currentKm: 13000,
        kmAtService: 10000,
        kmInterval: 2000,
      );
      expect(sisa, -1000);
    });

    test('tepat di kilometer servis berarti sisa 0', () {
      final int sisa = ServiceCalculator.hitungSisaKm(
        currentKm: 12000,
        kmAtService: 10000,
        kmInterval: 2000,
      );
      expect(sisa, 0);
    });
  });

  group('ServiceCalculator.hitungTanggalServisBerikutnya', () {
    test('menambah bulan dengan tepat', () {
      expect(
        ServiceCalculator.hitungTanggalServisBerikutnya(
          lastServiceDate: DateTime(2026, 1, 10),
          monthInterval: 2,
        ),
        DateTime(2026, 3, 10),
      );
    });

    test('melewati batas tahun', () {
      expect(
        ServiceCalculator.hitungTanggalServisBerikutnya(
          lastServiceDate: DateTime(2026, 12, 15),
          monthInterval: 6,
        ),
        DateTime(2027, 6, 15),
      );
    });

    test('31 Januari + 1 bulan dipangkas ke akhir Februari', () {
      expect(
        ServiceCalculator.hitungTanggalServisBerikutnya(
          lastServiceDate: DateTime(2026, 1, 31),
          monthInterval: 1,
        ),
        DateTime(2026, 2, 28),
      );
    });

    test('tahun kabisat memakai 29 Februari', () {
      expect(
        ServiceCalculator.hitungTanggalServisBerikutnya(
          lastServiceDate: DateTime(2024, 1, 31),
          monthInterval: 1,
        ),
        DateTime(2024, 2, 29),
      );
    });
  });

  group('ServiceCalculator.hitungSisaHari', () {
    test('menghitung selisih hari dari tanggal acuan', () {
      final int sisa = ServiceCalculator.hitungSisaHari(
        target: DateTime(2026, 3, 1),
        dari: DateTime(2026, 2, 1),
      );
      expect(sisa, 28);
    });

    test('jam diabaikan sehingga hari yang sama bernilai 0', () {
      final int sisa = ServiceCalculator.hitungSisaHari(
        target: DateTime(2026, 2, 1, 23, 59),
        dari: DateTime(2026, 2, 1, 0, 1),
      );
      expect(sisa, 0);
    });

    test('tanggal yang sudah lewat bernilai negatif', () {
      final int sisa = ServiceCalculator.hitungSisaHari(
        target: DateTime(2026, 1, 1),
        dari: DateTime(2026, 2, 1),
      );
      expect(sisa, -31);
    });
  });

  group('ServiceCalculator.statusDariSisaKm', () {
    test('di atas zona kuning berarti aman (hijau)', () {
      expect(
        ServiceCalculator.statusDariSisaKm(sisaKm: 401, kmInterval: 2000),
        ServiceStatus.aman,
      );
    });

    test('tepat di batas zona kuning berarti mendekati', () {
      expect(
        ServiceCalculator.statusDariSisaKm(sisaKm: 400, kmInterval: 2000),
        ServiceStatus.mendekati,
      );
    });

    test('sisa 0 berarti mendekati (jadwal servis tiba)', () {
      expect(
        ServiceCalculator.statusDariSisaKm(sisaKm: 0, kmInterval: 2000),
        ServiceStatus.mendekati,
      );
    });

    test('sisa negatif berarti lewat batas (merah)', () {
      expect(
        ServiceCalculator.statusDariSisaKm(sisaKm: -1, kmInterval: 2000),
        ServiceStatus.lewatBatas,
      );
    });

    test('interval kecil tetap punya zona kuning minimal 300 km', () {
      // 20% dari 1.000 km hanya 200 km, jadi dipakai batas minimal 300 km.
      expect(
        ServiceCalculator.statusDariSisaKm(sisaKm: 300, kmInterval: 1000),
        ServiceStatus.mendekati,
      );
      expect(
        ServiceCalculator.statusDariSisaKm(sisaKm: 301, kmInterval: 1000),
        ServiceStatus.aman,
      );
    });
  });

  group('ServiceCalculator.statusDariSisaHari', () {
    test('memakai 20% dari panjang interval', () {
      // 20% dari 60 hari = 12 hari.
      expect(
        ServiceCalculator.statusDariSisaHari(sisaHari: 13, totalHari: 60),
        ServiceStatus.aman,
      );
      expect(
        ServiceCalculator.statusDariSisaHari(sisaHari: 12, totalHari: 60),
        ServiceStatus.mendekati,
      );
    });

    test('interval pendek memakai zona kuning minimal 7 hari', () {
      expect(
        ServiceCalculator.statusDariSisaHari(sisaHari: 7, totalHari: 10),
        ServiceStatus.mendekati,
      );
      expect(
        ServiceCalculator.statusDariSisaHari(sisaHari: 8, totalHari: 10),
        ServiceStatus.aman,
      );
    });

    test('sisa negatif berarti lewat batas', () {
      expect(
        ServiceCalculator.statusDariSisaHari(sisaHari: -3, totalHari: 60),
        ServiceStatus.lewatBatas,
      );
    });
  });

  group('ServiceCalculator.hitungKomponen', () {
    test('menghitung sisa KM dan sisa hari sekaligus', () {
      final ComponentServiceStatus hasil = ServiceCalculator.hitungKomponen(
        component: _oliMesin,
        catatanTerakhir: _catatan(tanggal: DateTime(2026, 1, 1), km: 10000),
        currentKm: 11500,
        sekarang: DateTime(2026, 2, 1),
      );

      expect(hasil.remainingKm, 500);
      expect(hasil.nextServiceKm, 12000);
      expect(hasil.remainingDays, 28);
      expect(hasil.nextServiceDate, DateTime(2026, 3, 1));
      expect(hasil.kmStatus, ServiceStatus.aman);
      expect(hasil.dayStatus, ServiceStatus.aman);
      expect(hasil.status, ServiceStatus.aman);
      expect(hasil.hasData, isTrue);
    });

    test('status gabungan memakai yang paling buruk', () {
      // KM masih aman, tetapi tanggal servis sudah lewat sebulan.
      final ComponentServiceStatus hasil = ServiceCalculator.hitungKomponen(
        component: _oliMesin,
        catatanTerakhir: _catatan(tanggal: DateTime(2025, 11, 1), km: 10000),
        currentKm: 10500,
        sekarang: DateTime(2026, 2, 1),
      );

      expect(hasil.kmStatus, ServiceStatus.aman);
      expect(hasil.dayStatus, ServiceStatus.lewatBatas);
      expect(hasil.status, ServiceStatus.lewatBatas);
    });

    test('komponen tanpa riwayat servis berstatus belum ada data', () {
      final ComponentServiceStatus hasil = ServiceCalculator.hitungKomponen(
        component: _oliMesin,
        currentKm: 15000,
        sekarang: DateTime(2026, 2, 1),
      );

      expect(hasil.hasData, isFalse);
      expect(hasil.remainingKm, isNull);
      expect(hasil.remainingDays, isNull);
      expect(hasil.kmStatus, ServiceStatus.belumAdaData);
      expect(hasil.dayStatus, ServiceStatus.belumAdaData);
      expect(hasil.status, ServiceStatus.belumAdaData);
    });

    test('komponen tanpa interval KM hanya dihitung dari waktu', () {
      final ComponentServiceStatus hasil = ServiceCalculator.hitungKomponen(
        component: _aki,
        catatanTerakhir: _catatan(componentKey: 'aki', tanggal: DateTime(2025, 6, 1), km: 5000),
        currentKm: 20000,
        sekarang: DateTime(2026, 2, 1),
      );

      expect(hasil.remainingKm, isNull);
      expect(hasil.kmStatus, ServiceStatus.belumAdaData);
      expect(hasil.nextServiceDate, DateTime(2027, 6, 1));
      expect(hasil.remainingDays, isNotNull);
      // Status gabungan mengikuti satu-satunya patokan yang ada.
      expect(hasil.status, hasil.dayStatus);
    });
  });

  group('ServiceCalculator.hitungSemua', () {
    test('memilih catatan terbaru per komponen', () {
      final List<ComponentServiceStatus> hasil = ServiceCalculator.hitungSemua(
        komponen: <ComponentInterval>[_oliMesin, _aki],
        semuaCatatan: <ServiceRecord>[
          // Urutan sengaja diacak, seperti hasil query tanpa ORDER BY.
          _catatan(id: 1, tanggal: DateTime(2025, 10, 1), km: 8000),
          _catatan(id: 2, tanggal: DateTime(2026, 1, 1), km: 10000),
          _catatan(
            id: 3,
            componentKey: 'aki',
            tanggal: DateTime(2025, 6, 1),
            km: 5000,
          ),
        ],
        currentKm: 11500,
        sekarang: DateTime(2026, 2, 1),
      );

      expect(hasil.length, 2);
      expect(hasil.first.component.key, 'oli_mesin');
      expect(hasil.first.lastRecord?.id, 2);
      expect(hasil.first.remainingKm, 500);
      expect(hasil.last.component.key, 'aki');
      expect(hasil.last.lastRecord?.id, 3);
    });

    test('mengabaikan komponen yang tidak aktif', () {
      const ComponentInterval nonaktif = ComponentInterval(
        key: 'busi',
        name: 'Busi',
        kmInterval: 8000,
        monthInterval: 12,
        isActive: false,
        sortOrder: 3,
      );

      final List<ComponentServiceStatus> hasil = ServiceCalculator.hitungSemua(
        komponen: <ComponentInterval>[_oliMesin, nonaktif],
        semuaCatatan: const <ServiceRecord>[],
        currentKm: 1000,
      );

      expect(hasil.length, 1);
      expect(hasil.single.component.key, 'oli_mesin');
    });
  });
}
