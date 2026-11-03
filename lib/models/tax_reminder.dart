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

/// Pengingat tanggal jatuh tempo pajak / STNK untuk satu kendaraan.
///
/// Tiap kendaraan punya maksimal satu baris untuk tiap [TaxType]
/// (dijaga oleh constraint UNIQUE(vehicle_id, type) di database).
class TaxReminder {
  final int? id;
  final int vehicleId;
  final TaxType type;

  /// Tanggal jatuh tempo.
  final DateTime dueDate;

  /// Kirim notifikasi 30 hari sebelum jatuh tempo.
  final bool notifyH30;

  /// Kirim notifikasi 7 hari sebelum jatuh tempo.
  final bool notifyH7;

  const TaxReminder({
    this.id,
    required this.vehicleId,
    required this.type,
    required this.dueDate,
    this.notifyH30 = true,
    this.notifyH7 = true,
  });

  /// Sisa hari menuju jatuh tempo (negatif = sudah lewat).
  int get daysRemaining {
    final DateTime hariIni = DateTime.now();
    final DateTime awalHariIni = DateTime(hariIni.year, hariIni.month, hariIni.day);
    final DateTime awalJatuhTempo = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return awalJatuhTempo.difference(awalHariIni).inDays;
  }

  bool get isOverdue => daysRemaining < 0;

  TaxReminder copyWith({
    int? id,
    int? vehicleId,
    TaxType? type,
    DateTime? dueDate,
    bool? notifyH30,
    bool? notifyH7,
  }) {
    return TaxReminder(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      notifyH30: notifyH30 ?? this.notifyH30,
      notifyH7: notifyH7 ?? this.notifyH7,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'type': type.value,
      'due_date': dueDate.toIso8601String(),
      'notify_h30': notifyH30 ? 1 : 0,
      'notify_h7': notifyH7 ? 1 : 0,
    };
  }

  factory TaxReminder.fromMap(Map<String, Object?> map) {
    return TaxReminder(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      type: TaxType.fromValue(map['type'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      notifyH30: (map['notify_h30'] as int? ?? 1) == 1,
      notifyH7: (map['notify_h7'] as int? ?? 1) == 1,
    );
  }

  @override
  String toString() => 'TaxReminder(${type.label}, jatuh tempo: $dueDate)';
}
