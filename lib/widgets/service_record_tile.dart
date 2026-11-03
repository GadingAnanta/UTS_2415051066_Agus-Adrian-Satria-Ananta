import 'package:flutter/material.dart';

import '../models/component_interval.dart';
import '../models/service_record.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Satu baris catatan servis di halaman riwayat servis.
class ServiceRecordTile extends StatelessWidget {
  final ServiceRecord record;

  /// Data komponen untuk menampilkan nama & ikon (bukan kunci mentah).
  final ComponentInterval? component;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServiceRecordTile({
    super.key,
    required this.record,
    required this.component,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String namaKomponen = component?.name ?? record.componentKey;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                iconForComponent(component?.iconKey ?? 'lainnya'),
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    namaKomponen,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatTanggal(record.serviceDate)} · ${formatKm(record.kmAtService)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(record.cost),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((record.workshopName ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(Icons.store_outlined, size: 13, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.workshopName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((record.note ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      record.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu catatan servis',
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'hapus') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'hapus',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
