import 'package:flutter/material.dart';

/// Menampilkan SnackBar hasil operasi (sukses / gagal) dengan gaya seragam.
///
/// Dipakai semua halaman supaya pesan berhasil berwarna biasa, sedangkan
/// pesan gagal memakai warna error dan lebih lama tampil agar terbaca.
void tampilkanPesan(
  BuildContext context,
  String pesan, {
  bool error = false,
}) {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final ColorScheme scheme = Theme.of(context).colorScheme;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              size: 20,
              color: error ? scheme.onError : scheme.onInverseSurface,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan)),
          ],
        ),
        backgroundColor: error ? scheme.error : null,
        duration: Duration(seconds: error ? 5 : 3),
        action: error
            ? SnackBarAction(
                label: 'Tutup',
                textColor: scheme.onError,
                onPressed: messenger.hideCurrentSnackBar,
              )
            : null,
      ),
    );
}

/// Menampilkan dialog konfirmasi hapus.
///
/// Mengembalikan `true` bila pengguna menekan tombol hapus. Dipakai bersama
/// oleh swipe-to-delete, menu kartu, dan halaman detail supaya teks
/// konfirmasinya konsisten.
Future<bool> konfirmasiHapus(
  BuildContext context, {
  required String judul,
  required String pesan,
  String labelHapus = 'Hapus',
}) async {
  final bool? setuju = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(labelHapus),
        ),
      ],
    ),
  );

  return setuju ?? false;
}
