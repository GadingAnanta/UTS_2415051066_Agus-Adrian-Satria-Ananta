/// Kumpulan validator untuk `TextFormField`.
///
/// Semua method mengembalikan `null` jika input valid, atau pesan error
/// berbahasa Indonesia yang langsung bisa ditampilkan oleh form.
class Validators {
  const Validators._();

  /// Hanya menerima huruf, angka, spasi, titik, strip, dan garis miring.
  /// Dipakai untuk merek/tipe motor supaya input aneh seperti `@@@` ditolak.
  static final RegExp _polaNama = RegExp(r'^[A-Za-z0-9 .\-/]+$');

  /// Pola plat nomor Indonesia, contoh: `B 1234 XYZ`, `AB 1234`, `D 1234 AB`.
  static final RegExp _polaPlat = RegExp(r'^[A-Z]{1,2}\s?\d{1,4}(\s?[A-Z]{1,3})?$');

  static final RegExp _polaAngka = RegExp(r'^\d+$');

  /// Validasi wajib isi yang dipakai semua form.
  static String? wajibIsi(String? value, {String label = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  /// Validasi merek kendaraan, contoh: `Honda`, `Yamaha`.
  static String? merek(String? value) {
    final String? kosong = wajibIsi(value, label: 'Merek');
    if (kosong != null) return kosong;

    final String teks = value!.trim();
    if (teks.length < 2) {
      return 'Merek minimal 2 karakter';
    }
    if (!_polaNama.hasMatch(teks)) {
      return 'Merek hanya boleh huruf, angka, spasi, dan tanda hubung';
    }
    return null;
  }

  /// Validasi tipe/model kendaraan, contoh: `Vario 160`, `NMAX`.
  static String? tipe(String? value) {
    final String? kosong = wajibIsi(value, label: 'Tipe');
    if (kosong != null) return kosong;

    final String teks = value!.trim();
    if (teks.length < 2) {
      return 'Tipe minimal 2 karakter';
    }
    if (!_polaNama.hasMatch(teks)) {
      return 'Tipe hanya boleh huruf, angka, spasi, dan tanda hubung';
    }
    return null;
  }

  /// Validasi tahun pembuatan: 4 digit dan tidak melebihi tahun depan.
  static String? tahun(String? value) {
    final String? kosong = wajibIsi(value, label: 'Tahun');
    if (kosong != null) return kosong;

    final String teks = value!.trim();
    if (teks.length != 4 || !_polaAngka.hasMatch(teks)) {
      return 'Tahun harus 4 digit angka, contoh 2021';
    }

    final int tahun = int.parse(teks);
    final int tahunMaksimal = DateTime.now().year + 1;
    if (tahun < 1900 || tahun > tahunMaksimal) {
      return 'Tahun harus antara 1900 dan $tahunMaksimal';
    }
    return null;
  }

  /// Validasi plat nomor kendaraan.
  static String? platNomor(String? value) {
    final String? kosong = wajibIsi(value, label: 'Plat nomor');
    if (kosong != null) return kosong;

    // Spasi berlebih dirapikan dulu, lalu dibandingkan tanpa peduli besar huruf.
    final String teks = value!.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    if (!_polaPlat.hasMatch(teks)) {
      return 'Format plat tidak valid, contoh: B 1234 XYZ';
    }
    return null;
  }

  /// Validasi angka kilometer. [minimal] dipakai untuk aturan
  /// "KM baru tidak boleh lebih kecil dari KM sebelumnya".
  static String? kilometer(String? value, {String label = 'Kilometer', int? minimal}) {
    final String? kosong = wajibIsi(value, label: label);
    if (kosong != null) return kosong;

    final String teks = value!.trim();
    if (!_polaAngka.hasMatch(teks)) {
      return '$label harus berupa angka bulat tanpa titik/koma';
    }

    final int angka = int.parse(teks);
    if (angka < 0) {
      return '$label tidak boleh negatif';
    }
    if (minimal != null && angka < minimal) {
      return '$label tidak boleh kurang dari $minimal';
    }
    return null;
  }

  /// Validasi biaya servis (rupiah, bilangan bulat).
  static String? biaya(String? value) {
    final String? kosong = wajibIsi(value, label: 'Biaya');
    if (kosong != null) return kosong;

    final String teks = value!.trim();
    if (!_polaAngka.hasMatch(teks)) {
      return 'Biaya harus berupa angka bulat tanpa titik/koma';
    }
    if (int.parse(teks) <= 0) {
      return 'Biaya harus lebih dari 0';
    }
    return null;
  }
}
