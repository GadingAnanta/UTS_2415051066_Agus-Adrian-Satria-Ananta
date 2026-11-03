import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Menyiapkan implementasi SQLite sesuai platform yang sedang dipakai.
///
/// - Android/iOS: plugin `sqflite` sudah otomatis menjadi factory default,
///   jadi tidak ada yang perlu diubah.
/// - Web (pratinjau di Chrome): SQLite tidak tersedia sebagai plugin native,
///   sehingga dipakai versi WebAssembly dari `sqflite_common_ffi_web`.
///   Bagian ini hanya untuk keperluan pratinjau, bukan target tugas.
///
/// Fungsi ini harus dipanggil sekali di `main()` sebelum database dibuka.
void setupDatabaseFactory() {
  if (kIsWeb) {
    // File pendukung (web/sqlite3.wasm dan web/sqflite_sw.js) dihasilkan oleh
    // perintah: dart run sqflite_common_ffi_web:setup
    databaseFactory = databaseFactoryFfiWeb;
  }
}
