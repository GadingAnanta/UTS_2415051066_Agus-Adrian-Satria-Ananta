import 'package:bengkel_digital/models/vehicle.dart';
import 'package:bengkel_digital/utils/vehicle_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membuat kendaraan uji dengan tanggal relatif terhadap hari ini.
Vehicle buatKendaraan({
  required int id,
  String brand = 'Honda',
  String model = 'Vario 160',
  String plate = 'B 1234 XYZ',
  int year = 2021,
  DateTime? taxDueDate,
  DateTime? stnkDueDate,
}) {
  return Vehicle(
    id: id,
    userId: 'user-demo',
    brand: brand,
    model: model,
    year: year,
    plateNumber: plate,
    currentKm: 12000,
    taxDueDate: taxDueDate,
    stnkDueDate: stnkDueDate,
    createdAt: DateTime(2024, 1, id),
  );
}

DateTime hariIni(int tambahHari) {
  final DateTime sekarang = DateTime.now();
  return DateTime(sekarang.year, sekarang.month, sekarang.day)
      .add(Duration(days: tambahHari));
}

void main() {
  final List<Vehicle> data = <Vehicle>[
    buatKendaraan(
      id: 1,
      brand: 'Honda',
      model: 'Vario 160',
      plate: 'B 1234 XYZ',
      year: 2021,
      taxDueDate: hariIni(10),
      stnkDueDate: hariIni(400),
    ),
    buatKendaraan(
      id: 2,
      brand: 'Yamaha',
      model: 'NMAX',
      plate: 'D 5678 ABC',
      year: 2023,
      taxDueDate: hariIni(-5),
      stnkDueDate: hariIni(500),
    ),
    buatKendaraan(
      id: 3,
      brand: 'Suzuki',
      model: 'Satria F150',
      plate: 'F 9012 QWE',
      year: 2019,
    ),
  ];

  group('filterVehicles — pencarian', () {
    test('kata kunci kosong mengembalikan semua data dengan urutan sama', () {
      final List<Vehicle> hasil = filterVehicles(data);

      expect(hasil.map((Vehicle v) => v.id), <int>[1, 2, 3]);
    });

    test('mencocokkan merek tanpa peduli huruf besar/kecil', () {
      final List<Vehicle> hasil = filterVehicles(data, query: 'honda');

      expect(hasil, hasLength(1));
      expect(hasil.single.id, 1);
    });

    test('mencocokkan model dan plat nomor', () {
      expect(filterVehicles(data, query: 'nmax').single.id, 2);
      expect(filterVehicles(data, query: '9012').single.id, 3);
    });

    test('kata kunci lebih dari satu harus muncul semuanya', () {
      final List<Vehicle> hasil = filterVehicles(data, query: 'yamaha 2023');

      expect(hasil.single.id, 2);
      expect(filterVehicles(data, query: 'yamaha 2021'), isEmpty);
    });

    test('spasi berlebih diabaikan', () {
      final List<Vehicle> hasil = filterVehicles(data, query: '  vario   160 ');

      expect(hasil.single.id, 1);
    });

    test('kata kunci yang tidak ada menghasilkan daftar kosong', () {
      expect(filterVehicles(data, query: 'kawasaki'), isEmpty);
    });
  });

  group('filterVehicles — filter tanggal', () {
    test('semua mengembalikan seluruh data', () {
      expect(
        filterVehicles(data, filter: VehicleFilter.semua),
        hasLength(3),
      );
    });

    test('pajakDekat memuat yang ≤ 30 hari dan yang sudah terlambat', () {
      final List<Vehicle> hasil =
          filterVehicles(data, filter: VehicleFilter.pajakDekat);

      expect(hasil.map((Vehicle v) => v.id), <int>[1, 2]);
    });

    test('pajakDekat mengabaikan kendaraan tanpa tanggal', () {
      final List<Vehicle> hasil =
          filterVehicles(data, filter: VehicleFilter.pajakDekat);

      expect(hasil.any((Vehicle v) => v.id == 3), isFalse);
    });

    test('belumDiatur memuat kendaraan yang tanggalnya kosong', () {
      final List<Vehicle> hasil =
          filterVehicles(data, filter: VehicleFilter.belumDiatur);

      expect(hasil.single.id, 3);
    });

    test('pencarian dan filter dipakai bersamaan', () {
      final List<Vehicle> hasil = filterVehicles(
        data,
        query: 'yamaha',
        filter: VehicleFilter.pajakDekat,
      );

      expect(hasil.single.id, 2);

      final List<Vehicle> kosong = filterVehicles(
        data,
        query: 'yamaha',
        filter: VehicleFilter.belumDiatur,
      );

      expect(kosong, isEmpty);
    });
  });
}
