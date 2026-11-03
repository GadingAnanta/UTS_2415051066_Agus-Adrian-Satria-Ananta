import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';

/// Sumber kebenaran (single source of truth) untuk data kendaraan.
///
/// UI tidak pernah memanggil [DatabaseHelper] secara langsung. UI memanggil
/// provider, provider yang berbicara dengan database, lalu memberi tahu widget
/// lewat `notifyListeners()`.
class VehicleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Vehicle> _vehicles = <Vehicle>[];
  bool _isLoading = false;
  String? _errorMessage;

  /// Daftar kendaraan (tidak bisa diubah dari luar).
  List<Vehicle> get vehicles => List<Vehicle>.unmodifiable(_vehicles);

  bool get isLoading => _isLoading;
  bool get isEmpty => _vehicles.isEmpty;

  /// Pesan error terakhir, ditampilkan UI lewat SnackBar.
  String? get errorMessage => _errorMessage;

  /// Ambil ulang seluruh data kendaraan dari database.
  Future<void> loadVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await _db.getVehicles();
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar kendaraan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simpan kendaraan: INSERT jika [vehicle.id] null, UPDATE jika sudah ada.
  /// Mengembalikan `true` bila berhasil.
  Future<bool> saveVehicle(Vehicle vehicle) async {
    _errorMessage = null;

    try {
      if (vehicle.id == null) {
        await _db.insertVehicle(vehicle);
      } else {
        final int terubah = await _db.updateVehicle(vehicle);
        if (terubah == 0) {
          _errorMessage = 'Kendaraan tidak ditemukan, mungkin sudah dihapus.';
          notifyListeners();
          return false;
        }
      }

      // Muat ulang supaya urutan & data di UI selalu sama dengan database.
      _vehicles = await _db.getVehicles();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan kendaraan: $e';
      notifyListeners();
      return false;
    }
  }

  /// Hapus kendaraan beserta seluruh riwayat servis dan pengingat pajaknya.
  Future<bool> deleteVehicle(int id) async {
    _errorMessage = null;

    try {
      final int terhapus = await _db.deleteVehicle(id);
      if (terhapus == 0) {
        _errorMessage = 'Kendaraan tidak ditemukan, mungkin sudah dihapus.';
        notifyListeners();
        return false;
      }

      _vehicles = await _db.getVehicles();
      notifyListeners();

      // Notifikasi milik kendaraan ini tidak relevan lagi.
      await NotificationService.instance.cancelForVehicle(id);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus kendaraan: $e';
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
      _errorMessage =
          'KM baru (${newKm.toString()}) tidak boleh lebih kecil dari KM terakhir '
          '(${kendaraan.currentKm.toString()}).';
      notifyListeners();
      return false;
    }

    try {
      await _db.updateVehicleKm(vehicleId, newKm);
      _vehicles = await _db.getVehicles();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui kilometer: $e';
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

  /// Bersihkan pesan error setelah ditampilkan di SnackBar.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
