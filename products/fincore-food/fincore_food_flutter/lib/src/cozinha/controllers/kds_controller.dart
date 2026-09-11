import 'package:flutter/foundation.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';
import 'package:fincore_core/usecase/estornar_lote_estoque_usecase.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/database/fincore_database.dart';
import '../../estoque/controllers/estoque_controller.dart';

/// Controller do KDS (Kitchen Display System)
///
/// Gerencia a máquina de estados das ordens de preparo e sincroniza com
/// a tabela principal de pedidos e estoque.
class KdsController extends ChangeNotifier {
  final OrdemPreparoRepository _ordemRepo;
  final EstornarLoteEstoqueUseCase _estornoUseCase;
  final TenantContext _context;

  List<OrdemPreparo> _ordens = [];
  bool _isLoading = false;
  String? _errorMessage;

  KdsController({
    OrdemPreparoRepository? ordemRepo,
    EstornarLoteEstoqueUseCase? estornoUseCase,
    TenantContext? context,
  })  : _ordemRepo =
            ordemRepo ?? DependencyInjection().get<OrdemPreparoRepository>(),
        _estornoUseCase = estornoUseCase ??
            DependencyInjection().get<EstornarLoteEstoqueUseCase>(),
        _context = context ?? DependencyInjection().get<TenantContext>();

  List<OrdemPreparo> get ordens => _ordens;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtragem de ordens por status para a tela do KDS
  List<OrdemPreparo> get ordensPendentes =>
      _ordens.where((o) => o.status == StatusOrdemPreparo.pendente).toList();

  List<OrdemPreparo> get ordensEmPreparo =>
      _ordens.where((o) => o.status == StatusOrdemPreparo.emPreparo).toList();

  List<OrdemPreparo> get ordensProntas =>
      _ordens.where((o) => o.status == StatusOrdemPreparo.pronto).toList();

  /// Carrega as ordens ativas da cozinha
  Future<void> carregarOrdens({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _ordens = await _ordemRepo.findAtivasKds();
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Falha ao carregar fila do KDS: $e';
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _syncPedidoStatus(
    String pedidoId,
    String tenantId,
    StatusOrdemPreparo novoStatus,
  ) async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final now = DateTime.now().toUtc();

      final statusStr = switch (novoStatus) {
        StatusOrdemPreparo.pendente  => 'confirmado',
        StatusOrdemPreparo.emPreparo => 'em_preparo',
        StatusOrdemPreparo.pronto    => 'pronto',
        StatusOrdemPreparo.entregue  => 'entregue',
        StatusOrdemPreparo.cancelado => 'cancelado',
      };

      await (db.update(db.pedidosTable)
            ..where((t) => t.id.equals(pedidoId)))
          .write(PedidosTableCompanion(
        status: Value(statusStr),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));

      try {
        final outboxService = DependencyInjection().get<OutboxService>();
        await outboxService.enqueue(
          entity: 'Pedido',
          entityId: pedidoId,
          action: 'update',
          payload: {
            'id': pedidoId,
            'tenantId': tenantId,
            'status': statusStr,
            'updatedAt': now.toIso8601String(),
          },
          version: 1,
        );
      } catch (e) {
        debugPrint('[KDS] Erro ao registrar status no outbox: $e');
      }

      if (novoStatus == StatusOrdemPreparo.entregue ||
          novoStatus == StatusOrdemPreparo.cancelado) {
        try {
          final estoqueCtrl = DependencyInjection().get<EstoqueController>();
          await estoqueCtrl.recalcularReservasEEstoques();
        } catch (e) {
          debugPrint('[KDS] Erro ao sincronizar estoque: $e');
        }
      }
    } catch (e) {
      debugPrint('[KDS] Erro ao sincronizar status do pedido: $e');
    }
  }

