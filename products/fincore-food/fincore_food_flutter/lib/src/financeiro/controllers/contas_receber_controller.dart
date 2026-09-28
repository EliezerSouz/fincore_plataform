import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:uuid/uuid.dart';

enum StatusTituloReceber {
  pendente,
  recebido,
  atrasado,
  cancelado,
}

class TituloReceber {
  final String id;
  final String pedidoId;
  final int? numeroPedido;
  final String? clienteId;
  final String clienteNome;
  final String? clienteTelefone;
  final String? formaPagamentoId;
  final String formaPagamentoNome;
  final String? formaPagamentoTipo;
  final String? pixChave;
  final String? pixTipoChave;
  final int valorTotalCentavos;
  final double taxaMdrPercentual;
  final int prazoRepasseDias;
  final String tipoDiasRepasse;
  final StatusTituloReceber status;
  final DateTime dataEmissao;
  final DateTime dataEntrega;
  final DateTime dataVencimento;
  final DateTime? dataRecebimento;
  final String? operadorId;
  final String? observacoes;
  final String canalOrigem;

  const TituloReceber({
    required this.id,
    required this.pedidoId,
    this.numeroPedido,
    this.clienteId,
    required this.clienteNome,
    this.clienteTelefone,
    this.formaPagamentoId,
    required this.formaPagamentoNome,
    this.formaPagamentoTipo,
    this.pixChave,
    this.pixTipoChave,
    required this.valorTotalCentavos,
    this.taxaMdrPercentual = 0.0,
    this.prazoRepasseDias = 0,
    this.tipoDiasRepasse = 'corridos',
    required this.status,
    required this.dataEmissao,
    required this.dataEntrega,
    required this.dataVencimento,
    this.dataRecebimento,
    this.operadorId,
    this.observacoes,
    this.canalOrigem = 'pdv_express',
  });

  bool get isPendente => status == StatusTituloReceber.pendente;
  bool get isRecebido => status == StatusTituloReceber.recebido;
  bool get isAtrasado => status == StatusTituloReceber.atrasado;
  bool get isPix => (formaPagamentoTipo?.toLowerCase() == 'pix') || formaPagamentoNome.toLowerCase().contains('pix');

  bool get isCartao =>
      (formaPagamentoTipo?.toLowerCase().contains('cart') ?? false) ||
      formaPagamentoNome.toLowerCase().contains('cart') ||
      formaPagamentoNome.toLowerCase().contains('créd') ||
      formaPagamentoNome.toLowerCase().contains('cred') ||
      formaPagamentoNome.toLowerCase().contains('déb') ||
      formaPagamentoNome.toLowerCase().contains('deb');

  bool get isNotaPrazo =>
      (formaPagamentoTipo?.toLowerCase() == 'notaprazo') ||
      formaPagamentoNome.toLowerCase().contains('prazo') ||
      formaPagamentoNome.toLowerCase().contains('faturad');

  /// Indica se, do ponto de vista do cliente, o valor já foi quitado no ato da compra.
  /// (PIX, Dinheiro, Cartão de Crédito/Débito são pagos pelo cliente no ato; apenas Nota a Prazo gera dívida pendente do cliente).
  bool get isPagoPeloCliente => !isNotaPrazo || isRecebido;

  /// Valor estimado retido pela operadora da maquininha (MDR)
  int get valorTaxaCentavos => taxaMdrPercentual > 0 ? ((valorTotalCentavos * taxaMdrPercentual) / 100.0).round() : 0;

  /// Valor líquido estimado que entrará na conta bancária
  int get valorLiquidoCentavos => valorTotalCentavos - valorTaxaCentavos;

  /// Identifica o grupo/tipo de pagamento padronizado (PIX, Cartão, Nota a Prazo, etc.)
  String get tipoModalidadePadronizada {
    final tipo = formaPagamentoTipo?.toLowerCase() ?? '';
    final nome = formaPagamentoNome.toLowerCase();

    if (tipo == 'pix' || nome.contains('pix')) return 'PIX';
    if (tipo == 'cartaocredito' || (nome.contains('cart') && (nome.contains('créd') || nome.contains('cred')))) return 'Cartão de Crédito';
    if (tipo == 'cartaodebito' || (nome.contains('cart') && (nome.contains('déb') || nome.contains('deb')))) return 'Cartão de Débito';
    if (tipo.contains('cart') || nome.contains('cart')) return 'Cartão';
    if (tipo == 'notaprazo' || nome.contains('prazo') || nome.contains('faturad')) return 'Nota a Prazo';
    if (tipo == 'consumointerno' || nome.contains('consumo') || nome.contains('interno')) return 'Consumo Interno';
    return 'Outros';
  }

