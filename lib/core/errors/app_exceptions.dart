/// Hierarquia base de exceções de domínio da Salgaderia.
///
/// Todas as regras de negócio lançam exceções derivadas de [AppException],
/// permitindo que os Providers e UIs capturem e tratem erros de forma padronizada.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Lançada quando a validação de uma regra de negócio falha.
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Lançada quando uma entidade solicitada não foi encontrada.
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Lançada quando há erro de comunicação ou hardware de impressão.
class PrinterException extends AppException {
  const PrinterException(super.message);
}

/// Lançada quando há falha de persistência ou integridade no repositório.
class RepositoryException extends AppException {
  const RepositoryException(super.message);
}
