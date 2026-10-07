import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:uuid/uuid.dart';

/// Resumo de produto vendido para fechamento e auditoria de turno
class ProdutoVendidoResumo {
  final String produtoId;
  final String nome;
  final double quantidade;
  final int totalCentavos;
  final double percentualFaturamento;

  const ProdutoVendidoResumo({
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    required this.totalCentavos,
    required this.percentualFaturamento,
  });
}

/// Consolidado de uma forma de pagamento no turno
class FormaPagamentoResumo {
  final String nome;
  final int qtdTransacoes;
  final int totalCentavos;
  final double percentual;

  const FormaPagamentoResumo({
    required this.nome,
    required this.qtdTransacoes,
    required this.totalCentavos,
    required this.percentual,
  });
}

/// Resumo consolidado de uma sessão de caixa para exibição no dashboard e fechamento.
///
/// SEPARAÇÃO FUNDAMENTAL:
/// - [totalVendasCentavos]: soma dos pedidos confirmados NO PERÍODO da sessão (excl. consumo interno)
/// - [totalRecebimentosVendasCentavos]: lançamentos 'receita' VINCULADOS ao id da sessão
///   provenientes de vendas em dinheiro físico (descrição não contém 'baixa')
/// - [totalRecebimentosBaixasCentavos]: lançamentos 'receita' que são BAIXAS de contas anteriores
///   (descrição contém 'baixa', 'liquidação', 'quitação', 'recebimento conta a receber')
/// - [saldoEsperadoDinheiroCentavos]: cálculo real da gaveta física
class ResumoCaixa {
  final SessaoCaixaData? sessaoAtiva;

  /// VENDAS: soma dos pedidos confirmados no período da sessão (excl. uso interno e cancelados)
  final int totalVendasCentavos;

  /// DESPESAS internas (lançamentos tipo 'despesa')
  final int totalDespesasCentavos;

  /// SUPRIMENTOS: reforços de caixa (lançamentos tipo 'suprimento')
  final int totalSuprimentosCentavos;

  /// SANGRIAS: retiradas (lançamentos tipo 'sangria')
  final int totalSangriasCentavos;

  /// FUNDO INICIAL da sessão (valorAberturaCentavos)
  final int fundoTrocoCentavos;

  /// VENDAS EM DINHEIRO FÍSICO faturadas no turno
  final int totalVendasDinheiroCentavos;

  /// RECEBIMENTOS EM DINHEIRO FÍSICO provenientes de vendas pagas em dinheiro no turno
  final int totalRecebimentosVendasDinheiroCentavos;

  /// RECEBIMENTOS de BAIXAS de contas a receber feitas neste turno
  /// Inclui PIX, cartão e nota a prazo liquidados
  final int totalRecebimentosBaixasCentavos;

  /// BAIXAS RECEBIDAS ESPECIFICAMENTE EM DINHEIRO FÍSICO NA GAVETA
  final int totalRecebimentosBaixasDinheiroCentavos;

  /// TOTAL RECEBIDO NO TURNO (dinheiro + baixas)
  int get totalRecebimentosTurno =>
      totalVendasDinheiroCentavos + totalRecebimentosBaixasCentavos;

  /// DINHEIRO ESPERADO NA GAVETA ao fechar
  /// Fórmula: fundoInicial + vendasEmDinheiro + baixasEmDinheiro + suprimentos - sangrias - despesasPagas
  final int saldoEsperadoDinheiroCentavos;

  /// Saldo geral do caixa (todos os recebimentos - saidas)
  final int saldoCentavos;

  /// Consumo interno (para relatório, não impacta caixa)
  final int totalConsumoInternoCentavos;
  final int qtdConsumoInterno;

  /// VENDAS POR FORMA DE PAGAMENTO — baseado nos pedidos do período da sessão
  final Map<String, int> vendasPorFormaPagamento;

  /// RECEBIMENTOS POR FORMA (baixas) — baseado nos lançamentos de baixa da sessão
  final Map<String, int> recebimentosPorFormaPagamento;

  /// Quantidade de pedidos de venda no turno (excl. consumo interno)
  final int qtdPedidos;

  /// Pedidos agendados (encomendas com entrega futura)
  final int qtdVendasAgendadas;
  final int totalVendasAgendadasCentavos;

  /// Pedidos imediatos
  final int qtdVendasImediatas;
  final int totalVendasImediatasCentavos;

  /// Cancelamentos no período da sessão
  final int qtdCancelamentos;
  final int totalCancelamentosCentavos;

  /// Número sequencial do turno no dia (1, 2, 3...)
  final int numeroTurno;

