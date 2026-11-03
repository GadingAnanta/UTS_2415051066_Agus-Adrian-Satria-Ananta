import 'package:flutter/material.dart';

import 'constants.dart';
import 'service_calculator.dart';

/// Tema aplikasi (Material 3) dengan satu warna dasar yang konsisten.
///
/// Semua halaman mengambil warna dari `Theme.of(context).colorScheme`, jadi
/// mengganti [AppColors.primary] akan mengubah tampilan seluruh aplikasi.
ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: AppColors.primary);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF5F6F8),

    appBarTheme: AppBarThemeData(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),

    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
  );
}

/// Warna untuk setiap status servis.
///
/// Dipakai kartu komponen, ringkasan dashboard, dan badge status supaya
/// arti warnanya konsisten di seluruh aplikasi:
/// hijau = aman, kuning = mendekati, merah = lewat batas,
/// abu-abu = belum ada data.
Color colorForStatus(ServiceStatus status) {
  switch (status) {
    case ServiceStatus.aman:
      return AppColors.aman;
    case ServiceStatus.mendekati:
      return AppColors.mendekati;
    case ServiceStatus.lewatBatas:
      return AppColors.lewatBatas;
    case ServiceStatus.belumAdaData:
      return const Color(0xFF78909C);
  }
}
