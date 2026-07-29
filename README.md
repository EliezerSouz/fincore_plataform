# FINCORE Platform

> **O coração da sua gestão.**

Uma plataforma inteligente que conecta operação, gestão e resultados em um único lugar.

Toda empresa tem um coração. O FINCORE mantém esse coração em movimento.

---

## O que é o FINCORE?

O FINCORE é uma plataforma de gestão construída para pequenas e médias empresas.

A plataforma foi projetada para acompanhar toda a operação do negócio, desde o primeiro cadastro até a análise dos resultados, utilizando uma arquitetura moderna, orientada por domínio e preparada para múltiplos produtos.

Hoje o ecossistema contempla:

- FINCORE Food
- FINCORE Finance (roadmap)
- Novos produtos poderão compartilhar a mesma plataforma.

---

## Princípios

✔ Simplicidade antes da complexidade

✔ Operação antes da configuração

✔ Offline First

✔ Domain Driven Design

✔ Customer Lifecycle Driven

✔ Capabilities antes de módulos

---

## Estrutura do Ecossistema

```text
FINCORE PLATFORM
        │
    Platform
        │
   ┌────┴────┐
   │         │
 Food     Finance
   │         │
   └────┬────┘
        │
 Shared Packages
        │
  Documentation
```

---

## Primeira leitura

Bem-vindo ao ecossistema FINCORE.

A leitura da documentação deve seguir esta ordem:

1. [Constitution](docs/decisions/000_constitution.md)
2. [FPOS (Fincore Point of Sale)](docs/decisions/001_fpos.md)
3. [Evolution Framework](docs/decisions/002_evolution_framework.md)
4. [Execution Reset](docs/decisions/003_execution_reset.md)
5. [Onboarding](docs/002_onboarding.md)

---

## 📂 Estrutura Simplificada do Repositório

O monorepo é organizado para separar de forma limpa a governança, as ferramentas e os produtos desenvolvidos sobre a plataforma:

```
fincore_platform/
│
├── .github/                   ← Templates estruturados de Issues e Pull Requests
├── docs/                      ← Documentação e ADRs organizados por Document IDs
│   └── decisions/             ← Architecture Decision Records (ADRs)
│
├── products/                  ← Verticais de produto comercializáveis
│   ├── README.md              ➔ Catálogo de produtos (Food, Finance, CRM)
│   └── fincore-food/          ➔ FINCORE Food (aplicativo para food service)
│
├── packages/                  ← Componentes e bibliotecas compartilhadas
├── tools/                     ← Scripts de build e ferramentas de desenvolvimento
│
├── README.md                  ← Este arquivo de entrada
├── LICENSE                    ← Licença de uso MIT
└── CHANGELOG.md               ← Histórico de releases
```

---

*FINCORE © 2026 — Toda empresa tem um coração. O FINCORE mantém esse coração em movimento.*
