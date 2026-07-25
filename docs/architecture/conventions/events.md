# CONVENÇÕES DE EVENTOS DE DOMÍNIO (EVENTS CONVENTIONS) — SALGADERIA ERP

**Escopo:** Padronização de nomes, estrutura de payload e rastreabilidade para a Arquitetura Orientada a Eventos.

---

## 1. NOMENCLATURA DE EVENTOS DE DOMÍNIO

Todos os eventos representam fatos passados imutáveis que já ocorreram na aplicação. O nome deve estar obrigatoriamente no **passado do verbo** (`[Entidade][AcaoNoPassado]`):

### Exemplos Nativos do Ecossistema:
*   `PedidoCriado`
*   `PedidoCancelado`
*   `PedidoEntregue`
*   `ReservaCriada`
*   `ReservaLiberada`
*   `LoteProduzido`
*   `EstoqueMinimoAtingido`
*   `BriefingGerado`

---

## 2. ESTRUTURA PADRÃO DO PAYLOAD DE EVENTO & CORRELATION ID

Todo evento gerado herda de `DomainEvent` no pacote `salgaderia_shared`. O campo `correlationId` é **mandatório** para permitir o rastreamento (tracing) de uma cadeia completa de eventos originada por uma mesma ação:

```dart
abstract class DomainEvent {
  final String eventId;       // UUID único do evento individual
  final String correlationId; // UUID de correlação da transação original (Trace ID)
  final String tenantId;      // UUID da empresa/tenant
  final DateTime occurredOn;  // Timestamp UTC em que o fato ocorreu
  
  DomainEvent({
    required this.eventId,
    required this.correlationId,
    required this.tenantId,
    required this.occurredOn,
  });
}

class PedidoCriadoEvent extends DomainEvent {
  final String pedidoId;
  final double valorTotal;
  final List<ItemPedidoDTO> itens;
  
  PedidoCriadoEvent({
    required super.eventId,
    required super.correlationId,
    required super.tenantId,
    required super.occurredOn,
    required this.pedidoId,
    required this.valorTotal,
    required this.itens,
  });
}
```

### Exemplo de Rastreabilidade via `correlationId`:
```text
[Ação do Usuário: Confirmar Pedido] (Gera correlationId: "trace-abc-123")
  ├── PedidoCriado (correlationId: "trace-abc-123")
  ├── ReservaCriada (correlationId: "trace-abc-123")
  ├── AgendaAtualizada (correlationId: "trace-abc-123")
  └── NotificacaoEnviada (correlationId: "trace-abc-123")
```

---

## 3. REGRAS DE DISPARO DE EVENTOS

1.  **Imutabilidade:** Eventos disparados nunca podem ser alterados ou cancelados.
2.  **Publicação no Service:** Somente a camada de `Domain Service` pode disparar eventos após a persistência ter sido confirmada no banco de dados.
3.  **Preservação do Correlation ID:** Qualquer evento filho gerado em reação a um evento pai DEVE repassar o mesmo `correlationId`.

---

*Convenções aprovadas para o ecossistema Salgaderia ERP.*
