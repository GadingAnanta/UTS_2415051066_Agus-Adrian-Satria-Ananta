import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../services/supabase_service.dart';
import '../utils/app_exception.dart';
import '../utils/formatters.dart';

/// Satu-satunya pintu masuk data kendaraan.
///
/// Lapisan ini yang berbicara dengan Supabase; provider hanya memanggil
/// method di sini. Semua error teknis dibungkus menjadi [AppException]
/// berisi pesan berbahasa Indonesia.
class VehicleRepository {
  VehicleRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _db => _clientOverride ?? SupabaseService.instance.client;

  static const String _tabel = SupabaseService.tabelVehicles;

  /// Pemilik data selama aplikasi belum punya fitur login.
  ///
  /// Nilainya diambil dari `DEMO_USER_ID` di `.env` (lihat
  /// [SupabaseService.demoUserId]). Repository yang menempelkan nilai ini ke
  /// setiap baris baru, sehingga halaman form tidak perlu tahu soal `.env`.
  String get _userId => SupabaseService.instance.demoUserId;

  /// Semua kendaraan milik pengguna demo, terlama lebih dulu.
  Future<List<Vehicle>> fetchAll() async {
    try {
      final List<dynamic> rows = await _db
          .from(_tabel)
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: true);

      return rows
          .map((dynamic row) => Vehicle.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Satu kendaraan berdasarkan id. `null` bila tidak ada.
  Future<Vehicle?> fetchById(int id) async {
    try {
      final Map<String, dynamic>? row = await _db
          .from(_tabel)
          .select()
          .eq('id', id)
          .maybeSingle();

      return row == null ? null : Vehicle.fromJson(row);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Menyimpan kendaraan baru. Mengembalikan objek dengan `id` dari database.
  ///
  /// Kolom `user_id` selalu diisi dari konfigurasi di sini (bukan dari form),
  /// supaya pemilik data tidak bisa salah/tertimpa oleh input halaman.
  Future<Vehicle> create(Vehicle kendaraan) async {
    final Map<String, Object?> data = kendaraan.toInsertJson()
      ..['user_id'] = _userId;

    try {
      final Map<String, dynamic> row = await _db
          .from(_tabel)
          .insert(data)
          .select()
          .single();

      return Vehicle.fromJson(row);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Memperbarui seluruh kolom kendaraan yang bisa diedit.
  Future<Vehicle> update(Vehicle kendaraan) async {
    final int? id = kendaraan.id;
    if (id == null) {
      throw const AppException('Kendaraan belum tersimpan, tidak bisa diperbarui.');
    }

    try {
      final Map<String, dynamic> row = await _db
          .from(_tabel)
          .update(kendaraan.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return Vehicle.fromJson(row);
    } on PostgrestException catch (e) {
      // `.single()` melempar PGRST116 bila tidak ada baris yang cocok.
      if (e.code == 'PGRST116') {
        throw const AppException('Kendaraan tidak ditemukan, mungkin sudah dihapus.');
      }
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Menghapus kendaraan. Catatan servisnya ikut terhapus lewat
  /// `on delete cascade` di database.
  Future<void> delete(int id) async {
    try {
      final List<dynamic> terhapus =
          await _db.from(_tabel).delete().eq('id', id).select();

      if (terhapus.isEmpty) {
        throw const AppException('Kendaraan tidak ditemukan, mungkin sudah dihapus.');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Hanya memperbarui odometer (fitur "Update KM").
  Future<Vehicle> updateKm(int id, int kmBaru) async {
    try {
      final Map<String, dynamic> row = await _db
          .from(_tabel)
          .update(<String, Object?>{'current_km': kmBaru})
          .eq('id', id)
          .select()
          .single();

      return Vehicle.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const AppException('Kendaraan tidak ditemukan, mungkin sudah dihapus.');
      }
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Menyimpan tanggal jatuh tempo pajak & STNK.
  ///
  /// Nilai `null` dikirim apa adanya supaya tanggal yang dikosongkan
  /// pengguna benar-benar terhapus di database.
  Future<Vehicle> updateTaxDates(
    int id, {
    required DateTime? taxDueDate,
    required DateTime? stnkDueDate,
  }) async {
    try {
      final Map<String, dynamic> row = await _db
          .from(_tabel)
          .update(<String, Object?>{
            'tax_due_date': taxDueDate == null ? null : toIsoDate(taxDueDate),
            'stnk_due_date': stnkDueDate == null ? null : toIsoDate(stnkDueDate),
          })
          .eq('id', id)
          .select()
          .single();

      return Vehicle.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const AppException('Kendaraan tidak ditemukan, mungkin sudah dihapus.');
      }
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }
}
