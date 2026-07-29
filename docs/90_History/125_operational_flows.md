---
Title: 125 operational flows
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Fluxos Operacionais do FINCORE Food (Operational Flows)

> **Document ID**: 125  
> **Version**: 1.0.0  
> **Status**: ✍️ Ativo  
> **Criticidade**: **DOCUMENTO FUNDACIONAL NÃO NEGOCIÁVEL.** Todo roadmap, backlog, PRD de entidade, design de tela e caso de teste DEVE ser derivado dos fluxos abaixo. Nenhuma entidade, tabela ou endpoint deve ser criada antes do caso de uso correspondente ser especificado aqui.
>
> Este documento responde à pergunta fundamental do operador: **"Como eu uso este sistema para trabalhar?"**  
> Ele NÃO responde "quais tabelas existem" ou "quais packages existem" (esses assuntos pertencem a PRDs 100, 120, 121, etc).

---

## 🎯 Visão Estratégica

> O FINCORE Food é orientado a **processos de negócio completos**, não a entidades técnicas. Uma milestone só é considerada "entregue" quando uma **persona** (Atendente, Cozinheiro, Gestor, Entregador) consegue **executar do início ao fim** o seu fluxo operacional correspondente (abrir caixa até fechar venda, receber pedido até entregar, etc). Não existe mais a ideia de "entidade X pronta, sem tela". Se não há fluxo utilizável ponta a ponta, a milestone não está pronta.

---

## 👥 4 Personas Padrão (MVP Operacional)

Todo caso de uso abaixo deve ser interpretado do ponto de vista de UMA persona.

| ID | Persona | Papel na Operação | Localização Física | Principal Workstation |
|---|---|---|---|---|
| P1 | **Atendente / Caixa (Maria)** | Abre caixa, atende cliente, cadastra cliente rápido, monta pedido, recebe pagamento, emite cupom. | Balcão / Frente de Loja | Windows Desktop + TEF + Impressora ESC/POS 80mm |
| P2 | **Cozinheiro / Chefe (João)** | Visualiza fila de produção, inicia preparo, marca como pronto, cancela ordem com estorno, confere atrasos. | Cozinha / Produção | Tablet Android ou Desktop Windows em tela 10" modo cozinha 150% zoom |
| P3 | **Entregador (Carlos)** | Pega pedido pronto no balcão, confere itens com checklist, marca como "Saiu p/ Entrega", depois marca "Entregue" no endereço. | Rua / Entrega | Smartphone Android App (futuro) ou papel impresso (MVP) |
| P4 | **Gestor / Dono (Luiza)** | Abre/fecha caixa, cadastra produtos/clientes, configura preços, vê vendas do dia, ajusta estoque, planeja produção. | Escritório / Balcão | Windows Desktop |

---

## 🧭 REGRA NÃO NEGOCIÁVEL DE PERSPECTIVA

> **Cliente vem PRIMEIRO. Pedido vem DEPOIS.**
>
> O processo operacional NUNCA começa com "Criar um Pedido".  
> O processo operacional começa com "Abrir Caixa", depois "Identificar Cliente", depois "Selecionar Endereço".  
> O Pedido é uma consequência deste processo, não o início dele.

❌ **Incorreto (não usar mais como referência)**:
```
Criar Pedido
   ↳ Adicionar Cliente
   ↳ Adicionar Itens
```

✅ **Correto (todo o resto deste documento segue isto)**:
```
Abrir Caixa
   ↳ Selecionar Cliente (ou Cadastrar Rápido)
      ↳ Selecionar Local / Endereço
         ↳ Montar / Iniciar Venda
            ↳ Pedido criado automaticamente ao final
```

---

## 🔄 FLUXO 1 — FLUXO COMPLETO DE VENDA (Persona P1 — Atendente Maria)

**Objetivo**: Receber o cliente, atender do início ao fim, receber o pagamento, imprimir cupom e garantir que a cozinha recebeu o pedido.  
**Meta de SLA por operação**: ≤ 3 minutos por venda balcão, ≤ 8 minutos delivery.

