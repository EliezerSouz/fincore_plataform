# ADR-006: Gestão Multi-Endereços, Taxas por Bairro e Agendamento de Delivery

> **Document ID**: 307  
> **Version**: 1.0.0  
> **Status**: APPROVED  
> **Owner**: Principal Architect / Delivery & Logistics Team  
> **Contexto**: Suporte a endereços adicionais de clientes, autoseleção inteligente de frete e agendamento temporal de entregas.

---

## 1. Contexto

No segmento de alimentação (Fincore Food - Salgaderia / Delivery), um mesmo cliente frequentemente solicita pedidos para locais distintos ao longo da semana (ex: endereço residencial de noite, escritório de trabalho de dia). A limitação a um único endereço principal impedia a flexibilidade de entrega.

Além disso, a operação exige cobrança diferenciada de taxa de frete de acordo com o bairro do cliente e capacidade de **agendamento programado** para datas e horários futuros (ex: encomendas para festas de aniversário ou reuniões corporativas).

---

## 2. Decisão Tomada

1.  **Múltiplos Endereços Categorizados (`LocalEntrega`):** Os clientes podem possuir N endereços associados à chave estrangeira `Cliente.id`. Cada endereço possui `nomeIdentificador` (`Casa`, `Escritório`, `Trabalho`, `Outro`) visualizado por ícones contextuais e badges distintivos na interface.
2.  **Vínculo e Autoseleção de Frete (`TaxaEntrega`):** Ao cadastrar ou selecionar um endereço, o sistema faz a verificação do bairro com a tabela `taxa_entrega`, preenchendo automaticamente o valor em centavos no carrinho de venda do PDV.
3.  **Agendamento Temporal no PDV (`PdvPage`):** Implementado o seletor de **Data e Hora de Entrega** na tela de finalização de pedidos do PDV. O valor agendado é formatado no cabeçalho das observações da ordem de preparo: `[⏰ AGENDADA PARA: dd/MM/yyyy HH:mm]`.
4.  **Desacoplamento de Conclusão e Emissão Térmica:** O diálogo pós-fechamento do pedido separa o fluxo em dois comandos independentes:
    *   `[ 🖨️ IMPRIMIR VIAS ]`: Imprime o comprovante do cliente (Caixa) e a comanda de produção (Cozinha).
    *   `[ 🔄 NOVO ATENDIMENTO (F2) ]`: Apenas limpa a sessão e inicia um novo caixa sem imprimir.

---

## 3. Justificativa Técnica (Prós e Contras)

### 3.1 Vantagens (Prós)
*   **Flexibilidade Logística:** Reduz tempo de atendimento no telefone/balcão sem necessidade de redigitar endereços de escritório ou trabalho.
*   **Visibilidade Imediata no KDS:** O agendamento em destaque no topo da `OrdemPreparo` permite à cozinha priorizar pratos imediatos em relação às encomendas futuras.
*   **Controle Total de Emissão Térmica:** Evita desperdício de papel em pedidos rápidos onde o cliente dispensa o recibo impresso.

---

## 4. Consequências e Conformidade FPOS

*   As tabelas `LocalEntrega` e `TaxaEntrega` devem ser sincronizadas com prioridade topológica compatível com o `SyncEngine` (ADR-004).
*   Os componentes de impressão devem suportar os 3 terminais operacionais (Caixa, Cozinha e Expedição) conforme configurado em `ConfiguracoesPage`.
