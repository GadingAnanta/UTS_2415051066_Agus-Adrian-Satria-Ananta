import 'dart:convert';
import 'dart:io';

import 'package:bengkel_digital/models/tips_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Menguji parsing REST API memakai berkas `api/tips.json` yang sebenarnya,
/// sehingga isi data dan model selalu sinkron.
void main() {
  late Map<String, dynamic> berkas;

  setUpAll(() {
    final String isi = File('api/tips.json').readAsStringSync();
    berkas = jsonDecode(isi) as Map<String, dynamic>;
  });

  group('TipsData.fromJson', () {
    test('membaca seluruh bagian data', () {
      final TipsData data = TipsData.fromJson(berkas);

      expect(data.katalogMotor, isNotEmpty);
      expect(data.tipsPerawatan, isNotEmpty);
      expect(data.intervalServis, isNotEmpty);
      expect(data.diperbarui, isNotEmpty);
      expect(data.isEmpty, isFalse);
      expect(data.jumlahItem, greaterThan(20));
    });

    test('setiap katalog motor punya merek, model, dan kapasitas mesin', () {
      final TipsData data = TipsData.fromJson(berkas);

      for (final KatalogMotor motor in data.katalogMotor) {
        expect(motor.id, isNotEmpty);
        expect(motor.merek, isNotEmpty);
        expect(motor.model, isNotEmpty);
        expect(motor.kapasitasCc, greaterThan(0));
        expect(motor.labelKapasitas, contains('cc'));
      }
    });

    test('setiap tips punya judul, kategori, dan ringkasan', () {
      final TipsData data = TipsData.fromJson(berkas);

      for (final TipsPerawatan tips in data.tipsPerawatan) {
        expect(tips.judul, isNotEmpty);
        expect(tips.kategori, isNotEmpty);
        expect(tips.ringkasan, isNotEmpty);
        expect(tips.langkah, isNotEmpty);
      }
    });

    test('interval servis memakai kunci komponen yang dikenal aplikasi', () {
      final TipsData data = TipsData.fromJson(berkas);
      const Set<String> kunciDikenal = <String>{
        'oli_mesin',
        'oli_gearbox',
        'filter_udara',
        'busi',
        'kampas_rem',
        'rantai_belt',
        'aki',
        'ban',
      };

      for (final IntervalServisStandar item in data.intervalServis) {
        expect(kunciDikenal, contains(item.komponen));
        expect(item.nama, isNotEmpty);
        expect(item.intervalKm != null || item.intervalBulan != null, isTrue);
        expect(item.labelInterval, isNot('Tidak diatur'));
      }
    });

    test('JSON kosong tidak melempar error', () {
      final TipsData data = TipsData.fromJson(<String, dynamic>{});

      expect(data.katalogMotor, isEmpty);
      expect(data.tipsPerawatan, isEmpty);
      expect(data.intervalServis, isEmpty);
      expect(data.isEmpty, isTrue);
      expect(data.diperbarui, isEmpty);
      expect(data.versi, 1);
    });

    test('tipe data yang salah diabaikan, bukan crash', () {
      final TipsData data = TipsData.fromJson(<String, dynamic>{
        'katalog_motor': <dynamic>['bukan objek'],
        'tips_perawatan': 'bukan daftar',
        'interval_servis': <dynamic>[
          <String, dynamic>{'komponen': 'oli_mesin'},
        ],
      });

      expect(data.katalogMotor, isEmpty);
      expect(data.tipsPerawatan, isEmpty);
      // Butir yang tipenya benar tetap terbaca walau kolom lain kosong.
      expect(data.intervalServis, hasLength(1));
      expect(data.intervalServis.first.komponen, 'oli_mesin');
      expect(data.intervalServis.first.labelInterval, 'Tidak diatur');
    });

    test('angka berbentuk teks tetap terbaca', () {
      final KatalogMotor motor = KatalogMotor.fromJson(<String, dynamic>{
        'merek': 'Honda',
        'model': 'Beat',
        'kapasitas_cc': '110',
        'interval_servis_km': '4000',
      });

      expect(motor.kapasitasCc, 110);
      expect(motor.intervalServisKm, 4000);
      expect(motor.namaLengkap, 'Honda Beat');
      expect(motor.labelInterval, 'Servis tiap 4.000 km');
    });
  });
}
