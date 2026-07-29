import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/usecase/cliente_usecases.dart';

void main() {
  group('Cliente UseCases Unit Tests', () {
    late FincoreDatabase db;
    late TenantContext context;
    late ClienteRepository repository;
    late CriarClienteUseCase criarUseCase;
    late EditarClienteUseCase editarUseCase;
    late ExcluirClienteUseCase excluirUseCase;
    late BuscarClienteUseCase buscarUseCase;

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-001',
      razaoSocial: 'Fincore Test LTDA',
      nomeFantasia: 'Fincore Test',
      documentoFiscal: '11.222.333/0001-44',
      email: 'contato@fincore.com',
      telefone: '11999998888',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.ouro,
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Test',
      version: 1,
      metadata: mockMetadata,
    );

    final mockUsuario = CoreUsuario(
      id: 'user-001',
      nome: 'Operador Teste',
      email: 'op@fincore.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      context = TenantContext();
      context.clear();
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      repository = ClienteRepository(db: db, context: context);
      criarUseCase = CriarClienteUseCase(repository: repository);
      editarUseCase = EditarClienteUseCase(repository: repository);
      excluirUseCase = ExcluirClienteUseCase(repository: repository);
      buscarUseCase = BuscarClienteUseCase(repository: repository);
    });

    tearDown(() async {
      await db.close();
    });

    test('CriarClienteUseCase [CU-V05] deve criar e salvar cliente com sucesso', () async {
      final input = const ClienteInput(
        nome: 'Maria da Silva',
        telefone: '11988887777',
        email: 'maria@email.com',
        documento: '123.456.789-00',
        observacoes: 'Cliente VIP',
      );

      final cliente = await criarUseCase.execute(
        input: input,
        operadorId: 'user-001',
      );

      expect(cliente.id, isNotEmpty);
      expect(cliente.tenantId, equals('tenant-001'));
      expect(cliente.nome, equals('Maria da Silva'));
      expect(cliente.telefone, equals('11988887777'));
      expect(cliente.email, equals('maria@email.com'));
      expect(cliente.documento, equals('123.456.789-00'));

      final salvo = await repository.findById(cliente.id);
      expect(salvo, isNotNull);
      expect(salvo!.nome, equals('Maria da Silva'));
    });

    test('CriarClienteUseCase deve lançar exceção se nome estiver vazio', () async {
      final input = const ClienteInput(
        nome: '   ',
        telefone: '11988887777',
      );

      expect(
        () => criarUseCase.execute(input: input, operadorId: 'user-001'),
        throwsA(isA<ClienteDomainException>()),
      );
    });

    test('CriarClienteUseCase deve lançar exceção se telefone estiver vazio', () async {
      final input = const ClienteInput(
        nome: 'João',
        telefone: '',
      );

      expect(
        () => criarUseCase.execute(input: input, operadorId: 'user-001'),
        throwsA(isA<ClienteDomainException>()),
      );
    });

    test('EditarClienteUseCase [CU-V06] deve atualizar os dados do cliente', () async {
      final criado = await criarUseCase.execute(
        input: const ClienteInput(nome: 'Carlos', telefone: '11977776666'),
        operadorId: 'user-001',
      );

      final inputEdicao = const ClienteInput(
        nome: 'Carlos Eduardo',
        telefone: '11977776666',
        email: 'carlos@email.com',
      );

      final editado = await editarUseCase.execute(
        clienteId: criado.id,
        input: inputEdicao,
        operadorId: 'user-001',
      );

      expect(editado.nome, equals('Carlos Eduardo'));
      expect(editado.email, equals('carlos@email.com'));

      final doBanco = await repository.findById(criado.id);
      expect(doBanco!.nome, equals('Carlos Eduardo'));
    });

    test('ExcluirClienteUseCase [CU-V06] deve realizar exclusão lógica', () async {
      final criado = await criarUseCase.execute(
        input: const ClienteInput(nome: 'Ana', telefone: '11966665555'),
        operadorId: 'user-001',
      );

      await excluirUseCase.execute(
        clienteId: criado.id,
        operadorId: 'user-001',
      );

      final ativos = await repository.findAll();
      expect(ativos.any((c) => c.id == criado.id), isFalse);
    });

    test('BuscarClienteUseCase [CU-V07] deve filtrar por nome, telefone ou documento', () async {
      await criarUseCase.execute(
        input: const ClienteInput(nome: 'Ana Paula', telefone: '11911112222', documento: '11122233344'),
        operadorId: 'user-001',
      );
      await criarUseCase.execute(
        input: const ClienteInput(nome: 'Bruno Lima', telefone: '11933334444', documento: '55566677788'),
        operadorId: 'user-001',
      );

      final porNome = await buscarUseCase.execute(query: 'Ana');
      expect(porNome.length, equals(1));
      expect(porNome.first.nome, equals('Ana Paula'));

      final porTel = await buscarUseCase.execute(query: '3333');
      expect(porTel.length, equals(1));
      expect(porTel.first.nome, equals('Bruno Lima'));

      final porDoc = await buscarUseCase.execute(query: '111222');
      expect(porDoc.length, equals(1));
      expect(porDoc.first.nome, equals('Ana Paula'));
    });
  });
}
