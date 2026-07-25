import 'package:flutter_test/flutter_test.dart';
import 'package:salgaderia/database/app_database.dart';
import 'package:salgaderia/domain/ports/cliente_repository_port.dart';
import 'package:salgaderia/domain/usecases/buscar_cliente_por_telefone_usecase.dart';

class FakeClienteRepository implements IClienteRepository {
  final List<Cliente> clientes = [];

  @override
  Future<Cliente?> porTelefone(String telefone) async {
    return clientes.where((c) => c.telefone == telefone).firstOrNull;
  }

  @override
  Stream<List<Cliente>> observar() => throw UnimplementedError();

  @override
  Future<int> salvar(ClientesCompanion cliente, {int? id}) =>
      throw UnimplementedError();

  @override
  Stream<List<LocaisEntregaData>> observarLocais(int clienteId) =>
      throw UnimplementedError();

  @override
  Future<List<LocaisEntregaData>> obterLocais(int clienteId) =>
      throw UnimplementedError();

  @override
  Future<int> salvarLocal(LocaisEntregaCompanion local, {int? id}) =>
      throw UnimplementedError();

  @override
  Future<void> excluirLocal(int id) => throw UnimplementedError();
}

void main() {
  late FakeClienteRepository repo;
  late BuscarClientePorTelefoneUseCase useCase;

  setUp(() {
    repo = FakeClienteRepository();
    useCase = BuscarClientePorTelefoneUseCase(repo);

    repo.clientes.add(const Cliente(
      id: 1,
      nome: 'Maria Silva',
      telefone: '11999998888',
      logradouro: 'Rua Flores',
      numero: '123',
      bairro: 'Centro',
      cidade: 'São Paulo',
      cep: '01000-000',
      referencia: '',
      observacoes: '',
      ativo: true,
    ));
  });

  test('retorna cliente quando telefone coincide', () async {
    final cliente = await useCase('11999998888');
    expect(cliente, isNotNull);
    expect(cliente!.nome, 'Maria Silva');
  });

  test('retorna null se telefone estiver vazio', () async {
    final cliente = await useCase('  ');
    expect(cliente, isNull);
  });

  test('retorna null se cliente não for encontrado', () async {
    final cliente = await useCase('00000000000');
    expect(cliente, isNull);
  });
}
