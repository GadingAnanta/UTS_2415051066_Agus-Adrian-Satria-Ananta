import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../utils/service_calculator.dart';
import '../../widgets/component_status_card.dart';
import '../report/expense_chart_screen.dart';
import '../service/service_form_screen.dart';
import '../service/service_history_screen.dart';
import '../tax/tax_reminder_screen.dart';
import '../vehicle/update_km_screen.dart';

/// Beranda aplikasi: ringkasan satu kendaraan + status servis tiap komponen.
///
/// Semua angka dihitung di [ServiceProvider] memakai
/// `ServiceCalculator`, jadi halaman ini hanya menampilkan hasil.
class DashboardScreen extends StatefulWidget {
  final Vehicle vehicle;

  const DashboardScreen({super.key, required this.vehicle});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int get _vehicleId => widget.vehicle.id!;

  @override
  void initState() {
    super.initState();

    // Dimuat setelah frame pertama supaya notifyListeners() dari provider
    // tidak terjadi saat widget sedang dibangun.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ServiceProvider>().loadForVehicle(_kendaraanTerkini());
      if (!mounted) return;
      // Setiap kali dashboard dibuka, jadwal notifikasi disusun ulang agar
      // mengikuti tanggal servis dan jatuh tempo pajak yang paling baru.
      await _sinkronNotifikasi();
    });
  }

  /// Menyusun ulang seluruh jadwal notifikasi milik kendaraan ini.
  ///
  /// Dipanggil saat dashboard dibuka dan setelah data servis berubah.
  /// Kegagalan sinkronisasi tidak boleh mengganggu pemakaian aplikasi, jadi
  /// error-nya hanya dicatat di debug console.
  Future<void> _sinkronNotifikasi() async {
    final Vehicle kendaraan = _kendaraanTerkini();
    if (kendaraan.id == null) return;

    try {
      await NotificationService.instance.syncServiceReminders(
        vehicle: kendaraan,
        statuses: context.read<ServiceProvider>().statuses,
      );

      // Tanggal pajak & STNK kini tersimpan pada objek kendaraan.
      await NotificationService.instance.syncTaxReminders(kendaraan);
    } catch (e) {
      debugPrint('Gagal menyinkronkan notifikasi: $e');
    }
  }

  /// Ambil data kendaraan terbaru dari provider.
  ///
  /// Dipakai supaya KM yang tampil selalu angka terkini, bukan salinan lama
  /// yang dikirim lewat konstruktor.
  Vehicle _kendaraanTerkini() {
    return context.read<VehicleProvider>().vehicleById(_vehicleId) ?? widget.vehicle;
  }

  Future<void> _bukaUpdateKm() async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UpdateKmScreen(vehicle: _kendaraanTerkini()),
      ),
    );

    if (!mounted || berhasil != true) return;

    // Status servis harus dihitung ulang dengan kilometer baru.
    await context.read<ServiceProvider>().refresh();

    if (!mounted) return;
    _tampilkanPesan('Kilometer berhasil diperbarui.');

    // Kilometer baru bisa membuat komponen mendekati/lewat batas servis:
    // tampilkan notifikasi seketika (di Android).
    await _notifikasiKm();
  }

  /// Menampilkan notifikasi untuk komponen yang mendekati/lewat batas servis
  /// setelah kilometer kendaraan diperbarui.
  Future<void> _notifikasiKm() async {
    final ServiceProvider service = context.read<ServiceProvider>();
    final List<ComponentServiceStatus> perluPerhatian = service.statuses
        .where((ComponentServiceStatus item) => item.status.butuhPerhatian)
        .toList();

    if (perluPerhatian.isEmpty) return;

    final bool tampil = await NotificationService.instance.showKmWarning(
      vehicle: _kendaraanTerkini(),
      perluPerhatian: perluPerhatian,
    );

    if (!mounted) return;
    if (tampil) {
      _tampilkanPesan(
        'Notifikasi dikirim: ${perluPerhatian.length} komponen perlu servis.',
      );
    }
  }

  Future<void> _bukaPajak() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaxReminderScreen(vehicle: _kendaraanTerkini()),
      ),
    );

    if (!mounted) return;
    // Pengingat pajak bisa berubah dari halaman itu: sinkronkan ulang.
    await _sinkronNotifikasi();
  }

  Future<void> _bukaLaporan() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseChartScreen(vehicle: _kendaraanTerkini()),
      ),
    );
  }

  Future<void> _bukaRiwayat({String? componentKey}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ServiceHistoryScreen(
          vehicle: _kendaraanTerkini(),
          initialComponentKey: componentKey,
        ),
      ),
    );
  }

  Future<void> _catatServis({String? componentKey}) async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ServiceFormScreen(
          vehicle: _kendaraanTerkini(),
          initialComponentKey: componentKey,
        ),
      ),
    );

    if (!mounted || berhasil != true) return;
    _tampilkanPesan('Catatan servis berhasil ditambahkan.');

    // Tanggal servis berikutnya berubah → jadwal pengingat ikut diperbarui.
    await _sinkronNotifikasi();
  }

  void _tampilkanPesan(String pesan, {bool isError = false}) {
    tampilkanPesan(context, pesan, error: isError);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Vehicle kendaraan =
        context.watch<VehicleProvider>().vehicleById(_vehicleId) ?? widget.vehicle;
    final ServiceProvider service = context.watch<ServiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Riwayat servis',
            onPressed: () => _bukaRiwayat(),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: service.refresh,
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
          onRefresh: service.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              _KartuKendaraan(vehicle: kendaraan, onUpdateKm: _bukaUpdateKm),
              const SizedBox(height: 12),

              // Jalan pintas ke pengingat pajak dan laporan pengeluaran.
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _bukaPajak,
                      icon: const Icon(Icons.account_balance_outlined, size: 18),
                      label: const Text('Pajak & STNK'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _bukaLaporan,
                      icon: const Icon(Icons.insert_chart_outlined, size: 18),
                      label: const Text('Laporan Biaya'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (service.errorMessage != null) ...<Widget>[
                _KotakPesan(
                  pesan: service.errorMessage!,
                  warna: theme.colorScheme.error,
                  ikon: Icons.error_outline,
                  aksiLabel: 'Coba lagi',
                  onAksi: service.refresh,
                ),
                const SizedBox(height: 14),
              ],

              if (service.isLoading && service.statuses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (service.statuses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Belum ada komponen servis.')),
                )
              else ...<Widget>[
                _RingkasanStatus(provider: service),
                const SizedBox(height: 14),

                if (service.jumlahButuhPerhatian > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _KotakPesan(
                      pesan:
                          '${service.jumlahButuhPerhatian} komponen perlu segera '
                          'diservis. Ketuk kartunya untuk melihat riwayat.',
                      warna: colorForStatus(ServiceStatus.lewatBatas),
                      ikon: Icons.warning_amber_rounded,
                    ),
                  ),

                if (!service.hasRecords)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _KotakPesan(
                      pesan:
                          'Belum ada riwayat servis. Catat servis pertama agar '
                          'sisa KM dan sisa hari tiap komponen bisa dihitung.',
                      warna: theme.colorScheme.primary,
                      ikon: Icons.info_outline,
                      aksiLabel: 'Catat servis',
                      onAksi: () => _catatServis(),
                    ),
                  ),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Status Komponen',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${service.statuses.length} komponen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...service.statuses.map(
                  (ComponentServiceStatus item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ComponentStatusCard(
                      status: item,
                      onTap: () => _bukaRiwayat(componentKey: item.component.key),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu identitas kendaraan + tombol Update KM.
class _KartuKendaraan extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onUpdateKm;

  const _KartuKendaraan({required this.vehicle, required this.onUpdateKm});

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
                  radius: 24,
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
                        maxLines: 1,
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
            const SizedBox(height: 16),
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
                OutlinedButton.icon(
                  onPressed: onUpdateKm,
                  icon: const Icon(Icons.edit_road, size: 18),
                  label: const Text('Update KM'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiga angka ringkasan: aman, mendekati, lewat batas.
class _RingkasanStatus extends StatelessWidget {
  final ServiceProvider provider;

  const _RingkasanStatus({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _StatItem(
                jumlah: provider.jumlahAman,
                label: 'Aman',
                status: ServiceStatus.aman,
              ),
            ),
            Expanded(
              child: _StatItem(
                jumlah: provider.jumlahMendekati,
                label: 'Mendekati',
                status: ServiceStatus.mendekati,
              ),
            ),
            Expanded(
              child: _StatItem(
                jumlah: provider.jumlahLewatBatas,
                label: 'Lewat batas',
                status: ServiceStatus.lewatBatas,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int jumlah;
  final String label;
  final ServiceStatus status;

  const _StatItem({
    required this.jumlah,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warna = colorForStatus(status);

    return Column(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: warna.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$jumlah',
            style: theme.textTheme.titleMedium?.copyWith(
              color: warna,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Kotak pesan berwarna (info / peringatan / error).
class _KotakPesan extends StatelessWidget {
  final String pesan;
  final Color warna;
  final IconData ikon;
  final String? aksiLabel;
  final VoidCallback? onAksi;

  const _KotakPesan({
    required this.pesan,
    required this.warna,
    required this.ikon,
    this.aksiLabel,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
