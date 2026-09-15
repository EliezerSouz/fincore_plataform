# FINCORE Food Platform — Guia Completo de Instalação, Sincronização e Produção

> **Versão:** v1.3.0 Release  
> **Data:** Setembro/2026  
> **Arquitetura:** Offline-First (Drift/SQLite local) + SyncEngine + KDS/POS  

---

## 1. Visão Geral da Arquitetura de Produção

O **FINCORE Food** opera sob uma arquitetura local-first resiliente, permitindo a operação contínua do restaurante mesmo em quedas temporárias de internet ou rede local:

```text
  ┌────────────────────────┐                  ┌────────────────────────┐
  │  COMPUTADOR BALCÃO     │                  │   COMPUTADOR COZINHA   │
  │     (Windows POS)      │                  │     (Windows KDS)      │
  │                        │                  │                        │
  │  ┌──────────────────┐  │                  │  ┌──────────────────┐  │
  │  │  SQLite (Drift)  │  │                  │  │  SQLite (Drift)  │  │
  │  └────────┬─────────┘  │                  │  └────────┬─────────┘  │
  │           │            │                  │           │            │
  │     ┌─────▼──────┐     │                  │     ┌─────▼──────┐     │
  │     │ OutboxSync │     │                  │     │ OutboxSync │     │
  │     └─────┬──────┘     │                  │     └─────┬──────┘     │
  └───────────┼────────────┘                  └───────────┼────────────┘
              │                                           │
              └─────────────────┬─────────────────────────┘
                                │ SyncEngine (WebSocket / Push-Pull)
                                ▼
                   ┌─────────────────────────┐
                   │    NUVEM / SERVERPOD    │
                   │  (PostgreSQL Central)   │
                   └─────────────────────────┘
```

### Características Principais
- **Independência Operacional:** Vendas no balcão e preparo na cozinha continuam registrando pedidos localmente no SQLite.
- **Sincronia Bidirecional:** Status de preparo (Cozinha -> Balcão), pedidos de venda (Balcão -> Cozinha) e saldos de estoque são atualizados automaticamente em tempo real.
- **Auditoria e Logs Rastreáveis:** Toda mutação gera um evento imutável com ID único de rastreio (`SYNC-XXX`), auditado por `AuditService`.

---

## 2. Estrutura do Pacote de Produção (`fincore_food`)

O pacote gerado para distribuição fica localizado em `fincore_platform/fincore_food/`:

```text
fincore_food/
├── fincore_food_flutter.exe     ← Executável principal do sistema
├── .env                          ← Variáveis de ambiente (Chaves de API, URLs de sync)
├── msvcp140.dll                  ← Dependência de runtime do Windows C++
├── vcruntime140.dll              ← Dependência de runtime do Windows C++
├── data/                         ← Pasta criada dinamicamente para o banco SQLite local
├── logs/                         ← Pasta de logs operacionais e de sincronia (rotacionados)
└── COMO_RODAR_EM_OUTRO_PC.txt    ← Instruções rápidas para o operador
```

---

## 3. Passo a Passo para Instalação em Novo Computador (Balcão / Cozinha)

### Passo 1: Transferência dos Arquivos
1. Copie a pasta `fincore_food` inteira para um Pen Drive, HD Externo ou compartilhe via Rede Local.
2. Cole a pasta no diretório de sua preferência no computador de destino (Exemplo: `C:\FINCORE\fincore_food`).

### Passo 2: Execução sem Instalação de Runtimes Externos
1. Abra a pasta `C:\FINCORE\fincore_food`.
2. Dê um duplo clique no arquivo `fincore_food_flutter.exe`.
3. O sistema criará automaticamente as pastas `data/` (banco de dados SQLite local) e `logs/` na primeira inicialização.

> [!NOTE]
> As DLLs do C++ Runtime (`msvcp140.dll` e `vcruntime140.dll`) já vêm embutidas na pasta, dispensando a instalação prévia do Visual C++ Redistributable.

---

## 4. Testes e Validação Pós-Instalação

Para garantir que o ambiente de produção está totalmente funcional, execute a seguinte checklist no terminal do cliente:

- [ ] **Abertura da Aplicação:** O executável inicia sem mensagens de erro de DLLs ausentes.
- [ ] **Banco Local:** O arquivo de banco SQLite é criado dentro de `data/`.
- [ ] **Sincronização Balcão x Cozinha:** Realize uma venda teste no Balcão e verifique a chegada instantânea na tela da Cozinha (KDS).
- [ ] **Reversão de Status:** Altere o status na Cozinha para *Pronto* e depois para *Em Preparo*, confirmando a atualização imediata no Balcão.
- [ ] **Saldo de Estoque:** Realize um ajuste de saldo e verifique o valor atualizado em ambos os computadores.
- [ ] **Verificação de Logs:** Verifique na pasta `logs/` a presença do arquivo `.log` do dia contendo as entradas de inicialização e sincronia.

---

## 5. Procedimento de Backup e Restauração

### Backup Manual Rápido
- Copie a pasta `fincore_food/data/` para um local seguro (Pen Drive ou Nuvem).

### Restauração
- Em caso de falha de hardware, basta reinstalar a pasta `fincore_food` e substituir a pasta `data/` pelo backup armazenado.

---

*FINCORE Platform © 2026 — Toda empresa tem um coração. O FINCORE mantém esse coração em movimento.*
