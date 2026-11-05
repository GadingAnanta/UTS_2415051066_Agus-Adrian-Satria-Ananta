# Bengkel Digital

Aplikasi Flutter untuk mencatat kendaraan bermotor, menghitung jadwal servis,
dan mengingatkan jatuh tempo pajak/STNK. Data kendaraan dan riwayat servis
disimpan di **Supabase (PostgreSQL)**, sedangkan katalog motor dan tips
perawatan diambil dari **REST API** berbentuk berkas JSON.

Proyek ini dibuat untuk UTS mata kuliah Pemrograman Berbasis Mobile.

## Identitas

| | |
| --- | --- |
| Nama | Agus Adrian Satria Ananta |
| NIM | 2415051066 |
| Kelas | PTI 5C |
| Mata kuliah | Pemrograman Berbasis Mobile |

> Nilai yang dipakai aplikasi ada di `lib/utils/constants.dart` (`AppInfo`).
> Ubah di kedua tempat bila ada perubahan agar konsisten.

## Fitur

| Fitur | Keterangan |
| --- | --- |
| Beranda | Sapaan, ringkasan jumlah kendaraan, pajak/STNK yang jatuh tempo ≤ 30 hari, dan menu cepat. |
| Kendaraan (CRUD) | Tambah, lihat, ubah, hapus kendaraan. Pencarian, filter status, geser untuk hapus, tekan lama untuk menu cepat. |
| Detail kendaraan | Identitas motor, tanggal pajak & STNK beserta sisa hari, ringkasan biaya servis, riwayat servis. |
| Dashboard servis | Status tiap komponen (aman / mendekati / lewat batas) berdasarkan KM dan waktu, tombol catat servis, laporan biaya. |
| Riwayat servis (CRUD) | Catat, ubah, dan hapus servis per komponen; bisa difilter per komponen. |
| Update KM | Memperbarui odometer; KM baru tidak boleh lebih kecil dari yang tersimpan. |
| Pajak & STNK | Mengatur tanggal jatuh tempo pajak tahunan dan STNK 5 tahunan, plus info izin notifikasi. |
| Laporan pengeluaran | Grafik batang 6 bulan terakhir dan rincian biaya per komponen. |
| Katalog & Tips | Data dari REST API: 8 motor, 8 tips, 8 interval servis standar, dengan keadaan loading/error/empty. |
| Notifikasi lokal | Pengingat servis (H-7), pajak/STNK (H-30 dan H-7), dan peringatan kilometer. |
| Profil / About | Identitas mahasiswa, info aplikasi, daftar fitur, dan teknologi yang dipakai. |
| Responsif | Navigasi bawah (< 600 px) berubah menjadi NavigationRail (≥ 600 px); daftar berubah menjadi grid (≥ 600 px); Beranda dan Profil menjadi dua kolom (≥ 900 px). |

## Tech Stack

| Bagian | Teknologi |
| --- | --- |
| Bahasa / UI | Dart 3.13, Flutter 3.47 (Material 3) |
| State management | `provider` (`ChangeNotifier`) |
| Backend | Supabase (PostgreSQL + REST/PostgREST) via `supabase_flutter` |
| REST API | `http` + berkas `api/tips.json` |
| Grafik | `fl_chart` |
| Format angka/tanggal | `intl` (locale `id_ID`) |
| Konfigurasi | `flutter_dotenv` (hanya anon key) |
| Notifikasi | `flutter_local_notifications` + `timezone` (WIB) |
| Pengujian | `flutter_test` (87 test: model, kalkulator servis, filter, validator, layout) |

## REST API

- Berkas sumber: `api/tips.json` (ikut di-commit, jadi bisa di-host di GitHub
  Pages atau diakses langsung sebagai raw file).
- Alamat bawaan (dipakai bila `TIPS_API_URL` kosong):

  ```text
  https://raw.githubusercontent.com/GadingAnanta/UTS_2415051066_Agus-Adrian-Satria-Ananta/main/api/tips.json
  ```

- Alternatif GitHub Pages:

  ```text
  https://gadingananta.github.io/UTS_2415051066_Agus-Adrian-Satria-Ananta/api/tips.json
  ```

