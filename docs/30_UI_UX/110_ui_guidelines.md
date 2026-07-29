---
Title: UI Guidelines
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# UI & UX Visual Engineering Guidelines — FINCORE Platform

> **Document ID**: 110  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento rege os padrões de engenharia visual, layouts responsivos, micro-interações, atalhos globais de acessibilidade e estados de resposta para todos os produtos da FINCORE Platform (Food, Finance, CRM, etc.).

---

## 1. Grid e Espaçamentos

Adotamos um sistema de espaçamento linear de **8dp** (Base-8 Grid) para consistência visual geométrica.

### Escala de Espaçamento (Padding & Margins):
* **4dp** (`xxs`): Pequeno ajuste, separação interna de elementos de tags.
* **8dp** (`xs`): Espaçamento interno padrão de elementos agregados.
* **16dp** (`sm`): Margem interna padrão de cartões e blocos pequenos.
* **24dp** (`md`): Margem interna padrão de seções, painéis e formulários amplos.
* **32dp** (`lg`): Espaçamento externo de grandes layouts e containers masters.
* **48dp** (`xl`): Separação entre grandes blocos de layout de página.

---

## 2. Responsividade e Breakpoints

Para garantir que o software seja operado confortavelmente tanto em tablets no balcão quanto em monitores desktop Full HD, definimos três faixas de Breakpoints:

* **Compact / Mobile** (`< 600dp`):
  * Oculta a Sidebar padrão (substitui por Gaveta Hambúrguer).
  * Painel de carrinho e catálogo são empilhados verticalmente.
* **Medium / Tablet** (`600dp - 1024dp`):
  * Sidebar encolhida para exibição de ícones apenas.
  * O PDV Express exibe painéis lado a lado (`flex: 3` e `flex: 2`).
* **Expanded / Desktop** (`> 1024dp`):
  * Sidebar totalmente expandida com rótulos de texto de rotas.
  * Margem de página de `24dp` com grids de produtos em 3 ou 4 colunas.

---

## 3. Estados Vazios (Empty States)

Um estado vazio nunca deve ser apenas um aviso textual passivo. Ele deve incentivar a ação operacional imediata.

### Padrão de Componente:
1. **Ícone Temático**: Desenho vetorial sutil na cor cinza escuro (`#4B5563`).
2. **Título Curto**: Texto de status direto em negrito.
3. **Subtexto Explicativo**: Explica o motivo do estado vazio (ex: "Sem pedidos pendentes no painel de cozinha hoje").
4. **Call to Action (CTA)**: Botão de ação (se aplicável) em Laranja Forno (`#F97316`) ou Cyan (`#06B6D4`) para iniciar o fluxo (ex: "Identificar Cliente" ou "Adicionar Produto").

---

## 4. Carregamento Assíncrono (Skeleton & Shimmers)

Evitamos spinners circulares intrusivos que dão sensação de lentidão ao usuário. Em vez disso, usamos animações Shimmer (esqueleto) que imitam a forma real do componente carregado:

* **Tabelas / Listas**: Linhas cinzas suaves em pulso de gradiente horizontal com ciclo de opacidade de `1.5s`.
* **Cards de Produto**: Blocos retangulares de esqueleto estático que desaparecem por fade-in assim que os dados são processados.

---

## 5. Modais e Toasts (Políticas de Diálogo)

### Modais:
* **Foco**: O fundo deve aplicar Backdrop Filter com desfoque de `5px` (`ImageFilter.blur`).
* **Estrutura**: Botão de ação principal sempre à direita (destacado). Botão de fechar ou cancelar à esquerda em outline neutro.
* **Contingência**: Modais de bloqueio operacional (ex: Aguardando PIX) devem obrigatoriamente conter atalhos para forçar saída ou contornar falta de sinal em caso de emergência.

### Toasts / Snacks:
* **Notificação de Sucesso**: Fundo verde esmeralda (`#10B981`) com tempo de duração de `4s`.
* **Undo (Desfazer)**: Toasts de transição operacional (ex: marcar pedido como pronto) devem prover uma ação explícita de `DESFAZER` no canto direito.
* **Notificação de Erro**: Fundo vermelho carmim (`#EF4444`) com duração fixa de `6s` e opção de re-execução inline.

---

## 6. Atalhos Globais de Teclado (Acessibilidade Operacional)

Todo o fluxo transacional primário deve ser operado sem toques no mouse para garantir velocidade para a persona Maria:

* `F1`: Abre e foca a barra de pesquisa de catálogo.
* `F2`: Abre diálogo de identificação rápida de cliente (Nome / Telefone).
* `F3`: Foca no carrinho e avança para a aba de formas de pagamento.
* `F9`: Aciona re-impressão rápida de cupons da cozinha ou caixa.
* `F12`: Confirma a transação ativa (fecha venda / inicia lote).
* `ESC`: Cancela o modal corrente ou limpa o carrinho ativo, retornando o foco principal para a escuta de atalhos.

---

## 7. Padrão de Componentes Visuais

### Tabelas:
* **Cabeçalho**: Fundo plano escuro com texto cinza (`#9CA3AF`) em caixa alta e tamanho `11dp`.
* **Bordas**: Linhas divisórias horizontais sutis de 1px (`#1E1E24`).
* **Interatividade**: Hover visual alterando a cor da linha de fundo para `#1E1E24` (Shade de destaque).

### Formulários:
* **Espaçamento**: Altura fixa de inputs de `48dp` com fontes nítidas.
* **Borda de Foco Ativo**: Borda de `2px` em Laranja Forno (`#F97316`) que pulsa levemente ao receber foco, garantindo contraste para Maria.
* **Mensagens de Validação**: Texto descritivo em vermelho carmim abaixo do input, com tremor horizontal dinâmico (Shake) se submetido incorretamente.
