import '../models/vehicle.dart';
import 'formatters.dart';

/// Pilihan filter pada halaman daftar kendaraan.
///
/// Filter disimpan di [VehicleProvider] sebagai state bersama, sehingga
/// halaman lain (misalnya ringkasan) bisa membaca filter yang sama.
enum VehicleFilter {
  /// Semua kendaraan, tanpa penyaringan.
  semua('Semua'),

  /// Pajak atau STNK jatuh tempo dalam 30 hari ke depan (termasuk terlambat).
  pajakDekat('Pajak ≤ 30 hari'),

  /// Tanggal pajak atau STNK belum diisi.
  belumDiatur('Belum diatur');

  const VehicleFilter(this.label);

  /// Teks yang ditampilkan pada chip filter.
  final String label;
}

/// Menyaring daftar kendaraan berdasarkan kata kunci dan [VehicleFilter].
///
/// Fungsi murni (tanpa akses database) supaya mudah diuji dan bisa dipakai
/// ulang di mana saja:
/// - [query] dicocokkan dengan merek, model, dan plat nomor (tanpa peduli
///   huruf besar/kecil maupun spasi berlebih).
/// - [filter] `semua` mengembalikan seluruh data.
/// - Urutan hasil tetap seperti urutan aslinya (terlama lebih dulu).
List<Vehicle> filterVehicles(
  List<Vehicle> vehicles, {
  String query = '',
  VehicleFilter filter = VehicleFilter.semua,
}) {
  final String kunci = _normalisasi(query);

  return vehicles.where((Vehicle kendaraan) {
    if (!_cocokKunci(kendaraan, kunci)) return false;
    return _cocokFilter(kendaraan, filter);
  }).toList(growable: false);
}

/// True bila [kendaraan] memenuhi [filter].
bool _cocokFilter(Vehicle kendaraan, VehicleFilter filter) {
  switch (filter) {
    case VehicleFilter.semua:
      return true;
    case VehicleFilter.pajakDekat:
      return _sisaHariTerdekat(kendaraan) <= 30;
    case VehicleFilter.belumDiatur:
      return kendaraan.taxDueDate == null || kendaraan.stnkDueDate == null;
  }
}

/// Sisa hari ke jatuh tempo terdekat (pajak atau STNK).
///
/// Bila salah satu tanggal kosong, tanggal itu diabaikan. Bila keduanya
/// kosong, hasilnya [double.infinity] supaya tidak ikut terhitung "dekat".
double _sisaHariTerdekat(Vehicle kendaraan) {
  final List<DateTime> tanggal = <DateTime>[
    if (kendaraan.taxDueDate != null) kendaraan.taxDueDate!,
    if (kendaraan.stnkDueDate != null) kendaraan.stnkDueDate!,
  ];
  if (tanggal.isEmpty) return double.infinity;

  int terdekat = daysFromToday(tanggal.first);
  for (final DateTime item in tanggal.skip(1)) {
    final int sisa = daysFromToday(item);
    if (sisa < terdekat) terdekat = sisa;
  }
  return terdekat.toDouble();
}

/// Apakah kendaraan cocok dengan kata kunci pencarian.
bool _cocokKunci(Vehicle kendaraan, String kunci) {
  if (kunci.isEmpty) return true;

  final String gabungan = _normalisasi(
    '${kendaraan.brand} ${kendaraan.model} ${kendaraan.plateNumber} '
    '${kendaraan.year}',
  );

  // Setiap kata pada kunci harus muncul, jadi "honda 2021" tetap cocok.
  return kunci.split(' ').every(gabungan.contains);
}

/// Huruf kecil, tanpa spasi ganda, tanpa spasi di ujung.
String _normalisasi(String teks) {
  return teks.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
