import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../database/app_database.dart';
import '../../models/domain_models.dart';
import '../../providers/app_view_model.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  final _buscaController = TextEditingController();
  String _busca = '';
  String _filtroStatus = 'Todos'; // Todos, Críticos, Atenção/Produzir, Sem Movimentação, Maior Giro, Menor Giro
  
  // Mapa de simulação temporária por ID do produto
  final Map<int, int> _simulacoes = {};

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _obterBarraCobertura(double dias) {
    const totalBlocos = 10;
    final blocosPreenchidos = (dias).clamp(0.0, 10.0).round();
    final preenchido = '█' * blocosPreenchidos;
    final vazio = '░' * (totalBlocos - blocosPreenchidos);
    return '$preenchido$vazio';
  }

  String dinheiro(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  void _exibirDialogoProduzir(BuildContext context, AppViewModel vm, ProdutoComEstoque item) {
    final formKey = GlobalKey<FormState>();
    final qtdController = TextEditingController(text: '${item.loteMinimo}');
    final respController = TextEditingController();
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registrar Produção: ${item.produto.nome}'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantidade Produzida *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: qtdController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.production_quantity_limits_outlined, size: 20),
                        hintText: 'Ex: 100',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Campo obrigatório';
                        final num = int.tryParse(val) ?? 0;
                        if (num <= 0) return 'A quantidade deve ser maior que zero';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Responsável', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: respController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        hintText: 'Nome do operador / cozinheiro',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Observações', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: obsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.notes_outlined, size: 20),
                        hintText: 'Notas adicionais (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final qtd = int.parse(qtdController.text);
                try {
                  await vm.registrarProducaoDiaria(
                    produtoId: item.produto.id,
                    quantidade: qtd,
                    responsavel: respController.text.trim(),
                    observacao: obsController.text.trim(),
                    data: DateTime.now(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppSnackbar.sucesso(context, 'Produção de $qtd un. de ${item.produto.nome} registrada com sucesso!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackbar.erro(context, 'Erro ao registrar produção: $e');
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
        child: StreamBuilder<List<ProdutoComEstoque>>(
          stream: vm.observarEstoque(),
          builder: (context, estSnapshot) {
            if (!estSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final estoque = estSnapshot.data!;

            return StreamBuilder<List<Pedido>>(
              stream: db.select(db.pedidos).watch(),
              builder: (context, pedSnapshot) {
                if (!pedSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final pedidos = pedSnapshot.data!;

                return StreamBuilder<List<ItensPedidoData>>(
                  stream: db.select(db.itensPedido).watch(),
                  builder: (context, itensSnapshot) {
                    if (!itensSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final itens = itensSnapshot.data!;

                    // 1. CALCULAR DEMANDAS DE CADA DIA DA SEMANA (0 a 7 dias)
                    final Map<int, Map<int, int>> mapDemandByDay = {};
                    final Map<int, int> mapTotalActiveDemand = {};

                    for (final p in pedidos) {
                      if (p.status == 'Cancelado' || p.status == 'Finalizado') continue;
                      final diff = p.dataEntrega.difference(today).inDays;
                      final offset = diff.clamp(0, 15);
                      final pedidoItens = itens.where((i) => i.pedidoId == p.id);
                      for (final item in pedidoItens) {
                        if (!mapDemandByDay.containsKey(item.produtoId)) {
                          mapDemandByDay[item.produtoId] = {};
                        }
                        mapDemandByDay[item.produtoId]![offset] =
                            (mapDemandByDay[item.produtoId]![offset] ?? 0) + item.quantidade;
                        mapTotalActiveDemand[item.produtoId] =
                            (mapTotalActiveDemand[item.produtoId] ?? 0) + item.quantidade;
                      }
                    }

                    // 2. CONSTRUIR E CALCULAR OS ITENS DO MRP
                    final mrpItens = estoque.where((item) => item.produto.controlaEstoque).map((item) {
                      final p = item.produto;
                      
                      // Obter simulação
                      final qtdSimulada = _simulacoes[p.id] ?? 0;
                      final fisico = item.saldoAtual + qtdSimulada;

                      // Giro e Consumo Médio
                      double consumoMedio = 15.0;
                      if (mapTotalActiveDemand[p.id] != null) {
                        consumoMedio = (mapTotalActiveDemand[p.id]! / 7.0).clamp(1.0, 99999.0);
                      }
                      final coberturaDias = (fisico - item.reservado) / consumoMedio;

                      // Timeline de projeções para os próximos 6 dias (Hoje + 5 dias)
                      int stockProjetado = fisico;
                      final timeline = <Map<String, dynamic>>[];
                      DateTime? dataRuptura;

                      for (int dOffset = 0; dOffset <= 6; dOffset++) {
                        final dailyDemand = mapDemandByDay[p.id]?[dOffset] ?? 0;
                        stockProjetado -= dailyDemand;
                        final date = today.add(Duration(days: dOffset));
                        final dayStr = DateFormat('E', 'pt_BR').format(date).toUpperCase().replaceAll('.', '');

                        timeline.add({
                          'day': dayStr,
                          'stock': stockProjetado,
                          'demand': dailyDemand,
                          'isRupture': stockProjetado < 0,
                        });
                        if (stockProjetado < 0 && dataRuptura == null) {
                          dataRuptura = date;
                        }
                      }

                      // Status
                      final temRupturaIminente = dataRuptura != null && dataRuptura.difference(today).inDays <= 3;
                      final temRupturaFutura = dataRuptura != null && dataRuptura.difference(today).inDays > 3;

                      String status = 'OK';
                      String emoji = '🟢';
                      Color statusColor = Colors.green;

                      if (temRupturaIminente) {
                        status = 'Ruptura';
                        emoji = '🔴';
                        statusColor = Colors.red;
                      } else if (temRupturaFutura || (coberturaDias < 3.0) || (item.saldoAtual <= item.estoqueMinimo)) {
                        status = 'Atenção';
                        emoji = '🟡';
                        statusColor = Colors.amber;
                      }

                      // Necessidade de produção
                      int necessidade = 0;
                      final disponivel = fisico - item.reservado;
                      if (disponivel < item.estoqueMinimo) {
                        necessidade = item.estoqueIdeal - disponivel;
                        if (necessidade > 0 && status == 'OK') {
                          status = 'Produzir';
                          emoji = '🟠';
                          statusColor = Colors.orange;
                        }
                      }

                      // Obter última produção
                      // Usar movimentações para buscar a última produção registrada
                      return _MrpItem(
                        item: item,
                        fisico: fisico,
                        coberturaDias: coberturaDias.clamp(0.0, 999.0),
                        status: status,
                        emoji: emoji,
                        statusColor: statusColor,
                        necessidade: necessidade,
                        timeline: timeline,
                        dataRuptura: dataRuptura,
                        consumoMedio: consumoMedio,
                        demandaAtiva: mapTotalActiveDemand[p.id] ?? 0,
                      );
                    }).toList();

                    // 3. COMPUTAR KPIs DO TOPO
                    final produtosCriticos = mrpItens.where((m) => m.status == 'Ruptura').length;
                    final totalNecessidade = mrpItens.fold<int>(0, (sum, m) => sum + m.necessidade);
                    final mediaCobertura = mrpItens.isEmpty 
                        ? 0.0 
                        : mrpItens.fold<double>(0.0, (sum, m) => sum + m.coberturaDias) / mrpItens.length;
                    
                    DateTime? primeiraRuptura;
                    for (final m in mrpItens) {
                      if (m.dataRuptura != null) {
                        if (primeiraRuptura == null || m.dataRuptura!.isBefore(primeiraRuptura)) {
                          primeiraRuptura = m.dataRuptura;
                        }
                      }
                    }
                    final primeiraRupturaStr = primeiraRuptura != null 
                        ? DateFormat('E', 'pt_BR').format(primeiraRuptura).toUpperCase().replaceAll('.', '') 
                        : 'Sem Ruptura';

                    // 4. FILTRAR E ORDENAR A TABELA MRP
                    // Busca textual
                    var listaExibida = mrpItens;
                    if (_busca.isNotEmpty) {
                      final lower = _busca.toLowerCase();
                      listaExibida = listaExibida.where((m) => m.item.produto.nome.toLowerCase().contains(lower)).toList();
                    }

                    // Filtros rápidos
                    if (_filtroStatus == 'Críticos') {
                      listaExibida = listaExibida.where((m) => m.status == 'Ruptura').toList();
                    } else if (_filtroStatus == 'Atenção/Produzir') {
                      listaExibida = listaExibida.where((m) => m.status == 'Atenção' || m.necessidade > 0).toList();
                    } else if (_filtroStatus == 'Sem Movimentação') {
                      listaExibida = listaExibida.where((m) => m.demandaAtiva == 0 && m.item.saldoAtual == 0).toList();
                    } else if (_filtroStatus == 'Maior Giro') {
                      listaExibida.sort((a, b) => b.consumoMedio.compareTo(a.consumoMedio));
                    } else if (_filtroStatus == 'Menor Giro') {
                      listaExibida.sort((a, b) => a.consumoMedio.compareTo(b.consumoMedio));
                    }

                    // Se não for ordenado por giro, ordena por prioridade automática (Ruptura -> Atenção -> OK)
                    if (_filtroStatus != 'Maior Giro' && _filtroStatus != 'Menor Giro') {
                      listaExibida.sort((a, b) {
                        final prioridades = {'Ruptura': 0, 'Atenção': 1, 'Produzir': 2, 'OK': 3};
                        final valA = prioridades[a.status] ?? 4;
                        final valB = prioridades[b.status] ?? 4;
                        if (valA != valB) return valA.compareTo(valB);
                        return a.item.produto.nome.compareTo(b.item.produto.nome);
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho da página
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Central de Estoque (MRP)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Controle de rupturas, projeções de consumo e simulação de coberturas comerciais.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Painel de KPIs no topo
                        Row(
                          children: [
                            Expanded(child: _kpiCard('Produtos Críticos', '$produtosCriticos', Colors.red, Icons.warning_amber_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _kpiCard('Produção Necessária', '$totalNecessidade un.', Colors.orange, Icons.precision_manufacturing_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _kpiCard('Cobertura Média', '${mediaCobertura.toStringAsFixed(1)} dias', Colors.blue, Icons.hourglass_empty)),
                            const SizedBox(width: 16),
                            Expanded(child: _kpiCard('Primeira Ruptura', primeiraRupturaStr, Colors.purple, Icons.event_busy_outlined)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Barra de Pesquisa e Filtros
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _buscaController,
                                onChanged: (val) => setState(() => _busca = val.trim()),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: 'Pesquisar produto...',
                                  suffixIcon: _buscaController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _buscaController.clear();
                                            setState(() => _busca = '');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text('Filtro: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            ...['Todos', 'Críticos', 'Atenção/Produzir', 'Sem Movimentação', 'Maior Giro', 'Menor Giro'].map((f) {
                              final active = _filtroStatus == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: active,
                                  onSelected: (val) {
                                    if (val) setState(() => _filtroStatus = f);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tabela MRP Operacional
                        Expanded(
                          child: Card(
                            child: Column(
                              children: [
                                // Cabeçalho da Tabela
                                Container(
                                  color: Colors.grey.shade100,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  child: Row(
                                    children: const [
                                      Expanded(flex: 3, child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                      Expanded(flex: 1, child: Text('Hoje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                                      Expanded(flex: 1, child: Text('Amanhã', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                                      Expanded(flex: 2, child: Text('Cobertura', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                      Expanded(flex: 1, child: Text('Necessidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                                      Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Corpo da Tabela (Listview Expansível)
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: listaExibida.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final m = listaExibida[index];
                                      final p = m.item.produto;

                                      // Estoque de Hoje e Amanhã projetados
                                      final stockHoje = m.timeline.isNotEmpty ? m.timeline[0]['stock'] as int : m.fisico;
                                      final stockAmanha = m.timeline.length > 1 ? m.timeline[1]['stock'] as int : m.fisico;

                                      return ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                        leading: Text(m.emoji, style: const TextStyle(fontSize: 16)),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                p.nome,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                '${m.fisico}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: m.fisico < 0 ? Colors.red : Colors.black87,
                                                  fontSize: 13,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                '$stockAmanha',
                                                style: TextStyle(
                                                  color: stockAmanha < 0 ? Colors.red : Colors.grey.shade700,
                                                  fontSize: 13,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _obterBarraCobertura(m.coberturaDias),
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 10,
                                                      color: m.statusColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${m.coberturaDias.toStringAsFixed(1)} dias',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: m.statusColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                m.necessidade > 0 ? '${m.necessidade} un.' : '—',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: m.necessidade > 0 ? Colors.orange.shade800 : Colors.grey.shade500,
                                                  fontSize: 13,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: m.statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  m.status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: m.statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Container(
                                            color: Colors.grey.shade50,
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Grid de Detalhes de Estoque e Procura
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('Saldos e Reservas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                                          const SizedBox(height: 8),
                                                          _detailRow('Estoque Físico', '${m.item.saldoAtual} un.'),
                                                          _detailRow('Reserva Comercial', '${m.item.reservadoComercial} un.'),
                                                          _detailRow('Reserva Operacional', '${m.item.reservadoOperacional} un.'),
                                                          _detailRow('Estoque Mínimo (Crítico)', '${m.item.estoqueMinimo} un.'),
                                                          _detailRow('Estoque Ideal', '${m.item.estoqueIdeal} un.'),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 40),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('Consumo & Produção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                                          const SizedBox(height: 8),
                                                          _detailRow('Consumo Médio Diário', '${m.consumoMedio.toStringAsFixed(1)} un./dia'),
                                                          _detailRow('Total Pedido Ativo', '${m.demandaAtiva} un.'),
                                                          _detailRow('Lote Mínimo Fabricação', '${m.item.loteMinimo} un.'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 24),

                                                // Linha do tempo horizontal de consumo
                                                const Text('Consumo Previsto por Dia (Demanda de Pedidos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                                const SizedBox(height: 8),
                                                SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    children: m.timeline.map((tp) {
                                                      final isNeg = tp['stock'] < 0;
                                                      final demand = tp['demand'] as int;
                                                      return Container(
                                                        margin: const EdgeInsets.only(right: 8),
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        decoration: BoxDecoration(
                                                          color: isNeg ? Colors.red.shade50 : Colors.white,
                                                          border: Border.all(color: isNeg ? Colors.red.shade200 : Colors.grey.shade200),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Text(tp['day'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              demand > 0 ? '-$demand un.' : '0',
                                                              style: TextStyle(fontSize: 11, color: demand > 0 ? Colors.red : Colors.grey.shade600),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              'Saldo: ${tp['stock']}',
                                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isNeg ? Colors.red.shade700 : Colors.grey.shade800),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                const Divider(height: 24),

                                                // Simulador e Ações Rápidas
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Simulador inline
                                                    Row(
                                                      children: [
                                                        const Text('Simular Produção: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                        const SizedBox(width: 8),
                                                        ...[50, 100, 200].map((v) {
                                                          final active = (_simulacoes[p.id] ?? 0) == v;
                                                          return Padding(
                                                            padding: const EdgeInsets.only(right: 6),
                                                            child: OutlinedButton(
                                                              style: OutlinedButton.styleFrom(
                                                                backgroundColor: active ? AppColors.primary.withOpacity(0.1) : null,
                                                                side: BorderSide(color: active ? AppColors.primary : Colors.grey.shade300),
                                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  if (active) {
                                                                    _simulacoes.remove(p.id);
                                                                  } else {
                                                                    _simulacoes[p.id] = v;
                                                                  }
                                                                });
                                                              },
                                                              child: Text('+$v', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? AppColors.primary : Colors.grey.shade700)),
                                                            ),
                                                          );
                                                        }),
                                                        if (_simulacoes.containsKey(p.id))
                                                          TextButton(
                                                            onPressed: () => setState(() => _simulacoes.remove(p.id)),
                                                            child: const Text('Limpar', style: TextStyle(color: Colors.red, fontSize: 11)),
                                                          ),
                                                      ],
                                                    ),
                                                    // Ação de Produção Direta
                                                    FilledButton.icon(
                                                      style: FilledButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                      ),
                                                      onPressed: () => _exibirDialogoProduzir(context, vm, m.item),
                                                      icon: const Icon(Icons.precision_manufacturing_outlined, size: 16),
                                                      label: const Text('Produzir Agora', style: TextStyle(fontSize: 12)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String val, Color cor, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MrpItem {
  final ProdutoComEstoque item;
  final int fisico;
  final double coberturaDias;
  final String status;
  final String emoji;
  final Color statusColor;
  final int necessidade;
  final List<Map<String, dynamic>> timeline;
  final DateTime? dataRuptura;
  final double consumoMedio;
  final int demandaAtiva;

  const _MrpItem({
    required this.item,
    required this.fisico,
    required this.coberturaDias,
    required this.status,
    required this.emoji,
    required this.statusColor,
    required this.necessidade,
    required this.timeline,
    this.dataRuptura,
    required this.consumoMedio,
    required this.demandaAtiva,
  });
}
