import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/tax_reminder.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';

/// Menyimpan state pengingat pajak/STNK satu kendaraan yang sedang dibuka.
///
/// Pola pemakaiannya sama dengan [ServiceProvider]: panggil [loadForVehicle]
/// saat halaman dibuka, lalu [saveReminder] untuk menyimpan perubahan.
class TaxProvider extends ChangeNotifier {
  TaxProvider({DatabaseHelper? database}) : _database = database ?? DatabaseHelper.instance;

  final DatabaseHelper _database;

  Vehicle? _vehicle;
  List<TaxReminder> _reminders = <TaxReminder>[];
  bool _loading = false;
  String? _error;

  /// Kendaraan yang pengingatnya sedang ditampilkan.
  Vehicle? get vehicle => _vehicle;

  /// Daftar pengingat (maksimal 2 baris: pajak tahunan & STNK 5 tahunan).
  List<TaxReminder> get reminders => List<TaxReminder>.unmodifiable(_reminders);

  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _reminders.isEmpty;

  /// Mengambil pengingat pajak milik [kendaraan] dari database.
  Future<void> loadForVehicle(Vehicle kendaraan) async {
    _vehicle = kendaraan;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _database.getTaxRemindersByVehicle(kendaraan.id!);
    } catch (e) {
      _error = 'Gagal memuat pengingat pajak: $e';
      _reminders = <TaxReminder>[];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Mengambil pengingat untuk satu jenis dokumen, atau `null` bila belum ada.
  TaxReminder? reminderFor(TaxType tipe) {
    for (final TaxReminder item in _reminders) {
      if (item.type == tipe) return item;
    }
    return null;
  }

  /// Menyimpan (insert/update) pengingat lalu menyusun ulang jadwal notifikasi.
  ///
  /// Mengembalikan `true` bila berhasil. Pesan kesalahan tersedia di [error].
  Future<bool> saveReminder(TaxReminder reminder) async {
    _error = null;
    try {
      await _database.saveTaxReminder(reminder);

      if (_vehicle != null) {
        _reminders = await _database.getTaxRemindersByVehicle(_vehicle!.id!);
        notifyListeners();

        // Jadwal notifikasi selalu disinkronkan ulang setelah data berubah.
        await NotificationService.instance.syncTaxReminders(
          vehicle: _vehicle!,
          reminders: _reminders,
        );
      }
      return true;
    } catch (e) {
      _error = 'Gagal menyimpan pengingat: $e';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus pengingat satu jenis dokumen beserta jadwal notifikasinya.
  Future<bool> deleteReminder(TaxType tipe) async {
    final TaxReminder? ada = reminderFor(tipe);
    if (ada?.id == null || _vehicle == null) return false;

    _error = null;
    try {
      await _database.deleteTaxReminder(ada!.id!);
      _reminders = await _database.getTaxRemindersByVehicle(_vehicle!.id!);
      notifyListeners();

      // Sync ulang: id notifikasi yang lama otomatis dibatalkan.
      await NotificationService.instance.syncTaxReminders(
        vehicle: _vehicle!,
        reminders: _reminders,
      );
      return true;
    } catch (e) {
      _error = 'Gagal menghapus pengingat: $e';
      notifyListeners();
      return false;
    }
  }

  /// Pengingat terdekat (jatuh tempo paling awal), dipakai untuk ringkasan
  /// di dashboard.
  TaxReminder? get terdekat {
    if (_reminders.isEmpty) return null;
    TaxReminder hasil = _reminders.first;
    for (final TaxReminder item in _reminders) {
      if (item.dueDate.isBefore(hasil.dueDate)) hasil = item;
    }
    return hasil;
  }
}
