import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../database/app_database.dart';
import '../../../domain/ports/grupo_preco_repository_port.dart';
import '../../../domain/ports/pedido_repository_port.dart';
import '../../../domain/usecases/recalcular_preco_usecase.dart';
import '../../../models/domain_models.dart';
import '../../../services/settings_service.dart';

class PedidoProvider extends ChangeNotifier {
  final IPedidoRepository _pedidoRepository;
  final RecalcularPrecoUseCase _recalcularPrecoUseCase;

  Cliente? cliente;
  final List<ItemCarrinho> itens = [];
  List<ResumoGrupo> resumos = [];
  String tipoEntrega = 'Entrega';
  String formaPagamento = 'Pix';
  DateTime dataEntrega = DateTime.now().add(const Duration(hours: 2));
  String? erroPreco;
  bool salvando = false;

  PedidoProvider({
    required IPedidoRepository pedidoRepository,
    required IGrupoPrecoRepository grupoPrecoRepository,
  })  : _pedidoRepository = pedidoRepository,
        _recalcularPrecoUseCase = RecalcularPrecoUseCase(grupoPrecoRepository);

  int get subtotalCentavos =>
      itens.fold<int>(0, (a, b) => a + b.totalCentavos);

  void selecionarCliente(Cliente? c) {
    cliente = c;
    notifyListeners();
  }

  void alterarTipoEntrega(String tipo) {
    tipoEntrega = tipo;
    notifyListeners();
  }

  void alterarFormaPagamento(String pagamento) {
    formaPagamento = pagamento;
    notifyListeners();
  }

  void alterarDataEntrega(DateTime data) {
    dataEntrega = data;
    notifyListeners();
  }

  Future<void> adicionarProduto(
      Produto produto, GruposPrecoData grupo, int quantidade) async {
    final existente =
        itens.where((i) => i.produto.id == produto.id).firstOrNull;
    if (existente == null) {
      itens.add(ItemCarrinho(
          produto: produto, grupo: grupo, quantidade: quantidade));
    } else {
      existente.quantidade += quantidade;
    }
    await recalcularPrecos();
  }

  Future<void> removerItem(ItemCarrinho item) async {
    itens.remove(item);
    await recalcularPrecos();
  }

  Future<void> recalcularPrecos() async {
    try {
      resumos = await _recalcularPrecoUseCase(itens);
      erroPreco = null;
    } on ValidationException catch (e) {
      resumos = [];
      erroPreco = e.message;
    } catch (e) {
      resumos = [];
      erroPreco = e.toString();
    }
    notifyListeners();
  }

  Future<int> salvarPedido({
    required AppSettings settings,
    required int taxaEntregaCentavos,
    int? trocoParaCentavos,
    String observacoes = '',
  }) async {
    if (cliente == null) {
      throw const ValidationException('Selecione um cliente.');
    }
    if (itens.isEmpty) {
      throw const ValidationException('Adicione ao menos um produto.');
    }
    if (erroPreco != null) {
      throw ValidationException(erroPreco!);
    }

    salvando = true;
    notifyListeners();
    try {
      final id = await _pedidoRepository.criar(
        cliente: cliente!,
        entrega: dataEntrega,
        tipo: tipoEntrega,
        pagamento: formaPagamento,
        troco: trocoParaCentavos,
        observacoes: observacoes,
        taxa: tipoEntrega == 'Entrega' ? taxaEntregaCentavos : 0,
        itens: itens,
      );
      limparFormulario();
      return id;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  void limparFormulario() {
    cliente = null;
    itens.clear();
    resumos.clear();
    erroPreco = null;
    tipoEntrega = 'Entrega';
    formaPagamento = 'Pix';
    dataEntrega = DateTime.now().add(const Duration(hours: 2));
    notifyListeners();
  }
}
