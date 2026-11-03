/// Model satu catatan servis.
///
/// Satu kendaraan bisa punya banyak catatan servis (relasi 1 : banyak).
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

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'component_key': componentKey,
      'service_date': serviceDate.toIso8601String(),
      'km_at_service': kmAtService,
      'cost': cost,
      'workshop_name': workshopName,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServiceRecord.fromMap(Map<String, Object?> map) {
    return ServiceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      componentKey: map['component_key'] as String,
      serviceDate: DateTime.parse(map['service_date'] as String),
      kmAtService: map['km_at_service'] as int,
      cost: map['cost'] as int,
      workshopName: map['workshop_name'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'ServiceRecord(id: $id, komponen: $componentKey, km: $kmAtService, biaya: $cost)';
}
