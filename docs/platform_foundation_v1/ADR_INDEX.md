# Índice de Decisões de Arquitetura (ADR Index) — FINCORE

Este documento cataloga todas as Decisões de Arquitetura (Architecture Decision Records) oficiais registradas na pasta [docs/300_decisions/](file:///f:/Eigent/fincore_platform/docs/300_decisions/).

---

## 📂 Catálogo de ADRs Ativos

### [ADR-001: Official Technology Stack](file:///f:/Eigent/fincore_platform/docs/300_decisions/301_adr_001_official_technology_stack.md)
- **Status**: Aprovado
- **Decisão**: Definição da stack base (Flutter, Drift/SQLite para offline, Supabase para sincronização em nuvem, e injeção por contêiner).

### [ADR-002: Supabase Auth IDP](file:///f:/Eigent/fincore_platform/docs/300_decisions/302_adr_jz_001_supabase_auth_idp.md)
- **Status**: Aprovado
- **Decisão**: Uso do Supabase Auth como provedor de identidade global do ecossistema.

### [ADR-003: Usuários Globais sem TenantID](file:///f:/Eigent/fincore_platform/docs/300_decisions/303_adr_jz_002_usuarios_global_sem_tenantid.md)
- **Status**: Aprovado
- **Decisão**: Usuários não são atrelados a um único tenant em sua tabela raiz, permitindo a mesma conta transitar por múltiplos convites de empresas.

### [ADR-004: Identificadores Únicos UUIDv7](file:///f:/Eigent/fincore_platform/docs/300_decisions/304_adr_003_uuid_v7_identificadores.md)
- **Status**: Aprovado
- **Decisão**: Adoção de UUIDv7 ordenados por tempo para chaves primárias físicas, facilitando inserções indexadas no SQLite e Supabase.

### [ADR-005: Sync Engine com Outbox Topológico](file:///f:/Eigent/fincore_platform/docs/300_decisions/305_adr_004_sync_engine_topological_outbox.md)
- **Status**: Aprovado
- **Decisão**: Estruturação da fila de sincronização baseada em prioridade de chaves estrangeiras (Topological Order) para evitar erros de FK em envios remotos.

### [ADR-006: PDV Pricing Engine Integration](file:///f:/Eigent/fincore_platform/docs/300_decisions/306_adr_005_pdv_pricing_engine_integration.md)
- **Status**: Aprovado
- **Decisão**: Acoplamento do motor de precificação em lote (`fincore_pricing`) diretamente no fluxo de caixa/vendas do PDV Express.

### [ADR-007: Delivery Multi-Address and Scheduling](file:///f:/Eigent/fincore_platform/docs/300_decisions/307_adr_006_delivery_multi_address_and_scheduling.md)
- **Status**: Aprovado
- **Decisão**: Suporte nativo a agendamento de entregas e múltiplos endereços por cliente no banco offline.

### [ADR-008: Observabilidade e Auditoria Forense](file:///f:/Eigent/fincore_platform/docs/300_decisions/308_adr_008_observability.md)
- **Status**: Aprovado
- **Decisão**: Persistência de diffs JSON de auditoria, vinculação por Trace ID e monitoramento forense offline-first.

### [ADR-009: Design System Tokenizado em Camadas](file:///f:/Eigent/fincore_platform/docs/300_decisions/309_adr_009_design_system_tokenizado.md)
- **Status**: Aprovado
- **Decisão**: Arquitetura em camadas (Foundation, Semantic, Component, Bridge) com escopo reativo via contexto Flutter.

### [ADR-010: Arquitetura White-Label e Overrides por App](file:///f:/Eigent/fincore_platform/docs/300_decisions/310_adr_010_white_label.md)
- **Status**: Aprovado
- **Decisão**: Customização de marca baseada em configurações persistidas no SQLite com validação de contraste WCAG ativa.
