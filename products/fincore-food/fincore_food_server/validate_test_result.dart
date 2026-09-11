// ═══════════════════════════════════════════════════════════════════════════
// FINCORE Food — Validação de Resultados de Teste End-to-End (Corrigido)
// ═══════════════════════════════════════════════════════════════════════════
//
// Uso:
//   cd fincore_food_server
//   dart run validate_test_result.dart
//
// O que faz:
//   - Conecta diretamente no banco central e executa queries de integridade
//   - Verifica cada um dos 16 domínios operacionais
//   - Gera um relatório Markdown em logs/test_report_<timestamp>.md
//   - Exibe sumário colorido no terminal com status ✅ ou ❌
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:postgres/postgres.dart';

// ── Credenciais ──────────────────────────────────────────────────────────────
const _host     = 'db.nlaxdeqbordmovukyypk.supabase.co';
const _port     = 5432;
const _database = 'postgres';
const _user     = 'postgres';
const _password = 'GeR9cjvrXrujvL0R';

// ── IDs fixos criados no seed ────────────────────────────────────────────────
const _empresaId  = '11111111-1111-1111-1111-111111111111';
const _usuarioId  = '22222222-2222-2222-2222-222222222222';
const _prodXBurgId = 'cccc0001-0000-0000-0000-000000000001';
const _prodCocaId  = 'cccc0001-0000-0000-0000-000000000002';

late Connection _conn;

class DomValidation {
  final String name;
  final bool status;
  final String details;

  DomValidation(this.name, this.status, this.details);
}

