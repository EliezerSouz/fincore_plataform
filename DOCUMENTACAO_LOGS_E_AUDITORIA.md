# 📘 Guia Definitivo e Completo de Logs e Auditoria — FINCORE Platform

Este documento serve como o **manual de referência técnica definitivo** para entender, diagnosticar, auditar e padronizar toda a infraestrutura de **Logs, Auditoria e Versionamento** da plataforma **FINCORE**.

---

## 1. O Conceito de Versões nos Logs (Diferenciação Vital)

Para evitar qualquer confusão ao analisar os logs do sistema, é fundamental entender que existem **DUAS VERSÕES DIFERENTES** gravadas nos arquivos:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 1. VERSÃO DO APLICATIVO (App Release Version)                                         │
│    Exemplo: [v1.2.1]                                                                  │
│    O que significa: É a versão do software compilado rodando no Windows.               │
│    Onde aparece: Nos cabeçalhos dos ciclos de sync e rodapé do sistema.                │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. VERSÃO INCREMENTAL DA ENTIDADE (Entity syncVersion)                                │
│    Exemplo: ID: 64f61559... (v2)  ou  (v3)                                             │
│    O que significa: É a quantidade de vezes que o REGISTRO INDIVIDUAL já foi alterado.  │
│    Onde aparece: Nos logs de mutação do banco de dados (CREATE/UPDATE/DELETE).        │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Detalhamento Prático das Versões:

1. **Versão do Aplicativo (`App Version` ex: `v1.2.1`):**
   * **Propósito:** Saber se o executável que produziu aquele log possui as correções de código mais recentes.
   * **Exemplo no Log:**
     `====================== CICLO DE RECEBIMENTO REMOTO (PULL) [v1.2.1] =======================`

2. **Versão do Registro/Entidade (`syncVersion` ex: `v1`, `v2`, `v3`):**
   * **Propósito:** Rastrear quantas vezes aquele cadastro específico sofreu mutação.
   * **Regra de Avanço:**
     * `(v1)` = Registro criado pela primeira vez.
     * `(v2)` = 1ª alteração realizada no registro.
     * `(v3)` = 2ª alteração realizada no registro.
   * **Exemplo no Log Operacional / Banco:**
     `2026-09-16 01:02:03.463 [INFO] [BANCO] MUTACAO [UPDATE] Entidade [empresa_configuracao] ID: 64f61559... (v2)`
     *(Significa: A configuração dessa empresa acabou de receber a sua primeira atualização, avançando para a versão 2).*

---

## 2. Estrutura dos 7 Arquivos e Pastas da pasta `LOG/`

Para evitar arquivos gigantescos e amontoados, a plataforma FINCORE organiza os logs em **7 subpastas e arquivos temáticos diários**:

```text
LOG/
 ├── Sincronizacao/   --> sync_YYYY-MM-DD.log       (Envio/Recebimento Supabase, Outbox, Realtime)
 ├── Operacional/      --> operacional_YYYY-MM-DD.log (Navegação PDV, Caixa, Ações do Operador)
 ├── BancoDados/       --> banco_YYYY-MM-DD.log       (Mutações SQLite local: CREATE, UPDATE, DELETE)
 ├── Impressao/        --> impressao_YYYY-MM-DD.log   (Spooler ESC/POS, Vias de Cupom, KDS)
 ├── ImportExport/     --> importexport_YYYY-MM-DD.log(Carga de dados, Seeds, Backups CSV/JSON)
 ├── Erros/            --> erros_YYYY-MM-DD.log       (Espelho de todas as falhas graves e exceções)
 └── Auditoria/        --> auditoria_YYYY-MM-DD.log   (Auditoria gerencial: alteração de preços, login)
```

---

### Detalhamento Técnico de Cada Arquivo de Log:

### 2.1. `LOG/Sincronizacao/sync_YYYY-MM-DD.log`
* **Para que serve:** Monitorar a saúde da comunicação off-line/on-line entre o SQLite local e o Supabase na nuvem.
* **O que grava:**
  * Início e fim dos ciclos de PUSH (Envio) e PULL (Recebimento).
  * Envio de cada entidade da fila `outbox_sync` com status (`ENVIANDO`, `CONFIRMADO`, `RETENTANDO`).
  * Falhas transitórias (`code: 23503`) e ativação do mecanismo de **Auto-Recuperação (`Auto-Heal`)**.
  * Aplicação de deltas baixados da nuvem.

### 2.2. `LOG/BancoDados/banco_YYYY-MM-DD.log`
* **Para que serve:** Rastrear toda escrita realizada no banco de dados SQLite local.
* **O que grava:**
  * Operações de `MUTACAO [CREATE]`, `MUTACAO [UPDATE]` e `MUTACAO [DELETE]`.
  * ID do registro e a versão incremental gerada `(v1)`, `(v2)`, `(v3)`.
  * Diffs de alterações com dados reais de negócio (`{"taxaServico":{"old":10,"new":12}}`), omitindo metadados do motor.

### 2.3. `LOG/Operacional/operacional_YYYY-MM-DD.log`
* **Para que serve:** Acompanhar a jornada do operador no PDV e na comanda.
* **O que grava:**
  * Login offline/online de operadores.
  * Abertura e fechamento de comutação de caixas.
  * Troca de telas, busca de produtos, adição de itens ao carrinho.
  * Confirmação de vendas no PDV Express.

