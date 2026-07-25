# Design System - Salgaderia ERP

Este documento centraliza as definições visuais oficiais do projeto Salgaderia ERP. Todos os novos layouts, telas e componentes devem seguir as regras abaixo, garantindo consistência em todas as plataformas (Web, Desktop, Mobile).

## 1. Identidade Visual (Cores)
As cores são fixas e devem ser utilizadas estritamente através do arquivo `colors.dart`.
- **Primary:** `#F15A37`
- **Primary Hover:** `#E04C29`
- **Background:** `#F7F8FA`
- **Surface:** `#FFFFFF`
- **Sidebar:** `#FFFFFF`
- **Border:** `#E6E8EC`
- **Success:** `#22C55E`
- **Warning:** `#F59E0B`
- **Danger:** `#EF4444`
- **Info:** `#3B82F6`

## 2. Tipografia
- **Família de Fonte Principal:** `Inter` (via pacote google_fonts)
- **Fallback:** `Segoe UI`
- **Tamanhos e Hierarquia:**
  - `H1`: 32px
  - `H2`: 24px
  - `H3`: 20px
  - `Título Card`: 18px
  - `Texto`: 14px
  - `Legenda`: 12px
- **Pesos Disponíveis:** Regular, Medium, SemiBold, Bold.

## 3. Espaçamentos (Grid de 8px)
Sempre usar os múltiplos definidos em `spacing.dart`.
- `4px`, `8px`, `16px`, `24px`, `32px`, `48px`, `64px`
- *Proibido uso de valores arbitrários (ex: 13, 27).*

## 4. Bordas e Arredondamento (Radius)
Os cantos dos elementos nunca devem ser quadrados perfeitos.
- **Inputs:** 12px
- **Botões:** 12px
- **Cards:** 16px
- **Dialogs:** 24px

## 5. Sombras
Apenas 3 níveis de profundidade são permitidos, definidos em `shadows.dart`.
- `Shadow Small`: Sombra leve para elementos interativos (cards ao passar o mouse).
- `Shadow Medium`: Sombra média para botões e cards destacados.
- `Shadow Large`: Sombra pesada para modais, dialogs e overlays.

## 6. Ícones
- Apenas ícones delineados da biblioteca **Material Symbols Outlined**.

## 7. Estruturas Padronizadas
- **Telas:** Título e Descrição no topo -> Filtros, Busca e Ações Primárias logo abaixo -> Conteúdo Centralizado/Tabela -> Paginação no rodapé.
- **Dialogs:** Ícone -> Título -> Descrição -> (Campos/Tabelas) -> Ações (Cancelar | Salvar).
- **Tabelas:** Cabeçalho cinza claro, ações na última coluna, hover nas linhas, sem uso de listas desorganizadas.
- **Formulários:** Label acima do input (nada de floating labels). Indicação clara de obrigatório (`*`) e `(opcional)`.
- **Botões por Seção:** Apenas **UM** botão primário em destaque por tela/seção principal. O restante deve ser secundário, tonal ou outline.

## 8. Arquitetura do Design System no Código
Todos esses tokens estão na pasta `lib/design_system/`.
Antes de estilizar qualquer tela manualmente, reutilize os componentes de `lib/design_system/components/`. Se não existir um componente para sua necessidade, **crie-o** dentro do Design System antes de usá-lo na tela. Nunca duplique código visual.