  const ResumoCaixa({
    this.sessaoAtiva,
    this.totalVendasCentavos = 0,
    this.totalVendasDinheiroCentavos = 0,
    this.totalDespesasCentavos = 0,
    this.totalSuprimentosCentavos = 0,
    this.totalSangriasCentavos = 0,
    this.fundoTrocoCentavos = 0,
    this.saldoCentavos = 0,
    this.saldoEsperadoDinheiroCentavos = 0,
    this.totalRecebimentosVendasDinheiroCentavos = 0,
    this.totalRecebimentosBaixasCentavos = 0,
    this.totalRecebimentosBaixasDinheiroCentavos = 0,
    this.totalConsumoInternoCentavos = 0,
    this.qtdConsumoInterno = 0,
    this.vendasPorFormaPagamento = const {},
    this.recebimentosPorFormaPagamento = const {},
    this.qtdPedidos = 0,
    this.qtdVendasAgendadas = 0,
    this.totalVendasAgendadasCentavos = 0,
    this.qtdVendasImediatas = 0,
    this.totalVendasImediatasCentavos = 0,
    this.qtdCancelamentos = 0,
    this.totalCancelamentosCentavos = 0,
    this.numeroTurno = 1,
  });

  bool get caixaAberto => sessaoAtiva?.status == 'aberta';

  /// Nome do turno formatado: "TURNO 01 — DD/MM/YYYY"
  String get nomeTurnoFormatado {
    if (sessaoAtiva == null) return 'SEM TURNO ABERTO';
    final data = sessaoAtiva!.dataAbertura.toLocal();
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    return 'TURNO ${numeroTurno.toString().padLeft(2, '0')} — $dia/$mes/$ano';
  }
}

/// Tipos de evento na timeline financeira do turno
enum EventoTipo {
  abertura,
  fechamento,
  venda,
  cancelamento,
  consumoInterno,
  sangria,
  suprimento,
  despesa,
  baixa,
  recebimento,
}

/// Evento individual na timeline financeira cronológica do turno
class EventoTimeline {
  final DateTime dataHora;
  final EventoTipo tipo;
  final String descricao;
  final int valorCentavos;
  final String? pedidoId;
  final int? numeroPedido;
  final String? clienteNome;
  final String? formaPagamento;
  final String? tipoLogistica;
  final String? lancamentoId;
  final String? operadorNome;

  const EventoTimeline({
    required this.dataHora,
    required this.tipo,
    required this.descricao,
    required this.valorCentavos,
    this.pedidoId,
    this.numeroPedido,
    this.clienteNome,
    this.formaPagamento,
    this.tipoLogistica,
    this.lancamentoId,
    this.operadorNome,
  });

  /// Indica se este evento é uma entrada de valor (positivo para o caixa)
  bool get isCredito => tipo == EventoTipo.venda ||
      tipo == EventoTipo.suprimento ||
      tipo == EventoTipo.baixa ||
      tipo == EventoTipo.recebimento;

  /// Indica se este evento é uma saída de valor (negativo para o caixa)
  bool get isDebito => tipo == EventoTipo.sangria ||
      tipo == EventoTipo.despesa ||
      tipo == EventoTipo.cancelamento;

  /// Indica se impacta fisicamente a gaveta de dinheiro
  bool get impactaGaveta {
    if (!isCredito && !isDebito) return false;
    final fp = formaPagamento?.toLowerCase() ?? '';
    return fp.isEmpty || fp.contains('dinheiro') || fp.contains('especie') ||
        tipo == EventoTipo.sangria || tipo == EventoTipo.suprimento || tipo == EventoTipo.despesa;
  }
}

/// Controller do Módulo Financeiro
///
/// PRINCÍPIO CENTRAL: o caixa é uma CENTRAL DE CONSOLIDAÇÃO.
/// Todos os dados vêm das tabelas existentes — nenhum dado fictício.
///
/// REGRAS DE CÁLCULO:
/// - Vendas do turno: pedidos confirmados no PERÍODO da sessão
/// - Recebimentos: lançamentos financeiros vinculados à sessão
/// - Dinheiro esperado: fundo + dinheiro_recebido + suprimentos - sangrias - despesas
/// - Recebimentos de contas antigas: lançamentos com 'Baixa' na descrição
class FinanceiroController extends ChangeNotifier {
  final FincoreDatabase _db;
  final TenantContext _context;

