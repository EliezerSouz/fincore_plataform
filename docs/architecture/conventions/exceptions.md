# CONVENÇÕES DE EXCEÇÕES E FAIL FAST (EXCEPTIONS CONVENTIONS) — SALGADERIA ERP

**Escopo:** Diretrizes para tratamento defensivo de erros, exceções de domínio e política de Fail Fast.

---

## 1. PRINCÍPIO FAIL FAST (FALHAR RAPIDAMENTE E EXPLICITAMENTE)

Para evitar comportamentos silenciosos degradados e facilitar a identificação da causa raiz de erros:

*   **Veto a Retornos Null Silenciosos:** Nunca retorne `null` ou estruturas vazias para mascarar uma falha de sistema ou de banco. Lance uma exceção explícita de domínio.
*   **Veto a Tratamento Genérico (`catch (e)`):** Nunca engula exceções com blocos `try/catch` vazios ou registrando apenas `print(e)`. Toda exceção capturada deve ser tratada, logada com `correlationId` ou repassada.
*   **Validação Imediata de Parâmetros:** Valide precondições no início dos métodos do `Domain Service`. Se um parâmetro for inválido, lance `ArgumentError` ou uma `DomainException` imediatamente.

---

## 2. HIERARQUIA DE EXCEÇÕES DE DOMÍNIO

Todas as exceções específicas de negócio herdam de `SalgaderiaException` no pacote `salgaderia_shared`:

```dart
abstract class SalgaderiaException implements Exception {
  final String message;
  final String code;
  
  SalgaderiaException(this.message, this.code);
  
  @override
  String toString() => '[$code] $message';
}

// Exceções Específicas por Agregado:
class PedidoException extends SalgaderiaException {
  PedidoException(super.message, [super.code = 'PEDIDO_ERROR']);
}

class ReservaException extends SalgaderiaException {
  ReservaException(super.message, [super.code = 'RESERVA_INSUFICIENTE']);
}

class MRPException extends SalgaderiaException {
  MRPException(super.message, [super.code = 'MRP_ERROR']);
}

class AgendaCapacidadeException extends SalgaderiaException {
  AgendaCapacidadeException(super.message, [super.code = 'AGENDA_CAPACIDADE_EXCEDIDA']);
}

class AuthException extends SalgaderiaException {
  AuthException(super.message, [super.code = 'AUTH_UNAUTHORIZED']);
}
```

---

## 3. TRATAMENTO DE ERROS NA CAMADA DE ENDPOINTS & FRONTEND

*   **Endpoints Serverpod:** Capturam exceções de domínio (`SalgaderiaException`) e as convertem para respostas estruturadas de erro com código HTTP semântico correspondente (ex: `400 Bad Request`, `409 Conflict`, `401 Unauthorized`).
*   **Frontend Flutter:** Intercepta as exceções de API via `AppDialog` ou `SnackBar` semântico, exibindo a mensagem amigável para o operador sem quebrar o estado da tela.

---

*Convenções aprovadas para o ecossistema Salgaderia ERP.*
