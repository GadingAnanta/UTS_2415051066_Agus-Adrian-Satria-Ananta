import 'package:flutter/material.dart';

import '../models/component_interval.dart';

/// Konstanta yang dipakai di banyak tempat di aplikasi.

/// Identitas aplikasi.
class AppInfo {
  const AppInfo._();

  static const String appName = 'Bengkel Digital';
  static const String appTagline = 'Pengingat servis kendaraanmu';
}

/// Warna utama & warna status komponen.
///
/// Warna status dipakai di dashboard (hijau = aman, kuning = mendekati,
/// merah = sudah lewat batas).
class AppColors {
  const AppColors._();

  /// Warna biji (seed) tema Material 3.
  static const Color primary = Color(0xFF00695C);

  static const Color aman = Color(0xFF2E7D32);
  static const Color mendekati = Color(0xFFF9A825);
  static const Color lewatBatas = Color(0xFFC62828);
}

/// Daftar komponen bawaan sesuai spesifikasi tugas.
///
/// Nilai ini hanya dipakai sebagai data awal (seed) saat database pertama kali
/// dibuat. Setelah itu pengguna boleh mengubah intervalnya lewat halaman
/// pengaturan, dan perubahan tersimpan di tabel `component_intervals`.
///
/// Catatan: `kmInterval` bernilai null berarti komponen tersebut tidak punya
/// patokan kilometer (contoh: Aki hanya dihitung per bulan).
const List<ComponentInterval> defaultComponentIntervals = <ComponentInterval>[
  ComponentInterval(
    key: 'oli_mesin',
    name: 'Oli Mesin',
    kmInterval: 2000,
    monthInterval: 2,
    iconKey: 'oli_mesin',
    sortOrder: 1,
  ),
  ComponentInterval(
    key: 'oli_gearbox',
    name: 'Oli Gearbox',
    kmInterval: 8000,
    monthInterval: 6,
    iconKey: 'oli_gearbox',
    sortOrder: 2,
  ),
  ComponentInterval(
    key: 'filter_udara',
    name: 'Filter Udara',
    kmInterval: 8000,
    monthInterval: 6,
    iconKey: 'filter_udara',
    sortOrder: 3,
  ),
  ComponentInterval(
    key: 'busi',
    name: 'Busi',
    kmInterval: 8000,
    monthInterval: 12,
    iconKey: 'busi',
    sortOrder: 4,
  ),
  ComponentInterval(
    key: 'kampas_rem',
    name: 'Kampas Rem',
    kmInterval: 10000,
    monthInterval: 12,
    iconKey: 'kampas_rem',
    sortOrder: 5,
  ),
  ComponentInterval(
    key: 'rantai_belt',
    name: 'Rantai / Belt',
    kmInterval: 20000,
    monthInterval: 24,
    iconKey: 'rantai_belt',
    sortOrder: 6,
  ),
  ComponentInterval(
    key: 'aki',
    name: 'Aki',
    kmInterval: null,
    monthInterval: 24,
    iconKey: 'aki',
    sortOrder: 7,
  ),
  ComponentInterval(
    key: 'ban',
    name: 'Ban',
    kmInterval: 20000,
    monthInterval: 24,
    iconKey: 'ban',
    sortOrder: 8,
  ),
];

/// Pemetaan `iconKey` (disimpan di database) menjadi ikon Material.
///
/// Ikon tidak disimpan langsung di database supaya aman dari perubahan kode
/// ikon dan tetap bisa di-tree-shake oleh compiler Flutter.
const Map<String, IconData> _componentIcons = <String, IconData>{
  'oli_mesin': Icons.water_drop,
  'oli_gearbox': Icons.settings,
  'filter_udara': Icons.air,
  'busi': Icons.bolt,
  'kampas_rem': Icons.album,
  'rantai_belt': Icons.link,
  'aki': Icons.battery_charging_full,
  'ban': Icons.trip_origin,
};

/// Mengembalikan ikon untuk sebuah komponen. Jika tidak dikenal, pakai ikon
/// kunci pas sebagai ikon umum.
IconData iconForComponent(String iconKey) {
  return _componentIcons[iconKey] ?? Icons.build;
}