```mermaid
flowchart TD
    A[1. LOGIN no Sistema<br>Maria digita PIN / senha] --> B[2. ABRIR CAIXA<br>Informa valor de fundo de troco<br>Status: Caixa Aberto]
    B --> C{3. SELECIONAR CLIENTE<br>Busca por nome / telefone}
    C -->|Cliente encontrado| D[4. ✓ Cliente Selecionado<br>Mostra histórico de compras e endereços cadastrados]
    C -->|Cliente NÃO existe| E[5. CADASTRO RÁPIDO DE CLIENTE<br>Nome + Telefone, 6 campos máximo<br>Sem sair do fluxo de venda]
    E --> D
    D --> F{6. SELECIONAR LOCAL / ENDEREÇO}
    F -->|Balcão / Retirada| G[7. ✓ Local = Balcão<br>Sem taxa de entrega]
    F -->|Delivery| H[8. Seleciona Endereço cadastrado<br>ou cadastra 1 novo rápido<br>Calcula taxa de entrega por bairro/CEP]
    G --> I[9. MONTAR PEDIDO<br>Adiciona produtos / quantidades / observações]
    H --> I
    I --> J[10. RESOLVER PREÇO AUTOMÁTICO<br>Pricing Engine: tabela, prioridade, vigência, canal, faixa]
    J --> K{11. FORMA DE PAGAMENTO}
    K -->|Dinheiro| L[Troco calculado]
    K -->|PIX| M[Gera QR Code PIX dinâmico<br>Aguarda confirmação (até 30s)]
    K -->|Cartão / TEF| N[Integração TEF / OU lançamento manual]
    L --> O[12. CONFIRMAR VENDA — TRANSAÇÃO ATÔMICA ÚNICA]
    M --> O
    N --> O
    O --> P[12a. ✅ Grava Pedido<br>12b. ✅ Grava ItensPedido<br>12c. ✅ Gera EventoPedido (CQRS imutável)<br>12d. ✅ Atualiza Caixa / Movimento Financeiro<br>12e. ✅ Reserva Estoque (Físico → Reservado)<br>12f. ✅ Publica OrdemPreparo na Fila KDS]
    P --> Q[13. IMPRESSÃO CUPOM ESC/POS<br>Cabeçalho Empresa + itens + total + cliente + endereço<br>Fallback %TEMP% se impressora offline]
    Q --> R[14. UNDO PATTERN 4 SEGUNDOS<br>Toast verde: Venda #XXXX confirmada<br>Botão DESFAZER — cancela tudo atomicamente caso Maria erre]
    R --> S((15. FIM))
    R --> T{Cliente pede alteração?}
    T -->|Sim, clica DESFAZER| U[Desfaz TUDO: apaga Pedido / libera estoque / estorna caixa / remove do KDS / reimprime estorno]
    U --> C
```

### Checklist de Conclusão deste Fluxo (Definition of Done da Jornada Atendente)

- [ ] O Atendente consegue abrir o sistema e logar sem ajuda (PIN de 4 dígitos).
- [ ] Abrir caixa com valor de fundo de troco. Sessão de caixa aberta com usuário associado.
- [ ] Buscar cliente por nome OU telefone em < 2 segundos (índice + busca parcial).
- [ ] Cadastrar cliente RÁPIDO sem sair do fluxo de venda (6 campos no máximo: nome, telefone, endereço, bairro, numero, complemento).
- [ ] Selecionar entre Balcão / Retirada / Delivery. Mostrar taxa de entrega calculada automaticamente.
- [ ] Montar pedido com produtos, quantidades, observações. Preço atualiza em tempo real.
- [ ] Pagamento com Dinheiro (troco automático) OU Pix (QR dinâmico) OU Cartão.
- [ ] Confirmar venda com 1 atalho F12.
- [ ] Cupom impresso na impressora ESC/POS USB em < 2 segundos.
- [ ] Toast verde com DESFAZER aparece 4 segundos.
- [ ] Pedido aparece automaticamente no KDS do cozinheiro sem apertar "Sincronizar".
- [ ] Ao reiniciar o app, pedido continua lá (persistência real, não em memória).

---

## 🍳 FLUXO 2 — FLUXO DE PRODUÇÃO / KDS (Persona P2 — Cozinheiro João)

**Objetivo**: Pegar pedidos da fila, preparar, marcar como pronto, garantir que nenhum pedido se atrasou sem alerta visual.  
**Meta de SLA**: 100% das ordens têm timer visível; atraso > tempo estimado = alerta vermelho glow.

