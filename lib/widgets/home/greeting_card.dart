import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// Kartu sapaan di bagian atas Beranda.
class GreetingCard extends StatelessWidget {
  final int jumlahKendaraan;

  const GreetingCard({super.key, required this.jumlahKendaraan});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String namaDepan = AppInfo.mahasiswa.split(' ').first;

    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Halo, $namaDepan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jumlahKendaraan == 0
                        ? 'Belum ada kendaraan. Yuk mulai catat servis pertamamu.'
                        : '${AppInfo.appTagline}. $jumlahKendaraan kendaraan '
                            'terpantau hari ini.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary,
              child: Icon(Icons.two_wheeler, size: 30, color: scheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
