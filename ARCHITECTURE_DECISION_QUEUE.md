# ARCHITECTURE DECISION QUEUE — SALGADERIA ERP
## FILA DE DECISÕES ARQUITETURAIS PENDENTES (FUTUROS ADRs)

**Data:** 2026-07-24  
**Objetivo:** Registrar e acompanhar temas tecnológicos ou de infraestrutura que exigirão uma decisão arquitetural formal (ADR) durante o desenvolvimento do projeto, evitando que sejam esquecidos.

---

## FILA DE ANÁLISE

| # | Tema da Decisão | Opções em Análise | Status | Impacto / Módulo | Data Alvo |
|---|---|---|---|---|---|
| **ADQ-01** | **Estratégia de Cache para Estoque Crítico** | Redis vs. Serverpod Memory Cache | 🟡 Analisando | Performance do `EstoqueService` | Sprint 6 |
| **ADQ-02** | **Gateway de Mensageria do WhatsApp** | Evolution API vs. Z-API vs. Meta Cloud API | 🟡 Analisando | `WhatsAppService` | Sprint 12 |
| **ADQ-03** | **Armazenamento de Arquivos/Imagens (Logos e Comprovantes)** | Supabase Storage vs. AWS S3 Cloudflare R2 | 🟡 Analisando | Cadastro de Empresa e Expedição | Sprint 4 |
| **ADQ-04** | **Push Notifications para Apps Móveis** | Firebase Cloud Messaging (FCM) vs. OneSignal | ⚪ Aguardando | `NotificationWorker` / Mobile | Sprint 11 |
| **ADQ-05** | **Orquestrador de Webhooks de Pagamento (PIX)** | Mercado Pago API vs. Efí (Gerencianet) vs. Asaas | ⚪ Aguardando | `FinanceiroService` | Sprint 10 |

---

## FLUXO DE TRANSFORMAÇÃO EM ADR

```text
[Item na ARCHITECTURE_DECISION_QUEUE]
                 │
   (Início do desenvolvimento do módulo)
                 │
                 ▼
  [Análise de Prós e Contras / Benchmarks]
                 │
                 ▼
     [Decisão Tomada pela Equipe]
                 │
                 ▼
 [Gerar Arquivo em docs/adr/ADR-00X-Nome.md] ➔ Mover Status para ✅ Concluído
```

---

*Fila de Decisões Arquiteturais mantida pela equipe técnica.*
