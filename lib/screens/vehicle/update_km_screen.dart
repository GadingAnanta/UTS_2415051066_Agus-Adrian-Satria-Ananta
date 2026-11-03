import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

/// Halaman untuk memperbarui kilometer kendaraan.
///
/// KM dipakai sebagai patokan menghitung sisa jarak menuju servis berikutnya,
/// jadi halaman ini dibuat terpisah dan sesederhana mungkin: satu kolom isian.
///
/// Mengembalikan `true` lewat `Navigator.pop` bila berhasil disimpan.
class UpdateKmScreen extends StatefulWidget {
  final Vehicle vehicle;

  const UpdateKmScreen({super.key, required this.vehicle});

  @override
  State<UpdateKmScreen> createState() => _UpdateKmScreenState();
}

class _UpdateKmScreenState extends State<UpdateKmScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _kmController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final VehicleProvider provider = context.read<VehicleProvider>();
    final int kmBaru = int.parse(_kmController.text.trim());
    final bool berhasil = await provider.updateKm(widget.vehicle.id!, kmBaru);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (berhasil) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memperbarui kilometer.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Update KM')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              // Ringkasan KM yang tersimpan saat ini.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.speed, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Kilometer tercatat',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatKm(widget.vehicle.currentKm),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _kmController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Kilometer baru',
                  hintText: 'Contoh: 14250',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.edit_road),
                ),
                validator: (String? value) => Validators.kilometer(
                  value,
                  label: 'Kilometer',
                  minimal: widget.vehicle.currentKm,
                ),
                onFieldSubmitted: (_) => _simpan(),
              ),
              const SizedBox(height: 12),
              Text(
                'Kilometer tidak boleh lebih kecil dari angka tercatat, karena '
                'odometer tidak pernah berjalan mundur. Setelah disimpan, sisa '
                'KM tiap komponen di dashboard langsung dihitung ulang.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
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
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Kilometer'),
          ),
        ),
      ),
    );
  }
}
