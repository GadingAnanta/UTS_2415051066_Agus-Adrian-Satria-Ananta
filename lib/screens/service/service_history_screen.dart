import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/component_interval.dart';
import '../../models/service_record.dart';
import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/service_record_tile.dart';
import 'service_form_screen.dart';

/// Halaman riwayat servis satu kendaraan.
///
/// Menampilkan seluruh catatan servis (terbaru di atas), bisa difilter per
/// komponen, serta menjadi pintu masuk untuk menambah, mengedit, dan menghapus
/// catatan servis.
class ServiceHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  /// Bila diisi, halaman langsung menampilkan filter komponen tersebut
  /// (dipakai saat kartu komponen di dashboard diketuk).
  final String? initialComponentKey;

  const ServiceHistoryScreen({
    super.key,
    required this.vehicle,
    this.initialComponentKey,
  });

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  /// `null` berarti filter "Semua".
  String? _filterKey;

  @override
  void initState() {
    super.initState();
    _filterKey = widget.initialComponentKey;

    // Pastikan data yang dimuat memang milik kendaraan ini.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ServiceProvider provider = context.read<ServiceProvider>();
      if (provider.vehicleId != widget.vehicle.id) {
        provider.loadForVehicle(widget.vehicle);
      }
    });
  }

  /// Buka form catat servis (tambah atau edit).
  Future<void> _bukaForm({ServiceRecord? catatan}) async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ServiceFormScreen(
          vehicle: widget.vehicle,
          record: catatan,
          initialComponentKey: catatan == null ? _filterKey : null,
        ),
      ),
    );

    if (!mounted || berhasil != true) return;

    _tampilkanPesan(
      catatan == null
          ? 'Catatan servis berhasil ditambahkan.'
          : 'Perubahan catatan servis berhasil disimpan.',
    );
  }

  /// Konfirmasi lalu hapus satu catatan servis.
  Future<void> _konfirmasiHapus(ServiceRecord catatan) async {
    final ServiceProvider provider = context.read<ServiceProvider>();
    final String nama = provider.componentName(catatan.componentKey);

    final bool? setuju = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus catatan servis?'),
          content: Text(
            'Catatan $nama tanggal ${formatTanggal(catatan.serviceDate)} '
            '(${formatRupiah(catatan.cost)}) akan dihapus permanen.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (setuju != true || !mounted) return;

    final bool berhasil = await provider.deleteRecord(catatan.id!);
    if (!mounted) return;

    _tampilkanPesan(
      berhasil
          ? 'Catatan servis dihapus.'
          : (provider.errorMessage ?? 'Gagal menghapus catatan servis.'),
      isError: !berhasil,
    );
  }

  void _tampilkanPesan(String pesan, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Servis'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.vehicle.displayName} · ${widget.vehicle.plateNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Catat Servis'),
      ),
      body: SafeArea(
        child: Consumer<ServiceProvider>(
          builder: (BuildContext context, ServiceProvider provider, _) {
            if (provider.isLoading && provider.records.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.records.isEmpty) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Data gagal dimuat',
                message: provider.errorMessage!,
                actionLabel: 'Coba lagi',
                onAction: provider.refresh,
              );
            }

            if (provider.records.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada riwayat servis',
                message:
                    'Catat servis pertama (oli, kampas rem, dan lainnya) supaya '
                    'aplikasi bisa menghitung jadwal servis berikutnya.',
                actionLabel: 'Catat Servis',
                onAction: () => _bukaForm(),
              );
            }

            final List<ServiceRecord> daftar = _filterKey == null
                ? provider.records
                : provider.recordsForComponent(_filterKey!);

            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  _RingkasanServis(records: provider.records),
                  const SizedBox(height: 16),
                  _FilterKomponen(
                    provider: provider,
                    terpilih: _filterKey,
                    onPilih: (String? key) => setState(() => _filterKey = key),
                  ),
                  const SizedBox(height: 12),
                  if (daftar.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Belum ada servis untuk komponen ini.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...daftar.map(
                      (ServiceRecord catatan) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ServiceRecordTile(
                          record: catatan,
                          component: provider.componentByKey(catatan.componentKey),
                          onEdit: () => _bukaForm(catatan: catatan),
                          onDelete: () => _konfirmasiHapus(catatan),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Kartu ringkasan: jumlah servis & total biaya.
class _RingkasanServis extends StatelessWidget {
  final List<ServiceRecord> records;

  const _RingkasanServis({required this.records});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int totalBiaya =
        records.fold<int>(0, (int total, ServiceRecord item) => total + item.cost);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Angka(
                label: 'Total servis',
                value: '${records.length}x',
                icon: Icons.receipt_long_outlined,
              ),
            ),
            Container(width: 1, height: 40, color: scheme.outlineVariant),
            Expanded(
              child: _Angka(
                label: 'Total biaya',
                value: formatRupiah(totalBiaya),
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Angka({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Deretan chip filter komponen. Hanya komponen yang punya catatan yang tampil.
class _FilterKomponen extends StatelessWidget {
  final ServiceProvider provider;
  final String? terpilih;
  final ValueChanged<String?> onPilih;

  const _FilterKomponen({
    required this.provider,
    required this.terpilih,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    // Urutkan komponen sesuai daftar komponen, bukan urutan kemunculan catatan.
    final List<ComponentInterval> dipakai = provider.components
        .where((ComponentInterval item) => provider.recordsForComponent(item.key).isNotEmpty)
        .toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Semua'),
              selected: terpilih == null,
              onSelected: (_) => onPilih(null),
            ),
          ),
          ...dipakai.map(
            (ComponentInterval item) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(item.name),
                selected: terpilih == item.key,
                onSelected: (_) => onPilih(item.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
