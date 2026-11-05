import 'package:flutter/material.dart';

/// Label status ringkas: titik warna + teks, dibungkus pill.
///
/// Dipakai di kartu komponen, ringkasan pajak, dan daftar perhatian supaya
/// penanda status selalu tampil seragam.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  /// Tampilkan titik warna di depan teks.
  final bool dot;

  /// Ikon opsional, menggantikan titik warna.
  final IconData? icon;

  /// Versi kecil dipakai di dalam baris yang sempit.
  final bool kecil;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.dot = true,
    this.icon,
    this.kecil = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? gaya = (kecil
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(color: color, fontWeight: FontWeight.w700);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kecil ? 8 : 10,
        vertical: kecil ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null)
            Icon(icon, size: kecil ? 12 : 14, color: color)
          else if (dot)
            Container(
              width: kecil ? 6 : 8,
              height: kecil ? 6 : 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gaya,
            ),
          ),
        ],
      ),
    );
  }
}
