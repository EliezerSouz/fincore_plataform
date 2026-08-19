# ADR-009: Design System Tokenizado em Camadas

## Status
Aprovado (Freeze V1)

## Contexto
O FINCORE está evoluindo de um aplicativo único (FINCORE Food) para um ecossistema multiplataforma (ERP, PDV, App Cliente, App Motoboy) que roda em modo White-Label. Temas e cores primárias não podem mais estar associados a valores estáticos hardcoded na árvore de widgets.

## Decisão
Implementamos uma arquitetura de design system tokenizada em quatro camadas hierárquicas:
1. **Foundation (Physical Tokens)**: Escala física primitiva de cores brutas, espaçamentos unificados (`FincoreSpacing`), arredondamento de cantos (`FincoreRadius`), elevações (`FincoreShadowsFoundation`) e motion (`FincoreMotion`).
2. **Semantic Tokens**: Mapeamento de cores baseado em significado operacional (ex: `tokens.background`, `tokens.textPrimary`, `tokens.actionPrimary`).
3. **Component Specs & State Tokens (UI Contracts)**: Definições visuais específicas por componente que resolvem comportamentos e estados de interação de forma agnóstica (ex: `ButtonSpec`, `InteractionState`).
4. **Bridge de Compatibilidade (`FincoreColors`)**:fachada mantendo cores secundárias estáticas como constantes para evitar quebras em construtores const legados, enquanto a cor primária e gradientes mudam dinamicamente a partir dos tokens.

O acesso aos tokens ocorre de forma idiomática através do `FincoreThemeScope` e da extensão do `BuildContext` (ex: `context.tokens`, `context.spacing`).

## Consequências
- **Positivas**:
  - Customização de temas visualmente segura e isolada de regressões em tempo de compilação.
  - Compatibilidade com o ecossistema existente por meio da camada Bridge.
  - Acessibilidade validada automaticamente por cálculo matemático de contraste WCAG.
- **Negativas**:
  - Requer que novas interfaces sigam estritamente o Quality Gate e consumam apenas propriedades via context.
