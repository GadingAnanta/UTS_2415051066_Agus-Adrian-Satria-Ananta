import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vehicle_card.dart';
import '../tips/tips_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

/// Halaman daftar kendaraan: melihat, menambah, mengedit, dan menghapus motor.
class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  /// Buka form kendaraan. [vehicle] null berarti tambah baru.
  Future<void> _openForm(BuildContext context, {Vehicle? vehicle}) async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleFormScreen(vehicle: vehicle),
      ),
    );

    if (!context.mounted || berhasil != true) return;

    _showSnack(
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

  /// Buka halaman Katalog & Tips (data dari REST API).
  Future<void> _bukaTips(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TipsScreen()),
    );
  }

  /// Konfirmasi lalu hapus kendaraan.
  Future<void> _confirmDelete(BuildContext context, Vehicle vehicle) async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus kendaraan?'),
          content: Text(
            'Seluruh riwayat servis dan pengingat pajak untuk '
            '${vehicle.displayName} (${vehicle.plateNumber}) ikut terhapus '
            'dan tidak bisa dikembalikan.',
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

    if (setuju != true || !context.mounted) return;

    final VehicleProvider provider = context.read<VehicleProvider>();
    final bool berhasil = await provider.deleteVehicle(vehicle.id!);

    if (!context.mounted) return;

    _showSnack(
      context,
      berhasil
          ? 'Kendaraan "${vehicle.displayName}" dihapus.'
          : (provider.errorMessage ?? 'Gagal menghapus kendaraan.'),
      isError: !berhasil,
    );
  }

  void _showSnack(BuildContext context, String pesan, {bool isError = false}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendaraan Saya'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Katalog & Tips',
            onPressed: () => _bukaTips(context),
            icon: const Icon(Icons.menu_book_outlined),
          ),
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
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Data gagal dimuat',
                message: provider.errorMessage!,
                actionLabel: 'Coba lagi',
                onAction: provider.loadVehicles,
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

            // 4. Tampilkan daftar kendaraan.
            return RefreshIndicator(
              onRefresh: provider.loadVehicles,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.vehicles.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  // Item pertama adalah ringkasan jumlah kendaraan.
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${provider.vehicles.length} kendaraan terdaftar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final Vehicle vehicle = provider.vehicles[index - 1];
                  return VehicleCard(
                    vehicle: vehicle,
                    // Ketuk kartu = buka detail kendaraan (passing data).
                    onTap: () => _bukaDetail(context, vehicle),
                    onEdit: () => _openForm(context, vehicle: vehicle),
                    onDelete: () => _confirmDelete(context, vehicle),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
