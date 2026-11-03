import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'database/database_factory_setup.dart';
import 'providers/service_provider.dart';
import 'providers/tax_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/vehicle/vehicle_list_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Wajib dipanggil sebelum memakai plugin/platform channel.
  WidgetsFlutterBinding.ensureInitialized();

  // Tentukan implementasi SQLite (Android memakai sqflite, web memakai WASM).
  setupDatabaseFactory();

  // Muat data locale Indonesia supaya DateFormat(..., 'id_ID') berfungsi.
  await initializeDateFormatting('id_ID');

  // Siapkan notifikasi lokal (kanal Android + zona waktu) lalu minta izin.
  // Di web method ini tidak melakukan apa pun.
  await NotificationService.instance.init();
  await NotificationService.instance.mintaIzin();

  runApp(const BengkelDigitalApp());
}

/// Akar aplikasi: menyediakan provider (state) dan tema global.
class BengkelDigitalApp extends StatelessWidget {
  const BengkelDigitalApp({super.key});

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
        // Provider pengingat pajak/STNK, diisi saat halaman Pajak dibuka.
        ChangeNotifierProvider<TaxProvider>(
          create: (_) => TaxProvider(),
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

        home: const VehicleListScreen(),
      ),
    );
  }
}
