import 'package:bengkel_digital/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.merek', () {
    test('menolak input kosong', () {
      expect(Validators.merek(''), isNotNull);
      expect(Validators.merek(null), isNotNull);
    });

    test('menolak karakter aneh', () {
      expect(Validators.merek('@@@'), isNotNull);
    });

    test('menerima merek wajar', () {
      expect(Validators.merek('Honda'), isNull);
      expect(Validators.merek('Yamaha'), isNull);
    });
  });

  group('Validators.tahun', () {
    test('menolak selain 4 digit', () {
      expect(Validators.tahun('21'), isNotNull);
      expect(Validators.tahun('20211'), isNotNull);
      expect(Validators.tahun('20a1'), isNotNull);
    });

    test('menolak tahun di luar rentang', () {
      expect(Validators.tahun('1899'), isNotNull);
      expect(Validators.tahun('3000'), isNotNull);
    });

    test('menerima tahun valid', () {
      expect(Validators.tahun('2021'), isNull);
    });
  });

  group('Validators.platNomor', () {
    test('menerima format plat Indonesia', () {
      expect(Validators.platNomor('B 1234 XYZ'), isNull);
      expect(Validators.platNomor('b1234xyz'), isNull);
      expect(Validators.platNomor('AB 12'), isNull);
    });

    test('menolak format salah', () {
      expect(Validators.platNomor('1234'), isNotNull);
      expect(Validators.platNomor('B 12345 XYZ'), isNotNull);
    });
  });

  group('Validators.kilometer', () {
    test('menolak bukan angka', () {
      expect(Validators.kilometer('12.500'), isNotNull);
      expect(Validators.kilometer('abc'), isNotNull);
    });

    test('menolak nilai di bawah batas minimal', () {
      expect(Validators.kilometer('1000', minimal: 5000), isNotNull);
    });

    test('menerima angka valid', () {
      expect(Validators.kilometer('0'), isNull);
      expect(Validators.kilometer('12500', minimal: 5000), isNull);
    });
  });

  group('Validators.biaya', () {
    test('menolak nol atau negatif', () {
      expect(Validators.biaya('0'), isNotNull);
      expect(Validators.biaya('-500'), isNotNull);
    });

    test('menerima biaya wajar', () {
      expect(Validators.biaya('75000'), isNull);
    });
  });
}
