import 'package:flutter/material.dart';

import '../../models/tips_data.dart';
import '../../utils/constants.dart';

/// Tabel ringkas interval servis standar per komponen.
///
/// Dipakai di halaman Tips untuk membandingkan interval bawaan aplikasi
/// dengan data dari REST API.
class IntervalServisTable extends StatelessWidget {
  final List<IntervalServisStandar> interval;

  const IntervalServisTable({super.key, required this.interval});

  @override
  Widget build(BuildContext context) {
    if (interval.isEmpty) {
      return Text(
        'Belum ada data interval servis.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < interval.length; i++) ...<Widget>[
              if (i > 0)
                Divider(height: 1, indent: 56, color: scheme.outlineVariant),
              ListTile(
                dense: true,
                leading: Icon(
                  iconForComponent(interval[i].komponen),
                  color: scheme.primary,
                ),
                title: Text(
                  interval[i].nama.isEmpty
                      ? interval[i].komponen
                      : interval[i].nama,
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
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    interval[i].labelInterval,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
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
