import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'produtos_table.dart';

/// Tabela de Estoque de Produtos Acabados
///
/// Uma linha por produto que tem `controlaEstoque=true`.
///
/// ## Saldos
/// - `quantidadeAtual` → Físico real no freezer/estoque
/// - `quantidadeReservada` → Comprometido com pedidos futuros confirmados (não saiu fisicamente)
/// - Disponível = `quantidadeAtual - quantidadeReservada` (computed no app)
///
/// ## Fluxo de Produção
/// 1. Produção registrada → `quantidadeAtual` sobe (tipo: 'producao')
/// 2. Pedido futuro confirmado → `quantidadeReservada` sobe (tipo: 'reserva')
/// 3. Pedido cancelado → `quantidadeReservada` desce (tipo: 'liberacao_reserva')
/// 4. Entrega realizada → `quantidadeAtual` desce + `quantidadeReservada` desce (tipo: 'expedicao')
///
/// **Offline-First**: os saldos locais são a fonte de verdade durante
/// operação desconectada. O Outbox sincroniza para o Supabase.
@DataClassName('EstoqueProdutoData')
@TableIndex(name: 'estoque_produto_tenant_idx', columns: {#tenantId, #produtoId})
class EstoqueProdutosTable extends Table
    with IdentityColumns, AuditColumns, SyncColumns {
  /// Produto que este saldo representa
  TextColumn get produtoId => text().references(
        ProdutosTable,
        #id,
        onDelete: KeyAction.cascade,
        onUpdate: KeyAction.cascade,
      )();

  // ─── Saldos Físicos ───────────────────────────────────────────────────────

  /// Quantidade física atual no freezer/estoque (em unidades inteiras)
  IntColumn get quantidadeAtual =>
      integer().withDefault(const Constant(0))();

  /// Quantidade reservada — comprometida com pedidos futuros confirmados.
  /// Não saiu fisicamente ainda, mas já está comprometida.
  IntColumn get quantidadeReservada =>
      integer().withDefault(const Constant(0))();

  // ─── Limiares de Alerta ───────────────────────────────────────────────────

  /// Limiar mínimo de DISPONÍVEL — abaixo disso gera alerta "Estoque Baixo" (laranja).
  /// Alerta baseado em `quantidadeAtual - quantidadeReservada`.
  IntColumn get quantidadeMinima =>
      integer().withDefault(const Constant(0))();

  /// Limiar máximo — teto de reposição (para planejamento)
  IntColumn get quantidadeMaxima =>
      integer().withDefault(const Constant(9999))();

  // ─── Parâmetros de Produção ───────────────────────────────────────────────

  /// Tamanho sugerido de um lote de produção (ex: 200 = uma fornada típica).
  /// Usado como sugestão no `RegistrarProducaoDialog`.
  IntColumn get quantidadeProducaoLote =>
      integer().withDefault(const Constant(100))();

  /// Quantos dias de cobertura o produtor quer manter como alvo.
  /// Usado no planejamento preditivo: "Se o ritmo diário é X, preciso de diasCoberturaAlvo * X unidades disponíveis."
  IntColumn get diasCoberturaAlvo =>
      integer().withDefault(const Constant(3))();

  /// Unidade de medida: 'un' | 'kg' | 'L' | 'g' | 'mL'
  TextColumn get unidade => text().withDefault(const Constant('un'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Movimentações de Estoque — Histórico Imutável
///
/// Cada produção, venda, reserva, cancelamento e ajuste gera uma linha aqui.
/// O saldo em `EstoqueProdutosTable` é sempre recalculável a partir desta tabela.
///
/// ## Tipos de Movimentação
/// | Tipo | Afeta | Direção | Descrição |
/// |------|-------|---------|-----------|
/// | `producao` | `quantidadeAtual` | +n | Registro de produção diária |
/// | `reserva` | `quantidadeReservada` | +n | Pedido futuro confirmado |
/// | `liberacao_reserva` | `quantidadeReservada` | -n | Reserva cancelada |
/// | `expedicao` | `quantidadeAtual` + `quantidadeReservada` | -n cada | Entrega realizada |
/// | `ajuste_positivo` | `quantidadeAtual` | +n | Correção manual positiva (motivo obrigatório) |
/// | `ajuste_negativo` | `quantidadeAtual` | -n | Perda/descarte (motivo obrigatório) |
/// | `inventario` | `quantidadeAtual` | =n | Recontagem — redefine o saldo absoluto |
/// | `entrada` | `quantidadeAtual` | +n | Entrada genérica (retrocompatibilidade) |
/// | `saida` | `quantidadeAtual` | -n | Saída genérica (retrocompatibilidade) |
/// | `cancelamento` | `quantidadeAtual` | +n | Estorno de venda cancelada |
@DataClassName('MovimentacaoEstoqueData')
@TableIndex(
    name: 'mov_estoque_produto_idx', columns: {#tenantId, #produtoId})
@TableIndex(
    name: 'mov_estoque_pedido_idx', columns: {#tenantId, #pedidoId})
@TableIndex(
    name: 'mov_estoque_data_hora_idx', columns: {#tenantId, #dataHora})
class MovimentacoesEstoqueTable extends Table
    with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get produtoId => text()();

  /// Pedido associado (nullable — produções e ajustes não têm pedido)
  TextColumn get pedidoId => text().nullable()();

  /// Tipo de movimentação (ver tabela de tipos no comentário da classe)
  TextColumn get tipo => text()();

  /// Quantidade movimentada (sempre positivo — o tipo define a direção)
  IntColumn get quantidade => integer()();

  /// Snapshot de `quantidadeAtual` ANTES desta movimentação
  IntColumn get quantidadeAntes => integer()();

  /// Snapshot de `quantidadeAtual` APÓS esta movimentação
  IntColumn get quantidadeDepois => integer()();

  /// Snapshot de `quantidadeReservada` ANTES desta movimentação (null para tipos sem reserva)
  IntColumn get quantidadeReservadaAntes => integer().nullable()();

  /// Snapshot de `quantidadeReservada` APÓS esta movimentação (null para tipos sem reserva)
  IntColumn get quantidadeReservadaDepois => integer().nullable()();

  /// Motivo/descrição legível.
  /// OBRIGATÓRIO para: ajuste_positivo, ajuste_negativo, inventario, producao.
  TextColumn get motivo => text().withDefault(const Constant(''))();

  /// UUID do operador que gerou a movimentação
  TextColumn get operadorId => text().nullable()();

  /// Data e hora exata da movimentação (UTC)
  DateTimeColumn get dataHora => dateTime()();

  /// Data prevista de entrega (para tipo 'reserva' — permite relatório preditivo)
  DateTimeColumn get dataEntregaPrevista => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

