# CONVENÇÕES DE NOMENCLATURA (NAMING CONVENTIONS) — SALGADERIA ERP

**Escopo:** Padronização de nomes de classes, arquivos, métodos e DTOs na plataforma backend e cliente frontend.

---

## 1. NOMENCLATURA DE CAMADAS E ARTEFATOS

Para qualquer módulo de domínio `[Modulo]` (ex: `Cliente`, `Pedido`, `Estoque`), a nomenclatura deve ser estritamente consistente:

| Tipo de Componente | Padrão de Nomenclatura | Exemplo | Responsabilidade |
|---|---|---|---|
| **Domain Service** | `[Modulo]Service` | `ClienteService`, `PedidoService` | Contém 100% das regras de negócio do backend. |
| **Serverpod Endpoint** | `[Modulo]Endpoint` | `ClienteEndpoint`, `PedidoEndpoint` | Interface da API (recebe requisição e delega ao Service). |
| **Repository** | `[Modulo]Repository` | `ClienteRepository`, `PedidoRepository` | Camada de persistência pura (ORM Serverpod ou Drift). |
| **Modelo de Domínio** | `[Modulo]` / `[Modulo]Entity` | `Cliente`, `Pedido` | Entidade compartilhada no pacote `salgaderia_shared`. |
| **DTO / Payload** | `[Acao][Modulo]Request` / `Response` | `CriarPedidoRequest`, `CriarPedidoResponse` | Payload de entrada/saída de endpoints da API. |
| **Mapper** | `[Modulo]Mapper` | `ClienteMapper` | Converte entre DTOs de API e Entidades de Domínio. |

---

## 2. REGRAS DE ARQUIVOS E PASTAS

*   **Arquivos Dart:** Sempre em `snake_case.dart` (ex: `cliente_service.dart`, `criar_pedido_request.dart`).
*   **Classes e Enums:** Sempre em `PascalCase` (ex: `class ClienteService`, `enum StatusPedido`).
*   **Métodos e Variáveis:** Sempre em `camelCase` (ex: `reservarEstoque()`, `pedidoId`).
*   **Constantes:** Sempre em `lowerCamelCase` ou `kPascalCase` (ex: `maxTimeoutMs`, `kDefaultPadding`).

---

## 3. CONVENÇÕES ASSÍNCRONAS (FUTURES & STREAMS)

Para padronizar a chamada de métodos assíncronos no ecossistema Dart:

*   **Consultas Únicas (Futures):** Verbo no infinitivo claro (ex: `Future<Cliente> buscarPorId(String id)`).
*   **Operações de Escrita (Futures):** Verbo de ação direta (ex: `Future<void> salvar(Cliente cliente)`, `Future<void> deletar(String id)`).
*   **Escuta Reativa de Estado (Streams):** Prefixado por `observar` ou sufixado por `Stream` (ex: `Stream<List<Pedido>> observarPedidos()` ou `Stream<Estoque> estoqueStream()`).

---

*Convenções aprovadas para o ecossistema Salgaderia ERP.*
