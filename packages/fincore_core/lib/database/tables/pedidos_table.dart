import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

/// Tabela de Pedidos — gerados pelo PDV Express, PDV Balcão e Canal Delivery.
///
/// ## Decisões de Design
/// - `status`: ciclo de vida do pedido (rascunho → confirmado → em_preparo → pronto → entregue → cancelado)
/// - `tipoLogistica`: 'Entrega' ou 'Retirada' (ou 'Mesa/Balcão' no modo comanda)
/// - `formaPagamentoId`: referência ao ID da FormasPagamentoTable (não FK para evitar deleção em cascata)
/// - `operadorId`: UUID do usuário que criou o pedido (não FK para evitar join obrigatório)
/// - Valores monetários em CENTAVOS (integer) para evitar erros de ponto flutuante
/// - `itensJson`: snapshot serializado dos itens (Text JSON) — os itens reais ficam em ItensPedidoTable
///
/// Esta tabela é o ÚNICO registro persistente de vendas locais. O Outbox enfileira o
/// pedido para sincronização ao Supabase. O Módulo Financeiro lê desta tabela.
@DataClassName('PedidoData')
@TableIndex(name: 'pedido_tenant_status_idx', columns: {#tenantId, #status})
@TableIndex(name: 'pedido_tenant_data_idx', columns: {#tenantId, #dataHoraCriacao})
@TableIndex(name: 'pedido_tenant_cliente_idx', columns: {#tenantId, #clienteId})
class PedidosTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  /// Status do ciclo de vida: rascunho | confirmado | em_preparo | pronto | entregue | cancelado
  TextColumn get status => text().withDefault(const Constant('confirmado'))();

  /// Tipo de logística: 'Entrega' | 'Retirada' | 'Mesa/Balcão'
  TextColumn get tipoLogistica => text()();

  /// ID do cliente (nullable — vendas rápidas podem não ter cliente cadastrado)
  TextColumn get clienteId => text().nullable()();

  /// Nome do cliente digitado na hora (para vendas sem cliente cadastrado)
  TextColumn get clienteNomeAvulso => text().nullable()();

  /// Telefone do cliente digitado na hora
  TextColumn get clienteTelefoneAvulso => text().nullable()();

  /// Subtotal dos itens em centavos (sem taxa de entrega)
  IntColumn get valorSubtotalCentavos => integer()();

  /// Taxa de entrega em centavos (0 para Retirada/Balcão)
  IntColumn get valorTaxaEntregaCentavos => integer().withDefault(const Constant(0))();

  /// Total final = subtotal + taxa de entrega
  IntColumn get valorTotalCentavos => integer()();

  /// Troco solicitado em centavos (nullable — apenas para pagamento em dinheiro)
  IntColumn get trocoParaCentavos => integer().nullable()();

  /// ID (UUID) da forma de pagamento selecionada (referência fraca — não FK)
  TextColumn get formaPagamentoId => text().nullable()();

  /// Nome da forma de pagamento no momento da venda (snapshot — evita join)
  TextColumn get formaPagamentoNome => text().nullable()();

  /// Endereço de entrega serializado em JSON (snapshot do momento da venda)
  TextColumn get enderecoJson => text().nullable()();

  /// UUID do operador que finalizou a venda
  TextColumn get operadorId => text().nullable()();

  /// Data e hora de criação do pedido (timezone local convertida para UTC)
  DateTimeColumn get dataHoraCriacao => dateTime()();

  /// Número sequencial amigável do pedido (ex: #142) — gerado localmente
  IntColumn get numeroPedido => integer().nullable()();

  /// Observações gerais do pedido
  TextColumn get observacoes => text().nullable()();

  /// Canal de origem: 'pdv_express' | 'pdv_balcao' | 'delivery' | 'manual'
  TextColumn get canalOrigem => text().withDefault(const Constant('pdv_express'))();

  /// Data e hora prevista de entrega ou retirada (null para pedidos imediatos).
  /// Preenchida pelo PDV Express quando isEntregaAgendada == true.
  /// Usada para: cálculo de demanda futura, horário de início recomendado
  /// na cozinha e janela de produção no planejamento.
  DateTimeColumn get dataHoraEntregaPrevista => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Itens do Pedido — um registro por linha de produto no carrinho.
///
/// Armazena o snapshot completo do item no momento da venda (nome, preço unitário, total).
/// Isso garante imutabilidade histórica mesmo se o produto for editado ou excluído depois.
@DataClassName('ItemPedidoData')
@TableIndex(name: 'item_pedido_pedido_idx', columns: {#pedidoId})
@TableIndex(name: 'item_pedido_tenant_idx', columns: {#tenantId, #pedidoId})
class ItensPedidoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  /// UUID do pedido pai
  TextColumn get pedidoId => text()();

  /// UUID do produto (referência fraca — snapshot do nome abaixo garante histórico)
  TextColumn get produtoId => text()();

  /// Snapshot do nome do produto no momento da venda
  TextColumn get nomeProduto => text()();

  /// Quantidade (armazenada como real para suportar frações como 0.5 kg)
  RealColumn get quantidade => real()();

  /// Preço unitário em centavos no momento da venda (após resolução da tabela de preços)
  IntColumn get valorUnitarioCentavos => integer()();

  /// Total do item em centavos = quantidade × valorUnitarioCentavos
  IntColumn get valorTotalCentavos => integer()();

  /// Observações específicas do item (ex: "sem cebola")
  TextColumn get observacoes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
