// ═══════════════════════════════════════════════════════════════════════════
// FINCORE Food — Seed de Dados para Teste End-to-End
// ═══════════════════════════════════════════════════════════════════════════
//
// Uso:
//   cd fincore_food_server
//   dart run seed_test_data.dart
//
// Pré-requisito: banco zerado e migrations aplicadas
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:postgres/postgres.dart';

// ── Credenciais ──────────────────────────────────────────────────────────────
const _host     = 'db.nlaxdeqbordmovukyypk.supabase.co';
const _port     = 5432;
const _database = 'postgres';
const _user     = 'postgres';
const _password = 'GeR9cjvrXrujvL0R';

// ── IDs fixos para rastreabilidade ───────────────────────────────────────────
const _empresaId        = '11111111-1111-1111-1111-111111111111';
const _usuarioId        = '22222222-2222-2222-2222-222222222222';
const _configId         = '33333333-3333-3333-3333-333333333333';
const _catLanchesId     = 'aaaa0001-0000-0000-0000-000000000001';
const _catBebidasId     = 'aaaa0001-0000-0000-0000-000000000002';
const _catSobremesasId  = 'aaaa0001-0000-0000-0000-000000000003';
const _pgDinheiroId     = 'bbbb0001-0000-0000-0000-000000000001';
const _pgCartaoId       = 'bbbb0001-0000-0000-0000-000000000002';
const _pgPixId          = 'bbbb0001-0000-0000-0000-000000000003';
const _prodXBurgId      = 'cccc0001-0000-0000-0000-000000000001';
const _prodCocaId       = 'cccc0001-0000-0000-0000-000000000002';
const _tabelaPrecoXBurgId = 'dddd0001-0000-0000-0000-000000000001';
const _tabelaPrecoCocaId  = 'dddd0001-0000-0000-0000-000000000002';
const _estXBurgId       = 'eeee0001-0000-0000-0000-000000000001';
const _estCocaId        = 'eeee0001-0000-0000-0000-000000000002';
const _clienteId        = 'ffff0001-0000-0000-0000-000000000001';
const _sessaoCaixaId    = '1a1a0001-0000-0000-0000-000000000001';
const _pedidoId         = '2b2b0001-0000-0000-0000-000000000001';
const _itemXBurg1Id     = '3c3c0001-0000-0000-0000-000000000001';
const _itemXBurg2Id     = '3c3c0001-0000-0000-0000-000000000002';
const _itemCocaId       = '3c3c0001-0000-0000-0000-000000000003';
const _lancamentoId     = '4d4d0001-0000-0000-0000-000000000001';

late Connection _conn;

