import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_record.dart';
import '../services/supabase_service.dart';
import '../utils/app_exception.dart';

/// Pintu masuk data riwayat servis (tabel `service_records`).
class ServiceRecordRepository {
  ServiceRecordRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _db => _clientOverride ?? SupabaseService.instance.client;

  static const String _tabel = SupabaseService.tabelServiceRecords;

  /// Catatan servis satu kendaraan, terbaru di atas.
  /// Bila [componentKey] diisi, hasilnya difilter untuk komponen itu saja.
  Future<List<ServiceRecord>> fetchByVehicle(
    int vehicleId, {
    String? componentKey,
  }) async {
    try {
      var query = _db.from(_tabel).select().eq('vehicle_id', vehicleId);
      if (componentKey != null) {
        query = query.eq('component', componentKey);
      }

      final List<dynamic> rows = await query
          .order('service_date', ascending: false)
          .order('id', ascending: false);

      return rows
          .map((dynamic row) => ServiceRecord.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  /// Seluruh catatan servis dari semua kendaraan (dipakai grafik pengeluaran).
  Future<List<ServiceRecord>> fetchAll({required String userId}) async {
    try {
      // Filter pemilik dilakukan lewat relasi ke tabel vehicles.
      final List<dynamic> rows = await _db
          .from(_tabel)
          .select('*, vehicles!inner(user_id)')
          .eq('vehicles.user_id', userId)
          .order('service_date', ascending: false)
          .order('id', ascending: false);

      return rows
          .map((dynamic row) => ServiceRecord.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  Future<ServiceRecord> create(ServiceRecord catatan) async {
    try {
      final Map<String, dynamic> row = await _db
          .from(_tabel)
          .insert(catatan.toInsertJson())
          .select()
          .single();

      return ServiceRecord.fromJson(row);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  Future<ServiceRecord> update(ServiceRecord catatan) async {
    final int? id = catatan.id;
    if (id == null) {
      throw const AppException('Catatan servis belum tersimpan.');
    }

    try {
      final Map<String, dynamic> row = await _db
          .from(_tabel)
          .update(catatan.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return ServiceRecord.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const AppException('Catatan servis tidak ditemukan, mungkin sudah dihapus.');
      }
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      final List<dynamic> terhapus =
          await _db.from(_tabel).delete().eq('id', id).select();

      if (terhapus.isEmpty) {
        throw const AppException('Catatan servis tidak ditemukan, mungkin sudah dihapus.');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(SupabaseService.pesanError(e), penyebab: e);
    }
  }
}
