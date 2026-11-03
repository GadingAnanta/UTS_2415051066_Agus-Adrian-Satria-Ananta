import 'package:flutter/foundation.dart';

import '../models/component_interval.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../repositories/service_record_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/service_calculator.dart';
import 'load_state.dart';

/// Sumber kebenaran untuk riwayat servis dan status jadwal servis
/// satu kendaraan.
///
/// Alur lapisannya: **Screen → Provider → Repository → Supabase**.
/// 1. [loadForVehicle] mengambil seluruh catatan servis kendaraan dari
///    [ServiceRecordRepository], lalu menghitung status tiap komponen
///    (daftar komponen kini konfigurasi statis di aplikasi).
/// 2. UI hanya membaca hasil perhitungan yang sudah siap pakai ([statuses]),
///    sehingga widget tidak perlu tahu rumusnya.
/// 3. Setiap penambahan/penghapusan servis otomatis memuat ulang data,
///    jadi angka sisa KM/hari di dashboard selalu ikut berubah.
class ServiceProvider extends ChangeNotifier {
  ServiceProvider({
    ServiceRecordRepository? repository,
    VehicleRepository? vehicleRepository,
  })  : _repository = repository ?? ServiceRecordRepository(),
        _vehicleRepository = vehicleRepository ?? VehicleRepository();

  final ServiceRecordRepository _repository;
  final VehicleRepository _vehicleRepository;

  final List<ComponentInterval> _components =
      List<ComponentInterval>.of(defaultComponentIntervals);
  List<ServiceRecord> _records = <ServiceRecord>[];
  List<ComponentServiceStatus> _statuses = <ComponentServiceStatus>[];

  int? _vehicleId;
  int _currentKm = 0;
  LoadState _state = LoadState.idle;
  String? _errorMessage;

  /// Daftar komponen aktif (terurut sesuai `sortOrder`).
  List<ComponentInterval> get components =>
      List<ComponentInterval>.unmodifiable(_components);

  /// Seluruh catatan servis kendaraan, terbaru di atas.
  List<ServiceRecord> get records => List<ServiceRecord>.unmodifiable(_records);

  /// Status jadwal servis per komponen.
  List<ComponentServiceStatus> get statuses =>
      List<ComponentServiceStatus>.unmodifiable(_statuses);

  /// Status pemuatan: idle / loading / success / error.
  LoadState get state => _state;

  bool get isLoading => _state == LoadState.loading;
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

  /// Memuat riwayat servis untuk [kendaraan], lalu menghitung status tiap
  /// komponen berdasarkan `currentKm` kendaraan.
  Future<void> loadForVehicle(Vehicle kendaraan) async {
    final int? id = kendaraan.id;
    if (id == null) {
      _errorMessage = 'Kendaraan belum tersimpan, tidak bisa memuat servis.';
      _state = LoadState.error;
      notifyListeners();
      return;
    }

    _vehicleId = id;
    _currentKm = kendaraan.currentKm;
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _repository.fetchByVehicle(id);
      _hitungUlangStatus();
      _state = LoadState.success;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal memuat data servis.';
      _records = <ServiceRecord>[];
      _statuses = <ComponentServiceStatus>[];
      _state = LoadState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Memuat ulang data kendaraan yang sedang aktif.
  /// Dipakai setelah update KM dari halaman lain.
  Future<void> refresh() async {
    final int? id = _vehicleId;
    if (id == null) return;

    _state = LoadState.loading;
    notifyListeners();

    try {
      // KM terbaru dibaca ulang dari Supabase agar status ikut menyesuaikan.
      final Vehicle? kendaraan = await _vehicleRepository.fetchById(id);
      if (kendaraan == null) {
        _errorMessage = 'Kendaraan tidak ditemukan, mungkin sudah dihapus.';
        _state = LoadState.error;
      } else {
        _currentKm = kendaraan.currentKm;
        _records = await _repository.fetchByVehicle(id);
        _hitungUlangStatus();
        _state = LoadState.success;
      }
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal memuat ulang data servis.';
      _state = LoadState.error;
    } finally {
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
        await _repository.create(catatan);
      } else {
        await _repository.update(catatan);
      }

      await _muatUlangCatatan();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal menyimpan catatan servis.';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus satu catatan servis.
  Future<bool> deleteRecord(int id) async {
    _errorMessage = null;

    try {
      await _repository.delete(id);
      await _muatUlangCatatan();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal menghapus catatan servis.';
      notifyListeners();
      return false;
    }
  }

  /// Memuat ulang catatan servis + hitung status (tanpa mengubah flag loading
  /// agar daftar tidak berkedip).
  Future<void> _muatUlangCatatan() async {
    final int? id = _vehicleId;
    if (id != null) {
      _records = await _repository.fetchByVehicle(id);
      _hitungUlangStatus();
      _state = LoadState.success;
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
