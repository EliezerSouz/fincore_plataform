# LOGGING STANDARD — FINCORE PLATFORM

This document serves as the official enterprise reference standard for all observability, telemetry, and structured audit logging within the **FINCORE Platform**.

---

## 1. Absolute Directive: Instrument, Do Not Interfere

1. **Non-blocking Execution:** The logger observes system execution asynchronously. Failures in log emission or IO write must **never** break operational business transactions, calculations, or user flows.
2. **Preservation of Logic:** Operational code instrumentation must strictly preserve return values, exceptions, async behavior, database transactions, and API contracts.

---

## 2. Core Log Event Specification (`LogEvent`)

Every logged event complies with the unified `LogEvent` model:

- `id`: UUID string unique to this event line.
- `timestamp`: UTC DateTime timestamp (ISO 8601).
- `level`: `TRACE`, `DEBUG`, `INFO`, `NOTICE`, `WARNING`, `ERROR`, `CRITICAL`, `AUDIT`.
- `category`: `OPERACIONAL`, `AUDITORIA`, `SINCRONIZACAO`, `BANCO_DADOS`, `REDE`, `AUTENTICACAO`, `SEGURANCA`, `SISTEMA`, `PERFORMANCE`, `INTEGRACAO`, `ERRO`.
- `eventType`: Standard uppercase snake_case event type string (e.g. `PEDIDO_CRIADO`, `SYNC_ENTITY_FAILED`).
- `action`: Operation action (`CREATE`, `UPDATE`, `DELETE`, `READ`, `EXECUTE`, `PUSH`, `PULL`, `LOGIN`, `LOGOUT`).
- `module`: Target system module (`startup`, `sync`, `database`, `api`, `migration`, `printer`, `crash`, `app`, `importExport`, `audit`, `estoque`, `producao`, `pedidos`, `financeiro`).
- `source`: Execution source (`LOCAL`, `REMOTE`, `USER`, `SYSTEM`, `SYNC`, `SCHEDULED`, `INTEGRATION`).
- `traceId`: Correlation ID tracking an entire multi-step business workflow (e.g. Order Creation -> Reservation -> Kitchen Prep -> Dispatch -> Stock Deduction).
- `correlationId`: Transactional correlation ID grouping related events.
- `parentEventId`: Causal parent event ID.
- `applicationVersion`: Executable application version (e.g. `1.2.1`).
- `loggerVersion`: Logger engine version (e.g. `1.3.0`).
- `schemaVersion`: Database schema version.

---

## 3. Correlation ID Hierarchy

- **TRACE ID (`traceId`):** Unique identifier shared across all steps of an end-to-end operation.
- **CORRELATION ID (`correlationId`):** Groups events belonging to a specific batch or transaction context.
- **EVENT ID (`id`):** Unique UUID for the single log line.
- **PARENT EVENT ID (`parentEventId`):** Identifies the exact preceding event that triggered this step.

---

## 4. Error Code Taxonomy

Technical failures must preserve original technical error details without generic masking:

- **PostgreSQL / Supabase 42501:** `Category: INTEGRACAO / AUTENTICACAO`, `ErrorCode: 42501`, `ErrorType: PostgrestException (PERMISSION_DENIED)`.
- **PostgreSQL / Supabase 23503:** `Category: INTEGRACAO / BANCO_DADOS`, `ErrorCode: 23503`, `ErrorType: PostgrestException (FOREIGN_KEY_VIOLATION)`.
- **PostgreSQL / Supabase 23505:** `Category: INTEGRACAO / BANCO_DADOS`, `ErrorCode: 23505`, `ErrorType: PostgrestException (UNIQUE_CONSTRAINT_VIOLATION)`.
- **Offline / SocketException:** `Category: REDE`, `ErrorCode: SOCKET_DISCONNECTED`, `ErrorType: SocketException`.

---

## 5. Privacy & Sensitive Data Redaction

Keys matching `password`, `senha`, `token`, `secret`, `privateKey`, or `auth` are automatically redacted as `***REDACTED***` prior to disk or cloud emission.
