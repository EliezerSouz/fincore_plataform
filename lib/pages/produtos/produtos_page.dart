import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../database/app_database.dart';
import '../../models/domain_models.dart';
import '../../providers/app_view_model.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../design_system/colors.dart';
import '../../design_system/icons.dart';
import '../../design_system/typography.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_empty_state.dart';
import '../../modules/produtos/widgets/grupo_preco_dialog.dart';
import '../../design_system/components/operational_fields.dart';
import '../../design_system/components/app_drawer.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produtos e Preços',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerencie o catálogo de salgados e faixas de preços por volume.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.fastfood_outlined), text: 'Produtos'),
                  Tab(icon: Icon(Icons.sell_outlined), text: 'Grupos de Preço'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ProdutosTab(vm: vm),
                _GruposTab(vm: vm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProdutosTab extends StatefulWidget {
  final AppViewModel vm;

  const _ProdutosTab({required this.vm});

  @override
  State<_ProdutosTab> createState() => _ProdutosTabState();
}

class _ProdutosTabState extends State<_ProdutosTab> {
  String _filtroCategoria = 'Todos';
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProdutoComEstoque>>(
      stream: widget.vm.observarEstoque(),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? [];

        // Filtros
        var itensFiltrados = itens;
        if (_filtroCategoria != 'Todos') {
          itensFiltrados = itensFiltrados
              .where((i) => i.produto.categoria.toLowerCase() ==
                  _filtroCategoria.toLowerCase())
              .toList();
        }
        if (_busca.isNotEmpty) {
          itensFiltrados = itensFiltrados
              .where((i) => i.produto.nome
                  .toLowerCase()
                  .contains(_busca.toLowerCase()))
              .toList();
        }

        // Métricas
        final totalProdutos = itens.length;
        final categorias = itens.map((i) => i.produto.categoria).toSet().length;
        final semEstoque =
            itens.where((i) => i.disponivel <= i.estoqueMinimo).length;

        final listCategorias = ['Todos'] +
            itens.map((i) => i.produto.categoria).toSet().toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Metrics
            Row(
              children: [
                _metricCard('Total de Produtos', '$totalProdutos', Colors.blue),
                const SizedBox(width: 16),
                _metricCard('Categorias', '$categorias', Colors.purple),
                const SizedBox(width: 16),
                _metricCard('Estoque Baixo', '$semEstoque',
                    semEstoque > 0 ? Colors.red : Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // Filtro e Busca
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar produto...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _busca = v),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _produtoDialog(context, widget.vm),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo produto'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chips de Categoria
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: listCategorias.map((cat) {
                  final isSelected = _filtroCategoria == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _filtroCategoria = cat);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Grid de Produtos
            Expanded(
              child: itensFiltrados.isEmpty
                  ? const Card(
                      child: AppEmptyState(
                        icon: AppIcons.category,
                        title: 'Nenhum produto encontrado',
                        message: 'Cadastre os produtos ou mude o filtro para visualizar.',
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisExtent: 290,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: itensFiltrados.length,
                      itemBuilder: (context, index) {
                        return _productCard(context, itensFiltrados[index], widget.vm);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color.withAlpha(220),
                fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withAlpha(220),
                fontSize: 14),
          ),
        ],
      ),
    );
  }
  Widget _productCard(BuildContext context, ProdutoComEstoque item, AppViewModel vm) {
    final p = item.produto;
    final ehCritico = item.saldoAtual == 0 || item.disponivel <= 0;
    final ehBaixo = item.disponivel <= item.estoqueMinimo;

    Color badgeColor = Colors.green;
    String badgeText = 'ESTOQUE OK';
    if (ehCritico) {
      badgeColor = Colors.red;
      badgeText = 'CRÍTICO';
    } else if (ehBaixo) {
      badgeColor = Colors.amber;
      badgeText = 'ESTOQUE BAIXO';
    }

    final produzirNecessario = (item.reservado - item.saldoAtual) > 0 ? (item.reservado - item.saldoAtual) : 0;
    final estimativaConsumoDiario = item.estoqueMinimo > 0 ? item.estoqueMinimo : 30;
    final coberturaDias = (item.disponivel / (estimativaConsumoDiario / 3)).clamp(0, 99).toStringAsFixed(1);

    return StreamBuilder<GruposPrecoData?>(
      stream: (vm.db.select(vm.db.gruposPreco)..where((g) => g.id.equals(p.grupoPrecoId ?? 0))).watchSingleOrNull(),
      builder: (context, sGrupo) {
        final gpName = sGrupo.data?.nome ?? 'Sem grupo';

        return StreamBuilder<List<MovimentacoesEstoqueData>>(
          stream: (vm.db.select(vm.db.movimentacoesEstoque)
                ..where((m) => m.produtoId.equals(p.id))
                ..orderBy([(m) => OrderingTerm.desc(m.criadoEm)])
                ..limit(5))
              .watch(),
          builder: (context, sMovs) {
            final movs = sMovs.data ?? [];
            final ultimaMov = movs.isEmpty ? 'Nenhuma' : DateFormat('dd/MM HH:mm').format(movs.first.criadoEm);
            
            final entradas = movs.where((m) => m.tipoMovimentacao.contains('ENTRADA') || m.tipoMovimentacao == 'PRODUCAO' || m.tipoMovimentacao == 'ENTRADA_PRODUCAO');
            final ultimaEntrada = entradas.isEmpty ? 'Nenhuma' : DateFormat('dd/MM HH:mm').format(entradas.first.criadoEm);

            return Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _abrirDrawerProduto(context, vm, item, gpName, produzirNecessario, coberturaDias),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.categoria.toUpperCase(),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ),
                              AppBadge(label: badgeText, color: badgeColor),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grupo: $gpName',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _statCol('Físico', '${item.saldoAtual}')),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => vm.navegarPedidosDoProduto(p.id, p.nome),
                                    child: _statCol('Reservado', '${item.reservado}', highlight: item.reservado > 0),
                                  ),
                                ),
                                Expanded(child: _statCol('Produzir', '$produzirNecessario', highlight: produzirNecessario > 0)),
                                Expanded(child: _statCol('Cobertura', '$coberturaDias d')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Última entrada: $ultimaEntrada', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          Text('Última mov.: $ultimaMov', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _abrirDrawerProduto(context, vm, item, gpName, produzirNecessario, coberturaDias),
                            icon: const Icon(Icons.info_outline, size: 14),
                            label: const Text('Painel', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          ),
                          TextButton.icon(
                            onPressed: () => _produtoDialog(context, vm, item),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text('Editar', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          ),
                          TextButton.icon(
                            onPressed: () => vm.navegarProducao(
                              produto: p,
                              quantidade: produzirNecessario > 0 ? produzirNecessario : (item.loteMinimo > 0 ? item.loteMinimo : 50),
                            ),
                            icon: const Icon(Icons.restaurant_menu_outlined, size: 14),
                            label: const Text('Produzir', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _abrirDrawerProduto(
    BuildContext context,
    AppViewModel vm,
    ProdutoComEstoque item,
    String gpName,
    int produzirNecessario,
    String coberturaDias,
  ) {
    final p = item.produto;

    AppContextualDrawer.show(
      context: context,
      title: p.nome,
      subtitle: '${p.categoria} • Grupo $gpName',
      icon: Icons.fastfood_outlined,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: item.disponivel > 0 ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.disponivel > 0 ? Colors.green : Colors.red),
        ),
        child: Text(
          item.disponivel > 0 ? 'DISPONÍVEL' : 'SEM ESTOQUE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: item.disponivel > 0 ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
      ),
      actions: [
        if (item.reservado > 0)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              vm.navegarPedidosDoProduto(p.id, p.nome);
            },
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text('Ver Pedidos (${item.reservado} unid.)'),
          ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            vm.navegarProducao(
              produto: p,
              quantidade: produzirNecessario > 0 ? produzirNecessario : (item.loteMinimo > 0 ? item.loteMinimo : 50),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          icon: const Icon(Icons.restaurant_menu, size: 18),
          label: const Text('Enviar para Produção'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Cards de métricas do produto
          Row(
            children: [
              Expanded(child: _drawerMetric('Físico', '${item.saldoAtual}', Icons.inventory_2_outlined, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _drawerMetric('Reservado', '${item.reservado}', Icons.bookmark_border, Colors.amber)),
              const SizedBox(width: 8),
              Expanded(child: _drawerMetric('Produzir', '$produzirNecessario', Icons.build_circle_outlined, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _drawerMetric('Cobertura', '$coberturaDias dias', Icons.timelapse, Colors.purple)),
            ],
          ),
          const SizedBox(height: 20),

          // Informações de Estoque & Lote
          const Text('Parâmetros de Produção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _infoRow(Icons.inventory, 'Estoque Mínimo', '${item.estoqueMinimo} unidades'),
                  const Divider(height: 12),
                  _infoRow(Icons.flag_outlined, 'Estoque Ideal', '${item.estoqueIdeal} unidades'),
                  const Divider(height: 12),
                  _infoRow(Icons.widgets_outlined, 'Lote Padrão de Produção', '${item.loteMinimo} unidades'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pedidos que reservam este produto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pedidos Reservando Este Produto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (item.reservado > 0)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    vm.navegarPedidosDoProduto(p.id, p.nome);
                  },
                  child: const Text('Filtrar Pedidos'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TypedResult>>(
            stream: (vm.db.select(vm.db.itensPedido).join([
              innerJoin(vm.db.pedidos, vm.db.pedidos.id.equalsExp(vm.db.itensPedido.pedidoId)),
              innerJoin(vm.db.clientes, vm.db.clientes.id.equalsExp(vm.db.pedidos.clienteId)),
            ])
                  ..where(vm.db.itensPedido.produtoId.equals(p.id))
                  ..where(vm.db.pedidos.status.isIn(const ['Pendente', 'Em Preparo', 'Pronto', 'Em Rota'])))
                .watch(),
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Nenhum pedido ativo reservando este produto no momento.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Column(
                children: rows.map((row) {
                  final pedido = row.readTable(vm.db.pedidos);
                  final cliente = row.readTable(vm.db.clientes);
                  final itemPed = row.readTable(vm.db.itensPedido);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pedido #${pedido.id} • ${cliente.nome}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${itemPed.quantidade} unid.',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Status: ${pedido.status} • Entrega: ${DateFormat("dd/MM 'às' HH:mm").format(pedido.dataEntrega)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        vm.navegarKanbanComDestaque(pedidoId: pedido.id, status: pedido.status);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 10, color: color.withAlpha(200)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color.withAlpha(240)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCol(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.red : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _verHistoricoProdutoDialog(BuildContext context, AppViewModel vm, Produto p) {
    showDialog(
      context: context,
      builder: (d) {
        final query = vm.db.select(vm.db.movimentacoesEstoque)
          ..where((m) => m.produtoId.equals(p.id))
          ..orderBy([(m) => OrderingTerm.desc(m.criadoEm)]);
        return AlertDialog(
          title: Text('Histórico - ${p.nome}'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: StreamBuilder<List<MovimentacoesEstoqueData>>(
              stream: query.watch(),
              builder: (context, s) {
                final list = s.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('Nenhuma movimentação para este produto.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    final String signal = (m.tipoMovimentacao.contains('ENTRADA') || m.tipoMovimentacao.contains('CANCELAMENTO') || m.tipoMovimentacao == 'PRODUCAO') ? '+' : '-';
                    return ListTile(
                      title: Text('$signal${m.quantidade} un. (${m.tipoMovimentacao})'),
                      subtitle: Text('${m.motivo ?? ""}\n${DateFormat('dd/MM/yyyy HH:mm').format(m.criadoEm)}'),
                      trailing: Text('Saldo: ${m.saldoNovo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class _GruposTab extends StatelessWidget {
  final AppViewModel vm;

  const _GruposTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GruposPrecoData>>(
      stream: vm.gruposPreco.observar(),
      builder: (context, snapshot) {
        final grupos = snapshot.data ?? [];

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${grupos.length} grupos de preço cadastrados',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                AppButton(
                  onPressed: () => exibirGrupoPrecoDialog(context, vm),
                  icon: AppIcons.add,
                  label: 'Novo grupo',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: grupos.isEmpty
                  ? const Card(
                      child: AppEmptyState(
                        icon: AppIcons.category,
                        title: 'Nenhum grupo de preço cadastrado',
                        message:
                            'Crie grupos de preço com faixas de desconto por quantidade.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: grupos.length,
                      itemBuilder: (context, index) {
                        final g = grupos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withAlpha(40),
                              child: const Icon(AppIcons.category,
                                  color: AppColors.primary),
                            ),
                            title: Text(
                              g.nome,
                              style: AppTypography.text.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              g.descricao.isEmpty
                                  ? 'Sem descrição'
                                  : g.descricao,
                              style: AppTypography.text.copyWith(color: AppColors.textMuted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton.filledTonal(
                                  tooltip: 'Editar grupo',
                                  icon: const Icon(AppIcons.edit),
                                  onPressed: () =>
                                      exibirGrupoPrecoDialog(context, vm, g),
                                ),
                              ],
                            ),
                            children: [
                              FutureBuilder<List<FaixasPrecoData>>(
                                future: vm.gruposPreco.faixas(g.id),
                                builder: (context, snapshotFaixas) {
                                  final faixas = snapshotFaixas.data ?? [];
                                  if (faixas.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                          'Nenhuma faixa de preço cadastrada.'),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Table(
                                      border: TableBorder.all(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      children: [
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            color: AppColors.background,
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text('Quantidade',
                                                  style: AppTypography.text.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text('Preço Unitário',
                                                  style: AppTypography.text.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        for (final f in faixas)
                                          TableRow(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                  '${f.quantidadeMinima} a ${f.quantidadeMaxima ?? "ou mais"}',
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                  dinheiro(
                                                      f.valorUnitarioCentavos),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _produtoDialog(BuildContext context, AppViewModel vm,
    [ProdutoComEstoque? itemComEstoque]) async {
  final produto = itemComEstoque?.produto;
  final nome = TextEditingController(text: produto?.nome);
  int? grupoId = produto?.grupoPrecoId;

  final tempoMedio = TextEditingController(text: '${produto?.tempoMedioMinutos ?? 10}');
  final ordemProducao = TextEditingController(text: '${produto?.ordemProducao ?? 0}');
  final estoqueMinimo = TextEditingController(text: '${itemComEstoque?.estoqueMinimo ?? 0}');
  final estoqueIdeal = TextEditingController(text: '${itemComEstoque?.estoqueIdeal ?? 0}');
  final loteMinimo = TextEditingController(text: '${itemComEstoque?.loteMinimo ?? 1}');
  bool controlaEstoque = produto?.controlaEstoque ?? true;

  final grupos = await (vm.db.select(vm.db.gruposPreco)
        ..where((g) => g.ativo.equals(true))
        ..orderBy([(g) => OrderingTerm.asc(g.nome)]))
      .get();
  if (!context.mounted) return;

  if (grupoId == null && grupos.isNotEmpty) {
    grupoId = grupos.first.id;
  }

  await showDialog(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (_, set) => AlertDialog(
        title: Text(produto == null ? 'Novo Produto' : 'Editar Produto'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CARD 1: IDENTIFICAÇÃO E PREÇO
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Identificação & Precificação',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        const Divider(height: 16),
                        AppTextField(
                          label: 'Nome do produto',
                          isRequired: true,
                          controller: nome,
                          hint: 'Ex.: Coxinha de Frango',
                        ),
                        const SizedBox(height: 12),
                        AppDropdown<int>(
                          label: 'Grupo de Preço (Categoria)',
                          isRequired: true,
                          value: grupoId,
                          items: grupos
                              .map((g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text(g.nome),
                                  ))
                              .toList(),
                          onChanged: (v) => set(() => grupoId = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // CARD 2: GESTÃO DE ESTOQUE
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Controle de Estoque Físico',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            SizedBox(
                              height: 24,
                              child: Switch(
                                value: controlaEstoque,
                                onChanged: (v) => set(() => controlaEstoque = v),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        if (controlaEstoque) ...[
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Estoque Mínimo (Alerta)',
                                  controller: estoqueMinimo,
                                  keyboardType: TextInputType.number,
                                  hint: 'Ex.: 300',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Estoque Ideal (Segurança)',
                                  controller: estoqueIdeal,
                                  keyboardType: TextInputType.number,
                                  hint: 'Ex.: 500',
                                ),
                              ),
                            ],
                          ),
                        ] else
                          const Text(
                            'O controle de estoque está desativado para este produto. Nenhuma movimentação ou projeção será calculada.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // CARD 3: PLANEJAMENTO DE COZINHA & SLA
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preparação na Cozinha & Tempos (SLA)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                  label: 'Tempo por Fritura (min)',
                                  controller: tempoMedio,
                                  keyboardType: TextInputType.number,
                                  hint: 'Tempo por fornada/cuba (ex: 15)',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                  label: 'Capacidade do Lote (un)',
                                  controller: loteMinimo,
                                  keyboardType: TextInputType.number,
                                  hint: 'Capacidade por cuba/forno (ex: 50)',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dica: O sistema calcula o tempo total de fritura dividindo a quantidade do pedido pela capacidade do lote.',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Prioridade / Ordem na Produção',
                          controller: ordemProducao,
                          keyboardType: TextInputType.number,
                          hint: 'Ex.: 1 (Mais alta), 5 (Mais baixa)',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (nome.text.trim().isEmpty) return;
              if (grupoId == null) return;

              final gpNome = grupos.firstWhere((g) => g.id == grupoId).nome;

              await vm.produtos.salvar(
                id: produto?.id,
                nome: nome.text.trim(),
                categoria: gpNome,
                grupoPrecoId: grupoId!,
                tempoMedioMinutos: int.tryParse(tempoMedio.text) ?? 10,
                controlaEstoque: controlaEstoque,
                ordemProducao: int.tryParse(ordemProducao.text) ?? 0,
                estoqueMinimo: int.tryParse(estoqueMinimo.text) ?? 0,
                estoqueIdeal: int.tryParse(estoqueIdeal.text) ?? 0,
                loteMinimo: int.tryParse(loteMinimo.text) ?? 1,
              );
              if (d.mounted) Navigator.pop(d);
              if (context.mounted) {
                AppSnackbar.sucesso(context, 'Produto salvo com sucesso!');
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar produto'),
          ),
        ],
      ),
    ),
  );
}