- Struktur JSON: `versi`, `diperbarui`, `sumber`, `katalog_motor` (8 item),
  `tips_perawatan` (8 item), `interval_servis` (8 item).
- Alur: `TipsScreen` → `TipsProvider` → `TipsRepository` → `ApiService`
  (`http.get`, timeout 15 detik).
- Penanganan: status loading (spinner), error (pesan + tombol coba lagi +
  alamat API yang dipakai), dan empty (data kosong).

## Supabase

1. Buat project di [supabase.com](https://supabase.com).
2. Jalankan `supabase/schema.sql` di **SQL Editor**. Isinya:
   - tabel `vehicles` dan `service_records` (relasi 1 : banyak, `on delete cascade`),
   - kolom tanggal `tax_due_date` dan `stnk_due_date` pada `vehicles`,
   - RLS aktif + policy permissive untuk role `anon`,
   - blok `GRANT` untuk role `anon` (tabel dan sequence).
3. Ambil **Project URL** dan **anon/publishable key** dari
   *Project Settings → API*, lalu isi `.env` (lihat bagian Cara Menjalankan).
4. Selama belum ada fitur login, aplikasi memakai satu `user_id` demo dari
   `DEMO_USER_ID`. Pastikan baris di tabel memakai nilai yang sama.

> Aplikasi **hanya** memakai anon key. `service_role` key tidak pernah dipakai
> dan tidak boleh dimasukkan ke aplikasi.

## Struktur Arsitektur

```text
lib/
├── main.dart                     # bootstrap: locale, .env, Supabase, notifikasi, provider
├── models/                       # 5 model data (tanpa akses jaringan)
│   ├── vehicle.dart
│   ├── service_record.dart
│   ├── component_interval.dart   # konfigurasi statis interval komponen
│   ├── tax_reminder.dart
│   └── tips_data.dart            # TipsData, KatalogMotor, TipsPerawatan, IntervalServisStandar
├── providers/                    # ChangeNotifier: state + aturan tampilan
│   ├── vehicle_provider.dart     # daftar kendaraan, pencarian, filter, kendaraan terpilih
│   ├── service_provider.dart     # riwayat servis + status komponen
│   ├── tips_provider.dart        # state REST API
│   └── load_state.dart
├── repositories/                 # satu-satunya penghubung ke data
│   ├── vehicle_repository.dart
│   ├── service_record_repository.dart
│   └── tips_repository.dart
├── services/                     # lapisan teknis
│   ├── supabase_service.dart     # inisialisasi + pesan error
│   ├── api_service.dart          # HTTP GET + timeout
│   └── notification_service.dart # penjadwalan notifikasi lokal
├── screens/                      # 13 halaman
│   ├── main_shell.dart           # NavigationBar / NavigationRail
│   ├── home/home_screen.dart
│   ├── vehicle/{vehicle_list, vehicle_detail, vehicle_form, update_km}_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── service/{service_history, service_form}_screen.dart
│   ├── tax/tax_reminder_screen.dart
│   ├── report/expense_chart_screen.dart
│   ├── tips/tips_screen.dart
│   └── profile/profile_screen.dart
├── widgets/                      # widget yang dipakai lebih dari satu halaman
│   ├── adaptive_grid.dart        # 1 kolom → grid 2/3 kolom
│   ├── status_chip.dart, status_summary_row.dart
│   ├── vehicle_card.dart, vehicle_summary_card.dart, tax_due_card.dart
│   ├── component_status_card.dart, service_record_tile.dart
│   ├── empty_state.dart, error_view.dart, info_banner.dart, section_header.dart
│   ├── home/{greeting, reminder, mini_vehicle, quick_action}_card.dart
│   └── tips/{katalog_motor, tips, interval_table, tips_source}_card.dart
└── utils/                        # helper murni (tanpa UI berat)
    ├── constants.dart            # AppInfo, AppColors, interval komponen
    ├── responsive.dart           # breakpoint 600 / 900 / 1180
    ├── app_theme.dart            # tema Material 3
    ├── formatters.dart           # rupiah, KM, tanggal, selisih hari
    ├── json_parse.dart           # konversi aman int & tanggal dari JSON
    ├── validators.dart           # validasi form
    ├── service_calculator.dart   # status komponen (aman/mendekati/lewat)
    ├── expense_aggregator.dart   # agregasi biaya per bulan/komponen
    ├── vehicle_filter.dart       # pencarian + filter
    ├── feedback.dart             # SnackBar & dialog konfirmasi hapus
    ├── input_formatters.dart
    └── app_exception.dart
```

Aturan lapisan yang dipakai:

```text
Screen → Provider → Repository → Service → Supabase / REST API
```

- Screen hanya memanggil provider (dan widget murni). Tidak ada `http`,
  `SupabaseClient`, atau `.env` di dalam `lib/screens`.
- Repository adalah satu-satunya tempat query Supabase/HTTP.
- `user_id` pemilik data ditempelkan di repository, bukan di form.
- Notifikasi dijadwalkan dari provider (data) dan dari dashboard (aksi pengguna).

## Screenshot

Letakkan tangkapan layar di folder **`docs/screenshots/`** (buat foldernya bila
belum ada) dengan nama berkas berikut, lalu ganti baris komentar di bawahnya
menjadi gambar biasa.

| Berkas | Isi yang diambil |
| --- | --- |
| `01-beranda.png` | Beranda dengan ringkasan dan kartu pengingat |
| `02-kendaraan-list.png` | Daftar kendaraan (mode 1 kolom) |
| `03-kendaraan-grid.png` | Daftar kendaraan pada layar lebar (grid) |
| `04-detail-kendaraan.png` | Detail kendaraan + pajak/STNK |
| `05-dashboard-servis.png` | Status komponen servis |
| `06-form-kendaraan.png` | Form tambah kendaraan + validasi |
| `07-riwayat-servis.png` | Riwayat servis dan filter komponen |
| `08-pajak-stnk.png` | Halaman pajak & STNK |
| `09-laporan-biaya.png` | Grafik pengeluaran |
| `10-katalog-tips.png` | Katalog & tips dari REST API |
| `11-error-tips.png` | Keadaan error REST API (mis. mode pesawat) |
| `12-profil.png` | Halaman Profil/About |
| `13-rail.png` | NavigationRail pada jendela lebar |

Contoh pemakaian setelah gambar tersedia:

```markdown
![Beranda](docs/screenshots/01-beranda.png)
```

<!--
![Beranda](docs/screenshots/01-beranda.png)
![Daftar kendaraan](docs/screenshots/02-kendaraan-list.png)
![Detail kendaraan](docs/screenshots/04-detail-kendaraan.png)
![Katalog & tips](docs/screenshots/10-katalog-tips.png)
-->

## Cara Menjalankan

Prasyarat: Flutter 3.47+ (Dart 3.13+), Android SDK untuk build APK, dan project
Supabase yang sudah menjalankan `supabase/schema.sql`.

1. Ambil dependensi:

   ```powershell
   flutter pub get
   ```

2. Siapkan konfigurasi (hanya anon key):

   ```powershell
   Copy-Item .env.example .env
   ```

   Isi `.env`:

   ```dotenv
   SUPABASE_URL=https://<project-ref>.supabase.co
   SUPABASE_ANON_KEY=<anon-key>
   DEMO_USER_ID=11111111-1111-4111-8111-111111111111
   TIPS_API_URL=https://raw.githubusercontent.com/<user>/<repo>/main/api/tips.json
   ```

   `TIPS_API_URL` boleh dikosongkan; aplikasi memakai alamat bawaan di
   `lib/repositories/tips_repository.dart`.

3. Jalankan:

   ```powershell
   flutter run                 # perangkat/emulator Android
   flutter run -d windows      # jendela desktop (uji layout responsif)
   flutter run -d chrome       # pratinjau web (notifikasi tidak aktif)
   ```

   Untuk menguji perubahan lebar layar, jalankan versi desktop lalu ubah lebar
   jendela melewati 600 px dan 900 px.

4. Menjalankan pengujian otomatis:

   ```powershell
   flutter analyze
   flutter test
   ```

## Build APK

```powershell
# APK debug (paling cepat, untuk demo)
flutter build apk --debug

# APK release (ukuran lebih kecil, butuh signing untuk distribusi)
flutter build apk --release

# APK release per arsitektur (lebih kecil lagi)
flutter build apk --release --split-per-abi
```

Hasil build:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Catatan:

- `android/gradle.properties` sudah berisi `kotlin.incremental=false` karena
  path proyek mengandung spasi; jangan dihapus.
- Build release memakai debug signing secara default (cukup untuk UTS). Untuk
  distribusi, buat keystore sendiri lalu daftarkan di `android/key.properties`
  (jangan commit keystore maupun `key.properties`).
- Build web (opsional): `flutter build web`.

## Checklist Pengujian Manual

| # | Skenario | Hasil yang diharapkan |
| --- | --- | --- |
| 1 | Buka aplikasi dengan `.env` benar | Beranda tampil, data kendaraan termuat dari Supabase |
| 2 | Hapus/rusak sementara `.env` | Layar "Konfigurasi Diperlukan" muncul, aplikasi tidak crash |
| 3 | Tambah kendaraan dengan form kosong | Pesan validasi per kolom muncul, tidak ada data tersimpan |
| 4 | Isi plat `B1234XYZ` / tahun `1800` | Ditolak dengan pesan format yang jelas |
| 5 | Simpan kendaraan valid | SnackBar sukses, kartu muncul di Beranda & daftar |
| 6 | Cari "vario", lalu pilih filter "Lewat batas" | Daftar tersaring, ringkasan "x dari y kendaraan" |
| 7 | Geser kartu ke kiri lalu batal | Dialog konfirmasi muncul; batal = data tetap ada |
| 8 | Hapus kendaraan dari detail | Dialog konfirmasi, data + riwayat servis hilang, SnackBar sukses |
| 9 | Tekan lama kartu kendaraan | Bottom sheet aksi (detail / edit / hapus) muncul |
| 10 | Update KM lebih kecil dari sebelumnya | Ditolak dengan pesan perbandingan KM |
| 11 | Catat servis (komponen, tanggal, biaya) | Status komponen dan ringkasan biaya ikut berubah |
| 12 | Hapus catatan servis | Konfirmasi, riwayat dan status dihitung ulang |
| 13 | Atur tanggal pajak & STNK | Sisa hari tampil, pengingat dijadwalkan ulang |
| 14 | Buka Laporan Pengeluaran | Grafik 6 bulan + rincian komponen; tanpa data tampil pesan kosong |
| 15 | Buka Katalog & Tips | Spinner lalu 8 motor, 8 tips, 8 interval servis |
| 16 | Mode pesawat, buka Tips | Halaman error + tombol "Coba lagi" + alamat API |
| 17 | Nyalakan internet, tekan "Coba lagi" | Data tampil kembali |
| 18 | Tarik ke bawah di Beranda/Kendaraan/Tips | Data dimuat ulang tanpa error |
| 19 | Perkecil lebar jendela < 600 px | Navigasi bawah, daftar 1 kolom |
| 20 | Lebarkan ≥ 600 px | NavigationRail, daftar menjadi grid 2 kolom |
| 21 | Lebarkan ≥ 900 px | Beranda/Profil 2 kolom, katalog 3 kolom, rail diperluas (≥ 1180 px) |
| 22 | Cek semua halaman di 320 px | Tidak ada garis kuning/hitam "overflow" |
| 23 | Buka Profil | Nama, NIM, kelas, mata kuliah, versi app, URL repo & API tampil |
| 24 | Jalankan `flutter analyze` | No issues found |
| 25 | Jalankan `flutter test` | 87 test lulus |

## Catatan Keterbatasan

- Belum ada fitur login; semua data memakai `DEMO_USER_ID` dari `.env`.
- Zona waktu notifikasi disetel manual ke `Asia/Jakarta`
  (`NotificationService.zonaWaktu`). Untuk WITA/WIT ganti nilainya.
- Notifikasi lokal tidak tersedia di web; di web semua method notifikasi
  menjadi no-op.
- Katalog & tips bergantung pada berkas `api/tips.json` yang sudah di-push ke
  GitHub (lihat bagian REST API).
