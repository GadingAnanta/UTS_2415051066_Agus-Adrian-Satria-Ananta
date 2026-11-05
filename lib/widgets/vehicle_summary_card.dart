import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../utils/formatters.dart';

/// Kartu identitas kendaraan + kilometer terkini.
///
/// Dipakai di dashboard kendaraan dan di Beranda (ringkasan kendaraan).
class VehicleSummaryCard extends StatelessWidget {
  final Vehicle vehicle;

  /// Tombol "Update KM"; `null` menyembunyikan tombol (mis. di Beranda).
  final VoidCallback? onUpdateKm;

  /// Ketuk kartu untuk membuka detail kendaraan.
  final VoidCallback? onTap;

  const VehicleSummaryCard({
    super.key,
    required this.vehicle,
    this.onUpdateKm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.two_wheeler,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          vehicle.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.plateNumber} · ${vehicle.year}',
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
              const SizedBox(height: 14),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(Icons.speed, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kilometer saat ini',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          formatKm(vehicle.currentKm),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onUpdateKm != null)
                    Flexible(
                      child: OutlinedButton.icon(
                        onPressed: onUpdateKm,
                        icon: const Icon(Icons.edit_road, size: 18),
                        label: const Text(
                          'Update KM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
