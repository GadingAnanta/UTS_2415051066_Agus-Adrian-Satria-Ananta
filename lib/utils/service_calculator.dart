import 'dart:math' show max;

import '../models/component_interval.dart';
import '../models/service_record.dart';

/// Status kesehatan satu komponen servis.
///
/// Dipakai untuk mewarnai kartu di dashboard:
/// - [aman]       → hijau, masih jauh dari jadwal servis
/// - [mendekati]  → kuning, sudah dekat dengan jadwal servis
/// - [lewatBatas] → merah, sudah melewati jadwal servis
/// - [belumAdaData] → abu-abu, komponen belum pernah dicatat servisnya
///
/// Nilai [urutan] dipakai untuk memilih status terburuk ketika sebuah komponen
/// punya dua patokan sekaligus (kilometer dan waktu).
enum ServiceStatus {
  belumAdaData('Belum ada data', 0),
  aman('Aman', 1),
  mendekati('Mendekati', 2),
  lewatBatas('Lewat batas', 3);

  const ServiceStatus(this.label, this.urutan);

  /// Teks yang ditampilkan ke pengguna.
  final String label;

  /// Semakin besar, semakin buruk. `belumAdaData` dianggap paling ringan
  /// supaya komponen yang hanya punya satu patokan tetap dinilai dari
  /// patokan yang ada.
  final int urutan;

  /// True bila status perlu perhatian pengguna (kuning atau merah).
  bool get butuhPerhatian => this == mendekati || this == lewatBatas;
}

/// Hasil perhitungan jadwal servis untuk satu komponen pada satu kendaraan.
class ComponentServiceStatus {
  /// Pengaturan interval komponen (nama, interval KM, interval bulan).
  final ComponentInterval component;

  /// Catatan servis terakhir. `null` = komponen belum pernah diservis.
  final ServiceRecord? lastRecord;

  /// Sisa kilometer menuju servis berikutnya. Negatif = sudah lewat.
  /// `null` bila komponen tidak punya patokan KM atau belum ada data.
  final int? remainingKm;

  /// Sisa hari menuju servis berikutnya. Negatif = sudah lewat.
  /// `null` bila komponen tidak punya patokan waktu atau belum ada data.
  final int? remainingDays;

  /// Perkiraan tanggal servis berikutnya (dari interval bulan).
  final DateTime? nextServiceDate;

  /// Kilometer kendaraan saat servis berikutnya seharusnya dilakukan.
  final int? nextServiceKm;

  /// Status dari patokan kilometer saja.
  final ServiceStatus kmStatus;

  /// Status dari patokan waktu saja.
  final ServiceStatus dayStatus;

  const ComponentServiceStatus({
    required this.component,
    this.lastRecord,
    this.remainingKm,
    this.remainingDays,
    this.nextServiceDate,
    this.nextServiceKm,
    this.kmStatus = ServiceStatus.belumAdaData,
    this.dayStatus = ServiceStatus.belumAdaData,
  });

  /// Status gabungan: diambil yang paling buruk dari KM dan waktu.
  ///
  /// Contoh: sisa KM masih aman tetapi tanggalnya sudah lewat → merah.
  ServiceStatus get status =>
      kmStatus.urutan >= dayStatus.urutan ? kmStatus : dayStatus;

  /// True bila sudah ada riwayat servis sehingga angka sisa bisa dihitung.
  bool get hasData => lastRecord != null;

  /// True bila komponen ini punya minimal satu patokan yang bisa dihitung.
  bool get hasInterval => component.hasKmInterval || component.hasMonthInterval;

  @override
  String toString() => 'ComponentServiceStatus(${component.key}, ${status.label})';
}

/// Kumpulan perhitungan jadwal servis.
///
/// Semua fungsi di sini murni (tidak menyentuh database maupun UI) sehingga
/// mudah diuji. Lihat `test/service_calculator_test.dart`.
///
/// Aturan penentuan status (dipakai konsisten untuk KM dan waktu):
/// - sisa < 0                       → [ServiceStatus.lewatBatas]
/// - 0 ≤ sisa ≤ batas kuning        → [ServiceStatus.mendekati]
/// - sisa > batas kuning            → [ServiceStatus.aman]
///
/// Batas kuning = 20% dari interval, tetapi tidak lebih kecil dari
/// [batasMendekatiKmMinimal] (KM) atau [batasMendekatiHariMinimal] (hari).
/// Tujuannya supaya interval pendek tetap punya "zona peringatan" yang wajar.
class ServiceCalculator {
  const ServiceCalculator._();

