import 'package:uuid/uuid.dart';
import '../common/domain_primitives.dart';
import '../common/master_data_models.dart';
import '../repository/cliente_repository.dart';

/// Exceção de Domínio para Validações de Cliente
class ClienteDomainException implements Exception {
  final String message;
  const ClienteDomainException(this.message);

  @override
  String toString() => 'ClienteDomainException: $message';
}

/// DTO para entrada de cadastro/edição de Cliente
class ClienteInput {
  final String nome;
  final String telefone;
  final String? apelido;
  final String? email;
  final String? documento;
  final String observacoes;

  const ClienteInput({
    required this.nome,
    required this.telefone,
    this.apelido,
    this.email,
    this.documento,
    this.observacoes = '',
  });

  void validate() {
    if (nome.trim().isEmpty) {
      throw const ClienteDomainException('O nome do cliente é obrigatório.');
    }
    if (telefone.trim().isEmpty) {
      throw const ClienteDomainException('O telefone do cliente é obrigatório.');
    }
  }
}

/// Caso de Uso: [CU-V05] Cadastrar Cliente Completo
class CriarClienteUseCase {
  final ClienteRepository _repository;
  final Uuid _uuid;

  CriarClienteUseCase({
    required ClienteRepository repository,
    Uuid uuid = const Uuid(),
  })  : _repository = repository,
        _uuid = uuid;

  Future<Cliente> execute({
    required ClienteInput input,
    required String operadorId,
  }) async {
    input.validate();

    final telNorm = normalizarTelefone(input.telefone);
    final existenteTel = await _repository.findByTelefone(telNorm);
    if (existenteTel != null) {
      throw ClienteDomainException('Já existe um cliente cadastrado com este telefone (${formatarTelefone(telNorm)}: ${existenteTel.nomeExibicao}).');
    }

    final activeTenant = _repository.activeTenantId;
    final now = DateTime.now();

    final cliente = Cliente(
      id: _uuid.v4(),
      tenantId: activeTenant,
      nome: input.nome.trim(),
      apelido: input.apelido?.trim().isEmpty == true ? null : input.apelido?.trim(),
      telefone: telNorm.isNotEmpty ? telNorm : input.telefone.trim(),
      email: input.email?.trim(),
      documento: input.documento?.trim(),
      observacoes: input.observacoes.trim(),
      ativo: true,
      metadata: SyncMetadata(
        version: 1,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
        syncStatus: SyncStatus.pending,
      ),
    );

    await _repository.save(cliente);
    return cliente;
  }
}

/// Caso de Uso: [CU-V06] Editar Cliente
class EditarClienteUseCase {
  final ClienteRepository _repository;

  EditarClienteUseCase({required ClienteRepository repository})
      : _repository = repository;

  Future<Cliente> execute({
    required String clienteId,
    required ClienteInput input,
    required String operadorId,
  }) async {
    input.validate();

    final existente = await _repository.findById(clienteId);
    if (existente == null || existente.metadata.deletedAt != null) {
      throw ClienteDomainException('Cliente $clienteId não foi encontrado.');
    }

    final telNorm = normalizarTelefone(input.telefone);
    final existenteTel = await _repository.findByTelefone(telNorm, excludeId: clienteId);
    if (existenteTel != null) {
      throw ClienteDomainException('Já existe outro cliente cadastrado com este telefone (${formatarTelefone(telNorm)}: ${existenteTel.nomeExibicao}).');
    }

    final now = DateTime.now();
    final atualizado = existente.copyWith(
      nome: input.nome.trim(),
      apelido: () => input.apelido?.trim().isEmpty == true ? null : input.apelido?.trim(),
      telefone: telNorm.isNotEmpty ? telNorm : input.telefone.trim(),
      email: () => input.email?.trim(),
      documento: () => input.documento?.trim(),
      observacoes: input.observacoes.trim(),
      metadata: existente.metadata.copyWith(
        version: existente.metadata.version + 1,
        updatedAt: now,
        updatedBy: operadorId,
        syncStatus: SyncStatus.pending,
      ),
    );

    await _repository.save(atualizado);
    return atualizado;
  }
}

/// Caso de Uso: [CU-V06] Excluir Cliente (Soft Delete Lógico com Validação de Integridade)
class ExcluirClienteUseCase {
  final ClienteRepository _repository;

  ExcluirClienteUseCase({required ClienteRepository repository})
      : _repository = repository;

  Future<void> execute({
    required String clienteId,
    required String operadorId,
  }) async {
    final existente = await _repository.findById(clienteId);
    if (existente == null || existente.metadata.deletedAt != null) {
      throw ClienteDomainException('Cliente $clienteId não foi encontrado para exclusão.');
    }

    final totalPedidos = await _repository.countPedidosByClienteId(clienteId);
    if (totalPedidos > 0) {
      throw ClienteDomainException(
        'Não é possível excluir o cliente "${existente.nomeExibicao}" pois existem $totalPedidos pedido(s) vinculados ao seu histórico.',
      );
    }

    await _repository.delete(clienteId);
  }
}

/// Caso de Uso: [CU-V07] Localizar Cliente (Busca por Nome, Telefone, Documento)
class BuscarClienteUseCase {
  final ClienteRepository _repository;

  BuscarClienteUseCase({required ClienteRepository repository})
      : _repository = repository;

  Future<List<Cliente>> execute({String query = ''}) async {
    return await _repository.search(query);
  }
}
