/// Pengaturan interval servis untuk satu jenis komponen.
///
/// Contoh: Oli Mesin punya interval 2.000 km atau 2 bulan. Aki hanya punya
/// interval waktu 24 bulan, sehingga `kmInterval` bernilai null.
///
/// Data awal diambil dari `defaultComponentIntervals` (lihat `utils/constants.dart`)
/// dan boleh diubah pengguna lewat halaman Pengaturan Interval.
class ComponentInterval {
  /// Kunci unik & tetap, dipakai sebagai penghubung ke catatan servis.
  final String key;

  final String name;

  /// Interval kilometer. `null` = komponen ini tidak memakai patokan KM.
  final int? kmInterval;

  /// Interval bulan. `null` = komponen ini tidak memakai patokan waktu.
  final int? monthInterval;

  /// Kunci ikon (dipetakan ke `IconData` lewat `iconForComponent`).
  final String iconKey;

  /// Jika false, komponen tidak ikut dihitung di dashboard & pengingat.
  final bool isActive;

  /// Urutan tampil di daftar komponen.
  final int sortOrder;

  const ComponentInterval({
    required this.key,
    required this.name,
    this.kmInterval,
    this.monthInterval,
    this.iconKey = 'lainnya',
    this.isActive = true,
    this.sortOrder = 0,
  });

  bool get hasKmInterval => kmInterval != null && kmInterval! > 0;
  bool get hasMonthInterval => monthInterval != null && monthInterval! > 0;

  ComponentInterval copyWith({
    String? key,
    String? name,
    int? kmInterval,
    int? monthInterval,
    String? iconKey,
    bool? isActive,
    int? sortOrder,
  }) {
    return ComponentInterval(
      key: key ?? this.key,
      name: name ?? this.name,
      kmInterval: kmInterval ?? this.kmInterval,
      monthInterval: monthInterval ?? this.monthInterval,
      iconKey: iconKey ?? this.iconKey,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Mengubah interval menjadi teks ringkas, contoh: `2.000 km / 2 bulan`.
  String get intervalLabel {
    final List<String> bagian = <String>[];
    if (hasKmInterval) {
      // Ditulis manual agar file model tidak bergantung pada helper format.
      final String angka = kmInterval!.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (Match m) => '${m[1]}.',
      );
      bagian.add('$angka km');
    }
    if (hasMonthInterval) {
      bagian.add('$monthInterval bulan');
    }
    return bagian.isEmpty ? 'Tidak diatur' : bagian.join(' / ');
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'key': key,
      'name': name,
      'km_interval': kmInterval,
      'month_interval': monthInterval,
      'icon_key': iconKey,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory ComponentInterval.fromMap(Map<String, Object?> map) {
    return ComponentInterval(
      key: map['key'] as String,
      name: map['name'] as String,
      kmInterval: map['km_interval'] as int?,
      monthInterval: map['month_interval'] as int?,
      iconKey: map['icon_key'] as String? ?? 'lainnya',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'ComponentInterval($key, $intervalLabel)';
}
