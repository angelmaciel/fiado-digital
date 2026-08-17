import 'package:flutter_test/flutter_test.dart';

import 'package:fiado_digital/src/core/utils/guaranies.dart';

void main() {
  group('formatearGuaranies', () {
    test('separa los miles con punto y agrega el sufijo', () {
      expect(formatearGuaranies(150000), '150.000 Gs');
      expect(formatearGuaranies(0), '0 Gs');
    });
  });

  group('parsearGuaranies', () {
    test('ignora puntos, espacios y el sufijo que tipea el despensero', () {
      expect(parsearGuaranies('150.000'), 150000);
      expect(parsearGuaranies('150000 Gs'), 150000);
      expect(parsearGuaranies(' 25 000 '), 25000);
    });

    test('devuelve null cuando no hay ningún dígito', () {
      expect(parsearGuaranies(''), isNull);
      expect(parsearGuaranies('Gs'), isNull);
    });
  });
}
