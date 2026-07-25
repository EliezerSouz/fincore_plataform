# Métricas do Produto (Product Metrics)

> **Document ID**: 104  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> O produto é guiado por resultados, não por funcionalidades. Toda feature deve mover pelo menos uma métrica listada aqui.

---

## Métricas Operacionais

### ① Comercial — Receber Pedidos

| Métrica | Definição | Meta | Como Medir |
|---|---|---|---|
| **Tempo médio de venda** | Segundos entre abrir o PDV e confirmar o pedido | < 15s (Express) / < 60s (Completo) | Telemetria local (`criadoEm` - `inicioAtendimento`) |
| **Pedidos por hora** | Throughput do atendente | > 20/h no Express | Contagem por operador/hora |
| **Taxa de erro em pedidos** | Pedidos editados ou cancelados após criação | < 3% | `EventosPedido` tipo EDITADO ou CANCELAMENTO / total |
| **Taxa de conversão de orçamento** | Orçamentos que viram pedidos confirmados | > 70% | Status orçamento → confirmado |

### ② Produção — Planejar e Produzir

| Métrica | Definição | Meta | Como Medir |
|---|---|---|---|
| **Pedidos atrasados** | Pedidos que passaram da `dataEntrega` sem sair | < 2% | Status != Entregue/Finalizado quando `now > dataEntrega` |
| **Acurácia do MRP** | Sugestão de lote vs. produção real necessária | > 85% | Comparativo sugestão vs. consumo em 7 dias |
| **Desperdício** | Lotes vencidos / lotes produzidos | < 5% | Lotes com `quantidadeSaldo > 0` após validade |

### ③ Estoque

| Métrica | Definição | Meta | Como Medir |
|---|---|---|---|
| **Divergências FIFO** | Baixas fora de ordem cronológica | 0 | Auditoria automática de movimentações |
| **Rupturas de estoque** | Vezes que estoque = 0 com pedidos pendentes | < 1/semana | Alerta de estoque crítico acionado |
| **Giro de estoque** | Saídas / saldo médio por produto por mês | Depende do produto | Relatório mensal |

### ④ Cliente — Fidelizar

| Métrica | Definição | Meta | Como Medir |
|---|---|---|---|
| **Taxa de recompra** | Clientes que fazem > 1 pedido em 30 dias | > 40% | Contagem de clientes recorrentes |
| **Tempo médio de resposta** | Tempo entre receber pedido e confirmar ao cliente | < 30s (PDV) / < 5min (WhatsApp) | Timestamp de criação vs. notificação |
| **NPS do cliente** | Net Promoter Score (pesquisa pós-entrega) | > 50 | Pesquisa automatizada (v2.0) |

### ⑤ Financeiro

| Métrica | Definição | Meta | Como Medir |
|---|---|---|---|
| **Divergência de caixa** | Diferença entre saldo sistema e contagem física | R$ 0,00 | Fechamento de caixa diário |
| **Inadimplência** | Pedidos entregues com pagamento pendente > 7 dias | < 5% | Status financeiro = Pendente + dias |
| **Margem bruta por produto** | (Preço venda - custo produção) / preço venda | > 50% | Ficha técnica vs. preço (v1.5) |

---

## Métricas SaaS (Plataforma)

| Métrica | Definição | Meta (ano 1) | Meta (ano 3) |
|---|---|---|---|
| **MRR** | Monthly Recurring Revenue | R$ 15.000 | R$ 150.000 |
| **Churn mensal** | Empresas que cancelam / total ativo | < 5% | < 3% |
| **LTV** | Lifetime Value médio por empresa | > R$ 2.400 | > R$ 6.000 |
| **CAC** | Custo de aquisição por cliente | < R$ 200 | < R$ 300 |
| **NPS** | Net Promoter Score da plataforma | > 40 | > 60 |
| **Ativação** | % de empresas que criam o 1º pedido em < 24h | > 60% | > 80% |
| **Time-to-First-Sale** | Tempo entre cadastro e primeiro pedido real | < 30 min | < 15 min |
| **DAU/MAU** | Daily Active / Monthly Active ratio | > 50% | > 65% |

---

## Como Usar Este Documento

1. **Antes de implementar uma feature**: Identifique qual métrica ela move. Se nenhuma, questione a feature.
2. **Ao revisar um sprint**: Verifique se as entregas moveram alguma métrica positivamente.
3. **Ao priorizar o backlog**: Features que movem métricas com metas não atingidas sobem na fila.
4. **Ao medir sucesso do SaaS**: Revise mensalmente MRR, Churn, LTV e Ativação.

---

*Métricas são revisadas trimestralmente. Metas são ajustadas conforme aprendizado com clientes reais.*
