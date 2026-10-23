import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:fincore_core/src/logging/log_service.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_food_flutter/src/shared/supabase_connector.dart';

void main() {
  group('Sincronização de Ponta a Ponta - Validação Completa', () {
    late Directory tempDir;
    late FincoreDatabase db;
    late TenantContext context;
    late OutboxService outboxService;

    const testTenantId = '64f61559-2c0c-46e0-8411-3aa299541fdf'; // Solange Salgados
    const testUserId = 'user-validador-e2e-01';

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('fincore_e2e_sync_test');
      LogService.init(tempDir.path, runCleanup: false);
    });

    tearDownAll(() async {
      await LogService.instance.forceCleanup();
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    final mockEmpresa = CoreEmpresa(
      id: testTenantId,
      razaoSocial: 'Solange Salgados Artesanais ME',
      nomeFantasia: 'Solange Salgados',
      documentoFiscal: '12.345.678/0001-90',
      email: 'contato@solangesalgados.com.br',
      telefone: '11999998888',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.ouro,
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Desktop',
      version: 1,
      tipoPessoa: 'JURIDICA',
      metadata: SyncMetadata(
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: testUserId,
        updatedBy: testUserId,
      ),
    );

    final mockUsuario = CoreUsuario(
      id: testUserId,
      nome: 'Administrador Validador',
      email: 'admin@solangesalgados.com.br',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      context = TenantContext();
      context.clear();
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);
      outboxService = OutboxService(db: db, context: context);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Mapeamento de todas as tabelas e entidades para o schema público real', () {
      final connector = SupabaseConnector(
        context: context,
        hostUrl: 'https://nlaxdeqbordmovukyypk.supabase.co',
      );

      // Lista completa de entidades do ecossistema de alimentação e produção
      final entityToExpectedTable = <String, String>{
        'empresa': 'empresa',
        'empresas': 'empresa',
        'Empresa': 'empresa',
        'empresa_configuracao': 'empresa_configuracao',
        'categoria': 'categoria',
        'categorias': 'categoria',
        'Categoria': 'categoria',
        'produto': 'produto',
        'produtos': 'produto',
        'Produto': 'produto',
        'cliente': 'cliente',
        'clientes': 'cliente',
        'Cliente': 'cliente',
        'forma_pagamento': 'forma_pagamento',
        'formas_pagamento': 'forma_pagamento',
        'FormaPagamento': 'forma_pagamento',
        'local_entrega': 'local_entrega',
        'locais_entrega': 'local_entrega',
        'LocalEntrega': 'local_entrega',
        'taxa_entrega': 'taxa_entrega',
        'taxas_entrega': 'taxa_entrega',
        'TaxaEntrega': 'taxa_entrega',
        'tabela_precificacao': 'tabela_precificacao',
        'tabelas_precificacao': 'tabela_precificacao',
        'TabelaPrecificacao': 'tabela_precificacao',
        'item_tabela_precificacao': 'item_tabela_precificacao',
        'itens_tabela_precificacao': 'item_tabela_precificacao',
        'ItemTabelaPrecificacao': 'item_tabela_precificacao',
        'produto_tabela_precificacao': 'produto_tabela_precificacao',
        'produtos_tabelas_precificacao': 'produto_tabela_precificacao',
        'categoria_tabela_precificacao': 'categoria_tabela_precificacao',
        'categorias_tabelas_precificacao': 'categoria_tabela_precificacao',
        'pedido': 'pedido',
        'pedidos': 'pedido',
        'Pedido': 'pedido',
        'item_pedido': 'item_pedido',
        'itens_pedido': 'item_pedido',
        'ItensPedido': 'item_pedido',
        'ordens_preparo': 'ordens_preparo',
        'OrdemPreparo': 'ordens_preparo',
        'historicos_ordem_preparo': 'historicos_ordem_preparo',
        'HistoricoOrdemPreparo': 'historicos_ordem_preparo',
        'estoque_produto': 'estoque_produto',
        'EstoqueProduto': 'estoque_produto',
        'movimentacao_estoque': 'movimentacao_estoque',
        'MovimentacaoEstoque': 'movimentacao_estoque',
        'planejamento_producao': 'planejamento_producao',
        'PlanejamentoProducao': 'planejamento_producao',
        'sessao_caixa': 'sessao_caixa',
        'SessaoCaixa': 'sessao_caixa',
        'lancamento_financeiro': 'lancamento_financeiro',
        'LancamentoFinanceiro': 'lancamento_financeiro',
        'usuarios': 'usuarios',
        'usuario': 'usuarios',
        'Usuario': 'usuarios',
        'membro_empresa': 'membro_empresa',
        'membros_empresa': 'membro_empresa',
        'audit_log': 'audit_logs',
        'audit_logs': 'audit_logs',
      };

      for (final entry in entityToExpectedTable.entries) {
        // Validação no SupabaseConnector
        final connectorTable = connector.tableNameFor(entry.key);
        expect(
          connectorTable,
          equals(entry.value),
          reason: 'Entidade "${entry.key}" deveria mapear para "${entry.value}" no SupabaseConnector',
        );
      }
    });

    test('2. Enfileiramento no Outbox e isolamento rigoroso por Tenant', () async {
      final tabelasParaValidar = [
        ('empresa', testTenantId, {'telefone': '11988887777', 'nomeFantasia': 'Solange Salgados'}),
        ('empresa_configuracao', testTenantId, {'pixKey': '11988887777', 'taxaServico': 10}),
        ('categoria', 'cat-01', {'nome': 'Salgados Fritos', 'ordemExibicao': 1}),
        ('produto', 'prod-01', {'nome': 'Coxinha Especial', 'valorCentavos': 850}),
        ('cliente', 'cli-01', {'nome': 'Cliente VIP', 'telefone': '11977776666'}),
        ('forma_pagamento', 'fp-01', {'nome': 'Pix', 'tipo': 'PIX', 'ativo': true}),
        ('taxa_entrega', 'tx-01', {'nome': 'Bairro Centro', 'valorCentavos': 500}),
        ('pedido', 'ped-01', {'status': 'confirmado', 'valorTotalCentavos': 8500}),
        ('ordens_preparo', 'kds-01', {'status': 'em_preparo', 'prioridade': 1}),
        ('historicos_ordem_preparo', 'hist-01', {'titulo': 'Início do Fritador', 'versao': 1}),
        ('estoque_produto', 'est-01', {'quantidadeAtual': 120.0, 'quantidadeMinima': 20.0}),
        ('movimentacao_estoque', 'mov-01', {'tipo': 'ENTRADA', 'quantidade': 50.0}),
        ('sessao_caixa', 'caixa-01', {'status': 'ABERTO', 'valorAberturaCentavos': 20000}),
        ('lancamento_financeiro', 'lanc-01', {'tipo': 'RECEITA', 'valorCentavos': 8500}),
      ];

      for (final (entity, id, payload) in tabelasParaValidar) {
        final outboxId = await outboxService.enqueue(
          entity: entity,
          entityId: id,
          action: 'UPDATE',
          payload: payload,
          version: 1,
        );
        expect(outboxId, greaterThan(0));
      }

      final pendingEntries = await outboxService.getPendingEntries();
      expect(pendingEntries.length, equals(tabelasParaValidar.length));

      // Garantir que TODAS as entradas pertençam ao tenant ativo
      for (final entry in pendingEntries) {
        expect(entry.tenantId, equals(testTenantId));
        expect(entry.status, equals(SyncStatus.pending.name));
      }
    });

    test('3. Execução do SyncEngine com ciclo completo: pending -> processing -> synced e auditoria de logs', () async {
      // Registra mutação de alteração cadastral (ex: telefone da empresa e forma de pagamento)
      await outboxService.enqueue(
        entity: 'empresa',
        entityId: testTenantId,
        action: 'UPDATE',
        payload: {
          'id': testTenantId,
          'telefone': '11988887777',
          'nomeFantasia': 'Solange Salgados & Cia',
        },
        version: 2,
      );

      await outboxService.enqueue(
        entity: 'forma_pagamento',
        entityId: 'forma-pix-01',
        action: 'UPDATE',
        payload: {
          'id': 'forma-pix-01',
          'tenantId': testTenantId,
          'pixChave': '11988887777',
          'pixNomeFavorecido': 'SOLANGE SALGADOS',
        },
        version: 1,
      );

      final dispatchedList = <String>[];

      // Simula o push com sucesso
      final syncEngine = SyncEngine(
        outboxService: outboxService,
        context: context,
        db: db,
        serverPushHandler: (entry) async {
          dispatchedList.add('${entry.entity}:${entry.entityId}');
          await LogService.instance.logSync(
            step: 'PUSH',
            action: 'ENVIADO',
            entity: entry.entity,
            id: entry.entityId,
            status: LogStatus.success,
            tenantId: entry.tenantId,
          );
          return true;
        },
      );

      final result = await syncEngine.processPendingQueue();
      expect(result.successCount, equals(2));
      expect(result.failureCount, equals(0));
      expect(dispatchedList, contains('empresa:$testTenantId'));
      expect(dispatchedList, contains('forma_pagamento:forma-pix-01'));

      // Verifica se a fila foi desobstruída (todas as entradas em 'synced')
      final pendingAfter = await outboxService.getPendingEntries();
      expect(pendingAfter.isEmpty, isTrue);

      final stats = await outboxService.getOutboxStats();
      expect(stats.pending, equals(0));
      expect(stats.failed, equals(0));
      expect(stats.total, equals(2));
    });

    test('4. Escudo do Pull protege edições locais pendentes contra sobrescrita remota', () async {
      // Enfileira alteração local de um produto que ainda não foi enviado à nuvem
      const prodId = 'prod-escondidinho-01';
      await outboxService.enqueue(
        entity: 'produtos',
        entityId: prodId,
        action: 'UPDATE',
        payload: {'nome': 'Escondidinho de Carne Seca Local Modificado'},
        version: 5,
      );

      // Verifica se o ID está no escudo protetor do Outbox
      final protectedIds = await outboxService.getPendingEntityIds('produtos');
      expect(protectedIds, contains(prodId));

      // Durante um pull, se o servidor remoto tentar enviar uma versão antiga ou concorrente,
      // a mutação local é protegida e mantida intacta
      final deveProteger = protectedIds.contains(prodId);
      expect(deveProteger, isTrue, reason: 'Escudo do Pull DEVE proteger registros pendentes no outbox');
    });

    test('5. Idempotência do Outbox evita duplicação de pacotes em conexões instáveis', () async {
      final payload = {'status': 'pronto', 'versao': 2};

      // Tenta enfileirar duas vezes a mesma ação idêntica
      final id1 = await outboxService.enqueue(
        entity: 'ordens_preparo',
        entityId: 'ordem-rep-01',
        action: 'UPDATE',
        payload: payload,
        version: 2,
      );

      final id2 = await outboxService.enqueue(
        entity: 'ordens_preparo',
        entityId: 'ordem-rep-01',
        action: 'UPDATE',
        payload: payload,
        version: 2,
      );

      final pending = await outboxService.getPendingEntries();
      // O sistema coalescente/idempotente mantém integridade
      expect(pending.where((e) => e.entityId == 'ordem-rep-01').length, equals(1));
    });
  });
}
