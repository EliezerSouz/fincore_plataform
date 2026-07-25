import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:salgaderia/database/app_database.dart';
import 'package:salgaderia/data/repositories/pedido_repository.dart';
import 'package:salgaderia/data/repositories/cliente_repository.dart';
import 'package:salgaderia/data/repositories/produto_repository.dart';
import 'package:salgaderia/data/repositories/grupo_preco_repository.dart';
import 'package:salgaderia/models/domain_models.dart';

void main() {
  late AppDatabase db;
  late PedidoRepository pedidoRepo;
  late ClienteRepository clienteRepo;
  late ProdutoRepository produtoRepo;
  late GrupoPrecoRepository grupoRepo;

  late Cliente testCliente;
  late Produto testProduto;
  late GruposPrecoData testGrupo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pedidoRepo = PedidoRepository(db);
    clienteRepo = ClienteRepository(db);
    produtoRepo = ProdutoRepository(db);
    grupoRepo = GrupoPrecoRepository(db);

    // Cadastrar cliente de teste
    final clienteId = await clienteRepo.salvar(
      ClientesCompanion.insert(
        nome: 'Maria Silva',
        telefone: const Value('15999999999'),
        logradouro: const Value('Rua das Flores'),
        numero: const Value('123'),
        bairro: const Value('Centro'),
        cidade: const Value('Sorocaba'),
      ),
    );
    testCliente = await (db.select(db.clientes)..where((c) => c.id.equals(clienteId))).getSingle();

    // Cadastrar grupo de preço de teste
    final grupoId = await grupoRepo.salvar(
      nome: 'Fritos',
      descricao: 'Salgados fritos',
      faixas: [
        FaixaInput(1, null, 100),
      ],
    );
    testGrupo = await (db.select(db.gruposPreco)..where((g) => g.id.equals(grupoId))).getSingle();

    // Cadastrar produto de teste
    final produtoId = await produtoRepo.salvar(
      nome: 'Coxinha',
      categoria: 'Salgados',
      grupoPrecoId: grupoId,
      controlaEstoque: true,
    );
    testProduto = await (db.select(db.produtos)..where((p) => p.id.equals(produtoId))).getSingle();

    // Inicializar estoque para evitar erros
    await db.into(db.estoqueAtual).insertOnConflictUpdate(
      EstoqueAtualCompanion(
        produtoId: Value(produtoId),
        saldoAtual: const Value(500),
        reservado: const Value(0),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Ciclo de Vida do Pedido - Regras de Negócio', () {
    test('Criação de Pedido registra evento CRIADO e PIX_GERADO (se pago com PIX)', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'PIX',
        troco: null,
        observacoes: 'Sem cebola',
        taxa: 500,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 100),
        ],
      );

      final pedido = await pedidoRepo.completo(id);
      expect(pedido.pedido.status, equals('Pendente'));
      expect(pedido.pedido.versao, equals(1));
      expect(pedido.pedido.prioridade, equals('Normal'));

      // Verificar eventos gravados
      final eventos = await pedidoRepo.obterEventos(id);
      expect(eventos.length, equals(2)); // CRIADO + PIX_GERADO
      expect(eventos.any((e) => e.tipoEvento == 'CRIADO'), isTrue);
      expect(eventos.any((e) => e.tipoEvento == 'PIX_GERADO'), isTrue);
    });

    test('Transições operacionais lógicas válidas e inválidas (State Machine)', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: '',
        taxa: 0,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 50),
        ],
      );

      // Transição Pendente -> Em Preparo (Válida)
      await pedidoRepo.alterarStatus(id, 'Em Preparo');
      var p = await pedidoRepo.completo(id);
      expect(p.pedido.status, equals('Em Preparo'));

      // Transição Em Preparo -> Pronto (Válida)
      await pedidoRepo.alterarStatus(id, 'Pronto');
      p = await pedidoRepo.completo(id);
      expect(p.pedido.status, equals('Pronto'));

      // Transição Pronto -> Em Rota (Válida para Entrega)
      await pedidoRepo.alterarStatus(id, 'Em Rota');
      p = await pedidoRepo.completo(id);
      expect(p.pedido.status, equals('Em Rota'));

      // Transição Em Rota -> Finalizado (Válida)
      await pedidoRepo.alterarStatus(id, 'Finalizado');
      p = await pedidoRepo.completo(id);
      expect(p.pedido.status, equals('Finalizado'));

      // Transição direta inválida (ex: Pendente -> Finalizado direto deve lançar erro)
      final id2 = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: '',
        taxa: 0,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 10),
        ],
      );

      expect(
        () => pedidoRepo.alterarStatus(id2, 'Finalizado'),
        throwsA(isA<Exception>()),
      );
    });

    test('Edição incrementa número de versão e grava evento EDITADO', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: 'Original',
        taxa: 500,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 10),
        ],
      );

      await pedidoRepo.editar(
        id: id,
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: 'Editado',
        taxa: 500,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 20), // Dobrou a quantidade
        ],
      );

      final p = await pedidoRepo.completo(id);
      expect(p.pedido.versao, equals(2));
      expect(p.pedido.observacoes, equals('Editado'));

      final eventos = await pedidoRepo.obterEventos(id);
      expect(eventos.any((e) => e.tipoEvento == 'EDITADO'), isTrue);
    });

    test('Confirmação de pagamento PIX atualiza colunas e gera evento PIX_CONFIRMADO', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'PIX',
        troco: null,
        observacoes: '',
        taxa: 0,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 10),
        ],
      );

      await pedidoRepo.confirmarPix(pedidoId: id, comprovantePix: 'E123456789COMPROVANTE');

      final p = await pedidoRepo.completo(id);
      expect(p.pedido.pixConfirmado, isTrue);
      expect(p.pedido.comprovantePix, equals('E123456789COMPROVANTE'));
      expect(p.pedido.pixConfirmadoEm, isNotNull);

      final eventos = await pedidoRepo.obterEventos(id);
      expect(eventos.any((e) => e.tipoEvento == 'PIX_CONFIRMADO'), isTrue);
    });

    test('Reabertura de pedido incrementa versão, muda status e gera log', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: '',
        taxa: 0,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 10),
        ],
      );

      // Fluxo até Finalizado
      await pedidoRepo.alterarStatus(id, 'Em Preparo');
      await pedidoRepo.alterarStatus(id, 'Pronto');
      await pedidoRepo.alterarStatus(id, 'Em Rota');
      await pedidoRepo.alterarStatus(id, 'Finalizado');

      // Reabrir pedido para Em Preparo
      await pedidoRepo.reabrirPedido(
        pedidoId: id,
        novoStatus: 'Em Preparo',
        motivo: 'Cliente não recebeu',
        observacao: 'Tentativa de entrega falhou',
      );

      final p = await pedidoRepo.completo(id);
      expect(p.pedido.status, equals('Em Preparo'));
      expect(p.pedido.versao, equals(2));

      final eventos = await pedidoRepo.obterEventos(id);
      expect(eventos.any((e) => e.tipoEvento == 'REABERTURA'), isTrue);
      final evReabertura = eventos.firstWhere((e) => e.tipoEvento == 'REABERTURA');
      expect(evReabertura.descricao, contains('Cliente não recebeu'));
    });

    test('Reverter etapa volta status, incrementa versão e gera log', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: '',
        taxa: 0,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 10),
        ],
      );

      await pedidoRepo.alterarStatus(id, 'Em Preparo');
      await pedidoRepo.alterarStatus(id, 'Pronto');

      // Reverter para Em Preparo
      await pedidoRepo.reverterStatus(
        pedidoId: id,
        statusAnterior: 'Em Preparo',
        motivo: 'Erro do operador',
        observacao: 'Fritou salgado errado',
      );

      final p = await pedidoRepo.completo(id);
      expect(p.pedido.status, equals('Em Preparo'));
      expect(p.pedido.versao, equals(2));

      final eventos = await pedidoRepo.obterEventos(id);
      final evReversao = eventos.firstWhere((e) => e.titulo == 'Etapa revertida');
      expect(evReversao.descricao, contains('Erro do operador'));
    });

    test('Não é permitido editar ou cancelar pedido finalizado', () async {
      final id = await pedidoRepo.criar(
        cliente: testCliente,
        entrega: DateTime.now().add(const Duration(hours: 2)),
        tipo: 'Entrega',
        pagamento: 'Dinheiro',
        troco: null,
        observacoes: '',
        taxa: 0,
        itens: [
          ItemCarrinho(produto: testProduto, grupo: testGrupo, quantidade: 10),
        ],
      );

      await pedidoRepo.alterarStatus(id, 'Em Preparo');
      await pedidoRepo.alterarStatus(id, 'Pronto');
      await pedidoRepo.alterarStatus(id, 'Em Rota');
      await pedidoRepo.alterarStatus(id, 'Finalizado');

      // Tentativa de editar
      expect(
        () => pedidoRepo.editar(
          id: id,
          cliente: testCliente,
          entrega: DateTime.now(),
          tipo: 'Entrega',
          pagamento: 'Dinheiro',
          troco: null,
          observacoes: 'Tentativa de alteração',
          taxa: 0,
          itens: [],
        ),
        throwsA(isA<Exception>()),
      );

      // Tentativa de cancelar
      expect(
        () => pedidoRepo.cancelar(id),
        throwsA(isA<Exception>()),
      );
    });
  });
}
