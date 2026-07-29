---
Title: Pricing and Product Domain
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Especificação de Domínio: Produtos e Tabelas de Precificação

> **Document ID**: 121  
> **Version**: 1.3.0  
> **Status**: ✍️ Ativo  
>
> Este documento especifica o domínio de Produtos, Categorias e a estrutura de Tabelas de Precificação da FINCORE Platform, integrando as regras de herança e modelagem de associações N:N.

---

## 🎯 1. Objetivo e Visão Geral
Visando mitigar o custo operacional de manutenção de preços em larga escala, a FINCORE Platform adota o desacoplamento de preços através de **Tabelas de Precificação**.

Os produtos são associados de forma N:N a Tabelas de Precificação. Isso permite que um mesmo produto pertença a diferentes tabelas simultaneamente (ex: Tabela Balcão, Tabela Delivery, Tabela Promoção), cabendo ao **Pricing Engine** resolve o valor aplicável conforme prioridades e canais.

```text
Mini Coxinha ──┐
Mini Risole  ──┼─➔ ProdutoTabelaPrecificacao ─➔ Tabela: Mini Salgados ➔ Itens de Precificação
Mini Kibe    ──┘
```

---

## 🏗️ 2. Entidades de Domínio

### 2.1 Categoria
Organiza os produtos em agrupamentos lógicos de exibição e controle, com suporte nativo a hierarquia recursiva.
- `id` (TextUUID)
- `tenantId` (TextUUID)
- `parentId` (TextUUID, Nullable / References Categoria) - ID da categoria pai.
- `nome` (String, ex: 'Salgados Fritos')
- `descricao` (String)
- `ordemExibicao` (Int)
- `ativo` (Bool)
- `metadata` (SyncMetadata)

### 2.2 Tabela de Precificação (TabelaPrecificacao)
Define a política de precificação adotada para um conjunto de produtos.
- `id` (TextUUID)
- `tenantId` (TextUUID)
- `nome` (String, ex: 'Mini Salgados Tradicionais')
- `descricao` (String)
- `tipoPolitica` (Enum: `PricingPolicyType`)
- `prioridade` (Int: prioridade de resolução do motor)
- `ativo` (Bool)
- `metadata` (SyncMetadata)

### 2.3 Item da Tabela de Precificação (ItemTabelaPrecificacao)
Define os valores e intervalos de aplicação de preços baseados na política da tabela.
- `id` (TextUUID)
- `tenantId` (TextUUID)
- `tabelaPrecificacaoId` (TextUUID / References TabelaPrecificacao)
- `quantidadeMinima` (Int)
- `quantidadeMaxima` (Int, Nullable)
- `valorUnitarioCentavos` (Int)
- `ordem` (Int) - Campo para ordenação manual de faixas.
- `metadata` (SyncMetadata)

### 2.4 Produto
- `id` (TextUUID)
- `tenantId` (TextUUID)
- `codigo` (String, Nullable) - Código SKU/EAN de catálogo.
- `nome` (String, ex: 'Mini Coxinha')
- `descricao` (String, Nullable)
- `categoriaId` (TextUUID / References Categoria)
- `unidadeVenda` (Enum: `UnidadeVenda` - un, cento, kg, l, bandeja, caixa)
- `statusComercial` (Enum: `ProductStatus` - disponivel, indisponivel, descontinuado) - Separa o estado cadastral (ativo/inativo) do estado operacional (se há insumos e se está elegível à venda).
- `tempoMedioMinutos` (Int, tempo médio de preparo)
- `controlaEstoque` (Bool)
- `ordemProducao` (Int)
- `ativo` (Bool)
- `metadata` (SyncMetadata)

### 2.5 Associação Produto-Tabela (ProdutoTabelaPrecificacao)
Entidade associativa N:N mapeando quais produtos pertencem a quais tabelas, com regras de vigência e prioridades locais.
- `id` (TextUUID)
- `tenantId` (TextUUID)
- `produtoId` (TextUUID / References Produto)
- `tabelaPrecificacaoId` (TextUUID / References TabelaPrecificacao)
- `ativo` (Bool) - Se a vinculação está ativa.
- `prioridade` (Int) - Sobrecarga de prioridade para a vinculação específica.
- `dataInicio` (DateTime, Nullable) - Início da vigência do produto na tabela.
- `dataFim` (DateTime, Nullable) - Fim da vigência do produto na tabela.
- `metadata` (SyncMetadata)

---

## 🔄 3. Regras de Negócio e Precificação

1. **Alteração Centralizada**: Mutações em um único registro de `ItemTabelaPrecificacao` atualizam instantaneamente os preços de todos os produtos vinculados.
2. **Resolução por Prioridade**: Quando o `PricingEngine` recebe uma consulta para um item, ele resolve as tabelas correspondentes em que o produto está associado e aplica o preço da tabela de **maior prioridade ativa** em que o volume, canal e vigência temporal (`dataInicio` e `dataFim`) se enquadrem.
