import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/tips_data.dart';
import '../services/api_service.dart';

/// Mengambil katalog & tips dari REST API lalu mengubahnya menjadi [TipsData].
///
/// Alamat API dibaca dari `TIPS_API_URL` pada file `.env` supaya bisa diganti
/// tanpa mengubah kode. Bila variabel itu kosong, dipakai alamat bawaan
/// (berkas `api/tips.json` yang di-host di GitHub Pages).
class TipsRepository {
  TipsRepository({ApiService? api, String? url})
      : _api = api ?? ApiService(),
        _urlOverride = url;

  final ApiService _api;
  final String? _urlOverride;

  /// Alamat bawaan berkas katalog.
  ///
  /// Ganti dengan alamat GitHub Pages milikmu, contoh:
  /// `https://<username>.github.io/<repo>/api/tips.json`
  static const String urlBawaan =
      'https://raw.githubusercontent.com/GadingAnanta/'
      'UTS_2415051066_Agus-Adrian-Satria-Ananta/main/api/tips.json';

  /// Alamat yang benar-benar dipakai: `.env` → bawaan.
  String get url {
    final String? dariOverride = _urlOverride?.trim();
    if (dariOverride != null && dariOverride.isNotEmpty) return dariOverride;

    try {
      if (dotenv.isInitialized) {
        final String? dariEnv = dotenv.maybeGet('TIPS_API_URL')?.trim();
        if (dariEnv != null && dariEnv.isNotEmpty) return dariEnv;
      }
    } catch (_) {
      // .env belum dimuat (misalnya saat unit test): pakai alamat bawaan.
    }
    return urlBawaan;
  }

  /// Mengambil data katalog dari API.
  ///
  /// Melempar [AppException] bila jaringan bermasalah, server menolak, atau
  /// isi berkas bukan JSON yang diharapkan.
  Future<TipsData> fetchTips() async {
    final Map<String, dynamic> json = await _api.getJson(url);
    return TipsData.fromJson(json);
  }

  /// Menutup koneksi HTTP milik repository.
  void close() => _api.close();
}
