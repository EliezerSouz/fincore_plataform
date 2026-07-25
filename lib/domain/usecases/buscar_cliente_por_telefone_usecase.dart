import '../../database/app_database.dart';
import '../ports/cliente_repository_port.dart';

/// Caso de uso para busca de cliente por telefone.
class BuscarClientePorTelefoneUseCase {
  final IClienteRepository _repository;
  const BuscarClientePorTelefoneUseCase(this._repository);

  Future<Cliente?> call(String telefone) {
    final limpo = telefone.trim();
    if (limpo.isEmpty) return Future.value(null);
    return _repository.porTelefone(limpo);
  }
}
