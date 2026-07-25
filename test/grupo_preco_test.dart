import 'package:flutter_test/flutter_test.dart';
import 'package:salgaderia/core/errors/app_exceptions.dart';
import 'package:salgaderia/domain/usecases/validar_faixas_preco_usecase.dart';
import 'package:salgaderia/models/domain_models.dart';

void main() {
  const useCase = ValidarFaixasPrecoUseCase();

  group('Validação de faixas por grupo', () {
    test('aceita faixas sequenciais válidas', () {
      expect(
          () => useCase(const [
                FaixaInput(1, 24, 150),
                FaixaInput(25, 49, 120),
                FaixaInput(50, null, 100)
              ]),
          returnsNormally);
    });

    test('rejeita faixas sobrepostas', () {
      expect(
          () => useCase(
              const [FaixaInput(1, 30, 150), FaixaInput(25, 49, 120)]),
          throwsA(isA<ValidationException>()));
    });

    test('rejeita preço zerado', () {
      expect(
          () => useCase(const [FaixaInput(1, null, 0)]),
          throwsA(isA<ValidationException>()));
    });
  });
}
