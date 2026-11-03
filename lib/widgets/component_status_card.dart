import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/service_calculator.dart';

/// Kartu status satu komponen di dashboard.
///
/// Menampilkan: nama komponen, interval servis, status berwarna
/// (hijau/kuning/merah/abu-abu), sisa kilometer, dan sisa hari menuju
/// servis berikutnya.
class ComponentStatusCard extends StatelessWidget {
  final ComponentServiceStatus status;

  /// Dipanggil saat kartu diketuk (membuka riwayat servis komponen ini).
  final VoidCallback? onTap;

  const ComponentStatusCard({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warnaStatus = colorForStatus(status.status);
    final bool belumAdaData = status.status == ServiceStatus.belumAdaData;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- Baris atas: ikon, nama, status ---
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: warnaStatus.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconForComponent(status.component.iconKey),
                      size: 22,
                      color: warnaStatus,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          status.component.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Interval ${status.component.intervalLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: status.status, color: warnaStatus),
                ],
              ),

              const SizedBox(height: 12),

              // --- Isi: angka sisa atau ajakan mencatat servis ---
              if (belumAdaData)
                Text(
                  'Belum pernah dicatat. Tambahkan servis pertama supaya sisa '
                  'KM dan hari bisa dihitung.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...<Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (status.remainingKm != null)
                      _InfoPill(
                        icon: Icons.speed,
                        label: _teksSisaKm(status.remainingKm!),
                        color: colorForStatus(status.kmStatus),
                      ),
                    if (status.remainingDays != null)
                      _InfoPill(
                        icon: Icons.event_outlined,
                        label: _teksSisaHari(status.remainingDays!),
                        color: colorForStatus(status.dayStatus),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _teksServisTerakhir(status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Contoh: `Sisa 1.500 km` atau `Lewat 320 km`.
  String _teksSisaKm(int sisa) {
    if (sisa < 0) return 'Lewat ${formatKm(sisa.abs())}';
    return 'Sisa ${formatKm(sisa)}';
  }

  /// Contoh: `45 hari lagi`, `Jatuh tempo hari ini`, `Lewat 3 hari`.
  String _teksSisaHari(int sisa) {
    if (sisa < 0) return 'Lewat ${sisa.abs()} hari';
    if (sisa == 0) return 'Jatuh tempo hari ini';
    return '$sisa hari lagi';
  }

  /// Contoh: `Terakhir: 12 Oktober 2026 · 12.500 km`.
  String _teksServisTerakhir(ComponentServiceStatus status) {
    final DateTime? tanggal = status.lastRecord?.serviceDate;
    final int? km = status.lastRecord?.kmAtService;
    if (tanggal == null || km == null) return 'Belum ada riwayat servis.';

    final StringBuffer teks = StringBuffer('Terakhir: ${formatTanggal(tanggal)}');
    teks.write(' · ${formatKm(km)}');
    if (status.nextServiceDate != null) {
      teks.write(' · jadwal berikutnya ${formatTanggalPendek(status.nextServiceDate!)}');
    }
    return teks.toString();
  }
}

/// Badge kecil berisi titik warna + label status.
class _StatusBadge extends StatelessWidget {
  final ServiceStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Kotak kecil berisi ikon + teks (dipakai untuk sisa KM dan sisa hari).
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
