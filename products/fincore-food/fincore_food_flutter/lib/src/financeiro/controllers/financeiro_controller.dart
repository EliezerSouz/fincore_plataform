import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:uuid/uuid.dart';

/// Resumo consolidado de uma sessão de caixa para exibição no dashboard.
class ResumoCaixa {
  final SessaoCaixaData? sessaoAtiva;
  final int totalVendasCentavos;
  final int totalDespesasCentavos;
  final int saldoCentavos;
  final Map<String, int> vendasPorFormaPagamento; // nomeFP → valorCentavos
  final int qtdPedidos;

  const ResumoCaixa({
    this.sessaoAtiva,
    this.totalVendasCentavos = 0,
    this.totalDespesasCentavos = 0,
    this.saldoCentavos = 0,
    this.vendasPorFormaPagamento = const {},
    this.qtdPedidos = 0,
  });

  bool get caixaAberto => sessaoAtiva?.status == 'aberta';
}

/// Controller do Módulo Financeiro
///
/// Gerencia sessões de caixa e lançamentos financeiros.
/// Lê os pedidos do dia direto da `pedidosTable` para montar o dashboard.
class FinanceiroController extends ChangeNotifier {
  final FincoreDatabase _db;
  final TenantContext _context;
  final OutboxService _outbox;

  ResumoCaixa _resumo = const ResumoCaixa();
  bool _loading = false;
  String? _error;

  FinanceiroController()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>(),
        _outbox = DependencyInjection().get<OutboxService>() {
    _carregarResumo();
  }

  ResumoCaixa get resumo => _resumo;
  bool get loading => _loading;
  String? get error => _error;

  // ─────────────────────────────────────────────────────────────────
  // Carregamento do Resumo do Caixa
  // ─────────────────────────────────────────────────────────────────

