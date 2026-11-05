import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Grid yang jumlah kolomnya mengikuti lebar layar.
///
/// - [tinggiItem] diisi bila semua kartu harus sama tinggi (mis. katalog).
/// - Bila [tinggiItem] `null` dan layar sempit, isi ditumpuk sebagai kolom
///   biasa sehingga kartu tidak dipaksa menjadi persegi.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double jarak;

  /// Tinggi tetap tiap sel; wajib diisi agar grid rapi tanpa overflow.
  final double? tinggiItem;

  /// Batas jumlah kolom (mis. tips cukup 2 kolom di desktop).
  final int maksKolom;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.jarak = 12,
    this.tinggiItem,
    this.maksKolom = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int kolom = Responsive.kolom(
          constraints.maxWidth,
          maks: maksKolom,
        );

        // Satu kolom tanpa tinggi tetap → tumpuk vertikal (lebih natural).
        if (kolom == 1 && tinggiItem == null) {
          return Column(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) SizedBox(height: jarak),
                children[i],
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kolom,
            mainAxisSpacing: jarak,
            crossAxisSpacing: jarak,
            mainAxisExtent: tinggiItem,
          ),
          itemBuilder: (BuildContext context, int index) => children[index],
        );
      },
    );
  }
}
