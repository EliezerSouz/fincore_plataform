---
Title: 124 seed data
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Especificação de Domínio: Massa de Dados Inicial (Seed Data)

> **Document ID**: 124  
> **Version**: 1.0.0  
> **Status**: ✍️ Ativo  
>
> Este documento especifica a massa de dados padrão (seeds) para inicialização da FINCORE Platform, garantindo consistência ambiental e de testes.

---

## 🎯 1. Objetivo
Fornecer um ambiente pré-configurado funcional no primeiro boot (ou em ambientes de testes e desenvolvimento), permitindo que um operador consiga abrir o aplicativo, selecionar um cliente padrão e efetuar uma venda sem necessidade de cadastros manuais prévios.

---

## 📂 2. Massa de Dados Padrão (Seeds)

### 2.1 Empresa Demo (Tenant Principal)
- `id`: 'tenant-demo-001'
- `razaoSocial`: 'FINCORE Food Demo LTDA'
- `nomeFantasia`: 'FINCORE Food Demo'
- `documentoFiscal`: '00.000.000/0001-00'
- `email`: 'demo@fincore.com'
- `telefone`: '11999999999'
- `status`: `ativo`
- `plano`: `ouro`
- `timezone`: 'America/Sao_Paulo'
- `locale`: 'pt_BR'
- `currency`: 'BRL'
- `country`: 'BR'
- `createdFrom`: 'Web'
- `version`: 1

### 2.2 Usuário Administrador
- `id`: 'user-demo-admin'
- `tenantId`: 'tenant-demo-001'
- `nome`: 'Administrador Demo'
- `email`: 'admin@fincore.com'
- `perfil`: `administrador`
- `permissoes`: ['all']
- `ativo`: true

### 2.3 Categorias Padrão
1. **Salgados Fritos**
   - `id`: 'cat-salgados-fritos'
   - `ordemExibicao`: 1
2. **Salgados Assados**
   - `id`: 'cat-salgados-assados'
   - `ordemExibicao`: 2
3. **Bebidas**
   - `id`: 'cat-bebidas'
   - `ordemExibicao`: 3

### 2.4 Tabelas de Precificação Padrão
1. **Tabela Geral**
   - `id`: 'tabela-geral'
   - `tipoPolitica`: `faixaQuantidade`
   - `prioridade`: 10
2. **Tabela Bebidas**
   - `id`: 'tabela-bebidas'
   - `tipoPolitica`: `unitario`
   - `prioridade`: 5

### 2.5 Itens da Tabela (Regras de Faixas)
- **Tabela Geral (Salgados)**:
  - Faixa 1: Mínima 1, Máxima 24 ➔ Valor R$ 2,00 (200 centavos)
  - Faixa 2: Mínima 25, Máxima 49 ➔ Valor R$ 1,80 (180 centavos)
  - Faixa 3: Mínima 50, Máxima 99 ➔ Valor R$ 1,60 (160 centavos)
  - Faixa 4: Mínima 100, Máxima null ➔ Valor R$ 1,40 (140 centavos)
- **Tabela Bebidas**:
  - Faixa 1: Mínima 1, Máxima null ➔ Valor R$ 6,00 (600 centavos)

### 2.6 Produtos de Exemplo
1. **Mini Coxinha**
   - `id`: 'prod-mini-coxinha'
   - `categoriaId`: 'cat-salgados-fritos'
   - `unidadeVenda`: `un`
   - `statusComercial`: `disponivel`
2. **Mini Kibe**
   - `id`: 'prod-mini-kibe'
   - `categoriaId`: 'cat-salgados-fritos'
   - `unidadeVenda`: `un`
   - `statusComercial`: `disponivel`
3. **Coca-Cola Lata**
   - `id`: 'prod-coca-cola'
   - `categoriaId`: 'cat-bebidas'
   - `unidadeVenda`: `un`
   - `statusComercial`: `disponivel`

*Nota: Os produtos são vinculados às respectivas tabelas via entidade intermediária `ProdutoTabelaPrecificacao` (Mini Coxinha e Mini Kibe ➔ Tabela Geral; Coca-Cola ➔ Tabela Bebidas).*

### 2.7 Cliente Balcão (Cliente Padrão)
- `id`: 'cliente-balcao-001'
- `nome`: 'Cliente Consumidor (Balcão)'
- `telefone`: '00000000000'
- `ativo`: true