  /// Porsi interval yang dianggap "mendekati jadwal" (20%).
  static const double batasMendekatiRasio = 0.2;

  /// Zona peringatan minimal untuk patokan kilometer.
  static const int batasMendekatiKmMinimal = 300;

  /// Zona peringatan minimal untuk patokan waktu.
  static const int batasMendekatiHariMinimal = 7;

  /// Sisa kilometer menuju servis berikutnya.
  ///
  /// Rumus: `km saat servis terakhir + interval − km kendaraan sekarang`.
  /// Hasil negatif berarti servis sudah terlambat.
  static int hitungSisaKm({
    required int currentKm,
    required int kmAtService,
    required int kmInterval,
  }) {
    return kmAtService + kmInterval - currentKm;
  }

  /// Tanggal servis berikutnya berdasarkan interval bulan.
  ///
  /// Penambahan bulan dilakukan manual (bukan `Duration(days: 30)`) supaya
  /// hasilnya tepat. Jika tanggal tidak ada di bulan tujuan (contoh 31 Januari
  /// + 1 bulan), dipakai hari terakhir bulan tersebut (28/29 Februari).
  static DateTime hitungTanggalServisBerikutnya({
    required DateTime lastServiceDate,
    required int monthInterval,
  }) {
    final int totalBulan = lastServiceDate.month - 1 + monthInterval;
    final int tahun = lastServiceDate.year + totalBulan ~/ 12;
    final int bulan = totalBulan % 12 + 1;

    // Hari ke-0 dari bulan berikutnya = hari terakhir bulan tujuan.
    final int hariTerakhirBulan = DateTime(tahun, bulan + 1, 0).day;
    final int hari = lastServiceDate.day <= hariTerakhirBulan
        ? lastServiceDate.day
        : hariTerakhirBulan;

    return DateTime(tahun, bulan, hari);
  }

  /// Selisih hari dari [dari] (default: hari ini) sampai [target].
  ///
  /// Perhitungan memakai tanggal saja (jam diabaikan) supaya "besok" selalu
  /// bernilai 1 hari, bukan 0 hari karena selisih jam.
  static int hitungSisaHari({required DateTime target, DateTime? dari}) {
    final DateTime acuan = dari ?? DateTime.now();
    final DateTime awalAcuan = DateTime(acuan.year, acuan.month, acuan.day);
    final DateTime awalTarget = DateTime(target.year, target.month, target.day);
    return awalTarget.difference(awalAcuan).inDays;
  }

  /// Menentukan status dari sisa kilometer.
  static ServiceStatus statusDariSisaKm({
    required int sisaKm,
    required int kmInterval,
  }) {
    if (sisaKm < 0) return ServiceStatus.lewatBatas;

    final int batasKuning = max(
      batasMendekatiKmMinimal,
      (kmInterval * batasMendekatiRasio).round(),
    );
    return sisaKm <= batasKuning ? ServiceStatus.mendekati : ServiceStatus.aman;
  }

  /// Menentukan status dari sisa hari.
  ///
  /// [totalHari] adalah panjang satu interval dalam hari, dipakai untuk
  /// menghitung zona peringatan 20%.
  static ServiceStatus statusDariSisaHari({
    required int sisaHari,
    required int totalHari,
  }) {
    if (sisaHari < 0) return ServiceStatus.lewatBatas;

    final int batasKuning = max(
      batasMendekatiHariMinimal,
      (totalHari * batasMendekatiRasio).round(),
    );
    return sisaHari <= batasKuning ? ServiceStatus.mendekati : ServiceStatus.aman;
  }

