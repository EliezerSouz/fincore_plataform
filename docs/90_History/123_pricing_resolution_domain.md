---
Title: 123 pricing resolution domain
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Especificação de Domínio: Resolução de Conflitos de Precificação (Pricing Resolution)

> **Document ID**: 123  
> **Version**: 1.1.0  
> **Status**: ✍️ Ativo  
>
> Este documento especifica o algoritmo de desempate e resolução de conflitos de preços quando um produto se enquadrar em múltiplas tabelas vigentes simultaneamente.

---

## 🎯 1. Visão Geral
Com o suporte a relacionamentos N:N, um mesmo produto (ex: Mini Coxinha) pode estar ativo em várias Tabelas de Precificação ativas (ex: Tabela Geral, Tabela Delivery, Tabela Black Friday, Tabela Cliente VIP). Este documento formaliza as regras de precedência.

---

## ⚖️ 2. Algoritmo de Resolução e Precedência

O `PricingEngine` resolverá as consultas de preços aplicando estritamente as regras de desempate na seguinte ordem sequencial:

```text
1. Verificar Vigência (dataInicio e dataFim)
               │
               ▼
2. Descartar tabelas/vínculos inativos
               │
               ▼
3. Filtrar pelo Canal de Venda (ex: Delivery, Balcão)
               │
               ▼
4. Filtrar pelo Grupo do Cliente (ex: VIP, Atacado)
               │
               ▼
5. Selecionar Maior Prioridade (Tabela ou Vínculo)
               │
               ▼
6. Selecionar Menor Ordem (Itens da Tabela)
               │
               ▼
7. Aplicar item de precificação da faixa correspondente
               │
               ▼
8. Retornar Preço Resultante em Centavos
```

### Detalhamento das Regras:
1. **Verificação de Vigência**: Se a data e hora atual do sistema estiver fora do intervalo especificado em `dataInicio` ou `dataFim` no mapeamento associativo do produto, a tabela correspondente é descartada.
2. **Descarte de Inativos**: Exclui tabelas ou vínculos onde `ativo = false`.
3. **Filtro de Canal**: Se houver tabelas específicas associadas ao canal do pedido (ex: Tabela iFood), elas eliminam tabelas gerais.
4. **Filtro de Cliente**: Tabelas associadas a perfis específicos do cliente do pedido (ex: Tabela Revenda) eliminam tabelas gerais de varejo.
5. **Prioridade**: Caso restem múltiplas tabelas, escolhe-se aquela com maior número na coluna `prioridade`.
6. **Ordem**: Dentro da tabela escolhida, avalia os itens de precificação ordenados pelo campo `ordem` para evitar empates de faixas de volume.
7. **Aplicação de Faixa**: Retorna o preço da faixa na qual a quantidade do item no carrinho se enquadre.
