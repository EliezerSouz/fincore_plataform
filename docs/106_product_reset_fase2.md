# Comportamento de Interface: UX, Personas, Estados e Exceções (Fase 2)

> **Document ID**: 106  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento rege os padrões visuais, de animação (motion), navegação por teclado e fluxos de exceção de interface do FINCORE Food.

---

## 1. Personas e Cenários

* **Maria (Atendente, 24 anos)**: Opera o PDV no balcão sob pressa e barulho. Exige atalhos rápidos de teclado.
* **Thiago (Cozinheiro, 32 anos)**: Visualiza a tela a 2 metros de distância na cozinha quente/úmida. Exige fontes grandes e botões gigantes touch (Modo Cozinha).
* **Cleiton (Entregador, 29 anos)**: Celular de baixo custo sob luz solar intensa. Exige altíssimo contraste (Modo Sol/Outdoor).
* **Seu João (Dono, 45 anos)**: Acompanha métricas e audita o caixa remotamente via tablet/smartphone.

---

## 2. Jornada do Pedido Integrada (Omnichannel Flow)

O sistema possui uma espinha dorsal transacional única alimentada por múltiplos canais de venda (PDV, Web, WhatsApp, API):

```
┌────────────────────────────────────────────────────────┐
│           ① EMISSÃO DO PEDIDO (Estado: Criado)         │
├────────────────────────────────────────────────────────┤
│           ② FILA E PLANEJAMENTO (Estado: Pendente)      │
├────────────────────────────────────────────────────────┤
│           ③ PREPARO NA COZINHA (Estado: Em Preparo)    │
├────────────────────────────────────────────────────────┤
│           ④ EXPEDIÇÃO & CONFERÊNCIA (Estado: Pronto)   │
├────────────────────────────────────────────────────────┤
│           ⑤ ENTREGA LOGÍSTICA (Estado: Saiu p/ Entrega)│
├────────────────────────────────────────────────────────┤
│           ⑥ LIQUIDAÇÃO & CONCILIAÇÃO (Estado: Entregue)│
└────────────────────────────────────────────────────────┘
```

---

## 3. Interaction Principles (Diretrizes de Resposta Visual)

* **Confirmations**: Diálogos inline/modais claros para ações destrutivas (botão em vermelho carmim).
* **Undo Pattern**: Toast de 6s com opção `Desfazer (Undo)` para ações de transição de fluxo (ex: mudar status do pedido).
* **Offline Indicators**: Badge visível atualizando o estado de sync e conexão da internet.
* **Navegação por Teclado**: O PDV deve operar 100% por atalhos numéricos/função, com borda de foco de 2px Laranja Forno no elemento ativo.

---

## 4. Motion Guidelines (Sinalizadores de Feedback)
* **Pulse**: Urgências e alertas críticos (loop de opacidade 0.4 a 1.0 a cada 1.5s).
* **Shake**: Atalhos e inputs inválidos (tremor horizontal de 200ms).
* **Slide**: Entrada lateral de páginas e abas.
* **Fade**: Elementos dinâmicos inline (150ms).
* **Shimmer/Skeleton**: Carregamento assíncrono de tabelas e inputs.

---

## 5. UI Contracts (Estados de Transição)

### 5.1 Workspace Atendente: PDV Express
* **Estado**: `AguardandoPIX`
  * **Evento Disparador**: Confirmado envio de pedido via atalho F12.
  * **Ação Executada**: Bloqueia inputs, exibe modal do QR Code e escuta o stream do webhook do gateway do Serverpod.
  * **Feedback**: Spinner de progresso circular. Som curto de geração bem-sucedida.
  * **Timeout**: Sem resposta do webhook após 120s ➔ Transiciona para tela de erro.

### 5.2 Workspace Cozinha: Painel de Preparo
* **Estado**: `ProcessandoLote`
  * **Evento Disparador**: Clique no botão gigante "Iniciar Preparo do Lote".
  * **Ação Executada**: Registra lote localmente com `ativo = true` e inicia contagem regressiva baseada no tempo do produto.
  * **Feedback**: Timer regressivo centralizado. Barra de progresso linear.

---

## 6. Fluxos de Exceção e Políticas de Conflito

* **Queda de Conexão à Internet (Modo Local)**: Emissão e impressão thermal USB continuam funcionando. PIX dinâmico vira PIX manual com comprovante visual.
* **Algoritmo LIFO de Devolução**: Ao cancelar um pedido em preparo, devolve insumos exatamente para o último lote ativo, protegendo a validade FIFO dos lotes antigos.
* **Matriz de Resolução de Conflitos**:
  * *Policy A (Operação Vence)*: Lógica de status de lotes e cozinha prevalece localmente sobre a nuvem.
  * *Policy B (Financeiro Vence)*: Conciliação de caixa e pagamentos na API cloud nunca são revertidas localmente.
  * *Policy C (Servidor Vence)*: Catálogo de preços e dados mestres da nuvem sobrescrevem as tabelas locais.
  * *Policy D (Última Escrita Vence)*: Cadastros de clientes salvam o timestamp mais recente.
