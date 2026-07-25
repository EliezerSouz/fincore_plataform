# PRODUCT RESET 1.0 — FASE 1 (REVISÃO FINAL)
## Princípios, Capacidades, Domínios, Workspaces e Documentação

**Comitê**: Product Officer · Software Architect · CTO SaaS · UX Architect · Especialista ERP · Especialista Produção Alimentícia · Especialista PDV · Especialista Flutter/Serverpod/Drift

**Data**: 2026-07-25
**Revisão**: Final — Fase 1 congelada
**Status**: ✅ APROVADO — Documento Mestre — Fase 1 de 5

---

> [!IMPORTANT]
> **Regra permanente do produto**: Toda decisão de produto, arquitetura, design ou código deve responder positivamente à pergunta:
> *"Isso sobrevive em um produto vendido para 500 empresas?"*
> Se a resposta for não, a decisão está errada.

---

# PARTE 0 — PRODUCT PRINCIPLES

> [!CAUTION]
> Os documentos de diretrizes fundamentais da Fase 1 foram extraídos e congelados como referências independentes:
>
> 1. **[PRODUCT_PRINCIPLES.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_PRINCIPLES.md)** — Princípios do Produto
> 2. **[PRODUCT_MANIFESTO.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_MANIFESTO.md)** — Linhas vermelhas filosóficas e inegociáveis
> 3. **[PRODUCT_METRICS.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_METRICS.md)** — Métricas de sucesso que guiam priorização por resultados
> 4. **[QUALITY_ATTRIBUTES.md](file:///f:/Eigent/fincore_platform/docs/QUALITY_ATTRIBUTES.md)** — Requisitos não-funcionais técnicos por capacidade
>
> **Nenhum código deve ser escrito antes da leitura e compreensão destes documentos.**

---

# PARTE 1 — HIERARQUIA DE PENSAMENTO DO PRODUTO

## 1.1 A Nova Ordem

O produto **não** é organizado por telas. Não é organizado por módulos. Não é organizado por páginas.

O produto é organizado assim:

```
EMPRESA (quem usa)
    ↓
OPERAÇÃO (o que faz no dia a dia)
    ↓
CAPACIDADES DE NEGÓCIO (o que o sistema sabe fazer)
    ↓
DOMÍNIOS (como o conhecimento é agrupado)
    ↓
WORKSPACES (o ambiente visual por perfil)
    ↓
FUNCIONALIDADES (ações concretas)
    ↓
TELAS (a interface final)
```

---

# PARTE 2 — BUSINESS CAPABILITIES (Capacidades de Negócio)

## As 9 Capacidades do Produto

1. **RECEBER PEDIDOS**: O sistema sabe receber pedidos de qualquer origem (PDV Express, Web, WhatsApp IA, APIs).
2. **PLANEJAR PRODUÇÃO**: O sistema sabe o quanto produzir, quando e para quem (capacidades, agendas, bloqueios).
3. **PRODUZIR**: O sistema sabe registrar o o que foi produzido, por quem e quando (lotes, validade FIFO).
4. **SEPARAR & EMBALAR**: O sistema sabe o que precisa sair, para quem e em que ordem (checklist digital).
5. **ENTREGAR**: O sistema sabe organizar, roteirizar e rastrear entregas.
6. **RECEBER PAGAMENTO**: O sistema sabe cobrar, confirmar e conciliar (caixa, PIX dinâmico automático).
7. **FIDELIZAR**: O sistema sabe reconhecer, reter e recompensar clientes.
8. **ANALISAR NEGÓCIO**: O sistema sabe transformar dados operacionais em decisões (DRE, custos).
9. **ADMINISTRAR**: O sistema sabe configurar, controlar e governar a plataforma (Control Center).

---

# PARTE 3 — DOMÍNIOS (Bounded Contexts)

As 9 capacidades se organizam em **5 domínios** + **2 domínios de plataforma**:
* **COMERCIAL**: Receber Pedidos (①), Fidelizar (⑦)
* **OPERACIONAL**: Planejar (②), Produzir (③), Separar (④), Entregar (⑤)
* **FINANCEIRO**: Receber Pagamento (⑥), Analisar Negócio (⑧)
* **OMNICHANNEL**: Adaptadores de entrada (PDV, Web, WhatsApp IA, API)
* **EXPERIENCE**: Workspaces, Preferências, Notificações, Temas
* **PLATAFORMA**: Administrar (⑨), Identidade, Sync, Feature Flags, Licenciamento

---

# PARTE 4 — WORKSPACES POR PERFIL

## 4.1 Conceito de Persona Temporária
O dono pode trocar de workspace sem trocar de usuário. Isso permite simular a interface de atendimento ou da cozinha em tempo real para auditoria e treinamentos rápidos.

## 4.2 Workspaces Definidos
* **DONO**: Dashboard Executivo e Control Center.
* **ATENDENTE**: PDV (Express/Completo), Fila de Vendas do Dia e controle de Caixa.
* **COZINHA**: Painel de Preparo, Agenda do Dia, Registro de Lotes e Insumos.
* **EXPEDIÇÃO**: Pedidos Prontos, Checklist de Embalagem e Roteirização.
* **FINANCEIRO**: Fluxo de Caixa, Contas a Receber e Fechamento.

---

# PARTE 5 — CONTROL CENTER (ex-Centro Administrativo)

O Control Center é um hub de governança com as seguintes divisões:
* 🏢 **Empresa**: Razão social, CNPJ, dados fiscais.
* 👥 **Operação**: Usuários, operadores, permissões granulares por perfil e simulações.
* 💳 **Cobrança**: Formas de pagamento, regras de PIX e taxas.
* 🔗 **Integrações**: WhatsApp API, iFood, gateways externos.
* 📡 **Canais**: Configurações de impressão térmica, URLs do Portal Web e IA.
* 🚚 **Logística**: Bairros, taxas por região e entregadores.
* 🔄 **Plataforma**: Sincronização, Backups e Feature Flags do SaaS.
* 🔍 **Diagnóstico**: Logs estruturados JSON e status de conectividade.
* 🎨 **Experiência**: Temas, cores do PDV e idiomas.

---

# PARTE 6 — FEATURE FLAGS (Tridimensional)

As feature flags controlam as capacidades do produto sob 3 dimensões cruzadas:
* **Plano da Empresa**: Starter, Pro ou Enterprise habilitam o recurso no banco cloud.
* **Perfil do Usuário**: Dono, Atendente, Cozinha definem nível de acesso (Ler, Escrever, Admin).
* **Capability de Negócio**: Conecta o recurso ao domínio transacional do monorepo.

---

*Fase 1 de Governança — Eigent Reset*
*Assinado pelo Comitê e Congelado.*