  String get friendlyNumeroPedido {
    if (numeroPedido != null) {
      return '#${numeroPedido.toString().padLeft(4, '0')}';
    }
    if (pedidoId.length > 6) {
      return '#${pedidoId.substring(0, 6).toUpperCase()}';
    }
    return '#$pedidoId';
  }
}

DateTime _adicionarDiasUteis(DateTime dataBase, int diasUteis) {
  DateTime data = dataBase;
  int adicionados = 0;
  while (adicionados < diasUteis) {
    data = data.add(const Duration(days: 1));
    if (data.weekday != DateTime.saturday && data.weekday != DateTime.sunday) {
      adicionados++;
    }
  }
  return data;
}

int _extrairPrazoDias(String? texto, [String? fallbackNome]) {
  final combined = '${texto ?? ''} ${fallbackNome ?? ''}';
  final match = RegExp(r'prazo[:\s=_-]*(\d+)', caseSensitive: false).firstMatch(combined) ??
      RegExp(r'(\d+)\s*dias?', caseSensitive: false).firstMatch(combined);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 7;
  }
  return 7;
}

double _extrairTaxaMdr(String? texto, [String? fallbackNome]) {
  final combined = '${texto ?? ''} ${fallbackNome ?? ''}';
  final match = RegExp(r'taxa[:\s=_-]*([0-9]+(?:[\.,][0-9]+)?)\s*%', caseSensitive: false).firstMatch(combined) ??
      RegExp(r'([0-9]+(?:[\.,][0-9]+)?)\s*%', caseSensitive: false).firstMatch(combined);
  if (match != null) {
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
  }
  return 0.0;
}

int _extrairPrazoRepasse(String? texto, [String? tipo, String? fallbackNome]) {
  final combined = '${texto ?? ''} ${fallbackNome ?? ''}';
  final match = RegExp(r'repasse[:\s=_-]*(\d+)', caseSensitive: false).firstMatch(combined) ??
      RegExp(r'd\+(\d+)', caseSensitive: false).firstMatch(combined);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? ((tipo?.toLowerCase() == 'cartaodebito') ? 1 : 30);
  }
  final t = (tipo ?? '').toLowerCase();
  if (t == 'cartaodebito' || (fallbackNome?.toLowerCase().contains('déb') ?? false)) return 1;
  if (t == 'cartaocredito' || (fallbackNome?.toLowerCase().contains('créd') ?? false)) return 30;
  return 0;
}

String _extrairTipoDiasRepasse(String? texto, [String? tipo]) {
  final t = (texto ?? '').toLowerCase();
  if (t.contains('útil') || t.contains('uteis') || t.contains('util')) return 'úteis';
  if (t.contains('corrid')) return 'corridos';
  if ((tipo ?? '').toLowerCase() == 'cartaodebito') return 'úteis';
  return 'corridos';
}

/// Controller de Contas a Receber da FINCORE
class ContasReceberController extends ChangeNotifier {
  final FincoreDatabase _db;
  final TenantContext _context;
  final OutboxService _outbox;
  final _uuid = const Uuid();

  List<TituloReceber> _titulos = [];
  bool _loading = false;
  String? _error;

  String _statusFilter = 'Todos'; // 'Todos', 'Pendentes', 'Recebidos', 'Atrasados'
  String _formaPgtoFilter = 'Todas'; // 'Todas', 'PIX', 'Cartão de Crédito', 'Cartão de Débito', 'Nota a Prazo', etc.
  String _searchQuery = '';
  DateTime? _dataDe;
  DateTime? _dataAte;
  String _periodoPreset = 'tudo'; // 'tudo', 'hoje', '7dias', 'mes', 'custom'

  ContasReceberController()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>(),
        _outbox = DependencyInjection().get<OutboxService>() {
    carregar();
  }

  List<TituloReceber> get titulos => _titulos;
  bool get loading => _loading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get formaPgtoFilter => _formaPgtoFilter;
  String get searchQuery => _searchQuery;
  DateTime? get dataDe => _dataDe;
  DateTime? get dataAte => _dataAte;
  String get periodoPreset => _periodoPreset;

