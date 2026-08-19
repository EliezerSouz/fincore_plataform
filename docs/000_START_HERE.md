# Portal do Desenvolvedor — Comece Aqui (000_START_HERE)

> [!IMPORTANT]
> **FINCORE PLATFORM FOUNDATION V1**
> * **STATUS**: RELEASED
> * **CORE**: FROZEN
> * **DESIGN SYSTEM**: FROZEN (Bridge Ativo)
> * **GOVERNANCE**: ACTIVE
> * **NEXT PHASE**: PRODUCT ENGINEERING (Foco no Valor de Negócio)

Bem-vindo ao **FINCORE PLATFORM**. Este portal é a porta de entrada para qualquer engenheiro de software que esteja ingressando na equipe de desenvolvimento ou estendendo a plataforma. 

Nossa arquitetura visual e de infraestrutura de dados foi consolidada e congelada sob a versão **Platform Foundation V1 (Architecture Frozen)**.

---

## 🏆 Regra de Ouro da Documentação
Para evitar que a governança se torne um gargalo burocrático, cada documento listado abaixo deve responder de forma objetiva a uma pergunta operacional essencial:
- **ADR** responde: *Por que esta decisão estrutural de design foi tomada?*
- **RFC** responde: *Quais os impactos e justificativas para propor esta mudança?*
- **Registry** responde: *Este componente já existe homologado na biblioteca?*
- **Quality Gate** responde: *Este Pull Request atende aos requisitos mínimos de aceitação?*
- **Roadmap** responde: *Para qual direção o ecossistema está evoluindo?*

Se um documento deixar de responder a uma pergunta operacional importante de engenharia, ele deve ser simplificado ou descontinuado.

---

## 🧭 Trilha de Leitura Recomendada (Onboarding)

Para entender a arquitetura, as regras de conformidade e o funcionamento do core em uma única tarde, leia os documentos na seguinte sequência:

```text
    1. Manifesto & Congelamento            2. Princípios & Qualidade            3. Guias Práticos & Decisões
┌─────────────────────────────────┐      ┌─────────────────────────────┐      ┌──────────────────────────────┐
│  PLATFORM_FOUNDATION_V1.md      │ ───> │  PLATFORM_PRINCIPLES.md     │ ───> │  MIGRATION_PLAN.md           │
│  (Entenda o Marco e o Core)     │      │  (Os 10 Mandamentos do Core)│      │  (Como migrar telas legadas) │
└─────────────────────────────────┘      └─────────────────────────────┘      └──────────────────────────────┘
                │                                       │                                     │
                ▼                                       ▼                                     ▼
┌─────────────────────────────────┐      ┌─────────────────────────────┐      ┌──────────────────────────────┐
│  CORE_FREEZE.md                 │      │  QUALITY_GATE.md            │      │  ADR_INDEX.md                │
│  (Processo de RFC e Manutenção) │      │  (Checklist de PR de UI)    │      │  (Índice de Decisões de ADR) │
└─────────────────────────────────┘      └─────────────────────────────┘      └──────────────────────────────┘
                │                                       │                                     │
                ▼                                       ▼                                     ▼
┌─────────────────────────────────┐      ┌─────────────────────────────┐      ┌──────────────────────────────┐
│  ARCHITECTURE_REPORT.md         │      │  DESIGN_SYSTEM_STATUS.md    │      │  COMPONENT_REGISTRY.md       │
│  (Auditorias e Nota de Saúde)   │      │  (Estado de Conformidade UI)│      │  (Catálogo de Componentes)   │
└─────────────────────────────────┘      └─────────────────────────────┘      └──────────────────────────────┘
```

---

## 📚 Índice Completo de Documentação

