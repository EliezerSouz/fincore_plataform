import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_core/database/fincore_seeds.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/pdv_express/domain/confirmar_venda_use_case.dart';
import 'package:fincore_food_flutter/src/pdv_express/models/pedido_draft.dart';

void main() {
  setUpAll(() {
    LogService.init('.');
  });

  late FincoreDatabase db;
  late TenantContext context;
  late ConfirmarVendaUseCase useCase;
  const tenantId = FincoreSeeds.seedTenantId;

  setUp(() async {
    db = FincoreDatabase(NativeDatabase.memory());
    context = TenantContext();

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    context.setContext(
      empresa: CoreEmpresa(
        id: tenantId,
        razaoSocial: 'Pastelaria & Salgados Central Ltda',
        nomeFantasia: 'Pastelaria Central Demo',
        documentoFiscal: '11222333000181',
        email: 'contato@demo.com',
        telefone: '11988880001',
        status: StatusEmpresa.ativo,
        plano: PlanoEmpresa.ouro,
        timezone: 'America/Sao_Paulo',
        locale: 'pt_BR',
        currency: 'BRL',
        country: 'BR',
        createdFrom: 'Desktop',
        version: 1,
        tipoPessoa: 'JURIDICA',
        metadata: mockMetadata,
      ),
      usuario: CoreUsuario(
        id: 'user-operador-01',
        nome: 'Operador Caixa',
        email: 'caixa@demo.com',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
    );

    // Popula seeds de formas de pagamento, categorias e produtos
    await FincoreSeeds.populate(db);

    // Garante uma sessão de caixa aberta
    await db.into(db.sessoesCaixaTable).insert(
      SessoesCaixaTableCompanion.insert(
        id: 'sessao-caixa-01',
        tenantId: tenantId,
        operadorId: 'user-operador-01',
        dataAbertura: DateTime.now().toUtc(),
        valorAberturaCentavos: const Value(10000),
        status: const Value('aberta'),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        createdBy: 'user-operador-01',
        updatedBy: 'user-operador-01',
      ),
    );

    useCase = ConfirmarVendaUseCase(db: db, context: context);
  });

  tearDown(() async {
    await db.close();
    context.clear();
  });

  group('AUD-006: Split Payment (Pagamento Dividido / Múltiplas Formas)', () {
    test('Deve processar com sucesso pedido de R\$ 100,00 pago em R\$ 60,00 Cartão + R\$ 40,00 Dinheiro', () async {
      final pedidoId = const Uuid().v4();
      final produtoRef = (await db.select(db.produtosTable).get()).first;

      final pedido = PedidoDraft(
        id: pedidoId,
        tenantId: tenantId,
        tipoLogistica: 'Retirada',
        valorSubtotalCentavos: 10000, // R$ 100,00
        valorTaxaEntregaCentavos: 0,
        valorTotalCentavos: 10000,
        operadorId: 'user-operador-01',
        itens: [
          ItemPedidoDraft(
            produtoId: produtoRef.id,
            nome: produtoRef.nome,
            quantidade: 50,
            valorUnitarioCentavos: 200,
            valorTotalCentavos: 10000,
          ),
        ],
      );

      final pagamentos = [
        PagamentoItemDraft(
          formaPagamentoNome: 'Cartão de Crédito',
          valorCentavos: 6000, // R$ 60,00
          bandeira: 'Mastercard',
          nsu: '123456',
        ),
        PagamentoItemDraft(
          formaPagamentoNome: 'Dinheiro',
          valorCentavos: 4000, // R$ 40,00
          trocoCentavos: 0,
        ),
      ];

      final input = ConfirmarVendaInput(
        pedido: pedido,
        itens: pedido.itens,
        paymentMethod: 'Cartão de Crédito + Dinheiro',
        pagamentos: pagamentos,
        isEdit: false,
        oldItems: const [],
        isEntregaAgendada: false,
        operadorNome: 'Operador Caixa',
        movimentarEstoque: true,
      );

      final result = await useCase.execute(input);

      // 1. Pedido gerado
      expect(result.pedidoId, equals(pedidoId));
      expect(result.numeroPedido, greaterThan(0));

      final pedidoGravado = await (db.select(db.pedidosTable)..where((t) => t.id.equals(pedidoId))).getSingle();
      expect(pedidoGravado.valorTotalCentavos, equals(10000));
      expect(pedidoGravado.formaPagamentoNome, contains('Cartão de Crédito'));
      expect(pedidoGravado.formaPagamentoNome, contains('Dinheiro'));

      // 2. Tabela de Pagamentos Fracionados (pagamentos_pedido_table)
      final pagamentosSalvos = await (db.select(db.pagamentosPedidoTable)..where((t) => t.pedidoId.equals(pedidoId))).get();
      expect(pagamentosSalvos.length, equals(2));
      
      final cartao = pagamentosSalvos.firstWhere((p) => p.formaPagamentoNome == 'Cartão de Crédito');
      final dinheiro = pagamentosSalvos.firstWhere((p) => p.formaPagamentoNome == 'Dinheiro');
      expect(cartao.valorCentavos, equals(6000));
      expect(cartao.bandeira, equals('Mastercard'));
      expect(dinheiro.valorCentavos, equals(4000));

      // 3. Regra Contábil / Fluxo Financeiro:
      // - Apenas o Dinheiro (R$ 40,00) deve criar lançamento no caixa físico
      // - O Cartão (R$ 60,00) entra em Contas a Receber (não no caixa imediato)
      final lancamentos = await (db.select(db.lancamentosFinanceirosTable)..where((t) => t.pedidoId.equals(pedidoId))).get();
      expect(lancamentos.length, equals(1), reason: 'Apenas a fatia em Dinheiro deve movimentar a gaveta do caixa físico');
      expect(lancamentos.first.valorCentavos, equals(4000));
      expect(lancamentos.first.formaPagamentoNome, equals('Dinheiro'));

      // 4. Outbox gerado para as duas fatias de pagamento
      final outboxPagamentos = await (db.select(db.outboxSync)
            ..where((t) => t.entity.equals('pagamento_pedido')))
          .get();
      expect(outboxPagamentos.length, equals(2));
    });

    test('Deve rejeitar venda quando a soma das fatias for inferior ao total da venda', () async {
      final pedidoId = const Uuid().v4();
      final produtoRef = (await db.select(db.produtosTable).get()).first;

      final pedido = PedidoDraft(
        id: pedidoId,
        tenantId: tenantId,
        tipoLogistica: 'Retirada',
        valorSubtotalCentavos: 10000, // R$ 100,00
        valorTaxaEntregaCentavos: 0,
        valorTotalCentavos: 10000,
        operadorId: 'user-operador-01',
        itens: [
          ItemPedidoDraft(
            produtoId: produtoRef.id,
            nome: produtoRef.nome,
            quantidade: 50,
            valorUnitarioCentavos: 200,
            valorTotalCentavos: 10000,
          ),
        ],
      );

      final pagamentosIncompletos = [
        PagamentoItemDraft(
          formaPagamentoNome: 'Dinheiro',
          valorCentavos: 4000, // Faltam R$ 60,00
        ),
      ];

      final input = ConfirmarVendaInput(
        pedido: pedido,
        itens: pedido.itens,
        paymentMethod: 'Dinheiro',
        pagamentos: pagamentosIncompletos,
        isEdit: false,
        oldItems: const [],
        isEntregaAgendada: false,
        operadorNome: 'Operador Caixa',
      );

      expect(() => useCase.execute(input), throwsStateError);
    });
  });
}
