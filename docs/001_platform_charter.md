# Carta da Plataforma (Platform Charter)

> **Document ID**: 001  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
> **Owner**: Comitê de Arquitetura & Produto FINCORE  
>
> Este documento rege a missão, os objetivos e os padrões técnicos obrigatórios da **FINCORE**, a plataforma de tecnologia corporativa que serve de base para todos os produtos e verticais do ecossistema.

---

## 1. Propósito e Missão

O propósito da **FINCORE** é fornecer a fundação tecnológica ideal para o desenvolvimento de softwares corporativos e operacionais de alta robustez. A plataforma garante que novos produtos e verticais de negócio nasçam compartilhando a mesma filosofia de engenharia e os mesmos padrões de qualidade, eliminando redundâncias e acelerando o tempo de lançamento no mercado (Time-to-Market).

**Nossa Missão**:
> *"Empoderar equipes de engenharia a construir, manter e escalar verticais de produto corporativo de forma ágil, segura, offline-first e altamente resiliente à infraestrutura adverso."*

---

## 2. Divisão de Nomenclatura (Marca vs. Repositório)

Para manter a integridade comercial e organizacional do ecossistema, distinguimos explicitamente a identidade da marca da nomenclatura técnica:

* **FINCORE**: A marca oficial da plataforma, da futura empresa de software e do ecossistema corporativo.
* **`fincore_platform`**: O nome técnico do monorepo de código-fonte que abriga o ecossistema.
* **Verticais de Produto**: Nomes de produtos comerciais que nascem da plataforma, sempre prefixados com a marca (ex: `FINCORE Food`, `FINCORE Finance`).

---

## 3. Verticais de Produto Previstos

A plataforma é desenhada de forma desacoplada para permitir que múltiplos verticais de produto coexistam no mesmo repositório compartilhando código comum em `packages/`:

1. **FINCORE Food**: Sistema de automação operacional para o segmento de food service, produção sob encomenda e salgaderias (primeiro produto do ecossistema).
2. **FINCORE Finance**: Módulo e produto independente de gestão de fluxo de caixa, contas a receber, conciliação e demonstrativos contábeis (DRE).
3. **FINCORE CRM**: Hub de fidelização, histórico de compras, programa de prêmios e automação de contatos com clientes.
4. **FINCORE Analytics**: Motor de inteligência operacional com relatórios de performance, custos reais de produção e projeções de faturamento.
5. **FINCORE AI**: Agentes autônomos de inteligência artificial voltados a atendimento de canais e sugestões de volume ótimo de fabricação (MRP).
6. **FINCORE API**: Barramento de APIs de integração para canais externos (iFood, marketplaces, ERPs parceiros).

---

## 4. Padrões Técnicos Obrigatórios (Platform Core Standards)

Todo e qualquer produto construído sobre a FINCORE deve aderir estritamente aos seguintes padrões de engenharia:

### 4.1 Resiliência Offline-First
A operação local física do cliente é soberana. O sistema deve continuar funcionando normalmente (faturamento, impressão, preparo, baixas de estoque) mesmo sem conectividade de rede à internet. A sincronização em nuvem ocorre em background de forma assíncrona e transparente.

### 4.2 Isolamento Lógico de Inquilinos (Multi-Tenancy)
Dados de diferentes empresas (tenants) nunca se cruzam. O isolamento lógico deve ser mantido de forma rígida via **Row-Level Security (RLS)** no PostgreSQL (nuvem) e por filtros obrigatórios de `tenantId` nas transações SQLite (local).

### 4.3 Arquitetura Orientada por Eventos e CQRS
A escrita (Commands) deve ser desacoplada da leitura (Queries/Projeções). Mutações geram eventos imutáveis (`EventosPedido` e logs estruturados) que servem de histórico auditável e auditoria de caixa.

### 4.4 Automação de Spooler Físico
O software local deve gerenciar comandos diretos (ESC/POS) enviados ao spooler de impressão de etiquetas e cupons de forma assíncrona, garantindo que o faturamento de vendas não trave em caso de falhas físicas no hardware térmico.

---

## 5. Governança da Plataforma

* **ADR First**: Qualquer alteração estrutural ou de stack na arquitetura compartilhada da plataforma deve ser formalizada previamente através de um registro de decisão arquitetural (ADR - Architecture Decision Record).
* **Stack Tecnológica**: A stack tecnológica oficial da plataforma é canônica e regulada por meio do documento **[ADR-001: Stack Tecnológica Oficial](file:///f:/Eigent/fincore_platform/docs/300_decisions/301_adr_001_official_technology_stack.md)**. Alterações ou inclusões de novos componentes exigem nova versão do ADR.
* **Mudança Controlada**: Documentos marcados como `Frozen` (Congelados) não podem ser alterados de forma direta. Evoluções exigem nova versão semântica e aprovação do comitê.
* **PR Gates**: O merge de novos branches exige conformidade com as diretrizes do guia de contribuição **[ENG-002: Contributing](file:///f:/Eigent/fincore_platform/docs/401_contributing.md)** e aprovação nos testes automatizados locais.

---

*Platform Charter — FINCORE Platform*
