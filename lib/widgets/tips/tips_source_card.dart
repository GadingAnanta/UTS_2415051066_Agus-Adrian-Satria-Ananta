import 'package:flutter/material.dart';

import '../../models/tips_data.dart';
import '../../utils/formatters.dart';

/// Kartu keterangan sumber data REST API (versi, tanggal, jumlah butir).
class TipsSourceCard extends StatelessWidget {
  final TipsData data;
  final bool sedangMemuat;

  const TipsSourceCard({
    super.key,
    required this.data,
    this.sedangMemuat = false,
  });

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
