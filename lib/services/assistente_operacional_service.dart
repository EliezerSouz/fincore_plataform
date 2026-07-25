import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class InsightOperacional {
  final String id;
  final String titulo;
  final String mensagem;
  final String categoria; // 'Producao', 'Estoque', 'Logistica', 'Cliente'
  final String nivel; // 'Sucesso', 'Alerta', 'Info', 'Urgente'
  final IconData icon;
  final Map<String, dynamic>? metadata;

  InsightOperacional({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.categoria,
    required this.nivel,
    required this.icon,
    this.metadata,
  });
}


class BriefingOperacionalDiario {
  final String textoConversacional;
  final int totalPedidosHoje;
  final int totalSalgadosHoje;
  final List<Map<String, dynamic>> producaoSugerida; // [{'produto': Produto, 'quantidade': 175}, ...]
  final List<String> bairrosAgrupados;
  final List<String> rupturasPrevistas;
  final String tempoEstimadoOperacao;
  final int clientesVipAguardando;

  BriefingOperacionalDiario({
    required this.textoConversacional,
    required this.totalPedidosHoje,
    required this.totalSalgadosHoje,
    required this.producaoSugerida,
    required this.bairrosAgrupados,
    required this.rupturasPrevistas,
    required this.tempoEstimadoOperacao,
    required this.clientesVipAguardando,
  });
}

class AssistenteOperacionalService {
  final AppDatabase db;

  AssistenteOperacionalService(this.db);

  Future<BriefingOperacionalDiario> gerarBriefingDiario() async {
    final now = DateTime.now();
    final inicioHoje = DateTime(now.year, now.month, now.day);
    final fimHoje = inicioHoje.add(const Duration(days: 1));
    final fimAmanha = fimHoje.add(const Duration(days: 1));

    final todosPedidos = await (db.select(db.pedidos)
          ..where((p) => p.status.equals('Cancelado').not()))
        .get();

    final todosItens = await db.select(db.itensPedido).get();
    final todosProdutos = await db.select(db.produtos).get();
    final todosClientes = await db.select(db.clientes).get();
    final todosEstoques = await db.select(db.estoqueAtual).get();

    // Pedidos de hoje
    final pedidosHoje = todosPedidos.where((p) {
      return (p.dataEntrega.isAfter(inicioHoje) || p.dataEntrega.isAtSameMomentAs(inicioHoje)) &&
          p.dataEntrega.isBefore(fimHoje);
    }).toList();

    int totalSalgadosHoje = 0;
    for (final p in pedidosHoje) {
      final items = todosItens.where((i) => i.pedidoId == p.id);
      for (final item in items) {
        totalSalgadosHoje += item.quantidade;
      }
    }

    // Calcular produção necessária imediata
    final necessidadeProducao = <int, int>{}; // produtoId -> quantidade
    final pedidosParaProducao = todosPedidos.where((p) {
      return p.status == 'Pendente' || p.status == 'Em Preparo';
    }).toList();

    for (final p in pedidosParaProducao) {
      final items = todosItens.where((i) => i.pedidoId == p.id);
      for (final item in items) {
        necessidadeProducao[item.produtoId] = (necessidadeProducao[item.produtoId] ?? 0) + item.quantidade;
      }
    }

    final producaoSugerida = <Map<String, dynamic>>[];
    for (final entry in necessidadeProducao.entries) {
      final prod = todosProdutos.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => const Produto(
          id: 0,
          nome: 'Desconhecido',
          categoria: '',
          ativo: false,
          tempoMedioMinutos: 0,
          controlaEstoque: false,
          ordemProducao: 0,
        ),
      );
      if (prod.id != 0) {
        final est = todosEstoques.firstWhere(
          (e) => e.produtoId == prod.id,
          orElse: () => EstoqueAtualData(
            produtoId: 0,
            saldoAtual: 0,
            reservado: 0,
            reservadoComercial: 0,
            reservadoOperacional: 0,
            estoqueMinimo: 0,
            estoqueIdeal: 0,
            loteMinimo: 0,
            atualizadoEm: DateTime.now(),
          ),
        );
        int saldoDisponivel = est.saldoAtual;
        int precisoProduzir = entry.value - saldoDisponivel;
        if (precisoProduzir > 0) {
          producaoSugerida.add({
            'produto': prod,
            'quantidade': precisoProduzir,
            'disp': saldoDisponivel,
          });
        }
      }
    }