```mermaid
flowchart TD
    A[1. PEDIDO PUBLICADO DO FLUXO 1<br>Evento PedidoConfirmado → OrdemPreparo criada automaticamente] --> B[2. FILA KDS — COLUNA PENDENTE<br>Badge quantidade, ordem LIFO]
    B --> C{3. AÇÃO DO COZINHEIRO}
    C -->|Clica em INICIAR PREPARO| D[4. Ordem move p/ COLUNA EM PREPARO<br>Timer começa a contar<br>Status OrdemPreparo = emPreparo]
    C -->|Clica em CANCELAR ORDEM| E[5. CONFIRMAR CANCELAMENTO<br>Aviso: devolverá estoque LIFO automaticamente]
    E --> F[6. ✅ EventoPedido = Cancelado<br>✅ Liberação Reserva Estoque LIFO<br>✅ OrdemPreparo = cancelado<br>✅ KDS some da tela]
    F --> G((Fim))
    D --> H{7. TEMPO DECORRIDO vs ESTIMADO}
    H -->|Dentro do prazo| I[8. Timer azul / neutro]
    H -->|Atrasado > tempo estimado| J[9. Timer VERMELHO + GLOW + borda 3px<br>⚠️ Alerta visual]
    I --> K{10. Cozinheiro clica CONCLUIR}
    J --> K
    K --> L[11. Ordem move p/ COLUNA PRONTO<br>Status = pronto<br>Tempo total de preparo gravado]
    L --> M{12. Ação seguinte}
    M -->|Balcão Retirada| N[13. Avisa atendente: Pedido #XXXX pronto p/ retirada]
    M -->|Delivery| O[14. Fica na coluna Pronto até Entregador pegar]
    N --> P[15. Atendente entrega / marca como Retirado]
    O --> Q[16. Entregador marca Saiu para Entrega → depois Entregue (Fluxo 3)]
    P --> R((Fim do ciclo Produção))
    Q --> R
```

### Lista de Verificação do Fluxo 2

- [ ] Ao confirmar venda no Fluxo 1, ordem aparece na coluna Pendente do KDS em < 1 segundo (não precisa F5).
- [ ] Cozinheiro toca no botão INICIAR (64dp, dedo gordo gordura) e timer começa.
- [ ] Timer exibe mm:ss, e quando atrasa: borda vermelha 3px, sombra danger 10px, texto branco em fundo vermelho.
- [ ] Cancelar ordem abre modal de confirmação. Ao confirmar, estorna estoque automaticamente (LIFO).
- [ ] Concluir: move para coluna PRONTO. Gravado tempo de preparo no histórico.
- [ ] Ordem cancelada desaparece do KDS mas fica salva no histórico para auditoria.

---

## 💰 FLUXO 3 — FLUXO FINANCEIRO (Persona P4 — Gestora Luiza)

**Objetivo**: Registrar todos os pagamentos, produzir fechamento diário exato, com conciliação do caixa vs sistema, sem erro de 1 centavo.

```mermaid
flowchart TD
    A[1. PEDIDO CONFIRMADO PAGO (do Fluxo 1)<br>Transação atômica 12d] --> B[2. ENTRADA NO CAIXA<br>Registra LancamentoFinanceiro automático<br>Tipo = RECEITA / origem = PEDIDO / relaciona com pedidoId]
    B --> C[3. MOVIMENTAÇÃO FINANCEIRA<br>Forma de pgto: Dinheiro / PIX / Cartão / Outros<br>Valor em centavos (nunca float)]
    C --> D{4. TIPO DE LANÇAMENTO}
    D -->|Receita Venda| E[👍 Fluxo Caixa = ENTRADA]
    D -->|Estorno / Cancelamento| F[👎 Fluxo Caixa = SAÍDA<br>Gera lançamento negativo com mesmo pedidoId]
    D -->|Despesa Avulsa<br>(ex: compra gás, troco suplementar)| G[👎 Fluxo Caixa = SAÍDA avulsa<br>Luiza lança manualmente em tela Caixa]
    E --> H[5. FLUXO DE CAIXA EM TEMPO REAL<br>Saldo atual = Soma Receitas − Soma Saídas]
    F --> H
    G --> H
    H --> I[6. NO FIM DO DIA<br>Luiza clica em FECHAR CAIXA]
    I --> J[7. FECHAMENTO DIÁRIO<br>Gera Registro FechamentoCaixa com:<br>• Valor informado no sistema<br>• Valor contado físico por Luiza<br>• Diferença (arredondamento / faltante / sobra)<br>• Assinatura digital Luiza (PIN)]
    J --> K{8. Diferença?}
    K -->|R$ 0,00 fechou certinho| L[9. ✅ Status Fechamento = CONCILIADO]
    K -->|Diferença > R$ 0,01| M[10. ⚠️ Status = PENDENTE<br>Luiza justifica observação 200 caracteres<br>Marcado para auditoria gerencial]
    L --> N((11. Fim do dia))
    M --> N
```

---

## 📦 Casos de Uso Derivados (Backlog Priorizado por Fluxo)

Todo item de backlog DEVE ser derivado de um caso de uso abaixo. Nenhum ticket sem caso de uso.

### Casos de Uso do Fluxo de Venda (Atendente)

