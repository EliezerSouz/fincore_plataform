# EXECUTION RULES — SALGADERIA ERP
## AS 7 LEIS DA REVOLUÇÃO E MANUTENÇÃO DO SISTEMA

**Data:** 2026-07-24  
**Escopo:** Regras operacionais de engenharia mandatórias para todo desenvolvedor ou agente de IA trabalhando neste repositório.

---

> 🚀 **REGRA DE OURO DA ENGENHARIA:**
> **"Validar a espinha dorsal antes de adicionar complexidade."**
> *(Primeiro o fluxo mais simples funciona end-to-end; depois adicionamos eventos, sincronização offline, observabilidade e otimizações.)*

---

### LEI 1: NUNCA QUEBRAR O DESKTOP VIGENTE
O ERP Desktop Windows em produção é a ferramenta de trabalho da empresa. Nenhuma alteração, refatoração ou migração de banco de dados pode deixar a aplicação Desktop incapaz de abrir, compilar ou realizar vendas. Toda Sprint termina com o **build do Windows 100% funcional**.

### LEI 2: NUNCA REMOVER CÓDIGO ANTES DA MIGRAÇÃO COMPLETA
Seguindo o *Strangler Fig Pattern*, o código legado (como chamadas diretas ao SQLite) só pode ser deletado do frontend após o novo `Domain Service` no backend Serverpod estar implementado, testado, integrado e validado em produção.

### LEI 3: CRITÉRIOS DE ACEITE E EXIT CRITERIA SÃO INEGOCIÁVEIS
Nenhuma Sprint ou Fase é considerada encerrada se faltar um único item do seu *Exit Criteria*. O avanço para uma nova fase sem validar a fase anterior gera débito técnico cascateado e é estritamente proibido.

### LEI 4: VETO ABSOLUTO DE REGRAS DE NEGÓCIO NA UI
Telas em Flutter (Windows, Web ou Mobile) são puramente declarativas e reativas. Nenhuma lógica de validação física de estoque, regras de precificação por quantidade, SLAs ou cálculos de margem pode ser escrita dentro de Widgets ou ViewModels do frontend. **Toda regra pertence ao Backend Platform.**

### LEI 5: OBLIGATORIEDADE DE TESTES E COBERTURA MÍNIMA
Nenhum `Domain Service` ou endpoint do Serverpod pode ser merged sem testes unitários e de integração correspondentes. A cobertura de testes automatizados na camada de negócio do backend deve ser mantida em **no mínimo 80%**.

### LEI 6: DOCUMENTAÇÃO DE DECISÕES ARQUITETURAIS (ADR)
Qualquer desvio do design original, inclusão de pacotes/dependências críticas no Serverpod, mudanças no modelo de concorrência ou alterações de infraestrutura devem ser obrigatoriamente registrados em um arquivo curto de **ADR (Architecture Decision Record)** na pasta `docs/adr/`. Mudanças de arquitetura geram ADRs; evoluções padrão geram código.

### LEI 7: ISOLAMENTO TOTAL VIA INTERFACES DE ABSTRAÇÃO
Integrações externas (WhatsApp, PSPs de PIX, APIs de IA, serviços de E-mail) nunca podem ser chamadas diretamente pelos módulos centrais do sistema. Elas devem passar obrigatoriamente por interfaces abstratas (`WhatsAppService`, `AIService`), permitindo a troca transparente de fornecedores terceiros sem impactar o ERP.

---

## SPRINT 0 — MARCO GO / NO-GO

A Sprint 0 deve ser tratada como a validação definitiva de viabilidade tecnológica. O avanço para a Fase 1 só ocorre mediante aprovação dos 6 entregáveis do Go/No-Go:

1. [ ] Serverpod rodando em ambiente local.
2. [ ] PostgreSQL ativo (Docker local ou Supabase).
3. [ ] Pacote compartilhado `salgaderia_shared` compilando.
4. [ ] Flutter Desktop conectando ao backend.
5. [ ] Endpoint de diagnóstico `GET /health` respondendo 200 OK.
6. [ ] Primeiro endpoint de consulta de Produto funcional e consumido na UI Desktop.

---

## RETROSPECTIVA AO FINAL DE CADA FASE

Ao término do *Exit Criteria* de cada Fase, é mandatória uma retrospectiva de engenharia cobrindo 4 perguntas:
1. *O que aprendemos com a execução desta Fase?*
2. *Alguma hipótese técnica ou premissa de sync se mostrou incorreta?*
3. *O backlog de Sprints futuras exige algum reajuste de pontos ou ordem?*
4. *Algum novo ADR precisa ser documentado no repositório?*

---

## DEFINITION OF READY (DoR) DA PLATAFORMA

Uma User Story / Task só pode ser puxada para a Sprint quando atender a todos os critérios de prontidão:

- [ ] **Critérios de Aceite Definidos:** Requisitos de comportamento e resposta da API claramente descritos.
- [ ] **Dependências Resolvidas:** Nenhuma dependência de módulos anteriores bloqueando a execução.
- [ ] **Impacto Arquitetural Avaliado:** Se houver alteração de contrato de API ou ORM, um ADR correspondente foi rascunhado.
- [ ] **Cenários de Teste Mapeados:** Testes unitários e de sincronização offline identificados previamente.
- [ ] **Estimativa em Pontos Concluída:** A história foi pontuada e cabe dentro da capacidade da Sprint.
- [ ] **Design/Protótipo Revisado:** Se houver mudança de UI no Flutter, a tela está definida e aprovada.

---

*Estas regras formam a constituição operacional do repositório. O descumprimento de qualquer uma das 7 leis, do DoR ou do Go/No-Go invalida a entrega da Sprint.*
