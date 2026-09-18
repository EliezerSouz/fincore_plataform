import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_core/fincore_core.dart';

void main() {
  group('StatusPrecedence Unit Tests', () {
    test('1. Hierarquia de ranks deve seguir a máquina de estados', () {
      expect(StatusPrecedence.getRank('rascunho'), equals(0));
      expect(StatusPrecedence.getRank('confirmado'), equals(1));
      expect(StatusPrecedence.getRank('pendente'), equals(1));
      expect(StatusPrecedence.getRank('em_preparo'), equals(2));
      expect(StatusPrecedence.getRank('emPreparo'), equals(2));
      expect(StatusPrecedence.getRank('pronto'), equals(3));
      expect(StatusPrecedence.getRank('entregue'), equals(4));
      expect(StatusPrecedence.getRank('finalizado'), equals(4));
      expect(StatusPrecedence.getRank('cancelado'), equals(99));
    });

    test('2. NUNCA deve permitir regressão de entregue para pronto', () {
      expect(StatusPrecedence.isHigherOrEqual('entregue', 'pronto'), isTrue);
      expect(StatusPrecedence.isHigherOrEqual('entregue', 'em_preparo'), isTrue);
      expect(StatusPrecedence.isHigherOrEqual('entregue', 'confirmado'), isTrue);

      expect(StatusPrecedence.shouldAllowTransition('entregue', 'pronto'), isFalse);
      expect(StatusPrecedence.shouldAllowTransition('entregue', 'em_preparo'), isFalse);
    });

    test('3. Transição progressiva válida deve ser permitida', () {
      expect(StatusPrecedence.shouldAllowTransition('confirmado', 'em_preparo'), isTrue);
      expect(StatusPrecedence.shouldAllowTransition('em_preparo', 'pronto'), isTrue);
      expect(StatusPrecedence.shouldAllowTransition('pronto', 'entregue'), isTrue);
    });

    test('4. Cancelamento pode ser aplicado sobre estados ativos', () {
      expect(StatusPrecedence.shouldAllowTransition('em_preparo', 'cancelado'), isTrue);
      expect(StatusPrecedence.shouldAllowTransition('pronto', 'cancelado'), isTrue);
      expect(StatusPrecedence.isHigherOrEqual('cancelado', 'entregue'), isTrue);
    });
  });
}
