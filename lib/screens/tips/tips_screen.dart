import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tips_data.dart';
import '../../providers/load_state.dart';
import '../../providers/tips_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

/// Halaman Katalog & Tips.
///
/// Data diambil dari REST API (`api/tips.json` yang di-host di GitHub Pages)
/// lewat [TipsProvider] → `TipsRepository` → `ApiService`.
/// Halaman ini wajib menampilkan tiga kondisi: **loading**, **error**
/// (dengan tombol coba lagi), dan **empty** bila API mengembalikan data kosong.
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
    // saat widget sedang dibangun. Data tidak dimuat ulang bila sudah ada,
    // agar halaman tidak berkedip setiap kali dibuka kembali.
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
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Katalog gagal dimuat',
        message: '${provider.errorMessage ?? 'Terjadi kesalahan.'}\n\n'
            'Alamat API:\n${provider.urlApi}',
        actionLabel: 'Coba lagi',
        actionIcon: Icons.refresh,
        onAction: provider.refresh,
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

    // 4. DATA SIAP.
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          if (provider.state == LoadState.error)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _KotakPeringatan(pesan: provider.errorMessage ?? ''),
            ),
          _InfoSumber(data: data, sedangMemuat: provider.isLoading),
          const SizedBox(height: 20),
          _JudulBagian(
            ikon: Icons.two_wheeler,
            judul: 'Katalog Motor',
            jumlah: data.katalogMotor.length,
          ),
          const SizedBox(height: 10),
          _DaftarKatalog(motor: data.katalogMotor),
          const SizedBox(height: 22),
          _JudulBagian(
            ikon: Icons.tips_and_updates_outlined,
            judul: 'Tips Perawatan',
            jumlah: data.tipsPerawatan.length,
          ),
          const SizedBox(height: 10),
          ...data.tipsPerawatan.map(
            (TipsPerawatan tips) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _KartuTips(tips: tips),
            ),
          ),
          const SizedBox(height: 12),
          _JudulBagian(
            ikon: Icons.settings_suggest_outlined,
            judul: 'Interval Servis Standar',
            jumlah: data.intervalServis.length,
          ),
          const SizedBox(height: 10),
          _TabelInterval(interval: data.intervalServis),
        ],
      ),
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

/// Kartu kecil berisi sumber & tanggal pembaruan data.
class _InfoSumber extends StatelessWidget {
  final TipsData data;
  final bool sedangMemuat;

  const _InfoSumber({required this.data, required this.sedangMemuat});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final DateTime? diperbarui = DateTime.tryParse(data.diperbarui);

    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.cloud_done_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data dari REST API',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (sedangMemuat)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${data.jumlahItem} butir data'
              '${diperbarui == null ? '' : ' · diperbarui ${formatTanggal(diperbarui)}'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (data.sumber.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                data.sumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Judul bagian + jumlah butir.
class _JudulBagian extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final int jumlah;

  const _JudulBagian({required this.ikon, required this.judul, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(ikon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            judul,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$jumlah item',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Daftar kartu motor. Satu kolom di layar sempit, dua-tiga kolom di layar lebar
/// (memakai `Wrap` supaya tinggi kartu boleh berbeda tanpa overflow).
class _DaftarKatalog extends StatelessWidget {
  final List<KatalogMotor> motor;

  const _DaftarKatalog({required this.motor});

  @override
  Widget build(BuildContext context) {
    if (motor.isEmpty) {
      return const _BarisKosong(teks: 'Belum ada data motor di katalog.');
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints batas) {
        const double jarak = 10;
        final double lebar = batas.maxWidth;
        final int kolom = lebar >= 1000 ? 3 : (lebar >= 640 ? 2 : 1);
        final double lebarKartu = (lebar - jarak * (kolom - 1)) / kolom;

        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: motor
              .map(
                (KatalogMotor item) => SizedBox(
                  width: lebarKartu,
                  child: _KartuMotor(motor: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Kartu satu motor pada katalog.
class _KartuMotor extends StatelessWidget {
  final KatalogMotor motor;

  const _KartuMotor({required this.motor});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(
                    Icons.two_wheeler,
                    size: 20,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        motor.namaLengkap,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${motor.jenis} · ${motor.tahun}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _Chip(teks: motor.labelKapasitas),
                if (motor.transmisi.isNotEmpty) _Chip(teks: motor.transmisi),
                if (motor.konsumsiBbm != null)
                  _Chip(teks: '${motor.konsumsiBbm} km/L'),
              ],
            ),
            const SizedBox(height: 10),
            _BarisInfo(
              ikon: Icons.water_drop_outlined,
              label: 'Oli',
              nilai: motor.rekomendasiOli.isEmpty ? '-' : motor.rekomendasiOli,
            ),
            _BarisInfo(
              ikon: Icons.build_outlined,
              label: 'Interval',
              nilai: motor.labelInterval,
            ),
            if (motor.catatan.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                motor.catatan,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kartu tips dengan daftar langkah yang bisa dibuka-tutup.
class _KartuTips extends StatelessWidget {
  final TipsPerawatan tips;

  const _KartuTips({required this.tips});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          tips.judul,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${tips.kategori} · ${tips.labelInterval}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (tips.ringkasan.isNotEmpty) ...<Widget>[
            Text(tips.ringkasan, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
          ],
          ...tips.langkah.asMap().entries.map(
                (MapEntry<int, String> entri) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${entri.key + 1}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entri.value, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Tabel ringkas interval servis standar per komponen.
class _TabelInterval extends StatelessWidget {
  final List<IntervalServisStandar> interval;

  const _TabelInterval({required this.interval});

  @override
  Widget build(BuildContext context) {
    if (interval.isEmpty) {
      return const _BarisKosong(teks: 'Belum ada data interval servis.');
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < interval.length; i++) ...<Widget>[
              if (i > 0) Divider(height: 1, indent: 56, color: scheme.outlineVariant),
              ListTile(
                dense: true,
                leading: Icon(iconForComponent(interval[i].komponen), color: scheme.primary),
                title: Text(
                  interval[i].nama.isEmpty ? interval[i].komponen : interval[i].nama,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: interval[i].keterangan.isEmpty
                    ? null
                    : Text(
                        interval[i].keterangan,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                trailing: Text(
                  interval[i].labelInterval,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip kecil untuk spesifikasi motor.
class _Chip extends StatelessWidget {
  final String teks;

  const _Chip({required this.teks});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        teks,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Baris "ikon — label — nilai" di dalam kartu motor.
class _BarisInfo extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;

  const _BarisInfo({required this.ikon, required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ikon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Teks kecil saat satu bagian tidak punya data.
class _BarisKosong extends StatelessWidget {
  final String teks;

  const _BarisKosong({required this.teks});

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

/// Peringatan kecil bila muat ulang gagal padahal data lama masih ada.
class _KotakPeringatan extends StatelessWidget {
  final String pesan;

  const _KotakPeringatan({required this.pesan});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warna = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, size: 18, color: warna),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal memuat ulang: $pesan',
              style: theme.textTheme.bodySmall?.copyWith(color: warna),
            ),
          ),
        ],
      ),
    );
  }
}
