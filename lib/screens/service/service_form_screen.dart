import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/component_interval.dart';
import '../../models/service_record.dart';
import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/constants.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

/// Form untuk mencatat servis baru atau mengedit catatan servis lama.
///
/// Cara pakai:
/// - Tambah baru : `ServiceFormScreen(vehicle: kendaraan)`
/// - Tambah dengan komponen terpilih :
///   `ServiceFormScreen(vehicle: kendaraan, initialComponentKey: 'oli_mesin')`
/// - Edit        : `ServiceFormScreen(vehicle: kendaraan, record: catatan)`
///
/// Mengembalikan `true` lewat `Navigator.pop` bila penyimpanan berhasil.
class ServiceFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ServiceRecord? record;

  /// Komponen yang langsung terpilih saat form dibuka (opsional).
  final String? initialComponentKey;

  const ServiceFormScreen({
    super.key,
    required this.vehicle,
    this.record,
    this.initialComponentKey,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _kmController;
  final TextEditingController _biayaController = TextEditingController();
  final TextEditingController _bengkelController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _componentKey;
  late DateTime _tanggal;
  bool _isSaving = false;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();

    final ServiceRecord? catatan = widget.record;
    _componentKey = catatan?.componentKey ?? widget.initialComponentKey;
    _tanggal = catatan?.serviceDate ?? DateTime.now();
    _kmController = TextEditingController(
      // Default KM = KM kendaraan saat ini, karena servis biasanya dicatat
      // pada kilometer terkini.
      text: (catatan?.kmAtService ?? widget.vehicle.currentKm).toString(),
    );
    _biayaController.text = catatan == null ? '' : catatan.cost.toString();
    _bengkelController.text = catatan?.workshopName ?? '';
    _catatanController.text = catatan?.note ?? '';
  }

  @override
  void dispose() {
    _kmController.dispose();
    _biayaController.dispose();
    _bengkelController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  /// Menampilkan pemilih tanggal (tanggal servis tidak boleh di masa depan).
  Future<void> _pilihTanggal() async {
    final DateTime hariIni = DateTime.now();
    final DateTime? dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal.isAfter(hariIni) ? hariIni : _tanggal,
      firstDate: DateTime(2000),
      lastDate: hariIni,
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih tanggal servis',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (dipilih == null || !mounted) return;
    setState(() => _tanggal = dipilih);
  }

  /// Validasi tambahan: KM servis tidak boleh lebih kecil dari servis
  /// sebelumnya pada komponen yang sama.
  String? _validasiKm(String? value) {
    final String? dasar = Validators.kilometer(value, label: 'KM saat servis');
    if (dasar != null) return dasar;

    final String? key = _componentKey;
    if (key == null) return null;

    final int? kmTerakhir = context.read<ServiceProvider>().lastKmForComponent(key);
    if (kmTerakhir == null) return null;

    // Saat mengedit, KM milik catatan itu sendiri tidak dihitung sebagai batas.
    if (_isEdit && widget.record!.componentKey == key && widget.record!.kmAtService == kmTerakhir) {
      return null;
    }

    final int kmBaru = int.parse(value!.trim());
    if (kmBaru < kmTerakhir) {
      return 'KM tidak boleh lebih kecil dari servis sebelumnya '
          '(${formatKm(kmTerakhir)}).';
    }
    return null;
  }

  /// Validasi nama bengkel: boleh kosong, tetapi kalau diisi minimal 3 huruf.
  String? _validasiBengkel(String? value) {
    final String teks = (value ?? '').trim();
    if (teks.isEmpty) return null;
    if (teks.length < 3) return 'Nama bengkel minimal 3 karakter';
    return null;
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final ServiceProvider serviceProvider = context.read<ServiceProvider>();
    final VehicleProvider vehicleProvider = context.read<VehicleProvider>();

    final String bengkel = _bengkelController.text.trim();
    final String catatan = _catatanController.text.trim();
    final int km = int.parse(_kmController.text.trim());

    final ServiceRecord data = ServiceRecord(
      id: widget.record?.id,
      vehicleId: widget.vehicle.id!,
      componentKey: _componentKey!,
      serviceDate: _tanggal,
      kmAtService: km,
      cost: int.parse(_biayaController.text.trim()),
      workshopName: bengkel.isEmpty ? null : bengkel,
      note: catatan.isEmpty ? null : catatan,
      createdAt: widget.record?.createdAt ?? DateTime.now(),
    );

    final bool berhasil = await serviceProvider.saveRecord(data);

    // Kalau KM servis lebih tinggi dari KM kendaraan, sekalian perbarui
    // kilometer kendaraan supaya dashboard memakai angka terbaru.
    if (berhasil && km > widget.vehicle.currentKm) {
      await vehicleProvider.updateKm(widget.vehicle.id!, km);
      await serviceProvider.refresh();
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (berhasil) {
      Navigator.of(context).pop(true);
    } else {
      tampilkanPesan(
        context,
        serviceProvider.errorMessage ?? 'Gagal menyimpan catatan servis.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<ComponentInterval> komponen = context.watch<ServiceProvider>().components;

    // Pastikan nilai dropdown selalu ada di dalam daftar item.
    final bool keyValid = _componentKey != null &&
        komponen.any((ComponentInterval item) => item.key == _componentKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan Servis' : 'Catat Servis'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const _SectionLabel(text: 'Detail servis', icon: Icons.build_outlined),
              const SizedBox(height: 12),

              // --- Dropdown komponen ---
              DropdownButtonFormField<String>(
                initialValue: keyValid ? _componentKey : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Komponen',
                  prefixIcon: Icon(Icons.settings_suggest_outlined),
                ),
                hint: const Text('Pilih komponen yang diservis'),
                items: komponen
                    .map(
                      (ComponentInterval item) => DropdownMenuItem<String>(
                        value: item.key,
                        child: Row(
                          children: <Widget>[
                            Icon(iconForComponent(item.iconKey), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.name, overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              item.intervalLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  setState(() => _componentKey = value);
                  // Validasi ulang KM karena batas minimalnya ikut berubah.
                  _formKey.currentState?.validate();
                },
                validator: (String? value) =>
                    value == null ? 'Komponen wajib dipilih' : null,
              ),

              // Info servis terakhir untuk komponen terpilih.
              if (keyValid) ...<Widget>[
                const SizedBox(height: 8),
                _InfoTerakhir(
                  kmTerakhir: context.read<ServiceProvider>().lastKmForComponent(_componentKey!),
                  intervalLabel: komponen
                      .firstWhere((ComponentInterval item) => item.key == _componentKey)
                      .intervalLabel,
                ),
              ],

              const SizedBox(height: 14),

              // --- Tanggal servis ---
              // Memakai InputDecorator (bukan TextFormField) supaya tidak perlu
              // membuat TextEditingController baru setiap kali build.
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal servis',
                    prefixIcon: Icon(Icons.event_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    formatTanggal(_tanggal),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // --- KM saat servis ---
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'KM saat servis',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: _validasiKm,
              ),
              const SizedBox(height: 14),

              // --- Biaya ---
              TextFormField(
                controller: _biayaController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Biaya servis',
                  hintText: 'Contoh: 55000',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: Validators.biaya,
              ),
              const SizedBox(height: 14),

              // --- Nama bengkel (opsional) ---
              TextFormField(
                controller: _bengkelController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama bengkel (opsional)',
                  hintText: 'Contoh: Bengkel Pak Budi',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: _validasiBengkel,
              ),
              const SizedBox(height: 14),

              // --- Catatan (opsional) ---
              TextFormField(
                controller: _catatanController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: ganti oli sekalian cek rem',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
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
            onPressed: _isSaving || komponen.isEmpty ? null : _simpan,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Catatan Servis'),
          ),
        ),
      ),
    );
  }
}

/// Keterangan kecil di bawah dropdown komponen.
class _InfoTerakhir extends StatelessWidget {
  final int? kmTerakhir;
  final String intervalLabel;

  const _InfoTerakhir({required this.kmTerakhir, required this.intervalLabel});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            kmTerakhir == null
                ? 'Belum ada servis sebelumnya. Interval komponen: $intervalLabel.'
                : 'Servis terakhir di ${formatKm(kmTerakhir!)}. '
                    'Interval komponen: $intervalLabel.',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
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
