import 'package:flutter_test/flutter_test.dart';

import 'package:bengkel_digital/utils/responsive.dart';

void main() {
  group('Responsive.kolom', () {
    test('layar ponsel (< 600 px) memakai satu kolom', () {
      expect(Responsive.kolom(320), 1);
      expect(Responsive.kolom(599), 1);
    });

    test('tablet (600–899 px) memakai dua kolom', () {
      expect(Responsive.kolom(600), 2);
      expect(Responsive.kolom(899), 2);
    });

    test('desktop (≥ 900 px) memakai tiga kolom', () {
      expect(Responsive.kolom(900), 3);
      expect(Responsive.kolom(1440), 3);
    });

    test('batas maksimum kolom dihormati', () {
      expect(Responsive.kolom(1440, maks: 2), 2);
      expect(Responsive.kolom(700, maks: 1), 1);
    });
  });

  group('Responsive.sempit / lebar', () {
    test('ponsel dianggap sempit, tablet tidak', () {
      expect(Responsive.sempit(400), isTrue);
      expect(Responsive.sempit(600), isFalse);
      expect(Responsive.lebar(899), isFalse);
      expect(Responsive.lebar(900), isTrue);
    });
  });
}
