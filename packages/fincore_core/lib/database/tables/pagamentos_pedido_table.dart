import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

/// Tabela de Pagamentos do Pedido — suporta múltiplos pagamentos (Split Payment)
/// para um único pedido (ex: R$ 60,00 no Cartão + R$ 40,00 em Dinheiro).
///
/// Cada registro representa uma fatia/parcela do pagamento associada à sua respectiva
/// forma de pagamento e valor em centavos.
@DataClassName('PagamentoPedidoData')
@TableIndex(name: 'pagamento_pedido_idx', columns: {#pedidoId})
@TableIndex(name: 'pagamento_pedido_tenant_idx', columns: {#tenantId, #pedidoId})
class PagamentosPedidoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  /// UUID do pedido associado
  TextColumn get pedidoId => text()();

  /// UUID da forma de pagamento utilizada (referência fraca)
  TextColumn get formaPagamentoId => text().nullable()();

  /// Snapshot do nome da forma de pagamento no momento da transação (ex: "Dinheiro", "Cartão de Crédito", "PIX")
  TextColumn get formaPagamentoNome => text()();

  /// Valor pago nesta forma em centavos (integer)
  IntColumn get valorCentavos => integer()();

  /// Troco devolvido em centavos (aplicável principalmente para pagamentos em dinheiro)
  IntColumn get trocoCentavos => integer().withDefault(const Constant(0))();

  /// Bandeira da operadora (ex: "Mastercard", "Visa", "Elo") caso seja cartão
  TextColumn get bandeira => text().nullable()();

  /// NSU ou código de autorização da transação eletrônica
  TextColumn get nsuTransacao => text().nullable()();

  /// Observação adicional específica deste pagamento
  TextColumn get observacao => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
