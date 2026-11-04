import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
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

  /// Tanggal jatuh tempo pajak & STNK. Boleh kosong (diatur nanti dari
  /// halaman Pajak & STNK), tetapi bisa langsung diisi saat menambah motor.
  DateTime? _taxDue;
  DateTime? _stnkDue;

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
    _taxDue = kendaraan?.taxDueDate;
    _stnkDue = kendaraan?.stnkDueDate;
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

  /// Menampilkan pemilih tanggal untuk pajak tahunan atau STNK.
  Future<void> _pilihTanggal({required bool pajak}) async {
    final DateTime hariIni = DateTime.now();
    final DateTime? awal = pajak ? _taxDue : _stnkDue;

    final DateTime? dipilih = await showDatePicker(
      context: context,
      initialDate: awal ?? hariIni.add(const Duration(days: 30)),
      // Tanggal lampau diizinkan untuk mencatat pajak yang sudah terlewat.
      firstDate: DateTime(hariIni.year - 5),
      lastDate: DateTime(hariIni.year + 10, 12, 31),
      helpText: pajak ? 'Pilih jatuh tempo pajak' : 'Pilih jatuh tempo STNK',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      locale: const Locale('id', 'ID'),
    );

    if (dipilih == null || !mounted) return;

    setState(() {
      if (pajak) {
        _taxDue = dipilih;
      } else {
        _stnkDue = dipilih;
      }
    });
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
      taxDueDate: _taxDue,
      stnkDueDate: _stnkDue,
      createdAt: widget.vehicle?.createdAt ?? DateTime.now(),
    );

    final bool berhasil = await provider.saveVehicle(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (berhasil) {
      Navigator.of(context).pop(true);
    } else {
      tampilkanPesan(
        context,
        provider.errorMessage ?? 'Gagal menyimpan kendaraan.',
        error: true,
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
              const SizedBox(height: 24),

              // --- Pengingat pajak (opsional, bisa diubah kapan saja) ---
              const _SectionLabel(
                text: 'Pengingat pajak (opsional)',
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Isi tanggal jatuh tempo supaya aplikasi mengingatkan H-30 dan H-7. '
                'Boleh dikosongkan dan diatur nanti dari halaman Pajak & STNK.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              _PemilihTanggal(
                label: 'Jatuh tempo pajak tahunan',
                ikon: Icons.account_balance_outlined,
                tanggal: _taxDue,
                onPilih: () => _pilihTanggal(pajak: true),
                onHapus: () => setState(() => _taxDue = null),
              ),
              const SizedBox(height: 12),
              _PemilihTanggal(
                label: 'Jatuh tempo STNK 5 tahunan',
                ikon: Icons.assignment_outlined,
                tanggal: _stnkDue,
                onPilih: () => _pilihTanggal(pajak: false),
                onHapus: () => setState(() => _stnkDue = null),
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

/// Satu baris pemilih tanggal (pajak / STNK) yang bisa dikosongkan.
class _PemilihTanggal extends StatelessWidget {
  final String label;
  final IconData ikon;
  final DateTime? tanggal;
  final VoidCallback onPilih;
  final VoidCallback onHapus;

  const _PemilihTanggal({
    required this.label,
    required this.ikon,
    required this.tanggal,
    required this.onPilih,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onPilih,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(ikon),
          suffixIcon: tanggal == null
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  tooltip: 'Kosongkan tanggal',
                  icon: const Icon(Icons.close),
                  onPressed: onHapus,
                ),
        ),
        child: Text(
          tanggal == null ? 'Belum diatur' : formatTanggal(tanggal!),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: tanggal == null ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
