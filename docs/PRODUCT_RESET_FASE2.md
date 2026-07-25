# PRODUCT RESET 1.0 — FASE 2 (REVISÃO FINAL)
## UX, Personas, Jornadas Operacionais e Comportamento de Interface

**Comitê**: Product Officer · Software Architect · CTO SaaS · UX Architect · Especialista ERP · Especialista Produção Alimentícia · Especialista PDV · Especialista Flutter

**Data**: 2026-07-25
**Revisão**: Final — Fase 2 congelada
**Status**: ✅ APROVADO — Documento Mestre — Fase 2 de 5

---

# PARTE 1 — PERSONAS OPERACIONAIS

* **Maria (Atendente, 24 anos)**: Atende clientes presenciais no balcão ao mesmo tempo em que responde mensagens no WhatsApp. Opera em um ambiente barulhento. Precisa faturar pedidos sem tirar a mão do teclado numérico.
* **Thiago (Cozinheiro, 32 anos)**: Trabalha em ambiente quente, úmido e com mãos ocupadas (farinha/óleo). Visualiza o monitor a 2 metros de distância. Precisa de fontes grandes e botões touch gigantes (clicáveis com a lateral da mão).
* **Cleiton (Entregador, 29 anos)**: Passa o dia na rua sob sol e chuva. Usa celular de baixo custo montado no guidão. Precisa de altíssimo contraste (outdoor mode) e ações rápidas de 1 clique para GPS e conciliação.
* **Seu João (Dono, 45 anos)**: Audita a operação remotamente. Precisa de visualização rápida do fluxo de caixa e alertas de estoque de qualquer lugar via celular/tablet.

---

# PARTE 2 — JORNADA DO PEDIDO INTEGRADA (Omnichannel Flow)

O sistema possui uma **espinha dorsal transacional única** alimentada por múltiplos canais de venda (Omnichannel). O canal é apenas o adaptador; o domínio comercial processa a transação de forma idêntica.

