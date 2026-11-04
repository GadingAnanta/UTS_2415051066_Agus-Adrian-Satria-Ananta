import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_exception.dart';

/// Layanan HTTP sederhana untuk mengambil data JSON dari REST API.
///
/// Hanya berisi satu operasi (GET) karena aplikasi hanya butuh membaca
/// katalog & tips dari berkas `tips.json` yang di-host di GitHub Pages.
/// Semua kegagalan diterjemahkan menjadi [AppException] berisi pesan
/// berbahasa Indonesia, sehingga UI tinggal menampilkannya.
class ApiService {
  ApiService({http.Client? client, this.batasWaktu = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Batas waktu satu permintaan agar UI tidak menunggu tanpa akhir.
  final Duration batasWaktu;

  /// Mengambil JSON objek dari [url].
  Future<Map<String, dynamic>> getJson(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw AppException('Alamat API tidak valid: $url');
    }

    try {
      final http.Response respons = await _client
          .get(uri, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(batasWaktu);

      if (respons.statusCode < 200 || respons.statusCode >= 300) {
        throw AppException(
          _pesanStatus(respons.statusCode),
          penyebab: 'HTTP ${respons.statusCode}',
        );
      }

      // bodyBytes + utf8 dipakai supaya karakter non-ASCII (mis. "é")
      // tidak rusak karena salah menebak encoding.
      final dynamic data = jsonDecode(utf8.decode(respons.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw const AppException(
          'Format data dari server tidak sesuai. Diharapkan objek JSON.',
        );
      }
      return data;
    } on AppException {
      rethrow;
    } on TimeoutException catch (e) {
      throw AppException(
        'Server katalog terlalu lama merespons. Periksa koneksi lalu coba lagi.',
        penyebab: e,
      );
    } on FormatException catch (e) {
      throw AppException(
        'Data dari server bukan JSON yang valid.',
        penyebab: e,
      );
    } on http.ClientException catch (e) {
      throw AppException(_pesanJaringan(e.message), penyebab: e);
    } catch (e) {
      throw AppException(_pesanJaringan(e.toString()), penyebab: e);
    }
  }

  /// Menutup koneksi HTTP (dipanggil saat provider dibuang).
  void close() => _client.close();

  static String _pesanStatus(int kode) {
    if (kode == 404) {
      return 'Katalog belum tersedia di server (404). Pastikan berkas '
          'tips.json sudah diunggah dan alamatnya benar.';
    }
    if (kode == 401 || kode == 403) {
      return 'Akses ke katalog ditolak ($kode). Periksa pengaturan akses berkas.';
    }
    if (kode >= 500) {
      return 'Server katalog sedang bermasalah ($kode). Coba lagi nanti.';
    }
    return 'Permintaan katalog gagal (kode $kode).';
  }

  /// Pesan ramah untuk masalah jaringan. Pengecekan memakai teks karena
  /// `SocketException` hanya ada di platform non-web.
  static String _pesanJaringan(String pesanAsli) {
    final String teks = pesanAsli.toLowerCase();
    if (teks.contains('failed host lookup') || teks.contains('socketexception')) {
      return 'Tidak bisa menemukan server katalog. Periksa koneksi internet.';
    }
    if (teks.contains('cors') || teks.contains('xmlhttprequest')) {
      return 'Server menolak permintaan dari aplikasi web (CORS). '
          'Pastikan berkas di-host di GitHub Pages.';
    }
    if (teks.contains('connection refused') || teks.contains('connection closed')) {
      return 'Koneksi ke server katalog terputus. Coba lagi.';
    }
    return 'Gagal mengambil data katalog. Periksa koneksi internet lalu coba lagi.';
  }
}
