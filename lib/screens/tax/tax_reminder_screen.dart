import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tax_reminder.dart';
import '../../models/vehicle.dart';
import '../../providers/tax_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/formatters.dart';

/// Halaman pengaturan pengingat pajak tahunan & STNK 5 tahunan.
///
/// Tiap jenis dokumen punya satu tanggal jatuh tempo dan dua pilihan
/// pengingat: H-30 dan H-7. Setelah disimpan, jadwal notifikasi langsung
/// disusun ulang oleh [TaxProvider] lewat `NotificationService`.
class TaxReminderScreen extends StatefulWidget {
  final Vehicle vehicle;

  const TaxReminderScreen({super.key, required this.vehicle});

  @override
  State<TaxReminderScreen> createState() => _TaxReminderScreenState();
}

class _TaxReminderScreenState extends State<TaxReminderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaxProvider>().loadForVehicle(widget.vehicle);
    });
  }

  void _pesan(String teks, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Memilih tanggal jatuh tempo. Mengembalikan `null` bila dibatalkan.
  Future<DateTime?> _pilihTanggal(DateTime? tanggalAwal) async {
    final DateTime hariIni = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: tanggalAwal ?? hariIni.add(const Duration(days: 30)),
      // Boleh memilih tanggal lampau (misalnya mengingat pajak yang terlewat).
      firstDate: DateTime(hariIni.year - 5),
      lastDate: DateTime(hariIni.year + 10, 12, 31),
      helpText: 'Pilih tanggal jatuh tempo',
    );
  }

  Future<void> _simpan(TaxReminder reminder) async {
    final TaxProvider provider = context.read<TaxProvider>();
    final bool berhasil = await provider.saveReminder(reminder);

    if (!mounted) return;

    if (!berhasil) {
      _pesan(provider.error ?? 'Gagal menyimpan pengingat.', error: true);
      return;
    }

    // Beri tahu pengguna bila notifikasi tidak akan muncul karena izin.
    if (!NotificationService.instance.siap) {
      _pesan('Pengingat disimpan, tetapi notifikasi tidak tersedia di perangkat ini.');
    } else if (!await NotificationService.instance.izinAktif()) {
      _pesan('Pengingat disimpan. Aktifkan izin notifikasi agar pengingat muncul.');
    } else {
      _pesan('Pengingat ${reminder.type.label} disimpan.');
    }
  }

  Future<void> _hapus(TaxType tipe) async {
    final bool berhasil = await context.read<TaxProvider>().deleteReminder(tipe);
    if (!mounted) return;
    _pesan(
      berhasil ? 'Pengingat ${tipe.label} dihapus.' : 'Gagal menghapus pengingat.',
      error: !berhasil,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaxProvider provider = context.watch<TaxProvider>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pajak & STNK')),
      body: SafeArea(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
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
                  ...TaxType.values.map(
                    (TaxType tipe) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _KartuPajak(
                        // Key ikut berubah saat data berubah supaya draft
                        // (tanggal & switch) ikut diperbarui dari database.
                        key: ValueKey<String>(
                          '${tipe.value}-${provider.reminderFor(tipe)?.dueDate.toIso8601String() ?? 'kosong'}',
                        ),
                        tipe: tipe,
                        vehicleId: widget.vehicle.id!,
                        reminder: provider.reminderFor(tipe),
                        onPilihTanggal: _pilihTanggal,
                        onSimpan: _simpan,
                        onHapus: () => _hapus(tipe),
                      ),
                    ),
                  ),
                  if (!NotificationService.instance.siap)
                    _Catatan(
                      ikon: Icons.notifications_off_outlined,
                      teks:
                          'Notifikasi lokal tidak aktif di platform ini '
                          '(misalnya saat pratinjau di browser). Pengingat tetap '
                          'tersimpan dan akan dijadwalkan di perangkat Android.',
                    )
                  else
                    _Catatan(
                      ikon: Icons.schedule_outlined,
                      teks:
                          'Pengingat dikirim pukul '
                          '${NotificationService.jamKirim.toString().padLeft(2, '0')}.00 '
                          'waktu ${NotificationService.zonaWaktu}.',
                    ),
                ],
              ),
      ),
    );
  }
}

/// Satu kartu pengingat untuk satu jenis dokumen.
class _KartuPajak extends StatefulWidget {
  final TaxType tipe;
  final int vehicleId;
  final TaxReminder? reminder;
  final Future<DateTime?> Function(DateTime? tanggalAwal) onPilihTanggal;
  final Future<void> Function(TaxReminder reminder) onSimpan;
  final VoidCallback onHapus;

  const _KartuPajak({
    super.key,
    required this.tipe,
    required this.vehicleId,
    required this.reminder,
    required this.onPilihTanggal,
    required this.onSimpan,
    required this.onHapus,
  });

  @override
  State<_KartuPajak> createState() => _KartuPajakState();
}

class _KartuPajakState extends State<_KartuPajak> {
  DateTime? _tanggal;
  bool _h30 = true;
  bool _h7 = true;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _tanggal = widget.reminder?.dueDate;
    _h30 = widget.reminder?.notifyH30 ?? true;
    _h7 = widget.reminder?.notifyH7 ?? true;
  }

  Future<void> _pilih() async {
    final DateTime? hasil = await widget.onPilihTanggal(_tanggal);
    if (hasil == null || !mounted) return;
    setState(() => _tanggal = hasil);
  }

  Future<void> _simpan() async {
    final DateTime? tanggal = _tanggal;
    if (tanggal == null) return;

    setState(() => _menyimpan = true);
    await widget.onSimpan(
      TaxReminder(
        id: widget.reminder?.id,
        vehicleId: widget.vehicleId,
        type: widget.tipe,
        dueDate: tanggal,
        notifyH30: _h30,
        notifyH7: _h7,
      ),
    );
    if (mounted) setState(() => _menyimpan = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final DateTime? tanggal = _tanggal;

    final bool adaData = tanggal != null;
    final int? sisaHari = adaData ? daysFromToday(tanggal) : null;
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
                  widget.tipe == TaxType.pajakTahunan
                      ? Icons.account_balance_outlined
                      : Icons.assignment_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.tipe.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (adaData)
                  IconButton(
                    tooltip: 'Hapus pengingat',
                    onPressed: widget.onHapus,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pilih,
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
                            adaData ? formatTanggal(tanggal) : 'Ketuk untuk memilih tanggal',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sisaHari != null)
                      Text(
                        sisaHari < 0
                            ? 'Lewat ${sisaHari.abs()} hari'
                            : '$sisaHari hari lagi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: warnaStatus,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _h30,
              onChanged: (bool nilai) => setState(() => _h30 = nilai),
              title: const Text('Ingatkan 30 hari sebelumnya (H-30)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _h7,
              onChanged: (bool nilai) => setState(() => _h7 = nilai),
              title: const Text('Ingatkan 7 hari sebelumnya (H-7)'),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (adaData && !_menyimpan) ? _simpan : null,
                icon: _menyimpan
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Simpan Pengingat'),
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
