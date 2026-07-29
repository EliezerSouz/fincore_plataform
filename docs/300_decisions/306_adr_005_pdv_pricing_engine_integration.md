# ADR-005: Integração do PDV ao Módulo Fincore Pricing & Fim de Preços Hipotéticos

> **Document ID**: 306  
> **Version**: 1.0.0  
> **Status**: APPROVED  
> **Owner**: Principal Architect / POS & Pricing Team  
> **Contexto**: Eliminação de valores hardcoded/hipotéticos na tela de ponto de venda (`PdvPage`) e desacoplamento de precificação via módulo `fincore_pricing`.

---

## 1. Contexto

Durante a evolução do PDV Express e do Catálogo do PDV (`PdvPage`), identificou-se que o cálculo inicial de preços utilizava lógica com valores fallback em código (`_calculaPrecoBaseProduto` com retornos estáticos como `120` ou `450` centavos dependendo de strings no nome do produto).

Esta prática entra em conflito com o princípio do **FINCORE FPOS** de trabalhar estritamente com **dados reais e confiáveis** ("nada de dados fictícios ou preços inventados"). Além disso, o operador do PDV precisava lidar com um seletor redundante de tabelas no topo do catálogo que ocupava espaço visual na barra de busca rápida.

---

## 2. Decisão Tomada

1.  **Consulta Exclusiva via Módulo `fincore_pricing`:** O PDV passa a ler os preços unitários reais (em centavos) diretamente através de `ProdutoTabelaPrecificacaoRepository` e `ItemTabelaPrecificacaoRepository`.
2.  **Proibição de Preços Hipotéticos:** Caso um produto não possua preço cadastrado na tabela ativa, o método `_calculaPrecoBaseProduto(Produto prod)` deve retornar o valor real do mapa `_precosProdutosCentavos[prod.id] ?? 0` sem aplicar valores fictícios por adivinhação de nome.
3.  **Simplificação Visual da Barra Superior (UI):** O seletor de tabela de preço foi removido do topo da lista do PDV em prol da expansão do campo de busca inteligente por nome, código interno ou leitor de código de barras.

---

## 3. Justificativa Técnica (Prós e Contras)

### 3.1 Vantagens (Prós)
*   **Acurácia Financeira 100%:** Garante que o valor exibido e cobrado no PDV seja exatamente o valor estipulado pela gestão corporativa no módulo de precificação.
*   **Consistência Multi-Canal:** Pedidos de balcão, entregas e pedidos online compartilham a mesma fonte única da verdade (`ItemTabelaPrecificacao`).
*   **Eficiência Operacional:** O operador ganha mais agilidade com um campo de pesquisa desobstruído na tela principal do PDV.

### 3.2 Desafios (Contras e Mitigações)
*   **Dependência de Cadastro Prévio:** Produtos recém-criados no catálogo precisam ter seu preço atribuído no módulo de precificação antes de serem vendidos com valor superior a R$ 0,00. Mitigado por alertas de precificação na tela de cadastro de produtos.

---

## 4. Consequências e Conformidade FPOS

*   Qualquer nova interface de venda (PDV Mobile, Autoatendimento, Kiosk) deve consumir obrigatoriamente as tabelas de `fincore_pricing`.
*   É terminantemente proibido inserir `if (nome.contains('...')) return PRECO_HIPOTETICO;` em qualquer camada de apresentação da plataforma.