  /// Menghitung status lengkap satu komponen.
  ///
  /// [catatanTerakhir] adalah servis terakhir untuk komponen tersebut pada
  /// kendaraan ini. Bila `null`, komponen dianggap belum punya data sehingga
  /// statusnya [ServiceStatus.belumAdaData] (tidak diberi warna hijau/merah
  /// karena tidak ada dasar perhitungan).
  static ComponentServiceStatus hitungKomponen({
    required ComponentInterval component,
    ServiceRecord? catatanTerakhir,
    required int currentKm,
    DateTime? sekarang,
  }) {
    final ServiceRecord? catatan = catatanTerakhir;

    if (catatan == null) {
      return ComponentServiceStatus(component: component);
    }

    // --- Patokan kilometer ---
    int? sisaKm;
    int? kmBerikutnya;
    ServiceStatus statusKm = ServiceStatus.belumAdaData;

    if (component.hasKmInterval) {
      kmBerikutnya = catatan.kmAtService + component.kmInterval!;
      sisaKm = hitungSisaKm(
        currentKm: currentKm,
        kmAtService: catatan.kmAtService,
        kmInterval: component.kmInterval!,
      );
      statusKm = statusDariSisaKm(sisaKm: sisaKm, kmInterval: component.kmInterval!);
    }

    // --- Patokan waktu ---
    DateTime? tanggalBerikutnya;
    int? sisaHari;
    ServiceStatus statusHari = ServiceStatus.belumAdaData;

    if (component.hasMonthInterval) {
      tanggalBerikutnya = hitungTanggalServisBerikutnya(
        lastServiceDate: catatan.serviceDate,
        monthInterval: component.monthInterval!,
      );
      final int totalHari = hitungSisaHari(
        target: tanggalBerikutnya,
        dari: catatan.serviceDate,
      );
      sisaHari = hitungSisaHari(target: tanggalBerikutnya, dari: sekarang);
      statusHari = statusDariSisaHari(sisaHari: sisaHari, totalHari: totalHari);
    }

    return ComponentServiceStatus(
      component: component,
      lastRecord: catatan,
      remainingKm: sisaKm,
      remainingDays: sisaHari,
      nextServiceDate: tanggalBerikutnya,
      nextServiceKm: kmBerikutnya,
      kmStatus: statusKm,
      dayStatus: statusHari,
    );
  }

  /// Menghitung status semua komponen sekaligus.
  ///
  /// [semuaCatatan] boleh berisi seluruh riwayat servis kendaraan; fungsi ini
  /// sendiri yang memilih catatan terbaru per komponen. Dengan begitu cukup
  /// satu query database untuk seluruh dashboard.
  ///
  /// Urutan hasil mengikuti `sortOrder` komponen (sudah diurutkan database).
  static List<ComponentServiceStatus> hitungSemua({
    required List<ComponentInterval> komponen,
    required List<ServiceRecord> semuaCatatan,
    required int currentKm,
    DateTime? sekarang,
  }) {
    // 1. Kelompokkan: componentKey → catatan servis terbaru.
    final Map<String, ServiceRecord> terakhir = <String, ServiceRecord>{};
    for (final ServiceRecord catatan in semuaCatatan) {
      final ServiceRecord? sebelumnya = terakhir[catatan.componentKey];
      if (sebelumnya == null || _lebihBaru(catatan, sebelumnya)) {
        terakhir[catatan.componentKey] = catatan;
      }
    }

    // 2. Hitung status tiap komponen aktif.
    return komponen
        .where((ComponentInterval item) => item.isActive)
        .map(
          (ComponentInterval item) => hitungKomponen(
            component: item,
            catatanTerakhir: terakhir[item.key],
            currentKm: currentKm,
            sekarang: sekarang,
          ),
        )
        .toList(growable: false);
  }

  /// Membandingkan dua catatan servis: mana yang lebih baru.
  ///
  /// Patokan utama tanggal servis, lalu kilometer (servis dengan KM lebih
  /// tinggi dianggap lebih baru), terakhir id.
  static bool _lebihBaru(ServiceRecord baru, ServiceRecord lama) {
    final int selisihTanggal = baru.serviceDate.compareTo(lama.serviceDate);
    if (selisihTanggal != 0) return selisihTanggal > 0;

    final int selisihKm = baru.kmAtService.compareTo(lama.kmAtService);
    if (selisihKm != 0) return selisihKm > 0;

    return (baru.id ?? 0) > (lama.id ?? 0);
  }
}
