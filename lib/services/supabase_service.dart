import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_exception.dart';

/// Layanan tunggal untuk koneksi ke Supabase.
///
/// Tanggung jawabnya hanya dua:
/// 1. Membaca konfigurasi dari `.env` (URL + anon key) lalu menginisialisasi
///    `supabase_flutter`.
/// 2. Menyediakan [client] untuk dipakai repository, sekaligus menerjemahkan
///    error teknis menjadi pesan berbahasa Indonesia ([pesanError]).
///
/// Hanya repository yang boleh menyentuh kelas ini; screen tidak.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  /// Nama tabel di Supabase (dipakai repository).
  static const String tabelVehicles = 'vehicles';
  static const String tabelServiceRecords = 'service_records';

  /// Nilai cadangan bila DEMO_USER_ID tidak diisi di .env.
  static const String _demoUserIdDefault = '11111111-1111-4111-8111-111111111111';

  bool _siap = false;
  String? _pesanKonfigurasi;

  /// True bila Supabase berhasil diinisialisasi.
  bool get siap => _siap;

  /// Alasan kegagalan konfigurasi (null bila tidak ada masalah).
  String? get pesanKonfigurasi => _pesanKonfigurasi;

  /// Id pengguna demo selama aplikasi belum punya fitur login.
  String get demoUserId =>
      dotenv.maybeGet('DEMO_USER_ID') ?? _demoUserIdDefault;

  /// Client Supabase yang sudah siap dipakai.
  ///
  /// Melempar [AppException] bila [initialize] belum berhasil, supaya error
  /// konfigurasi muncul sebagai pesan yang jelas, bukan crash.
  SupabaseClient get client {
    if (!_siap) {
      throw AppException(
        _pesanKonfigurasi ??
            'Koneksi ke Supabase belum siap. Periksa kembali file .env.',
      );
    }
    return Supabase.instance.client;
  }

  /// Membaca `.env` lalu menginisialisasi Supabase.
  ///
  /// Mengembalikan `true` bila berhasil. Bila gagal, aplikasi tetap bisa
  /// dijalankan dan menampilkan pesan kesalahan konfigurasi di layar.
  Future<bool> initialize() async {
    if (_siap) return true;

    try {
      await _muatEnv();

      final String url = dotenv.maybeGet('SUPABASE_URL')?.trim() ?? '';
      final String anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY')?.trim() ?? '';

      final String? masalah = _validasiKonfigurasi(url, anonKey);
      if (masalah != null) {
        _pesanKonfigurasi = masalah;
        return false;
      }

      await Supabase.initialize(url: url, publishableKey: anonKey);
      _siap = true;
      _pesanKonfigurasi = null;
      return true;
    } catch (e) {
      // Pesan sengaja tidak menyertakan nilai key agar tidak bocor di log.
      _pesanKonfigurasi = 'Gagal menyiapkan koneksi Supabase. '
          'Periksa SUPABASE_URL dan SUPABASE_ANON_KEY di file .env.';
      debugPrint('SupabaseService.initialize gagal: $e');
      return false;
    }
  }

  /// Memuat `.env`; kalau belum ada, pakai `.env.example` sebagai cadangan
  /// supaya pesan errornya tetap informatif.
  Future<void> _muatEnv() async {
    try {
      await dotenv.load(fileName: '.env', isOptional: true);
    } catch (e) {
      debugPrint('Gagal membaca .env: $e');
    }

    if ((dotenv.maybeGet('SUPABASE_URL') ?? '').isEmpty) {
      try {
        await dotenv.load(fileName: '.env.example', isOptional: true);
      } catch (e) {
        debugPrint('Gagal membaca .env.example: $e');
      }
    }
  }

  /// Memastikan nilai konfigurasi masuk akal sebelum dipakai.
  String? _validasiKonfigurasi(String url, String anonKey) {
    if (url.isEmpty || anonKey.isEmpty) {
      return 'Konfigurasi Supabase belum lengkap. Salin .env.example menjadi '
          '.env lalu isi SUPABASE_URL dan SUPABASE_ANON_KEY.';
    }
    if (url.contains('<') || anonKey.contains('<')) {
      return 'File .env masih berisi contoh. Isi SUPABASE_URL dan '
          'SUPABASE_ANON_KEY dengan nilai dari dashboard Supabase.';
    }
    if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      return 'SUPABASE_URL tidak valid. Bentuknya harus '
          'https://<project-ref>.supabase.co (bukan URL dashboard).';
    }
    return null;
  }

  /// Menerjemahkan error teknis menjadi pesan yang bisa dibaca pengguna.
  static String pesanError(Object error) {
    if (error is AppException) return error.pesan;

    if (error is PostgrestException) {
      final String kode = error.code ?? '-';
      if (kode == 'PGRST205' || error.message.contains('schema cache')) {
        return 'Tabel belum ada di Supabase. Jalankan supabase/schema.sql '
            'lebih dulu di SQL Editor.';
      }
      if (kode == '42501' || error.message.contains('row-level security')) {
        return 'Akses ditolak oleh aturan RLS. Pastikan policy anon pada '
            'schema.sql sudah dijalankan.';
      }
      if (kode == '23503') {
        return 'Data terkait tidak ditemukan (foreign key). Muat ulang lalu coba lagi.';
      }
      return 'Database menolak permintaan ($kode): ${error.message}';
    }

    if (error is AuthException) {
      return 'Sesi Supabase tidak valid: ${error.message}';
    }

    final String teks = error.toString().toLowerCase();
    if (teks.contains('socketexception') ||
        teks.contains('failed host lookup') ||
        teks.contains('clientexception') ||
        teks.contains('connection') ||
        teks.contains('network')) {
      return kIsWeb
          ? 'Tidak bisa menghubungi server. Periksa koneksi internet dan '
              'pastikan domain dibuka lewat https.'
          : 'Tidak bisa menghubungi server. Periksa koneksi internet Anda.';
    }
    if (teks.contains('timeout')) {
      return 'Server terlalu lama merespons. Coba lagi beberapa saat.';
    }

    return 'Terjadi kesalahan tak terduga. Coba lagi.';
  }
}
