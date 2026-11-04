import 'package:flutter/foundation.dart';

import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/app_exception.dart';
import '../utils/vehicle_filter.dart';
import 'load_state.dart';

/// Sumber kebenaran (single source of truth) untuk data kendaraan.
///
/// Alur lapisannya: **Screen → Provider → Repository → Supabase**.
/// Screen tidak pernah memanggil Supabase; provider memakai
/// [VehicleRepository], lalu memberi tahu widget lewat `notifyListeners()`.
class VehicleProvider extends ChangeNotifier {
  VehicleProvider({VehicleRepository? repository})
      : _repository = repository ?? VehicleRepository();

  final VehicleRepository _repository;

  List<Vehicle> _vehicles = <Vehicle>[];
  LoadState _state = LoadState.idle;
  String? _errorMessage;

  /// State bersama (shared state): kendaraan yang sedang dipilih/dibuka.
  /// Dipakai dashboard & daftar supaya keduanya menunjuk kendaraan yang sama.
  int? _selectedVehicleId;

  /// State bersama (shared state): kata kunci pencarian pada daftar.
  String _query = '';

  /// State bersama (shared state): filter aktif pada daftar.
  VehicleFilter _filter = VehicleFilter.semua;

  /// Daftar kendaraan (tidak bisa diubah dari luar).
  List<Vehicle> get vehicles => List<Vehicle>.unmodifiable(_vehicles);

  /// Status pemuatan: idle / loading / success / error.
  LoadState get state => _state;

  bool get isLoading => _state == LoadState.loading;
  bool get isEmpty => _vehicles.isEmpty;

  /// Pesan error terakhir, ditampilkan UI lewat SnackBar.
  String? get errorMessage => _errorMessage;

  /// Id kendaraan yang sedang dipilih (state bersama antar halaman).
  int? get selectedVehicleId => _selectedVehicleId;

  /// Objek kendaraan yang sedang dipilih, `null` bila belum ada.
  Vehicle? get selectedVehicle {
    final int? id = _selectedVehicleId;
    return id == null ? null : vehicleById(id);
  }

  /// Menandai kendaraan sebagai "sedang dibuka".
  void selectVehicle(int? id) {
    if (_selectedVehicleId == id) return;
    _selectedVehicleId = id;
    notifyListeners();
  }

  // --- State bersama: pencarian & filter ---

  /// Kata kunci pencarian yang sedang aktif (huruf asli dari pengguna).
  String get query => _query;

  /// Filter yang sedang aktif.
  VehicleFilter get filter => _filter;

  /// True bila pengguna sedang memakai pencarian atau filter.
  bool get hasActiveFilter =>
      _query.trim().isNotEmpty || _filter != VehicleFilter.semua;

  /// Daftar kendaraan setelah disaring pencarian + filter.
  ///
  /// Halaman daftar memakai getter ini, sehingga state filter tetap hidup
  /// meskipun halaman dibuka ulang (shared state di provider).
  List<Vehicle> get filteredVehicles =>
      filterVehicles(_vehicles, query: _query, filter: _filter);

