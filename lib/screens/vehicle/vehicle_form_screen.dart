import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/input_formatters.dart';
import '../../utils/validators.dart';

/// Form untuk menambah kendaraan baru atau mengedit kendaraan yang sudah ada.
///
/// Cara pakai:
/// - Tambah baru : `VehicleFormScreen()`
/// - Edit        : `VehicleFormScreen(vehicle: kendaraan)`
///
/// Halaman ini mengembalikan `true` lewat `Navigator.pop` bila penyimpanan
/// berhasil, sehingga halaman pemanggil bisa menampilkan SnackBar.
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _kmController;

  bool _isSaving = false;

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    // Isi form dengan data lama bila sedang mengedit.
    final Vehicle? kendaraan = widget.vehicle;
    _brandController = TextEditingController(text: kendaraan?.brand ?? '');
    _modelController = TextEditingController(text: kendaraan?.model ?? '');
    _yearController = TextEditingController(
      text: kendaraan == null ? '' : kendaraan.year.toString(),
    );
    _plateController = TextEditingController(text: kendaraan?.plateNumber ?? '');
    _kmController = TextEditingController(
      text: kendaraan == null ? '' : kendaraan.currentKm.toString(),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    // Tutup keyboard supaya SnackBar tidak tertutup.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final VehicleProvider provider = context.read<VehicleProvider>();
    final Vehicle data = Vehicle(
      id: widget.vehicle?.id,
      // Pemilik data: selama belum ada login, dipakai DEMO_USER_ID dari .env.
      userId: widget.vehicle?.userId ?? SupabaseService.instance.demoUserId,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      plateNumber: _plateController.text.trim().toUpperCase(),
      currentKm: int.parse(_kmController.text.trim()),
      taxDueDate: widget.vehicle?.taxDueDate,
      stnkDueDate: widget.vehicle?.stnkDueDate,
      createdAt: widget.vehicle?.createdAt ?? DateTime.now(),
    );

    final bool berhasil = await provider.saveVehicle(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (berhasil) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan kendaraan.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const _SectionLabel(
                text: 'Data kendaraan',
                icon: Icons.two_wheeler,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Merek',
                  hintText: 'Contoh: Honda',
                  prefixIcon: Icon(Icons.factory_outlined),
                ),
                validator: Validators.merek,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _modelController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tipe / Model',
                  hintText: 'Contoh: Vario 160',
                  prefixIcon: Icon(Icons.directions_bike_outlined),
                ),
                validator: Validators.tipe,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 4,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Tahun pembuatan',
                  hintText: 'Contoh: 2021',
                  prefixIcon: Icon(Icons.event_outlined),
                  counterText: '',
                ),
                validator: Validators.tahun,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                  const UpperCaseTextFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Plat nomor',
                  hintText: 'Contoh: B 1234 XYZ',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: Validators.platNomor,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Kilometer saat ini',
                  hintText: 'Contoh: 12500',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: (String? value) =>
                    Validators.kilometer(value, label: 'Kilometer'),
                onFieldSubmitted: (_) => _simpan(),
              ),
              const SizedBox(height: 24),
              Text(
                'Tip: catat kilometer sesuai angka di speedometer saat ini. '
                'Angka ini dipakai untuk menghitung sisa jarak ke servis berikutnya.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _simpan,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
          ),
        ),
      ),
    );
  }
}

/// Judul kecil di atas sekelompok field.
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
