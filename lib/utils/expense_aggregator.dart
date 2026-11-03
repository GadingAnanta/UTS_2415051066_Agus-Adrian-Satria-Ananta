import '../models/service_record.dart';

/// Total pengeluaran pada satu bulan.
class MonthlyExpense {
  /// Bulan yang dihitung, selalu tanggal 1 jam 00.00 supaya mudah dibandingkan.
  final DateTime bulan;

  /// Jumlah uang yang dikeluarkan (rupiah).
  final int total;

  /// Banyak catatan servis pada bulan tersebut.
  final int jumlahServis;

  const MonthlyExpense({
    required this.bulan,
    required this.total,
    required this.jumlahServis,
  });

  @override
  String toString() => 'MonthlyExpense($bulan, Rp $total, $jumlahServis servis)';
}

/// Total pengeluaran untuk satu komponen.
class ComponentExpense {
  final String componentKey;
  final int total;
  final int jumlahServis;

  const ComponentExpense({
    required this.componentKey,
    required this.total,
    required this.jumlahServis,
  });

  @override
  String toString() => 'ComponentExpense($componentKey, Rp $total)';
}

/// Kumpulan fungsi murni (tanpa akses database/widget) untuk mengolah biaya
/// servis menjadi data grafik.
///
/// Dipisah dari UI supaya mudah diuji lewat unit test, sesuai aturan
/// "logika terpisah dari tampilan".
class ExpenseAggregator {
  ExpenseAggregator._();

  /// Mengelompokkan biaya servis per bulan untuk [jumlahBulan] bulan terakhir.
  ///
  /// Hasil selalu berisi tepat [jumlahBulan] entri dan urut dari bulan paling
  /// lama ke bulan terbaru. Bulan tanpa catatan servis tetap muncul dengan
  /// total 0, sehingga grafik tidak "bolong".
  ///
  /// [acuan] adalah tanggal patokan (default: hari ini) — dipakai di unit test
  /// agar hasilnya tidak bergantung pada tanggal saat tes dijalankan.
  static List<MonthlyExpense> perBulan(
    List<ServiceRecord> records, {
    int jumlahBulan = 6,
    DateTime? acuan,
  }) {
    assert(jumlahBulan > 0, 'jumlahBulan harus lebih dari 0');

    final DateTime sekarang = acuan ?? DateTime.now();
    // Bulan berjalan dinormalisasi ke tanggal 1.
    final DateTime bulanBerjalan = DateTime(sekarang.year, sekarang.month);

    // Siapkan keranjang kosong untuk tiap bulan (paling lama → terbaru).
    final List<DateTime> daftarBulan = List<DateTime>.generate(
      jumlahBulan,
      (int i) => DateTime(bulanBerjalan.year, bulanBerjalan.month - (jumlahBulan - 1 - i)),
    );

    final Map<DateTime, int> totalPerBulan = <DateTime, int>{
      for (final DateTime bulan in daftarBulan) bulan: 0,
    };
    final Map<DateTime, int> jumlahPerBulan = <DateTime, int>{
      for (final DateTime bulan in daftarBulan) bulan: 0,
    };

    for (final ServiceRecord record in records) {
      final DateTime kunci = DateTime(
        record.serviceDate.year,
        record.serviceDate.month,
      );
      // Catatan di luar rentang bulan yang diminta diabaikan.
      if (!totalPerBulan.containsKey(kunci)) continue;

      totalPerBulan[kunci] = totalPerBulan[kunci]! + record.cost;
      jumlahPerBulan[kunci] = jumlahPerBulan[kunci]! + 1;
    }

    return daftarBulan
        .map(
          (DateTime bulan) => MonthlyExpense(
            bulan: bulan,
            total: totalPerBulan[bulan]!,
            jumlahServis: jumlahPerBulan[bulan]!,
          ),
        )
        .toList();
  }

  /// Mengelompokkan biaya servis per komponen, diurutkan dari yang terbesar.
  static List<ComponentExpense> perKomponen(List<ServiceRecord> records) {
    final Map<String, int> total = <String, int>{};
    final Map<String, int> jumlah = <String, int>{};

    for (final ServiceRecord record in records) {
      total[record.componentKey] = (total[record.componentKey] ?? 0) + record.cost;
      jumlah[record.componentKey] = (jumlah[record.componentKey] ?? 0) + 1;
    }

    final List<ComponentExpense> hasil = total.entries
        .map(
          (MapEntry<String, int> entry) => ComponentExpense(
            componentKey: entry.key,
            total: entry.value,
            jumlahServis: jumlah[entry.key] ?? 0,
          ),
        )
        .toList();

    hasil.sort((ComponentExpense a, ComponentExpense b) => b.total.compareTo(a.total));
    return hasil;
  }

  /// Total seluruh biaya servis pada daftar catatan.
  static int total(List<ServiceRecord> records) {
    int jumlah = 0;
    for (final ServiceRecord record in records) {
      jumlah += record.cost;
    }
    return jumlah;
  }

  /// Rata-rata biaya per bulan dari hasil [perBulan] (dibulatkan ke bawah).
  static int rataRataPerBulan(List<MonthlyExpense> data) {
    if (data.isEmpty) return 0;
    final int totalSemua = data.fold<int>(
      0,
      (int jumlah, MonthlyExpense item) => jumlah + item.total,
    );
    return totalSemua ~/ data.length;
  }
}
