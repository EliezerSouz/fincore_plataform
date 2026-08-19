import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/presentation/validators/fincore_validators.dart';

void main() {
  // ─── required ────────────────────────────────────────────────────────────────

  group('FincoreValidators.required', () {
    test('null → retorna mensagem de erro', () {
      expect(FincoreValidators.required(null), isNotNull);
    });

    test('string vazia → retorna mensagem de erro', () {
      expect(FincoreValidators.required(''), isNotNull);
    });

    test('só espaços → retorna mensagem de erro', () {
      expect(FincoreValidators.required('   '), isNotNull);
    });

    test('valor válido → retorna null', () {
      expect(FincoreValidators.required('texto'), isNull);
    });

    test('número como string → retorna null', () {
      expect(FincoreValidators.required('42'), isNull);
    });
  });

  // ─── requiredMsg ──────────────────────────────────────────────────────────────

  group('FincoreValidators.requiredMsg', () {
    const msg = 'Nome é obrigatório';
    final validator = FincoreValidators.requiredMsg(msg);

    test('vazio → retorna a mensagem customizada', () {
      expect(validator(''), equals(msg));
    });

    test('null → retorna a mensagem customizada', () {
      expect(validator(null), equals(msg));
    });

    test('valor preenchido → retorna null', () {
      expect(validator('Carlos'), isNull);
    });
  });

  // ─── minLength ─────────────────────────────────────────────────────────────

  group('FincoreValidators.minLength', () {
    final min3 = FincoreValidators.minLength(3);

    test('null → retorna null (deixa required tratar)', () {
      expect(min3(null), isNull);
    });

    test('vazio → retorna null (deixa required tratar)', () {
      expect(min3(''), isNull);
    });

    test('2 chars (< mín 3) → retorna erro', () {
      expect(min3('ab'), isNotNull);
    });

    test('3 chars (= mín) → retorna null', () {
      expect(min3('abc'), isNull);
    });

    test('10 chars (> mín) → retorna null', () {
      expect(min3('abcdefghij'), isNull);
    });

    test('espaços em branco não contam para o comprimento', () {
      expect(min3('  a  '), isNotNull); // trim → 'a' = 1 char
    });
  });

  // ─── maxLength ─────────────────────────────────────────────────────────────

  group('FincoreValidators.maxLength', () {
    final max5 = FincoreValidators.maxLength(5);

    test('null → retorna null', () {
      expect(max5(null), isNull);
    });

    test('5 chars (= máx) → retorna null', () {
      expect(max5('abcde'), isNull);
    });

    test('6 chars (> máx) → retorna erro', () {
      expect(max5('abcdef'), isNotNull);
    });

    test('3 chars (< máx) → retorna null', () {
      expect(max5('abc'), isNull);
    });
  });

  // ─── email ─────────────────────────────────────────────────────────────────

  group('FincoreValidators.email', () {
    test('null → retorna null (deixa required tratar)', () {
      expect(FincoreValidators.email(null), isNull);
    });

    test('vazio → retorna null (deixa required tratar)', () {
      expect(FincoreValidators.email(''), isNull);
    });

    test('email válido simples → retorna null', () {
      expect(FincoreValidators.email('usuario@dominio.com'), isNull);
    });

    test('email com subdomínio → retorna null', () {
      expect(FincoreValidators.email('user@mail.empresa.com.br'), isNull);
    });

    test('email com + e . → retorna null', () {
      expect(FincoreValidators.email('user.name+tag@empresa.org'), isNull);
    });

    test('sem @ → retorna erro', () {
      expect(FincoreValidators.email('usuariodominio.com'), isNotNull);
    });

    test('sem domínio → retorna erro', () {
      expect(FincoreValidators.email('usuario@'), isNotNull);
    });

    test('sem extensão → retorna erro', () {
      expect(FincoreValidators.email('usuario@dominio'), isNotNull);
    });

    test('com espaço → retorna erro', () {
      expect(FincoreValidators.email('usuario @dominio.com'), isNotNull);
    });
  });

  // ─── telefone ──────────────────────────────────────────────────────────────

  group('FincoreValidators.telefone', () {
    test('null → retorna null', () {
      expect(FincoreValidators.telefone(null), isNull);
    });

    test('vazio → retorna null', () {
      expect(FincoreValidators.telefone(''), isNull);
    });

    test('11 dígitos (celular) → retorna null', () {
      expect(FincoreValidators.telefone('11999999999'), isNull);
    });

    test('10 dígitos (fixo) → retorna null', () {
      expect(FincoreValidators.telefone('1133334444'), isNull);
    });

    test('com formatação (11) 99999-9999 → retorna null', () {
      expect(FincoreValidators.telefone('(11) 99999-9999'), isNull);
    });

    test('9 dígitos → retorna erro', () {
      expect(FincoreValidators.telefone('119999999'), isNotNull);
    });

    test('12 dígitos → retorna erro', () {
      expect(FincoreValidators.telefone('119999999999'), isNotNull);
    });

    test('letras → retorna erro (0 dígitos)', () {
      expect(FincoreValidators.telefone('abcde'), isNotNull);
    });
  });

  // ─── cpfCnpj ───────────────────────────────────────────────────────────────

  group('FincoreValidators.cpfCnpj', () {
    test('null → retorna null', () {
      expect(FincoreValidators.cpfCnpj(null), isNull);
    });

    test('11 dígitos (CPF) → retorna null', () {
      expect(FincoreValidators.cpfCnpj('12345678901'), isNull);
    });

    test('14 dígitos (CNPJ) → retorna null', () {
      expect(FincoreValidators.cpfCnpj('12345678000190'), isNull);
    });

    test('CPF com formatação 123.456.789-01 → retorna null', () {
      expect(FincoreValidators.cpfCnpj('123.456.789-01'), isNull);
    });

    test('CNPJ com formatação 12.345.678/0001-90 → retorna null', () {
      expect(FincoreValidators.cpfCnpj('12.345.678/0001-90'), isNull);
    });

    test('10 dígitos → retorna erro', () {
      expect(FincoreValidators.cpfCnpj('1234567890'), isNotNull);
    });

    test('12 dígitos → retorna erro', () {
      expect(FincoreValidators.cpfCnpj('123456789012'), isNotNull);
    });
  });

  // ─── username ──────────────────────────────────────────────────────────────

  group('FincoreValidators.username', () {
    test('null → retorna null', () {
      expect(FincoreValidators.username(null), isNull);
    });

    test('letras e números → retorna null', () {
      expect(FincoreValidators.username('carlos123'), isNull);
    });

    test('com ponto → retorna null', () {
      expect(FincoreValidators.username('carlos.oliveira'), isNull);
    });

    test('com sublinhado → retorna null', () {
      expect(FincoreValidators.username('carlos_oliveira'), isNull);
    });

    test('com espaço → retorna erro', () {
      expect(FincoreValidators.username('carlos oliveira'), isNotNull);
    });

    test('com @ → retorna erro', () {
      expect(FincoreValidators.username('carlos@empresa'), isNotNull);
    });

    test('com hífen → retorna erro', () {
      expect(FincoreValidators.username('carlos-oliveira'), isNotNull);
    });
  });

  // ─── positiveDecimal ───────────────────────────────────────────────────────

  group('FincoreValidators.positiveDecimal', () {
    test('null → retorna null', () {
      expect(FincoreValidators.positiveDecimal(null), isNull);
    });

    test('4.50 → retorna null', () {
      expect(FincoreValidators.positiveDecimal('4.50'), isNull);
    });

    test('4,50 (vírgula brasileira) → retorna null', () {
      expect(FincoreValidators.positiveDecimal('4,50'), isNull);
    });

    test('0 → retorna erro (não é positivo)', () {
      expect(FincoreValidators.positiveDecimal('0'), isNotNull);
    });

    test('-5.00 → retorna erro', () {
      expect(FincoreValidators.positiveDecimal('-5.00'), isNotNull);
    });

    test('texto "abc" → retorna erro', () {
      expect(FincoreValidators.positiveDecimal('abc'), isNotNull);
    });
  });

  // ─── nonNegativeInteger ────────────────────────────────────────────────────

  group('FincoreValidators.nonNegativeInteger', () {
    test('null → retorna null', () {
      expect(FincoreValidators.nonNegativeInteger(null), isNull);
    });

    test('0 → retorna null', () {
      expect(FincoreValidators.nonNegativeInteger('0'), isNull);
    });

    test('30 → retorna null', () {
      expect(FincoreValidators.nonNegativeInteger('30'), isNull);
    });

    test('-1 → retorna erro', () {
      expect(FincoreValidators.nonNegativeInteger('-1'), isNotNull);
    });

    test('3.5 (decimal) → retorna erro', () {
      expect(FincoreValidators.nonNegativeInteger('3.5'), isNotNull);
    });

    test('"abc" → retorna erro', () {
      expect(FincoreValidators.nonNegativeInteger('abc'), isNotNull);
    });
  });

  // ─── integer ───────────────────────────────────────────────────────────────

  group('FincoreValidators.integer', () {
    test('42 → retorna null', () {
      expect(FincoreValidators.integer('42'), isNull);
    });

    test('-5 → retorna null (inteiro negativo é válido)', () {
      expect(FincoreValidators.integer('-5'), isNull);
    });

    test('3.5 → retorna erro', () {
      expect(FincoreValidators.integer('3.5'), isNotNull);
    });

    test('"texto" → retorna erro', () {
      expect(FincoreValidators.integer('texto'), isNotNull);
    });
  });

  // ─── decimal ───────────────────────────────────────────────────────────────

  group('FincoreValidators.decimal', () {
    test('3.14 → retorna null', () {
      expect(FincoreValidators.decimal('3.14'), isNull);
    });

    test('3,14 (vírgula) → retorna null', () {
      expect(FincoreValidators.decimal('3,14'), isNull);
    });

    test('-2.5 → retorna null', () {
      expect(FincoreValidators.decimal('-2.5'), isNull);
    });

    test('"texto" → retorna erro', () {
      expect(FincoreValidators.decimal('texto'), isNotNull);
    });
  });

  // ─── compose ───────────────────────────────────────────────────────────────

  group('FincoreValidators.compose', () {
    final validator = FincoreValidators.compose([
      FincoreValidators.required,
      FincoreValidators.email,
    ]);

    test('vazio → retorna erro do required (primeiro validator falha)', () {
      final result = validator('');
      expect(result, isNotNull);
      expect(result, equals('Campo obrigatório'));
    });

    test('email inválido → retorna erro do email (segundo validator falha)', () {
      final result = validator('nao-e-email');
      expect(result, isNotNull);
      expect(result, equals('E-mail inválido'));
    });

    test('email válido e preenchido → retorna null', () {
      expect(validator('user@dominio.com'), isNull);
    });

    group('compose com required + minLength(3)', () {
      final v = FincoreValidators.compose([
        FincoreValidators.required,
        FincoreValidators.minLength(3),
      ]);

      test('vazio → erro de required', () {
        expect(v(''), equals('Campo obrigatório'));
      });

      test('2 chars → erro de minLength', () {
        expect(v('ab'), contains('3'));
      });

      test('3 chars → null', () {
        expect(v('abc'), isNull);
      });
    });
  });
}
