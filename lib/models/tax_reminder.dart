/// Jenis dokumen pajak yang diingatkan.
enum TaxType {
  pajakTahunan('pajak_tahunan', 'Pajak Tahunan'),
  stnkLimaTahunan('stnk_lima_tahunan', 'STNK 5 Tahunan');

  const TaxType(this.value, this.label);

  /// Nilai yang disimpan di kolom `type`.
  final String value;

  /// Label yang ditampilkan ke pengguna.
  final String label;

  /// Mengubah teks dari database kembali menjadi enum.
  /// Jika nilainya tidak dikenal, dianggap pajak tahunan.
  static TaxType fromValue(String value) {
    return TaxType.values.firstWhere(
      (TaxType tipe) => tipe.value == value,
      orElse: () => TaxType.pajakTahunan,
    );
  }
}

/// Pengingat tanggal jatuh tempo pajak / STNK.
///
/// Sejak data dipindah ke Supabase, tanggal jatuh tempo disimpan sebagai
/// kolom `tax_due_date` dan `stnk_due_date` pada tabel `vehicles`.
/// Jadi kelas ini bukan lagi tabel tersendiri, melainkan objek nilai
/// (value object) yang dibentuk dari data kendaraan untuk ditampilkan
/// dan dijadwalkan sebagai notifikasi.
class TaxReminder {
  final TaxType type;

  /// Tanggal jatuh tempo.
  final DateTime dueDate;

  /// Id kendaraan pemilik pengingat (opsional, untuk keperluan notifikasi).
  final int? vehicleId;

  const TaxReminder({
    required this.type,
    required this.dueDate,
    this.vehicleId,
  });

  /// Sisa hari menuju jatuh tempo (negatif = sudah lewat).
  int get daysRemaining {
    final DateTime hariIni = DateTime.now();
    final DateTime awalHariIni = DateTime(hariIni.year, hariIni.month, hariIni.day);
    final DateTime awalJatuhTempo = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return awalJatuhTempo.difference(awalHariIni).inDays;
  }

  bool get isOverdue => daysRemaining < 0;

  TaxReminder copyWith({TaxType? type, DateTime? dueDate, int? vehicleId}) {
    return TaxReminder(
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  @override
  String toString() => 'TaxReminder(${type.label}, jatuh tempo: $dueDate)';
}