```
[ CANAL DE ORIGEM ]
  ├── PDV Express (Atendente digita atalhos locais)
  ├── Portal Web do Cliente (Cliente faz o self-checkout)
  ├── Agente de IA WhatsApp (Conversação interpretada e confirmada)
  └── API de Integração (iFood, marketplaces, APIs de parceiros)
            │
            ▼
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

# PARTE 3 — INTERACTION PRINCIPLES (Princípios de Interação)

Estes princípios regem a consistência de como o software responde ao operador. Devem ser respeitados em qualquer fluxo.

### 3.1 Confirmations (Ações Destrutivas)
* Toda ação crítica (ex: deletar item do carrinho, remover cliente, cancelar lote) exige confirmação inline ou modal focado. O botão de ação é sempre em vermelho carmim.

### 3.2 Undo Pattern (Ações Irreversíveis)
* Ações de fluxo (ex: concluir um lote de produção por engano, marcar pedido como entregue erroneamente) exibem um **Toast Banner temporário** com a opção `Desfazer (Undo)` antes de persistirem de forma inalterável no banco.

### 3.3 Async Progress (Processamentos Longos)
* Ações de fluxo curto (< 500ms) mostram spinner inline dentro do botão. Ações longas (> 500ms) usam overlay translúcido bloqueante.

### 3.4 Offline Indicators (Transparência de Rede)
* Um **badge de conectividade** no cabeçalho exibe:
  * Verde estável: `Conectado`
  * Amarelo: `Sincronizando (X pendentes)`
  * Vermelho estável: `Modo Local (Offline)`

### 3.5 Error Recovery (UX de Resolução de Erros)
* Todo erro deve exibir o que aconteceu (em linguagem operacional simples), o impacto e o botão de ação corretiva imediata.

### 3.6 Keyboard Navigation Guidelines (Navegação por Teclado)
* O PDV Express deve ser operável 100% via teclado numérico + teclas de função (`F1` a `F12`).
* Borda de contraste de `2px` em Laranja Forno no elemento focado.
* Teclas universais: `Enter` (confirma/avança), `Esc` (cancela/fecha), `Setas` (navega em tabelas/buscas).

### 3.7 Action Placement Consistency (Posicionamento de Ações)
* Botões de ação primária (Avançar, Salvar, Confirmar) ficam **sempre no canto inferior direito**.
* Botões de ação secundária (Voltar, Cancelar) ficam **sempre à esquerda** do botão primário.

### 3.8 Standard Timings (Prazos Padrão de Componentes)
* **Toasts Informativos / Alertas**: `4 segundos` (desaparece automaticamente).
* **Toasts com Ação de Undo**: `6 segundos` (tempo ideal para arrependimento sem travar o fluxo).
* **Banners de Erro de Conexão / Falhas**: `Persistentes` (só desaparecem quando o erro é resolvido ou o operador clica no botão "Fechar [x]").

---

# PARTE 4 — MOTION GUIDELINES (Diretrizes de Animação)

As animações no sistema servem como sinalizadores funcionais de estado.

* **Pulse (Urgência)**: Badges de estoque crítico ou pedidos atrasados. Loop contínuo de opacidade (0.4 a 1.0) a cada 1.5 segundos.
* **Shake (Validação)**: Formulários vazios ou atalhos inválidos. Tremor horizontal sutil de 200ms.
* **Slide (Navegação)**: Transição lateral para a entrada de novas páginas ou workspaces (300ms).
* **Fade (Componentes)**: Componentes dinâmicos aparecendo/desaparecendo inline (150ms).
* **Shimmer/Skeleton (Carregamento)**: Blocos cinza pulsantes simulando o formato dos dados até a query terminar.

---

# PARTE 5 — STATE DESIGN (Design de Estados)

Telas não são estáticas. Mapeamos as variações estruturais de interface para os três workspaces principais.

## 5.1 Workspace Atendente: PDV Express
* **Vazio**: Sem itens. Foco no campo do cliente. Ilustração indicando: `Pressione F1 para iniciar`.
* **DigitandoCliente**: Campo de texto com borda ativa. Autocomplete ativo buscando dígitos numéricos.
* **ClienteEncontrado**: Exibe resumo do cliente, endereço principal selecionado e atalho F2 piscando suavemente.
* **InserindoItens**: Foco no campo Produto. Grade do carrinho atualizada com scroll automático para o último item adicionado.
* **AguardandoPIX**: Exibição do QR Code centralizado com timer regressivo de 120s e spinner de progresso linear.
* **ErroPIX**: Banner vermelho: `Confirmação de pagamento expirou. [Tentar novamente] [Confirmar Manualmente]`.
* **SucessoVenda**: Overlay verde de 1.5s indicando `Pedido faturado e impresso com sucesso`. Auto-limpeza do carrinho.
* **ModoOffline**: Tarja superior vermelha permanente. Campo de PIX automático substituído por "PIX Manual (Maquininha)".

## 5.2 Workspace Cozinha: Painel de Preparo
* **FilaVazia**: Ilustração centralizada de forno limpo: `Sem pedidos pendentes para o período`.
* **DemandasDoDia**: Cards de pedidos agrupados por hora de entrega e ordenados por urgência SLA.
* **ProcessandoLote**: Timer de contagem regressiva gigante e barra de progresso do cozimento/fritura.
* **LoteConcluido**: Card do lote piscando em verde (Fade) aguardando o clique "Armazenar no Freezer".

## 5.3 Workspace Plataforma: Control Center
* **CarregandoConfiguracoes**: Skeletons simulando inputs em abas.
* **DesconexaoCloudBanner**: Tarja amarela no topo: `Servidor inacessível. Operando com configurações locais gravadas em [Timestamp]`.

---

# PARTE 6 — EXCEPTION FLOWS (UX de Exceção)

## 6.1 Queda de Conexão à Internet (Modo Local)
* Indicador de rede muda para `Modo Local (Offline)`.
* Emissão de pedidos e baixas no SQLite local continuam funcionando normalmente.
* PIX automático desabilitado. O sistema solicita PIX manual (maquininha física externa).
* Spooler local envia pedidos para a impressora física via cabo USB/Rede local.

## 6.2 Expiração de QR Code PIX (Timeout de Confirmação)
* Se ultrapassar 120s sem resposta do webhook do Serverpod, o sistema exibe banner de timeout.
* Permite `Re-gerar QR Code` ou `Confirmar Manualmente` (solicita confirmação visual do comprovante).

## 6.3 Cancelamento de Pedido na Linha de Produção (Estorno LIFO)
* Pedido cancelado pisca em vermelho com sinal sonoro na cozinha.
* Ao confirmar o cancelamento, o sistema devolve as quantidades físicas de insumos exatamente para o último lote de produção de onde saíram (**Algoritmo LIFO**), evitando contaminações na validade de lotes antigos do freezer.

## 6.4 Alteração de Endereço de Última Hora
* O atendente altera o endereço e o sistema recalcula a taxa de entrega.
* Se a diferença for positiva, gera cobrança incremental de PIX. Se for negativa, gera saldo de crédito.
* A etiqueta de expedição antiga é sinalizada como "CANCELADA" no sistema e uma nova etiqueta é impressa.

## 6.5 Conflito de Sincronização (Nuvem vs. Local)
* Se um pedido for modificado de formas conflitantes localmente e na nuvem ao mesmo tempo, aplica-se a política de resolução de conflitos ativa para aquele domínio.

## 6.6 Políticas de Resolução de Conflitos (Conflict Resolution Policies)

| Política | Regra de Resolução | Aplicação Recomendada |
|---|---|---|
| **Policy A: Operação Vence** | As alterações feitas localmente no PDV/Cozinha física prevalecem sobre a nuvem (para evitar perda de insumos já preparados). | Status de pedidos, estoque físico. |
| **Policy B: Financeiro Vence**| Mutações financeiras confirmadas e conciliadas pelo servidor (ex: PIX recebido na API) nunca podem ser revertidas localmente. | Pagamentos, fluxo de caixa. |
| **Policy C: Servidor Vence** | O estado canônico gravado no banco de dados na nuvem sobrescreve o banco local em caso de conflito de dados mestres. | Catálogo de produtos, faixas de preço. |
| **Policy D: Última Escrita Vence**| O registro com o timestamp (`atualizadoEm`) mais recente é o gravado, independente de onde veio. | Cadastro de clientes, endereços. |
| **Policy E: Resolução Manual** | O sistema exibe um diálogo de conciliação manual para o operador escolher qual versão salvar. | Casos críticos de cadastro duplo de usuários. |

## 6.7 Matriz de Recuperabilidade de Exceções

| Evento de Falha | Impacto | Tipo de Recuperação | Ação do Usuário | Auditoria de Logs |
|---|---|---|---|---|
| **Queda de Conexão** | Bloqueio de sync cloud | **Automática** (reconecta) | Nenhuma (operação continua local) | `INFO [Sync] Queda detectada` |
| **Falha de Impressão**| Perda do cupom físico | **Manual** | Clicar em "Reimprimir Pedido [F9]" | `WARN [Print] Erro de spooler` |
| **Erro PIX Timeout** | Sem confirmação | **Híbrida** | Re-gerar QR Code ou confirmar manual | `EVENT [Pay] Confirmação manual` |
| **Falta de Insumo** | Produção bloqueada | **Manual** | Iniciar lote de emergência na cozinha | `ALERT [Stock] Estoque abaixo min` |
| **Conflito de Sync** | Dados divergentes | **Automática** (por Policy) | Nenhuma (ou decisão via modal manual)| `CONFLICT [Sync] Resolvido via Policy` |

---

# PARTE 7 — WIREFRAME ESTRUTURAL DO PDV EXPRESS

```text
+-----------------------------------------------------------------------------------+
| [!] WORKSPACE ATENDENTE - PDV EXPRESS                      [ Persona Ativa: Dono ]|
+-----------------------------------------------------------------------------------+
|  [F1] CLIENTE (Telefone ou Nome)                                                  |
|  [ 11999999999                  ]  [+] Cadastrar Rápido                           |
|  ↳ Cliente: Maria Souza (Endereço: Centro - Principal)                            |
+-----------------------------------------------------------------------------------+
|  [F2] PRODUTO                                              QUANTIDADE             |
|  [ Coxinha de Frango            ]                          [ 100        ] [Add]   |
|  ↳ Valor Unitário: R$ 0,80 (Aplicado 20% desconto de faixa para >50 un)           |
+-----------------------------------------------------------------------------------+
|  CARRINHO DE ITENS (Foco Teclado)                                                 |
|  1. 100x Coxinha de Frango (R$ 0,80 un) ............................. R$  80,00   |
|  2. 50x Bolinha de Queijo (R$ 0,90 un) .............................. R$  45,00   |
|                                                                                   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
|  DETALHES DE ENTREGA                                                              |
|  Tipo: [x] Entrega  [ ] Balcão  [ ] Consumo Local                                 |
|  Agenda: Data [ 25/07/2026 ] Hora [ 18:00 ]                                       |
|  Endereço: [ Principal (Rua das Flores, 123 - Centro)                    ] [v]    |
|  [ ] Salvar Endereço Manualmente como: [ Casa / Trabalho ]                        |
+-----------------------------------------------------------------------------------+
|  PAGAMENTO E RESUMO                                                               |
|  Forma: [x] PIX  [ ] Dinheiro (Troco para: [      ])  [ ] Cartão                  |
|                                                                                   |
|  Subtotal: R$ 125,00    Taxa de Entrega: R$ [ 15,00 ]    TOTAL: R$ 140,00         |
+-----------------------------------------------------------------------------------+
|  [F12] FINALIZAR E IMPRIMIR (Registra pedido localmente e gera QR Code PIX)        |
+-----------------------------------------------------------------------------------+
```

---

# PARTE 8 — WIREFRAME ESTRUTURAL DO CONTROL CENTER

```text
+-----------------------------------------------------------------------------------+
| [⚙️] CONTROL CENTER (Configurações Gerais da Plataforma)                           |
+-----------------------------------------------------------------------------------+
| [ Abas Horizontais: ]                                                             |
| [ 🏢 Empresa ] [ 👥 Operação ] [ 💳 Cobrança ] [ 🚚 Logística ] [ 🔄 Plataforma ] |
+-----------------------------------------------------------------------------------+
|  ABA SELECIONADA: [ 👥 Operação ]                                                 |
|                                                                                   |
|  USUÁRIOS E PERFIS:                                                               |
|  [+] Novo Usuário      [+] Novo Perfil                                            |
|                                                                                   |
|  Lista de Operadores Cadastrados:                                                 |
|  - João Silva (Perfil: Dono) ----------------------------- [Editar] [Remover]     |
|  - Maria Souza (Perfil: Atendente) ----------------------- [Editar] [Remover]     |
|  - Thiago Costa (Perfil: Cozinha) ------------------------ [Editar] [Remover]     |
|                                                                                   |
|  Configuração de Permissões para o Perfil Selecionado: [ Cozinha ]                |
|  [ ] Acessar Financeiro e Caixa                                                   |
|  [x] Visualizar Agenda de Produção                                                |
|  [x] Registrar Lotes de Produção                                                  |
|  [ ] Configurar Catálogo e Preços                                                 |
|  [x] Visualizar Estoque e MRP                                                     |
|                                                                                   |
|  Personas Temporárias (Simulação):                                                |
|  Permitir que o perfil [ Dono ] simule o Workspace: [x] Cozinha [x] Atendente     |
+-----------------------------------------------------------------------------------+
|                                                                      [ Salvar ]   |
+-----------------------------------------------------------------------------------+
```

---

# PARTE 9 — DESIGN SYSTEM VISUAL (Design Tokens)

* **Cores HSL**: Background `hsl(210, 20%, 98%)`, Primária Laranja Forno `hsl(24, 95%, 50%)`, Sucesso `hsl(142, 70%, 35%)`, Alerta `hsl(0, 85%, 45%)`.
* **Tipografia**: `display-1` (32px, Bold), `heading-1` (24px, SemiBold), `body-primary` (14px, Regular).
* **Grid**: Espaçamento múltiplo de `8px`. Grid Desktop: 12 colunas (gutter 24px). Grid Mobile: 4 colunas (gutter 16px).

---

# PARTE 10 — ACCESSIBILITY OPERACIONAL (Acessibilidade Física)

Acessibilidade em ERP de alimentos foca no ambiente adverso da cozinha e do balcão.

1. **Modo Cozinha (Visualização à Distância)**:
   * Fontes com aumento de 150% (mínimo `24px` para listagens comuns). Contraste WCAG AAA (`7:1`).
   * Botões de checklist com área ativa (padding interno) de pelo menos `64px` para toques rápidos.

2. **Modo Sol / Outdoor (Celular do Entregador)**:
   * Paleta 100% monocromática sob luz solar intensa (fundo branco puro, bordas pretas grossas e texto preto absoluto). Desativação de gradientes ou sombras.

3. **Modo Luva / Touch**:
   * Elementos clicáveis têm espaçamento livre de interferência (margin) de no mínimo `16px`.
   * Bloqueio contra duplos-cliques acidentais (debouncing de `500ms` in nível de widget).

4. **Alertas Sonoros**:
   * Sucesso / Leitura de item: Bip curto e agudo (800Hz, 100ms).
   * Erro / Alerta Crítico: Som duplo grave (250Hz, 300ms).

---

# PARTE 11 — RESPONSIVE LAYOUT STRATEGY (Estratégia de Layout)

O ERP é adaptativo por contexto de dispositivo:
* **TV Cozinha (1920x1080)**: Modo Grade Kanban estático (sem scroll horizontal). Cartões expandidos com contagem regressiva gigante.
* **PDV Desktop (1024x768+)**: Layout fixo em duas colunas (Carrinho à direita fixo). Foco no inputs de teclado. Sem menus colapsáveis.
* **Tablet (10")**: Layout híbrido. Menus retráteis por gesto (swipe). Grid de botões touch para seleção de produtos rápidos.
* **Smartphone (Entregador)**: Layout coluna única. Botões persistentes na base. Foco na geolocalização e botão de ligar para o cliente.

---

# PARTE 12 — CLASSIFICAÇÃO DE SEVERIDADE DE NORMAS (Norms Criticality)

Para guiar revisões de arquitetura e código, as regras deste documento e dos princípios são classificadas por severidade:

| Nível de Severidade | Impacto no Desenvolvimento | Exemplos de Regras |
|---|---|---|
| **🔴 Critical (Crítico)** | **Inviolável**. Violação impede compilação ou reprova automaticamente o PR em nível arquitetural. Sem exceções. | - Operação 100% offline estável.<br>- Isolamento estrito de TenantId em todas as tabelas.<br>- Zero perda de dados locais antes da transação Drift. |
| **🟠 Strong (Forte)** | **Muito Recomendado**. Alteração de comportamento exige discussão e aprovação formal via Architecture Decision Record (ADR). | - Confirmação temporária de Undo de 6 segundos.<br>- Padrão de cores HSL e fontes legíveis para o Modo Cozinha.<br>- Posição consistente de botões primários no canto inferior direito. |
| **🟡 Recommended (Sugerido)**| **Flexível**. Pode variar de acordo com o contexto visual, criatividade de UX ou feedback do cliente local. | - Tempos padrão de toasts informativos de 4 segundos.<br>- Layout ASCII exato da ordem dos elementos de input do PDV Express. |

---

# PARTE 13 — UI CONTRACTS (Contratos de Interface)

Definição estrita das transições do sistema por Workspace:

### 13.1 Workspace Atendente: PDV Express
* **Estado**: `AguardandoPIX`
  * **Evento Disparador**: Confirmado envio de pedido via atalho F12.
  * **Ação Executada**: Bloqueia inputs, exibe modal do QR Code e escuta o stream do webhook do gateway do Serverpod.
  * **Feedback Visual/Sonoro**: Spinner de progresso circular. Som curto de geração bem-sucedida.
  * **Exceção de Falha**: Timeout da API após 120 segundos.
  * **Estratégia de Recuperação**: Exibe botões `Re-gerar QR Code` ou `Confirmar Manualmente` (libera transição manual).

### 13.2 Workspace Cozinha: Painel de Preparo
* **Estado**: `ProcessandoLote`
  * **Evento Disparador**: Clique no botão gigante "Iniciar Preparo do Lote".
  * **Ação Executada**: Registra lote localmente com `ativo = true` e inicia contagem regressiva baseada no tempo do produto.
  * **Feedback Visual/Sonoro**: Timer regressivo centralizado. Barra de progresso linear.
  * **Exceção de Falha**: Cancelamento repentino do pedido associado na nuvem.
  * **Estratégia de Recuperação**: Alerta visual piscante em vermelho com bip duplo de erro. Transiciona o estoque local via LIFO de devolução.

---

# PARTE 14 — DESIGN REVIEW CHECKLIST (Checklist de Pull Request)

> [!IMPORTANT]
> **Checklist Obrigatório**: Toda Pull Request de interface deve responder afirmativamente a estes 10 itens antes de ser mesclada no branch de produção.

- [ ] **1. Única Pergunta**: A tela responde a apenas uma ação ou pergunta principal por vez?
- [ ] **2. Estado Offline**: O comportamento local caso a internet caia foi testado e o banner de conectividade atualiza?
- [ ] **3. Loading / Shimmer**: Existe indicador visual de carregamento para qualquer query assíncrona?
- [ ] **4. Empty State**: Telas sem dados possuem ilustrações de "estado vazio" com ação sugerida (ex: botão de cadastrar)?
- [ ] **5. Error UX**: Os fluxos de erro exibem causa amigável, impacto e botão de ação corretiva?
- [ ] **6. Undo**: Ações de exclusão/mudança de status exibem toast temporário com opção "Desfazer"?
- [ ] **7. Navegação Teclado**: É possível completar todo o fluxo operacional principal sem encostar no mouse?
- [ ] **8. Foco Visual**: O elemento ativo no teclado possui a borda contrastante de 2px Laranja Forno?
- [ ] **9. Touch Targets**: Todos os botões em telas touch têm área de clique mínima de 48x48dp (64x64dp na cozinha)?
- [ ] **10. Feedback Sonoro**: Os alertas críticos emitem os bipes correspondentes no ambiente físico?

---

*Fase 2 de UX & Operação — Eigent Platform*
