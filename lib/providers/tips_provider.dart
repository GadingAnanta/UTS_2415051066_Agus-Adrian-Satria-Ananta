import 'package:flutter/foundation.dart';

import '../models/tips_data.dart';
import '../repositories/tips_repository.dart';
import '../utils/app_exception.dart';
import 'load_state.dart';

/// State halaman Katalog & Tips.
///
/// Alur: **Screen → TipsProvider → TipsRepository → ApiService (HTTP GET)**.
/// Provider menyimpan tiga hal yang dibutuhkan UI: status pemuatan,
/// data hasil API, dan pesan error.
class TipsProvider extends ChangeNotifier {
  TipsProvider({TipsRepository? repository})
      : _repository = repository ?? TipsRepository();

  final TipsRepository _repository;

  LoadState _state = LoadState.idle;
  TipsData? _data;
  String? _errorMessage;

  /// Status pemuatan: idle / loading / success / error.
  LoadState get state => _state;

  bool get isLoading => _state == LoadState.loading;

  /// Data katalog. `null` berarti belum pernah berhasil dimuat.
  TipsData? get data => _data;

  /// True bila API mengembalikan data tetapi semuanya kosong.
  bool get isEmpty => _data == null || _data!.isEmpty;

  /// Pesan error terakhir, ditampilkan di halaman error.
  String? get errorMessage => _errorMessage;

  /// Alamat API yang sedang dipakai (ditampilkan di halaman error
  /// supaya mudah dicek saat berkas belum diunggah).
  String get urlApi => _repository.url;

  /// Mengambil data katalog dari API.
  Future<void> loadTips() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.fetchTips();
      _state = LoadState.success;
    } catch (e) {
      _errorMessage = e is AppException
          ? e.pesan
          : 'Gagal memuat katalog. Periksa koneksi internet lalu coba lagi.';
      _state = LoadState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Muat ulang data (dipakai tombol "Coba lagi" dan pull-to-refresh).
  Future<void> refresh() => loadTips();

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }
}
