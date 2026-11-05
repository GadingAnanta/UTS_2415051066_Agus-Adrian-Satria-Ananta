import 'package:flutter/material.dart';

/// Nada pesan pada [InfoBanner].
enum BannerTone { info, sukses, peringatan, bahaya }

/// Kotak pesan berwarna untuk keterangan, hasil aksi, atau peringatan.
///
/// Menggantikan kotak pesan buatan per halaman supaya warna dan bentuknya
/// konsisten di seluruh aplikasi.
class InfoBanner extends StatelessWidget {
  final String pesan;
  final String? judul;
  final BannerTone tone;
  final IconData? icon;
  final Widget? aksi;

  const InfoBanner({
    super.key,
    required this.pesan,
    this.judul,
    this.tone = BannerTone.info,
    this.icon,
    this.aksi,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warna = _warna(theme.colorScheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warna.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon ?? _ikonBawaan, size: 20, color: warna),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (judul != null) ...<Widget>[
                  Text(
                    judul!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: warna,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  pesan,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (aksi != null) ...<Widget>[
                  const SizedBox(height: 8),
                  aksi!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _warna(ColorScheme skema) {
    switch (tone) {
      case BannerTone.sukses:
        return const Color(0xFF2E7D32);
      case BannerTone.peringatan:
        return const Color(0xFFF9A825);
      case BannerTone.bahaya:
        return skema.error;
      case BannerTone.info:
        return skema.primary;
    }
  }

  IconData get _ikonBawaan {
    switch (tone) {
      case BannerTone.sukses:
        return Icons.check_circle_outline;
      case BannerTone.peringatan:
        return Icons.warning_amber_rounded;
      case BannerTone.bahaya:
        return Icons.error_outline;
      case BannerTone.info:
        return Icons.info_outline;
    }
  }
}
