import '../value_objects/money.dart';
import '../value_objects/phone.dart';
import '../value_objects/cpf_cnpj.dart';
import '../value_objects/pix_key.dart';
import '../value_objects/misc_value_objects.dart';
import '../value_objects/address.dart';

/// Formatador centralizado para valores monetários (BRL).
///
/// Nunca formatar moeda diretamente na UI — usar sempre este formatador.
class FincoreMoneyFormatter {
  const FincoreMoneyFormatter._();

  /// Formata centavos como `R$ 1.234,56`.
  static String format(int centavos) =>
      FinCoreMoney.fromCentavos(centavos).formatted;

  /// Formata centavos sem símbolo: `1.234,56`.
  static String formatRaw(int centavos) =>
      FinCoreMoney.fromCentavos(centavos).formattedRaw;

  /// Formata um [FinCoreMoney] como `R$ 1.234,56`.
  static String formatMoney(FinCoreMoney money) => money.formatted;
}

/// Formatador centralizado para telefones brasileiros.
class FincorePhoneFormatter {
  const FincorePhoneFormatter._();

  /// Formata uma string de telefone como `(15) 99999-9999`.
  static String format(String raw) => FincorePhone.parse(raw).formatted;

  /// Formata um [FincorePhone] como `(15) 99999-9999`.
  static String formatPhone(FincorePhone phone) => phone.formatted;
}

/// Formatador centralizado para CPF e CNPJ.
class FinCoreCpfCnpjFormatter {
  const FinCoreCpfCnpjFormatter._();

  /// Formata automaticamente CPF (`###.###.###-##`) ou CNPJ (`##.###.###/####-##`).
  static String format(String raw) => FinCoreCpfCnpj.parse(raw).formatted;

  /// Formata um [FinCoreCpfCnpj] existente.
  static String formatDoc(FinCoreCpfCnpj doc) => doc.formatted;
}

/// Formatador centralizado para datas e horários.
///
/// Toda formatação de DateTime no sistema deve passar por aqui.
class FinCoreDateFormatter {
  const FinCoreDateFormatter._();

  /// Formata como `27/07/2025`.
  static String formatDate(DateTime dt) {
    return '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year}';
  }

  /// Formata como `14:35`.
  static String formatTime(DateTime dt) {
    return '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  /// Formata como `27/07/2025 14:35`.
  static String formatDateTime(DateTime dt) {
    return '${formatDate(dt)} ${formatTime(dt)}';
  }

  /// Formata como `27/07` (dia/mês sem ano — útil para dashboards).
  static String formatShortDate(DateTime dt) {
    return '${_pad(dt.day)}/${_pad(dt.month)}';
  }

  /// Formata como "há X minutos", "há X horas", "há X dias" (tempo relativo).
  static String formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    return 'há ${diff.inDays} dias';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Formatador para chaves PIX.
class FincorePixFormatter {
  const FincorePixFormatter._();

  /// Formata a chave PIX para exibição no cupom/tela.
  static String format(FincorePixKey key) => key.formatted;

  /// Formata a chave para uso em payloads EMV.
  static String formatClean(FincorePixKey key) => key.clean;

  /// Retorna o label do tipo: "CPF", "E-mail", "Chave Aleatória" etc.
  static String tipoLabel(FincorePixKey key) => key.tipoLabel;
}

/// Formatador para CEP.
class FincorePostalCodeFormatter {
  const FincorePostalCodeFormatter._();

  /// Formata como `18000-000`.
  static String format(String raw) =>
      FincorePostalCode.parse(raw).formatted;
}

/// Formatador para endereço.
class FincoreAddressFormatter {
  const FincoreAddressFormatter._();

  /// Formata o endereço em uma única linha.
  static String format(FincoreAddress address) => address.singleLine;

  /// Retorna lista de linhas para impressão em cupom térmico.
  static List<String> formatForPrint(FincoreAddress address) =>
      address.twoLines;
}

/// Formatador para percentual.
class FincorePercentageFormatter {
  const FincorePercentageFormatter._();

  /// Formata como `10,50%`.
  static String format(double value) =>
      FincorePercentage(value).formatted;
}
