import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bengkel_digital/models/component_interval.dart';
import 'package:bengkel_digital/models/service_record.dart';
import 'package:bengkel_digital/utils/app_theme.dart';
import 'package:bengkel_digital/utils/service_calculator.dart';
import 'package:bengkel_digital/widgets/component_status_card.dart';

const ComponentInterval _oliMesin = ComponentInterval(
  key: 'oli_mesin',
  name: 'Oli Mesin',
  kmInterval: 2000,
  monthInterval: 2,
  iconKey: 'oli_mesin',
  sortOrder: 1,
);

ServiceRecord _catatan() => ServiceRecord(
      id: 1,
      vehicleId: 1,
      componentKey: 'oli_mesin',
      serviceDate: DateTime(2026, 1, 10),
      kmAtService: 10000,
      cost: 55000,
      createdAt: DateTime(2026, 1, 10),
    );

/// Membungkus kartu dengan MaterialApp supaya tema & MediaQuery tersedia.
Widget _bungkus(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  setUpAll(() async {
    // DateFormat locale id_ID butuh data locale dimuat lebih dulu.
    await initializeDateFormatting('id_ID');
  });

  testWidgets('menampilkan sisa KM dan sisa hari', (WidgetTester tester) async {
    final ComponentServiceStatus status = ComponentServiceStatus(
      component: _oliMesin,
      lastRecord: _catatan(),
      remainingKm: 1500,
      remainingDays: 45,
      nextServiceDate: DateTime(2026, 3, 10),
      nextServiceKm: 12000,
      kmStatus: ServiceStatus.aman,
      dayStatus: ServiceStatus.mendekati,
    );

    await tester.pumpWidget(_bungkus(ComponentStatusCard(status: status)));

    expect(find.text('Oli Mesin'), findsOneWidget);
    expect(find.text('Interval 2.000 km / 2 bulan'), findsOneWidget);
    expect(find.text('Sisa 1.500 km'), findsOneWidget);
    expect(find.text('45 hari lagi'), findsOneWidget);
    // Status gabungan memakai yang paling buruk: kuning (mendekati).
    expect(find.text('Mendekati'), findsOneWidget);
    expect(find.textContaining('Terakhir: 10 Januari 2026'), findsOneWidget);
  });

  testWidgets('menampilkan teks lewat batas saat sisa negatif',
      (WidgetTester tester) async {
    final ComponentServiceStatus status = ComponentServiceStatus(
      component: _oliMesin,
      lastRecord: _catatan(),
      remainingKm: -320,
      remainingDays: -5,
      kmStatus: ServiceStatus.lewatBatas,
      dayStatus: ServiceStatus.lewatBatas,
    );

    await tester.pumpWidget(_bungkus(ComponentStatusCard(status: status)));

    expect(find.text('Lewat 320 km'), findsOneWidget);
    expect(find.text('Lewat 5 hari'), findsOneWidget);
    expect(find.text('Lewat batas'), findsOneWidget);
  });

  testWidgets('komponen tanpa riwayat menampilkan ajakan mencatat servis',
      (WidgetTester tester) async {
    const ComponentServiceStatus status = ComponentServiceStatus(
      component: _oliMesin,
    );

    await tester.pumpWidget(_bungkus(const ComponentStatusCard(status: status)));

    expect(find.textContaining('Belum pernah dicatat'), findsOneWidget);
    expect(find.text('Belum ada data'), findsOneWidget);
  });
}