### 🏛️ 1. Governança, Manifesto e Visão
- **[FINCORE_PRODUCT_VISION_2030.md](file:///f:/Eigent/fincore_platform/docs/FINCORE_PRODUCT_VISION_2030.md)**: A estrela guia do negócio (North Star), proposta de valor comercial, e a arquitetura Engine Pattern.
- **[PLATFORM_FOUNDATION_V1.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/PLATFORM_FOUNDATION_V1.md)**: Formalização do encerramento do Sprint 0 e declaração do estado de Core Frozen.
- **[CORE_FREEZE.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/CORE_FREEZE.md)**: Manual operacional do processo de controle de alterações sob RFC e ADR.
- **[PLATFORM_PRINCIPLES.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/PLATFORM_PRINCIPLES.md)**: Os 10 princípios estruturais da engenharia da plataforma.

### 🛡️ 2. Auditorias, Qualidade e Débitos
- **[ARCHITECTURE_REPORT.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/ARCHITECTURE_REPORT.md)**: Relatório geral de auditoria e nota de integridade da arquitetura (9.5/10).
- **[TECH_DEBT.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/TECH_DEBT.md)**: Inventário priorizado de correção de débitos técnicos.
- **[QUALITY_GATE.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/QUALITY_GATE.md)**: Regras obrigatórias de homologação para aceitação de novas interfaces em Pull Requests.

### 🎨 3. Design System & Componentes
- **[design_system_governance.md](file:///C:/Users/eliez/.gemini/antigravity-ide/brain/5e20ae7a-7e1b-4f53-b5fd-bfbb0302e706/design_system_governance.md)**: A "Constituição Visual" de design tokens e separação por níveis (Level 0 a 3).
- **[DESIGN_SYSTEM_STATUS.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/DESIGN_SYSTEM_STATUS.md)**: Tabela de conformidade de tokens físicos/semânticos.
- **[COMPONENT_REGISTRY.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/COMPONENT_REGISTRY.md)**: Catálogo com status e versionamento dos 19 componentes mapeados.
- **[MIGRATION_PLAN.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/MIGRATION_PLAN.md)**: Guia de transição prática de telas e cores legadas para o motor dinâmico.
- **[SHOWCASE_PLAN.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/SHOWCASE_PLAN.md)**: Roteiro e estrutura do Storybook interno (`packages/fincore_showcase`).

### 🗺️ 4. Decisões Arquiteturais e Futuro
- **[ADR_INDEX.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/ADR_INDEX.md)**: Índice mapeado dos ADRs de 001 a 010.
- **[ROADMAP_PLATFORM.md](file:///f:/Eigent/fincore_platform/docs/platform_foundation_v1/ROADMAP_PLATFORM.md)**: Dependências de pacotes e roadmap de novos módulos de negócio.

---

## 🚀 Roteiro de Engenharia de Plataforma (Platform Roadmap)

Para suportar o crescimento sustentável da plataforma pelos próximos 10 anos, planejamos as seguintes evoluções de engenharia nas próximas fases:

- **Fase 1 — Developer Experience (DX)**: Desenvolvimento de uma ferramenta de CLI própria (`fincore-cli`) para geração automatizada de novos módulos de negócio, CRUDs e diálogo estruturado, além do comando `fincore doctor` para validação de setup local.
- **Fase 2 — Architecture Linter**: Criação do pacote `fincore_analyze` integrado ao pipeline de CI/CD para detectar e bloquear passagens de cores hardcoded, layouts crus ou queries SQL declaradas diretamente fora da camada de repositório.
- **Fase 3 — Platform Health Dashboard**: Painel administrativo expondo cobertura de código, métricas de performance KDS, contagem de hardcodes remanescentes e status de sincronização remota.
- **Fase 4 — Domain-Driven Architecture**: Separação clara de domínios em sub-camadas (Commercial, Inventory, CRM, Finance, Identity) contendo partições limpas de Application, Domain, Infrastructure e Presentation.
- **Fase 5 — Event Catalog**: Catálogo e rastreamento forense de eventos de domínio gerados (ex: `ProductCreated`, `PriceChanged`, `SyncFinished`).
- **Fase 6 — Internal SDK**: Padronização de consumo simplificado via fachada centralizada: `Fincore.audit()`, `Fincore.sync()`, `Fincore.theme()`, etc.

---

## 📈 Métricas de Monitoramento e KPIs

Com o core congelado, nosso progresso será medido por dois conjuntos de indicadores quantitativos:

### Indicadores de Plataforma (Platform Engineering)
- **Test Coverage**: Cobertura global de testes automatizados unitários e de widgets.
- **Dívida Técnica**: Contagem de widgets legados e referências de cores manuais pendentes de migração.
- **Performance**: Tempo de inicialização do app local, latência do ciclo de sincronização de banco de dados e consumo médio de memória em hardware de PDV.

### Indicadores de Produto (Product Engineering)
- **Tempo de Entrada**: Tempo total necessário para cadastrar um novo cliente ou produto no ERP.
- **Ciclo de Venda**: Tempo gasto na criação de um pedido, faturamento e emissão do cupom térmico no PDV Express.
- **Sincronização**: Delay de visibilidade de um pedido criado no PDV para aparecer no KDS (Cozinha).

---

## 🔥 Roteiro de Engenharia de Produto (Product Roadmap)

O desenvolvimento de novas funcionalidades de negócio deve seguir a seguinte ordem de prioridade operacional:

1. **Ciclo de Pedido a Entrega**:
   - Pedidos ➔ Agenda ➔ Produção (KDS) ➔ Expedição ➔ Logística de Entrega (Motoboy) ➔ Financeiro (Fluxo de Caixa).
2. **MRP & Controle de Insumos**:
   - Explosão de insumos ➔ Consumo de receita ➔ Gestão de Lotes ➔ Cadeia de Frio e Congelamento ➔ Alertas de Validade.
3. **CRM & Fidelização**:
   - Cadastro unificado de clientes ➔ Histórico de consumo ➔ Preferências e restrições alimentares ➔ Campanhas direcionadas.
4. **Compras & Cadeia de Suprimentos**:
   - Avaliação de fornecedores ➔ Cotações em lote ➔ Pedidos de compras ➔ Recebimento de mercadorias com atualização automática de estoque.
5. **Dashboard Executivo**:
   - Visibilidade integrada de vendas, perdas de insumos, tempo de preparo de cozinha e lucratividade líquida de vendas.