    // Bairros agrupados
    final bairrosMap = <String, int>{};
    for (final p in pedidosHoje) {
      final c = todosClientes.firstWhere(
        (cl) => cl.id == p.clienteId,
        orElse: () => const Cliente(
          id: 0,
          nome: '',
          telefone: '',
          logradouro: '',
          numero: '',
          bairro: '',
          cidade: '',
          cep: '',
          referencia: '',
          observacoes: '',
          ativo: false,
        ),
      );
      if (c.bairro.isNotEmpty) {
        bairrosMap[c.bairro] = (bairrosMap[c.bairro] ?? 0) + 1;
      }
    }
    final bairrosAgrupados = bairrosMap.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();

    // Rupturas previstas
    final rupturasPrevistas = <String>[];
    for (final est in todosEstoques) {
      final prod = todosProdutos.firstWhere(
        (p) => p.id == est.produtoId,
        orElse: () => const Produto(
          id: 0,
          nome: '',
          categoria: '',
          ativo: false,
          tempoMedioMinutos: 0,
          controlaEstoque: false,
          ordemProducao: 0,
        ),
      );
      if (prod.id != 0 && prod.controlaEstoque) {
        if (est.saldoAtual < est.estoqueMinimo) {
          rupturasPrevistas.add('${prod.nome} (Estoque abaixo do mínimo)');
        }
      }
    }

    // Clientes VIP
    int vips = 0;
    for (final p in pedidosHoje) {
      final c = todosClientes.firstWhere(
        (cl) => cl.id == p.clienteId,
        orElse: () => const Cliente(
          id: 0,
          nome: '',
          telefone: '',
          logradouro: '',
          numero: '',
          bairro: '',
          cidade: '',
          cep: '',
          referencia: '',
          observacoes: '',
          ativo: false,
        ),
      );
      if (c.observacoes.toLowerCase().contains('vip')) {
        vips++;
      }
    }

    // Estimativa de tempo
    final totalMinutos = (pedidosHoje.length * 12) + (totalSalgadosHoje ~/ 10);
    final horas = totalMinutos ~/ 60;
    final mins = totalMinutos % 60;
    final tempoEstimadoStr = horas > 0 ? '${horas}h ${mins}min' : '${mins}min';

    // Montar texto conversacional estilo ChatGPT
    final buffer = StringBuffer();
    final saudacao = now.hour < 12 ? 'Bom dia!' : (now.hour < 18 ? 'Boa tarde!' : 'Boa noite!');
    buffer.writeln('$saudacao');
    buffer.writeln('Hoje existem ${pedidosHoje.length} pedidos agendados (${totalSalgadosHoje} salgados no total).\n');

    if (producaoSugerida.isNotEmpty) {
      buffer.writeln('Você precisa produzir:');
      for (final item in producaoSugerida) {
        final p = item['produto'] as Produto;
        buffer.writeln('• ${item['quantidade']} ${p.nome}');
      }
      buffer.writeln('\nSe produzir agora, você atenderá todos os pedidos até amanhã.');
    } else {
      buffer.writeln('✔ Seu estoque atual cobre toda a demanda do dia sem necessidade imediata de produção!');
    }

    if (vips > 0) {
      buffer.writeln('⭐ Há $vips cliente(s) VIP com pedidos agendados hoje.');
    }

    if (bairrosAgrupados.isNotEmpty) {
      buffer.writeln('📍 Existem entregas para os bairros: ${bairrosAgrupados.join(", ")} que podem ser agrupadas em rota.');
    }

    if (rupturasPrevistas.isNotEmpty) {
      buffer.writeln('⚠️ Ruptura prevista: ${rupturasPrevistas.take(2).join(", ")}.');
    }

    buffer.writeln('\n⏱ Tempo estimado da operação hoje: $tempoEstimadoStr.');

