import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';
import 'package:fincore_core/usecase/estornar_lote_estoque_usecase.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/database/fincore_database.dart';
import '../../estoque/controllers/estoque_controller.dart';
import '../../shared/data/sync/supabase_sync_service.dart';

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
  StreamSubscription? _syncSub;

  KdsController({
    OrdemPreparoRepository? ordemRepo,
    EstornarLoteEstoqueUseCase? estornoUseCase,
    TenantContext? context,
  })  : _ordemRepo =
            ordemRepo ?? DependencyInjection().get<OrdemPreparoRepository>(),
        _estornoUseCase = estornoUseCase ??
            DependencyInjection().get<EstornarLoteEstoqueUseCase>(),
        _context = context ?? DependencyInjection().get<TenantContext>() {
    try {
      final syncService = DependencyInjection().get<SupabaseSyncService>();
      _syncSub = syncService.onDataSynced.listen((_) => carregarOrdens(silent: true));
    } catch (_) {}
  }

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
    OrdemPreparo ordem,
    StatusOrdemPreparo novoStatus,
  ) async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final now = DateTime.now().toUtc();

      final statusStr = switch (novoStatus) {
        StatusOrdemPreparo.pendente        => 'confirmado',
        StatusOrdemPreparo.emPreparo       => 'em_preparo',
        StatusOrdemPreparo.pronto          => 'pronto',
        StatusOrdemPreparo.saiuParaEntrega => 'pronto',
        StatusOrdemPreparo.entregue        => 'entregue',
        StatusOrdemPreparo.cancelado       => 'cancelado',
      };

      // Recupera syncVersion atual para incrementar
      final pedidoRow = await (db.select(db.pedidosTable)..where((t) => t.id.equals(ordem.pedidoId))).getSingleOrNull();
      final pedidoVersion = (pedidoRow?.syncVersion ?? 1) + 1;

      final ordemRow = await (db.select(db.ordensPreparoTable)..where((t) => t.id.equals(ordem.id))).getSingleOrNull();
      final ordemVersion = (ordemRow?.syncVersion ?? 1) + 1;

      await (db.update(db.pedidosTable)
            ..where((t) => t.id.equals(ordem.pedidoId)))
          .write(PedidosTableCompanion(
        status: Value(statusStr),
        syncVersion: Value(pedidoVersion),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));

      await (db.update(db.ordensPreparoTable)
            ..where((t) => t.id.equals(ordem.id)))
          .write(OrdensPreparoTableCompanion(
        syncVersion: Value(ordemVersion),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));

      try {
        final outboxService = DependencyInjection().get<OutboxService>();
        await outboxService.enqueue(
          entity: 'Pedido',
          entityId: ordem.pedidoId,
          action: 'update',
          payload: {
            'id': ordem.pedidoId,
            'tenantId': ordem.tenantId,
            'status': statusStr,
            if (pedidoRow != null) ...{
              'valorSubtotalCentavos': pedidoRow.valorSubtotalCentavos,
              'valorTaxaEntregaCentavos': pedidoRow.valorTaxaEntregaCentavos,
              'valorTaxaServicoCentavos': pedidoRow.valorTaxaServicoCentavos,
              'valorTotalCentavos': pedidoRow.valorTotalCentavos,
            },
            'syncVersion': pedidoVersion,
            'updatedAt': now.toIso8601String(),
          },
          version: pedidoVersion,
        );

        final kdsItensJson = jsonEncode(ordem.itens.map((i) => i.toJson()).toList());
        final ordemStatusStr = switch (novoStatus) {
          StatusOrdemPreparo.pendente        => 'pendente',
          StatusOrdemPreparo.emPreparo       => 'em_preparo',
          StatusOrdemPreparo.pronto          => 'pronto',
          StatusOrdemPreparo.saiuParaEntrega => 'saiu_para_entrega',
          StatusOrdemPreparo.entregue        => 'entregue',
          StatusOrdemPreparo.cancelado       => 'cancelado',
        };
        await outboxService.enqueue(
          entity: 'OrdemPreparo',
          entityId: ordem.id,
          action: 'update',
          payload: {
            'id': ordem.id,
            'tenantId': ordem.tenantId,
            'pedidoId': ordem.pedidoId,
            'itensJson': kdsItensJson,
            'status': ordemStatusStr,
            'prioridade': ordem.prioridade.name,
            'operadorId': ordem.operadorId,
            'criadaEm': ordem.criadaEm.toUtc().toIso8601String(),
            if (ordem.iniciadaEm != null) 'iniciadaEm': ordem.iniciadaEm!.toUtc().toIso8601String(),
            if (ordem.concluidaEm != null) 'concluidaEm': ordem.concluidaEm!.toUtc().toIso8601String(),
            if (ordem.canceladaEm != null) 'canceladaEm': ordem.canceladaEm!.toUtc().toIso8601String(),
            'tempoEstimadoSegundos': ordem.tempoEstimadoSegundos,
            'observacoes': ordem.observacoes,
            'syncVersion': ordemVersion,
            'updatedAt': now.toIso8601String(),
          },
          version: ordemVersion,
        );

        // Dispara push imediato para o Supabase sem aguardar o timer de 30s
        try {
          final syncEngine = DependencyInjection().get<SyncEngine>();
          unawaited(syncEngine.processPendingQueue().catchError((_) => const SyncResult(
                successCount: 0,
                failureCount: 0,
                hasPendingAfter: true,
              )));
        } catch (_) {}
      } catch (e) {
        debugPrint('[KDS] Erro ao registrar status no outbox: $e');
      }

      // Registra linha do tempo no histórico
      try {
        String? operadorNome;
        if (_context.hasContext) {
          operadorNome = _context.usuario.nome;
        }
        final isRev = (novoStatus.index < ordem.status.index) ||
            (ordem.status == StatusOrdemPreparo.cancelado && novoStatus != StatusOrdemPreparo.cancelado);
        final isCancelamento = novoStatus == StatusOrdemPreparo.cancelado;
        final statusLabelsMap = {
          StatusOrdemPreparo.pendente: 'Pendente',
          StatusOrdemPreparo.emPreparo: 'Em Preparo',
          StatusOrdemPreparo.pronto: 'Pronto',
          StatusOrdemPreparo.entregue: 'Entregue',
          StatusOrdemPreparo.cancelado: 'Cancelado',
        };
        final deLabel = statusLabelsMap[ordem.status] ?? ordem.status.name;
        final paraLabel = statusLabelsMap[novoStatus] ?? novoStatus.name;
        final titulo = isCancelamento
            ? 'Pedido Cancelado (KDS)'
            : (isRev ? 'Status Revertido (KDS)' : 'Status Atualizado (KDS)');
        final descricao = 'Passou de "$deLabel" para "$paraLabel"';

        await _ordemRepo.registrarHistorico(
          ordem.id,
          titulo,
          descricao,
          operadorNome: operadorNome,
        );
      } catch (e) {
        debugPrint('[KDS] Erro ao registrar histórico: $e');
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
    await _syncPedidoStatus(updated, StatusOrdemPreparo.emPreparo);

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
    await _syncPedidoStatus(updated, StatusOrdemPreparo.pronto);

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
    await _syncPedidoStatus(updated, StatusOrdemPreparo.entregue);

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
    await _syncPedidoStatus(updated, StatusOrdemPreparo.cancelado);

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

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncSub?.cancel();
    super.dispose();
  }
}