void main() async {
  _header('FINCORE FOOD — SEED DE DADOS DE TESTE E2E (CORRIGIDO)');
  _info('Banco: $_host / $_database');
  _info('');

  try {
    _step('Conectando ao banco...');
    _conn = await Connection.open(
      Endpoint(host: _host, port: _port, database: _database, username: _user, password: _password),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    _ok('Conexão estabelecida!');
  } catch (e) {
    _erro('Falha ao conectar: $e');
    exitCode = 1;
    return;
  }

  final erros = <String>[];

  try {
    await _step1_empresa(erros);
    await _step2_usuario(erros);
    await _step3_membro(erros);
    await _step4_configuracoes(erros);
    await _step5_categorias(erros);
    await _step6_formasPagamento(erros);
    await _step7_produtos(erros);
    await _step8_tabelaPreco(erros);
    await _step9_estoqueInicial(erros);
    await _step10_cliente(erros);
    await _step11_abrirCaixa(erros);
    await _step12_criarPedido(erros);
    await _step13_validarReserva(erros);
    await _step14_lancamentoFinanceiro(erros);
    await _step15_entregarPedido(erros);
    await _step16_validarEstoque(erros);
    await _step17_fecharCaixa(erros);
  } finally {
    await _conn.close();
  }

  _header('RESULTADO FINAL DO SEED');
  if (erros.isEmpty) {
    _ok('🎉 Todos os passos concluídos com sucesso!');
  } else {
    _aviso('⚠️  ${erros.length} erro(s) durante o seed:');
    for (final e in erros) {
      _erro('  - $e');
    }
    exitCode = 1;
  }
}

Future<void> _step1_empresa(List<String> erros) async {
  _step('Passo 1 — Cadastrando empresa...');
  try {
    await _exec('''
      INSERT INTO public.empresa (
        id, "razaoSocial", "nomeFantasia", "documentoFiscal", email, telefone,
        status, plano, timezone, locale, currency, country, "createdFrom", "tipoPessoa",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_empresaId', 'Lanchonete Teste LTDA', 'FinFood Teste', '12345678000195',
        'contato@fincoretest.com', '11999990000', 'ativo', 'premium', 'America/Sao_Paulo',
        'pt_BR', 'BRL', 'BR', 'teste_e2e', 'J',
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');
    _ok('Empresa criada: Lanchonete Teste (ID: $_empresaId)');
  } catch (e) {
    erros.add('Passo 1 (empresa): $e');
    _erro('$e');
  }
}

Future<void> _step2_usuario(List<String> erros) async {
  _step('Passo 2 — Cadastrando usuário owner...');
  try {
    await _exec('''
      INSERT INTO public.usuarios (
        id, "activeTenantId", username, email, nome, ativo,
        "criadoEm", "atualizadoEm"
      ) VALUES (
        '$_usuarioId', '$_empresaId', 'owner', 'owner@fincoretest.com', 'João Silva (Owner)', true,
        now(), now()
      ) ON CONFLICT (id) DO NOTHING;
    ''');
    _ok('Usuário criado: owner@fincoretest.com na tabela usuarios');
  } catch (e) {
    erros.add('Passo 2 (usuarios): $e');
    _erro('$e');
  }
}

Future<void> _step3_membro(List<String> erros) async {
  _step('Passo 3 — Vinculando owner à empresa (membro_empresa)...');
  try {
    await _exec('''
      INSERT INTO public.membro_empresa (
        id, "tenantId", "usuarioId", role, ativo, "convidadoEm",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_usuarioId', 'owner', true, now(),
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT DO NOTHING;
    ''');
    _ok('Membro vinculado: owner → $_empresaId');
  } catch (e) {
    erros.add('Passo 3 (membro_empresa): $e');
    _erro('$e');
  }
}

Future<void> _step4_configuracoes(List<String> erros) async {
  _step('Passo 4 — Configurações gerais da empresa...');
  try {
    await _exec('''
      INSERT INTO public.empresa_configuracao (
        id, "tenantId", "taxaServico", "usarWhatsApp", tema, "mensagemRodape",
        "autoPrintCaixa", "autoPrintCozinha", "autoPrintBalcao", "autoPrintExpedicao",
        "viasCliente", "viasCozinha", "viasBalcao", "viasExpedicao",
        "larguraPapel", "cortarPapel", "abrirGaveta",
        "imprimirQRCode", "imprimirCopiaCola", "imprimirRodape", "imprimirLogo",
        "pixTipo", "taxaEntregaPorKm", "valorPorKmCentavos", "modoDeliveryAtivo", "clienteObrigatorioVenda",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_configId', '$_empresaId', 0.0, false, 'escuro', 'Obrigado pela preferência!',
        false, false, false, false,
        1, 1, 1, 1,
        80, false, false,
        false, false, false, false,
        'cnpj', true, 150, true, false,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');
    _ok('Configurações aplicadas: entrega por km=true, valor/km=R\$1,50');
  } catch (e) {
    erros.add('Passo 4 (empresa_configuracao): $e');
    _erro('$e');
  }
}

Future<void> _step5_categorias(List<String> erros) async {
  _step('Passo 5 — Cadastrando categorias...');
  final cats = [
    (_catLanchesId, 'Lanches', 1),
    (_catBebidasId, 'Bebidas', 2),
    (_catSobremesasId, 'Sobremesas', 3),
  ];
  for (final (id, nome, ordem) in cats) {
    try {
      await _exec('''
        INSERT INTO public.categoria (
          id, "tenantId", nome, descricao, "ordemExibicao", ativo,
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          '$id', '$_empresaId', '$nome', 'Categoria de lanchonete E2E', $ordem, true,
          now(), now(), '$_usuarioId', '$_usuarioId', 1
        ) ON CONFLICT (id) DO NOTHING;
      ''');
      _ok('  ✅ Categoria $nome criada');
    } catch (e) {
      erros.add('Passo 5 (categoria $nome): $e');
      _erro('  ❌ $nome → $e');
    }
  }
}

Future<void> _step6_formasPagamento(List<String> erros) async {
  _step('Passo 6 — Formas de pagamento...');
  final fgs = [
    (_pgDinheiroId, 'Dinheiro', 'dinheiro', 1),
    (_pgCartaoId, 'Cartão Crédito', 'cartao_credito', 2),
    (_pgPixId, 'Pix', 'pix', 3),
  ];
  for (final (id, nome, tipo, ordem) in fgs) {
    try {
      await _exec('''
        INSERT INTO public.forma_pagamento (
          id, "tenantId", nome, tipo, ordem, ativo, "permiteTroco",
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          '$id', '$_empresaId', '$nome', '$tipo', $ordem, true, true,
          now(), now(), '$_usuarioId', '$_usuarioId', 1
        ) ON CONFLICT (id) DO NOTHING;
      ''');
      _ok('  ✅ Forma de pagamento $nome');
    } catch (e) {
      erros.add('Passo 6 (forma_pagamento $nome): $e');
      _erro('  ❌ $nome → $e');
    }
  }
}

Future<void> _step7_produtos(List<String> erros) async {
  _step('Passo 7 — Cadastrando produtos...');
  final prods = [
    (_prodXBurgId, 'X-Burguer', _catLanchesId, 1),
    (_prodCocaId, 'Coca-Cola 350ml', _catBebidasId, 2),
  ];
  for (final (id, nome, catId, ordem) in prods) {
    try {
      await _exec('''
        INSERT INTO public.produto (
          id, "tenantId", nome, "categoriaId", "unidadeVenda",
          "statusComercial", "tempoMedioMinutos", "controlaEstoque", "ordemProducao", ativo,
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          '$id', '$_empresaId', '$nome', '$catId', 'un',
          'ativo', 15, true, $ordem, true,
          now(), now(), '$_usuarioId', '$_usuarioId', 1
        ) ON CONFLICT (id) DO NOTHING;
      ''');
      _ok('  ✅ Produto $nome criado.');
    } catch (e) {
      erros.add('Passo 7 (produto $nome): $e');
      _erro('  ❌ $nome → $e');
    }
  }
}

Future<void> _step8_tabelaPreco(List<String> erros) async {
  _step('Passo 8 — Tabelas de preços escalonadas...');
  try {
    // 1. Tabela do X-Burguer
    await _exec('''
      INSERT INTO public.tabela_precificacao (
        id, "tenantId", nome, descricao, "tipoPolitica", prioridade, ativo,
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_tabelaPrecoXBurgId', '$_empresaId', 'Tabela X-Burguer', 'Preços do X-Burguer', 'varejo', 1, true,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');
    
    await _exec('''
      INSERT INTO public.produto_tabela_precificacao (
        id, "tenantId", "produtoId", "tabelaPrecificacaoId", ativo, prioridade,
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_prodXBurgId', '$_tabelaPrecoXBurgId', true, 1,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT DO NOTHING;
    ''');

    await _exec('''
      INSERT INTO public.item_tabela_precificacao (
        id, "tenantId", "tabelaPrecificacaoId", "quantidadeMinima", "valorUnitarioCentavos", ordem,
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_tabelaPrecoXBurgId', 1, 1800, 1,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT DO NOTHING;
    ''');

    // 2. Tabela da Coca-Cola
    await _exec('''
      INSERT INTO public.tabela_precificacao (
        id, "tenantId", nome, descricao, "tipoPolitica", prioridade, ativo,
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_tabelaPrecoCocaId', '$_empresaId', 'Tabela Coca-Cola', 'Preços de Bebidas', 'varejo', 1, true,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');

    await _exec('''
      INSERT INTO public.produto_tabela_precificacao (
        id, "tenantId", "produtoId", "tabelaPrecificacaoId", ativo, prioridade,
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_prodCocaId', '$_tabelaPrecoCocaId', true, 1,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT DO NOTHING;
    ''');

    await _exec('''
      INSERT INTO public.item_tabela_precificacao (
        id, "tenantId", "tabelaPrecificacaoId", "quantidadeMinima", "valorUnitarioCentavos", ordem,
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_tabelaPrecoCocaId', 1, 700, 1,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT DO NOTHING;
    ''');

    _ok('Tabelas de precificação vinculadas aos produtos com sucesso.');
  } catch (e) {
    erros.add('Passo 8 (tabela_preco): $e');
    _erro('$e');
  }
}

Future<void> _step9_estoqueInicial(List<String> erros) async {
  _step('Passo 9 — Estoque inicial...');
  final estoques = [
    (_estXBurgId, _prodXBurgId, 50, 'X-Burguer'),
    (_estCocaId, _prodCocaId, 100, 'Coca-Cola'),
  ];
  for (final (id, prodId, qtd, nome) in estoques) {
    try {
      await _exec('''
        INSERT INTO public.estoque_produto (
          id, "tenantId", "produtoId", "quantidadeAtual", "quantidadeReservada", "quantidadeMinima", "quantidadeMaxima",
          "quantidadeProducaoLote", "diasCoberturaAlvo", unidade,
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          '$id', '$_empresaId', '$prodId',
          $qtd, 0, 5, 200,
          50, 3, 'un',
          now(), now(), '$_usuarioId', '$_usuarioId', 1
        ) ON CONFLICT ("tenantId", "produtoId") DO UPDATE SET
          "quantidadeAtual" = $qtd,
          "quantidadeReservada" = 0,
          "updatedAt" = now();
      ''');

      await _exec('''
        INSERT INTO public.movimentacao_estoque (
          id, "tenantId", "produtoId", tipo, quantidade, "quantidadeAntes", "quantidadeDepois",
          motivo, "operadorId", "dataHora",
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          gen_random_uuid(), '$_empresaId', '$prodId', 'entrada_manual',
          $qtd, 0, $qtd,
          'Estoque inicial para teste E2E', '$_usuarioId', now(),
          now(), now(), '$_usuarioId', '$_usuarioId', 1
        );
      ''');
      _ok('  ✅ Estoque implantado para $nome: $qtd un.');
    } catch (e) {
      erros.add('Passo 9 (estoque $nome): $e');
      _erro('  ❌ $nome → $e');
    }
  }
}

Future<void> _step10_cliente(List<String> erros) async {
  _step('Passo 10 — Cadastrando cliente...');
  try {
    await _exec('''
      INSERT INTO public.cliente (
        id, "tenantId", nome, documento, telefone, email, observacoes, ativo, "aceitaWhatsapp", "aceitaMarketing",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_clienteId', '$_empresaId',
        'João da Silva', '12345678901', '11988880000', 'joao@teste.com', 'Cliente de teste E2E', true, true, false,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');
    _ok('Cliente cadastrado: João da Silva (CPF/documento: 12345678901)');
  } catch (e) {
    erros.add('Passo 10 (cliente): $e');
    _erro('$e');
  }
}

Future<void> _step11_abrirCaixa(List<String> erros) async {
  _step('Passo 11 — Abrindo sessão de caixa...');
  try {
    await _exec('''
      INSERT INTO public.sessao_caixa (
        id, "tenantId", "operadorId", "operadorNome",
        status, "dataAbertura", "valorAberturaCentavos", "totalVendasCentavos", "totalDespesasCentavos",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_sessaoCaixaId', '$_empresaId', '$_usuarioId', 'João Silva (Owner)',
        'aberta', now(), 10000, 0, 0,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');
    _ok('Sessão de caixa aberta com R\$100,00.');
  } catch (e) {
    erros.add('Passo 11 (sessao_caixa): $e');
    _erro('$e');
  }
}

Future<void> _step12_criarPedido(List<String> erros) async {
  _step('Passo 12 — Criando pedido (2x X-Burguer + 1x Coca-Cola)...');
  try {
    await _exec('''
      INSERT INTO public.pedido (
        id, "tenantId", "clienteId", status, "tipoLogistica",
        "valorSubtotalCentavos", "valorTaxaEntregaCentavos", "valorTotalCentavos",
        "canalOrigem", "dataHoraCriacao",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_pedidoId', '$_empresaId', '$_clienteId', 'rascunho', 'entrega',
        4300, 500, 4800,
        'pdv_express', now(),
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');

    // Itens
    // 2x X-Burguer
    await _exec('''
      INSERT INTO public.item_pedido (
        id, "tenantId", "pedidoId", "produtoId", "nomeProduto", quantidade, "valorUnitarioCentavos", "valorTotalCentavos",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_itemXBurg1Id', '$_empresaId', '$_pedidoId', '$_prodXBurgId', 'X-Burguer', 2.0, 1800, 3600,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');

    // 1x Coca-Cola
    await _exec('''
      INSERT INTO public.item_pedido (
        id, "tenantId", "pedidoId", "produtoId", "nomeProduto", quantidade, "valorUnitarioCentavos", "valorTotalCentavos",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_itemCocaId', '$_empresaId', '$_pedidoId', '$_prodCocaId', 'Coca-Cola 350ml', 1.0, 700, 700,
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');

    // Mudar pedido para "confirmado" para simbolizar fechamento do carrinho e reservar estoque
    await _exec('''
      UPDATE public.pedido SET status = 'confirmado' WHERE id = '$_pedidoId';
    ''');

    // Reservar estoque
    await _exec('''
      UPDATE public.estoque_produto
      SET "quantidadeReservada" = "quantidadeReservada" + 2,
          "updatedAt" = now()
      WHERE "tenantId" = '$_empresaId' AND "produtoId" = '$_prodXBurgId';
    ''');

    _ok('Pedido criado com itens e estoque reservado.');
  } catch (e) {
    erros.add('Passo 12 (pedido): $e');
    _erro('$e');
  }
}

Future<void> _step13_validarReserva(List<String> erros) async {
  _step('Passo 13 — Validando reserva de estoque...');
  try {
    final res = await _conn.execute('''
      SELECT "quantidadeAtual", "quantidadeReservada"
      FROM public.estoque_produto
      WHERE "tenantId" = '$_empresaId' AND "produtoId" = '$_prodXBurgId';
    ''');
    final atual    = res.first[0] as int;
    final reserva  = res.first[1] as int;
    if (reserva == 2) {
      _ok('✅ X-Burguer: Atual=$atual | Reservada=$reserva (OK)');
    } else {
      erros.add('Passo 13: X-Burguer reservada=$reserva, esperado 2');
      _erro('❌ X-Burguer reservada=$reserva (esperado: 2)');
    }
  } catch (e) {
    erros.add('Passo 13 (reserva): $e');
    _erro('$e');
  }
}

Future<void> _step14_lancamentoFinanceiro(List<String> erros) async {
  _step('Passo 14 — Pagamento do pedido (Pix R\$48,00)...');
  try {
    await _exec('''
      INSERT INTO public.lancamento_financeiro (
        id, "tenantId", "sessaoCaixaId", "pedidoId", tipo, "formaPagamentoId", "formaPagamentoNome", "valorCentavos",
        descricao, "operadorId", "dataHora",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        '$_lancamentoId', '$_empresaId', '$_sessaoCaixaId', '$_pedidoId', 'recebimento', '$_pgPixId', 'Pix', 4800,
        'Pagamento pedido E2E', '$_usuarioId', now(),
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      ) ON CONFLICT (id) DO NOTHING;
    ''');

    await _exec('''
      UPDATE public.sessao_caixa
      SET "totalVendasCentavos" = "totalVendasCentavos" + 4800,
          "updatedAt" = now()
      WHERE id = '$_sessaoCaixaId';
    ''');
    _ok('Lançamento financeiro de recebimento Pix efetuado.');
  } catch (e) {
    erros.add('Passo 14 (lancamento): $e');
    _erro('$e');
  }
}

Future<void> _step15_entregarPedido(List<String> erros) async {
  _step('Passo 15 — Entregando pedido e baixando estoque...');
  try {
    await _exec('''
      UPDATE public.pedido SET status = 'entregue' WHERE id = '$_pedidoId';
    ''');

    // Baixa de estoque do X-Burguer
    await _exec('''
      UPDATE public.estoque_produto
      SET "quantidadeAtual" = "quantidadeAtual" - 2,
          "quantidadeReservada" = "quantidadeReservada" - 2,
          "updatedAt" = now()
      WHERE "tenantId" = '$_empresaId' AND "produtoId" = '$_prodXBurgId';
    ''');

    await _exec('''
      INSERT INTO public.movimentacao_estoque (
        id, "tenantId", "produtoId", "pedidoId", tipo, quantidade, "quantidadeAntes", "quantidadeDepois",
        motivo, "operadorId", "dataHora",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_prodXBurgId', '$_pedidoId', 'saida_venda', 2, 50, 48,
        'Venda E2E', '$_usuarioId', now(),
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      );
    ''');

    // Baixa de estoque da Coca-Cola
    await _exec('''
      UPDATE public.estoque_produto
      SET "quantidadeAtual" = "quantidadeAtual" - 1,
          "updatedAt" = now()
      WHERE "tenantId" = '$_empresaId' AND "produtoId" = '$_prodCocaId';
    ''');

    await _exec('''
      INSERT INTO public.movimentacao_estoque (
        id, "tenantId", "produtoId", "pedidoId", tipo, quantidade, "quantidadeAntes", "quantidadeDepois",
        motivo, "operadorId", "dataHora",
        "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
      ) VALUES (
        gen_random_uuid(), '$_empresaId', '$_prodCocaId', '$_pedidoId', 'saida_venda', 1, 100, 99,
        'Venda E2E', '$_usuarioId', now(),
        now(), now(), '$_usuarioId', '$_usuarioId', 1
      );
    ''');

    _ok('Pedido marcado como entregue. Reservas e estoques ajustados.');
  } catch (e) {
    erros.add('Passo 15 (entrega): $e');
    _erro('$e');
  }
}

Future<void> _step16_validarEstoque(List<String> erros) async {
  _step('Passo 16 — Validando estoque final...');
  try {
    final resX = await _conn.execute("SELECT \"quantidadeAtual\" FROM public.estoque_produto WHERE \"tenantId\" = '$_empresaId' AND \"produtoId\" = '$_prodXBurgId'");
    final resC = await _conn.execute("SELECT \"quantidadeAtual\" FROM public.estoque_produto WHERE \"tenantId\" = '$_empresaId' AND \"produtoId\" = '$_prodCocaId'");
    final qX = resX.first[0] as int;
    final qC = resC.first[0] as int;

    if (qX == 48 && qC == 99) {
      _ok('✅ Estoque OK: X-Burguer = $qX (esp: 48) | Coca-Cola = $qC (esp: 99)');
    } else {
      erros.add('Passo 16: Estoque inconsistente X-Burguer=$qX, Coca=$qC');
      _erro('❌ Estoque inconsistente: X-Burguer=$qX (esp: 48) | Coca-Cola=$qC (esp: 99)');
    }
  } catch (e) {
    erros.add('Passo 16 (validar estoque): $e');
    _erro('$e');
  }
}

Future<void> _step17_fecharCaixa(List<String> erros) async {
  _step('Passo 17 — Fechando caixa...');
  try {
    await _exec('''
      UPDATE public.sessao_caixa
      SET status = 'fechada',
          "dataFechamento" = now(),
          "valorFechamentoCentavos" = 14800,
          "diferencaCentavos" = 0,
          observacoes = 'Caixa fechado no teste E2E',
          "updatedAt" = now(),
          "updatedBy" = '$_usuarioId'
      WHERE id = '$_sessaoCaixaId';
    ''');
    _ok('Caixa fechado com sucesso.');
  } catch (e) {
    erros.add('Passo 17 (fechamento): $e');
    _erro('$e');
  }
}

// ═══════════════════════════════════════════════════════════════════════════

Future<void> _exec(String sql) async {
  await _conn.execute(sql);
}

String gen() {
  // Gera UUID v4 simples
  final r = <int>[];
  for (var i = 0; i < 16; i++) {
    r.add((DateTime.now().microsecondsSinceEpoch + i * 7919) % 256);
  }
  r[6] = (r[6] & 0x0f) | 0x40;
  r[8] = (r[8] & 0x3f) | 0x80;
  String hex(int n) => n.toRadixString(16).padLeft(2, '0');
  return '${hex(r[0])}${hex(r[1])}${hex(r[2])}${hex(r[3])}-'
      '${hex(r[4])}${hex(r[5])}-'
      '${hex(r[6])}${hex(r[7])}-'
      '${hex(r[8])}${hex(r[9])}-'
      '${hex(r[10])}${hex(r[11])}${hex(r[12])}${hex(r[13])}${hex(r[14])}${hex(r[15])}';
}

void _header(String msg) => print('\n╔══ $msg ══╗');
void _step(String msg)   => print('\n➜  $msg');
void _ok(String msg)     => print('   $msg');
void _aviso(String msg)  => print('   $msg');
void _info(String msg)   => print('   $msg');
void _erro(String msg)   => print('   ✗ $msg');
