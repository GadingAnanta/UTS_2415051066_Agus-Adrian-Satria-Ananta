/// Exception aplikasi: pesan yang aman ditampilkan ke pengguna.
///
/// Repositori menangkap error teknis (PostgrestException, SocketException,
/// dan sebagainya) lalu melempar [AppException] berisi pesan berbahasa
/// Indonesia. Dengan begitu lapisan UI tidak perlu tahu detail teknisnya.
class AppException implements Exception {
  /// Pesan siap tampil di SnackBar / halaman error.
  final String pesan;

  /// Error asli (untuk log/debug), boleh null.
  final Object? penyebab;

  const AppException(this.pesan, {this.penyebab});

  @override
  String toString() =>
      penyebab == null ? 'AppException: $pesan' : 'AppException: $pesan ($penyebab)';
}
