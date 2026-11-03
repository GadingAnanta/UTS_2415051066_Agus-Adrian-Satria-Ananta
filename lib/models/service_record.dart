/// Model satu catatan servis.
///
/// Satu kendaraan bisa punya banyak catatan servis (relasi 1 : banyak).
/// Objek ini dipetakan ke tabel `service_records` di Supabase.
class ServiceRecord {
  final int? id;
  final int vehicleId;

  /// Kunci komponen yang diservis, contoh: `oli_mesin`.
  /// Nilainya merujuk ke `ComponentInterval.key`.
  final String componentKey;

  final DateTime serviceDate;

  /// Kilometer kendaraan saat servis dilakukan.
  final int kmAtService;

  /// Biaya servis dalam rupiah (disimpan sebagai bilangan bulat).
  final int cost;

  final String? workshopName;
  final String? note;
  final DateTime createdAt;

  const ServiceRecord({
    this.id,
    required this.vehicleId,
    required this.componentKey,
    required this.serviceDate,
    required this.kmAtService,
    required this.cost,
    this.workshopName,
    this.note,
    required this.createdAt,
  });

  ServiceRecord copyWith({
    int? id,
    int? vehicleId,
    String? componentKey,
    DateTime? serviceDate,
    int? kmAtService,
    int? cost,
    String? workshopName,
    String? note,
    DateTime? createdAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      componentKey: componentKey ?? this.componentKey,
      serviceDate: serviceDate ?? this.serviceDate,
      kmAtService: kmAtService ?? this.kmAtService,
      cost: cost ?? this.cost,
      workshopName: workshopName ?? this.workshopName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Data yang dikirim saat INSERT (id & created_at dibuat database).
  Map<String, Object?> toInsertJson() {
    return <String, Object?>{
      'vehicle_id': vehicleId,
      'component': componentKey,
      'service_date': _tanggalKeTeks(serviceDate),
      'service_km': kmAtService,
      'cost': cost,
      'workshop': workshopName,
      'note': note,
    };
  }

  /// Data yang dikirim saat UPDATE.
  Map<String, Object?> toUpdateJson() => toInsertJson();

  /// Membuat objek dari baris tabel `service_records`.
  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: _keInt(json['id']),
      vehicleId: _keInt(json['vehicle_id']) ?? 0,
      componentKey: json['component'] as String? ?? 'lainnya',
      serviceDate: _keTanggal(json['service_date']) ?? DateTime.now(),
      kmAtService: _keInt(json['service_km']) ?? 0,
      cost: _keInt(json['cost']) ?? 0,
      workshopName: json['workshop'] as String?,
      note: json['note'] as String?,
      createdAt: _keTanggal(json['created_at']) ?? DateTime.now(),
    );
  }

  static String _tanggalKeTeks(DateTime tanggal) {
    final String bulan = tanggal.month.toString().padLeft(2, '0');
    final String hari = tanggal.day.toString().padLeft(2, '0');
    return '${tanggal.year}-$bulan-$hari';
  }

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
  String toString() =>
      'ServiceRecord(id: $id, komponen: $componentKey, km: $kmAtService, biaya: $cost)';
}
