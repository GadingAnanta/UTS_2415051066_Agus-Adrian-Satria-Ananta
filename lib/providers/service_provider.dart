import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/component_interval.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../utils/service_calculator.dart';

/// Sumber kebenaran untuk riwayat servis dan status jadwal servis
/// satu kendaraan.
///
/// Alur kerjanya:
/// 1. [loadForVehicle] mengambil daftar komponen + seluruh catatan servis
///    kendaraan tersebut, lalu menghitung status tiap komponen.
/// 2. UI hanya membaca hasil perhitungan yang sudah siap pakai
///    ([statuses]), sehingga widget tidak perlu tahu rumusnya.
/// 3. Setiap penambahan/penghapusan servis otomatis memuat ulang data,
///    jadi angka sisa KM/hari di dashboard selalu ikut berubah.
class ServiceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ComponentInterval> _components = <ComponentInterval>[];
  List<ServiceRecord> _records = <ServiceRecord>[];
  List<ComponentServiceStatus> _statuses = <ComponentServiceStatus>[];

  int? _vehicleId;
  int _currentKm = 0;
  bool _isLoading = false;
  String? _errorMessage;

  /// Daftar komponen aktif (terurut sesuai `sort_order`).
  List<ComponentInterval> get components =>
      List<ComponentInterval>.unmodifiable(_components);

  /// Seluruh catatan servis kendaraan, terbaru di atas.
  List<ServiceRecord> get records => List<ServiceRecord>.unmodifiable(_records);

  /// Status jadwal servis per komponen.
  List<ComponentServiceStatus> get statuses =>
      List<ComponentServiceStatus>.unmodifiable(_statuses);

  bool get isLoading => _isLoading;
  bool get hasRecords => _records.isNotEmpty;

  /// Pesan error terakhir, ditampilkan UI lewat SnackBar.
  String? get errorMessage => _errorMessage;

  /// Id kendaraan yang sedang dibuka (null bila belum ada).
  int? get vehicleId => _vehicleId;

  // --- Ringkasan jumlah komponen per status (dipakai di dashboard) ---

  int get jumlahAman =>
      _statuses.where((ComponentServiceStatus s) => s.status == ServiceStatus.aman).length;

  int get jumlahMendekati => _statuses
      .where((ComponentServiceStatus s) => s.status == ServiceStatus.mendekati)
      .length;

  int get jumlahLewatBatas => _statuses
      .where((ComponentServiceStatus s) => s.status == ServiceStatus.lewatBatas)
      .length;

  int get jumlahBelumAdaData => _statuses
      .where((ComponentServiceStatus s) => s.status == ServiceStatus.belumAdaData)
      .length;

  int get jumlahButuhPerhatian => jumlahMendekati + jumlahLewatBatas;

  // ---------------------------------------------------------------------------
  // MEMUAT DATA
  // ---------------------------------------------------------------------------

  /// Memuat komponen + riwayat servis untuk [kendaraan], lalu menghitung
  /// status tiap komponen berdasarkan `currentKm` kendaraan.
  Future<void> loadForVehicle(Vehicle kendaraan) async {
    final int? id = kendaraan.id;
    if (id == null) {
      _errorMessage = 'Kendaraan belum tersimpan, tidak bisa memuat servis.';
      notifyListeners();
      return;
    }

    _vehicleId = id;
    _currentKm = kendaraan.currentKm;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _components = await _db.getComponentIntervals(onlyActive: true);
      _records = await _db.getServiceRecordsByVehicle(id);
      _hitungUlangStatus();
    } catch (e) {
      _errorMessage = 'Gagal memuat data servis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memuat ulang data kendaraan yang sedang aktif.
  /// Dipakai setelah update KM dari halaman lain.
  Future<void> refresh() async {
    final int? id = _vehicleId;
    if (id == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // KM terbaru dibaca ulang dari database agar status ikut menyesuaikan.
      final Vehicle? kendaraan = await _db.getVehicleById(id);
      if (kendaraan == null) {
        _errorMessage = 'Kendaraan tidak ditemukan, mungkin sudah dihapus.';
      } else {
        _currentKm = kendaraan.currentKm;
        _components = await _db.getComponentIntervals(onlyActive: true);
        _records = await _db.getServiceRecordsByVehicle(id);
        _hitungUlangStatus();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat ulang data servis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menghitung status semua komponen dari data yang sudah ada di memori.
  void _hitungUlangStatus() {
    _statuses = ServiceCalculator.hitungSemua(
      komponen: _components,
      semuaCatatan: _records,
      currentKm: _currentKm,
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD CATATAN SERVIS
  // ---------------------------------------------------------------------------

  /// Menyimpan catatan servis: INSERT bila [catatan.id] null, UPDATE bila ada.
  /// Mengembalikan `true` bila berhasil.
  Future<bool> saveRecord(ServiceRecord catatan) async {
    _errorMessage = null;

    try {
      if (catatan.id == null) {
        await _db.insertServiceRecord(catatan);
      } else {
        final int terubah = await _db.updateServiceRecord(catatan);
        if (terubah == 0) {
          _errorMessage = 'Catatan servis tidak ditemukan, mungkin sudah dihapus.';
          notifyListeners();
          return false;
        }
      }

      await _muatUlangCatatan();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan catatan servis: $e';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus satu catatan servis.
  Future<bool> deleteRecord(int id) async {
    _errorMessage = null;

    try {
      final int terhapus = await _db.deleteServiceRecord(id);
      if (terhapus == 0) {
        _errorMessage = 'Catatan servis tidak ditemukan, mungkin sudah dihapus.';
        notifyListeners();
        return false;
      }

      await _muatUlangCatatan();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus catatan servis: $e';
      notifyListeners();
      return false;
    }
  }

  /// Memuat ulang catatan servis + hitung status (tanpa mengubah flag loading
  /// agar daftar tidak berkedip).
  Future<void> _muatUlangCatatan() async {
    final int? id = _vehicleId;
    if (id != null) {
      _records = await _db.getServiceRecordsByVehicle(id);
      _hitungUlangStatus();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // HELPER UNTUK UI
  // ---------------------------------------------------------------------------

  /// Status satu komponen berdasarkan `key`. `null` bila tidak ditemukan.
  ComponentServiceStatus? statusFor(String componentKey) {
    for (final ComponentServiceStatus item in _statuses) {
      if (item.component.key == componentKey) return item;
    }
    return null;
  }

  /// Nama komponen dari `key`. Dipakai daftar riwayat servis supaya tidak
  /// menampilkan kunci mentah seperti `oli_mesin`.
  String componentName(String componentKey) {
    for (final ComponentInterval item in _components) {
      if (item.key == componentKey) return item.name;
    }
    return componentKey;
  }

  /// Ikon komponen dari `key`.
  ComponentInterval? componentByKey(String componentKey) {
    for (final ComponentInterval item in _components) {
      if (item.key == componentKey) return item;
    }
    return null;
  }

  /// Seluruh catatan servis milik satu komponen, terbaru di atas.
  List<ServiceRecord> recordsForComponent(String componentKey) {
    return _records
        .where((ServiceRecord catatan) => catatan.componentKey == componentKey)
        .toList(growable: false);
  }

  /// Kilometer tertinggi yang pernah tercatat untuk satu komponen.
  ///
  /// Dipakai form servis untuk memastikan KM servis baru tidak lebih kecil
  /// dari servis sebelumnya pada komponen yang sama.
  int? lastKmForComponent(String componentKey) {
    final List<ServiceRecord> daftar = recordsForComponent(componentKey);
    if (daftar.isEmpty) return null;

    int tertinggi = daftar.first.kmAtService;
    for (final ServiceRecord catatan in daftar) {
      if (catatan.kmAtService > tertinggi) tertinggi = catatan.kmAtService;
    }
    return tertinggi;
  }

  /// Bersihkan pesan error setelah ditampilkan di SnackBar.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
