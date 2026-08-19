# Quality Gate (Portão de Qualidade) — FINCORE Design System

Este documento estabelece o checklist de conformidade obrigatório que todo componente novo ou refatorado deve satisfazer antes de ser integrado ao core da plataforma.

---

## 🛡️ Checklist de Homologação de UI/UX

Nenhum código de interface de usuário será aceito se falhar em qualquer um dos seguintes critérios de aceitação:

### 1. Aderência aos Tokens de Design
- [ ] O componente consome propriedades apenas de `context.tokens`, `context.spacing`, `context.radius`, `context.motion` ou `context.shadows`.
- [ ] Não existem cores literais declaradas (`Color(0xFF...)` ou `Colors.orange`).
- [ ] Não há números mágicos de layout (margens fixas ou paddings hardcoded).

### 2. Multi-Tema & Acessibilidade
- [ ] O componente foi validado e permanece legível tanto em **Modo Claro (Light Mode)** quanto em **Modo Escuro (Dark Mode)**.
- [ ] Contraste verificado matematicamente pela WCAG (`WcagValidator`): mínimo de `3.0:1` para botões/ações bold ou `4.5:1` para texto normal de leitura.

### 3. Estados de Interação Completos
- [ ] **Hover**: Mudança sutil de cor/opacidade sob mouseover.
- [ ] **Focus**: Anel de foco visível para navegação por teclado.
- [ ] **Disabled**: Estilo visual desativado sem responder a cliques.
- [ ] **Loading**: Estado de carregamento integrado (shimmer ou spinner) ativo.
- [ ] **Error**: Destaque visual adequado em caso de falha de validação.

### 4. Responsividade e Adaptação
- [ ] Adapta-se a diferentes breakpoints via `context.isMobile`/`context.isTablet`/`context.isDesktop`.
- [ ] Não apresenta erros visuais de overflow em telas pequenas.

### 5. Testes e Documentação
- [ ] Acompanha um arquivo de teste de widget (widget test) cobrindo os estados principais.
- [ ] Possui arquivo `README.md` documentando parâmetros e casos de uso típicos.
- [ ] Possui uma versão registrada no Showcase da plataforma.
