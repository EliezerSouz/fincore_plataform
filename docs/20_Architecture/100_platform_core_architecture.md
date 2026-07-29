---
Title: Platform Core Architecture
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Arquitetura do Platform Core (Platform Core Architecture)

> **Document ID**: 100  
> **Version**: 1.0.0  
> **Status**: ✍️ Ativo  
>
> Este documento especifica o desenho arquitetural do Platform Core da FINCORE Platform, definindo responsabilidades, limites lógicos, diagramas de módulos e políticas de extensão para o monorepo.

---

## 🎯 1. Responsabilidades do Core

O Platform Core representa o núcleo de infraestrutura compartilhada do ecossistema FINCORE. Suas responsabilidades são estritamente técnicas e transversais, abstendo-se de conhecer regras ou especificações de verticais de negócio (como Food, CRM ou Financeiro).

As capacidades sob responsabilidade do Core são:
1. **Multi-Tenancy (Isolamento)**: Filtro dinâmico e validação obrigatória de `tenantId` em todas as operações de banco local/remoto.
2. **Sincronização Reativa (SyncEngine & Outbox)**: Replicação de dados offline-first, fila outbox transacional local e políticas de resolução de conflitos.
3. **Auditoria Geral (AuditService)**: Gravação imutável de autoria, alteração e deleção de dados em nível de banco.
4. **Gerenciamento de Contexto (TenantContext)**: Estado ativo da sessão do operador, localização, fuso horário, moeda e idioma ativos.
5. **Persistência Compartilhada (BaseRepository & Drift base)**: Abstrações de repositório comuns e helpers de acesso ao SQLite.
6. **Segurança e PINs**: Autenticação de dois fatores, controle de sessão e validação de PIN de gerente para mutações críticas.

---

## 🏗️ 2. Limites Arquiteturais e Dependências

Para evitar acoplamentos que quebrem a modularidade e impeçam a reutilização do Core em outros projetos do monorepo, são estabelecidos os seguintes limites de dependências de código:

```text
┌──────────────────────────────────────────────────────────┐
│                      Módulos Funcionais                  │
│               (fincore_food, fincore_finance)            │
└────────────────────────────┬─────────────────────────────┘
                             │
                             ▼ (Depende de)
┌──────────────────────────────────────────────────────────┐
│                       Platform Core                      │
│                      (fincore_core)                      │
└────────────────────────────┬─────────────────────────────┘
                             │
                             ▼ (Depende de)
┌──────────────────────────────────────────────────────────┐
│                      fincore_shared                      │
│                  fincore_design_system                   │
└──────────────────────────────────────────────────────────┘
```

### Regras de Acoplamento:
1. **Isolamento de Negócio**: Nenhuma classe dentro de `fincore_core` pode importar arquivos, pacotes ou modelos pertencentes aos verticais de negócio (`fincore_food`, `fincore_finance`, etc.).
2. **Uso de Contratos**: Comunicações do Core com regras específicas de domínio devem ser feitas através de interfaces abstratas (contratos) injetadas no container de DI em tempo de execução.
3. **Persistência de Dados**: O Core expõe o `BaseRepository` genérico e gerencia a outbox. Tabelas específicas de domínio devem estender as abstrações expostas pelo Core.

---

## 📂 3. Organização de Módulos (packages/fincore_core)

O pacote `fincore_core` é estruturado nas seguintes subpastas de forma a organizar logicamente as capacidades:

```text
fincore_core/
├── lib/
│    ├── auth/          # Autenticação de dois fatores e controle de acessos
│    ├── audit/         # AuditService e gravação de logs de AuditEvent
│    ├── common/        # Helpers comuns e exceções globais
│    ├── context/       # TenantContext e variáveis de ambiente/internacionalização
│    ├── database/      # Configurações do Drift SQLite e outbox_sync schema
│    ├── di/            # Registro e abstração de Injeção de Dependências
│    ├── repository/    # Contrato abstrato BaseRepository
│    ├── sync/          # SyncEngine e workers de push/pull offline-first
│    └── tenancy/       # Filtros e validação dinâmica de isolamento por Tenant
```

---

## 🚀 4. Políticas de Extensão

Qualquer nova capacidade de infraestrutura de rede, criptografia, exportação fiscal ou integração genérica de pagamentos que seja passível de reuso por mais de um vertical deve ser modelada primeiramente como uma proposta de extensão de infraestrutura e implementada no Platform Core.
