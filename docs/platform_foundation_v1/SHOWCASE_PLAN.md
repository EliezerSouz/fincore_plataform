# Planejamento do Showcase de Componentes — FINCORE Showcase

Este documento planeja o desenvolvimento do pacote `packages/fincore_showcase`, que funcionará como a ferramenta de Storybook interna do ecossistema FINCORE.

---

## 🏛️ Estrutura do Pacote `fincore_showcase`

O showcase será estruturado como uma aplicação Flutter separada dentro do monorepo, permitindo que designers e desenvolvedores interajam com os componentes isoladamente:

```text
packages/fincore_showcase/
├── lib/
│   ├── main.dart             // Inicializa o showcase e o gerenciador de estado do tema
│   ├── src/
│   │   ├── categories/       // Menu de navegação por categorias (Buttons, Forms, Layouts)
│   │   ├── widgets/          // Visualizadores individuais de cada componente
│   │   └── sandbox/          // Painel interativo para ajustar cores de marca e arredondamento
```

---

## 🎨 Painel Interativo de Teste de Marca (Sandbox)
O Showcase incluirá um controle deslizante lateral que permitirá:
1. **Alterar a Cor de Marca (Brand Color)**: Injeta instantaneamente a cor via `ThemeController` e reconstrói todos os botões e inputs para testar o comportamento White-Label.
2. **Alternar Modos**: Chave rápida para alternar entre Dark Mode e Light Mode.
3. **Ajustar Bordas (BorderRadius)**: Mudar o raio dinamicamente entre `4`, `8`, `12` e `20` pixels.
4. **Verificar Contraste**: Exibir na tela se a combinação de cor de marca escolhida atende aos critérios WCAG de acessibilidade.

---

## 📅 Roteiro de Implementação do Showcase
- **Semana 1**: Estruturar a navegação lateral e controle sandbox de marcas e temas.
- **Semana 2**: Integrar botões, inputs, switches, checkboxes e cards (Level 1).
- **Semana 3**: Adicionar os painéis estruturais complexos `FincoreScaffold` e `CrudSplitView` (Level 3) com dados mockados de ERP e KDS.
