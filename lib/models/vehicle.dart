/// Model data kendaraan (satu sepeda motor milik pengguna).
///
/// Objek ini dipetakan langsung ke tabel `vehicles` di SQLite.
class Vehicle {
  /// `null` berarti data belum tersimpan di database (kendaraan baru).
  final int? id;
  final String brand;
  final String model;
  final int year;
  final String plateNumber;

  /// Kilometer terakhir yang diketahui. Diperbarui lewat fitur "Update KM".
  final int currentKm;

  /// Waktu data dibuat, dipakai untuk mengurutkan daftar kendaraan.
  final DateTime createdAt;

  const Vehicle({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.currentKm,
    required this.createdAt,
  });

  /// Nama tampilan, contoh: `Honda Vario 160`.
  String get displayName => '$brand $model';

  /// Salinan objek dengan sebagian field diubah.
  Vehicle copyWith({
    int? id,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    int? currentKm,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      currentKm: currentKm ?? this.currentKm,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Mengubah objek menjadi `Map` untuk disimpan oleh sqflite.
  ///
  /// Field `id` hanya ikut dikirim kalau tidak null, supaya SQLite bisa
  /// membuat AUTOINCREMENT saat data baru disisipkan.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'plate_number': plateNumber,
      'current_km': currentKm,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Membuat objek dari baris tabel SQLite.
  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as int?,
      brand: map['brand'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      plateNumber: map['plate_number'] as String,
      currentKm: map['current_km'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'Vehicle(id: $id, $displayName, ${plateNumber.trim()})';
}