### 2.4. `LOG/Impressao/impressao_YYYY-MM-DD.log`
* **Para que serve:** Diagnosticar problemas de impressão de cupons e integração KDS.
* **O que grava:**
  * Envio de impressões para spooler ESC/POS (Caixa, Cozinha, Balcão, Expedição).
  * Status da impressora (Conectada, Sem Papel, Erro de Comunicação USB/Network).
  * Comandos de corte de papel e abertura de gaveta.

### 2.5. `LOG/ImportExport/importexport_YYYY-MM-DD.log`
* **Para que serve:** Rastrear cargas massivas de dados, migrações e restauração de backups.
* **O que grava:**
  * Execução de Scripts de Seed (carga inicial de dados de teste).
  * Importação de planilhas de produtos/clientes.
  * Migrações de estrutura do banco de dados local.

### 2.6. `LOG/Erros/erros_YYYY-MM-DD.log`
* **Para que serve:** Centralizar **todas** as falhas críticas do sistema em um só lugar.
* **O que grava:**
  * Qualquer linha registrada como `[ERRO]` ou `[CRITICO]` nos outros módulos é **duplicada automaticamente neste arquivo**.
  * Exceções não capturadas do Flutter/Dart (Stack traces completas).
  * Falhas permanentes de schema ou RLS.

### 2.7. `LOG/Auditoria/auditoria_YYYY-MM-DD.log`
* **Para que serve:** Registro de segurança gerencial para auditoria fiscal e financeira.
* **O que grava:**
  * Quem alterou o preço de um produto.
  * Quem concedeu desconto ou cancelou um pedido.
  * Quem abriu a gaveta manualmente.

---

## 3. Anatomia Padronizada de uma Linha de Log

Todas as linhas em todos os 7 arquivos seguem um **padrão estrutural estrito e uniforme**:

```text
2026-09-16 01:38:19.460 [INFO]    [SINCRONISMO  ] Elias de Souza @ Solange Salgados Artesanais | [ENVIANDO] Entidade: [itens_pedido] | Acao: CREATE | ID: 4d967272... [Rastreio: SYNC-1A0A8822FFC]
```

### Componentes Obrigatórios:
1. **Timestamp Milissegundos:** `YYYY-MM-DD HH:mm:ss.SSS`
2. **Tag de Severidade Alinhada:** `[INFO]`, `[AVISO]`, `[ERRO]`, `[DEBUG]` (com alinhamento de 7 caracteres para leitores de log como BareTail).
3. **Módulo entre Colchetes:** `[SINCRONISMO]`, `[BANCO]`, `[IMPRESSORA]`.
4. **Contexto de Operação:** `Operador @ Empresa`.
5. **Mensagem Estruturada:** Descrição clara com IDs encurtados (`ID: 4d967272...`) e Versão da Entidade `(v2)` quando aplicável.
6. **Trace ID:** `[Rastreio: SYNC-XXXXXXXXX]` para correlação de ciclo.

---

## 4. Tabela de Auditoria em Banco (`audit_logs`) vs. Arquivos `.log`

É crucial distinguir as duas camadas de auditoria existentes:

| Característica | Arquivos de Log (`LOG/*.log`) | Tabela no Banco (`audit_logs`) |
| :--- | :--- | :--- |
| **Público Alvo** | Suporte Técnico / Desenvolvedores. | Gerentes, Dono da Empresa, Auditoria Fiscal. |
| **Armazenamento** | Arquivos de texto rotacionados por dia. | Tabela SQLite local + Sincronizada no Supabase. |
| **Conteúdo** | Fluxo técnico, retentativas, SQL, tempos. | Histórico de alterações de negócio (Quem, Quando, O quê). |
| **Retenção** | Limpeza automática em 30 dias. | Histórico permanente (conforme política fiscal). |

---

## 5. Roteiro Prático de Diagnóstico para o Suporte

### Como identificar uma dúvida ou erro em 3 passos:

#### Passo 1: Descubra qual é a natureza do problema
* Problema de internet/sync? $\rightarrow$ Abra `LOG/Sincronizacao/sync_YYYY-MM-DD.log`
* Problema de dado não gravando localmente? $\rightarrow$ Abra `LOG/BancoDados/banco_YYYY-MM-DD.log`
* Impressora não saiu cupom? $\rightarrow$ Abra `LOG/Impressao/impressao_YYYY-MM-DD.log`
* O sistema deu erro na tela? $\rightarrow$ Abra `LOG/Erros/erros_YYYY-MM-DD.log`

#### Passo 2: Copie o `Trace ID`
Ao achar o erro (linha com `[ERRO]` ou `[AVISO]`), copie o código do rastro, por exemplo: `SYNC-1A0A8822FFC`.

#### Passo 3: Filtre o arquivo por esse `Trace ID`
Ao filtrar pelo Trace ID, você verá toda a história cronológica daquela operação específica (desde o momento em que o operador clicou no botão até a resposta final do banco ou da nuvem).

---

## 6. Análise de Padronização e Garantias do Sistema

Realizamos uma varredura completa na base de código e garantimos que:

1. ✅ **Nomes de Empresa Limpos:** O executável e os metadados registram **`Fincore Platform`**.
2. ✅ **Sem Poluição de Metadados nos Diffs:** Diffs mostram apenas dados de negócio reais.
3. ✅ **Versão do Registro Monotônica:** A `syncVersion` em mutações do banco de dados **nunca regride**.
4. ✅ **Versão do Aplicativo nos Cabeçalhos:** Todos os ciclos informam a release exata (ex: `v1.2.1`).
5. ✅ **Trace ID Único por Ciclo:** Operações compostas compartilham a mesma chave de rastreabilidade.
