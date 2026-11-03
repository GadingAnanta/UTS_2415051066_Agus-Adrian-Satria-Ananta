import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/tax_reminder.dart';
import '../models/vehicle.dart';
import '../utils/formatters.dart';
import '../utils/service_calculator.dart';

/// Layanan notifikasi lokal aplikasi.
///
/// Memakai `flutter_local_notifications` (menampilkan & menjadwalkan
/// notifikasi) dan `timezone` (supaya jadwal memakai jam lokal, bukan UTC).
///
/// Tiga jenis notifikasi yang dipakai aplikasi:
/// 1. **Pengingat servis berbasis waktu** — dijadwalkan otomatis dari tanggal
///    servis berikutnya tiap komponen (lihat [syncServiceReminders]).
/// 2. **Peringatan berbasis kilometer** — ditampilkan seketika saat KM
///    kendaraan diperbarui dan ada komponen yang mulai mendekati/lewat batas
///    (lihat [showKmWarning]).
/// 3. **Pengingat pajak/STNK** — H-30 dan H-7 sebelum jatuh tempo
///    (lihat [syncTaxReminders]).
///
/// Di web semua method tidak melakukan apa pun, karena notifikasi lokal tidak
/// tersedia di browser dan web hanya dipakai untuk pratinjau.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Zona waktu yang dipakai untuk menghitung jadwal notifikasi.
  ///
  /// Aplikasi ini tidak menambah paket `flutter_timezone`, jadi zona waktu
  /// disetel manual ke WIB. Untuk WITA/WIT cukup ganti nilainya menjadi
  /// `Asia/Makassar` atau `Asia/Jayapura`.
  static const String zonaWaktu = 'Asia/Jakarta';

  /// Jam pengiriman notifikasi (09.00 pagi) supaya tidak mengganggu malam.
  static const int jamKirim = 9;

  // Id kanal notifikasi Android (dibuat sekali saat init).
  static const String kanalServis = 'kanal_servis';
  static const String kanalPajak = 'kanal_pajak';

  bool _siap = false;

  /// True bila notifikasi siap dipakai (selalu false di web).
  bool get siap => _siap;

  // ---------------------------------------------------------------------------
  // INISIALISASI
  // ---------------------------------------------------------------------------

  /// Menyiapkan plugin, zona waktu, dan kanal notifikasi Android.
  ///
  /// Dipanggil sekali di `main()` sebelum `runApp`.
  Future<void> init() async {
    if (kIsWeb) return;

    // 1. Data zona waktu + zona lokal.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(zonaWaktu));

    // 2. Pengaturan awal per platform.
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Izin iOS sengaja tidak diminta otomatis; diminta lewat mintaIzin().
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _saatNotifikasiDiketuk,
    );

    // 3. Kanal notifikasi Android (wajib untuk Android 8+).
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kanalServis,
        'Pengingat Servis',
        description: 'Pengingat jadwal servis komponen kendaraan.',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kanalPajak,
        'Pengingat Pajak & STNK',
        description: 'Pengingat jatuh tempo pajak tahunan dan STNK.',
        importance: Importance.high,
      ),
    );

    _siap = true;
  }

  /// Meminta izin notifikasi (wajib di Android 13+ / API 33+).
  ///
  /// Mengembalikan `true` bila izin diberikan. Di Android versi lama method ini
  /// otomatis mengembalikan `true` karena izin tidak diperlukan.
  Future<bool> mintaIzin() async {
    if (kIsWeb) return false;

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? diizinkan = await androidPlugin?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final bool? izinIos = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return diizinkan ?? izinIos ?? true;
  }

  /// Cek apakah pengguna masih mengizinkan notifikasi.
  Future<bool> izinAktif() async {
    if (kIsWeb) return false;
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? aktif = await androidPlugin?.areNotificationsEnabled();
    return aktif ?? true;
  }

  /// Callback saat notifikasi diketuk pengguna.
  ///
  /// Untuk saat ini hanya dicatat; navigasi ke halaman terkait bisa ditambah
  /// dengan membaca `response.payload` (contoh: `servis:oli_mesin`).
  void _saatNotifikasiDiketuk(NotificationResponse response) {
    debugPrint('Notifikasi diketuk, payload: ${response.payload}');
  }

  // ---------------------------------------------------------------------------
  // 1. PENGINGAT SERVIS BERBASIS WAKTU
  // ---------------------------------------------------------------------------

  /// Menyusun ulang jadwal pengingat servis untuk satu kendaraan.
  ///
  /// Dipanggil setiap dashboard kendaraan dibuka dan setiap kali ada catatan
  /// servis baru. Jadwal lama dibatalkan lebih dulu agar tidak menumpuk.
  ///
  /// Pengingat dikirim H-7 sebelum tanggal servis berikutnya. Bila tanggal
  /// servis berikutnya kurang dari 7 hari lagi, notifikasi dikirim besok pagi.
  Future<void> syncServiceReminders({
    required Vehicle vehicle,
    required List<ComponentServiceStatus> statuses,
  }) async {
    if (!_siap || vehicle.id == null) return;

    final int vehicleId = vehicle.id!;

    // 1. Batalkan jadwal lama kendaraan ini.
    for (int urutan = 1; urutan <= 20; urutan++) {
      await _plugin.cancel(id: _idServis(vehicleId, urutan));
    }

    // 2. Jadwalkan ulang untuk komponen yang punya patokan waktu.
    for (final ComponentServiceStatus item in statuses) {
      final DateTime? jatuhTempo = item.nextServiceDate;
      if (jatuhTempo == null) continue;

      final DateTime? waktuKirim = _waktuPengingat(jatuhTempo);
      if (waktuKirim == null) continue;

      await _plugin.zonedSchedule(
        id: _idServis(vehicleId, item.component.sortOrder),
        title: 'Waktunya servis ${item.component.name}',
        body:
            '${vehicle.displayName} (${vehicle.plateNumber}) dijadwalkan servis '
            'pada ${formatTanggalPendek(jatuhTempo)}.',
        scheduledDate: _keZona(waktuKirim),
        notificationDetails: _detailServis,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'servis:${item.component.key}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2. PERINGATAN BERBASIS KILOMETER
  // ---------------------------------------------------------------------------

  /// Menampilkan notifikasi seketika saat KM kendaraan diperbarui.
  ///
  /// [perluPerhatian] berisi komponen berstatus mendekati/lewat batas.
  /// Mengembalikan `true` bila notifikasi benar-benar ditampilkan.
  Future<bool> showKmWarning({
    required Vehicle vehicle,
    required List<ComponentServiceStatus> perluPerhatian,
  }) async {
    if (!_siap || perluPerhatian.isEmpty || vehicle.id == null) return false;

    final String rincian = perluPerhatian
        .map((ComponentServiceStatus item) => '• ${_ringkasStatus(item)}')
        .join('\n');

    await _plugin.show(
      id: _idKm(vehicle.id!),
      title: '${perluPerhatian.length} komponen perlu servis',
      body: '${vehicle.displayName} (${vehicle.plateNumber})\n$rincian',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          kanalServis,
          'Pengingat Servis',
          channelDescription: 'Pengingat jadwal servis komponen kendaraan.',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            '${vehicle.displayName} (${vehicle.plateNumber})\n$rincian',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'km:${vehicle.id}',
    );

    return true;
  }

  /// Contoh keluaran: `Oli Mesin: sisa 300 km` atau `Kampas Rem: lewat 1.200 km`.
  String _ringkasStatus(ComponentServiceStatus item) {
    final List<String> bagian = <String>[];

    final int? sisaKm = item.remainingKm;
    if (sisaKm != null) {
      bagian.add(
        sisaKm < 0 ? 'lewat ${formatKm(sisaKm.abs())}' : 'sisa ${formatKm(sisaKm)}',
      );
    }

    final int? sisaHari = item.remainingDays;
    if (sisaHari != null) {
      bagian.add(sisaHari < 0 ? 'lewat ${sisaHari.abs()} hari' : '$sisaHari hari lagi');
    }

    return '${item.component.name}: ${bagian.join(', ')}';
  }

  // ---------------------------------------------------------------------------
  // 3. PENGINGAT PAJAK / STNK
  // ---------------------------------------------------------------------------

  /// Menyusun ulang jadwal pengingat pajak & STNK untuk satu kendaraan.
  ///
  /// Tanggal jatuh tempo sekarang ikut tersimpan di tabel `vehicles`
  /// (`tax_due_date` & `stnk_due_date`), jadi cukup satu objek [Vehicle].
  /// H-30 dan H-7 selalu dijadwalkan; jadwal yang tanggalnya sudah lewat
  /// dilewati (tidak ada gunanya mengingatkan masa lalu).
  Future<void> syncTaxReminders(Vehicle vehicle) async {
    if (!_siap || vehicle.id == null) return;

    final int vehicleId = vehicle.id!;

    // Bersihkan jadwal lama: 2 jenis dokumen × 2 pengingat.
    for (final TaxType tipe in TaxType.values) {
      for (final int h in <int>[30, 7]) {
        await _plugin.cancel(id: _idPajak(vehicleId, tipe.index, h));
      }
    }

    for (final TaxReminder reminder in taxRemindersFor(vehicle)) {
      await _jadwalkanPajak(vehicle: vehicle, reminder: reminder, hariSebelum: 30);
      await _jadwalkanPajak(vehicle: vehicle, reminder: reminder, hariSebelum: 7);
    }
  }

  /// Membentuk daftar pengingat dari tanggal jatuh tempo yang tersimpan
  /// di [vehicle]. Tanggal yang kosong tidak menghasilkan pengingat.
  static List<TaxReminder> taxRemindersFor(Vehicle vehicle) {
    return <TaxReminder>[
      if (vehicle.taxDueDate != null)
        TaxReminder(
          type: TaxType.pajakTahunan,
          dueDate: vehicle.taxDueDate!,
          vehicleId: vehicle.id,
        ),
      if (vehicle.stnkDueDate != null)
        TaxReminder(
          type: TaxType.stnkLimaTahunan,
          dueDate: vehicle.stnkDueDate!,
          vehicleId: vehicle.id,
        ),
    ];
  }

  Future<void> _jadwalkanPajak({
    required Vehicle vehicle,
    required TaxReminder reminder,
    required int hariSebelum,
  }) async {
    final DateTime jatuhTempo = DateTime(
      reminder.dueDate.year,
      reminder.dueDate.month,
      reminder.dueDate.day,
      jamKirim,
    );
    final DateTime waktuKirim = jatuhTempo.subtract(Duration(days: hariSebelum));

    // Lewati bila waktunya sudah lewat.
    if (!waktuKirim.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _idPajak(vehicle.id!, reminder.type.index, hariSebelum),
      title: 'H-$hariSebelum ${reminder.type.label}',
      body:
          '${vehicle.displayName} (${vehicle.plateNumber}) — jatuh tempo '
          '${formatTanggal(reminder.dueDate)}.',
      scheduledDate: _keZona(waktuKirim),
      notificationDetails: _detailPajak,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'pajak:${reminder.type.value}',
    );
  }

  /// Membatalkan seluruh notifikasi milik satu kendaraan.
  /// Dipakai saat kendaraan dihapus.
  Future<void> cancelForVehicle(int vehicleId) async {
    if (!_siap) return;

    for (int urutan = 1; urutan <= 20; urutan++) {
      await _plugin.cancel(id: _idServis(vehicleId, urutan));
    }
    for (final TaxType tipe in TaxType.values) {
      for (final int h in <int>[30, 7]) {
        await _plugin.cancel(id: _idPajak(vehicleId, tipe.index, h));
      }
    }
    await _plugin.cancel(id: _idKm(vehicleId));
  }

  /// Daftar notifikasi yang masih terjadwal (berguna saat demo/pengujian).
  Future<List<PendingNotificationRequest>> daftarTerjadwal() async {
    if (!_siap) return <PendingNotificationRequest>[];
    return _plugin.pendingNotificationRequests();
  }

  // ---------------------------------------------------------------------------
  // DETAIL & ID
  // ---------------------------------------------------------------------------

  static const NotificationDetails _detailServis = NotificationDetails(
    android: AndroidNotificationDetails(
      kanalServis,
      'Pengingat Servis',
      channelDescription: 'Pengingat jadwal servis komponen kendaraan.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _detailPajak = NotificationDetails(
    android: AndroidNotificationDetails(
      kanalPajak,
      'Pengingat Pajak & STNK',
      channelDescription: 'Pengingat jatuh tempo pajak tahunan dan STNK.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Id notifikasi dibuat deterministik supaya jadwal lama bisa dibatalkan
  /// tanpa perlu menyimpan daftar id di database.
  ///
  /// - Servis : 1.000.000 + id kendaraan × 100 + urutan komponen (1..20)
  /// - Pajak  : 2.000.000 + id kendaraan × 100 + jenis × 10 + (H-30 → 1, H-7 → 2)
  /// - KM     : 3.000.000 + id kendaraan
  static int _idServis(int vehicleId, int urutan) =>
      1000000 + vehicleId * 100 + urutan;

  static int _idPajak(int vehicleId, int tipeIndex, int hariSebelum) =>
      2000000 + vehicleId * 100 + tipeIndex * 10 + (hariSebelum == 30 ? 1 : 2);

  static int _idKm(int vehicleId) => 3000000 + vehicleId;

  /// Mengubah `DateTime` (jam dinding lokal) menjadi waktu di zona aplikasi.
  ///
  /// Dibuat dari komponen tahun/bulan/hari/jam, bukan dari titik waktu, supaya
  /// notifikasi tetap dikirim pukul 09.00 WIB meskipun zona waktu HP berbeda.
  static tz.TZDateTime _keZona(DateTime waktu) {
    return tz.TZDateTime(
      tz.local,
      waktu.year,
      waktu.month,
      waktu.day,
      waktu.hour,
      waktu.minute,
    );
  }

  /// Menghitung waktu kirim pengingat servis.
  ///
  /// - Normal: 7 hari sebelum tanggal servis, jam 09.00.
  /// - Bila H-7 sudah lewat tetapi servis belum lewat: besok jam 09.00.
  /// - Bila tanggal servis sudah lewat: `null` (tidak dijadwalkan).
  DateTime? _waktuPengingat(DateTime tanggalServis) {
    final DateTime sekarang = DateTime.now();
    final DateTime jatuhTempo = DateTime(
      tanggalServis.year,
      tanggalServis.month,
      tanggalServis.day,
      jamKirim,
    );

    final DateTime h7 = jatuhTempo.subtract(const Duration(days: 7));
    if (h7.isAfter(sekarang)) return h7;

    if (jatuhTempo.isAfter(sekarang)) {
      return DateTime(sekarang.year, sekarang.month, sekarang.day + 1, jamKirim);
    }

    return null;
  }
}
