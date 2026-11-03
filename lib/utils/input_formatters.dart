import 'package:flutter/services.dart';

/// Memaksa teks input menjadi HURUF BESAR (dipakai untuk plat nomor).
///
/// Panjang teks tidak berubah, jadi posisi kursor tetap aman.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
