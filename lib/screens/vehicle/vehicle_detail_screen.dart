import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_record.dart';
import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/service_record_tile.dart';
import '../../widgets/tax_due_card.dart';
import '../../widgets/vehicle_summary_card.dart';
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
              VehicleSummaryCard(vehicle: kendaraan),
              const SizedBox(height: 12),
              TaxDueCard(vehicle: kendaraan),
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
              SectionHeader(
                icon: Icons.receipt_long_outlined,
                title: 'Riwayat Servis',
                subtitle: '${riwayat.length} catatan servis',
                trailing: riwayat.isEmpty
                    ? null
                    : Text(
                        formatRupiah(
                          riwayat.fold<int>(
                            0,
                            (int total, ServiceRecord r) => total + r.cost,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // --- Kondisi: loading / error / kosong / berisi ---
              if (service.isLoading && riwayat.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dataKendaraanIni &&
                  service.errorMessage != null &&
                  riwayat.isEmpty)
                InfoBanner(
                  tone: BannerTone.bahaya,
                  judul: 'Riwayat gagal dimuat',
                  pesan: service.errorMessage!,
                  aksi: TextButton(
                    onPressed: () => service.loadForVehicle(kendaraan),
                    child: const Text('Coba lagi'),
                  ),
                )
              else if (riwayat.isEmpty)
                const InfoBanner(
                  pesan: 'Belum ada riwayat servis untuk kendaraan ini. '
                      'Tekan "Catat Servis" untuk menambah catatan pertama.',
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
