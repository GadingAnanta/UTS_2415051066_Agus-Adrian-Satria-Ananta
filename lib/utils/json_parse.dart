// Helper kecil untuk membaca nilai JSON dari Supabase/API dengan aman.
//
// Data dari server bisa datang sebagai `int`, `num`, atau `String`
// (PostgreSQL kadang mengirim angka besar sebagai teks). Dua fungsi di sini
// dipakai bersama oleh model kendaraan, catatan servis, dan data tips supaya
// aturan konversinya hanya ditulis sekali.

/// Mengubah nilai apa pun menjadi `int`, atau `null` bila tidak bisa dibaca.
int? keInt(Object? nilai) {
  if (nilai == null) return null;
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();
  return int.tryParse(nilai.toString());
}

/// Mengubah nilai tanggal dari database menjadi `DateTime` lokal.
///
/// Kolom `date` dikirim sebagai `YYYY-MM-DD`, sedangkan `timestamptz` sebagai
/// ISO 8601. Nilai yang tidak bisa di-parse menghasilkan `null` (bukan error)
/// supaya satu baris rusak tidak menggagalkan seluruh daftar.
DateTime? keTanggal(Object? nilai) {
  if (nilai == null) return null;
  if (nilai is DateTime) return nilai;
  final String teks = nilai.toString();
  if (teks.isEmpty) return null;
  return DateTime.tryParse(teks)?.toLocal();
}
