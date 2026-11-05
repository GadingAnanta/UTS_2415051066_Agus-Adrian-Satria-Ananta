import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'tips/tips_screen.dart';
import 'vehicle/vehicle_list_screen.dart';

/// Kerangka utama aplikasi: menampung empat tab (Beranda, Kendaraan, Tips,
/// Profil) dan memilih navigasi sesuai lebar layar.
///
/// - **< 600 px**  → `NavigationBar` di bagian bawah.
/// - **≥ 600 px**  → `NavigationRail` di kiri (label ikon), dan versi
///   diperluas pada layar ≥ 1180 px.
///
/// Isi tab disimpan dengan [IndexedStack] supaya kata kunci pencarian dan
/// posisi gulir tidak hilang saat berpindah tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indeks = 0;

  void _pilihTab(int indeks) {
    if (indeks == _indeks) return;
    setState(() => _indeks = indeks);
  }

  @override
  Widget build(BuildContext context) {
    final Widget isi = IndexedStack(
      index: _indeks,
      children: <Widget>[
        HomeScreen(onBukaTab: _pilihTab),
        const VehicleListScreen(),
        const TipsScreen(),
        const ProfileScreen(),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints batas) {
        // Ponsel: navigasi bawah.
        if (Responsive.sempit(batas.maxWidth)) {
          return Scaffold(
            body: isi,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _indeks,
              onDestinationSelected: _pilihTab,
              destinations: _tujuanBawah,
            ),
          );
        }

        // Tablet & desktop: navigasi samping.
        final bool diperluas = batas.maxWidth >= Responsive.batasRailDiperluas;
        final ColorScheme scheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                extended: diperluas,
                minExtendedWidth: 200,
                selectedIndex: _indeks,
                onDestinationSelected: _pilihTab,
                labelType: diperluas
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: diperluas
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(
                                Icons.two_wheeler,
                                size: 18,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppInfo.appName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.two_wheeler,
                            size: 20,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                ),
                destinations: _tujuanSamping,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: isi),
            ],
          ),
        );
      },
    );
  }

  /// Tujuan navigasi bawah (ponsel).
  static const List<NavigationDestination> _tujuanBawah =
      <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.two_wheeler_outlined),
      selectedIcon: Icon(Icons.two_wheeler),
      label: 'Kendaraan',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Tips',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  /// Tujuan navigasi samping (tablet & desktop).
  static const List<NavigationRailDestination> _tujuanSamping =
      <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Beranda'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.two_wheeler_outlined),
      selectedIcon: Icon(Icons.two_wheeler),
      label: Text('Kendaraan'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: Text('Tips'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Profil'),
    ),
  ];
}
