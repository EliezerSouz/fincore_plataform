import 'package:intl/intl.dart';

/// Formatadores de domínio da Salgaderia.
///
/// Centralizado aqui para que a camada de tema não carregue responsabilidades
/// de apresentação de dados, e para facilitar a migração futura para o backend.
final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Formata [centavos] como moeda brasileira. Ex.: 8500 → "R\$ 85,00"
String dinheiro(int centavos) => _moeda.format(centavos / 100);

/// Formata [numero] com 6 dígitos com zeros à esquerda. Ex.: 19 → "000019"
String pedidoNumero(int numero) => numero.toString().padLeft(6, '0');
