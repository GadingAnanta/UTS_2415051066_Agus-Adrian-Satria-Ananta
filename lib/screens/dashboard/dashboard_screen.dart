import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/feedback.dart';
import '../../utils/service_calculator.dart';
import '../../widgets/component_status_card.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_summary_row.dart';
import '../../widgets/vehicle_summary_card.dart';
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
              VehicleSummaryCard(
                vehicle: kendaraan,
                onUpdateKm: _bukaUpdateKm,
              ),
              const SizedBox(height: 12),

              // Jalan pintas ke pengingat pajak dan laporan pengeluaran.
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _bukaPajak,
                    icon: const Icon(Icons.account_balance_outlined, size: 18),
                    label: const Text('Pajak & STNK'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _bukaLaporan,
                    icon: const Icon(Icons.insert_chart_outlined, size: 18),
                    label: const Text('Laporan Biaya'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (service.errorMessage != null) ...<Widget>[
                InfoBanner(
                  tone: BannerTone.bahaya,
                  judul: 'Gagal memuat status servis',
                  pesan: service.errorMessage!,
                  aksi: TextButton(
                    onPressed: service.refresh,
                    child: const Text('Coba lagi'),
                  ),
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
                StatusSummaryRow(
                  items: <StatusSummaryItem>[
                    StatusSummaryItem(
                      jumlah: service.jumlahAman,
                      label: 'Aman',
                      color: AppColors.aman,
                    ),
                    StatusSummaryItem(
                      jumlah: service.jumlahMendekati,
                      label: 'Mendekati',
                      color: AppColors.mendekati,
                    ),
                    StatusSummaryItem(
                      jumlah: service.jumlahLewatBatas,
                      label: 'Lewat batas',
                      color: AppColors.lewatBatas,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (service.jumlahButuhPerhatian > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InfoBanner(
                      tone: BannerTone.peringatan,
                      pesan:
                          '${service.jumlahButuhPerhatian} komponen perlu segera '
                          'diservis. Ketuk kartunya untuk melihat riwayat.',
                    ),
                  ),

                if (!service.hasRecords)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InfoBanner(
                      pesan:
                          'Belum ada riwayat servis. Catat servis pertama agar '
                          'sisa KM dan sisa hari tiap komponen bisa dihitung.',
                      aksi: FilledButton.tonalIcon(
                        onPressed: () => _catatServis(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Catat servis'),
                      ),
                    ),
                  ),

                SectionHeader(
                  icon: Icons.tune,
                  title: 'Status Komponen',
                  subtitle: '${service.statuses.length} komponen dipantau',
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
