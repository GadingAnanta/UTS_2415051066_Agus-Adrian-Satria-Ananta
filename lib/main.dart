import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/service_provider.dart';
import 'providers/tips_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/vehicle/vehicle_list_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Wajib dipanggil sebelum memakai plugin/platform channel.
  WidgetsFlutterBinding.ensureInitialized();

  // Muat data locale Indonesia supaya DateFormat(..., 'id_ID') berfungsi.
  await initializeDateFormatting('id_ID');

  // Baca .env lalu sambungkan ke Supabase (Repository → Supabase).
  // Bila gagal, aplikasi tetap dibuka dan menampilkan pesan konfigurasi.
  final bool supabaseSiap = await SupabaseService.instance.initialize();

  // Siapkan notifikasi lokal (kanal Android + zona waktu) lalu minta izin.
  // Di web method ini tidak melakukan apa pun.
  await NotificationService.instance.init();
  await NotificationService.instance.mintaIzin();

  runApp(BengkelDigitalApp(supabaseSiap: supabaseSiap));
}

/// Akar aplikasi: menyediakan provider (state) dan tema global.
class BengkelDigitalApp extends StatelessWidget {
  /// Hasil inisialisasi Supabase; `false` berarti tampilkan layar kesalahan.
  final bool supabaseSiap;

  const BengkelDigitalApp({super.key, required this.supabaseSiap});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider langsung memuat data saat aplikasi pertama dibuka.
        ChangeNotifierProvider<VehicleProvider>(
          create: (_) => VehicleProvider()..loadVehicles(),
        ),
        // Provider servis diisi saat dashboard sebuah kendaraan dibuka.
        ChangeNotifierProvider<ServiceProvider>(
          create: (_) => ServiceProvider(),
        ),
        // Provider katalog & tips, diisi saat halaman Tips dibuka.
        ChangeNotifierProvider<TipsProvider>(
          create: (_) => TipsProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppInfo.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),

        // Bahasa Indonesia untuk seluruh teks bawaan Flutter
        // (pemilih tanggal, tombol dialog, dsb).
        locale: const Locale('id', 'ID'),
        supportedLocales: const <Locale>[
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: supabaseSiap
            ? const VehicleListScreen()
            : const _LayarKonfigurasiGagal(),
      ),
    );
  }
}

/// Ditampilkan bila `.env` belum benar atau Supabase tidak bisa dihubungi
/// saat aplikasi dibuka. Lebih ramah daripada crash tanpa penjelasan.
class _LayarKonfigurasiGagal extends StatelessWidget {
  const _LayarKonfigurasiGagal();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String pesan = SupabaseService.instance.pesanKonfigurasi ??
        'Koneksi ke Supabase gagal disiapkan.';

    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi Diperlukan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Aplikasi belum tersambung ke database',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(pesan, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text(
              'Langkah perbaikan:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '1. Salin file .env.example menjadi .env di folder proyek.\n'
              '2. Isi SUPABASE_URL dan SUPABASE_ANON_KEY dari dashboard Supabase.\n'
              '3. Jalankan supabase/schema.sql di SQL Editor Supabase.\n'
              '4. Jalankan ulang aplikasi (flutter run).',
            ),
            const SizedBox(height: 20),
            Text(
              'Catatan: aplikasi hanya memakai anon key, tidak pernah service_role key.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
