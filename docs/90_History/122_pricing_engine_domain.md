---
Title: 122 pricing engine domain
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Especificação de Domínio: Pricing Engine (Motor de Precificação)

> **Document ID**: 122  
> **Version**: 1.0.0  
> **Status**: ✍️ Ativo  
>
> Este documento especifica o Pricing Engine (Motor de Precificação) da FINCORE Platform, definindo a resolução de preços, priorização de tabelas e estratégias de descontos/promoções.

---

## 🎯 1. Visão Geral e Princípios
O cálculo de preços e faixas de desconto é de responsabilidade centralizada e exclusiva do **Pricing Engine**. Nenhum outro módulo da aplicação (como PDV, KDS ou Faturamento) deve calcular preços de forma ad-hoc. 

Qualquer consulta de preço de produto deve passar pelo Pricing Engine para garantir a aplicação correta de impostos, taxas, descontos e tabelas de precificação vigentes.

---

## 🏗️ 2. Resolução de Preços e Prioridade

Como um produto pode participar de múltiplas **Tabelas de Precificação** (ex: Tabela Balcão, Tabela Delivery, Tabela Promoção), o Pricing Engine resolve o preço aplicando regras de prioridade decrescente:

```text
Produto ➔ Consultar Tabelas Associadas (N:N) ➔ Filtrar Ativas ➔ Ordenar por Prioridade (Maior valor primeiro) ➔ Avaliar Regras de Faixas ➔ Retornar Preço Calculado
```

### 2.1 Algoritmo de Resolução:
1. **Identificação do Contexto**: O canal de venda (ex: Delivery, Balcão) e a empresa (tenant) são injetados na chamada de resolução.
2. **Coleta de Tabelas**: O motor busca as tabelas de precificação associadas ao produto através da entidade intermediária `ProdutoTabelaPrecificacao`.
3. **Filtro de Atividade**: Somente tabelas com status `ativo = true` são avaliadas.
4. **Avaliação de Prioridade**: As tabelas são ordenadas pela coluna `prioridade` (ex: prioridade `100` precede prioridade `10`).
5. **Cálculo da Regra**: A política da tabela ativa (ex: `faixaQuantidade`, `unitario`) é executada contra os itens da tabela (`ItensTabelaPrecificacao`) para extrair o valor unitário final em centavos.

---

## 🧩 3. Taxonomia de Políticas de Precificação (PricingPolicyType)

O motor suporta nativamente as seguintes políticas lógicas:
- `unitario`: Preço unitário fixo sem variação por volume.
- `faixaQuantidade`: Descontos progressivos escalonados por faixas (ex: de 1 a 24 itens ➔ R$ 2,00; acima de 25 ➔ R$ 1,80).
- `fracionado`: Venda fracionada por partes ou fatias.
- `peso`: Cálculo proporcional baseado em peso/balança (kg).
- `cento`: Venda por lotes de 100 unidades.
- `combo`: Preços promocionais especiais ao agrupar múltiplos produtos.
- `promocional`: Desconto por período temporal ou datas sazonais específicas.
