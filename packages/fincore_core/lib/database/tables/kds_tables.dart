import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'produtos_table.dart';

/// Tabela de Ordens de Preparo — KDS (Kitchen Display System)
///
/// Registra cada lote de produção que a cozinha deve preparar.
/// O status segue a máquina de estados: pendente → em_preparo → pronto → entregue → cancelado
@DataClassName('OrdemPreparoData')
class OrdensPreparoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get pedidoId => text()(); // Referência ao ID do Pedido na OutboxSync

  // Itens serializados como JSON [{"produtoId": "x", "nome": "y", "quantidade": 10}]
  TextColumn get itensJson => text()();

  TextColumn get status => text()(); // pendente | em_preparo | pronto | entregue | cancelado
  TextColumn get prioridade => text()(); // normal | urgente | vip | programado

  // Operador responsável pelo preparo
  TextColumn get operadorId => text().nullable()();

  // Timing de controle (RFC 3339)
  DateTimeColumn get criadaEm      => dateTime()();
  DateTimeColumn get iniciadaEm    => dateTime().nullable()();
  DateTimeColumn get concluidaEm   => dateTime().nullable()();
  DateTimeColumn get canceladaEm   => dateTime().nullable()();

  // Tempo estimado total de preparo (em segundos)
  IntColumn get tempoEstimadoSegundos => integer().withDefault(const Constant(0))();

  TextColumn get observacoes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Lotes de Insumos — Controle FIFO/LIFO
///
/// Cada lote representa uma entrada de insumo na cozinha com data de validade.
/// O algoritmo LIFO de estorno (EstornarLoteEstoqueUseCase) devolve ao lote
/// mais recente ativo para preservar a validade FIFO dos lotes antigos.
@DataClassName('LoteInsumoData')
class LotesInsumoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get produtoId => text().references(
        ProdutosTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();

  // Código do lote para rastreabilidade (ex: "LOT-20260725-001")
  TextColumn get codigoLote => text().nullable()();

  // Quantidade em estoque (centésimos para precisão — ex: 1000 = 10.00 unidades)
  IntColumn get quantidadeInicial   => integer()();
  IntColumn get quantidadeDisponivel => integer()();
  IntColumn get quantidadeReservada  => integer().withDefault(const Constant(0))();

  TextColumn get unidade => text()(); // Mapeado de UnidadeVenda

  // Datas de validade e entrada
  DateTimeColumn get dataValidade  => dateTime().nullable()();
  DateTimeColumn get dataEntrada   => dateTime()();

  // Status: ativo | zerado | vencido | cancelado
  TextColumn get statusLote => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Histórico/Linha do Tempo Operacional das Ordens de Preparo (Lifecycle)
@DataClassName('HistoricoOrdemPreparoData')
class HistoricosOrdemPreparoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get ordemPreparoId => text().references(
        OrdensPreparoTable,
        #id,
        onDelete: KeyAction.cascade,
        onUpdate: KeyAction.cascade,
      )();

  TextColumn get titulo => text()(); // "Status alterado", "PIX Confirmado", "Pedido criado"
  TextColumn get descricao => text()(); // "Passou de Pendente para Em Preparo"
  TextColumn get operadorNome => text().withDefault(const Constant('Operador'))();
  DateTimeColumn get criadaEm => dateTime()();
  TextColumn get versao => text().withDefault(const Constant('v1'))();

  @override
  Set<Column> get primaryKey => {id};
}
