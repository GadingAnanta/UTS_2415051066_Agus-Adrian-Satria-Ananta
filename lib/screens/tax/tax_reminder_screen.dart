import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tax_reminder.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';

/// Halaman pengaturan tanggal jatuh tempo pajak tahunan & STNK 5 tahunan.
///
/// Sejak data pindah ke Supabase, tanggal jatuh tempo disimpan sebagai kolom
/// `tax_due_date` dan `stnk_due_date` pada tabel `vehicles`. Penyimpanan
/// dilakukan lewat [VehicleProvider] (Provider → Repository → Supabase),
/// lalu jadwal notifikasi H-30 dan H-7 disusun ulang otomatis.
class TaxReminderScreen extends StatefulWidget {
  final Vehicle vehicle;

  const TaxReminderScreen({super.key, required this.vehicle});

  @override
  State<TaxReminderScreen> createState() => _TaxReminderScreenState();
}

class _TaxReminderScreenState extends State<TaxReminderScreen> {
  bool _menyimpan = false;

  /// Kendaraan terbaru dari provider, supaya tanggal yang tampil selalu
  /// sama dengan data di database.
  Vehicle _kendaraan(BuildContext context) {
    return context.read<VehicleProvider>().vehicleById(widget.vehicle.id!) ??
        widget.vehicle;
  }

  void _pesan(String teks, {bool error = false}) {
    tampilkanPesan(context, teks, error: error);
  }

  Future<DateTime?> _pilihTanggal(DateTime? tanggalAwal) async {
    final DateTime hariIni = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: tanggalAwal ?? hariIni.add(const Duration(days: 30)),
      // Boleh memilih tanggal lampau (misalnya mengingat pajak yang terlewat).
      firstDate: DateTime(hariIni.year - 5),
      lastDate: DateTime(hariIni.year + 10, 12, 31),
      helpText: 'Pilih tanggal jatuh tempo',
      locale: const Locale('id', 'ID'),
    );
  }

  /// Menyimpan satu tanggal. [tipe] menentukan kolom mana yang diubah.
  Future<void> _simpan(TaxType tipe, DateTime? tanggal) async {
    final Vehicle kendaraan = _kendaraan(context);
    final VehicleProvider provider = context.read<VehicleProvider>();

    setState(() => _menyimpan = true);

    final bool berhasil = await provider.saveTaxDates(
      kendaraan.id!,
      taxDueDate: tipe == TaxType.pajakTahunan ? tanggal : kendaraan.taxDueDate,
      stnkDueDate: tipe == TaxType.stnkLimaTahunan ? tanggal : kendaraan.stnkDueDate,
    );

    if (!mounted) return;
    setState(() => _menyimpan = false);

    if (!berhasil) {
      _pesan(provider.errorMessage ?? 'Gagal menyimpan tanggal.', error: true);
      return;
    }

    if (tanggal == null) {
      _pesan('Tanggal ${tipe.label} dihapus.');
    } else if (!NotificationService.instance.siap) {
      _pesan('Tanggal disimpan. Notifikasi tidak tersedia di perangkat ini.');
    } else if (!await NotificationService.instance.izinAktif()) {
      _pesan('Tanggal disimpan. Aktifkan izin notifikasi agar pengingat muncul.');
    } else {
      _pesan('Pengingat ${tipe.label} disimpan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Vehicle kendaraan = context.watch<VehicleProvider>().vehicleById(widget.vehicle.id!) ??
        widget.vehicle;

    return Scaffold(
      appBar: AppBar(title: const Text('Pajak & STNK')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Text(
              'Atur tanggal jatuh tempo pajak tahunan dan STNK 5 tahunan. '
              'Aplikasi akan mengingatkan 30 hari dan 7 hari sebelumnya.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _KartuPajak(
              tipe: TaxType.pajakTahunan,
              tanggal: kendaraan.taxDueDate,
              menyimpan: _menyimpan,
              onPilihTanggal: _pilihTanggal,
              onSimpan: (DateTime? tanggal) => _simpan(TaxType.pajakTahunan, tanggal),
              onHapus: () => _simpan(TaxType.pajakTahunan, null),
            ),
            const SizedBox(height: 12),
            _KartuPajak(
              tipe: TaxType.stnkLimaTahunan,
              tanggal: kendaraan.stnkDueDate,
              menyimpan: _menyimpan,
              onPilihTanggal: _pilihTanggal,
              onSimpan: (DateTime? tanggal) => _simpan(TaxType.stnkLimaTahunan, tanggal),
              onHapus: () => _simpan(TaxType.stnkLimaTahunan, null),
            ),
            const SizedBox(height: 8),
            if (!NotificationService.instance.siap)
              _Catatan(
                ikon: Icons.notifications_off_outlined,
                teks: 'Notifikasi lokal tidak aktif di platform ini '
                    '(misalnya saat pratinjau di browser). Tanggal tetap '
                    'tersimpan dan pengingat dijadwalkan di perangkat Android.',
              )
            else
              _Catatan(
                ikon: Icons.schedule_outlined,
                teks: 'Pengingat dikirim pukul '
                    '${NotificationService.jamKirim.toString().padLeft(2, '0')}.00 '
                    'waktu ${NotificationService.zonaWaktu}.',
              ),
          ],
        ),
      ),
    );
  }
}

/// Satu kartu untuk satu jenis dokumen pajak.
class _KartuPajak extends StatelessWidget {
  final TaxType tipe;
  final DateTime? tanggal;
  final bool menyimpan;
  final Future<DateTime?> Function(DateTime? tanggalAwal) onPilihTanggal;
  final Future<void> Function(DateTime? tanggal) onSimpan;
  final VoidCallback onHapus;

  const _KartuPajak({
    required this.tipe,
    required this.tanggal,
    required this.menyimpan,
    required this.onPilihTanggal,
    required this.onSimpan,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final bool adaData = tanggal != null;
    final int? sisaHari = adaData ? daysFromToday(tanggal!) : null;
    final Color warnaStatus = sisaHari == null
        ? scheme.onSurfaceVariant
        : sisaHari < 0
            ? scheme.error
            : sisaHari <= 30
                ? const Color(0xFFEF6C00)
                : scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  tipe == TaxType.pajakTahunan
                      ? Icons.account_balance_outlined
                      : Icons.assignment_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tipe.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (adaData)
                  IconButton(
                    tooltip: 'Hapus tanggal',
                    onPressed: menyimpan ? null : onHapus,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: menyimpan
                  ? null
                  : () async {
                      final DateTime? hasil = await onPilihTanggal(tanggal);
                      if (hasil != null) await onSimpan(hasil);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.event_outlined, size: 20, color: warnaStatus),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            adaData ? 'Jatuh tempo' : 'Belum diatur',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            adaData
                                ? formatTanggal(tanggal!)
                                : 'Ketuk untuk memilih tanggal',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sisaHari != null)
                      Text(
                        sisaHari < 0 ? 'Lewat ${sisaHari.abs()} hari' : '$sisaHari hari lagi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: warnaStatus,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengingat otomatis: H-30 dan H-7 sebelum jatuh tempo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Catatan kecil berikon di bagian bawah halaman.
class _Catatan extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _Catatan({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ikon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teks,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
