import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../data/services/impressora_esc_pos.dart';
import '../database/app_database.dart';
import '../domain/ports/impressora_port.dart';
import '../models/domain_models.dart';
import '../repositories/repositories.dart';
import '../services/settings_service.dart';

class AppViewModel extends ChangeNotifier {
  final AppDatabase db;
  final IImpressoraPort impressoraPort;

  late final ProdutoRepository produtos = ProdutoRepository(db);
  late final GrupoPrecoRepository gruposPreco = GrupoPrecoRepository(db);
  late final ClienteRepository clientes = ClienteRepository(db);
  late final PedidoRepository pedidos = PedidoRepository(db);
  late final SettingsService settingsService = SettingsService(db);

  AppSettings settings = const AppSettings();
  int pagina = 0;
  bool ocupado = false;

  AppViewModel(this.db, {IImpressoraPort? impressora})
      : impressoraPort = impressora ?? const ImpressoraEscPos() {
    settingsService.carregar().then((v) {
      settings = v;
      reconciliarReservasEstoque();
      notifyListeners();
    });
  }

  Future<void> reconciliarReservasEstoque() async {
    try {
      await db.transaction(() async {
        final prods = await db.select(db.produtos).get();
        for (final p in prods) {
          final query = db.select(db.itensPedido).join([
            innerJoin(db.pedidos, db.pedidos.id.equalsExp(db.itensPedido.pedidoId)),
          ])
            ..where(db.itensPedido.produtoId.equals(p.id))
            ..where(db.pedidos.status.isIn(const [
              'Pendente',
              'Em Preparo',
              'Pronto',
              'Em Rota',
              'Aguardando Cliente'
            ]));

          final rows = await query.get();
          int totalReservado = 0;
          for (final row in rows) {
            final item = row.readTable(db.itensPedido);
            totalReservado += item.quantidade;
          }

          final est = await (db.select(db.estoqueAtual)
                ..where((e) => e.produtoId.equals(p.id)))
              .getSingleOrNull();

          if (est != null) {
            await (db.update(db.estoqueAtual)
                  ..where((e) => e.produtoId.equals(p.id)))
                .write(EstoqueAtualCompanion(reservado: Value(totalReservado)));
          } else {
            await db.into(db.estoqueAtual).insert(
                  EstoqueAtualCompanion(
                    produtoId: Value(p.id),
                    saldoAtual: const Value(0),
                    reservado: Value(totalReservado),
                    atualizadoEm: Value(DateTime.now()),
                  ),
                );
          }
        }
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Erro na reconciliação de reservas: $e');
    }
  }

  void navegar(int i) {
    pagina = i;
    notifyListeners();
  }

  // Filtros Cruzados para Navegação Integrada ERP
  int? clienteFiltroId;
  String? clienteFiltroNome;
  int? produtoFiltroId;
  String? produtoFiltroNome;

  void navegarPedidosDoCliente(int clienteId, String nomeCliente, {int targetPageIndex = 4}) {
    clienteFiltroId = clienteId;
    clienteFiltroNome = nomeCliente;
    produtoFiltroId = null;
    produtoFiltroNome = null;
    pagina = targetPageIndex;
    notifyListeners();
  }

  void navegarPedidosDoProduto(int produtoId, String nomeProduto, {int targetPageIndex = 4}) {
    produtoFiltroId = produtoId;
    produtoFiltroNome = nomeProduto;
    clienteFiltroId = null;
    clienteFiltroNome = null;
    pagina = targetPageIndex;
    notifyListeners();
  }

  void limparFiltrosCruzados() {
    clienteFiltroId = null;
    clienteFiltroNome = null;
    produtoFiltroId = null;
    produtoFiltroNome = null;
    notifyListeners();
  }

  Produto? produtoPreSelecionadoProducao;
  int? quantidadeSugeridaProducao;

  void navegarProducao({required Produto produto, required int quantidade, int targetPageIndex = 3}) {
    produtoPreSelecionadoProducao = produto;
    quantidadeSugeridaProducao = quantidade;
    pagina = targetPageIndex;
    notifyListeners();
  }

  int? pedidoIdParaDestacar;
  String? filtroStatusSugerido;

  void navegarKanbanComDestaque({required int pedidoId, required String status, int targetPageIndex = 4}) {
    pedidoIdParaDestacar = pedidoId;
    filtroStatusSugerido = status;
    pagina = targetPageIndex;
    notifyListeners();
  }

  void limparDestaqueKanban() {
    pedidoIdParaDestacar = null;
    filtroStatusSugerido = null;
  }

  PedidoCompleto? pedidoParaRepetir;

  void navegarRepetirPedido(PedidoCompleto p, {int targetPageIndex = 11}) {
    pedidoParaRepetir = p;
    pagina = targetPageIndex;
    notifyListeners();
  }

  void limparRepetirPedido() {
    pedidoParaRepetir = null;
  }

  Future<int> salvarPedido({
    int? id,
    required Cliente cliente,
    required DateTime entrega,
    required String tipo,
    required String pagamento,
    int? troco,
    required String observacoes,
    required int taxa,
    required List<ItemCarrinho> itens,
    String prioridade = 'Normal',
    int? origemId,
    int? prioridadeId,
    DateTime? dataProducao,
    String statusFinanceiro = 'Pendente',
  }) async {
    ocupado = true;
    notifyListeners();
    try {
      if (id == null) {
        final newId = await pedidos.criar(
          cliente: cliente,
          entrega: entrega,
          tipo: tipo,
          pagamento: pagamento,
          troco: troco,
          observacoes: observacoes,
          taxa: taxa,
          itens: itens,
          prioridade: prioridade,
          origemId: origemId,
          prioridadeId: prioridadeId,
          dataProducao: dataProducao,
          statusFinanceiro: statusFinanceiro,
        );
        final completo = await pedidos.completo(newId);
        await impressoraPort.imprimirPedido(completo, settings);
        ocupado = false;
        notifyListeners();
        return newId;
      } else {
        await pedidos.editar(
          id: id,
          cliente: cliente,
          entrega: entrega,
          tipo: tipo,
          pagamento: pagamento,
          troco: troco,
          observacoes: observacoes,
          taxa: taxa,
          itens: itens,
          prioridade: prioridade,
          origemId: origemId,
          prioridadeId: prioridadeId,
          dataProducao: dataProducao,
          statusFinanceiro: statusFinanceiro,
        );
        ocupado = false;
        notifyListeners();
        return id;
      }
    } catch (e) {
      ocupado = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reimprimir(int id) async {
    final completo = await pedidos.completo(id);
    await impressoraPort.imprimirPedido(completo, settings);
  }

  Future<void> salvarSettings(AppSettings s) async {
    await settingsService.salvar(s);
    settings = s;
    notifyListeners();
  }

  // Métodos para Locais de Entrega de Clientes
  Stream<List<LocaisEntregaData>> observarLocaisEntrega(int clienteId) =>
      clientes.observarLocais(clienteId);

  Future<List<LocaisEntregaData>> obterLocaisEntrega(int clienteId) =>
      clientes.obterLocais(clienteId);

  Future<int> salvarLocalEntrega(LocaisEntregaCompanion local, {int? id}) async {
    final resId = await clientes.salvarLocal(local, id: id);
    notifyListeners();
    return resId;
  }

  Future<void> excluirLocalEntrega(int id) async {
    await clientes.excluirLocal(id);
    notifyListeners();
  }

  // Métodos para Controle de Estoque
  Stream<List<ProdutoComEstoque>> observarEstoque() {
    final query = db.select(db.produtos).join([
      leftOuterJoin(db.estoqueAtual, db.estoqueAtual.produtoId.equalsExp(db.produtos.id)),
    ])..where(db.produtos.ativo.equals(true))
      ..orderBy([OrderingTerm.asc(db.produtos.nome)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final prod = row.readTable(db.produtos);
        final est = row.readTableOrNull(db.estoqueAtual);
        return ProdutoComEstoque(
          produto: prod,
          saldoAtual: est?.saldoAtual ?? 0,
          reservado: est?.reservado ?? 0,
          reservadoComercial: est?.reservadoComercial ?? 0,
          reservadoOperacional: est?.reservadoOperacional ?? 0,
          estoqueMinimo: est?.estoqueMinimo ?? 0,
          estoqueIdeal: est?.estoqueIdeal ?? 0,
          loteMinimo: est?.loteMinimo ?? 1,
        );
      }).toList();
    });
  }

  Future<void> registrarProducaoDiaria({
    required int produtoId,
    required int quantidade,
    required String responsavel,
    required String observacao,
    DateTime? data,
  }) async {
    final dataRegistro = data ?? DateTime.now();
    await db.transaction(() async {
      final est = await (db.select(db.estoqueAtual)
            ..where((e) => e.produtoId.equals(produtoId)))
          .getSingleOrNull();

      final saldoAnterior = est?.saldoAtual ?? 0;
      final reservado = est?.reservado ?? 0;
      final saldoNovo = saldoAnterior + quantidade;

      await db.into(db.estoqueAtual).insertOnConflictUpdate(
            EstoqueAtualCompanion(
              produtoId: Value(produtoId),
              saldoAtual: Value(saldoNovo),
              reservado: Value(reservado),
              atualizadoEm: Value(DateTime.now()),
            ),
          );

      await db.into(db.movimentacoesEstoque).insert(
            MovimentacoesEstoqueCompanion(
              produtoId: Value(produtoId),
              tipoMovimentacao: const Value('ENTRADA_PRODUCAO'),
              quantidade: Value(quantidade),
              saldoAnterior: Value(saldoAnterior),
              saldoNovo: Value(saldoNovo),
              motivo: Value('Produção diária (Resp: $responsavel) ${observacao.isNotEmpty ? "- $observacao" : ""}'),
              criadoEm: Value(dataRegistro),
            ),
          );
    });
    notifyListeners();
  }

  Future<void> registrarAjusteManual({
    required int produtoId,
    required bool ehEntrada,
    required int quantidade,
    required String tipoAjuste,
    required String motivo,
  }) async {
    await db.transaction(() async {
      final est = await (db.select(db.estoqueAtual)
            ..where((e) => e.produtoId.equals(produtoId)))
          .getSingleOrNull();

      final saldoAnterior = est?.saldoAtual ?? 0;
      final reservado = est?.reservado ?? 0;
      final saldoNovo = ehEntrada ? (saldoAnterior + quantidade) : (saldoAnterior - quantidade).clamp(0, 999999);

      await db.into(db.estoqueAtual).insertOnConflictUpdate(
            EstoqueAtualCompanion(
              produtoId: Value(produtoId),
              saldoAtual: Value(saldoNovo),
              reservado: Value(reservado),
              atualizadoEm: Value(DateTime.now()),
            ),
          );

      await db.into(db.movimentacoesEstoque).insert(
            MovimentacoesEstoqueCompanion(
              produtoId: Value(produtoId),
              tipoMovimentacao: Value(ehEntrada ? 'AJUSTE_POSITIVO' : 'AJUSTE_NEGATIVO'),
              quantidade: Value(quantidade),
              saldoAnterior: Value(saldoAnterior),
              saldoNovo: Value(saldoNovo),
              motivo: Value('Ajuste ($tipoAjuste): $motivo'),
              criadoEm: Value(DateTime.now()),
            ),
          );
    });
    notifyListeners();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }
}
