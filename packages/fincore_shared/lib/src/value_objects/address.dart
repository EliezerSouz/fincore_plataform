import 'package:meta/meta.dart';

/// Value Object para endereço completo brasileiro.
///
/// Agrupa logradouro, número, complemento, bairro, cidade, UF e CEP.
/// Fornece representações em uma ou múltiplas linhas para exibição
/// em telas, cupons e documentos.
///
/// Exemplo:
/// ```dart
/// final addr = FincoreAddress(
///   logradouro: 'Rua das Flores',
///   numero: '123',
///   bairro: 'Centro',
///   cidade: 'Sorocaba',
///   uf: 'SP',
///   cep: '18000-000',
/// );
/// print(addr.singleLine);
/// // Rua das Flores, 123 - Centro - Sorocaba/SP - 18000-000
/// ```
@immutable
class FincoreAddress {
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String cep;

  const FincoreAddress({
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.cep = '',
  });

  const FincoreAddress.empty()
      : logradouro = '',
        numero = '',
        complemento = '',
        bairro = '',
        cidade = '',
        uf = '',
        cep = '';

  bool get isEmpty =>
      logradouro.isEmpty &&
      numero.isEmpty &&
      bairro.isEmpty &&
      cidade.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Endereço em uma linha para exibição compacta.
  String get singleLine {
    final parts = <String>[];
    if (logradouro.isNotEmpty) {
      parts.add(numero.isNotEmpty ? '$logradouro, $numero' : logradouro);
    }
    if (complemento.isNotEmpty) parts.add(complemento);
    if (bairro.isNotEmpty) parts.add(bairro);
    if (cidade.isNotEmpty) {
      parts.add(uf.isNotEmpty ? '$cidade/$uf' : cidade);
    }
    if (cep.isNotEmpty) parts.add(cep);
    return parts.join(' - ');
  }

  /// Endereço em duas linhas para cupom térmico.
  List<String> get twoLines {
    final line1 = <String>[];
    final line2 = <String>[];

    if (logradouro.isNotEmpty) {
      line1.add(numero.isNotEmpty ? '$logradouro, $numero' : logradouro);
    }
    if (complemento.isNotEmpty) line1.add(complemento);
    if (bairro.isNotEmpty) line2.add(bairro);
    if (cidade.isNotEmpty) {
      line2.add(uf.isNotEmpty ? '$cidade/$uf' : cidade);
    }
    if (cep.isNotEmpty) line2.add(cep);

    final result = <String>[];
    if (line1.isNotEmpty) result.add(line1.join(' - '));
    if (line2.isNotEmpty) result.add(line2.join(' - '));
    return result;
  }

  FincoreAddress copyWith({
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? uf,
    String? cep,
  }) {
    return FincoreAddress(
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      uf: uf ?? this.uf,
      cep: cep ?? this.cep,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FincoreAddress &&
      other.logradouro == logradouro &&
      other.numero == numero &&
      other.bairro == bairro &&
      other.cidade == cidade &&
      other.uf == uf &&
      other.cep == cep;

  @override
  int get hashCode =>
      Object.hash(logradouro, numero, bairro, cidade, uf, cep);

  @override
  String toString() => singleLine;
}