    return BriefingOperacionalDiario(
      textoConversacional: buffer.toString(),
      totalPedidosHoje: pedidosHoje.length,
      totalSalgadosHoje: totalSalgadosHoje,
      producaoSugerida: producaoSugerida,
      bairrosAgrupados: bairrosAgrupados,
      rupturasPrevistas: rupturasPrevistas,
      tempoEstimadoOperacao: tempoEstimadoStr,
      clientesVipAguardando: vips,
    );
  }

  Future<List<InsightOperacional>> gerarInsights() async {
    final insights = <InsightOperacional>[];

    try {
      // 1. Analisar Produção Diária Necessária
      final queryItens = db.select(db.itensPedido).join([
        innerJoin(db.pedidos, db.pedidos.id.equalsExp(db.itensPedido.pedidoId)),
        innerJoin(db.produtos, db.produtos.id.equalsExp(db.itensPedido.produtoId)),
      ])..where(db.pedidos.status.isIn(const ['Pendente', 'Em Preparo']));

      final rows = await queryItens.get();
      final totaisPorProduto = <String, int>{};

      for (final r in rows) {
        final prod = r.readTable(db.produtos);
        final item = r.readTable(db.itensPedido);
        totaisPorProduto[prod.nome] = (totaisPorProduto[prod.nome] ?? 0) + item.quantidade;
      }

      if (totaisPorProduto.isNotEmpty) {
        final resumoProducao = totaisPorProduto.entries
            .map((e) => '• ${e.value}x ${e.key}')
            .take(3)
            .join('\n');

        insights.add(InsightOperacional(
          id: 'prod_hoje',
          titulo: 'Sugestão de Produção Imediata',
          mensagem: 'Para atender todos os pedidos em aberto hoje, sugerimos produzir:\n$resumoProducao',
          categoria: 'Producao',
          nivel: 'Urgente',
          icon: Icons.restaurant_menu,
        ));
      }

      // 2. Analisar Cobertura e Projeção de Estoque
      final estoques = await db.select(db.estoqueAtual).get();
      for (final est in estoques) {
        final p = await (db.select(db.produtos)..where((pr) => pr.id.equals(est.produtoId))).getSingleOrNull();
        if (p != null) {
          if (est.saldoAtual < est.estoqueMinimo) {
            insights.add(InsightOperacional(
              id: 'est_baixo_${p.id}',
              titulo: 'Estoque Crítico: ${p.nome}',
              mensagem: 'Saldo atual (${est.saldoAtual} un) abaixo do mínimo (${est.estoqueMinimo} un). Cobertura estimada inferior a 1 dia.',
              categoria: 'Estoque',
              nivel: 'Alerta',
              icon: Icons.warning_amber_rounded,
            ));
          }
        }
      }

      // 3. Otimização de Entregas por Região / Bairro
      final pedidosPendentes = await (db.select(db.pedidos)..where((p) => p.status.isIn(const ['Pendente', 'Em Preparo', 'Pronto']))).get();

      final regioesMap = <String, int>{};
      for (final ped in pedidosPendentes) {
        final cliente = await (db.select(db.clientes)..where((c) => c.id.equals(ped.clienteId))).getSingleOrNull();
        if (cliente != null && cliente.bairro.isNotEmpty) {
          final bairroNorm = cliente.bairro.trim();
          regioesMap[bairroNorm] = (regioesMap[bairroNorm] ?? 0) + 1;
        }
      }

      for (final entry in regioesMap.entries) {
        if (entry.value >= 2) {
          insights.add(InsightOperacional(
            id: 'regiao_${entry.key}',
            titulo: 'Oportunidade de Agrupamento de Entregas',
            mensagem: 'Existem ${entry.value} pedidos aguardando entrega no bairro "${entry.key}". É possível agrupar em uma mesma rota de saída.',
            categoria: 'Logistica',
            nivel: 'Sucesso',
            icon: Icons.route,
          ));
          break;
        }
      }
    } catch (e) {
      debugPrint('Erro ao gerar insights do Assistente Operacional: $e');
    }

    return insights;
  }
}

