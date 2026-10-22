import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';

void main() {
  group('PixGenerator & Padrão Bacen EMV', () {
    test('Normalização de Chave PIX Celular para E.164 (+55)', () {
      expect(PixGenerator.normalizarChave(chave: '35998339825', tipo: 'Celular'), equals('+5535998339825'));
      expect(PixGenerator.normalizarChave(chave: '(35) 99833-9825', tipo: 'Celular'), equals('+5535998339825'));
      expect(PixGenerator.normalizarChave(chave: '5535998339825', tipo: 'Celular'), equals('+5535998339825'));
    });

    test('Normalização de CPF e CNPJ (apenas dígitos)', () {
      expect(PixGenerator.normalizarChave(chave: '123.456.789-01', tipo: 'CPF'), equals('12345678901'));
      expect(PixGenerator.normalizarChave(chave: '12.345.678/0001-90', tipo: 'CNPJ'), equals('12345678000190'));
    });

    test('Geração de Payload Copia e Cola Estático Bacen', () {
      final payload = PixGenerator.gerarCopiaCola(
        chave: '35998339825',
        favorecido: 'Solange Salgados',
        cidade: 'Pouso Alegre',
        valor: 45.50,
        tipoChave: 'Celular',
      );

      // Deve começar com 000201
      expect(payload.startsWith('000201'), isTrue);

      // NÃO deve conter a Tag 01 com '12' (que quebra nos bancos)
      expect(payload.contains('010212'), isFalse);

      // Deve conter o GUI oficial br.gov.bcb.pix
      expect(payload.contains('br.gov.bcb.pix'), isTrue);

      // Deve conter a chave celular em padrão E.164 (+55...)
      expect(payload.contains('+5535998339825'), isTrue);

      // Deve conter o valor 45.50 (Tag 540545.50)
      expect(payload.contains('540545.50'), isTrue);

      // Deve conter o nome e cidade saneados
      expect(payload.contains('SOLANGE SALGADOS'), isTrue);
      expect(payload.contains('POUSO ALEGRE'), isTrue);

      // Deve conter o sufixo 6304 + 4 hexadecimais de CRC
      expect(RegExp(r'6304[0-9A-F]{4}$').hasMatch(payload), isTrue);
    });
  });
}
