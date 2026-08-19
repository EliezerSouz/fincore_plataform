import 'package:drift/drift.dart';
import 'fincore_database.dart';
import '../common/domain_primitives.dart';

class FincoreSeeds {
  static const seedTenantId = '00000000-0000-4000-a000-000000000001';

  static Future<void> populate(FincoreDatabase db) async {
    final now = DateTime.now();

    // 0. Empresa de Seed com UUID Válido
    await db.into(db.empresasTable).insert(EmpresasTableCompanion.insert(
      id: seedTenantId,
      razaoSocial: 'Demo Empresa LTDA',
      nomeFantasia: 'FINCORE Food Demo',
      documentoFiscal: '00000000000000',
      email: 'demo@fincore.com',
      telefone: '0000000000',
      status: 'ativo',
      plano: 'ouro',
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'seed',
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 1. Categorias
    await db.into(db.categoriasTable).insert(CategoriasTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000101',
      tenantId: seedTenantId,
      nome: 'Salgados Fritos',
      descricao: 'Salgados fritos na hora',
      ordemExibicao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.categoriasTable).insert(CategoriasTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000102',
      tenantId: seedTenantId,
      nome: 'Salgados Assados',
      descricao: 'Salgados assados no forno',
      ordemExibicao: 2,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.categoriasTable).insert(CategoriasTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000103',
      tenantId: seedTenantId,
      nome: 'Bebidas',
      descricao: 'Refrigerantes e sucos',
      ordemExibicao: 3,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 2. Produtos
    await db.into(db.produtosTable).insert(ProdutosTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000201',
      tenantId: seedTenantId,
      categoriaId: '00000000-0000-4000-a000-000000000101',
      nome: 'Mini Coxinha',
      descricao: const Value('Copo de mini coxinhas'),
      ativo: true,
      sku: const Value('MCX001'),
      unidadeVenda: 'un',
      statusComercial: 'ativo',
      tempoMedioMinutos: 5,
      controlaEstoque: false,
      ordemProducao: 1,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.produtosTable).insert(ProdutosTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000202',
      tenantId: seedTenantId,
      categoriaId: '00000000-0000-4000-a000-000000000101',
      nome: 'Kibe',
      descricao: const Value('Kibe frito com hortelã'),
      ativo: true,
      sku: const Value('KIB001'),
      unidadeVenda: 'un',
      statusComercial: 'ativo',
      tempoMedioMinutos: 5,
      controlaEstoque: false,
      ordemProducao: 2,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.produtosTable).insert(ProdutosTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000203',
      tenantId: seedTenantId,
      categoriaId: '00000000-0000-4000-a000-000000000103',
      nome: 'Coca Cola lata',
      descricao: const Value('Lata 350ml'),
      ativo: true,
      sku: const Value('COC001'),
      unidadeVenda: 'un',
      statusComercial: 'ativo',
      tempoMedioMinutos: 5,
      controlaEstoque: false,
      ordemProducao: 3,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 3. Cliente
    await db.into(db.clientesTable).insert(ClientesTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000301',
      tenantId: seedTenantId,
      nome: 'Cliente Consumidor (Balcão)',
      telefone: '00000000000',
      email: const Value('consumidor@fincore.com'),
      documento: const Value('000.000.000-00'),
      observacoes: 'Consumidor final genérico',
      ativo: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 4. Formas de Pagamento
    await db.into(db.formasPagamentoTable).insert(FormasPagamentoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000401',
      tenantId: seedTenantId,
      nome: 'Dinheiro',
      tipo: 'DINHEIRO',
      ordem: 1,
      ativo: true,
      permiteTroco: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.formasPagamentoTable).insert(FormasPagamentoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000402',
      tenantId: seedTenantId,
      nome: 'Pix',
      tipo: 'PIX',
      ordem: 2,
      ativo: true,
      permiteTroco: false,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 5. Tabelas de Precificação
    await db.into(db.tabelasPrecificacaoTable).insert(TabelasPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000901',
      tenantId: seedTenantId,
      nome: 'Tabela Geral',
      descricao: 'Tabela de preços padrão para salgados',
      tipoPolitica: 'faixaQuantidade',
      prioridade: 10,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.tabelasPrecificacaoTable).insert(TabelasPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000902',
      tenantId: seedTenantId,
      nome: 'Tabela Bebidas',
      descricao: 'Tabela de preços para bebidas',
      tipoPolitica: 'unitario',
      prioridade: 5,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 6. Itens das Tabelas (Faixas de Preço)
    // Tabela Geral (Salgados):
    // Faixa 1: 1 a 24 -> R$ 2,00 (200 centavos)
    await db.into(db.itensTabelaPrecificacaoTable).insert(ItensTabelaPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000911',
      tenantId: seedTenantId,
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
      quantidadeMinima: 1,
      quantidadeMaxima: const Value(24),
      valorUnitarioCentavos: 200,
      ordem: 1,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    // Faixa 2: 25 a 49 -> R$ 1,80 (180 centavos)
    await db.into(db.itensTabelaPrecificacaoTable).insert(ItensTabelaPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000912',
      tenantId: seedTenantId,
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
      quantidadeMinima: 25,
      quantidadeMaxima: const Value(49),
      valorUnitarioCentavos: 180,
      ordem: 2,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    // Faixa 3: 50 a 99 -> R$ 1,60 (160 centavos)
    await db.into(db.itensTabelaPrecificacaoTable).insert(ItensTabelaPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000913',
      tenantId: seedTenantId,
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
      quantidadeMinima: 50,
      quantidadeMaxima: const Value(99),
      valorUnitarioCentavos: 160,
      ordem: 3,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    // Faixa 4: >= 100 -> R$ 1,40 (140 centavos)
    await db.into(db.itensTabelaPrecificacaoTable).insert(ItensTabelaPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000914',
      tenantId: seedTenantId,
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
      quantidadeMinima: 100,
      quantidadeMaxima: const Value(null),
      valorUnitarioCentavos: 140,
      ordem: 4,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // Tabela Bebidas:
    // Faixa 1: >= 1 -> R$ 6,00 (600 centavos) (Simulando preço fixo para refrigerantes/sucos)
    await db.into(db.itensTabelaPrecificacaoTable).insert(ItensTabelaPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000921',
      tenantId: seedTenantId,
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000902',
      quantidadeMinima: 1,
      quantidadeMaxima: const Value(null),
      valorUnitarioCentavos: 600,
      ordem: 1,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));

    // 7. Associação de Produtos com Tabelas de Precificação (N:N)
    // Coxinha -> Tabela Geral
    await db.into(db.produtosTabelasPrecificacaoTable).insert(ProdutosTabelasPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000931',
      tenantId: seedTenantId,
      produtoId: '00000000-0000-4000-a000-000000000201',
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
      ativo: true,
      prioridade: 0,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    // Kibe -> Tabela Geral
    await db.into(db.produtosTabelasPrecificacaoTable).insert(ProdutosTabelasPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000932',
      tenantId: seedTenantId,
      produtoId: '00000000-0000-4000-a000-000000000202',
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000901',
      ativo: true,
      prioridade: 0,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
    // Coca Cola lata -> Tabela Bebidas
    await db.into(db.produtosTabelasPrecificacaoTable).insert(ProdutosTabelasPrecificacaoTableCompanion.insert(
      id: '00000000-0000-4000-a000-000000000933',
      tenantId: seedTenantId,
      produtoId: '00000000-0000-4000-a000-000000000203',
      tabelaPrecificacaoId: '00000000-0000-4000-a000-000000000902',
      ativo: true,
      prioridade: 0,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      syncStatus: SyncStatus.synced,
    ));
  }
}
