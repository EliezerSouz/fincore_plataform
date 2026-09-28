import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

/// Tabela de Sessões de Caixa (Turno Operacional)
///
/// Um caixa é aberto no início do turno e fechado no fim.
/// Todos os lançamentos financeiros pertencem a uma sessão.
///
/// Status: 'aberta' → 'em_conferencia' → 'fechada'
@DataClassName('SessaoCaixaData')
@TableIndex(
    name: 'sessao_caixa_tenant_status_idx', columns: {#tenantId, #status})
@TableIndex(
    name: 'sessao_caixa_operador_idx', columns: {#tenantId, #operadorId})
class SessoesCaixaTable extends Table
    with IdentityColumns, AuditColumns, SyncColumns {
  /// Operador responsável pela sessão
  TextColumn get operadorId => text()();

  /// Nome snapshot do operador (evita join)
  TextColumn get operadorNome => text().withDefault(const Constant('Operador'))();

  /// Status do ciclo: 'aberta' | 'em_conferencia' | 'fechada'
  TextColumn get status => text().withDefault(const Constant('aberta'))();

  /// Data/hora de abertura do caixa
  DateTimeColumn get dataAbertura => dateTime()();

  /// Data/hora de fechamento (null enquanto aberta)
  DateTimeColumn get dataFechamento => dateTime().nullable()();

  /// Valor do fundo de troco ao abrir (em centavos)
  IntColumn get valorAberturaCentavos =>
      integer().withDefault(const Constant(0))();

  /// Valor contado fisicamente ao fechar (em centavos, null se não conferido)
  IntColumn get valorFechamentoCentavos => integer().nullable()();

  /// Total de vendas consolidado ao fechar (calculado automaticamente)
  IntColumn get totalVendasCentavos =>
      integer().withDefault(const Constant(0))();

  /// Total de despesas/sangrias na sessão
  IntColumn get totalDespesasCentavos =>
      integer().withDefault(const Constant(0))();

  /// Diferença (sobra/falta): valorFechamento - (abertura + receitas - despesas)
  IntColumn get diferencaCentavos => integer().nullable()();

  /// Observações do operador ao fechar
  TextColumn get observacoes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Lançamentos Financeiros
///
/// Cada transação monetária (venda, sangria, suprimento, despesa)
/// registra uma linha aqui, associada a uma sessão de caixa.
///
/// Valores SEMPRE em centavos e SEMPRE positivos.
/// O campo `tipo` determina se aumenta ou diminui o saldo.
///
/// Tipos:
///   'receita'    → venda realizada (aumenta saldo)
///   'sangria'    → retirada de dinheiro (diminui saldo)
///   'suprimento' → reforço de troco (aumenta saldo)
///   'despesa'    → pagamento de conta operacional (diminui saldo)
@DataClassName('LancamentoFinanceiroData')
@TableIndex(
    name: 'lancamento_sessao_idx', columns: {#tenantId, #sessaoCaixaId})
@TableIndex(
    name: 'lancamento_forma_pgto_idx',
    columns: {#tenantId, #formaPagamentoId})
@TableIndex(
    name: 'lancamento_data_idx', columns: {#tenantId, #dataHora})
class LancamentosFinanceirosTable extends Table
    with IdentityColumns, AuditColumns, SyncColumns {
  /// Sessão de caixa à qual este lançamento pertence
  TextColumn get sessaoCaixaId => text()();

  /// Pedido que originou a receita (null para sangria, suprimento, despesa)
  TextColumn get pedidoId => text().nullable()();

  /// Tipo do lançamento
  TextColumn get tipo => text()();

  /// ID da forma de pagamento (null para despesas sem pagamento digital)
  TextColumn get formaPagamentoId => text().nullable()();

  /// Snapshot do nome da forma de pagamento
  TextColumn get formaPagamentoNome => text().nullable()();

  /// Valor em centavos (sempre positivo)
  IntColumn get valorCentavos => integer()();

  /// Descrição legível: "Venda #0042 - PIX", "Sangria de caixa", etc.
  TextColumn get descricao => text().withDefault(const Constant(''))();

  /// Operador que registrou o lançamento
  TextColumn get operadorId => text().nullable()();

  /// Data e hora exata do lançamento
  DateTimeColumn get dataHora => dateTime()();

  /// Bandeira do cartão (ex: Visa, Mastercard, Elo) — para conciliação futura
  TextColumn get bandeira => text().nullable()();

  /// NSU / Identificador da transação da maquininha — para conciliação futura
  TextColumn get nsuTransacao => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
