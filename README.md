# FINCORE Platform Monorepo

> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Bem-vindo ao repositório central da **FINCORE**, a plataforma corporativa que serve de fundação para o desenvolvimento de múltiplos produtos corporativos de alta resiliência e foco operacional.

---

## 🚀 Como Iniciar (Onboarding Obrigatório)

Se você é um novo colaborador ou Inteligência Artificial integrada ao time, **é obrigatório** ler o documento de boas-vindas e seguir a trilha sequencial de leitura de governança antes de fazer qualquer alteração ou escrever código:

👉 **[PLT-002: Onboarding](file:///f:/Eigent/fincore_platform/docs/002_onboarding.md)**

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

*FINCORE Platform — Desenvolvendo o futuro dos sistemas operacionais.*
