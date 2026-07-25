# Guia de Engenharia (Engineering Guide)

> **Document ID**: 003  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento define os padrões obrigatórios de escrita de código, qualidade arquitetural e o uso colaborativo de inteligência artificial adotados em todos os produtos da FINCORE.

---

## 1. Princípio da Reimplementação Consciente

> [!IMPORTANT]
> **O código existente em projetos legados (como a Salgaderia) serve exclusivamente como referência de conhecimento.**
> Nenhum componente ou arquivo de código-fonte deve ser copiado diretamente para este repositório. Toda funcionalidade incorporada ao FINCORE deverá ser reimplementada do zero, em conformidade estrita com os padrões arquiteturais, de qualidade de código, acessibilidade física e governança definidos nesta plataforma.

---

## 2. Padrões de Código e Clean Architecture

Toda base de código escrita sob a FINCORE deve respeitar o desacoplamento de Clean Architecture dividida em:

* **Presentation Layer**: Controladores de estados finitos que isolam eventos e lógica visual dos widgets do Flutter.
* **Domain Layer**: Regras de negócio puras (Use Cases e Entities) em Dart puro, sem dependências de infraestrutura de banco de dados ou frameworks.
* **Data Layer**: Repositórios concretos e conexões SQLite/Postgres (Serverpod e Drift).

### 2.1 Regra da Abstração Compartilhada (Abstração Tardia)

> [!IMPORTANT]
> **Toda abstração compartilhada deve surgir da necessidade comprovada em pelo menos dois pontos distintos da plataforma.**
> Antes disso, a implementação deve permanecer local ao domínio que a utiliza. É expressamente proibido criar frameworks internos, classes bases globais (ex: `Command`, `CommandHandler`, `Repository`, `Entity`) ou componentes de infraestrutura compartilhados de forma preemptiva em `/packages/fincore_core/` ou `/packages/fincore_shared/` sem uma demanda real comprovada pela repetição física do código.

---

## 3. Padrões Obrigatórios de Robustez Distribuída

* **Outbox e Idempotência**: Qualquer gravação síncrona transacional deve registrar a tarefa outbox de forma atômica localmente. A API cloud garante a idempotência validando chaves UUID `commandId`.
* **Segurança e Tenants**: Queries de persistência devem filtrar implicitamente o `tenantId` logado para impedir vazamento de dados de inquilinos.

---

## 4. Uso Colaborativo de Inteligência Artificial (AI Guidelines)

Como a FINCORE adota o desenvolvimento acelerado com suporte de IAs (como Claude, Gemini, ChatGPT e Copilot), as seguintes diretrizes são mandatórias para qualquer agente de IA ou desenvolvedor humano que interaja com prompts:

### 4.1 O Contrato de Prompt de IA
Toda IA atuante no projeto é considerada um membro pleno da equipe de arquitetura e deve obedecer à **Single Source of Truth (SSOT)**.
* **Leitura Prévia**: A IA deve ler a trilha de onboarding descrita no **[PLT-002: Onboarding](file:///f:/Eigent/fincore_platform/docs/002_onboarding.md)** antes de sugerir refatorações.
* **Proibição de Código Fora do Escopo**: É estritamente proibido criar features fantasmas ou códigos que não sirvam a uma Capability e Feature prioritária descrita no backlog.
* **Consistência de Estado**: IAs devem modelar telas baseadas em máquinas de estados finitos descritas no State Design, em vez de espalhar estados mutáveis reativos em views.

### 4.2 Como Referenciar Decisões
Toda sugestão de código ou Pull Request gerado por ferramentas de IA deve listar no rodapé da descrição:
1. Quais documentos de governança em `docs/` serviram de base.
2. A atestação de que a entrega atende a 100% dos requisitos do **[PRD-009: Design Review Checklist](file:///f:/Eigent/fincore_platform/docs/109_design_review_checklist.md)**.

---

*Engineering Guide — FINCORE Platform*
