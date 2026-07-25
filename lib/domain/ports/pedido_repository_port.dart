import '../../database/app_database.dart';
import '../../models/domain_models.dart';

abstract class IPedidoRepository {
  Stream<List<Pedido>> observar({String busca = ''});
  Future<int> criar({
    required Cliente cliente,
    required DateTime entrega,
    required String tipo,
    required String pagamento,
    required int? troco,
    required String observacoes,
    required int taxa,
    required List<ItemCarrinho> itens,
    String prioridade = 'Normal',
    int? origemId,
    int? prioridadeId,
    DateTime? dataProducao,
    String statusFinanceiro = 'Pendente',
  });
  Future<PedidoCompleto> completo(int id);
  Future<void> alterarStatus(int id, String novoStatus);
  Future<int> duplicar(int id);
  Future<void> cancelar(int id);
  Future<void> editar({
    required int id,
    required Cliente cliente,
    required DateTime entrega,
    required String tipo,
    required String pagamento,
    required int? troco,
    required String observacoes,
    required int taxa,
    required List<ItemCarrinho> itens,
    String prioridade = 'Normal',
    int? origemId,
    int? prioridadeId,
    DateTime? dataProducao,
    String statusFinanceiro = 'Pendente',
  });

  // Eventos & Auditoria
  Future<List<EventosPedidoData>> obterEventos(int pedidoId);
  Future<void> registrarEvento({
    required int pedidoId,
    required String tipoEvento,
    required String titulo,
    required String descricao,
    int? usuarioId,
    String? usuarioNome,
    required int versao,
  });
  Future<void> reabrirPedido({
    required int pedidoId,
    required String novoStatus,
    required String motivo,
    required String observacao,
  });
  Future<void> reverterStatus({
    required int pedidoId,
    required String statusAnterior,
    required String motivo,
    required String observacao,
  });
  Future<void> confirmarPix({
    required int pedidoId,
    required String comprovantePix,
  });
}