  List<String> get modalidadesDisponiveis {
    final set = <String>{};
    for (final t in _titulos) {
      set.add(t.tipoModalidadePadronizada);
    }
    const ordemPreferida = [
      'PIX',
      'Cartão de Crédito',
      'Cartão de Débito',
      'Cartão',
      'Nota a Prazo',
      'Consumo Interno',
      'Outros',
    ];
    final list = set.toList()
      ..sort((a, b) {
        final idxA = ordemPreferida.indexOf(a);
        final idxB = ordemPreferida.indexOf(b);
        if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
        if (idxA != -1) return -1;
        if (idxB != -1) return 1;
        return a.compareTo(b);
      });
    return ['Todas', ...list];
  }

  List<String> get formasPagamentoDisponiveis => modalidadesDisponiveis;

  // ─── Métricas Consolidadas (Dinâmicas com base nos Filtros Ativos) ─────────

  /// Lista de títulos aplicando filtros de busca, modalidade de pagamento e período
  List<TituloReceber> get titulosContextoFiltrado {
    return _titulos.where((t) {
      // Filtro por Modalidade / Tipo de Pagamento (PIX, Cartão, Nota a Prazo, etc.)
      if (_formaPgtoFilter == 'Notas a Prazo' || _formaPgtoFilter == 'Nota a Prazo') {
        if (!t.isNotaPrazo) return false;
      } else if (_formaPgtoFilter == 'Cartões a Receber' || _formaPgtoFilter == 'Cartão' || _formaPgtoFilter == 'Cartão de Crédito' || _formaPgtoFilter == 'Cartão de Débito') {
        if (!t.isCartao) return false;
      } else if (_formaPgtoFilter == 'PIX a Receber' || _formaPgtoFilter == 'PIX') {
        if (!t.isPix) return false;
      } else if (_formaPgtoFilter != 'Todas' && _formaPgtoFilter != 'Todos' && t.tipoModalidadePadronizada != _formaPgtoFilter) {
        return false;
      }

      // Filtro de Busca (Cliente, Telefone, Pedido #, Forma Pgto)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNome = t.clienteNome.toLowerCase().contains(q);
        final matchTel = t.clienteTelefone?.contains(q) ?? false;
        final matchPed = t.friendlyNumeroPedido.toLowerCase().contains(q);
        final matchFp = t.formaPagamentoNome.toLowerCase().contains(q);
        final matchMod = t.tipoModalidadePadronizada.toLowerCase().contains(q);
        if (!matchNome && !matchTel && !matchPed && !matchFp && !matchMod) return false;
      }

      // Filtro de Período (compara com a data de emissão ou entrega)
      if (_dataDe != null) {
        final inicioDe = DateTime(_dataDe!.year, _dataDe!.month, _dataDe!.day, 0, 0, 0);
        if (t.dataEmissao.isBefore(inicioDe)) return false;
      }
      if (_dataAte != null) {
        final fimAte = DateTime(_dataAte!.year, _dataAte!.month, _dataAte!.day, 23, 59, 59, 999);
        if (t.dataEmissao.isAfter(fimAte)) return false;
      }

      return true;
    }).toList();
  }

  int get totalAReceberCentavos => titulosContextoFiltrado
      .where((t) => t.isPendente || t.isAtrasado)
      .fold(0, (acc, t) => acc + t.valorTotalCentavos);

  int get totalLiquidoAReceberCentavos => titulosContextoFiltrado
      .where((t) => t.isPendente || t.isAtrasado)
      .fold(0, (acc, t) => acc + t.valorLiquidoCentavos);

  int get totalTaxasMdrEstimadasCentavos => titulosContextoFiltrado
      .where((t) => t.isPendente || t.isAtrasado)
      .fold(0, (acc, t) => acc + t.valorTaxaCentavos);

  int get totalRecebidoPeriodoCentavos => titulosContextoFiltrado
      .where((t) => t.isRecebido)
      .fold(0, (acc, t) => acc + t.valorTotalCentavos);

  int get totalVencidoCentavos => titulosContextoFiltrado
      .where((t) => t.isAtrasado)
      .fold(0, (acc, t) => acc + t.valorTotalCentavos);

  int get qtdPendentes =>
      titulosContextoFiltrado.where((t) => t.isPendente || t.isAtrasado).length;

  int get qtdRecebidos =>
      titulosContextoFiltrado.where((t) => t.isRecebido).length;

  int get qtdAtrasados =>
      titulosContextoFiltrado.where((t) => t.isAtrasado).length;

  int get qtdTotal => titulosContextoFiltrado.length;

  // ─── Lista Filtrada (Incluindo Filtro de Status) ───────────────────────────

  List<TituloReceber> get titulosFiltrados {
    return titulosContextoFiltrado.where((t) {
      // Filtro de Status
      if (_statusFilter == 'Pendentes' && !t.isPendente && !t.isAtrasado) return false;
      if (_statusFilter == 'Recebidos' && !t.isRecebido) return false;
      if (_statusFilter == 'Atrasados' && !t.isAtrasado) return false;

      return true;
    }).toList();
  }

  // ─── Carregamento ──────────────────────────────────────────────────────────

  Future<void> carregar() async {
    if (!_context.hasContext) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantId = _context.tenantId;

      // 1. Carrega todos os pedidos não cancelados que movimentam financeiro
      final pedidosRows = await (_db.select(_db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.deletedAt.isNull() &
                t.isUsoInterno.equals(false) &
                t.status.isNotIn(['cancelado']))
            ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.desc)]))
          .get();

      // 2. Carrega formas de pagamento
      final formasRows = await (_db.select(_db.formasPagamentoTable)
            ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
          .get();
      final formasMap = {for (final f in formasRows) f.id: f};

      // 3. Carrega clientes cadastrados para enriquecer telefones se necessário
      final clientesRows = await (_db.select(_db.clientesTable)
            ..where((c) => c.tenantId.equals(tenantId) & c.deletedAt.isNull()))
          .get();
      final clientesMap = {for (final c in clientesRows) c.id: c};

      // 4. Carrega lançamentos financeiros
      final lancamentosRows = await (_db.select(_db.lancamentosFinanceirosTable)
            ..where((l) => l.tenantId.equals(tenantId) & l.deletedAt.isNull()))
          .get();
      final lancamentosPorPedido = <String, List<LancamentoFinanceiroData>>{};
      for (final l in lancamentosRows) {
        if (l.pedidoId != null) {
          lancamentosPorPedido.putIfAbsent(l.pedidoId!, () => []).add(l);
        }
      }

      final agora = DateTime.now();
      final List<TituloReceber> lista = [];

      for (final ped in pedidosRows) {
        final forma = ped.formaPagamentoId != null ? formasMap[ped.formaPagamentoId] : null;
        final cliente = ped.clienteId != null ? clientesMap[ped.clienteId] : null;

        final fpNome = ped.formaPagamentoNome ?? forma?.nome ?? 'Não informada';
        final fpTipo = forma?.tipo;
        final fpNomeLower = fpNome.toLowerCase();

        // ── Dinheiro: entra no caixa à vista — NÃO gera contas a receber ───────
        final isDinheiro = fpTipo == 'dinheiro' ||
            fpNomeLower.contains('dinheiro') ||
            fpNomeLower.contains('espécie') ||
            fpNomeLower.contains('especie') ||
            fpNomeLower == 'dinheiro';
        if (isDinheiro) continue;

        // ── Cartão de Crédito / Débito ────────────────────────────────────────
        final isCartao = (fpTipo != null &&
                (fpTipo.toLowerCase().contains('cartao') ||
                 fpTipo.toLowerCase().contains('cart'))) ||
            fpNomeLower.contains('cart') ||
            fpNomeLower.contains('créd') ||
            fpNomeLower.contains('cred') ||
            fpNomeLower.contains('déb') ||
            fpNomeLower.contains('deb');

        // ── Nota a Prazo / Fiado ──────────────────────────────────────────────
        final isNotaPrazo = fpTipo == 'notaPrazo' ||
            fpNomeLower.contains('prazo') ||
            fpNomeLower.contains('faturad') ||
            (forma?.descricao != null &&
             forma!.descricao!.toLowerCase().contains('prazo'));

        // ── PIX: Liquidação instantânea no ato da compra (D+0) ───────────────
        final isPix = fpTipo == 'pix' || fpNomeLower.contains('pix');

        // Formas que NÃO devem gerar título de contas a receber:
        // consumo interno, cortesia, bonificação, etc.
        final isConsumoOuCortesia = fpTipo == 'consumoInterno' ||
            fpNomeLower.contains('consumo') ||
            fpNomeLower.contains('cortesia') ||
            fpNomeLower.contains('bonif') ||
            fpNomeLower.contains('interno');
        if (isConsumoOuCortesia) continue;

        // Determina se já está quitado/recebido:
        final lancamentos = lancamentosPorPedido[ped.id] ?? [];

        // Para PIX: Liquidação instantânea D+0. Se o pedido foi realizado e confirmado, já é recebido.
        // Para Cartão ou Nota a Prazo: quitado via baixa explícita ou lançamento de receita.
        final temReceita = isPix
            ? true
            : (isNotaPrazo || isCartao)
                ? lancamentos.any((l) =>
                    l.tipo == 'receita' &&
                    l.descricao.toLowerCase().contains('baixa'))
                : lancamentos.any((l) => l.tipo == 'receita');

        // Data do Pedido e Data da Entrega
        final dataEntrega = ped.dataHoraEntregaPrevista?.toLocal() ?? ped.dataHoraCriacao.toLocal();

        final taxaMdr = isCartao ? _extrairTaxaMdr(forma?.descricao, fpNome) : 0.0;
        final prazoRepasse = isCartao ? _extrairPrazoRepasse(forma?.descricao, fpTipo, fpNome) : (isNotaPrazo ? _extrairPrazoDias(forma?.descricao, fpNome) : 0);
        final tipoDias = isCartao ? _extrairTipoDiasRepasse(forma?.descricao, fpTipo) : 'corridos';

        // Cálculo de Vencimento / Previsão de Repasse:
        DateTime dataVencimento = dataEntrega;
        if (isCartao) {
          if (tipoDias == 'úteis') {
            dataVencimento = _adicionarDiasUteis(dataEntrega, prazoRepasse);
          } else {
            dataVencimento = dataEntrega.add(Duration(days: prazoRepasse));
          }
        } else if (isNotaPrazo) {
          dataVencimento = dataEntrega.add(Duration(days: prazoRepasse));
        }

        StatusTituloReceber status;
        DateTime? dataRecebimento;

        if (temReceita) {
          status = StatusTituloReceber.recebido;
          final lancamentoReceita = lancamentos.where(
            (l) => (isNotaPrazo || isCartao)
                ? (l.tipo == 'receita' && l.descricao.toLowerCase().contains('baixa'))
                : l.tipo == 'receita',
          ).firstOrNull;
          dataRecebimento = lancamentoReceita?.dataHora.toLocal() ?? ped.dataHoraCriacao.toLocal();
        } else {
          // Pendente: se já passou a data do vencimento, está atrasado
          if (agora.isAfter(dataVencimento)) {
            status = StatusTituloReceber.atrasado;
          } else {
            status = StatusTituloReceber.pendente;
          }
        }

        final tel = ped.clienteTelefoneAvulso ?? cliente?.telefone;
        final nome = ped.clienteNomeAvulso ?? cliente?.nome ?? 'Cliente Sem Nome';

        lista.add(
          TituloReceber(
            id: ped.id,
            pedidoId: ped.id,
            numeroPedido: ped.numeroPedido,
            clienteId: ped.clienteId,
            clienteNome: nome,
            clienteTelefone: tel,
            formaPagamentoId: ped.formaPagamentoId,
            formaPagamentoNome: fpNome,
            formaPagamentoTipo: fpTipo,
            pixChave: forma?.pixChave,
            pixTipoChave: forma?.pixTipoChave,
            valorTotalCentavos: ped.valorTotalCentavos,
            taxaMdrPercentual: taxaMdr,
            prazoRepasseDias: prazoRepasse,
            tipoDiasRepasse: tipoDias,
            status: status,
            dataEmissao: ped.dataHoraCriacao.toLocal(),
            dataEntrega: dataEntrega,
            dataVencimento: dataVencimento,
            dataRecebimento: dataRecebimento,
            observacoes: ped.observacoes,
            canalOrigem: ped.canalOrigem,
          ),
        );
      }

      _titulos = lista;
      _loading = false;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ContasReceberController] Erro ao carregar: $e\n$stack');
      _error = 'Erro ao carregar contas a receber: $e';
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Dar Baixa / Confirmar Recebimento ─────────────────────────────────────

  Future<bool> darBaixa(
    TituloReceber titulo, {
    String? observacao,
    DateTime? dataBaixa,
    String? formaPagamentoQuitacaoId,
    String? formaPagamentoQuitacaoNome,
  }) async {
    if (!_context.hasContext) return false;

    try {
      final tenantId = _context.tenantId;
      final userId = _context.usuario.id;
      final agora = dataBaixa ?? DateTime.now();

      // 1. Busca sessão de caixa aberta para associar a receita
      var sessao = await (_db.select(_db.sessoesCaixaTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.status.equals('aberta') &
                t.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

      if (sessao == null) {
        final newSessaoId = _uuid.v4();
        await _db.into(_db.sessoesCaixaTable).insert(
          SessoesCaixaTableCompanion.insert(
            id: newSessaoId,
            tenantId: tenantId,
            operadorId: userId,
            operadorNome: Value(_context.usuario.nome.isNotEmpty ? _context.usuario.nome : 'Operador'),
            dataAbertura: agora.toUtc(),
            valorAberturaCentavos: const Value(0),
            status: const Value('aberta'),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: agora.toUtc(),
            updatedAt: agora.toUtc(),
            createdBy: userId,
            updatedBy: userId,
          ),
        );
        await _outbox.enqueue(
          entity: 'sessao_caixa',
          entityId: newSessaoId,
          action: 'CREATE',
          version: 1,
          payload: {
            'id': newSessaoId,
            'tenantId': tenantId,
            'operadorId': userId,
            'operadorNome': _context.usuario.nome.isNotEmpty ? _context.usuario.nome : 'Operador',
            'dataAbertura': agora.toUtc().toIso8601String(),
            'valorAberturaCentavos': 0,
            'status': 'aberta',
            'createdAt': agora.toUtc().toIso8601String(),
            'updatedAt': agora.toUtc().toIso8601String(),
            'createdBy': userId,
            'updatedBy': userId,
          },
        );
        sessao = await (_db.select(_db.sessoesCaixaTable)..where((t) => t.id.equals(newSessaoId))).getSingle();
      }

      final sessaoId = sessao.id;

      final lancamentoId = _uuid.v4();
      final valorReceitaCentavos = titulo.isCartao ? titulo.valorLiquidoCentavos : titulo.valorTotalCentavos;
      final fpNomeUsada = formaPagamentoQuitacaoNome ?? titulo.formaPagamentoNome;
      final fpIdUsada = formaPagamentoQuitacaoId ?? titulo.formaPagamentoId;

      final descReceita = titulo.isCartao
          ? 'Baixa Adquirente Cartão ${titulo.tipoModalidadePadronizada} ${titulo.friendlyNumeroPedido} - ${titulo.clienteNome}'
          : 'Baixa Contas a Receber ${titulo.friendlyNumeroPedido} - ${titulo.clienteNome}${observacao != null && observacao.isNotEmpty ? ' ($observacao)' : ''}';

      await _db.into(_db.lancamentosFinanceirosTable).insert(
        LancamentosFinanceirosTableCompanion.insert(
          id: lancamentoId,
          tenantId: tenantId,
          sessaoCaixaId: sessaoId,
          pedidoId: Value(titulo.pedidoId),
          tipo: 'receita',
          formaPagamentoId: Value(fpIdUsada),
          formaPagamentoNome: Value(fpNomeUsada),
          valorCentavos: valorReceitaCentavos,
          descricao: Value(descReceita),
          operadorId: Value(userId),
          dataHora: agora,
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: agora.toUtc(),
          updatedAt: agora.toUtc(),
          createdBy: userId,
          updatedBy: userId,
        ),
      );

      // Enfileira Outbox Receita
      await _outbox.enqueue(
        entity: 'lancamento_financeiro',
        entityId: lancamentoId,
        action: 'CREATE',
        version: 1,
        payload: {
          'id': lancamentoId,
          'tenantId': tenantId,
          'sessaoCaixaId': sessaoId,
          'pedidoId': titulo.pedidoId,
          'tipo': 'receita',
          'formaPagamentoId': fpIdUsada,
          'formaPagamentoNome': fpNomeUsada,
          'valorCentavos': valorReceitaCentavos,
          'descricao': descReceita,
          'operadorId': userId,
          'dataHora': agora.toUtc().toIso8601String(),
          'createdAt': agora.toUtc().toIso8601String(),
          'updatedAt': agora.toUtc().toIso8601String(),
          'createdBy': userId,
          'updatedBy': userId,
        },
      );

      // Partida dobrada: Lançamento de despesa da taxa da maquininha se houver
      if (titulo.isCartao && titulo.valorTaxaCentavos > 0) {
        final taxaLancamentoId = _uuid.v4();
        final descTaxa = 'Taxa MDR Adquirente (${titulo.taxaMdrPercentual.toStringAsFixed(2)}%) - ${titulo.friendlyNumeroPedido}';
        await _db.into(_db.lancamentosFinanceirosTable).insert(
          LancamentosFinanceirosTableCompanion.insert(
            id: taxaLancamentoId,
            tenantId: tenantId,
            sessaoCaixaId: sessaoId,
            pedidoId: Value(titulo.pedidoId),
            tipo: 'despesa',
            formaPagamentoId: Value(fpIdUsada),
            formaPagamentoNome: Value(fpNomeUsada),
            valorCentavos: titulo.valorTaxaCentavos,
            descricao: Value(descTaxa),
            operadorId: Value(userId),
            dataHora: agora,
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: agora.toUtc(),
            updatedAt: agora.toUtc(),
            createdBy: userId,
            updatedBy: userId,
          ),
        );
        await _outbox.enqueue(
          entity: 'lancamento_financeiro',
          entityId: taxaLancamentoId,
          action: 'CREATE',
          version: 1,
          payload: {
            'id': taxaLancamentoId,
            'tenantId': tenantId,
            'sessaoCaixaId': sessaoId,
            'pedidoId': titulo.pedidoId,
            'tipo': 'despesa',
            'formaPagamentoId': fpIdUsada,
            'formaPagamentoNome': fpNomeUsada,
            'valorCentavos': titulo.valorTaxaCentavos,
            'descricao': descTaxa,
            'operadorId': userId,
            'dataHora': agora.toUtc().toIso8601String(),
            'createdAt': agora.toUtc().toIso8601String(),
            'updatedAt': agora.toUtc().toIso8601String(),
            'createdBy': userId,
            'updatedBy': userId,
          },
        );
      }

      await carregar();
      return true;
    } catch (e) {
      debugPrint('[ContasReceberController] Erro ao dar baixa: $e');
      return false;
    }
  }

  /// Dá baixa em um pedido pelo [pedidoId] diretamente (usado pelo Kanban ou Aba Financeiro do Cliente)
  Future<bool> darBaixaPorPedidoId({
    required String pedidoId,
    String? observacao,
    DateTime? dataBaixa,
    String? formaPagamentoQuitacaoId,
    String? formaPagamentoQuitacaoNome,
  }) async {
    final t = _titulos.cast<TituloReceber?>().firstWhere(
      (item) => item?.pedidoId == pedidoId,
      orElse: () => null,
    );
    if (t != null) {
      return await darBaixa(
        t,
        observacao: observacao,
        dataBaixa: dataBaixa,
        formaPagamentoQuitacaoId: formaPagamentoQuitacaoId,
        formaPagamentoQuitacaoNome: formaPagamentoQuitacaoNome,
      );
    }

    // Se ainda não estiver carregado na lista em memória, tenta recuperar do banco local
    try {
      final ped = await (_db.select(_db.pedidosTable)..where((p) => p.id.equals(pedidoId))).getSingleOrNull();
      if (ped == null) return false;

      final fp = ped.formaPagamentoId != null
          ? await (_db.select(_db.formasPagamentoTable)..where((f) => f.id.equals(ped.formaPagamentoId!))).getSingleOrNull()
          : null;

      final dataEntrega = ped.dataHoraEntregaPrevista?.toLocal() ?? ped.dataHoraCriacao.toLocal();
      final tempTitulo = TituloReceber(
        id: ped.id,
        pedidoId: ped.id,
        numeroPedido: ped.numeroPedido,
        clienteId: ped.clienteId,
        clienteNome: ped.clienteNomeAvulso ?? 'Cliente',
        clienteTelefone: ped.clienteTelefoneAvulso,
        formaPagamentoId: ped.formaPagamentoId,
        formaPagamentoNome: ped.formaPagamentoNome ?? fp?.nome ?? 'Não informada',
        formaPagamentoTipo: fp?.tipo,
        pixChave: fp?.pixChave,
        pixTipoChave: fp?.pixTipoChave,
        valorTotalCentavos: ped.valorTotalCentavos,
        status: StatusTituloReceber.pendente,
        dataEmissao: ped.dataHoraCriacao.toLocal(),
        dataEntrega: dataEntrega,
        dataVencimento: dataEntrega,
        canalOrigem: ped.canalOrigem,
      );

      return await darBaixa(
        tempTitulo,
        observacao: observacao,
        dataBaixa: dataBaixa,
        formaPagamentoQuitacaoId: formaPagamentoQuitacaoId,
        formaPagamentoQuitacaoNome: formaPagamentoQuitacaoNome,
      );
    } catch (e) {
      debugPrint('[ContasReceberController] Erro ao dar baixa por pedidoId: $e');
      return false;
    }
  }

  /// Estorna a baixa de um pedido pelo [pedidoId] gravando o motivo em histórico (usado pelo Kanban, Detalhes de Pedido e Contas a Receber)
  Future<bool> estornarBaixaPorPedidoId({
    required String pedidoId,
    required String motivoEstorno,
    String? operadorNome,
  }) async {
    if (!_context.hasContext) return false;

    try {
      final tenantId = _context.tenantId;
      final userId = _context.usuario.id;
      final opNome = operadorNome ?? _context.usuario.nome;
      final now = DateTime.now().toUtc();

      // 1. Deleta os lançamentos de receita/despesa associados a este pedido
      final lancamentos = await (_db.select(_db.lancamentosFinanceirosTable)
            ..where((l) => l.tenantId.equals(tenantId) & l.pedidoId.equals(pedidoId)))
          .get();

      int valorEstornadoCentavos = 0;
      for (final l in lancamentos) {
        valorEstornadoCentavos += l.valorCentavos;
        await (_db.delete(_db.lancamentosFinanceirosTable)..where((t) => t.id.equals(l.id))).go();
        await _outbox.enqueue(
          entity: 'lancamento_financeiro',
          entityId: l.id,
          action: 'DELETE',
          version: l.syncVersion + 1,
          payload: {'id': l.id, 'tenantId': tenantId},
        );
      }

      // 2. Busca a OrdemPreparo associada para gravar na timeline do pedido
      final ordemRow = await (_db.select(_db.ordensPreparoTable)
            ..where((t) => t.tenantId.equals(tenantId) & t.pedidoId.equals(pedidoId)))
          .getSingleOrNull();

      if (ordemRow != null) {
        final valFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorEstornadoCentavos / 100);
        final histId = const Uuid().v4();
        final descHist = 'Estorno de pagamento ($valFmt) efetuado por $opNome. Motivo: $motivoEstorno';

        await _db.into(_db.historicosOrdemPreparoTable).insert(
          HistoricosOrdemPreparoTableCompanion.insert(
            id: histId,
            tenantId: tenantId,
            ordemPreparoId: ordemRow.id,
            titulo: 'ESTORNO DE PAGAMENTO',
            descricao: descHist,
            operadorNome: Value(opNome),
            criadaEm: now,
            versao: const Value('v1'),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: userId,
            updatedBy: userId,
          ),
        );

        await _outbox.enqueue(
          entity: 'HistoricoOrdemPreparo',
          entityId: histId,
          action: 'CREATE',
          version: 1,
          payload: {
            'id': histId,
            'tenantId': tenantId,
            'ordemPreparoId': ordemRow.id,
            'titulo': 'ESTORNO DE PAGAMENTO',
            'descricao': descHist,
            'operadorNome': opNome,
            'criadaEm': now.toIso8601String(),
            'versao': 'v1',
            'syncVersion': 1,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'createdBy': userId,
            'updatedBy': userId,
          },
        );
      }

      await carregar();
      return true;
    } catch (e) {
      debugPrint('[ContasReceberController] Erro ao estornar baixa: $e');
      return false;
    }
  }

  /// Retorna os títulos de um cliente específico (pelo ID ou nome).
  /// [apenasNotasPrazo] se true, filtra apenas pendências reais de Nota a Prazo/Faturado.
  List<TituloReceber> getTitulosPorCliente(String clienteId, {String? clienteNome, bool apenasNotasPrazo = false}) {
    return _titulos.where((t) {
      if (apenasNotasPrazo && !t.isNotaPrazo) return false;
      if (t.clienteId != null && t.clienteId == clienteId) return true;
      if (clienteNome != null && clienteNome.isNotEmpty && t.clienteNome.toLowerCase() == clienteNome.toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
  }

  // ─── Filtros ───────────────────────────────────────────────────────────────

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setFormaPgtoFilter(String filter) {
    _formaPgtoFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPeriodo(DateTime? de, DateTime? ate, [String preset = 'custom']) {
    _dataDe = de;
    _dataAte = ate;
    _periodoPreset = preset;
    notifyListeners();
  }

  void limparFiltros() {
    _statusFilter = 'Todos';
    _formaPgtoFilter = 'Todas';
    _searchQuery = '';
    _dataDe = null;
    _dataAte = null;
    _periodoPreset = 'tudo';
    notifyListeners();
  }
}

