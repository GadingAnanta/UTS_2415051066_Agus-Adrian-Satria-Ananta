import 'package:flutter/material.dart';

import '../../models/tax_reminder.dart';
import '../../models/vehicle.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../status_chip.dart';

/// Satu baris pengingat pajak/STNK: kendaraan + jenis + sisa hari.
typedef PengingatPajak = ({
  Vehicle vehicle,
  TaxType jenis,
  DateTime tanggal,
  int sisaHari,
});

/// Kartu pengingat jatuh tempo untuk Beranda.
///
/// Ketuk kartu untuk membuka detail kendaraan.
class ReminderCard extends StatelessWidget {
  final PengingatPajak pengingat;

  /// Ketuk kartu (mis. membuka detail kendaraan).
  final VoidCallback? onTap;

  const ReminderCard({super.key, required this.pengingat, this.onTap});

  Color get _warna {
    if (pengingat.sisaHari <= 7) return AppColors.lewatBatas;
    return AppColors.mendekati;
  }

  String get _labelSisa {
    final int sisa = pengingat.sisaHari;
    if (sisa < 0) return 'Lewat ${sisa.abs()} hari';
    if (sisa == 0) return 'Hari ini';
    return '$sisa hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Vehicle kendaraan = pengingat.vehicle;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  StatusChip(
                    label: pengingat.jenis == TaxType.pajakTahunan
                        ? 'Pajak'
                        : 'STNK',
                    color: _warna,
                    dot: false,
                    icon: pengingat.jenis == TaxType.pajakTahunan
                        ? Icons.account_balance_outlined
                        : Icons.badge_outlined,
                    kecil: true,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      _labelSisa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _warna,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                kendaraan.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${kendaraan.plateNumber} · '
                '${formatTanggalPendek(pengingat.tanggal)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
