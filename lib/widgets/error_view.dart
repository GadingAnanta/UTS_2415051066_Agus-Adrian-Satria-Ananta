import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Tampilan kegagalan memuat data, lengkap dengan tombol coba lagi.
class ErrorView extends StatelessWidget {
  final String pesan;
  final VoidCallback? onRetry;
  final String judul;

  const ErrorView({
    super.key,
    required this.pesan,
    this.onRetry,
    this.judul = 'Gagal memuat data',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: judul,
      message: pesan,
      actionLabel: onRetry == null ? null : 'Coba lagi',
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}
