import '../utils/json_parse.dart';

/// Model untuk berkas `tips.json` yang diambil lewat REST API.
///
/// Berkas ini berisi tiga bagian:
/// 1. [katalogMotor] — daftar motor beserta spesifikasi ringkasnya.
/// 2. [tipsPerawatan] — tips perawatan berkendara.
/// 3. [intervalServis] — interval servis standar per komponen, dipakai
///    sebagai pembanding data interval di aplikasi.
///
/// Semua kelas di file ini sengaja "tahan banting": kolom yang hilang atau
/// bertipe lain tidak membuat aplikasi crash, cukup memakai nilai default.
class TipsData {
  final int versi;
  final String diperbarui;
  final String sumber;
  final List<KatalogMotor> katalogMotor;
  final List<TipsPerawatan> tipsPerawatan;
  final List<IntervalServisStandar> intervalServis;

  const TipsData({
    this.versi = 1,
    this.diperbarui = '',
    this.sumber = '',
    this.katalogMotor = const <KatalogMotor>[],
    this.tipsPerawatan = const <TipsPerawatan>[],
    this.intervalServis = const <IntervalServisStandar>[],
  });

  /// True bila API mengembalikan data kosong (dipakai untuk empty state).
  bool get isEmpty =>
      katalogMotor.isEmpty && tipsPerawatan.isEmpty && intervalServis.isEmpty;

  /// Jumlah total butir data, ditampilkan di ringkasan halaman.
  int get jumlahItem =>
      katalogMotor.length + tipsPerawatan.length + intervalServis.length;

  factory TipsData.fromJson(Map<String, dynamic> json) {
    return TipsData(
      versi: JsonBaca.integer(json['versi']) ?? 1,
      diperbarui: JsonBaca.teks(json['diperbarui']),
      sumber: JsonBaca.teks(json['sumber']),
      katalogMotor: JsonBaca.daftar(json['katalog_motor'], KatalogMotor.fromJson),
      tipsPerawatan: JsonBaca.daftar(json['tips_perawatan'], TipsPerawatan.fromJson),
      intervalServis:
          JsonBaca.daftar(json['interval_servis'], IntervalServisStandar.fromJson),
    );
  }
}

/// Satu motor pada katalog.
class KatalogMotor {
  final String id;
  final String merek;
  final String model;
  final int tahun;
  final String jenis;
  final int kapasitasCc;
  final String transmisi;
  final String rekomendasiOli;
  final int? intervalServisKm;
  final int? konsumsiBbm;
  final String catatan;

  const KatalogMotor({
    required this.id,
    required this.merek,
    required this.model,
    required this.tahun,
    this.jenis = '',
    this.kapasitasCc = 0,
    this.transmisi = '',
    this.rekomendasiOli = '',
    this.intervalServisKm,
    this.konsumsiBbm,
    this.catatan = '',
  });

  /// Contoh: `Honda Vario 160 CBS`.
  String get namaLengkap => '$merek $model'.trim();

  /// Contoh: `160 cc`.
  String get labelKapasitas => kapasitasCc > 0 ? '$kapasitasCc cc' : '-';

  /// Contoh: `Servis tiap 2.000 km`.
  String get labelInterval {
    final int? km = intervalServisKm;
    if (km == null || km <= 0) return 'Interval tidak diatur';
    return 'Servis tiap ${JsonBaca.pisahRibuan(km)} km';
  }

  factory KatalogMotor.fromJson(Map<String, dynamic> json) {
    return KatalogMotor(
      id: JsonBaca.teks(json['id']),
      merek: JsonBaca.teks(json['merek']),
      model: JsonBaca.teks(json['model']),
      tahun: JsonBaca.integer(json['tahun']) ?? 0,
      jenis: JsonBaca.teks(json['jenis']),
      kapasitasCc: JsonBaca.integer(json['kapasitas_cc']) ?? 0,
      transmisi: JsonBaca.teks(json['transmisi']),
      rekomendasiOli: JsonBaca.teks(json['rekomendasi_oli']),
      intervalServisKm: JsonBaca.integer(json['interval_servis_km']),
      konsumsiBbm: JsonBaca.integer(json['konsumsi_bbm_km_per_liter']),
      catatan: JsonBaca.teks(json['catatan']),
    );
  }
}

/// Satu tips perawatan.
class TipsPerawatan {
  final int id;
  final String judul;
  final String kategori;
  final String ringkasan;

