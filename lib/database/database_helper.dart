import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/component_interval.dart';
import '../models/service_record.dart';
import '../models/tax_reminder.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';

/// Satu-satunya pintu masuk ke database SQLite.
///
/// Dibuat sebagai singleton (`DatabaseHelper.instance`) supaya koneksi database
/// hanya dibuka sekali dan dipakai bersama oleh semua provider.
///
/// Pola pemakaian:
/// ```dart
/// final DatabaseHelper db = DatabaseHelper.instance;
/// final List<Vehicle> kendaraan = await db.getVehicles();
/// ```
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _namaDatabase = 'bengkel_digital.db';
  static const int _versiDatabase = 1;

  // Nama tabel dibuat konstanta agar tidak salah ketik.
  static const String tabelKendaraan = 'vehicles';
  static const String tabelServis = 'service_records';
  static const String tabelKomponen = 'component_intervals';
  static const String tabelPajak = 'tax_reminders';

  /// Disimpan sebagai Future (bukan Database) supaya dua pemanggilan bersamaan
  /// tidak membuka database dua kali.
  Future<Database>? _futureDatabase;

  Future<Database> get database => _futureDatabase ??= _bukaDatabase();

  // ---------------------------------------------------------------------------
  // SETUP DATABASE
  // ---------------------------------------------------------------------------

  Future<Database> _bukaDatabase() async {
    final String folder = await getDatabasesPath();
    final String lokasi = p.join(folder, _namaDatabase);

    return openDatabase(
      lokasi,
      version: _versiDatabase,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// `foreign_keys` harus diaktifkan manual di SQLite, kalau tidak aturan
  /// ON DELETE CASCADE tidak berjalan.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel komponen dibuat lebih dulu karena dirujuk oleh tabel servis.
    await db.execute('''
      CREATE TABLE $tabelKomponen (
        key TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        km_interval INTEGER,
        month_interval INTEGER,
        icon_key TEXT NOT NULL DEFAULT 'lainnya',
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Tabel kendaraan.
    await db.execute('''
      CREATE TABLE $tabelKendaraan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        plate_number TEXT NOT NULL,
        current_km INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel catatan servis.
    await db.execute('''
      CREATE TABLE $tabelServis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        component_key TEXT NOT NULL,
        service_date TEXT NOT NULL,
        km_at_service INTEGER NOT NULL,
        cost INTEGER NOT NULL DEFAULT 0,
        workshop_name TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES $tabelKendaraan (id) ON DELETE CASCADE,
        FOREIGN KEY (component_key) REFERENCES $tabelKomponen (key)
      )
    ''');

    // 4. Tabel pengingat pajak / STNK.
    await db.execute('''
      CREATE TABLE $tabelPajak (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        due_date TEXT NOT NULL,
        notify_h30 INTEGER NOT NULL DEFAULT 1,
        notify_h7 INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (vehicle_id) REFERENCES $tabelKendaraan (id) ON DELETE CASCADE,
        UNIQUE (vehicle_id, type)
      )
    ''');

    // 5. Index supaya query per kendaraan tetap cepat saat data banyak.
    await db.execute('CREATE INDEX idx_servis_kendaraan ON $tabelServis (vehicle_id)');
    await db.execute('CREATE INDEX idx_servis_tanggal ON $tabelServis (service_date)');
    await db.execute('CREATE INDEX idx_pajak_kendaraan ON $tabelPajak (vehicle_id)');

    // 6. Isi data awal komponen sesuai spesifikasi tugas.
    final Batch batch = db.batch();
    for (final ComponentInterval komponen in defaultComponentIntervals) {
      batch.insert(tabelKomponen, komponen.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Menutup koneksi. Berguna saat pengujian atau reset data.
  Future<void> close() async {
    final Future<Database>? future = _futureDatabase;
    _futureDatabase = null;
    if (future != null) {
      final Database db = await future;
      await db.close();
    }
  }

  /// Menghapus file database (semua data hilang). Dipakai untuk reset data.
  Future<void> deleteDatabaseFile() async {
    await close();
    final String folder = await getDatabasesPath();
    await deleteDatabase(p.join(folder, _namaDatabase));
  }

  // ---------------------------------------------------------------------------
  // CRUD: KENDARAAN (vehicles)
  // ---------------------------------------------------------------------------

  Future<int> insertVehicle(Vehicle kendaraan) async {
    final Database db = await database;
    return db.insert(tabelKendaraan, kendaraan.toMap());
  }

  Future<List<Vehicle>> getVehicles() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelKendaraan,
      orderBy: 'created_at ASC',
    );
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelKendaraan,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Vehicle.fromMap(rows.first);
  }

  /// Mengembalikan jumlah baris yang terubah (0 = id tidak ditemukan).
  Future<int> updateVehicle(Vehicle kendaraan) async {
    if (kendaraan.id == null) {
      throw ArgumentError('updateVehicle butuh kendaraan dengan id tidak null');
    }
    final Database db = await database;
    return db.update(
      tabelKendaraan,
      kendaraan.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[kendaraan.id],
    );
  }

  /// Menghapus kendaraan beserta seluruh servis & pengingat pajaknya
  /// (ON DELETE CASCADE).
  Future<int> deleteVehicle(int id) async {
    final Database db = await database;
    return db.delete(tabelKendaraan, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Hanya memperbarui kolom kilometer (dipakai fitur "Update KM").
  Future<int> updateVehicleKm(int vehicleId, int kmBaru) async {
    final Database db = await database;
    return db.update(
      tabelKendaraan,
      <String, Object?>{'current_km': kmBaru},
      where: 'id = ?',
      whereArgs: <Object?>[vehicleId],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: CATATAN SERVIS (service_records)
  // ---------------------------------------------------------------------------

  Future<int> insertServiceRecord(ServiceRecord catatan) async {
    final Database db = await database;
    return db.insert(tabelServis, catatan.toMap());
  }

  Future<int> updateServiceRecord(ServiceRecord catatan) async {
    if (catatan.id == null) {
      throw ArgumentError('updateServiceRecord butuh catatan dengan id tidak null');
    }
    final Database db = await database;
    return db.update(
      tabelServis,
      catatan.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[catatan.id],
    );
  }

  Future<int> deleteServiceRecord(int id) async {
    final Database db = await database;
    return db.delete(tabelServis, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Semua catatan servis milik satu kendaraan, terbaru di atas.
  /// Jika [componentKey] diisi, hasilnya difilter untuk komponen tersebut.
  Future<List<ServiceRecord>> getServiceRecordsByVehicle(
    int vehicleId, {
    String? componentKey,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelServis,
      where: componentKey == null ? 'vehicle_id = ?' : 'vehicle_id = ? AND component_key = ?',
      whereArgs: componentKey == null
          ? <Object?>[vehicleId]
          : <Object?>[vehicleId, componentKey],
      orderBy: 'service_date DESC, id DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  /// Seluruh catatan servis dari semua kendaraan (dipakai grafik pengeluaran).
  Future<List<ServiceRecord>> getAllServiceRecords() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelServis,
      orderBy: 'service_date DESC, id DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  /// Servis terakhir untuk satu komponen pada satu kendaraan.
  /// `null` berarti komponen tersebut belum pernah diservis.
  Future<ServiceRecord?> getLastServiceRecord(
    int vehicleId,
    String componentKey,
  ) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelServis,
      where: 'vehicle_id = ? AND component_key = ?',
      whereArgs: <Object?>[vehicleId, componentKey],
      orderBy: 'service_date DESC, km_at_service DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceRecord.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------------
  // CRUD: INTERVAL KOMPONEN (component_intervals)
  // ---------------------------------------------------------------------------

  Future<List<ComponentInterval>> getComponentIntervals({bool onlyActive = false}) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelKomponen,
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'sort_order ASC',
    );
    return rows.map(ComponentInterval.fromMap).toList();
  }

  Future<ComponentInterval?> getComponentIntervalByKey(String key) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelKomponen,
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ComponentInterval.fromMap(rows.first);
  }

  /// Menambah komponen baru buatan pengguna.
  Future<int> insertComponentInterval(ComponentInterval komponen) async {
    final Database db = await database;
    return db.insert(tabelKomponen, komponen.toMap());
  }

  /// Menyimpan perubahan interval (KM / bulan / status aktif) sebuah komponen.
  Future<int> updateComponentInterval(ComponentInterval komponen) async {
    final Database db = await database;
    return db.update(
      tabelKomponen,
      komponen.toMap(),
      where: 'key = ?',
      whereArgs: <Object?>[komponen.key],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: PENGINGAT PAJAK (tax_reminders)
  // ---------------------------------------------------------------------------

  /// Simpan atau perbarui pengingat pajak.
  ///
  /// Tabel punya constraint UNIQUE(vehicle_id, type), jadi kalau baris untuk
  /// kombinasi itu sudah ada kita lakukan UPDATE, kalau belum INSERT.
  Future<int> saveTaxReminder(TaxReminder reminder) async {
    final Database db = await database;
    final List<Map<String, Object?>> existing = await db.query(
      tabelPajak,
      columns: <String>['id'],
      where: 'vehicle_id = ? AND type = ?',
      whereArgs: <Object?>[reminder.vehicleId, reminder.type.value],
      limit: 1,
    );

    if (existing.isEmpty) {
      return db.insert(tabelPajak, reminder.toMap());
    }

    final int id = existing.first['id'] as int;
    return db.update(
      tabelPajak,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<TaxReminder>> getTaxRemindersByVehicle(int vehicleId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelPajak,
      where: 'vehicle_id = ?',
      whereArgs: <Object?>[vehicleId],
      orderBy: 'due_date ASC',
    );
    return rows.map(TaxReminder.fromMap).toList();
  }

  /// Semua pengingat pajak (dipakai untuk menjadwalkan notifikasi).
  Future<List<TaxReminder>> getAllTaxReminders() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tabelPajak,
      orderBy: 'due_date ASC',
    );
    return rows.map(TaxReminder.fromMap).toList();
  }

  Future<int> deleteTaxReminder(int id) async {
    final Database db = await database;
    return db.delete(tabelPajak, where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