  Future<void> _carregarResumo() async {
    if (!_context.hasContext) return;
    _loading = true;
    notifyListeners();

    try {
      final tenantId = _context.tenantId;
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day).toUtc();
      final fimDia = inicioDia.add(const Duration(days: 1));

      // 1. Busca sessão ativa
      final sessaoAtiva = await (
        _db.select(_db.sessoesCaixaTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.equals('aberta') &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataAbertura, mode: OrderingMode.desc)])
          ..limit(1)
      ).getSingleOrNull();

      // 2. Pedidos do dia confirmados (para montar o resumo mesmo sem sessão de caixa)
      final pedidosDia = await (
        _db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.equals('confirmado') &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicioDia) &
              t.dataHoraCriacao.isSmallerThanValue(fimDia) &
              t.deletedAt.isNull())
      ).get();

      // 3. Lançamentos da sessão ativa (se existir)
      List<LancamentoFinanceiroData> lancamentos = [];
      if (sessaoAtiva != null) {
        lancamentos = await (
          _db.select(_db.lancamentosFinanceirosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.sessaoCaixaId.equals(sessaoAtiva.id) &
                t.deletedAt.isNull())
        ).get();
      }

      // 4. Consolida as vendas por forma de pagamento
      final Map<String, int> vendasPorFP = {};
      int totalVendas = 0;
      int totalDespesas = 0;

      // Agrupa pedidos por forma de pagamento
      for (final p in pedidosDia) {
        final fpNome = p.formaPagamentoNome ?? 'Não informado';
        vendasPorFP[fpNome] = (vendasPorFP[fpNome] ?? 0) + p.valorTotalCentavos;
        totalVendas += p.valorTotalCentavos;
      }

      // Despesas e sangrias da sessão
      for (final l in lancamentos) {
        if (l.tipo == 'despesa' || l.tipo == 'sangria') {
          totalDespesas += l.valorCentavos;
        }
      }

      final saldo = totalVendas - totalDespesas +
          (sessaoAtiva?.valorAberturaCentavos ?? 0);

      _resumo = ResumoCaixa(
        sessaoAtiva: sessaoAtiva,
        totalVendasCentavos: totalVendas,
        totalDespesasCentavos: totalDespesas,
        saldoCentavos: saldo,
        vendasPorFormaPagamento: vendasPorFP,
        qtdPedidos: pedidosDia.length,
      );
    } catch (e) {
      _error = 'Erro ao carregar resumo financeiro: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _carregarResumo();

  // ─────────────────────────────────────────────────────────────────
  // Abrir / Fechar Caixa
  // ─────────────────────────────────────────────────────────────────

  Future<void> abrirCaixa({int valorAberturaCentavos = 0}) async {
    if (!_context.hasContext) return;
    if (_resumo.caixaAberto) return;

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final operadorNome = _context.usuario.nome;
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();

    await _db.into(_db.sessoesCaixaTable).insert(
      SessoesCaixaTableCompanion.insert(
        id: id,
        tenantId: tenantId,
        operadorId: operadorId,
        operadorNome: Value(operadorNome),
        status: const Value('aberta'),
        dataAbertura: now,
        valorAberturaCentavos: Value(valorAberturaCentavos),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );
    await _outbox.enqueue(
      entity: 'sessao_caixa',
      entityId: id,
      action: 'CREATE',
      version: 1,
      payload: _sessaoPayload(
        id: id,
        tenantId: tenantId,
        operadorId: operadorId,
        operadorNome: operadorNome,
        status: 'aberta',
        dataAbertura: now,
        valorAberturaCentavos: valorAberturaCentavos,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _carregarResumo();
  }

  Future<void> fecharCaixa({int? valorContadoCentavos, String? observacoes}) async {
    final sessao = _resumo.sessaoAtiva;
    if (sessao == null) return;

    final now = DateTime.now().toUtc();
    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;

    final diferenca = valorContadoCentavos != null
        ? valorContadoCentavos - _resumo.saldoCentavos
        : null;

    await (_db.update(_db.sessoesCaixaTable)
          ..where((t) => t.id.equals(sessao.id)))
        .write(SessoesCaixaTableCompanion(
      status: const Value('fechada'),
      dataFechamento: Value(now),
      valorFechamentoCentavos: Value(valorContadoCentavos),
      totalVendasCentavos: Value(_resumo.totalVendasCentavos),
      totalDespesasCentavos: Value(_resumo.totalDespesasCentavos),
      diferencaCentavos: Value(diferenca),
      observacoes: Value(observacoes),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));
    await _outbox.enqueue(
      entity: 'sessao_caixa',
      entityId: sessao.id,
      action: 'UPDATE',
      version: sessao.syncVersion + 1,
      payload: _sessaoPayload(
        id: sessao.id,
        tenantId: tenantId,
        operadorId: sessao.operadorId,
        operadorNome: sessao.operadorNome,
        status: 'fechada',
        dataAbertura: sessao.dataAbertura,
        dataFechamento: now,
        valorAberturaCentavos: sessao.valorAberturaCentavos,
        valorFechamentoCentavos: valorContadoCentavos,
        totalVendasCentavos: _resumo.totalVendasCentavos,
        totalDespesasCentavos: _resumo.totalDespesasCentavos,
        diferencaCentavos: diferenca,
        observacoes: observacoes,
        createdAt: sessao.createdAt,
        updatedAt: now,
      ),
    );

    await _carregarResumo();
  }

  /// Lançamento avulso (sangria, suprimento, despesa)
  Future<void> lancarMovimento({
    required String tipo,
    required int valorCentavos,
    required String descricao,
  }) async {
    final sessao = _resumo.sessaoAtiva;
    if (sessao == null) return;

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();

    final id = const Uuid().v4();
    await _db.into(_db.lancamentosFinanceirosTable).insert(
      LancamentosFinanceirosTableCompanion.insert(
        id: id,
        tenantId: tenantId,
        sessaoCaixaId: sessao.id,
        tipo: tipo,
        valorCentavos: valorCentavos,
        descricao: Value(descricao),
        operadorId: Value(operadorId),
        dataHora: now,
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );
    await _outbox.enqueue(
      entity: 'lancamento_financeiro',
      entityId: id,
      action: 'CREATE',
      version: 1,
      payload: {
        'id': id,
        'tenantId': tenantId,
        'sessaoCaixaId': sessao.id,
        'tipo': tipo,
        'valorCentavos': valorCentavos,
        'descricao': descricao,
        'operadorId': operadorId,
        'dataHora': now.toIso8601String(),
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': operadorId,
        'updatedBy': operadorId,
      },
    );

    await _carregarResumo();
  }

  Map<String, dynamic> _sessaoPayload({
    required String id,
    required String tenantId,
    required String operadorId,
    required String operadorNome,
    required String status,
    required DateTime dataAbertura,
    required int valorAberturaCentavos,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? dataFechamento,
    int? valorFechamentoCentavos,
    int totalVendasCentavos = 0,
    int totalDespesasCentavos = 0,
    int? diferencaCentavos,
    String? observacoes,
  }) => {
        'id': id,
        'tenantId': tenantId,
        'operadorId': operadorId,
        'operadorNome': operadorNome,
        'status': status,
        'dataAbertura': dataAbertura.toIso8601String(),
        'dataFechamento': dataFechamento?.toIso8601String(),
        'valorAberturaCentavos': valorAberturaCentavos,
        'valorFechamentoCentavos': valorFechamentoCentavos,
        'totalVendasCentavos': totalVendasCentavos,
        'totalDespesasCentavos': totalDespesasCentavos,
        'diferencaCentavos': diferencaCentavos,
        'observacoes': observacoes,
        'syncVersion': 1,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': operadorId,
        'updatedBy': operadorId,
      };
}
