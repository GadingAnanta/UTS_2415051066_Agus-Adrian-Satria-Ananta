import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_record.dart';
import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/service_record_tile.dart';
import '../dashboard/dashboard_screen.dart';
import '../service/service_form_screen.dart';
import 'vehicle_form_screen.dart';

/// Halaman detail satu kendaraan.
///
/// Data kendaraan **dikirim dari halaman daftar** lewat konstruktor
/// (`VehicleDetailScreen(vehicle: kendaraan)`), lalu halaman ini memuat
/// riwayat servisnya lewat [ServiceProvider].
///
/// Isi halaman:
/// 1. Identitas kendaraan (nama, plat, tahun, kilometer).
/// 2. Tanggal jatuh tempo pajak & STNK beserta sisa hari.
/// 3. Ringkasan jumlah catatan servis dan total biaya.
/// 4. Daftar riwayat servis (bisa diedit/dihapus dari sini).
class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  int get _vehicleId => widget.vehicle.id!;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ServiceProvider service = context.read<ServiceProvider>();
      // Muat ulang bila provider masih menyimpan data kendaraan lain.
      if (service.vehicleId != _vehicleId) {
        service.loadForVehicle(_kendaraanTerkini());
      }
      context.read<VehicleProvider>().selectVehicle(_vehicleId);
    });
  }

  /// Ambil data kendaraan terbaru dari provider (KM bisa berubah di halaman lain).
  Vehicle _kendaraanTerkini() {
    return context.read<VehicleProvider>().vehicleById(_vehicleId) ?? widget.vehicle;
  }

  void _pesan(String teks, {bool error = false}) {
    tampilkanPesan(context, teks, error: error);
  }

  /// Buka form edit dengan data kendaraan yang sedang tampil (sudah terisi).
  Future<void> _editKendaraan() async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleFormScreen(vehicle: _kendaraanTerkini()),
      ),
    );

    if (!mounted || berhasil != true) return;
    _pesan('Perubahan kendaraan berhasil disimpan.');
  }

  /// Konfirmasi lalu hapus kendaraan; kembali ke daftar bila berhasil.
  Future<void> _hapusKendaraan() async {
    final Vehicle kendaraan = _kendaraanTerkini();

    final bool setuju = await konfirmasiHapus(
      context,
      judul: 'Hapus kendaraan?',
      pesan: 'Seluruh riwayat servis dan pengingat pajak untuk '
          '${kendaraan.displayName} (${kendaraan.plateNumber}) ikut terhapus '
          'dan tidak bisa dikembalikan.',
    );

    if (!setuju || !mounted) return;

    final VehicleProvider provider = context.read<VehicleProvider>();
    final bool berhasil = await provider.deleteVehicle(kendaraan.id!);

    if (!mounted) return;

    if (!berhasil) {
      _pesan(provider.errorMessage ?? 'Gagal menghapus kendaraan.', error: true);
      return;
    }

    // SnackBar tetap tampil setelah halaman ini ditutup karena messenger
    // berada di atas Navigator.
    _pesan('Kendaraan "${kendaraan.displayName}" dihapus.');
    Navigator.of(context).pop();
  }

  Future<void> _bukaDashboard() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DashboardScreen(vehicle: _kendaraanTerkini()),
      ),
    );
  }

  Future<void> _catatServis({ServiceRecord? record, String? componentKey}) async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ServiceFormScreen(
          vehicle: _kendaraanTerkini(),
          record: record,
          initialComponentKey: componentKey,
        ),
      ),
    );

    if (!mounted || berhasil != true) return;
    _pesan(record == null
        ? 'Catatan servis berhasil ditambahkan.'
        : 'Catatan servis berhasil diperbarui.');
  }

  Future<void> _hapusServis(ServiceRecord record) async {
    final bool setuju = await konfirmasiHapus(
      context,
      judul: 'Hapus catatan servis?',
      pesan: 'Catatan servis tanggal ${formatTanggal(record.serviceDate)} akan '
          'dihapus dan status komponen ikut dihitung ulang.',
    );

    if (!setuju || !mounted) return;

    final ServiceProvider provider = context.read<ServiceProvider>();
    final bool berhasil = await provider.deleteRecord(record.id!);

    if (!mounted) return;
    _pesan(
      berhasil ? 'Catatan servis dihapus.' : (provider.errorMessage ?? 'Gagal menghapus.'),
      error: !berhasil,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Vehicle kendaraan =
        context.watch<VehicleProvider>().vehicleById(_vehicleId) ?? widget.vehicle;
    final ServiceProvider service = context.watch<ServiceProvider>();

    // Hanya tampilkan riwayat bila provider memang memuat kendaraan ini.
    final bool dataKendaraanIni = service.vehicleId == _vehicleId;
    final List<ServiceRecord> riwayat =
        dataKendaraanIni ? service.records : const <ServiceRecord>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kendaraan'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit kendaraan',
            onPressed: _editKendaraan,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Hapus kendaraan',
            onPressed: _hapusKendaraan,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Muat ulang riwayat',
            onPressed: () => service.loadForVehicle(kendaraan),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _catatServis(),
        icon: const Icon(Icons.add),
        label: const Text('Catat Servis'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => service.loadForVehicle(kendaraan),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              _KartuIdentitas(vehicle: kendaraan),
              const SizedBox(height: 12),
              _KartuPajak(vehicle: kendaraan),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _bukaDashboard,
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: const Text('Dashboard'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _catatServis(),
                      icon: const Icon(Icons.build_outlined, size: 18),
                      label: const Text('Catat Servis'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Ringkasan riwayat ---
              Row(
                children: <Widget>[
                  Icon(Icons.receipt_long_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat Servis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (riwayat.isNotEmpty)
                    Text(
                      formatRupiah(
                        riwayat.fold<int>(0, (int total, ServiceRecord r) => total + r.cost),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // --- Kondisi: loading / error / kosong / berisi ---
              if (service.isLoading && riwayat.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dataKendaraanIni && service.errorMessage != null && riwayat.isEmpty)
                _KotakPesan(
                  pesan: service.errorMessage!,
                  aksiLabel: 'Coba lagi',
                  onAksi: () => service.loadForVehicle(kendaraan),
                )
              else if (riwayat.isEmpty)
                const _KotakPesan(
                  pesan: 'Belum ada riwayat servis untuk kendaraan ini. '
                      'Tekan "Catat Servis" untuk menambah catatan pertama.',
                  ikon: Icons.info_outline,
                )
              else
                ...riwayat.map(
                  (ServiceRecord catatan) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceRecordTile(
                      record: catatan,
                      component: service.componentByKey(catatan.componentKey),
                      onEdit: () => _catatServis(record: catatan),
                      onDelete: () => _hapusServis(catatan),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu identitas kendaraan (data yang dikirim dari halaman daftar).
class _KartuIdentitas extends StatelessWidget {
  final Vehicle vehicle;

  const _KartuIdentitas({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.two_wheeler, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        vehicle.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.plateNumber} · ${vehicle.year}',
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
                Expanded(
                  child: _InfoKecil(
                    ikon: Icons.speed,
                    label: 'Kilometer',
                    nilai: formatKm(vehicle.currentKm),
                  ),
                ),
                Expanded(
                  child: _InfoKecil(
                    ikon: Icons.calendar_month_outlined,
                    label: 'Tahun',
                    nilai: vehicle.year.toString(),
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

/// Kartu tanggal jatuh tempo pajak & STNK.
class _KartuPajak extends StatelessWidget {
  final Vehicle vehicle;

  const _KartuPajak({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            _BarisPajak(
              ikon: Icons.account_balance_outlined,
              label: 'Pajak Tahunan',
              tanggal: vehicle.taxDueDate,
            ),
            _BarisPajak(
              ikon: Icons.assignment_outlined,
              label: 'STNK 5 Tahunan',
              tanggal: vehicle.stnkDueDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisPajak extends StatelessWidget {
  final IconData ikon;
  final String label;
  final DateTime? tanggal;

  const _BarisPajak({required this.ikon, required this.label, required this.tanggal});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final DateTime? jatuhTempo = tanggal;
    final int? sisaHari = jatuhTempo == null ? null : daysFromToday(jatuhTempo);
    final Color warna = sisaHari == null
        ? scheme.onSurfaceVariant
        : sisaHari < 0
            ? scheme.error
            : sisaHari <= 30
                ? const Color(0xFFEF6C00)
                : scheme.primary;

    return ListTile(
      dense: true,
      leading: Icon(ikon, color: scheme.primary),
      title: Text(label, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        jatuhTempo == null ? 'Belum diatur' : 'Jatuh tempo ${formatTanggal(jatuhTempo)}',
        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Text(
        sisaHari == null
            ? '-'
            : sisaHari < 0
                ? 'Lewat ${sisaHari.abs()} hari'
                : '$sisaHari hari',
        style: theme.textTheme.bodySmall?.copyWith(
          color: warna,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Dua baris info kecil (ikon, label, nilai).
class _InfoKecil extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;

  const _InfoKecil({required this.ikon, required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(ikon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              nilai,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kotak pesan (info / error) dengan aksi opsional.
class _KotakPesan extends StatelessWidget {
  final String pesan;
  final IconData ikon;
  final String? aksiLabel;
  final VoidCallback? onAksi;

  const _KotakPesan({
    required this.pesan,
    this.ikon = Icons.error_outline,
    this.aksiLabel,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warna = aksiLabel == null ? theme.colorScheme.primary : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warna.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ikon, size: 20, color: warna),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pesan,
              style: theme.textTheme.bodySmall?.copyWith(color: warna),
            ),
          ),
          if (aksiLabel != null && onAksi != null) ...<Widget>[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAksi,
              style: TextButton.styleFrom(foregroundColor: warna),
              child: Text(aksiLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
