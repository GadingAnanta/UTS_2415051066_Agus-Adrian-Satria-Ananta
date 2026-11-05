import 'package:flutter/material.dart';

import '../../models/tips_data.dart';

/// Kartu ringkas satu tips perawatan.
///
/// Isi lengkap (ringkasan + langkah) dibuka lewat lembar bawah supaya tinggi
/// kartu tetap rapi saat ditata dalam grid.
class TipsCard extends StatelessWidget {
  final TipsPerawatan tips;

  const TipsCard({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => tampilkanDetailTips(context, tips),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tips.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tips.ringkasan.isEmpty ? 'Ketuk untuk melihat langkah.' : tips.ringkasan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      tips.kategori,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tips.labelInterval,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lembar bawah berisi ringkasan dan langkah-langkah tips.
Future<void> tampilkanDetailTips(BuildContext context, TipsPerawatan tips) {
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
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tips.judul,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tips.kategori} · ${tips.labelInterval}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (tips.ringkasan.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    tips.ringkasan,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
                if (tips.langkah.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Langkah',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < tips.langkah.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${i + 1}.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tips.langkah[i],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
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
