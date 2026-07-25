# Mapa de Capacidades (Platform Capabilities Map)

> **Document ID**: 005  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
> **Owner**: Principal Product Officer & CTO  
>
> Este documento mapeia **o que** a FINCORE Platform oferece e planeja oferecer ao longo do tempo. Ele funciona como o catálogo executivo de ativos de negócio da empresa de software, fornecendo transparência sobre o estado de desenvolvimento de cada capability.

---

## 1. Serviços de Infraestrutura Core (Platform Services)

Estes são os motores arquiteturais compartilhados em `/packages/` que dão sustentação aos produtos:

| Serviço / Capability | Descrição Técnica | Status Atual | Versão Alvo |
|---|---|---|---|
| **Multi-Tenancy** | Isolamento de dados via Postgres RLS e Drift local. | ✅ Stable (Spec) | `v0.0.1` |
| **Offline-First Sync** | Protocolo Outbox/Inbound e deduplicação idempotente. | ✅ Stable (Spec) | `v0.0.1` |
| **Identity & Access** | Autenticação unificada por perfil e token JWT. | 📅 Planned | `v0.0.3` |
| **Audit Logging** | Registros JSON imutáveis de alteração de estado. | ✅ Stable (Spec) | `v0.0.1` |
| **Print Spooler** | Motor de envio RAW (ESC/POS) de impressão térmica. | ✅ Stable (Spec) | `v0.0.1` |

---

## 2. Portfólio de Verticais de Negócio (Product Capabilities)

### 2.1 FINCORE Food (Vertical de Alimentação)

| Capability | Funcionalidades | Status Atual | Versão |
|---|---|---|---|
| **① Receber Pedidos** | PDV Express (Atalhos), PDV Completo, Fila do Dia. | 🛠️ In Development| `v1.0` |
| **② Planejar Produção**| MRP (Previsão de Produção), Agenda e bloqueios. | 📅 Planned | `v1.5` |
| **③ Produzir** | Registro de Lotes (FIFO), devolução de insumos (LIFO).| 🛠️ In Development| `v1.0` |
| **④ Separar & Embalar** | Checklist de expedição física e conferência. | 📅 Planned | `v1.0` |
| **⑤ Entregar** | Roteirização de rotas e despacho de motoboys. | 📅 Planned | `v1.5` |
| **⑥ Receber Pagamento**| Frente de Caixa, PIX dinâmico automático. | 📅 Planned | `v1.0` |
| **⑦ Fidelizar** | Cadastro inteligente de clientes e faixas de preço. | 🛠️ In Development| `v1.0` |

### 2.2 FINCORE Finance (Vertical de Finanças)

| Capability | Funcionalidades | Status Atual | Versão |
|---|---|---|---|
| **⑧ Analisar Negócio** | DRE Financeiro, custos reais, fechamento de caixa. | 📅 Planned | `v1.5` |
| **Conciliação Bancária**| Integração automatizada com extratos Open Finance. | 🔮 Future | `v2.5` |

### 2.3 FINCORE CRM (Vertical de Relação com Clientes)

| Capability | Funcionalidades | Status Atual | Versão |
|---|---|---|---|
| **Loyalty Program** | Carteira de pontos de fidelidade e prêmios automáticos. | 🔮 Future | `v2.0` |
| **WhatsApp CRM** | Campanhas reativas automáticas baseadas em consumo. | 🔮 Future | `v2.0` |

---

## 3. Classificação de Ciclo de Vida de Capabilities

* **🔮 Research (Pesquisa)**: Investigando viabilidade técnica, arquitetura de integração e APIs de terceiros.
* **📅 Planned (Planejado)**: Escopo de UX definido, mapeado no backlog mestre com DoD.
* **🛠️ In Development (Em Desenvolvimento)**: Código ativamente sendo implementado no sprint atual.
* **✅ Stable (Estável)**: Validado, testado e em produção no monorepo principal.
* **🍂 Deprecated (Descontinuado)**: Mantido para compatibilidade histórica, com rota de migração ativa.

---

*Platform Capabilities Map — FINCORE Platform*