  /// Mengubah kata kunci pencarian lalu memberi tahu UI.
  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// Mengubah filter aktif lalu memberi tahu UI.
  void setFilter(VehicleFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// Mengembalikan pencarian & filter ke keadaan awal.
  void resetFilter() {
    if (!hasActiveFilter) return;
    _query = '';
    _filter = VehicleFilter.semua;
    notifyListeners();
  }

  /// Ambil ulang seluruh data kendaraan dari Supabase.
  Future<void> loadVehicles() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await _repository.fetchAll(
        userId: SupabaseService.instance.demoUserId,
      );

      // Kalau kendaraan terpilih sudah tidak ada, lepaskan pilihannya.
      final int? dipilih = _selectedVehicleId;
      if (dipilih != null && vehicleById(dipilih) == null) {
        _selectedVehicleId = _vehicles.isEmpty ? null : _vehicles.first.id;
      } else if (dipilih == null && _vehicles.isNotEmpty) {
        _selectedVehicleId = _vehicles.first.id;
      }

      _state = LoadState.success;

      // Data berasal dari Supabase, jadi jadwal pengingat pajak/STNK disusun
      // ulang setiap kali daftar dimuat (misalnya setelah aplikasi dibuka).
      await _sinkronPengingatPajak();
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal memuat daftar kendaraan.';
      _state = LoadState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Menyusun ulang pengingat pajak & STNK untuk seluruh kendaraan.
  ///
  /// Kegagalan penjadwalan notifikasi tidak boleh menggagalkan pemuatan data,
  /// jadi error-nya hanya dicatat lewat [debugPrint].
  Future<void> _sinkronPengingatPajak() async {
    for (final Vehicle kendaraan in _vehicles) {
      try {
        await NotificationService.instance.syncTaxReminders(kendaraan);
      } catch (e) {
        debugPrint('Gagal menyinkronkan pengingat pajak: $e');
      }
    }
  }

  /// Simpan kendaraan: INSERT jika [vehicle.id] null, UPDATE jika sudah ada.
  /// Mengembalikan `true` bila berhasil.
  Future<bool> saveVehicle(Vehicle vehicle) async {
    _errorMessage = null;

    try {
      final Vehicle tersimpan = vehicle.id == null
          ? await _repository.create(vehicle)
          : await _repository.update(vehicle);

      _gabungkan(tersimpan);

      // Sinkronkan ulang pengingat pajak karena tanggalnya mungkin berubah.
      await NotificationService.instance.syncTaxReminders(tersimpan);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal menyimpan kendaraan.';
      notifyListeners();
      return false;
    }
  }

  /// Hapus kendaraan beserta seluruh riwayat servisnya (cascade di database).
  Future<bool> deleteVehicle(int id) async {
    _errorMessage = null;

    try {
      await _repository.delete(id);
      _vehicles = _vehicles
          .where((Vehicle kendaraan) => kendaraan.id != id)
          .toList(growable: false);

      if (_selectedVehicleId == id) {
        _selectedVehicleId = _vehicles.isEmpty ? null : _vehicles.first.id;
      }

      // Notifikasi milik kendaraan ini tidak relevan lagi.
      await NotificationService.instance.cancelForVehicle(id);

      _state = LoadState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal menghapus kendaraan.';
      notifyListeners();
      return false;
    }
  }

  /// Perbarui kilometer kendaraan.
  ///
  /// Kilometer baru tidak boleh lebih kecil dari kilometer yang tersimpan,
  /// karena odometer tidak pernah berjalan mundur.
  Future<bool> updateKm(int vehicleId, int newKm) async {
    _errorMessage = null;

    final Vehicle? kendaraan = vehicleById(vehicleId);
    if (kendaraan == null) {
      _errorMessage = 'Kendaraan tidak ditemukan.';
      notifyListeners();
      return false;
    }
    if (newKm < kendaraan.currentKm) {
      _errorMessage = 'KM baru (${newKm.toString()}) tidak boleh lebih kecil dari '
          'KM terakhir (${kendaraan.currentKm.toString()}).';
      notifyListeners();
      return false;
    }

    try {
      final Vehicle terbaru = await _repository.updateKm(vehicleId, newKm);
      _gabungkan(terbaru);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal memperbarui kilometer.';
      notifyListeners();
      return false;
    }
  }

  /// Simpan tanggal jatuh tempo pajak & STNK satu kendaraan.
  Future<bool> saveTaxDates(
    int vehicleId, {
    required DateTime? taxDueDate,
    required DateTime? stnkDueDate,
  }) async {
    _errorMessage = null;

    try {
      final Vehicle terbaru = await _repository.updateTaxDates(
        vehicleId,
        taxDueDate: taxDueDate,
        stnkDueDate: stnkDueDate,
      );
      _gabungkan(terbaru);
      await NotificationService.instance.syncTaxReminders(terbaru);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.pesan : 'Gagal menyimpan tanggal pajak.';
      notifyListeners();
      return false;
    }
  }

  /// Cari kendaraan di memori berdasarkan id. `null` jika tidak ada.
  Vehicle? vehicleById(int id) {
    for (final Vehicle kendaraan in _vehicles) {
      if (kendaraan.id == id) return kendaraan;
    }
    return null;
  }

  /// Mengganti satu entri di daftar dengan versi terbaru dari server.
  void _gabungkan(Vehicle terbaru) {
    final int? id = terbaru.id;
    if (id == null) return;

    final int indeks = _vehicles.indexWhere((Vehicle k) => k.id == id);
    if (indeks == -1) {
      _vehicles = <Vehicle>[..._vehicles, terbaru];
    } else {
      final List<Vehicle> salinan = List<Vehicle>.of(_vehicles);
      salinan[indeks] = terbaru;
      _vehicles = salinan;
    }
    _state = LoadState.success;
  }

  /// Bersihkan pesan error setelah ditampilkan di SnackBar.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
