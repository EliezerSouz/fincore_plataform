import 'package:flutter_test/flutter_test.dart';
import 'package:salgaderia/core/utils/formatters.dart';

void main() {
  test('formata número de pedido', () {
    expect(pedidoNumero(19), '000019');
  });

  test('formata valor em centavos', () {
    expect(dinheiro(8500), contains('85,00'));
  });
}
