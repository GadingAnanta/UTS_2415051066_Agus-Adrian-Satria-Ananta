import 'package:flutter/material.dart';

/// Satu angka ringkasan beserta warna & ikonnya.
class StatusSummaryItem {
  final int jumlah;
  final String label;
  final Color color;
  final IconData? icon;

  const StatusSummaryItem({
    required this.jumlah,
    required this.label,
    required this.color,
    this.icon,
  });
}

/// Deretan angka ringkasan dalam satu kartu (aman / mendekati / lewat batas,
/// atau jumlah kendaraan / pajak dekat / belum diatur).
class StatusSummaryRow extends StatelessWidget {
  final List<StatusSummaryItem> items;

  const StatusSummaryRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0)
                Container(
                  width: 1,
                  height: 42,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              Expanded(child: _ItemAngka(item: items[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemAngka extends StatelessWidget {
  final StatusSummaryItem item;

  const _ItemAngka({required this.item});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (item.icon != null) ...<Widget>[
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 4),
            ],
            Text(
              '${item.jumlah}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: item.color,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
