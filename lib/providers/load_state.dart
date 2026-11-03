/// Status pemuatan data yang dipakai semua provider.
///
/// Membuat alur UI menjadi seragam:
/// - [idle]    : belum ada permintaan
/// - [loading] : sedang mengambil data (tampilkan spinner)
/// - [success] : data siap (tampilkan konten / empty state)
/// - [error]   : gagal (tampilkan pesan + tombol coba lagi)
enum LoadState { idle, loading, success, error }
