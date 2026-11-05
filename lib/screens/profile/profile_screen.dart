import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/responsive.dart';
import '../../widgets/status_chip.dart';

/// Halaman Profil / About: identitas mahasiswa, informasi aplikasi, daftar
/// fitur, serta teknologi dan sumber data yang dipakai.
///
/// Dua kolom pada layar ≥ 900 px, satu kolom pada layar lebih kecil.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints batas) {
            final bool lebar = Responsive.lebar(batas.maxWidth);

            final Widget kolomKiri = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const <Widget>[
                _KartuIdentitas(),
                SizedBox(height: 12),
                _KartuAplikasi(),
              ],
            );

            final Widget kolomKanan = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const <Widget>[
                _KartuFitur(),
                SizedBox(height: 12),
                _KartuTeknis(),
              ],
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                if (lebar)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: kolomKiri),
                      const SizedBox(width: 16),
                      Expanded(child: kolomKanan),
                    ],
                  )
                else ...<Widget>[
                  kolomKiri,
                  const SizedBox(height: 12),
                  kolomKanan,
                ],
                const SizedBox(height: 20),
                Text(
                  'Dibuat untuk UTS ${AppInfo.mataKuliah} · ${AppInfo.versi}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kartu identitas mahasiswa.
class _KartuIdentitas extends StatelessWidget {
  const _KartuIdentitas();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String inisial = AppInfo.mahasiswa
        .split(' ')
        .where((String kata) => kata.isNotEmpty)
        .take(2)
        .map((String kata) => kata[0].toUpperCase())
        .join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    inisial,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppInfo.mahasiswa,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mahasiswa ${AppInfo.mataKuliah}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 12),
            _BarisInfo(label: 'NIM', nilai: AppInfo.nim, ikon: Icons.badge_outlined),
            _BarisInfo(
              label: 'Kelas',
              nilai: AppInfo.kelas,
              ikon: Icons.groups_outlined,
            ),
            _BarisInfo(
              label: 'Mata kuliah',
              nilai: AppInfo.mataKuliah,
              ikon: Icons.school_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu informasi aplikasi.
class _KartuAplikasi extends StatelessWidget {
  const _KartuAplikasi();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary,
                  child: Icon(
                    Icons.two_wheeler,
                    color: scheme.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppInfo.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${AppInfo.appTagline} · v${AppInfo.versi}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppInfo.deskripsi,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu daftar fitur utama.
class _KartuFitur extends StatelessWidget {
  const _KartuFitur();

  static const List<String> _fitur = <String>[
    'Kelola kendaraan: tambah, cari, filter, edit, dan hapus.',
    'Catat servis per komponen beserta biaya dan bengkel.',
    'Hitung sisa kilometer dan hari menuju servis berikutnya.',
    'Pengingat jatuh tempo pajak & STNK dan notifikasi lokal.',
    'Laporan pengeluaran servis dalam bentuk grafik bulanan.',
    'Katalog motor dan tips perawatan dari REST API.',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Fitur aplikasi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final String item in _fitur)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kartu teknologi, sumber data, dan tautan repositori.
class _KartuTeknis extends StatelessWidget {
  const _KartuTeknis();

  static const List<String> _teknologi = <String>[
    'Flutter',
    'Material 3',
    'Provider',
    'Supabase',
    'REST API',
    'fl_chart',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Teknologi & sumber data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String item in _teknologi)
                  StatusChip(
                    label: item,
                    color: scheme.primary,
                    dot: false,
                    kecil: true,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Database',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Supabase PostgreSQL · tabel vehicles & service_records',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Repositori',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(
              AppInfo.repo,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'REST API katalog',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(
              AppInfo.apiTips,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris label–nilai dengan ikon.
class _BarisInfo extends StatelessWidget {
  final String label;
  final String nilai;
  final IconData ikon;

  const _BarisInfo({
    required this.label,
    required this.nilai,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ikon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