  /// Langkah-langkah praktis (boleh kosong).
  final List<String> langkah;

  final int? intervalKm;
  final int? intervalBulan;

  const TipsPerawatan({
    required this.id,
    required this.judul,
    this.kategori = 'Umum',
    this.ringkasan = '',
    this.langkah = const <String>[],
    this.intervalKm,
    this.intervalBulan,
  });

  /// Contoh: `2.000 km / 2 bulan`, atau `-` bila tidak ada patokan.
  String get labelInterval {
    final List<String> bagian = <String>[];
    final int? km = intervalKm;
    final int? bulan = intervalBulan;
    if (km != null && km > 0) bagian.add('${JsonBaca.pisahRibuan(km)} km');
    if (bulan != null && bulan > 0) bagian.add('$bulan bulan');
    return bagian.isEmpty ? '-' : bagian.join(' / ');
  }

  factory TipsPerawatan.fromJson(Map<String, dynamic> json) {
    return TipsPerawatan(
      id: JsonBaca.integer(json['id']) ?? 0,
      judul: JsonBaca.teks(json['judul']),
      kategori: JsonBaca.teks(json['kategori'], fallback: 'Umum'),
      ringkasan: JsonBaca.teks(json['ringkasan']),
      langkah: JsonBaca.daftarTeks(json['langkah']),
      intervalKm: JsonBaca.integer(json['interval_km']),
      intervalBulan: JsonBaca.integer(json['interval_bulan']),
    );
  }
}

/// Interval servis standar untuk satu komponen.
///
/// Nilai `komponen` memakai kunci yang sama dengan `ComponentInterval.key`
/// di aplikasi (contoh: `oli_mesin`), sehingga bisa dibandingkan langsung.
class IntervalServisStandar {
  final String komponen;
  final String nama;
  final int? intervalKm;
  final int? intervalBulan;
  final String keterangan;

  const IntervalServisStandar({
    required this.komponen,
    required this.nama,
    this.intervalKm,
    this.intervalBulan,
    this.keterangan = '',
  });

  bool get punyaIntervalKm => intervalKm != null && intervalKm! > 0;
  bool get punyaIntervalBulan => intervalBulan != null && intervalBulan! > 0;

  /// Contoh: `2.000 km / 2 bulan`, atau `24 bulan` untuk aki.
  String get labelInterval {
    final List<String> bagian = <String>[];
    if (punyaIntervalKm) bagian.add('${JsonBaca.pisahRibuan(intervalKm!)} km');
    if (punyaIntervalBulan) bagian.add('$intervalBulan bulan');
    return bagian.isEmpty ? 'Tidak diatur' : bagian.join(' / ');
  }

  factory IntervalServisStandar.fromJson(Map<String, dynamic> json) {
    return IntervalServisStandar(
      komponen: JsonBaca.teks(json['komponen']),
      nama: JsonBaca.teks(json['nama']),
      intervalKm: JsonBaca.integer(json['interval_km']),
      intervalBulan: JsonBaca.integer(json['interval_bulan']),
      keterangan: JsonBaca.teks(json['keterangan']),
    );
  }
}

/// Kumpulan helper kecil untuk membaca JSON dengan aman.
///
/// Dipisah ke kelas sendiri supaya model tidak bergantung pada paket lain
/// (misalnya `intl`) dan tetap mudah diuji.
class JsonBaca {
  const JsonBaca._();

  static String teks(Object? nilai, {String fallback = ''}) {
    if (nilai == null) return fallback;
    final String hasil = nilai.toString().trim();
    return hasil.isEmpty ? fallback : hasil;
  }

  static int? integer(Object? nilai) => keInt(nilai);

  /// Mengubah daftar JSON menjadi daftar objek model.
  /// Butir yang bukan objek dilewati, bukan membuat parsing gagal.
  static List<T> daftar<T>(
    Object? nilai,
    T Function(Map<String, dynamic>) pembuat,
  ) {
    if (nilai is! List) return <T>[];
    return nilai
        .whereType<Map<String, dynamic>>()
        .map(pembuat)
        .toList(growable: false);
  }

  static List<String> daftarTeks(Object? nilai) {
    if (nilai is! List) return const <String>[];
    return nilai
        .map((Object? item) => teks(item))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// Format ribuan sederhana: `2000` menjadi `2.000`.
  static String pisahRibuan(int angka) {
    return angka.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (Match m) => '${m[1]}.',
        );
  }
}