  /// Altera o estado da ordem para em preparo (inicia timer)
  Future<void> iniciarPreparo(String ordemId, String operadorId) async {
    final index = _ordens.indexWhere((o) => o.id == ordemId);
    if (index == -1) return;

    final ordem = _ordens[index];
    if (ordem.status != StatusOrdemPreparo.pendente) return;

    final agora = DateTime.now();
    final updated = ordem.copyWith(
      status: StatusOrdemPreparo.emPreparo,
      operadorId: operadorId,
      iniciadaEm: agora,
      metadata: SyncMetadata(
        version: ordem.metadata.version + 1,
        createdAt: ordem.metadata.createdAt,
        updatedAt: agora,
        createdBy: ordem.metadata.createdBy,
        updatedBy: operadorId,
        syncStatus: SyncStatus.pending,
      ),
    );

    await _ordemRepo.save(updated);
    await _syncPedidoStatus(ordem.pedidoId, ordem.tenantId, StatusOrdemPreparo.emPreparo);

    _ordens[index] = updated;
    notifyListeners();
  }

  /// Altera o estado da ordem para pronto (conclui o preparo)
  Future<void> concluirPreparo(String ordemId, String operadorId) async {
    final index = _ordens.indexWhere((o) => o.id == ordemId);
    if (index == -1) return;

    final ordem = _ordens[index];
    if (ordem.status != StatusOrdemPreparo.emPreparo) return;

    final agora = DateTime.now();
    final updated = ordem.copyWith(
      status: StatusOrdemPreparo.pronto,
      concluidaEm: agora,
      metadata: SyncMetadata(
        version: ordem.metadata.version + 1,
        createdAt: ordem.metadata.createdAt,
        updatedAt: agora,
        createdBy: ordem.metadata.createdBy,
        updatedBy: operadorId,
        syncStatus: SyncStatus.pending,
      ),
    );

    await _ordemRepo.save(updated);
    await _syncPedidoStatus(ordem.pedidoId, ordem.tenantId, StatusOrdemPreparo.pronto);

    _ordens[index] = updated;
    notifyListeners();
  }

  /// Marca a ordem como entregue (remove da fila ativa do KDS)
  Future<void> entregarOrdem(String ordemId, String operadorId) async {
    final index = _ordens.indexWhere((o) => o.id == ordemId);
    if (index == -1) return;

    final ordem = _ordens[index];
    if (ordem.status != StatusOrdemPreparo.pronto) return;

    final agora = DateTime.now();
    final updated = ordem.copyWith(
      status: StatusOrdemPreparo.entregue,
      metadata: SyncMetadata(
        version: ordem.metadata.version + 1,
        createdAt: ordem.metadata.createdAt,
        updatedAt: agora,
        createdBy: ordem.metadata.createdBy,
        updatedBy: operadorId,
        syncStatus: SyncStatus.pending,
      ),
    );

    await _ordemRepo.save(updated);
    await _syncPedidoStatus(ordem.pedidoId, ordem.tenantId, StatusOrdemPreparo.entregue);

    _ordens.removeAt(index);
    notifyListeners();
  }

  /// Cancela a ordem e executa o estorno LIFO de insumos associados
  Future<void> cancelarOrdem(String ordemId, String operadorId,
      {String? motivo}) async {
    final index = _ordens.indexWhere((o) => o.id == ordemId);
    if (index == -1) return;

    final ordem = _ordens[index];
    if (ordem.status == StatusOrdemPreparo.entregue ||
        ordem.status == StatusOrdemPreparo.cancelado) {
      return;
    }

    final agora = DateTime.now();
    final updated = ordem.copyWith(
      status: StatusOrdemPreparo.cancelado,
      canceladaEm: agora,
      metadata: SyncMetadata(
        version: ordem.metadata.version + 1,
        createdAt: ordem.metadata.createdAt,
        updatedAt: agora,
        createdBy: ordem.metadata.createdBy,
        updatedBy: operadorId,
        syncStatus: SyncStatus.pending,
      ),
    );

    // Salvar cancelamento
    await _ordemRepo.save(updated);
    await _syncPedidoStatus(ordem.pedidoId, ordem.tenantId, StatusOrdemPreparo.cancelado);

    // Executar algoritmo LIFO para cada item da ordem de preparo cancelada
    for (final item in ordem.itens) {
      final qtdCentesimos = (item.quantidade * 100).toInt();
      await _estornoUseCase.execute(
        produtoId: item.produtoId,
        quantidadeCenteseimosEstornar: qtdCentesimos,
        operadorId: operadorId,
      );
    }

    _ordens.removeAt(index);
    notifyListeners();
  }
}
