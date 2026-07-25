# ADR-000: [TÍTULO DA DECISÃO ARQUITETURAL]

**Data:** YYYY-MM-DD  
**Status:** [ 💡 Proposto | ✅ Aceito | ❌ Rejeitado | ⚠️ Substituído por ADR-XXX ]  
**Decisores:** [Nomes/Papéis dos envolvidos]  

---

## 1. CONTEXTO
Descreva o cenário técnico ou operacional, o problema enfrentado e o motivo pelo qual uma decisão arquitetural é necessária.

## 2. REQUISITOS & RESTRICÕES
Liste as restrições de desempenho, custo, complexidade ou governança que afetam a escolha.

## 3. ALTERNATIVAS CONSIDERADAS
- **Opção A:** [Descrição curta, prós e contras]
- **Opção B:** [Descrição curta, prós e contras]
- **Opção C:** [Descrição curta, prós e contras]

## 4. DECISÃO ESCOLHIDA
Especifique a opção escolhida e a justificativa clara pela qual ela supera as alternativas no contexto do ecossistema Salgaderia ERP.

## 5. CONSEQUÊNCIAS
- **Positivas:** [Ganhos de performance, facilidade de manutenção, reuso, etc.]
- **Negativas / Riscos:** [Aumento de complexidade, dependência de terceiros, débito técnico assumido.]

## 6. IMPACTO NAS APIS (CONTRACT & BREAKING CHANGES)
- **Mudanças em Endpoints:** [Acréscimo de rotas, deprecamento ou alterações em DTOs.]
- **Versionamento:** [Exige nova versão `/v2` ou mantém compatibilidade retroativa com cliente N-1?]

## 7. IMPACTO NA MIGRAÇÃO E SINCRONIZAÇÃO (DATABASE & OFFLINE)
- **Migrations no Postgres:** [Afeta tabelas existentes? Exige scripts de atualização de dados antigos?]
- **Reconciliação Offline:** [Altera regras de concorrência ou sync_queue no SQLite local?]
