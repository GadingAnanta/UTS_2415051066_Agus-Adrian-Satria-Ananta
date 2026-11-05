import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bengkel_digital/models/tax_reminder.dart';
import 'package:bengkel_digital/models/tips_data.dart';
import 'package:bengkel_digital/models/vehicle.dart';
import 'package:bengkel_digital/utils/app_theme.dart';
import 'package:bengkel_digital/widgets/adaptive_grid.dart';
import 'package:bengkel_digital/widgets/home/reminder_card.dart';
import 'package:bengkel_digital/widgets/status_chip.dart';
import 'package:bengkel_digital/widgets/status_summary_row.dart';
import 'package:bengkel_digital/widgets/tax_due_card.dart';
import 'package:bengkel_digital/widgets/tips/katalog_motor_card.dart';
import 'package:bengkel_digital/widgets/tips/tips_card.dart';
import 'package:bengkel_digital/widgets/vehicle_card.dart';

/// Menguji tata letak di beberapa lebar layar: tidak boleh ada
/// RenderFlex overflow maupun exception saat layout.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  final Vehicle kendaraan = Vehicle(
    id: 1,
    userId: 'uji',
    brand: 'Honda',
    model: 'Vario 160 CBS dengan nama panjang',
    year: 2024,
    plateNumber: 'B 1234 XYZ',
    currentKm: 24500,
    taxDueDate: DateTime.now().add(const Duration(days: 12)),
    stnkDueDate: DateTime.now().subtract(const Duration(days: 3)),
    createdAt: DateTime(2026, 1, 1),
  );

  Widget bungkus(Widget child, double lebar) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: lebar, child: child),
        ),
      ),
    );
  }

  testWidgets('AdaptiveGrid 1/2/3 kolom tanpa overflow', (WidgetTester tester) async {
    final List<Widget> kartu = <Widget>[
      for (int i = 0; i < 5; i++)
        Card(
          child: Center(child: Text('Kartu $i')),
        ),
    ];

    for (final double lebar in <double>[360, 700, 1000]) {
      await tester.pumpWidget(
        bungkus(
          SingleChildScrollView(
            child: AdaptiveGrid(tinggiItem: 96, children: kartu),
          ),
          lebar,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'lebar $lebar');
    }
  });

  testWidgets('Kartu Beranda aman di layar sempit', (WidgetTester tester) async {
    await tester.pumpWidget(
      bungkus(
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StatusChip(label: 'Pajak', color: Colors.orange, kecil: true),
              StatusSummaryRow(
                items: const <StatusSummaryItem>[
                  StatusSummaryItem(
                    jumlah: 3,
                    label: 'Kendaraan',
                    color: Colors.teal,
                    icon: Icons.two_wheeler,
                  ),
                  StatusSummaryItem(
                    jumlah: 2,
                    label: 'Pajak ≤ 30 hari',
                    color: Colors.orange,
                    icon: Icons.account_balance_outlined,
                  ),
                  StatusSummaryItem(
                    jumlah: 1,
                    label: 'STNK ≤ 30 hari',
                    color: Colors.red,
                    icon: Icons.badge_outlined,
                  ),
                ],
              ),
              SizedBox(
                height: 104,
                child: ReminderCard(
                  pengingat: (
                    vehicle: kendaraan,
                    jenis: TaxType.pajakTahunan,
                    tanggal: kendaraan.taxDueDate!,
                    sisaHari: 12,
                  ),
                ),
              ),
              TaxDueCard(vehicle: kendaraan),
              VehicleCard(
                vehicle: kendaraan,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
        320,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kartu Tips & katalog aman di sel grid sempit', (WidgetTester tester) async {
    const TipsPerawatan tips = TipsPerawatan(
      id: 1,
      judul: 'Ganti oli mesin secara rutin untuk menjaga performa',
      kategori: 'Mesin',
      ringkasan:
          'Oli mesin perlu diganti sesuai interval agar gesekan komponen tetap rendah.',
      langkah: <String>['Siapkan oli', 'Panaskan mesin', 'Buang oli lama'],
      intervalKm: 2000,
      intervalBulan: 2,
    );

    const KatalogMotor motor = KatalogMotor(
      id: 'vario-160',
      merek: 'Honda',
      model: 'Vario 160 CBS',
      tahun: 2024,
      jenis: 'Skuter',
      kapasitasCc: 160,
      transmisi: 'CVT',
      rekomendasiOli: '10W-30',
      intervalServisKm: 2000,
      konsumsiBbm: 45,
    );

    for (final double lebar in <double>[280, 360, 520]) {
      await tester.pumpWidget(
        bungkus(
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 156,
                  child: TipsCard(tips: tips),
                ),
                SizedBox(
                  height: 172,
                  child: KatalogMotorCard(motor: motor),
                ),
              ],
            ),
          ),
          lebar,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'lebar $lebar');
    }
  });
}