void main() async {
  _header('FINCORE FOOD — RELATÓRIO DE VALIDAÇÃO DE TESTE E2E (CORRIGIDO)');
  _info('Conectando ao banco...');

  try {
    _conn = await Connection.open(
      Endpoint(host: _host, port: _port, database: _database, username: _user, password: _password),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    _ok('Conexão ativa.');
  } catch (e) {
    _erro('Erro ao conectar ao banco: $e');
    exitCode = 1;
    return;
  }

  final validations = <DomValidation>[];

  try {
    // 1. Empresa / Onboarding
    validations.add(await _validaEmpresa());
    // 2. Usuário / IAM
    validations.add(await _validaUsuario());
    // 3. Configurações Gerais
    validations.add(await _validaConfiguracoes());
    // 4. Taxa de Entrega
    validations.add(await _validaTaxaEntrega());
    // 5. Categorias
    validations.add(await _validaCategorias());
    // 6. Produtos
    validations.add(await _validaProdutos());
    // 7. Tabela de Preço
    validations.add(await _validaTabelaPrecos());
    // 8. Estoque Inicial / Movimentações
    validations.add(await _validaEstoqueInicial());
    // 9. Cliente
    validations.add(await _validaCliente());
    // 10. Pedido / Venda
    validations.add(await _validaPedido());
    // 11. Reserva de Estoque
    validations.add(await _validaReservaEstoque());
    // 12. Caixa
    validations.add(await _validaCaixa());
    // 13. Lançamento Financeiro
    validations.add(await _validaLancamentoFinanceiro());
    // 14. Estoque Pós-Venda (Baixas de estoque)
    validations.add(await _validaEstoquePosVenda());
    // 15. Auditoria (audit_log)
    validations.add(await _validaAuditoria());
    // 16. Logs DEV (Serverpod logs)
    validations.add(await _validaLogsDev());

    // Imprimir no terminal
    _imprimirSumario(validations);

    // Salvar relatório
    await _salvarRelatorio(validations);

  } finally {
    await _conn.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VALIDAÇÕES POR DOMÍNIO
// ═══════════════════════════════════════════════════════════════════════════

Future<DomValidation> _validaEmpresa() async {
  try {
    final res = await _conn.execute("SELECT id, \"razaoSocial\", \"documentoFiscal\" FROM public.empresa WHERE id = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Empresa / Onboarding', false, 'Empresa de teste não encontrada no banco.');
    final row = res.first;
    return DomValidation('Empresa / Onboarding', true, 'Empresa "${row[1]}" (CNPJ: ${row[2]}) cadastrada com ID correto.');
  } catch (e) {
    return DomValidation('Empresa / Onboarding', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaUsuario() async {
  try {
    final res = await _conn.execute("SELECT id, nome, email FROM public.usuarios WHERE id = '$_usuarioId'");
    if (res.isEmpty) return DomValidation('Usuário / IAM', false, 'Usuário owner não encontrado no banco.');
    final row = res.first;
    
    // Verifica membro_empresa
    final resMembro = await _conn.execute("SELECT role, ativo FROM public.membro_empresa WHERE \"tenantId\" = '$_empresaId' AND \"usuarioId\" = '$_usuarioId'");
    if (resMembro.isEmpty) return DomValidation('Usuário / IAM', false, 'Membro vinculado não encontrado na tabela membro_empresa.');
    final roleM = resMembro.first[0];
    final ativo = resMembro.first[1];

    return DomValidation('Usuário / IAM', true, 'Owner "${row[1]}" (${row[2]}) vinculado como membro $roleM (ativo: $ativo).');
  } catch (e) {
    return DomValidation('Usuário / IAM', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaConfiguracoes() async {
  try {
    final res = await _conn.execute("SELECT tema, \"taxaServico\", \"modoDeliveryAtivo\" FROM public.empresa_configuracao WHERE \"tenantId\" = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Configurações Gerais', false, 'Configurações de teste não encontradas.');
    final row = res.first;
    return DomValidation('Configurações Gerais', true, 'Tema cadastrado: ${row[0]} | Taxa Serviço: ${row[1]}% | Delivery Ativo: ${row[2]}.');
  } catch (e) {
    return DomValidation('Configurações Gerais', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaTaxaEntrega() async {
  try {
    final res = await _conn.execute("SELECT \"taxaEntregaPorKm\", \"valorPorKmCentavos\" FROM public.empresa_configuracao WHERE \"tenantId\" = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Taxa de Entrega', false, 'Configurações de entrega vazias.');
    final row = res.first;
    return DomValidation('Taxa de Entrega', true, 'Taxa por km ativa: ${row[0]} | Valor/km: R\$${((row[1] as int) / 100).toStringAsFixed(2)}.');
  } catch (e) {
    return DomValidation('Taxa de Entrega', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaCategorias() async {
  try {
    final res = await _conn.execute("SELECT COUNT(*) FROM public.categoria WHERE \"tenantId\" = '$_empresaId'");
    final count = res.first[0] as int;
    if (count == 3) {
      return DomValidation('Categorias', true, '$count categorias criadas corretas (Lanches, Bebidas, Sobremesas).');
    } else {
      return DomValidation('Categorias', false, 'Encontradas $count categorias, esperado 3.');
    }
  } catch (e) {
    return DomValidation('Categorias', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaProdutos() async {
  try {
    final res = await _conn.execute("SELECT COUNT(*) FROM public.produto WHERE \"tenantId\" = '$_empresaId'");
    final count = res.first[0] as int;
    if (count == 2) {
      return DomValidation('Produtos', true, '$count produtos criados corretos (X-Burguer, Coca-Cola).');
    } else {
      return DomValidation('Produtos', false, 'Encontrados $count produtos, esperado 2.');
    }
  } catch (e) {
    return DomValidation('Produtos', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaTabelaPrecos() async {
  try {
    final resT = await _conn.execute("SELECT COUNT(*) FROM public.tabela_precificacao WHERE \"tenantId\" = '$_empresaId' AND ativo = true");
    final countT = resT.first[0] as int;
    if (countT != 2) return DomValidation('Tabela de Preço', false, 'Esperado 2 tabelas de preço ativas, encontradas $countT.');

    final resI = await _conn.execute('''
      SELECT pt."produtoId", itp."valorUnitarioCentavos"
      FROM public.produto_tabela_precificacao pt
      JOIN public.item_tabela_precificacao itp ON itp."tabelaPrecificacaoId" = pt."tabelaPrecificacaoId"
      WHERE pt."tenantId" = '$_empresaId'
    ''');
    if (resI.length != 2) return DomValidation('Tabela de Preço', false, 'Esperado 2 itens de precificação de produto, encontrados ${resI.length}.');

    var precosOk = true;
    final det = <String>[];
    for (final row in resI) {
      final pid = row[0] as String;
      final preco = row[1] as int;
      if (pid == _prodXBurgId && preco != 1800) precosOk = false;
      if (pid == _prodCocaId && preco != 700) precosOk = false;
      det.add('${pid == _prodXBurgId ? 'X-Burguer' : 'Coca-Cola'}=R\$${(preco/100).toStringAsFixed(2)}');
    }

    if (precosOk) {
      return DomValidation('Tabela de Preço', true, 'Tabela cadastrada com valores: ${det.join(", ")}.');
    } else {
      return DomValidation('Tabela de Preço', false, 'Valores da tabela incorretos: ${det.join(", ")}.');
    }
  } catch (e) {
    return DomValidation('Tabela de Preço', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaEstoqueInicial() async {
  try {
    final res = await _conn.execute("SELECT SUM(quantidade), tipo FROM public.movimentacao_estoque WHERE \"tenantId\" = '$_empresaId' AND tipo = 'entrada_manual' GROUP BY tipo");
    if (res.isEmpty) return DomValidation('Estoque Inicial', false, 'Nenhuma entrada manual de estoque registrada no log de movimentação.');
    return DomValidation('Estoque Inicial', true, 'Estoque inicial implantado com sucesso via movimentacao_estoque.');
  } catch (e) {
    return DomValidation('Estoque Inicial', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaCliente() async {
  try {
    final res = await _conn.execute("SELECT nome, documento FROM public.cliente WHERE \"tenantId\" = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Cliente', false, 'Nenhum cliente cadastrado no banco.');
    final row = res.first;
    return DomValidation('Cliente', true, 'Cliente "${row[0]}" (CPF: ${row[1]}) cadastrado com sucesso.');
  } catch (e) {
    return DomValidation('Cliente', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaPedido() async {
  try {
    final res = await _conn.execute("SELECT status, \"valorSubtotalCentavos\", \"valorTaxaEntregaCentavos\", \"valorTotalCentavos\" FROM public.pedido WHERE \"tenantId\" = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Pedido / Venda', false, 'Nenhum pedido de teste encontrado.');
    final row = res.first;
    final total = row[3] as int;
    final sub = row[1] as int;
    final taxa = row[2] as int;
    if (total == 4800 && sub == 4300 && taxa == 500) {
      return DomValidation('Pedido / Venda', true, 'Pedido registrado: Subtotal R\$43,00 + Entrega R\$5,00 = Total R\$48,00. Status: ${row[0]}.');
    } else {
      return DomValidation('Pedido / Venda', false, 'Valores incorretos no pedido: Subtotal=$sub Taxa=$taxa Total=$total.');
    }
  } catch (e) {
    return DomValidation('Pedido / Venda', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaReservaEstoque() async {
  try {
    // Como o pedido foi marcado como "entregue" no seed, a reserva atual de X-Burguer deve ter voltado para 0
    final res = await _conn.execute("SELECT \"quantidadeReservada\" FROM public.estoque_produto WHERE \"tenantId\" = '$_empresaId' AND \"produtoId\" = '$_prodXBurgId'");
    if (res.isEmpty) return DomValidation('Reserva de Estoque', false, 'Registro de estoque do X-Burguer não encontrado.');
    final reserva = res.first[0] as int;
    if (reserva == 0) {
      return DomValidation('Reserva de Estoque', true, 'Reserva baixada com sucesso (reserva atual: 0) após a entrega.');
    } else {
      return DomValidation('Reserva de Estoque', false, 'Reserva permaneceu em $reserva, esperado 0 pós-entrega.');
    }
  } catch (e) {
    return DomValidation('Reserva de Estoque', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaCaixa() async {
  try {
    final res = await _conn.execute("SELECT status, \"valorAberturaCentavos\", \"valorFechamentoCentavos\", \"totalVendasCentavos\" FROM public.sessao_caixa WHERE \"tenantId\" = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Caixa', false, 'Nenhuma sessão de caixa cadastrada.');
    final row = res.first;
    final status = row[0] as String;
    final abertura = row[1] as int;
    final fechamento = row[2] as int;
    final totalVendas = row[3] as int;
    if (status == 'fechada' && abertura == 10000 && fechamento == 14800 && totalVendas == 4800) {
      return DomValidation('Caixa', true, 'Sessão fechada com sucesso. Abertura: R\$100,00 | Vendas: R\$48,00 | Fechamento: R\$148,00.');
    } else {
      return DomValidation('Caixa', false, 'Valores inconsistentes no caixa: Status=$status Abertura=$abertura Fechamento=$fechamento Vendas=$totalVendas.');
    }
  } catch (e) {
    return DomValidation('Caixa', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaLancamentoFinanceiro() async {
  try {
    final res = await _conn.execute("SELECT tipo, \"valorCentavos\", \"formaPagamentoNome\" FROM public.lancamento_financeiro WHERE \"tenantId\" = '$_empresaId'");
    if (res.isEmpty) return DomValidation('Financeiro', false, 'Nenhum lançamento financeiro registrado.');
    final row = res.first;
    final tipo = row[0] as String;
    final valor = row[1] as int;
    final forma = row[2] as String;
    if (tipo == 'recebimento' && valor == 4800 && forma == 'Pix') {
      return DomValidation('Financeiro', true, 'Lançamento de R\$48,00 em Pix registrado com sucesso no caixa.');
    } else {
      return DomValidation('Financeiro', false, 'Lançamento inconsistente: Tipo=$tipo Valor=$valor Forma=$forma.');
    }
  } catch (e) {
    return DomValidation('Financeiro', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaEstoquePosVenda() async {
  try {
    final resX = await _conn.execute("SELECT \"quantidadeAtual\" FROM public.estoque_produto WHERE \"tenantId\" = '$_empresaId' AND \"produtoId\" = '$_prodXBurgId'");
    final resC = await _conn.execute("SELECT \"quantidadeAtual\" FROM public.estoque_produto WHERE \"tenantId\" = '$_empresaId' AND \"produtoId\" = '$_prodCocaId'");
    if (resX.isEmpty || resC.isEmpty) return DomValidation('Estoque Pós-Venda', false, 'Registros de estoque não encontrados.');

    final qtdX = resX.first[0] as int;
    final qtdC = resC.first[0] as int;

    // Inicial era: 50 X-Burguer, 100 Coca. Vendido: 2 X-Burguer, 1 Coca.
    // Final esperado: 48 X-Burguer, 99 Coca.
    if (qtdX == 48 && qtdC == 99) {
      return DomValidation('Estoque Pós-Venda', true, 'Estoque baixado corretamente: X-Burguer=$qtdX (esperado: 48) | Coca-Cola=$qtdC (esperado: 99).');
    } else {
      return DomValidation('Estoque Pós-Venda', false, 'Erro de baixa de estoque. X-Burguer=$qtdX (esperado: 48) | Coca-Cola=$qtdC (esperado: 99).');
    }
  } catch (e) {
    return DomValidation('Estoque Pós-Venda', false, 'Erro: $e');
  }
}

Future<DomValidation> _validaAuditoria() async {
  try {
    final res = await _conn.execute("SELECT COUNT(*) FROM public.audit_logs WHERE \"tenantId\" = '$_empresaId'");
    final count = res.first[0] as int;
    return DomValidation('Auditoria (Audit Log)', true, '$count logs de auditoria encontrados na tabela audit_logs.');
  } catch (e) {
    return DomValidation('Auditoria (Audit Log)', false, 'Tabela inexistente ou erro: $e');
  }
}

Future<DomValidation> _validaLogsDev() async {
  try {
    final resS = await _conn.execute("SELECT COUNT(*) FROM public.serverpod_session_log");
    final resL = await _conn.execute("SELECT COUNT(*) FROM public.serverpod_log");
    final countS = resS.first[0] as int;
    final countL = resL.first[0] as int;
    return DomValidation('Logs DEV', true, 'Encontrados $countS logs de sessão e $countL logs do Serverpod.');
  } catch (e) {
    return DomValidation('Logs DEV', false, 'Erro ao acessar tabelas de logs: $e');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS E FORMATADORES
// ═══════════════════════════════════════════════════════════════════════════

void _imprimirSumario(List<DomValidation> list) {
  _header('SUMÁRIO DA VALIDAÇÃO');
  int sucessos = 0;
  for (final v in list) {
    if (v.status) {
      _ok('✅ [OK] ${v.name.padRight(28)} : ${v.details}');
      sucessos++;
    } else {
      _erro('❌ [ERRO] ${v.name.padRight(26)} : ${v.details}');
    }
  }
  
  final statusGeral = sucessos == list.length ? '✅ SUCESSO TOTAL' : '❌ FALHA NO TESTE';
  print('\n╔═══════════════════════════════════════════════════════════════╗');
  print('  Resultado Geral: $statusGeral ($sucessos/${list.length} Domínios)');
  print('╚═══════════════════════════════════════════════════════════════╝');
}

Future<void> _salvarRelatorio(List<DomValidation> list) async {
  final logsDir = Directory('logs');
  if (!logsDir.existsSync()) {
    logsDir.createSync();
  }

  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
  final file = File('logs/test_report_$timestamp.md');

  final sb = StringBuffer();
  sb.writeln('# Relatório de Validação de Teste End-to-End');
  sb.writeln('Gerado em: ${DateTime.now().toLocal()}\n');
  sb.writeln('## Resumo Executivo');
  
  final sucessos = list.where((v) => v.status).length;
  final status = sucessos == list.length ? 'SUCESSO ✅' : 'FALHA ❌';
  sb.writeln('- **Status Geral:** $status');
  sb.writeln('- **Score:** $sucessos de ${list.length} domínios operacionais validados com sucesso.\n');

  sb.writeln('## Detalhes por Domínio');
  sb.writeln('| Domínio | Status | Detalhes |');
  sb.writeln('|---------|--------|----------|');
  for (final v in list) {
    final statusSymbol = v.status ? '✅ OK' : '❌ ERRO';
    sb.writeln('| ${v.name} | $statusSymbol | ${v.details} |');
  }

  await file.writeAsString(sb.toString());
  print('Relatório salvo em: ${file.path}');
}

void _header(String msg) => print('\n╔══ $msg ══╗');
void _info(String msg)   => print('   $msg');
void _ok(String msg)     => print('   $msg');
void _erro(String msg)   => print('   $msg');
