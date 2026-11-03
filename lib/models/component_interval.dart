/// Pengaturan interval servis untuk satu jenis komponen.
///
/// Contoh: Oli Mesin punya interval 2.000 km atau 2 bulan. Aki hanya punya
/// interval waktu 24 bulan, sehingga `kmInterval` bernilai null.
///
/// Data awal diambil dari `defaultComponentIntervals` (lihat `utils/constants.dart`).
///
/// Sejak aplikasi memakai Supabase, daftar komponen bukan lagi tabel
/// database melainkan konfigurasi statis di sisi aplikasi. Karena itu kelas
/// ini hanya menyimpan data di memori (tidak ada `toMap`/`fromMap`).
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

  @override
  String toString() => 'ComponentInterval($key, $intervalLabel)';
}
