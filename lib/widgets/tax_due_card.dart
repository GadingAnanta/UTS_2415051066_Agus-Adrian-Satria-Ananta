import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

/// Kartu dua baris jatuh tempo: pajak tahunan dan STNK 5 tahunan.
///
/// Warna chip mengikuti sisa hari:
/// merah = sudah lewat / ≤ 7 hari, kuning = ≤ 30 hari, hijau = masih jauh.
class TaxDueCard extends StatelessWidget {
  final Vehicle vehicle;

  const TaxDueCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            _BarisJatuhTempo(
              ikon: Icons.account_balance_outlined,
              label: 'Pajak Tahunan',
              tanggal: vehicle.taxDueDate,
            ),
            _BarisJatuhTempo(
              ikon: Icons.assignment_outlined,
              label: 'STNK 5 Tahunan',
              tanggal: vehicle.stnkDueDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisJatuhTempo extends StatelessWidget {
  final IconData ikon;
  final String label;
  final DateTime? tanggal;

  const _BarisJatuhTempo({
    required this.ikon,
    required this.label,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final DateTime? jatuhTempo = tanggal;
    final int? sisaHari = jatuhTempo == null ? null : daysFromToday(jatuhTempo);

    final Color warna;
    final String teksSisa;
    if (sisaHari == null) {
      warna = scheme.onSurfaceVariant;
      teksSisa = 'Belum diatur';
    } else if (sisaHari < 0) {
      warna = AppColors.lewatBatas;
      teksSisa = 'Lewat ${sisaHari.abs()} hari';
    } else if (sisaHari <= 7) {
      warna = AppColors.lewatBatas;
      teksSisa = sisaHari == 0 ? 'Hari ini' : '$sisaHari hari lagi';
    } else if (sisaHari <= 30) {
      warna = AppColors.mendekati;
      teksSisa = '$sisaHari hari lagi';
    } else {
      warna = AppColors.aman;
      teksSisa = '$sisaHari hari lagi';
    }

    return ListTile(
      dense: true,
      leading: Icon(ikon, color: scheme.primary),
      title: Text(label, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        jatuhTempo == null
            ? 'Belum diatur'
            : 'Jatuh tempo ${formatTanggal(jatuhTempo)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Align(
          alignment: Alignment.centerRight,
          child: StatusChip(
            label: teksSisa,
            color: warna,
            dot: false,
            kecil: true,
          ),
        ),
      ),
    );
  }
}
