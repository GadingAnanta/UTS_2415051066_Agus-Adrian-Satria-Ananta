import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tips_data.dart';
import '../../providers/load_state.dart';
import '../../providers/tips_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_grid.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tips/interval_table.dart';
import '../../widgets/tips/katalog_motor_card.dart';
import '../../widgets/tips/tips_card.dart';
import '../../widgets/tips/tips_source_card.dart';

/// Halaman Katalog & Tips.
///
/// Data diambil dari REST API (`api/tips.json`) lewat [TipsProvider] →
/// `TipsRepository` → `ApiService`. Halaman ini wajib menampilkan tiga kondisi:
/// **loading**, **error** (dengan tombol coba lagi), dan **empty**.
///
/// Tata letak responsif memakai `LayoutBuilder`:
/// - < 600 px  → satu kolom (daftar menumpuk).
/// - ≥ 600 px  → grid 2 kolom.
/// - ≥ 900 px  → grid 3 kolom untuk katalog, 2 kolom untuk tips.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  @override
  void initState() {
    super.initState();

    // Dimuat setelah frame pertama supaya notifyListeners() tidak terjadi
    // saat widget sedang dibangun. Data tidak dimuat ulang bila sudah ada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final TipsProvider provider = context.read<TipsProvider>();
      if (provider.state == LoadState.idle) {
        provider.loadTips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TipsProvider provider = context.watch<TipsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog & Tips'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: provider.isLoading ? null : provider.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(child: _bangunIsi(provider)),
    );
  }

  Widget _bangunIsi(TipsProvider provider) {
    // 1. LOADING — belum ada data sama sekali.
    if (provider.state == LoadState.loading && provider.data == null) {
      return const _TampilanMemuat();
    }

    // 2. ERROR — tampilkan pesan + tombol coba lagi.
    if (provider.state == LoadState.error && provider.data == null) {
      return ErrorView(
        judul: 'Katalog gagal dimuat',
        pesan: '${provider.errorMessage ?? 'Terjadi kesalahan.'}\n\n'
            'Alamat API:\n${provider.urlApi}',
        onRetry: provider.refresh,
      );
    }

    final TipsData? data = provider.data;

    // 3. EMPTY — API berhasil tetapi datanya kosong.
    if (data == null || data.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Katalog masih kosong',
        message: 'Server tidak mengirim data katalog, tips, maupun interval '
            'servis. Coba muat ulang beberapa saat lagi.',
        actionLabel: 'Muat ulang',
        actionIcon: Icons.refresh,
        onAction: provider.refresh,
      );
    }

    // 4. DATA SIAP — tata letak mengikuti lebar layar.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints batas) {
        final bool sempit = Responsive.sempit(batas.maxWidth);
        final int kolomKatalog = Responsive.kolom(batas.maxWidth, maks: 3);
        final int kolomTips = Responsive.kolom(batas.maxWidth, maks: 2);

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              if (provider.state == LoadState.error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoBanner(
                    tone: BannerTone.bahaya,
                    judul: 'Gagal memuat ulang',
                    pesan: provider.errorMessage ?? 'Terjadi kesalahan.',
                    aksi: TextButton(
                      onPressed: provider.refresh,
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ),
              TipsSourceCard(data: data, sedangMemuat: provider.isLoading),
              const SizedBox(height: 20),
              SectionHeader(
                icon: Icons.two_wheeler,
                title: 'Katalog Motor',
                subtitle: '${data.katalogMotor.length} motor · ketuk untuk detail',
              ),
              const SizedBox(height: 10),
              if (data.katalogMotor.isEmpty)
                const _BagianKosong(teks: 'Belum ada data motor di katalog.')
              else
                AdaptiveGrid(
                  maksKolom: kolomKatalog,
                  tinggiItem: sempit ? 156 : 172,
                  children: <Widget>[
                    for (final KatalogMotor motor in data.katalogMotor)
                      KatalogMotorCard(motor: motor),
                  ],
                ),
              const SizedBox(height: 24),
              SectionHeader(
                icon: Icons.tips_and_updates_outlined,
                title: 'Tips Perawatan',
                subtitle:
                    '${data.tipsPerawatan.length} tips · ketuk kartu untuk langkah',
              ),
              const SizedBox(height: 10),
              if (data.tipsPerawatan.isEmpty)
                const _BagianKosong(teks: 'Belum ada tips perawatan.')
              else
                AdaptiveGrid(
                  maksKolom: kolomTips,
                  tinggiItem: sempit ? 146 : 156,
                  children: <Widget>[
                    for (final TipsPerawatan tips in data.tipsPerawatan)
                      TipsCard(tips: tips),
                  ],
                ),
              const SizedBox(height: 24),
              SectionHeader(
                icon: Icons.settings_suggest_outlined,
                title: 'Interval Servis Standar',
                subtitle: '${data.intervalServis.length} komponen',
              ),
              const SizedBox(height: 10),
              IntervalServisTable(interval: data.intervalServis),
            ],
          ),
        );
      },
    );
  }
}

/// Spinner + teks saat data pertama kali diambil.
class _TampilanMemuat extends StatelessWidget {
  const _TampilanMemuat();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Mengambil katalog dari server...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Teks kecil saat satu bagian tidak punya data.
class _BagianKosong extends StatelessWidget {
  final String teks;

  const _BagianKosong({required this.teks});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        teks,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
