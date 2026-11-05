import 'package:flutter/material.dart';

import '../../models/tips_data.dart';
import '../status_chip.dart';

/// Kartu satu motor pada katalog REST API.
///
/// Tinggi kartu dijaga tetap (dipakai di dalam `AdaptiveGrid`), karena itu
/// catatan panjang dipindah ke lembar detail yang terbuka saat kartu diketuk.
class KatalogMotorCard extends StatelessWidget {
  final KatalogMotor motor;

  const KatalogMotorCard({super.key, required this.motor});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => tampilkanDetailMotor(context, motor),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 19,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${motor.jenis} · ${motor.tahun}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  _Label(teks: motor.labelKapasitas),
                  if (motor.transmisi.isNotEmpty) _Label(teks: motor.transmisi),
                  if (motor.konsumsiBbm != null)
                    _Label(teks: '${motor.konsumsiBbm} km/L'),
                ],
              ),
              const Spacer(),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Lembar detail katalog: spesifikasi lengkap + catatan.
Future<void> tampilkanDetailMotor(BuildContext context, KatalogMotor motor) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme scheme = theme.colorScheme;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  motor.namaLengkap,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    StatusChip(
                      label: motor.jenis.isEmpty ? 'Motor' : motor.jenis,
                      color: scheme.primary,
                      dot: false,
                      icon: Icons.category_outlined,
                      kecil: true,
                    ),
                    StatusChip(
                      label: '${motor.tahun}',
                      color: scheme.secondary,
                      dot: false,
                      icon: Icons.event_outlined,
                      kecil: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BarisDetail(label: 'Kapasitas mesin', nilai: motor.labelKapasitas),
                _BarisDetail(
                  label: 'Transmisi',
                  nilai: motor.transmisi.isEmpty ? '-' : motor.transmisi,
                ),
                _BarisDetail(
                  label: 'Konsumsi BBM',
                  nilai: motor.konsumsiBbm == null
                      ? '-'
                      : '${motor.konsumsiBbm} km/L',
                ),
                _BarisDetail(
                  label: 'Rekomendasi oli',
                  nilai: motor.rekomendasiOli.isEmpty
                      ? '-'
                      : motor.rekomendasiOli,
                ),
                _BarisDetail(label: 'Interval servis', nilai: motor.labelInterval),
                if (motor.catatan.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Catatan',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    motor.catatan,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Chip kecil untuk spesifikasi motor.
class _Label extends StatelessWidget {
  final String teks;

  const _Label({required this.teks});

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

/// Baris label–nilai pada lembar detail.
class _BarisDetail extends StatelessWidget {
  final String label;
  final String nilai;

  const _BarisDetail({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
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
