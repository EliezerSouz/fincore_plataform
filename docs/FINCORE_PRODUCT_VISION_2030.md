# Visão de Produto 2030 (FINCORE PRODUCT VISION 2030)

Este documento define as diretrizes estratégicas comerciais, a proposta de valor e a arquitetura funcional de motores (Engines) do **FINCORE PLATFORM** de longo prazo.

---

## 🌟 Estrela Guia (The North Star)

> **"Automatizar toda a operação de empresas alimentícias, da venda à entrega, com inteligência operacional, rastreabilidade completa e uma experiência simples para o usuário."**

Qualquer funcionalidade ou evolução arquitetural de produto deve ser avaliada frente a esta premissa: *esta alteração nos aproxima ou nos afasta da nossa North Star?*

---

## 🎯 Quem é o Nosso Cliente?

### Hoje (Alvo Imediato)
- Salgaderias, Docerias, Confeitarias e Padarias tradicionais que sofrem com gargalos de produção física diária, sincronização de pedidos de balcão/delivery, e controle de validade de insumos perecíveis.

### Amanhã (Escala 2030)
- Indústrias alimentícias de médio porte, distribuidoras de alimentos resfriados/congelados, Buffets corporativos e redes estruturadas de Food Service (Franquias).

---

## 💎 Proposta de Valor (Value Proposition)

Por que um cliente de alimentação escolhe o **FINCORE** em vez de concorrentes genéricos como Bling, Tiny, Omie ou SAP/TOTVS?

1. **Inteligência de Produção Alimentícia**: Ao contrário de ERPs tradicionais (que apenas registram entradas e saídas financeiras), o FINCORE planeja a produção com base em receitas, perdas reais e lote de insumos (MRP integrado de fábrica).
2. **Resiliência Offline (Offline-First)**: Em locais de processamento de alimentos, cozinhas de subsolo ou quiosques com internet instável, o PDV e o KDS continuam trabalhando sem interrupções.
3. **Auditoria Forense Nativa**: Rastreabilidade completa de todas as pesagens, alterações de preços por funcionários, devoluções e descarte de lote com diff histórico.
4. **Política Comercial Avançada (Commercial Pricing Engine)**: Motor de precificação inteligente capaz de lidar com tabelas de atacado, varejo, acordos comerciais por parceiro de forma dinâmica.

---

## ⚙️ O Padrão de Motores Funcionais (Engine Pattern)

Para evitar a fragmentação de regras de negócio em controllers ou telas da aplicação, o FINCORE adota o **Engine Pattern**: toda lógica complexa de negócios deve residir exclusivamente em classes isoladas e independentes do framework (Engines).

### 🛠️ Mapa de Engines da Plataforma

```text
[ ERP App / PDV App / KDS App ]
               │
               ▼  (Consome)
[ Fincore Internal SDK & Contracts ]
               │
               ▼  (Dispara)
     ┌───────────────────┼───────────────────┐
     ▼                   ▼                   ▼
[Pricing Engine]  [Production Engine] [Inventory Engine]  ...
```

- **Platform Engine**: Gerencia injeção de dependência e ciclo de vida local. (🟢 Stable)
- **Theme Engine**: Controla tokens visuais em tempo de execução. (🟢 Stable)
- **Audit Engine**: Gera logs e diffs forenses em formato JSON. (🟢 Stable)
- **Sync Engine**: Efetua a ordenação topológica de outbox e envio Supabase. (🟢 Stable)
- **Commercial Pricing Engine**: Calcula políticas comerciais e preços em lote. (🟡 Preview)
- **Production Planning Engine (MRP)**: Planeja requisições de receitas e rendimentos físicos. (🔴 Planned)
- **Inventory Engine**: Executa controle FIFO e reserva de estoques por comandas. (🔴 Planned)
- **CRM Engine**: Fornece recomendações operacionais e históricos de consumo. (🔴 Planned)
- **Delivery Engine**: Consolida tarifas e rotas para despacho de mercadorias. (🔴 Planned)
- **Financial Health Engine**: Emite relatórios DRE locais offline. (🔴 Planned)

---

## 📈 Princípios de Produto (Product Principles)
- **Operação Acima do Registro**: O FINCORE nunca é um simples repositório de dados ou CRUD de cadastros; ele reflete e atua sobre o fluxo produtivo real de alimentos.
- **Transparência e Simplicidade**: Interfaces sofisticadas e robustas no core, mas extremamente fáceis de operar em ambientes de cozinha e balcão sob alta pressão.
- **Privacidade e Governança**: Garantia de isolamento rigoroso de informações comerciais entre tenants com segurança de dados de ponta a ponta.
