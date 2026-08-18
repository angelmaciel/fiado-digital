import 'package:flutter_test/flutter_test.dart';
import 'package:fiado_digital/src/core/utils/whatsapp.dart';

void main() {
  group('WhatsApp.normalizar', () {
    test('convierte el formato local paraguayo al internacional', () {
      expect(WhatsApp.normalizar('0981 234 567'), '595981234567');
      expect(WhatsApp.normalizar('0971-445-128'), '595971445128');
    });

    test('acepta un número que ya trae el código de país', () {
      expect(WhatsApp.normalizar('+595 981 234567'), '595981234567');
      expect(WhatsApp.normalizar('595981234567'), '595981234567');
    });

    test('acepta el celular sin cero ni prefijo', () {
      expect(WhatsApp.normalizar('981234567'), '595981234567');
    });

    test('rechaza lo que no puede ser un teléfono', () {
      expect(WhatsApp.normalizar(null), isNull);
      expect(WhatsApp.normalizar(''), isNull);
      expect(WhatsApp.normalizar('sin numero'), isNull);
      expect(WhatsApp.normalizar('123'), isNull);
      expect(WhatsApp.normalizar('09812345678901'), isNull);
    });
  });
}