| ID | Caso de Uso | Persona | Prioridade MVP |
|---|---|---|---|
| CU-V01 | Abrir caixa com fundo de troco | P1 Atendente | MUST HAVE |
| CU-V02 | Fechar caixa com conferência | P1 / P4 | MUST HAVE |
| CU-V03 | Localizar cliente por nome / telefone | P1 | MUST HAVE |
| CU-V04 | Cadastrar cliente rápido (não sai do fluxo) | P1 | MUST HAVE |
| CU-V05 | Cadastrar cliente completo (tela separada) | P4 Gestor | MUST HAVE |
| CU-V06 | Editar cliente existente | P4 | SHOULD HAVE |
| CU-V07 | Selecionar Balcão vs Delivery | P1 | MUST HAVE |
| CU-V08 | Selecionar / cadastrar endereço entrega | P1 | MUST HAVE |
| CU-V09 | Adicionar / remover produto do pedido | P1 | MUST HAVE |
| CU-V10 | Alterar quantidade / observação item | P1 | MUST HAVE |
| CU-V11 | Resolver preço automaticamente | P1 (automático) | MUST HAVE |
| CU-V12 | Pagamento em Dinheiro + Troco | P1 | MUST HAVE |
| CU-V13 | Pagamento PIX QR Code dinâmico | P1 | MUST HAVE |
| CU-V14 | Pagamento Cartão / TEF (integração) | P1 | SHOULD HAVE |
| CU-V15 | Confirmar Venda (transação atômica 7 passos) | P1 | MUST HAVE |
| CU-V16 | Imprimir Cupom ESC/POS | P1 | MUST HAVE |
| CU-V17 | Desfazer venda (Undo Pattern 4s) | P1 | MUST HAVE |
| CU-V18 | Cancelar venda já confirmada (estorno) | P4 | MUST HAVE |

### Casos de Uso do Fluxo Produção (Cozinheiro)

| ID | Caso de Uso | Persona | Prioridade |
|---|---|---|---|
| CU-K01 | Visualizar ordens pendentes | P2 Cozinheiro | MUST HAVE |
| CU-K02 | Iniciar Preparo de Ordem | P2 | MUST HAVE |
| CU-K03 | Concluir Preparo de Ordem | P2 | MUST HAVE |
| CU-K04 | Cancelar Ordem com Estorno LIFO | P2 / P4 | MUST HAVE |
| CU-K05 | Timer visível e alerta atraso | P2 | MUST HAVE |
| CU-K06 | Prioridade normal/urgente/vip/programado | P2 | SHOULD HAVE |

### Casos de Uso do Fluxo Financeiro (Gestor)

| ID | Caso de Uso | Persona | Prioridade |
|---|---|---|---|
| CU-F01 | Ver saldo do caixa em tempo real | P1 / P4 | MUST HAVE |
| CU-F02 | Lançar despesa avulsa (diversas) | P4 | SHOULD HAVE |
| CU-F03 | Fechamento Diário com conferência | P4 | MUST HAVE |
| CU-F04 | Justificar diferença de caixa | P4 | SHOULD HAVE |
| CU-F05 | Listar lançamentos do dia / filtro por forma pgto | P4 | MUST HAVE |

---

## 🔗 Relação com os Outros PRDs

| PRD | Relação com o 125 |
|---|---|
| [100 Core Architecture](file:///f:/Eigent/fincore_platform/docs/100_platform_core_architecture.md) | Camadas técnicas (camadas) ← 125 diz quais jornadas passarão por estas camadas. |
| [105 Product Reset Fase 1](file:///f:/Eigent/fincore_platform/docs/105_product_reset_fase1.md) | Capabilities high level ← 125 materializa as capabilities em casos de uso. |
| [108 Milestones](file:///f:/Eigent/fincore_platform/docs/108_product_reset_fase4.md) | Roadmap por milestones técnicas ← **DEVE SER REESTRUTURADO** usando os Fluxos 1, 2, 3 como unidade de entrega. |
| [110 UI Guidelines](file:///f:/Eigent/fincore_platform/docs/110_ui_guidelines.md) | Aplica transversalmente nos fluxos 1, 2 e 3. |
| 120 Config / 121 Pricing / 122 Engine | Implementam os "blocos" internos (Cliente / Preço) que os Fluxos consomem. |
| [091 DoD](file:///f:/Eigent/fincore_platform/docs/091_definition_of_done.md) | Checklist técnico que complementa o Checklist de Jornada deste PRD 125. |

---

*Fim do Documento PRD-125 Fluxos Operacionais — Status Ativo 1.0.0*
