# NON-FUNCTIONAL REQUIREMENTS (NFR) — SALGADERIA ERP
## METAS OBJETIVAS DE QUALIDADE, DESEMPENHO E CONFIABILIDADE

**Data:** 2026-07-24  
**Escopo:** Métricas quantitativas de qualidade técnica que a Plataforma de Backend e a aplicação Desktop devem obrigatoriamente cumprir.

---

## 1. REQUISITOS NÃO-FUNCIONAIS QUANTITATIVOS

| Categoria | Parâmetro | Meta Objetiva | Mecanismo de Verificação |
|---|---|---|---|
| **Disponibilidade** | Uptime da Backend Platform | **99.9%** de disponibilidade | Monitoring & Health Checks no Supabase |
| **Desempenho API** | Tempo de resposta de endpoints síncronos | **< 200 ms** (P95) | Métricas APM / Logs Serverpod |
| **Inicialização** | Startup time do App Desktop | **< 3 segundos** | Benchmarks de inicialização Flutter |
| **Sincronização** | Tempo de descarte da fila offline (`sync_queue`) | **< 5 segundos** para 50 registros | Testes automatizados de sync |
| **Autenticação** | Tempo de resposta do login JWT | **< 2 segundos** | Testes de integração de Auth |
| **Qualidade** | Cobertura de testes unitários no backend | **>= 80%** de cobertura | CI/CD (GitHub Actions coverage) |
| **Observabilidade** | Cobertura de logs por tenant | **100%** de operações rastreadas com `correlationId` | Structured Logging |
| **Resiliência** | Operação offline do balcão/cozinha | **100% funcional** para vendas e consultas locais | Testes de desconexão de rede |

---

## 2. REGRAS DE FALHA E SEGURANÇA

*   **Degradação Graciosa:** Se um serviço externo (como a API da OpenAI/Gemini ou WhatsApp) falhar ou estiver lento (> 8s), o ERP desacopla o serviço imediatamente e opera em modo local/estruturado sem travar a interface do operador.
*   **Limites de Carga:** Proteção de rate limiting para evitar estoiro de consumo e garantir que requisições administrativas tenham prioridade em relação aos portais públicos.
*   **Isolamento Rígido de Dados:** Zero vazamento de dados entre empresas/tenants no banco de dados.

---

*Requisitos Não-Funcionais congelados para o ecossistema Salgaderia ERP.*
