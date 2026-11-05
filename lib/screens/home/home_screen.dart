import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tax_reminder.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/constants.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_grid.dart';
import '../../widgets/error_view.dart';
import '../../widgets/home/greeting_card.dart';
import '../../widgets/home/mini_vehicle_card.dart';
import '../../widgets/home/quick_action_card.dart';
import '../../widgets/home/reminder_card.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_summary_row.dart';
import '../vehicle/vehicle_detail_screen.dart';
import '../vehicle/vehicle_form_screen.dart';

/// Beranda aplikasi: sapaan, ringkasan kendaraan, pengingat yang mendesak,
/// dan jalan pintas ke fitur utama.
///
/// Tata letak responsif (`LayoutBuilder`):
/// - < 600 px  → satu kolom.
/// - ≥ 600 px  → 2 kolom.
/// - ≥ 900 px  → 3 kolom.
class HomeScreen extends StatelessWidget {
  /// Dipakai untuk berpindah tab dari Beranda (Kendaraan / Tips / Profil).
  final void Function(int) onBukaTab;

  const HomeScreen({super.key, required this.onBukaTab});

  @override
  Widget build(BuildContext context) {
    final VehicleProvider provider = context.watch<VehicleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: provider.isLoading ? null : provider.loadVehicles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            if (provider.isLoading && provider.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.isEmpty) {
              return ErrorView(
                pesan: provider.errorMessage!,
                onRetry: provider.loadVehicles,
              );
            }

            return RefreshIndicator(
              onRefresh: provider.loadVehicles,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints batas) {
                  final int kolom = Responsive.kolom(batas.maxWidth, maks: 3);
                  return _IsiBeranda(kolom: kolom, onBukaTab: onBukaTab);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Isi Beranda yang sudah menerima jumlah kolom dari [LayoutBuilder].
class _IsiBeranda extends StatelessWidget {
  final int kolom;
  final void Function(int) onBukaTab;

  const _IsiBeranda({required this.kolom, required this.onBukaTab});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final VehicleProvider provider = context.watch<VehicleProvider>();
    final List<Vehicle> kendaraan = provider.vehicles;

    final List<PengingatPajak> dekat = <PengingatPajak>[];
    int jumlahPajakDekat = 0;
    int jumlahStnkDekat = 0;

    for (final Vehicle item in kendaraan) {
      final DateTime? pajak = item.taxDueDate;
      if (pajak != null) {
        final int sisa = daysFromToday(pajak);
        if (sisa <= 30) {
          jumlahPajakDekat++;
          dekat.add((
            vehicle: item,
            jenis: TaxType.pajakTahunan,
            tanggal: pajak,
            sisaHari: sisa,
          ));
        }
      }

      final DateTime? stnk = item.stnkDueDate;
      if (stnk != null) {
        final int sisa = daysFromToday(stnk);
        if (sisa <= 30) {
          jumlahStnkDekat++;
          dekat.add((
            vehicle: item,
            jenis: TaxType.stnkLimaTahunan,
            tanggal: stnk,
            sisaHari: sisa,
          ));
        }
      }
    }

    dekat.sort(
      (PengingatPajak a, PengingatPajak b) =>
          a.sisaHari.compareTo(b.sisaHari),
    );

    final int belumDiatur = kendaraan
        .where(
          (Vehicle item) => item.taxDueDate == null || item.stnkDueDate == null,
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        GreetingCard(jumlahKendaraan: kendaraan.length),
        const SizedBox(height: 14),

        if (provider.errorMessage != null) ...<Widget>[
          InfoBanner(
            tone: BannerTone.bahaya,
            judul: 'Sebagian data gagal dimuat',
            pesan: provider.errorMessage!,
            aksi: TextButton(
              onPressed: provider.loadVehicles,
              child: const Text('Coba lagi'),
            ),
          ),
          const SizedBox(height: 14),
        ],

        StatusSummaryRow(
          items: <StatusSummaryItem>[
            StatusSummaryItem(
              jumlah: kendaraan.length,
              label: 'Kendaraan',
              color: theme.colorScheme.primary,
              icon: Icons.two_wheeler,
            ),
            StatusSummaryItem(
              jumlah: jumlahPajakDekat,
              label: 'Pajak ≤ 30 hari',
              color: AppColors.mendekati,
              icon: Icons.account_balance_outlined,
            ),
            StatusSummaryItem(
              jumlah: jumlahStnkDekat,
              label: 'STNK ≤ 30 hari',
              color: AppColors.lewatBatas,
              icon: Icons.badge_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),

        SectionHeader(
          icon: Icons.notifications_active_outlined,
          title: 'Perlu perhatian',
          subtitle: 'Jatuh tempo 30 hari ke depan'
              '${belumDiatur == 0 ? '' : ' · $belumDiatur kendaraan belum diatur'}',
          actionLabel: kendaraan.isEmpty ? null : 'Lihat semua',
          onAction: () => onBukaTab(1),
        ),
        const SizedBox(height: 10),
        if (dekat.isEmpty)
          InfoBanner(
            tone: BannerTone.sukses,
            judul: 'Tidak ada jatuh tempo dekat',
            pesan: kendaraan.isEmpty
                ? 'Tambahkan kendaraan agar pengingat pajak dan STNK bisa '
                    'disusun otomatis.'
                : 'Semua pajak dan STNK kendaraanmu masih jauh dari jatuh tempo.',
          )
        else
          AdaptiveGrid(
            maksKolom: kolom,
            tinggiItem: 104,
            children: <Widget>[
              for (final PengingatPajak item in dekat.take(6))
                ReminderCard(
                  pengingat: item,
                  onTap: () => _bukaDetail(context, item.vehicle),
                ),
            ],
          ),
        const SizedBox(height: 20),

        SectionHeader(
          icon: Icons.garage_outlined,
          title: 'Kendaraan saya',
          subtitle: kendaraan.isEmpty
              ? 'Belum ada kendaraan terdaftar'
              : '${kendaraan.length} kendaraan terdaftar',
          actionLabel: kendaraan.isEmpty ? null : 'Kelola',
          onAction: () => onBukaTab(1),
        ),
        const SizedBox(height: 10),
        if (kendaraan.isEmpty)
          InfoBanner(
            pesan: 'Mulai dengan menambahkan motor pertamamu. Data akan '
                'tersimpan di Supabase dan bisa dibuka lagi kapan saja.',
            aksi: FilledButton.tonalIcon(
              onPressed: () => _bukaForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah kendaraan'),
            ),
          )
        else
          AdaptiveGrid(
            maksKolom: kolom,
            tinggiItem: 92,
            children: <Widget>[
              for (final Vehicle item in kendaraan.take(3))
                MiniVehicleCard(
                  vehicle: item,
                  onTap: () => _bukaDetail(context, item),
                ),
            ],
          ),
        const SizedBox(height: 20),

        const SectionHeader(
          icon: Icons.bolt_outlined,
          title: 'Menu cepat',
          subtitle: 'Akses fitur utama dalam satu ketukan',
        ),
        const SizedBox(height: 10),
        AdaptiveGrid(
          maksKolom: kolom,
          tinggiItem: 104,
          children: <Widget>[
            QuickActionCard(
              ikon: Icons.add_circle_outline,
              judul: 'Tambah Motor',
              keterangan: 'Daftarkan kendaraan baru',
              onTap: () => _bukaForm(context),
            ),
            QuickActionCard(
              ikon: Icons.two_wheeler_outlined,
              judul: 'Daftar Kendaraan',
              keterangan: 'Cari, filter, dan kelola',
              onTap: () => onBukaTab(1),
            ),
            QuickActionCard(
              ikon: Icons.menu_book_outlined,
              judul: 'Katalog & Tips',
              keterangan: 'Data dari REST API',
              onTap: () => onBukaTab(2),
            ),
            QuickActionCard(
              ikon: Icons.person_outline,
              judul: 'Profil',
              keterangan: 'Identitas & info aplikasi',
              onTap: () => onBukaTab(3),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _bukaForm(BuildContext context) async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const VehicleFormScreen()),
    );

    if (!context.mounted || berhasil != true) return;
    tampilkanPesan(context, 'Kendaraan berhasil ditambahkan.');
  }

  Future<void> _bukaDetail(BuildContext context, Vehicle vehicle) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }
}
