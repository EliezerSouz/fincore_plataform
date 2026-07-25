# DESIGN REVIEW CHECKLIST

> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este checklist de design e experiência do usuário (UX) deve ser respondido por qualquer Pull Request que altere ou introduza elementos visuais nos Workspaces antes de ser mesclado em produção.

---

## 📋 Critérios de Aceite de UX Operacional

### 1. Foco e Carga Cognitiva
- [ ] **A tela responde a apenas uma pergunta principal por vez?** (Evitar excesso de ações secundárias que distraiam ou confundam o operador).
- [ ] **Interface limpa e calma**: Há respiro e espaçamentos múltiplos de 8px consistentes?

### 2. Resiliência e Falhas
- [ ] **Comportamento offline testado**: O que acontece se a rede cair durante o uso desta tela? Há bloqueio ou contingência local?
- [ ] **Loading / Shimmer**: Indicadores visuais estão presentes em consultas assíncronas longas (> 500ms)?
- [ ] **Empty States**: Listagens sem dados têm textos claros orientando a primeira ação (ex: botão de criar)?
- [ ] **Error UX**: Feedbacks de erro mostram causa simples, impacto imediato e ação recomendada de recuperação?

### 3. Facilidade e Agilidade (Foco em Teclado/Touch)
- [ ] **Navegação 100% por teclado**: O fluxo principal pode ser completado sem mouse no PDV?
- [ ] **Indicação clara de foco**: O elemento focado pelo teclado possui a borda contrastante de 2px Laranja Forno?
- [ ] **Touch Targets**: Área de toque mínima de 48x48dp (64x64dp na Cozinha) para operações com luvas ou mãos sujas?
- [ ] **Undo (Desfazer)**: Ações irreversíveis têm banner toast temporário de 6s com opção de cancelar?

---

*Design Review Checklist — FINCORE Platform*
