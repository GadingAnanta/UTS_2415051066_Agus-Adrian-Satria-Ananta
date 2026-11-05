import 'package:flutter/widgets.dart';

/// Aturan tata letak responsif aplikasi.
///
/// Dua titik henti (breakpoint) yang dipakai konsisten di seluruh halaman:
/// - **< 600 px** : ponsel → `NavigationBar` di bawah, konten satu kolom.
/// - **600–899 px**: tablet → `NavigationRail` di kiri, grid 2 kolom.
/// - **≥ 900 px** : desktop → `NavigationRail` (bisa diperluas), grid 3 kolom.
class Responsive {
  const Responsive._();

  /// Lebar minimum untuk beralih dari NavigationBar ke NavigationRail.
  static const double batasSempit = 600;

  /// Lebar minimum untuk tata letak tiga kolom.
  static const double batasLebar = 900;

  /// Lebar minimum untuk NavigationRail versi diperluas (label + ikon).
  static const double batasRailDiperluas = 1180;

  /// True bila layar tergolong ponsel.
  static bool sempit(double lebar) => lebar < batasSempit;

  /// True bila layar tergolong desktop/lebar.
  static bool lebar(double lebar) => lebar >= batasLebar;

  /// Jumlah kolom grid untuk [lebar].
  ///
  /// [maks] membatasi jumlah kolom (misalnya kartu tips cukup 2 kolom).
  static int kolom(double lebar, {int maks = 3}) {
    if (lebar < batasSempit) return 1;
    if (lebar < batasLebar) return maks >= 2 ? 2 : 1;
    return maks;
  }
}

/// Ekstensi praktis supaya widget bisa menulis `context.sempit`.
extension ResponsiveContext on BuildContext {
  /// Lebar area yang tersedia untuk widget ini.
  double get lebarLayar => MediaQuery.sizeOf(this).width;

  bool get layarSempit => Responsive.sempit(lebarLayar);
  bool get layarLebar => Responsive.lebar(lebarLayar);
}
