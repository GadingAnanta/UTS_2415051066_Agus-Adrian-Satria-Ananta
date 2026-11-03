import 'package:intl/intl.dart';

/// Kumpulan helper untuk memformat angka, uang, dan tanggal ke gaya Indonesia.
///
/// Penting: `DateFormat` dengan locale `id_ID` butuh data locale yang dimuat
/// lewat `initializeDateFormatting('id_ID')`. Pemanggilan itu dilakukan sekali
/// di `main()` sebelum aplikasi dijalankan.

// Objek formatter dibuat sekali saja (mahal jika dibuat berulang di dalam build).
final NumberFormat _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final NumberFormat _angka = NumberFormat.decimalPattern('id_ID');
final DateFormat _tanggalPanjang = DateFormat('d MMMM yyyy', 'id_ID');
final DateFormat _tanggalPendek = DateFormat('dd/MM/yyyy', 'id_ID');
final DateFormat _bulanSingkat = DateFormat('MMM yy', 'id_ID');
final DateFormat _iso = DateFormat('yyyy-MM-dd');

/// Contoh keluaran: `Rp 125.000`
String formatRupiah(num nilai) => _rupiah.format(nilai);

/// Contoh keluaran: `12.500 km`
String formatKm(num kilometer) => '${_angka.format(kilometer)} km';

/// Contoh keluaran: `1 November 2026`
String formatTanggal(DateTime tanggal) => _tanggalPanjang.format(tanggal);

/// Contoh keluaran: `01/11/2026`
String formatTanggalPendek(DateTime tanggal) => _tanggalPendek.format(tanggal);

/// Contoh keluaran: `Nov 26` (dipakai untuk label grafik bulanan)
String formatBulan(DateTime tanggal) => _bulanSingkat.format(tanggal);

/// Mengubah DateTime menjadi teks ISO `yyyy-MM-dd` untuk disimpan di database.
String toIsoDate(DateTime tanggal) => _iso.format(tanggal);

/// Mengubah teks ISO dari database kembali menjadi DateTime.
DateTime parseIsoDate(String teks) => DateTime.parse(teks);

/// Menghitung selisih hari (dibulatkan ke bawah) dari hari ini sampai [target].
/// Hasil negatif berarti [target] sudah lewat.
int daysFromToday(DateTime target) {
  final DateTime hariIni = DateTime.now();
  final DateTime awalHariIni = DateTime(hariIni.year, hariIni.month, hariIni.day);
  final DateTime awalTarget = DateTime(target.year, target.month, target.day);
  return awalTarget.difference(awalHariIni).inDays;
}
