# ADR-003: Adoção de UUID v7 para Identificadores Únicos

> **Document ID**: 304  
> **Version**: 1.0.0  
> **Status**: APPROVED  
> **Owner**: Principal Architect / Product Owner  
> **Contexto**: Padronização dos identificadores primários (PK) em todas as tabelas de negócio do FINCORE, no Drift SQLite e Supabase PostgreSQL.

---

## 1. Contexto

O FINCORE é uma plataforma multi-tenant baseada em uma arquitetura offline-first. Isso exige que o cliente Flutter (dispositivo móvel, desktop ou web em modo offline) consiga gerar identificadores de registro locais de forma independente e com garantia de unicidade absoluta antes de sincronizá-los com o servidor remoto.

Tradicionalmente, UUID v4 é amplamente utilizado para esse propósito devido à facilidade de geração aleatória. No entanto, UUID v4 não possui ordenação cronológica, o que acarreta os seguintes problemas:
1.  **Fragmentação de Índices B-Tree:** No banco de dados (SQLite local e PostgreSQL remoto), inserções sequenciais com chaves puramente aleatórias (como UUID v4) forçam divisões constantes de páginas no índice B-Tree, degradando a performance de escrita.
2.  **Impossibilidade de Ordenação Cronológica por ID:** UUID v4 não permite saber qual registro foi criado primeiro sem consultar a coluna `createdAt`.

---

## 2. Decisão Tomada

Adotar **UUID v7** de forma obrigatória como padrão de identificador único (PK) em todas as tabelas e entidades de negócio do FINCORE.

*   **Implementação no Client (Dart/Drift):** A geração das chaves em modo offline no client Flutter usará o gerador UUID v7 da biblioteca `package:uuid`.
*   **Implementação no Server (PostgreSQL/Supabase):** Quando inseridos pelo backend, as tabelas Postgres utilizarão a geração do UUID v7 (ou gen_random_uuid se o suporte v7 nativo não estiver ativado no cluster, mas priorizando a lógica v7 gerada no app/server).

---

## 3. Justificativa Técnica (Prós e Contras)

### 3.1 Vantagens (Prós)
*   **Ordenação Temporal Nativa:** UUID v7 embutirá um timestamp de 48 bits de milissegundos nos primeiros bytes da chave. Isso torna os identificadores cronologicamente sequenciais e lexicograficamente ordenáveis.
*   **Performance B-Tree:** Reduz drasticamente a fragmentação de índices, pois novas linhas são inseridas no final do índice (semelhante a um ID auto-incremental sequencial).
*   **Unicidade Distribuída:** Mantém 74 bits de entropia aleatória, garantindo segurança contra colisões em múltiplos dispositivos gerando dados offline.
*   **Independência de Banco:** Permite ordenar registros de forma cronológica aproximada sem necessidade de campos extras ou queries complexas de data.

### 3.2 Desvantagens (Contras)
*   **Vazamento de Timestamp:** Como os primeiros bytes contêm o timestamp de criação, é possível inferir a data e hora em que o registro foi gerado observando o ID. Para registros de negócio internos no ERP, isso não representa vulnerabilidade de segurança.
