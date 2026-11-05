import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/feedback.dart';
import '../../utils/responsive.dart';
import '../../utils/vehicle_filter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/vehicle_card.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

/// Halaman daftar kendaraan: melihat, mencari, memfilter, menambah,
/// mengedit, dan menghapus motor.
///
/// Bentuk interaksi yang tersedia:
/// 1. **Ketuk kartu** → membuka halaman detail (passing data).
/// 2. **Tekan lama kartu** → menu cepat (detail / edit / hapus).
/// 3. **Geser kartu ke kiri** → hapus dengan konfirmasi.
/// 4. **Tarik ke bawah** → muat ulang data (pull-to-refresh).
/// 5. **Cari & filter** → kata kunci dan chip filter (state bersama).
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final TextEditingController _cariController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pencarian disimpan di provider (shared state), jadi isi kolom
    // dikembalikan sesuai nilai terakhir saat halaman dibangun ulang.
    _cariController.text = context.read<VehicleProvider>().query;
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI
  // ---------------------------------------------------------------------------

  /// Buka form kendaraan. [vehicle] null berarti tambah baru.
  Future<void> _openForm(BuildContext context, {Vehicle? vehicle}) async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleFormScreen(vehicle: vehicle),
      ),
    );

    if (!context.mounted || berhasil != true) return;

    tampilkanPesan(
      context,
      vehicle == null
          ? 'Kendaraan berhasil ditambahkan.'
          : 'Perubahan kendaraan berhasil disimpan.',
    );
  }

  /// Buka detail kendaraan. Objek [vehicle] dikirim langsung dari daftar
  /// (passing data), lalu halaman detail memuat riwayat servisnya.
  Future<void> _bukaDetail(BuildContext context, Vehicle vehicle) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HAPUS
  // ---------------------------------------------------------------------------

  /// Minta konfirmasi lalu hapus kendaraan. Mengembalikan `true` bila terhapus.
  Future<bool> _hapus(BuildContext context, Vehicle vehicle) async {
    final bool setuju = await konfirmasiHapus(
      context,
      judul: 'Hapus kendaraan?',
      pesan: 'Seluruh riwayat servis dan pengingat pajak untuk '
          '${vehicle.displayName} (${vehicle.plateNumber}) ikut terhapus '
          'dan tidak bisa dikembalikan.',
    );

    if (!setuju || !context.mounted) return false;

    final VehicleProvider provider = context.read<VehicleProvider>();
    final bool berhasil = await provider.deleteVehicle(vehicle.id!);

    if (!context.mounted) return false;

    tampilkanPesan(
      context,
      berhasil
          ? 'Kendaraan "${vehicle.displayName}" dihapus.'
          : (provider.errorMessage ?? 'Gagal menghapus kendaraan.'),
      error: !berhasil,
    );

    return berhasil;
  }

  /// Dipakai Dismissible: selalu mengembalikan `false` karena daftar sudah
  /// diperbarui oleh provider setelah penghapusan berhasil.
  Future<bool> _swipeHapus(BuildContext context, Vehicle vehicle) async {
    await _hapus(context, vehicle);
    return false;
  }

  /// Menu cepat saat kartu ditekan lama.
  Future<void> _menuCepat(BuildContext context, Vehicle vehicle) async {
    final String? aksi = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.two_wheeler),
              title: Text(vehicle.displayName),
              subtitle: Text(vehicle.plateNumber),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Lihat detail'),
              onTap: () => Navigator.of(sheetContext).pop('detail'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit kendaraan'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus kendaraan'),
              onTap: () => Navigator.of(sheetContext).pop('hapus'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || aksi == null) return;

    switch (aksi) {
      case 'detail':
        await _bukaDetail(context, vehicle);
      case 'edit':
        await _openForm(context, vehicle: vehicle);
      case 'hapus':
        await _hapus(context, vehicle);
    }
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendaraan Saya'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => context.read<VehicleProvider>().loadVehicles(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Motor'),
      ),
      body: SafeArea(
        child: Consumer<VehicleProvider>(
          builder: (BuildContext context, VehicleProvider provider, _) {
            // 1. Sedang memuat data pertama kali.
            if (provider.isLoading && provider.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Gagal memuat dan belum ada data sama sekali.
            if (provider.errorMessage != null && provider.isEmpty) {
              return ErrorView(
                judul: 'Data gagal dimuat',
                pesan: provider.errorMessage!,
                onRetry: provider.loadVehicles,
              );
            }

            // 3. Belum ada kendaraan sama sekali.
            if (provider.isEmpty) {
              return EmptyState(
                icon: Icons.two_wheeler,
                title: 'Belum ada kendaraan',
                message:
                    'Tambahkan motor pertamamu supaya aplikasi bisa mengingatkan '
                    'jadwal servis dan pajak.',
                actionLabel: 'Tambah Motor',
                onAction: () => _openForm(context),
              );
            }

            // 4. Daftar kendaraan + pencarian & filter.
            return Column(
              children: <Widget>[
                _BilahPencarian(controller: _cariController, provider: provider),
                _BarisFilter(provider: provider),
                Expanded(
                  child: _DaftarKendaraan(
                    provider: provider,
                    onBukaDetail: (Vehicle v) => _bukaDetail(context, v),
                    onEdit: (Vehicle v) => _openForm(context, vehicle: v),
                    onHapus: (Vehicle v) => _hapus(context, v),
                    onSwipeHapus: (Vehicle v) => _swipeHapus(context, v),
                    onTekanLama: (Vehicle v) => _menuCepat(context, v),
                    onReset: () {
                      _cariController.clear();
                      provider.resetFilter();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kolom pencarian di atas daftar.
class _BilahPencarian extends StatelessWidget {
  final TextEditingController controller;
  final VehicleProvider provider;

  const _BilahPencarian({required this.controller, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: provider.setQuery,
        decoration: InputDecoration(
          hintText: 'Cari merek, model, atau plat nomor',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Bersihkan pencarian',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    provider.setQuery('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Deretan chip filter.
class _BarisFilter extends StatelessWidget {
  final VehicleProvider provider;

  const _BarisFilter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: <Widget>[
          for (final VehicleFilter item in VehicleFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(item.label),
                selected: provider.filter == item,
                onSelected: (_) => provider.setFilter(item),
              ),
            ),
          if (provider.hasActiveFilter)
            TextButton.icon(
              onPressed: provider.resetFilter,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Daftar kartu kendaraan, lengkap dengan empty state hasil filter.
class _DaftarKendaraan extends StatelessWidget {
  final VehicleProvider provider;
  final void Function(Vehicle) onBukaDetail;
  final void Function(Vehicle) onEdit;
  final void Function(Vehicle) onHapus;
  final Future<bool> Function(Vehicle) onSwipeHapus;
  final void Function(Vehicle) onTekanLama;

  /// Mengosongkan kolom pencarian sekaligus filter di provider.
  final VoidCallback onReset;

  const _DaftarKendaraan({
    required this.provider,
    required this.onBukaDetail,
    required this.onEdit,
    required this.onHapus,
    required this.onSwipeHapus,
    required this.onTekanLama,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Vehicle> hasil = provider.filteredVehicles;

    if (hasil.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ada kendaraan yang cocok',
        message: provider.query.trim().isEmpty
            ? 'Tidak ada kendaraan pada filter ini. Coba pilih filter lain.'
            : 'Tidak ada kendaraan yang cocok dengan "${provider.query.trim()}". '
                'Coba kata kunci lain atau reset pencarian.',
        actionLabel: 'Reset pencarian',
        actionIcon: Icons.filter_alt_off_outlined,
        onAction: onReset,
      );
    }

    final String teksRingkasan = provider.hasActiveFilter
        ? '${hasil.length} dari ${provider.vehicles.length} kendaraan'
        : '${provider.vehicles.length} kendaraan terdaftar';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints batas) {
        // < 600 px → daftar satu kolom; ≥ 600 px → grid 2–3 kolom.
        final int kolom = Responsive.kolom(batas.maxWidth, maks: 3);

        return RefreshIndicator(
          onRefresh: provider.loadVehicles,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    teksRingkasan,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (kolom == 1)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: hasil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) =>
                        _kartu(context, hasil[index]),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverGrid.builder(
                    itemCount: hasil.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: kolom,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 124,
                    ),
                    itemBuilder: (BuildContext context, int index) =>
                        _kartu(context, hasil[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Satu kartu kendaraan + gestur (ketuk, tekan lama, geser untuk hapus).
  Widget _kartu(BuildContext context, Vehicle vehicle) {
    return Dismissible(
      key: ValueKey<int?>(vehicle.id),
      direction: DismissDirection.endToStart,
      background: const _LatarHapus(),
      confirmDismiss: (_) => onSwipeHapus(vehicle),
      child: VehicleCard(
        vehicle: vehicle,
        // Ketuk kartu = buka detail kendaraan (passing data).
        onTap: () => onBukaDetail(vehicle),
        // Tekan lama = menu cepat (interaksi tambahan).
        onLongPress: () => onTekanLama(vehicle),
        onEdit: () => onEdit(vehicle),
        onDelete: () => onHapus(vehicle),
      ),
    );
  }
}

/// Latar merah saat kartu digeser untuk dihapus.
class _LatarHapus extends StatelessWidget {
  const _LatarHapus();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Text(
            'Hapus',
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
