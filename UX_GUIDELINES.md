# Diretrizes de Experiência do Usuário (UX Guidelines) — SnackFlow / SalgadoERP

Este documento define os padrões visuais e comportamentais para o desenvolvimento de qualquer tela ou funcionalidade do ERP.

---

## 🎨 1. O Alinhamento Visual (Hierarquia)
- **Top Bar Alignment:** O título e a descrição de qualquer tela devem ficar no topo absoluto, respeitando apenas a margem padrão (EdgeInsets.fromLTRB(32, 0, 32, 32)). Não centralize conteúdos verticalmente na tela se a página estiver com poucos itens.
- **Estruturação por Módulos:** O menu lateral organiza a navegação em blocos lógicos:
  - **Comercial:** Relacionado à entrada de dinheiro e vendas (Dashboard, Pedidos, Clientes, Produtos).
  - **Operação:** Relacionado à entrega e produção (Estoque, etc.).
  - **Sistema:** Configurações globais.

---

## 📦 2. Exibição de Dados e Contexto
- **Sempre Mostre Métricas (Counters):** Antes de listar itens em qualquer tela, exiba contadores rápidos no topo (ex: "X produtos cadastrados", "Y sem estoque").
- **Empty States Inteligentes:** Nunca mostre apenas uma tabela ou lista vazia. Se não houver dados:
  - Exiba um ícone ilustrativo adequado.
  - Insira um texto claro explicando o que é aquela tela.
  - Forneça um botão de ação rápida (CTA) para o usuário criar seu primeiro registro.

---

## 🧾 3. Formulários e Dialogs
- **Organização por Seções (Sections):** Em diálogos de cadastro, agrupe campos em seções lógicas com bordas leves ou cards (ex: "Dados Pessoais", "Endereço").
- **Tamanho Controlado:** Evite diálogos gigantescos. Use abas ou seções roláveis.

---

## ⚡ 4. Fluxo de Vendas (Novo Pedido)
- **Stepper Horizontal:** Reduza a fadiga de decisão dividindo o fechamento de pedidos em etapas sequenciais guiadas:
  - ① Cliente → ② Produtos → ③ Entrega → ④ Pagamento → ⑤ Confirmar.
- **Seleção Rápida:** Substitua o campo de autocompletar por um catálogo visual no formato Grid/Wrap de produtos, onde a quantidade é alterada com simples cliques em botões de `+` e `-`.
