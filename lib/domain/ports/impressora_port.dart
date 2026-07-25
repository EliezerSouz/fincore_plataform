import '../../models/domain_models.dart';
import '../../services/settings_service.dart';

/// Contrato da porta de impressão.
///
/// Permite desacoplar a lógica de negócio dos drivers de hardware (ESC/POS, PDF, Windows Spooler).
abstract class IImpressoraPort {
  /// Envia um cupom de pedido para a impressora configurada.
  Future<void> imprimirPedido(PedidoCompleto pedido, AppSettings settings);

  /// Testa a conectividade com o destino de impressão configurado.
  Future<bool> testarConexao(String destino);
}
