import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

class FincoreFormatters {
  static final _telefone = [
    FilteringTextInputFormatter.digitsOnly,
    TelefoneInputFormatter(),
  ];
  static final _cnpjCpf = [
    FilteringTextInputFormatter.digitsOnly,
    CpfOuCnpjFormatter(),
  ];
  static final _cep = [
    FilteringTextInputFormatter.digitsOnly,
    CepInputFormatter(),
  ];
  static final _real = [
    FilteringTextInputFormatter.digitsOnly,
    RealInputFormatter(moeda: false),
  ];

  /// Retorna a lista de formatadores para Telefone ((##) #####-####)
  static List<TextInputFormatter> get telefone => _telefone;

  /// Retorna a lista de formatadores para CPF ou CNPJ (dinâmico)
  static List<TextInputFormatter> get cnpjCpf => _cnpjCpf;

  /// Retorna a lista de formatadores para CEP (##.###-###)
  static List<TextInputFormatter> get cep => _cep;

  /// Retorna a lista de formatadores para Valores em Reais (1.234,56)
  static List<TextInputFormatter> get real => _real;
}
