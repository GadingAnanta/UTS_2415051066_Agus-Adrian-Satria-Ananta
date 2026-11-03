import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../utils/expense_aggregator.dart';
import '../../utils/formatters.dart';

/// Laporan pengeluaran servis: grafik batang 6 bulan terakhir + rincian
/// per komponen.
///
/// Seluruh perhitungan ada di [ExpenseAggregator]; halaman ini hanya
/// merapikan tampilan.
class ExpenseChartScreen extends StatefulWidget {
  final Vehicle vehicle;

  const ExpenseChartScreen({super.key, required this.vehicle});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  /// Jumlah bulan yang ditampilkan pada grafik.
  static const int _jumlahBulan = 6;

  /// Index batang yang sedang disentuh (untuk menyorot batang terpilih).
  int? _indexTerpilih;

  @override
  void initState() {
    super.initState();

    // Pastikan data terbaru sudah dimuat (halaman bisa dibuka langsung
    // tanpa lewat dashboard).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ServiceProvider provider = context.read<ServiceProvider>();
      if (provider.vehicleId != widget.vehicle.id) {
        provider.loadForVehicle(widget.vehicle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ServiceProvider provider = context.watch<ServiceProvider>();

    final List<MonthlyExpense> bulanan = ExpenseAggregator.perBulan(
      provider.records,
      jumlahBulan: _jumlahBulan,
    );
    final List<ComponentExpense> komponen = ExpenseAggregator.perKomponen(
      provider.records,
    );
    final int totalSemua = ExpenseAggregator.total(provider.records);
    final int rataRata = ExpenseAggregator.rataRataPerBulan(bulanan);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Pengeluaran')),
      body: SafeArea(
        child: provider.isLoading && provider.records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: <Widget>[
                  _Ringkasan(
                    total: totalSemua,
                    rataRata: rataRata,
                    jumlahCatatan: provider.records.length,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Pengeluaran $_jumlahBulan Bulan Terakhir',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.records.isEmpty)
                    _KotakKosong(
                      pesan:
                          'Belum ada catatan servis. Tambahkan catatan lewat '
                          'tombol "Catat Servis" di dashboard.',
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                        child: SizedBox(
                          height: 240,
                          child: _GrafikBulanan(
                            data: bulanan,
                            indexTerpilih: _indexTerpilih,
                            onSentuh: (int? index) =>
                                setState(() => _indexTerpilih = index),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (komponen.isNotEmpty) ...<Widget>[
                    Text(
                      'Rincian per Komponen',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < komponen.length; i++)
                            _BarisKomponen(
                              nama: provider.componentName(komponen[i].componentKey),
                              data: komponen[i],
                              totalSemua: totalSemua,
                              tampilkanGaris: i != komponen.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Kartu tiga angka ringkasan.
class _Ringkasan extends StatelessWidget {
  final int total;
  final int rataRata;
  final int jumlahCatatan;

  const _Ringkasan({
    required this.total,
    required this.rataRata,
    required this.jumlahCatatan,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Total pengeluaran servis',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatRupiah(total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AngkaKecil(
                    label: 'Rata-rata / bulan',
                    nilai: formatRupiah(rataRata),
                  ),
                ),
                Container(width: 1, height: 32, color: scheme.outlineVariant),
                Expanded(
                  child: _AngkaKecil(
                    label: 'Jumlah catatan',
                    nilai: '$jumlahCatatan kali',
                    rataKanan: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AngkaKecil extends StatelessWidget {
  final String label;
  final String nilai;
  final bool rataKanan;

  const _AngkaKecil({
    required this.label,
    required this.nilai,
    this.rataKanan = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(left: rataKanan ? 12 : 0, right: rataKanan ? 0 : 12),
      child: Column(
        crossAxisAlignment:
            rataKanan ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            nilai,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grafik batang pengeluaran per bulan.
class _GrafikBulanan extends StatelessWidget {
  final List<MonthlyExpense> data;
  final int? indexTerpilih;
  final ValueChanged<int?> onSentuh;

  const _GrafikBulanan({
    required this.data,
    required this.indexTerpilih,
    required this.onSentuh,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Nilai tertinggi dipakai untuk menentukan skala sumbu Y.
    final int nilaiMaks = data.fold<int>(
      0,
      (int maks, MonthlyExpense item) => item.total > maks ? item.total : maks,
    );
    // Sisakan ruang di atas batang tertinggi agar label tidak menempel.
    final double batasAtas = nilaiMaks <= 0 ? 100000 : nilaiMaks * 1.25;

    return BarChart(
      BarChartData(
        maxY: batasAtas,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (event is FlTapUpEvent) {
              onSentuh(null);
              return;
            }
            final int? index = response?.spot?.touchedBarGroupIndex;
            onSentuh(index);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData group) =>
                scheme.inverseSurface.withValues(alpha: 0.92),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem:
                (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
              final MonthlyExpense item = data[groupIndex];
              return BarTooltipItem(
                '${formatBulan(item.bulan)}\n${formatRupiah(item.total)}',
                theme.textTheme.bodySmall!.copyWith(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: batasAtas / 4,
          getDrawingHorizontalLine: (double value) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: <int>[4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: batasAtas / 4,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value <= 0) return const SizedBox.shrink();
                // Ringkas label sumbu: 1.500.000 → "1,5 jt".
                final String label = value >= 1000000
                    ? '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)} jt'
                    : '${(value / 1000).round()} rb';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final bool terpilih = index == indexTerpilih;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatBulan(data[index].bulan),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: terpilih ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: terpilih ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: data[i].total.toDouble(),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: i == indexTerpilih ? scheme.primary : scheme.primary.withValues(alpha: 0.55),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Satu baris rincian biaya per komponen (nama, jumlah, bar proporsi).
class _BarisKomponen extends StatelessWidget {
  final String nama;
  final ComponentExpense data;
  final int totalSemua;
  final bool tampilkanGaris;

  const _BarisKomponen({
    required this.nama,
    required this.data,
    required this.totalSemua,
    required this.tampilkanGaris,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double porsi = totalSemua <= 0 ? 0 : data.total / totalSemua;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatRupiah(data.total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: porsi.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.jumlahServis} kali servis · ${(porsi * 100).toStringAsFixed(0)}% dari total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (tampilkanGaris) ...<Widget>[
            const SizedBox(height: 10),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );
  }
}

/// Kotak kosong saat belum ada catatan servis.
class _KotakKosong extends StatelessWidget {
  final String pesan;

  const _KotakKosong({required this.pesan});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.insert_chart_outlined,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            pesan,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
