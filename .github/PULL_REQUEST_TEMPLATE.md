# Pull Request — FINCORE Platform

## 📝 Descrição
<!-- Descreva o objetivo da PR, quais alterações foram feitas e quais tarefas/issues ela resolve -->

## 🔗 Tarefas Relacionadas
* Resolve: #<!-- ID da issue correspondente -->

## 💼 Capability Associada
<!-- Indique a qual das 9 Business Capabilities esta PR pertence -->
* [ ] ① Receber Pedidos (PDV)
* [ ] ② Planejar Produção
* [ ] ③ Produzir (Cozinha)
* [ ] ④ Separar & Embalar
* [ ] ⑤ Entregar (Logística)
* [ ] ⑥ Receber Pagamento (Caixa)
* [ ] ⑦ Fidelizar (CRM)
* [ ] ⑧ Analisar Negócio (Analytics)
* [ ] ⑨ Administrar (Control Center / Plataforma)

---

## 🔴 Checklist de Design Review (UX Obligatório)
<!-- Marque [x] para atestar a conformidade com as diretrizes do DESIGN_REVIEW_CHECKLIST.md -->

- [ ] **1. Única Pergunta (Princípio 1)**: A tela responde a apenas uma ação ou pergunta principal por vez?
- [ ] **2. Estado Offline**: O comportamento local caso a internet caia foi testado de forma resiliente?
- [ ] **3. Loading / Shimmer**: Existe indicador visual de carregamento para qualquer query assíncrona?
- [ ] **4. Empty State**: Telas ou listagens vazias sem dados possuem ilustrações descritivas?
- [ ] **5. Error UX**: Os fluxos de erro exibem causa de forma simples, o impacto real e a ação corretiva?
- [ ] **6. Undo**: Ações de exclusão/mudança de status exibem toast temporário com a opção "Desfazer"?
- [ ] **7. Navegação por Teclado**: É possível completar todo o fluxo principal sem encostar no mouse?
- [ ] **8. Foco Visual**: O elemento ativo no teclado possui a borda contrastante de 2px Laranja Forno?
- [ ] **9. Touch Targets**: Todos os botões em telas touch têm tamanho mínimo de 48x48dp (64x64dp na Cozinha)?
- [ ] **10. Feedback Sonoro**: Os alertas críticos ou confirmações emitem bipes correspondentes?

---

## 🛠️ Checklist de Engenharia
* [ ] O código passa na suíte local de testes automatizados (`flutter test`).
* [ ] Novas tabelas ou mutações locais injetam implicitamente o filtro de `tenantId`.
* [ ] O commit segue a convenção de *Conventional Commits*.
* [ ] Qualquer mudança de arquitetura foi previamente discutida e documentada via ADR.
* [ ] A entrega respeita integralmente o **Princípio da Reimplementação Consciente** (sem cópias diretas da Salgaderia).
