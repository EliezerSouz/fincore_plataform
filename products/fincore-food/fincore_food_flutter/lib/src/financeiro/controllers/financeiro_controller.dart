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
  final int totalSuprimentosCentavos;
  final int totalSangriasCentavos;
  final int fundoTrocoCentavos;
  final int saldoCentavos;
  final int saldoEsperadoDinheiroCentavos;
  final int totalConsumoInternoCentavos;
  final int qtdConsumoInterno;
  final Map<String, int> vendasPorFormaPagamento; // nomeFP → valorCentavos
  final int qtdPedidos;
  final int qtdVendasAgendadas;
  final int totalVendasAgendadasCentavos;
  final int qtdVendasImediatas;
  final int totalVendasImediatasCentavos;

  const ResumoCaixa({
    this.sessaoAtiva,
    this.totalVendasCentavos = 0,
    this.totalDespesasCentavos = 0,
    this.totalSuprimentosCentavos = 0,
    this.totalSangriasCentavos = 0,
    this.fundoTrocoCentavos = 0,
    this.saldoCentavos = 0,
    this.saldoEsperadoDinheiroCentavos = 0,
    this.totalConsumoInternoCentavos = 0,
    this.qtdConsumoInterno = 0,
    this.vendasPorFormaPagamento = const {},
    this.qtdPedidos = 0,
    this.qtdVendasAgendadas = 0,
    this.totalVendasAgendadasCentavos = 0,
    this.qtdVendasImediatas = 0,
    this.totalVendasImediatasCentavos = 0,
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
  List<SessaoCaixaData> _historicoSessoes = [];
  bool _loading = false;
  String? _error;

  FinanceiroController()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>(),
        _outbox = DependencyInjection().get<OutboxService>() {
    _carregarResumo();
  }

  ResumoCaixa get resumo => _resumo;
  List<SessaoCaixaData> get historicoSessoes => _historicoSessoes;
  bool get loading => _loading;
  String? get error => _error;

  // ─────────────────────────────────────────────────────────────────
  // Carregamento do Resumo e Histórico de Caixas
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

      // 2. Histórico de sessões passadas (ordenadas pela data de abertura decrescente)
      _historicoSessoes = await (
        _db.select(_db.sessoesCaixaTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataAbertura, mode: OrderingMode.desc)])
          ..limit(50)
      ).get();

      // 3. Todos os pedidos confirmados do dia
      final todosPedidosDia = await (
        _db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.equals('confirmado') &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicioDia) &
              t.dataHoraCriacao.isSmallerThanValue(fimDia) &
              t.deletedAt.isNull())
      ).get();

      // 4. Lançamentos da sessão ativa (se existir)
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

      // 5. Consolida as vendas por forma de pagamento e distingue vendas agendadas vs imediatas
      final Map<String, int> vendasPorFP = {};
      int totalVendas = 0;
      int totalDespesas = 0;
      int totalSuprimentos = 0;
      int totalSangrias = 0;
      int totalConsumoInterno = 0;
      int qtdConsumo = 0;
      int qtdVendasReais = 0;
      int qtdAgendadas = 0;
      int totalAgendadas = 0;
      int qtdImediatas = 0;
      int totalImediatas = 0;
      int vendasDinheiroEspecie = 0;

      for (final p in todosPedidosDia) {
        final fpNome = p.formaPagamentoNome ?? 'Não informado';
        final isConsumo = p.isUsoInterno ||
            fpNome.toLowerCase().contains('consumo') ||
            fpNome.toLowerCase().contains('cortesia') ||
            fpNome.toLowerCase().contains('bonifica');

        if (isConsumo) {
          totalConsumoInterno += p.valorTotalCentavos;
          qtdConsumo++;
          continue;
        }

        vendasPorFP[fpNome] = (vendasPorFP[fpNome] ?? 0) + p.valorTotalCentavos;
        totalVendas += p.valorTotalCentavos;
        qtdVendasReais++;

        if (fpNome.toLowerCase().contains('dinheiro') || fpNome.toLowerCase().contains('especie')) {
          vendasDinheiroEspecie += p.valorTotalCentavos;
        }

        final isAgendado = p.dataHoraEntregaPrevista != null &&
            p.dataHoraEntregaPrevista!.toUtc().isAfter(fimDia);

        if (isAgendado) {
          qtdAgendadas++;
          totalAgendadas += p.valorTotalCentavos;
        } else {
          qtdImediatas++;
          totalImediatas += p.valorTotalCentavos;
        }
      }

      // 6. Processa sangrias, suprimentos e despesas da sessão
      for (final l in lancamentos) {
        if (l.tipo == 'despesa') {
          totalDespesas += l.valorCentavos;
        } else if (l.tipo == 'sangria') {
          totalSangrias += l.valorCentavos;
        } else if (l.tipo == 'suprimento') {
          totalSuprimentos += l.valorCentavos;
        }
      }

      final fundoTroco = sessaoAtiva?.valorAberturaCentavos ?? 0;
      final saldoGeral = totalVendas - totalDespesas - totalSangrias + totalSuprimentos + fundoTroco;
      final saldoDinheiro = fundoTroco + vendasDinheiroEspecie + totalSuprimentos - totalSangrias - totalDespesas;

      _resumo = ResumoCaixa(
        sessaoAtiva: sessaoAtiva,
        totalVendasCentavos: totalVendas,
        totalDespesasCentavos: totalDespesas,
        totalSuprimentosCentavos: totalSuprimentos,
        totalSangriasCentavos: totalSangrias,
        fundoTrocoCentavos: fundoTroco,
        saldoCentavos: saldoGeral,
        saldoEsperadoDinheiroCentavos: saldoDinheiro < 0 ? 0 : saldoDinheiro,
        totalConsumoInternoCentavos: totalConsumoInterno,
        qtdConsumoInterno: qtdConsumo,
        vendasPorFormaPagamento: vendasPorFP,
        qtdPedidos: qtdVendasReais,
        qtdVendasAgendadas: qtdAgendadas,
        totalVendasAgendadasCentavos: totalAgendadas,
        qtdVendasImediatas: qtdImediatas,
        totalVendasImediatasCentavos: totalImediatas,
      );
    } catch (e) {
      _error = 'Erro ao carregar resumo financeiro: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _carregarResumo();

  /// Carrega os lançamentos de uma sessão específica do histórico
  Future<List<LancamentoFinanceiroData>> carregarLancamentosSessao(String sessaoId) async {
    if (!_context.hasContext) return [];
    final tenantId = _context.tenantId;
    return await (
      _db.select(_db.lancamentosFinanceirosTable)
        ..where((t) =>
            t.tenantId.equals(tenantId) &
            t.sessaoCaixaId.equals(sessaoId) &
            t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.dataHora, mode: OrderingMode.desc)])
    ).get();
  }

  /// Carrega os pedidos confirmados pertencentes a uma sessão (ou à sessão ativa)
  Future<List<PedidoData>> carregarPedidosSessao([String? sessaoId]) async {
    if (!_context.hasContext) return [];
    final tenantId = _context.tenantId;

    final targetSessao = sessaoId != null
        ? await (_db.select(_db.sessoesCaixaTable)..where((s) => s.id.equals(sessaoId))).getSingleOrNull()
        : _resumo.sessaoAtiva;

    if (targetSessao == null) return [];

    final inicio = targetSessao.dataAbertura;
    final fim = targetSessao.dataFechamento ?? DateTime.now().toUtc();

    return await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.equals('confirmado') &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
              t.dataHoraCriacao.isSmallerThanValue(fim.add(const Duration(minutes: 5))) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.desc)]))
        .get();
  }

  // ─────────────────────────────────────────────────────────────────
  // Abrir / Fechar Caixa
  // ─────────────────────────────────────────────────────────────────

  Future<void> abrirCaixa({
    int valorAberturaCentavos = 0,
    String nomeTurno = 'Turno Padrão',
  }) async {
    if (!_context.hasContext) return;
    if (_resumo.caixaAberto) return;

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final operadorNome = _context.usuario.nome;
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();

    final obsTurno = 'Turno: $nomeTurno';

    await _db.into(_db.sessoesCaixaTable).insert(
      SessoesCaixaTableCompanion.insert(
        id: id,
        tenantId: tenantId,
        operadorId: operadorId,
        operadorNome: Value(operadorNome),
        status: const Value('aberta'),
        dataAbertura: now,
        valorAberturaCentavos: Value(valorAberturaCentavos),
        observacoes: Value(obsTurno),
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
        observacoes: obsTurno,
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
