import 'package:flutter_test/flutter_test.dart';
import 'package:salgaderia/core/errors/app_exceptions.dart';
import 'package:salgaderia/domain/usecases/validar_faixas_preco_usecase.dart';
import 'package:salgaderia/models/domain_models.dart';

void main() {
  const useCase = ValidarFaixasPrecoUseCase();

  group('ValidarFaixasPrecoUseCase - Regras de Domínio', () {
    test('lança ValidationException se lista for vazia', () {
      expect(
        () => useCase([]),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Cadastre ao menos uma faixa'),
        )),
      );
    });

    test('lança ValidationException se quantidade minima < 1', () {
      expect(
        () => useCase([const FaixaInput(0, 10, 100)]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException se preço em centavos < 1', () {
      expect(
        () => useCase([const FaixaInput(1, 10, 0)]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException se máxima for menor que mínima', () {
      expect(
        () => useCase([const FaixaInput(10, 5, 100)]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException se houver faixas sobrepostas', () {
      expect(
        () => useCase([
          const FaixaInput(1, 20, 150),
          const FaixaInput(15, 30, 120),
        ]),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('sobrepostas'),
        )),
      );
    });

    test('aceita sequência perfeita de faixas contínuas', () {
      expect(
        () => useCase([
          const FaixaInput(1, 24, 150),
          const FaixaInput(25, 49, 120),
          const FaixaInput(50, null, 100),
        ]),
        returnsNormally,
      );
    });
  });
}