  /// Formata observações ou identificador de turno para exibição legível
  static String formatarNomeTurno(String? observacoes, [DateTime? data]) {
    if (observacoes == null || observacoes.trim().isEmpty) {
      if (data != null) {
        final d = data.toLocal();
        return 'Turno 01 (${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')})';
      }
      return 'Turno 01';
    }
    if (observacoes.startsWith('TURNO:')) {
      final partes = observacoes.split(':');
      if (partes.length >= 2) {
        final num = int.tryParse(partes[1]) ?? 1;
        final dataStr = partes.length >= 3 ? partes[2] : '';
        return 'Turno ${num.toString().padLeft(2, '0')}${dataStr.isNotEmpty ? " · $dataStr" : ""}';
      }
    }
    return observacoes;
  }
  final OutboxService _outbox;

  ResumoCaixa _resumo = const ResumoCaixa();
  List<SessaoCaixaData> _historicoSessoes = [];
  SessaoCaixaData? _turnoDiaAnteriorAberto;
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
  SessaoCaixaData? get turnoDiaAnteriorAberto => _turnoDiaAnteriorAberto;
  bool get loading => _loading;
  String? get error => _error;

  // ─────────────────────────────────────────────────────────────────
  // Utilitários de Numeração de Turno
  // ─────────────────────────────────────────────────────────────────

  /// Extrai o número do turno do campo observacoes.
  /// Formato armazenado: "TURNO:N:..." onde N é o número inteiro.
  static int _extrairNumeroTurno(String? observacoes) {
    if (observacoes == null || observacoes.isEmpty) return 1;
    final match = RegExp(r'TURNO:(\d+)').firstMatch(observacoes);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  /// Calcula o próximo número de turno para o dia atual.
  /// Conta quantas sessões foram abertas hoje e adiciona 1.
  Future<int> _calcularProximoNumeroTurno(String tenantId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day).toUtc();
    final fimDia = inicioDia.add(const Duration(days: 1));

    final sessoesDia = await (_db.select(_db.sessoesCaixaTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.dataAbertura.isBiggerOrEqualValue(inicioDia) &
              t.dataAbertura.isSmallerThanValue(fimDia) &
              t.deletedAt.isNull()))
        .get();

    return sessoesDia.length + 1;
  }

  /// Detecta se há um turno aberto de um dia anterior (data de abertura != hoje).
  Future<SessaoCaixaData?> _detectarTurnoDiaAnteriorAberto(String tenantId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day).toUtc();

    // Busca sessão aberta cuja data de abertura é ANTES de hoje
    final sessao = await (_db.select(_db.sessoesCaixaTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.equals('aberta') &
              t.dataAbertura.isSmallerThanValue(inicioDia) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataAbertura, mode: OrderingMode.asc)])
          ..limit(1))
        .getSingleOrNull();

    return sessao;
  }

  // ─────────────────────────────────────────────────────────────────
  // Carregamento do Resumo e Histórico de Caixas
  // ─────────────────────────────────────────────────────────────────

  Future<void> _carregarResumo() async {
    if (!_context.hasContext) return;
    _loading = true;
    notifyListeners();

    try {
      final tenantId = _context.tenantId;

      // 1. Detectar turno aberto de dia anterior (alerta de segurança)
      _turnoDiaAnteriorAberto = await _detectarTurnoDiaAnteriorAberto(tenantId);

      // 2. Buscar sessão ativa do DIA ATUAL
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day).toUtc();

      SessaoCaixaData? sessaoAtiva = await (_db.select(_db.sessoesCaixaTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.status.equals('aberta') &
                t.dataAbertura.isBiggerOrEqualValue(inicioDia) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.dataAbertura, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();

      // Se não encontrou sessão do dia atual, verifica se há turno anterior aberto
      if (sessaoAtiva == null && _turnoDiaAnteriorAberto != null) {
        sessaoAtiva = _turnoDiaAnteriorAberto;
      }

      // 3. Histórico de sessões (últimas 100, ordenadas por abertura desc)
      _historicoSessoes = await (_db.select(_db.sessoesCaixaTable)
            ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.dataAbertura, mode: OrderingMode.desc)])
            ..limit(100))
          .get();

      if (sessaoAtiva == null) {
        _resumo = const ResumoCaixa();
        return;
      }

      // 4. Período da sessão
      final inicio = sessaoAtiva.dataAbertura;
      final fim = sessaoAtiva.dataFechamento ?? DateTime.now().toUtc();

      // 5. Pedidos NO PERÍODO DA SESSÃO (confirmados, não cancelados)
      final pedidosDaSessao = await (_db.select(_db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.status.isNotIn(['cancelado', 'rascunho']) &
                t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
                t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
                t.deletedAt.isNull()))
          .get();

      // 6. Cancelamentos no período
      final cancelamentosDaSessao = await (_db.select(_db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.status.equals('cancelado') &
                t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
                t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
                t.deletedAt.isNull()))
          .get();

      // 7. Lançamentos DA SESSÃO (por FK sessaoCaixaId)
      final lancamentosDaSessao = await (_db.select(_db.lancamentosFinanceirosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.sessaoCaixaId.equals(sessaoAtiva!.id) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.dataHora, mode: OrderingMode.asc)]))
          .get();

      // 8. Calcular vendas por forma de pagamento (dos pedidos)
      final Map<String, int> vendasPorFP = {};
      int totalVendas = 0;
      int totalConsumoInterno = 0;
      int qtdConsumo = 0;
      int qtdVendas = 0;
      int qtdAgendadas = 0;
      int totalAgendadas = 0;
      int qtdImediatas = 0;
      int totalImediatas = 0;

      // Data de corte para "agendado" = amanhã ou além do período do turno
      final dataCorteAgendado = sessaoAtiva.dataFechamento ?? fim;

      for (final p in pedidosDaSessao) {
        final fpNome = p.formaPagamentoNome ?? 'Não informado';
        final isConsumo = p.isUsoInterno ||
            fpNome.toLowerCase().contains('consumo') ||
            fpNome.toLowerCase().contains('cortesia') ||
            fpNome.toLowerCase().contains('bonifica') ||
            fpNome.toLowerCase().contains('interno');

        if (isConsumo) {
          totalConsumoInterno += p.valorTotalCentavos;
          qtdConsumo++;
          continue;
        }

        vendasPorFP[fpNome] = (vendasPorFP[fpNome] ?? 0) + p.valorTotalCentavos;
        totalVendas += p.valorTotalCentavos;
        qtdVendas++;

        final isAgendado = p.dataHoraEntregaPrevista != null &&
            p.dataHoraEntregaPrevista!.toUtc().isAfter(dataCorteAgendado);

        if (isAgendado) {
          qtdAgendadas++;
          totalAgendadas += p.valorTotalCentavos;
        } else {
          qtdImediatas++;
          totalImediatas += p.valorTotalCentavos;
        }
      }

      // 9. Calcular movimentações de caixa dos lançamentos
      int totalDespesas = 0;
      int totalSuprimentos = 0;
      int totalSangrias = 0;
      int totalRecBaixas = 0;
      int totalRecBaixasDinheiro = 0;

      // Vendas em dinheiro originadas dos pedidos do turno
      int totalVendasDinheiro = 0;
      for (final entry in vendasPorFP.entries) {
        final fpLower = entry.key.toLowerCase();
        if (fpLower.contains('dinheiro') || fpLower.contains('especie')) {
          totalVendasDinheiro += entry.value;
        }
      }

      final Map<String, int> recPorFP = {};

      for (final l in lancamentosDaSessao) {
        if (l.tipo == 'despesa') {
          totalDespesas += l.valorCentavos;
        } else if (l.tipo == 'sangria') {
          totalSangrias += l.valorCentavos;
        } else if (l.tipo == 'suprimento') {
          totalSuprimentos += l.valorCentavos;
        } else if (l.tipo == 'receita') {
          final descLower = l.descricao.toLowerCase();
          final isBaixa = descLower.contains('baixa') ||
              descLower.contains('liquid') ||
              descLower.contains('validad') ||
              descLower.contains('quitação') ||
              descLower.contains('quitacao') ||
              descLower.contains('recebimento conta');

          final fpNomeLanc = l.formaPagamentoNome ?? 'Dinheiro';
          final fpLower = fpNomeLanc.toLowerCase();
          final isDinheiro = fpLower.contains('dinheiro') || fpLower.contains('especie');

          if (isBaixa) {
            totalRecBaixas += l.valorCentavos;
            if (isDinheiro) {
              totalRecBaixasDinheiro += l.valorCentavos;
            }
          }

          recPorFP[fpNomeLanc] = (recPorFP[fpNomeLanc] ?? 0) + l.valorCentavos;
        }
      }

      // 10. Calcular dinheiro esperado na gaveta
      // FÓRMULA RIGOROSA DA GAVETA FÍSICA:
      // Fundo Inicial + Vendas em Dinheiro Realizadas + Baixas Recebidas em Dinheiro + Suprimentos - Sangrias - Despesas Balcão
      final fundoTroco = sessaoAtiva.valorAberturaCentavos;
      final saldoDinheiro = fundoTroco + totalVendasDinheiro + totalRecBaixasDinheiro + totalSuprimentos - totalSangrias - totalDespesas;

      // Saldo geral (todas as modalidades recebidas - saídas)
      final saldoGeral = fundoTroco + totalVendas + totalRecBaixas + totalSuprimentos - totalSangrias - totalDespesas;

      // 11. Calcular número do turno
      final numTurno = _extrairNumeroTurno(sessaoAtiva.observacoes);

      // 12. Consolidar cancelamentos
      final totalCancelamentos = cancelamentosDaSessao.fold<int>(0, (s, p) => s + p.valorTotalCentavos);

      _resumo = ResumoCaixa(
        sessaoAtiva: sessaoAtiva,
        totalVendasCentavos: totalVendas,
        totalVendasDinheiroCentavos: totalVendasDinheiro,
        totalDespesasCentavos: totalDespesas,
        totalSuprimentosCentavos: totalSuprimentos,
        totalSangriasCentavos: totalSangrias,
        fundoTrocoCentavos: fundoTroco,
        saldoCentavos: saldoGeral < 0 ? 0 : saldoGeral,
        saldoEsperadoDinheiroCentavos: saldoDinheiro < 0 ? 0 : saldoDinheiro,
        totalRecebimentosVendasDinheiroCentavos: totalVendasDinheiro,
        totalRecebimentosBaixasCentavos: totalRecBaixas,
        totalRecebimentosBaixasDinheiroCentavos: totalRecBaixasDinheiro,
        totalConsumoInternoCentavos: totalConsumoInterno,
        qtdConsumoInterno: qtdConsumo,
        vendasPorFormaPagamento: vendasPorFP,
        recebimentosPorFormaPagamento: recPorFP,
        qtdPedidos: qtdVendas,
        qtdVendasAgendadas: qtdAgendadas,
        totalVendasAgendadasCentavos: totalAgendadas,
        qtdVendasImediatas: qtdImediatas,
        totalVendasImediatasCentavos: totalImediatas,
        qtdCancelamentos: cancelamentosDaSessao.length,
        totalCancelamentosCentavos: totalCancelamentos,
        numeroTurno: numTurno,
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
    return await (_db.select(_db.lancamentosFinanceirosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.sessaoCaixaId.equals(sessaoId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHora, mode: OrderingMode.asc)]))
        .get();
  }

  /// Carrega os pedidos confirmados pertencentes a uma sessão (por período de tempo)
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
              t.status.isNotIn(['cancelado', 'rascunho']) &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
              t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.desc)]))
        .get();
  }

  /// Carrega os pedidos cancelados de uma sessão
  Future<List<PedidoData>> carregarCancelamentosSessao([String? sessaoId]) async {
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
              t.status.equals('cancelado') &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
              t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.desc)]))
        .get();
  }

  /// Carrega os itens específicos de um pedido para detalhamento e auditoria
  Future<List<ItemPedidoData>> carregarItensPedido(String pedidoId) async {
    if (!_context.hasContext) return [];
    return await (_db.select(_db.itensPedidoTable)
          ..where((t) => t.pedidoId.equals(pedidoId) & t.deletedAt.isNull()))
        .get();
  }

  /// Consolida e sumariza todos os produtos vendidos nesta sessão
  Future<List<ProdutoVendidoResumo>> carregarProdutosVendidosSessao([String? sessaoId]) async {
    final pedidos = await carregarPedidosSessao(sessaoId);
    if (pedidos.isEmpty) return [];

    final pedidoIds = pedidos.map((p) => p.id).toList();
    final itens = await (_db.select(_db.itensPedidoTable)
          ..where((t) => t.pedidoId.isIn(pedidoIds) & t.deletedAt.isNull()))
        .get();

    if (itens.isEmpty) return [];

    final Map<String, (String id, String nome, double qtd, int total)> agrupado = {};
    int totalGeralCentavos = 0;

    for (final item in itens) {
      final key = item.nomeProduto;
      final current = agrupado[key];
      final novaQtd = (current?.$3 ?? 0.0) + item.quantidade;
      final novoTotal = (current?.$4 ?? 0) + item.valorTotalCentavos;
      agrupado[key] = (item.produtoId, item.nomeProduto, novaQtd, novoTotal);
      totalGeralCentavos += item.valorTotalCentavos;
    }

    final lista = agrupado.values.map((val) {
      final perc = totalGeralCentavos > 0 ? (val.$4 / totalGeralCentavos) * 100 : 0.0;
      return ProdutoVendidoResumo(
        produtoId: val.$1,
        nome: val.$2,
        quantidade: val.$3,
        totalCentavos: val.$4,
        percentualFaturamento: perc,
      );
    }).toList();

    lista.sort((a, b) => b.totalCentavos.compareTo(a.totalCentavos));
    return lista;
  }

  /// Carrega as encomendas futuras / agendadas registradas durante o turno
  Future<List<PedidoData>> carregarEncomendasFuturasSessao([String? sessaoId]) async {
    final pedidos = await carregarPedidosSessao(sessaoId);
    return pedidos.where((p) {
      final isAgendado = (p.tipoLogistica.toLowerCase().contains('agend') ||
          p.tipoLogistica.toLowerCase().contains('programada') ||
          p.dataHoraEntregaPrevista != null);
      return isAgendado;
    }).toList();
  }

  /// Carrega o balanço de Contas a Receber do turno:
  /// - Contas geradas a prazo no turno (separadas em já quitadas vs pendentes)
  /// - Baixas / recebimentos efetuados no turno (identificando se quitou pedido deste turno ou título anterior)
  Future<Map<String, dynamic>> carregarContasReceberDoTurno([String? sessaoId]) async {
    if (!_context.hasContext) return {};
    final tenantId = _context.tenantId;

    final targetSessao = sessaoId != null
        ? await (_db.select(_db.sessoesCaixaTable)..where((s) => s.id.equals(sessaoId))).getSingleOrNull()
        : _resumo.sessaoAtiva;

    if (targetSessao == null) return {};

    final inicio = targetSessao.dataAbertura;
    final fim = targetSessao.dataFechamento ?? DateTime.now().toUtc();

    // 1. Pedidos do período da sessão (não cancelados, não rascunho, não consumo interno)
    final pedidos = await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.isNotIn(['cancelado', 'rascunho']) &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
              t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
              t.isUsoInterno.equals(false) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.asc)]))
        .get();

    // 2. Lançamentos financeiros do turno
    final lancamentos = await carregarLancamentosSessao(sessaoId ?? targetSessao.id);

    // Baixas / recebimentos efetuados neste turno
    final lancamentosBaixa = lancamentos.where((l) {
      final d = l.descricao.toLowerCase();
      return l.tipo == 'receita' &&
          (d.contains('baixa') ||
              d.contains('liquid') ||
              d.contains('quitação') ||
              d.contains('quitacao') ||
              d.contains('recebimento conta') ||
              d.contains('recebimento titulo') ||
              d.contains('recebimento título'));
    }).toList();

    // Mapeamento de pedidoId -> Lançamento de Baixa
    final Map<String, LancamentoFinanceiroData> mapaBaixasPorPedido = {};
    final Set<String> pedidosComBaixa = {};

    for (final l in lancamentosBaixa) {
      if (l.pedidoId != null) {
        mapaBaixasPorPedido[l.pedidoId!] = l;
        pedidosComBaixa.add(l.pedidoId!);
      }
    }

    // Identificar pedidos do turno faturados a prazo / fiado / crediário / a receber
    final contasGeradas = pedidos.where((p) {
      final fp = (p.formaPagamentoNome ?? '').toLowerCase();
      final isDinheiro = fp.contains('dinheiro') || fp.contains('especie') || fp.isEmpty;
      // Considera a prazo/fiado ou qualquer modalidade a faturar
      final isPrazo = fp.contains('prazo') ||
          fp.contains('fiado') ||
          fp.contains('crediar') ||
          fp.contains('faturad') ||
          fp.contains('boleto') ||
          fp.contains('carn') ||
          fp.contains('vale') ||
          fp.contains('convenio') ||
          fp.contains('pendente');
      return (isPrazo || !isDinheiro) && !p.isUsoInterno;
    }).toList();

    // Também verificar se a descrição do lançamento cita o número do pedido
    for (final p in contasGeradas) {
      if (!pedidosComBaixa.contains(p.id)) {
        final numStr = p.numeroPedido != null ? '#${p.numeroPedido}' : '';
        if (numStr.isNotEmpty) {
          final baixaCorrespondente = lancamentosBaixa.cast<LancamentoFinanceiroData?>().firstWhere(
                (l) => l != null && l.descricao.contains(numStr),
                orElse: () => null,
              );
          if (baixaCorrespondente != null) {
            pedidosComBaixa.add(p.id);
            mapaBaixasPorPedido[p.id] = baixaCorrespondente;
          }
        }
      }
    }

    // Contas geradas no turno separadas por status
    final contasGeradasQuitadas = contasGeradas.where((p) => pedidosComBaixa.contains(p.id)).toList();
    final contasGeradasPendentes = contasGeradas.where((p) => !pedidosComBaixa.contains(p.id)).toList();

    // Baixas separadas por origem: quitou pedido gerado neste turno vs título/dívida anterior
    final setIdsPedidosTurno = pedidos.map((p) => p.id).toSet();
    final lancamentosBaixaTurnoAtual = lancamentosBaixa.where((l) => l.pedidoId != null && setIdsPedidosTurno.contains(l.pedidoId)).toList();
    final lancamentosBaixaAnteriores = lancamentosBaixa.where((l) => l.pedidoId == null || !setIdsPedidosTurno.contains(l.pedidoId)).toList();

    final totalGeradoCentavos = contasGeradas.fold<int>(0, (s, p) => s + p.valorTotalCentavos);
    final totalGeradoQuitadoCentavos = contasGeradasQuitadas.fold<int>(0, (s, p) => s + p.valorTotalCentavos);
    final totalGeradoPendenteCentavos = contasGeradasPendentes.fold<int>(0, (s, p) => s + p.valorTotalCentavos);
    final totalRecebidoCentavos = lancamentosBaixa.fold<int>(0, (s, l) => s + l.valorCentavos);
    final totalRecebidoDinheiroCentavos = lancamentosBaixa.where((l) {
      final fp = (l.formaPagamentoNome ?? '').toLowerCase();
      return fp.contains('dinheiro') || fp.contains('especie');
    }).fold<int>(0, (s, l) => s + l.valorCentavos);

    return {
      'contasGeradas': contasGeradas,
      'contasGeradasQuitadas': contasGeradasQuitadas,
      'contasGeradasPendentes': contasGeradasPendentes,
      'lancamentosBaixa': lancamentosBaixa,
      'lancamentosBaixaTurnoAtual': lancamentosBaixaTurnoAtual,
      'lancamentosBaixaAnteriores': lancamentosBaixaAnteriores,
      'totalGeradoCentavos': totalGeradoCentavos,
      'totalGeradoQuitadoCentavos': totalGeradoQuitadoCentavos,
      'totalGeradoPendenteCentavos': totalGeradoPendenteCentavos,
      'totalRecebidoCentavos': totalRecebidoCentavos,
      'totalRecebidoDinheiroCentavos': totalRecebidoDinheiroCentavos,
      'pedidosComBaixa': pedidosComBaixa,
      'mapaBaixasPorPedido': mapaBaixasPorPedido,
    };
  }

  // ─────────────────────────────────────────────────────────────────
  // Abrir / Fechar Caixa
  // ─────────────────────────────────────────────────────────────────

  /// Abre uma nova sessão de caixa com numeração AUTOMÁTICA.
  /// O número do turno é calculado automaticamente (quantos turnos foram abertos hoje + 1).
  /// O operador NÃO escolhe o nome — o sistema determina.
  Future<void> abrirCaixa({
    int valorAberturaCentavos = 0,
    String nomeTurno = '', // Ignorado — mantido para compatibilidade de chamada
  }) async {
    if (!_context.hasContext) return;
    if (_resumo.caixaAberto) return;

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final operadorNome = _context.usuario.nome;
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();

    // Calcular número automático do turno para o dia atual
    final numeroTurnoHoje = await _calcularProximoNumeroTurno(tenantId);

    // Formato estruturado para extração posterior: "TURNO:N:..."
    final hoje = DateTime.now();
    final diaStr = '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
    final obsComNumero = 'TURNO:$numeroTurnoHoje:$diaStr';

    await _db.into(_db.sessoesCaixaTable).insert(
      SessoesCaixaTableCompanion.insert(
        id: id,
        tenantId: tenantId,
        operadorId: operadorId,
        operadorNome: Value(operadorNome),
        status: const Value('aberta'),
        dataAbertura: now,
        valorAberturaCentavos: Value(valorAberturaCentavos),
        observacoes: Value(obsComNumero),
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
        observacoes: obsComNumero,
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

    // Diferença: valor contado - dinheiro esperado na gaveta
    final diferenca = valorContadoCentavos != null
        ? valorContadoCentavos - _resumo.saldoEsperadoDinheiroCentavos
        : null;

    // Manter o prefixo TURNO:N: nas observacoes ao adicionar obs do fechamento
    final obsAtual = sessao.observacoes ?? '';
    final obsPreserved = observacoes != null && observacoes.isNotEmpty
        ? '$obsAtual | Fechamento: $observacoes'
        : obsAtual;

    await (_db.update(_db.sessoesCaixaTable)
          ..where((t) => t.id.equals(sessao.id)))
        .write(SessoesCaixaTableCompanion(
      status: const Value('fechada'),
      dataFechamento: Value(now),
      valorFechamentoCentavos: Value(valorContadoCentavos),
      totalVendasCentavos: Value(_resumo.totalVendasCentavos),
      totalDespesasCentavos: Value(_resumo.totalDespesasCentavos),
      diferencaCentavos: Value(diferenca),
      observacoes: Value(obsPreserved),
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
        observacoes: obsPreserved,
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
    String? formaPagamentoNome,
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
        formaPagamentoNome: Value(formaPagamentoNome),
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
        'formaPagamentoNome': formaPagamentoNome,
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

  /// Carrega a Timeline Financeira Cronológica do Turno.
  ///
  /// Une todos os eventos do turno — pedidos confirmados, cancelamentos,
  /// lançamentos de sangria/suprimento/despesa/baixa — em uma lista ordenada
  /// por data/hora, permitindo rastreabilidade completa de cada centavo.
  Future<List<EventoTimeline>> carregarTimelineFinanceira([String? sessaoId]) async {
    if (!_context.hasContext) return [];

    final targetSessao = sessaoId != null
        ? await (_db.select(_db.sessoesCaixaTable)..where((s) => s.id.equals(sessaoId))).getSingleOrNull()
        : _resumo.sessaoAtiva;

    if (targetSessao == null) return [];

    final inicio = targetSessao.dataAbertura;
    final fim = targetSessao.dataFechamento ?? DateTime.now().toUtc();
    final tenantId = _context.tenantId;

    final eventos = <EventoTimeline>[];

    // Evento de abertura
    eventos.add(EventoTimeline(
      dataHora: targetSessao.dataAbertura,
      tipo: EventoTipo.abertura,
      descricao: 'Turno aberto por ${targetSessao.operadorNome}',
      valorCentavos: targetSessao.valorAberturaCentavos,
      operadorNome: targetSessao.operadorNome,
    ));

    // Pedidos confirmados
    final pedidos = await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.isNotIn(['cancelado', 'rascunho']) &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
              t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.asc)]))
        .get();

    for (final p in pedidos) {
      final fp = p.formaPagamentoNome ?? 'Dinheiro';
      final isConsumo = p.isUsoInterno ||
          fp.toLowerCase().contains('consumo') ||
          fp.toLowerCase().contains('cortesia') ||
          fp.toLowerCase().contains('bonifica') ||
          fp.toLowerCase().contains('interno');

      eventos.add(EventoTimeline(
        dataHora: p.dataHoraCriacao,
        tipo: isConsumo ? EventoTipo.consumoInterno : EventoTipo.venda,
        descricao: isConsumo
            ? 'Consumo Interno${p.clienteNomeAvulso != null ? " · ${p.clienteNomeAvulso}" : ""}'
            : 'Venda #${p.numeroPedido?.toString().padLeft(4, "0") ?? p.id.substring(0, 6)} — ${p.clienteNomeAvulso ?? "Consumidor Final"} · $fp',
        valorCentavos: p.valorTotalCentavos,
        pedidoId: p.id,
        numeroPedido: p.numeroPedido,
        clienteNome: p.clienteNomeAvulso,
        formaPagamento: fp,
        tipoLogistica: p.tipoLogistica,
        operadorNome: targetSessao.operadorNome,
      ));
    }

    // Pedidos cancelados
    final cancelados = await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.equals('cancelado') &
              t.dataHoraCriacao.isBiggerOrEqualValue(inicio) &
              t.dataHoraCriacao.isSmallerOrEqualValue(fim.add(const Duration(minutes: 1))) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.asc)]))
        .get();

    for (final p in cancelados) {
      eventos.add(EventoTimeline(
        dataHora: p.dataHoraCriacao,
        tipo: EventoTipo.cancelamento,
        descricao: 'CANCELAMENTO #${p.numeroPedido?.toString().padLeft(4, "0") ?? p.id.substring(0, 6)} — ${p.clienteNomeAvulso ?? "Consumidor Final"}',
        valorCentavos: p.valorTotalCentavos,
        pedidoId: p.id,
        numeroPedido: p.numeroPedido,
        clienteNome: p.clienteNomeAvulso,
        formaPagamento: p.formaPagamentoNome,
        operadorNome: targetSessao.operadorNome,
      ));
    }

    // Lançamentos financeiros (sangrias, suprimentos, despesas, baixas)
    final lancamentos = await (_db.select(_db.lancamentosFinanceirosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.sessaoCaixaId.equals(targetSessao.id) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dataHora, mode: OrderingMode.asc)]))
        .get();

    for (final l in lancamentos) {
      final descLower = l.descricao.toLowerCase();
      final isBaixa = descLower.contains('baixa') ||
          descLower.contains('liquid') ||
          descLower.contains('quitação') ||
          descLower.contains('quitacao') ||
          descLower.contains('recebimento conta');

      EventoTipo tipoEvento;
      if (l.tipo == 'sangria') {
        tipoEvento = EventoTipo.sangria;
      } else if (l.tipo == 'suprimento') {
        tipoEvento = EventoTipo.suprimento;
      } else if (l.tipo == 'despesa') {
        tipoEvento = EventoTipo.despesa;
      } else if (isBaixa) {
        tipoEvento = EventoTipo.baixa;
      } else {
        tipoEvento = EventoTipo.recebimento;
      }

      eventos.add(EventoTimeline(
        dataHora: l.dataHora,
        tipo: tipoEvento,
        descricao: l.descricao.isNotEmpty ? l.descricao : l.tipo.toUpperCase(),
        valorCentavos: l.valorCentavos,
        lancamentoId: l.id,
        formaPagamento: l.formaPagamentoNome,
        pedidoId: l.pedidoId,
        operadorNome: targetSessao.operadorNome,
      ));
    }

    // Evento de fechamento (se sessão fechada)
    if (targetSessao.dataFechamento != null) {
      eventos.add(EventoTimeline(
        dataHora: targetSessao.dataFechamento!,
        tipo: EventoTipo.fechamento,
        descricao: 'Turno encerrado por ${targetSessao.operadorNome}',
        valorCentavos: targetSessao.valorFechamentoCentavos ?? 0,
        operadorNome: targetSessao.operadorNome,
      ));
    }

    // Ordenar cronologicamente
    eventos.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return eventos;
  }

  Map<String, dynamic> _sessaoPayload({
    required String id,
    required String tenantId,
    required String operadorId,
    required String? operadorNome,
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
