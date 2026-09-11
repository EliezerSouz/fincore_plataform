import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'produtos_table.dart';

/// Tabela de Planejamento de Produção — intenção formal de produzir N unidades.
///
/// ## Conceito
/// Representa a decisão do planejador/admin de produzir determinado produto
/// em determinada data. NÃO é criado automaticamente — sempre requer ação humana.
///
/// ## Ciclo de vida (coluna [status])
/// ```
/// planejada → em_preparacao → em_producao → concluida
///                  ↓               ↓
///              cancelada       parcial → concluida
/// ```
///
/// ## Integração com Estoque
/// Ao concluir o plano ([status] = 'concluida'), o controller gera automaticamente
/// uma movimentação de estoque do tipo 'producao' com referência ao [id] deste plano,
/// incrementando [quantidadeAtual] em [EstoqueProdutosTable].
///
/// ## Offline-First
/// Sincronizado via Outbox → Supabase. Idempotente via UUID.
@DataClassName('PlanoProducaoData')
@TableIndex(name: 'plano_producao_tenant_idx', columns: {#tenantId, #produtoId})
@TableIndex(name: 'plano_producao_data_idx', columns: {#tenantId, #dataPlano})
@TableIndex(name: 'plano_producao_status_idx', columns: {#tenantId, #status})
class PlanejamentoProducaoTable extends Table
    with IdentityColumns, AuditColumns, SyncColumns {
  /// Produto que será produzido nesta campanha.
  TextColumn get produtoId => text().references(
        ProdutosTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();

  /// Data em que a produção será executada (data da campanha).
  /// Armazenada em UTC — exibida no fuso local.
  DateTimeColumn get dataPlano => dateTime()();

  /// Quantidade que o planejador pretende produzir.
  IntColumn get quantidadePlanejada => integer()();

  /// Quantidade efetivamente produzida (0 até conclusão).
  IntColumn get quantidadeProduzida => integer().withDefault(const Constant(0))();

  /// Capacidade de referência de campanha (copiada do parâmetro do produto no momento do plano).
  /// Usado apenas como referência visual — não é um limite hard.
  IntColumn get capacidadeCampanha => integer().withDefault(const Constant(0))();

  /// Status do ciclo de vida:
  /// 'planejada' | 'em_preparacao' | 'em_producao' | 'parcial' | 'concluida' | 'cancelada'
  TextColumn get status =>
      text().withDefault(const Constant('planejada'))();

  /// Motivo de cancelamento (obrigatório quando status == 'cancelada').
  TextColumn get motivoCancelamento => text().nullable()();

  /// Observações livres do planejador.
  TextColumn get observacoes => text().nullable()();

  /// UUID do operador que criou/última ação no plano.
  TextColumn get operadorId => text().nullable()();

  /// ID da necessidade que deu origem a este plano (opcional).
  TextColumn get necessidadeOrigem => text().nullable().named('necessidade_origem')();

  @override
  Set<Column> get primaryKey => {id};
}
