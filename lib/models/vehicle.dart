/// Model data kendaraan (satu sepeda motor milik pengguna).
///
/// Objek ini dipetakan ke tabel `vehicles` di Supabase (PostgreSQL).
/// Nama field Dart memakai camelCase, sedangkan kolom database memakai
/// snake_case; penerjemahannya ada di [toJson] dan [fromJson].
class Vehicle {
  /// `null` berarti data belum tersimpan di database (kendaraan baru).
  final int? id;

  /// Pemilik data. Selama belum ada fitur login, diisi `DEMO_USER_ID`
  /// dari file `.env`.
  final String userId;

  final String brand;
  final String model;
  final int year;
  final String plateNumber;

  /// Kilometer terakhir yang diketahui. Diperbarui lewat fitur "Update KM".
  final int currentKm;

  /// Tanggal jatuh tempo pajak tahunan. `null` = belum diisi.
  final DateTime? taxDueDate;

  /// Tanggal jatuh tempo perpanjangan STNK 5 tahunan. `null` = belum diisi.
  final DateTime? stnkDueDate;

  /// Waktu data dibuat, dipakai untuk mengurutkan daftar kendaraan.
  final DateTime createdAt;

  const Vehicle({
    this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.currentKm,
    this.taxDueDate,
    this.stnkDueDate,
    required this.createdAt,
  });

  /// Nama tampilan, contoh: `Honda Vario 160`.
  String get displayName => '$brand $model';

  /// Salinan objek dengan sebagian field diubah.
  Vehicle copyWith({
    int? id,
    String? userId,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    int? currentKm,
    DateTime? taxDueDate,
    DateTime? stnkDueDate,
    DateTime? createdAt,
    bool hapusTaxDueDate = false,
    bool hapusStnkDueDate = false,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      currentKm: currentKm ?? this.currentKm,
      taxDueDate: hapusTaxDueDate ? null : (taxDueDate ?? this.taxDueDate),
      stnkDueDate: hapusStnkDueDate ? null : (stnkDueDate ?? this.stnkDueDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Data yang dikirim saat INSERT.
  ///
  /// `id` dan `created_at` sengaja tidak ikut karena dibuat otomatis
  /// oleh PostgreSQL (`generated always as identity` dan `now()`).
  Map<String, Object?> toInsertJson() {
    return <String, Object?>{
      'user_id': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'plate': plateNumber,
      'current_km': currentKm,
      'tax_due_date': _tanggalKeTeks(taxDueDate),
      'stnk_due_date': _tanggalKeTeks(stnkDueDate),
    };
  }

  /// Data yang dikirim saat UPDATE. Semua kolom ikut supaya nilai yang
  /// dikosongkan pengguna benar-benar menjadi `null` di database.
  Map<String, Object?> toUpdateJson() => toInsertJson();

  /// Membuat objek dari baris tabel `vehicles`.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: _keInt(json['id']),
      userId: json['user_id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: _keInt(json['year']) ?? 0,
      plateNumber: json['plate'] as String? ?? '',
      currentKm: _keInt(json['current_km']) ?? 0,
      taxDueDate: _keTanggal(json['tax_due_date']),
      stnkDueDate: _keTanggal(json['stnk_due_date']),
      createdAt: _keTanggal(json['created_at']) ?? DateTime.now(),
    );
  }

  /// Kolom `date` di Postgres dikirim sebagai `YYYY-MM-DD`.
  static String? _tanggalKeTeks(DateTime? tanggal) {
    if (tanggal == null) return null;
    final String bulan = tanggal.month.toString().padLeft(2, '0');
    final String hari = tanggal.day.toString().padLeft(2, '0');
    return '${tanggal.year}-$bulan-$hari';
  }

  /// `date` -> `YYYY-MM-DD`, `timestamptz` -> ISO 8601.
  static DateTime? _keTanggal(Object? nilai) {
    if (nilai == null) return null;
    if (nilai is DateTime) return nilai;
    final String teks = nilai.toString();
    if (teks.isEmpty) return null;
    return DateTime.tryParse(teks)?.toLocal();
  }

  static int? _keInt(Object? nilai) {
    if (nilai == null) return null;
    if (nilai is int) return nilai;
    if (nilai is num) return nilai.toInt();
    return int.tryParse(nilai.toString());
  }

  @override
  String toString() => 'Vehicle(id: $id, $displayName, ${plateNumber.trim()})';
}
